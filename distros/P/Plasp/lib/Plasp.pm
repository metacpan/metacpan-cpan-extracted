package Plasp;

use Carp;
use Digest::MD5 qw(md5_hex);
use File::MMagic;
use File::LibMagic;
use Module::Runtime qw(require_module);
use List::Util qw(all);
use Path::Tiny;
use Plasp::Exception::Code;
use Plasp::Log;
use Scalar::Util qw(blessed);
use Type::Tiny;

use Moo;
use Sub::HandlesVia;
use Types::Standard qw(InstanceOf Str Bool ArrayRef HashRef);
use Types::Path::Tiny qw(Path AbsPath);
use namespace::clean;

with 'Plasp::Compiler', 'Plasp::Parser', 'Plasp::State';

our $VERSION = '1.05';

=head1 NAME

Plasp - PerlScript/ASP

=head1 VERSION

version 1.05

=head1 SYNOPSIS

In C<MyApp.pm>

  package MyApp;

  use Moo;

  with 'Plasp::App';

  1;

In C<app.psgi>

  use MyApp;

  $app = MyApp->new;

=head1 DESCRIPTION

Plasp is L<CatalystX::ASP>, which is a plugin for Catalyst to support ASP
(PerlScript) but with Catalyst ripped out.

This is largely based off of Joshua Chamas's L<Apache::ASP>, as the application
I've been working with was written for L<Apache::ASP>. Thus, this was designed
to be almost a drop-in replacement. However, there were many features that I
chose not to implement.

Plasp is a framework built on Plack, which can process ASP scripts. Simply
apply the L<Plasp::App> role to your app class and create a new PSGI app with
C<< MyApp->new >>.

Just to be clear, the L<Parser|Plasp::Parser> is almost totally ripped
off of Joshua Chamas's parser in L<Apache::ASP>. Similarly with the
L<Compiler|Plasp::Compiler> and L<GlobalASA|Plasp::GlobalASA>.
However, the other components are reimplementations.

=cut

our @CompileChecksumKeys = qw(Global GlobalPackage IncludesDir XMLSubsMatch);
our @Objects             = qw(Server Request Response Application Session);

has 'req' => (
    is      => 'rw',
    clearer => 'clear_req'
);

has '_mm' => (
    is      => 'ro',
    default => sub {
        my $mm = File::MMagic->new;
        $mm->addFileExts( '\.xml$',   'text/xml' );
        $mm->addFileExts( '\.csv$',   'text/csv' );
        $mm->addFileExts( '\.css$',   'text/css' );
        $mm->addFileExts( '\.js$',    'application/javascript' );
        $mm->addFileExts( '\.json$',  'application/json' );
        $mm->addFileExts( '\.gif$',   'image/gif' );
        $mm->addFileExts( '\.jpe?g$', 'image/jpeg' );
        $mm->addFileExts( '\.png$',   'image/png' );
        $mm->addFileExts( '\.ico$',   'image/x-icon' );
        return $mm;
    },
);

has '_magic' => (
    is      => 'ro',
    default => sub {
        return File::LibMagic->new;
    },
);

=head1 CONFIGURATION

You can configure Plasp by calling the class method C<< $class->config >> and
passing in a hash ref

  MyApp->config({
    ApplicationRoot => '/var/www',
    DocumentRoot    => 'public',
    Global          => 'lib',
    GlobalPackage   => 'MyApp',
    IncludesDir     => 'templates',
    MailHost        => 'localhost',
    MailFrom        => 'myapp@localhost',
    XMLSubsMatch    => '(?:myapp):\w+',
    Debug           => 0,
  }):

The following documentation is also plagiarized from Joshua Chamas.

=over

=item ApplicationRoot

The Application root is where relative paths will be based off. By default,
it'll be the the current working directory.

=cut

has 'ApplicationRoot' => (
    is      => 'ro',
    isa     => AbsPath,
    coerce  => AbsPath->coercion,
    default => sub { path( '.' )->absolute },
);

=item DocumentRoot

An Apache::ASP compiles and processes paths based on files within the
DocumentRoot. This makes configuration similar to Apache::ASP which took the
DocumentRoot from the Apache configuration. By default, it'll be the
subdirectory C<public> relative to the ApplicationRoot.

=cut

has 'DocumentRoot' => (
    is      => 'rw',
    isa     => Path,
    coerce  => Path->coercion,
    default => sub { path( 'public' )->absolute( shift->ApplicationRoot ) },
);

=item Global

Global is the nerve center of an Apache::ASP application, in which the
global.asa may reside defining the web application's event handlers.

Includes, specified with C<< <!--#include file=somefile.inc--> >> or
C<< $Response->Include() >> syntax, may also be in this directory, please see
section on includes for more information.

=cut

has 'Global' => (
    is      => 'rw',
    isa     => Path,
    coerce  => Path->coercion,
    default => sub { shift->DocumentRoot },
);

=item GlobalPackage

Perl package namespace that all scripts, includes, & global.asa events are
compiled into.  By default, GlobalPackage is some obscure name that is uniquely
generated from the file path of the Global directory, and global.asa file. The
use of explicitly naming the GlobalPackage is to allow scripts access to globals
and subs defined in a perl module that is included with commands like:

  __PACKAGE__->config({
    GlobalPackage => 'MyApp' });

=cut

has 'GlobalPackage' => (
    is  => 'ro',
    isa => Str,
);

=item IncludesDir

No default. If set, this directory will also be used to look for includes when
compiling scripts. By default the directory the script is in, and the Global
directory are checked for includes.

This extension was added so that includes could be easily shared between ASP
applications, whereas placing includes in the Global directory only allows
sharing between scripts in an application.

  __PACKAGE__->config({
    IncludeDirs => '.' });

Also, multiple includes directories may be set:

  __PACKAGE__->config({
    IncludeDirs => ['../shared', '/usr/local/asp/shared'] });

Using IncludesDir in this way creates an includes search path that would look
like C<.>, C<Global>, C<../shared>, C</usr/local/asp/shared>. The current
directory of the executing script is checked first whenever an include is
specified, then the C<Global> directory in which the F<global.asa> resides, and
finally the C<IncludesDir> setting.

=cut

has 'IncludesDir' => (
    is     => 'rw',
    isa    => ArrayRef [Path],
    coerce => sub {
        my @paths = ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_;
        return [ map { Path->coercion->( $_ ) } @paths ];
    },
    lazy    => 1,
    default => sub { [ shift->Global ] },
);

=item MailHost

The mail host is the SMTP server that the below Mail* config directives will
use when sending their emails. By default L<Net::SMTP> uses SMTP mail hosts
configured in L<Net::Config>, which is set up at install time, but this setting
can be used to override this config.

The mail hosts specified in the Net::Config file will be used as backup SMTP
servers to the C<MailHost> specified here, should this primary server not be
working.

  __PACKAGE__->config({
    MailHost => 'smtp.yourdomain.com.foobar' });

=cut

has 'MailHost' => (
    is      => 'ro',
    isa     => Str,
    default => 'localhost',
);

=item MailFrom

No default. Set this to specify the default mail address placed in the C<From:>
mail header for the C<< $Server->Mail() >> API extension

  __PACKAGE__->config({
    MailFrom => 'youremail@yourdomain.com.foobar' });

=cut

has 'MailFrom' => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

=item XMLSubsMatch

Default is not defined. Set to some regexp pattern that will match all XML and
HTML tags that you want to have perl subroutines handle. The is
L<Apache::ASP/XMLSubs>'s custom tag technology ported to Plasp, and can
 be used to create powerful extensions to your XML and HTML rendering.

Please see XML/XSLT section for instructions on its use.

  __PACKAGE__->config({
    XMLSubsMatch => 'my:[\w\-]+' });

=cut

has 'XMLSubsMatch' => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s/\(\?\:([^\)]*)\)/($1)/isg;
        $_[0] =~ s/\(([^\)]*)\)/(?:$1)/isg;
        qr/$_[0]/;
    },
);

=item Error404Path

Path of the page in C<DocumentRoot> to serve when page not found. This page
will go through ASP processing, so ensure this page is simple and does not have
opportunity for error.

=cut

has 'Error404Path' => (
    is  => 'ro',
    isa => Str,
);

=item Error500Path

Path of the page in C<DocumentRoot> to serve when error in application, or in
Plasp. This page will go through ASP processing, so ensure this page is simple
and does not have opportunity for error.

=cut

has 'Error500Path' => (
    is  => 'ro',
    isa => Str,
);

=item FormFill

default 0, if true will auto fill HTML forms with values from $Request->Form().
This functionality is provided by use of L<HTML::FillInForm::ForceUTF8>. For
more information please see "perldoc HTML::FillInForm::ForceUTF8"

This feature can be enabled on a per form basis at runtime with
C<< $Response->{FormFill} = 1 >>

=cut

has 'FormFill' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

=item Debug

Simply sets the log level to debug

=back

=cut

has 'Debug' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has '_include_file_cache' => (
    is          => 'rw',
    isa         => HashRef,
    default     => sub { {} },
    handles_via => 'Hash',
    handles     => {
        _include_file_from_cache => 'get',
        _cache_include_file      => 'set',
        _include_file_is_cached  => 'exists',
    },
);

has '_compile_checksum' => (
    is      => 'ro',
    isa     => Str,
    default => sub {
        my $self = shift;
        md5_hex(
            join( '&-+',
                $VERSION,
                map { $self->$_ || '' } @CompileChecksumKeys
            )
        );
    },
);

# $self->log can be either a object method or class method.
#
# If called as an object method, then $asp object would be defined and
# available, ie. during request processing
#
# Otherwise, if called as a class method, then don't use PSGI logger since
# not available
my $_log = Plasp::Log->new;

sub log {
    my ( $self ) = @_;

    $_log->asp( $self ) if ref $self && !$_log->asp;

    return $_log;
}

has 'errors' => (
    is          => 'rw',
    isa         => ArrayRef,
    default     => sub { [] },
    handles_via => 'Array',
    handles     => {
        has_errors => 'count',
    }
);

sub error {
    my $self = shift;
    $self->log->error( @_ );
    push @{ $self->errors }, $_[0];
}

=head1 OBJECTS

The beauty of the ASP Object Model is that it takes the burden of CGI and
Session Management off the developer, and puts them in objects accessible from
any ASP script and include. For the perl programmer, treat these objects as
globals accessible from anywhere in your ASP application.

The Plasp object model supports the following:

  Object        Function
  ------        --------
  $Session      - user session state
  $Response     - output to browser
  $Request      - input from browser
  $Application  - application state
  $Server       - general methods

These objects, and their methods are further defined in their respective
pod.

=over

=item L<Plasp::Session>

=item L<Plasp::Response>

=item L<Plasp::Request>

=item L<Plasp::Application>

=item L<Plasp::Server>

=back

If you would like to define your own global objects for use in your scripts and
includes, you can initialize them in the F<global.asa> C<Script_OnStart> like:

  use vars qw( $Form $App ); # declare globals
  sub Script_OnStart {
    $App  = MyApp->new;     # init $App object
    $Form = $Request->Form; # alias form data
  }

In this way you can create site wide application objects and simple aliases for
common functions.

=cut

for ( qw(Server Request Response GlobalASA) ) {
    my $class = join( '::', __PACKAGE__, $_ );
    require_module $class;
    has "$_" => (
        is      => 'ro',
        isa     => InstanceOf [$class],
        clearer => "clear_$_",
        lazy    => 1,
        default => sub { $class->new( asp => shift ) },
    );
}

sub BUILD {
    my ( $self ) = @_;

    # Prepend $self->ApplicationRoot if DocumentRoo is relative and not found
    if ( !$self->DocumentRoot->exists && $self->DocumentRoot->is_relative ) {
        $self->DocumentRoot(
            path( $self->DocumentRoot )->absolute( $self->ApplicationRoot )
        );
    }

    # Prepend $self->ApplicationRoot if Global is relative and not found
    if ( !$self->Global->exists && $self->Global->is_relative ) {
        $self->Global(
            path( $self->Global )->absolute( $self->ApplicationRoot )
        );
    }

    # Go through each IncludeDir and check paths
    my @includes_dir;
    for ( @{ $self->IncludesDir } ) {
        if ( $_->is_relative ) {
            push @includes_dir,
                path( $_ )->absolute( $self->ApplicationRoot )->stringify;
        }
        else {
            push @includes_dir, $_;
        }
    }
    $self->IncludesDir( \@includes_dir );

    # Trigger Application creation now
    $self->Application;

    # Trigger GlobalASA compilation now
    $self->GlobalASA->Application_OnStart;

    # Setup new Session
    $self->GlobalASA->Session_OnStart && $self->Session->_unset_is_new
        if $self->Session->_is_new;

    return;
}

=head1 METHODS

These are methods available for the C<Plasp> object

=over

=item $self->search_includes_dir($include)

Returns the full path to the include if found in IncludesDir

=cut

sub search_includes_dir {
    my ( $self, $include ) = @_;

    # Check cache first, and just return path if cached
    return $self->_include_file_from_cache( $include )
        if $self->_include_file_is_cached( $include );


    # Look through each IncludesDir
    for my $dir ( @{ $self->IncludesDir } ) {
        my $file = $dir->child( $include );
        if ( $file->exists ) {

            # Don't forget to cache the results
            return $self->_cache_include_file( $include => $file->stringify );
        }
    }

    # For includes of absolute filesystem path
    my $file = path( $include );
    if ( $self->ApplicationRoot->subsumes( $file ) && $file->exists ) {
        return $self->_cache_include_file( $include => $file->stringify );
    }

    # Returning undef means file not found. Let calling method handle error
    return;
}

=item $self->file_id($file)

Returns a file id that can be used a subroutine name when compiled

=cut

sub file_id {
    my ( $self, $file, $without_checksum ) = @_;

    my $checksum = $without_checksum ? $self->_compile_checksum : '';
    my @id;

    $file =~ s|/+|/|sg;
    $file =~ s/[\Wx]/_/sg;
    if ( length( $file ) >= 35 ) {
        push @id, substr( $file, length( $file ) - 35, 36 );

        # only do the hex of the original file to create a unique identifier
        # for the long id
        push @id, 'x', md5_hex( $file . $checksum );
    } else {
        push @id, $file, 'x', $checksum;
    }

    return join( '', '__ASP_', @id );
}

=item $self->execute($code)

Eval the given C<$code>. The C<$code> can be a ref to CODE or a SCALAR, ie. a
string of code to execute. Alternatively, C<$code> can be the absolute name of
a subroutine.

=cut

sub execute {

    # shifting @_ because passing through arguments (from $Response->Include)
    my $self = shift;
    my $code = shift;

    no strict qw(refs);    ## no critic
    no warnings;

    # This is to set up "global" ASP objects available directly in script or
    # in the "main" namespace
    for my $object ( @Objects ) {
        for my $namespace ( 'main', $self->GlobalASA->package ) {
            my $var = join( '::', $namespace, $object );
            $$var = $self->$object;
        }
    }

    # This will cause STDOUT to be captured and handled by Tie::Handle in the
    # Response class
    tie local *STDOUT, 'Plasp::Response';

    my @rv;
    if ( my $reftype = ref $code ) {
        if ( $reftype eq 'CODE' ) {

            # The most common case
            @rv = eval { &$code; };
        } elsif ( $reftype eq 'SCALAR' ) {

            # If $code is just a ref to a string, just send it to client
            $self->Response->WriteRef( $code );

            # Determine the MIME type of the content
            ## Suppress warnings from File::MMagic
            local $SIG{__WARN__} = sub { };
            my $mimetype = $self->_mm->checktype_byfilename(
                $self->req->path_info
            );
            if ( $mimetype =~ m{application/octet-stream} ) {
                my $file = path(
                    $self->DocumentRoot, $self->req->path_info
                )->stringify;
                $mimetype = $self->_magic->info_from_filename(
                    $file
                )->{mime_type};
            }
            $self->Response->ContentType( $mimetype );
        } else {
            $self->error(
                "Could not execute because \$code is a ref, but not CODE or SCALAR!"
            );
        }
    } elsif ( defined( $code ) && length( $code ) ) {

        # Alternatively, execute a function in the ASP context given a string
        # of the subroutine name
        # If absolute package already, then no need to set to package namespace
        my $subid = ( $code =~ /::/ )
            ? $code
            : $self->GlobalASA->package . '::' . $code;
        @rv = eval { &$subid; };
    }
    if ( $@ ) {

        unless ( blessed( $@ )
            && ( $@->isa( 'Plasp::Exception::End' )
                || $@->isa( 'Plasp::Exception::Redirect' ) ) ) {

            # "Rethrow" the error
            Plasp::Exception::Code->throw( $@ );
        }
    }

    return @rv;
}

=item $self->cleanup()

Cleans up objects that are transient. Get ready for the next request

=cut

has '_cleaned_up' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

sub cleanup {
    my ( $self ) = @_;

    # Don't need to do it if already cleaned up
    return if $self->_cleaned_up;

    # Since cleanup happens at the end of script processing, trigger
    # Script_OnEnd
    $self->GlobalASA->Script_OnEnd;

    # Clean up abandoned $Session, which marks the end of the $Session and so
    # trigger Session_OnEnd
    $self->GlobalASA->Session_OnEnd if $self->Session->IsAbandoned;

    # Remove more references in order to get things destroyed
    undef &Plasp::Response::TIEHANDLE;

    # Remove references to global ASP objects
    no strict qw(refs);    ## no critic
    for my $object ( reverse @Objects ) {
        for my $namespace ( 'main', $self->GlobalASA->package ) {
            my $var = join( '::', $namespace, $object );
            undef $$var;
        }
    }

    # Clear transient global objects from ASP object
    $self->clear_Session;
    $self->clear_Response;
    $self->clear_Request;

    # Clear request attributes
    $self->clear_req;
    $self->errors( [] );
    $self->log->entries( [] );

    $self->_cleaned_up( 1 );
}

# Clear remaining global objects in order
sub DEMOLISH {
    my ( $self ) = @_;

    $self->cleanup;

    $self->clear_Application;
    $self->clear_Server;
    $self->clear_GlobalASA;
}

1;

=back

=head1 BUGS/CAVEATS

Obviously there are no bugs ;-) As of now, every known bug has been addressed.
However, a caveat is that not everything from Apache::ASP is implemented here.
Though the module touts itself to be a drop-in replacement, don't believe the
author and try it out for yourself first. You've been warned :-)

=head1 AUTHOR

Steven Leung E<lt> sleung@cpan.org E<gt>

Joshua Chamas E<lt> asp-dev@chamas.com E<gt>

=head1 SEE ALSO

=over

=item * L<Plasp::App>

=item * L<Plack>

=item * L<Apache::ASP>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 Steven Leung

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

package Module::Recursive::Require;

use strict;
use warnings;
use Carp;
use File::Spec;
use File::Find;
use File::Basename;
use UNIVERSAL::require;
use vars qw/$VERSION/;

$VERSION = '0.04';

sub new {
    my $proto      = shift;
    my $class      = ref $proto || $proto;
    my $args_ref   = shift;
    
    # * Default path by $INC[0]
    my $path       
        = $args_ref->{path} || $INC[0];

    # * Default extentions by .pm and .pl
    my $extensions
        = $args_ref->{extensions} || [qw/pm pl/];

    my $self
        = {
            _path        => File::Spec->catfile( $path ),
            _filters     => [],
            _extensions  => $extensions,
            _packages    => undef,
            _first_loads => [],
          };

    return bless( $self, $class );
}

sub first_loads {
    my $self    = shift;
    my @modules = @_;

    $self->{_first_loads} = \@modules;

    return 1;
}

sub add_filter {
    my $self   = shift;
    my $filter = shift;

    push @{ $self->{_filters} }, $filter;

    return 1;
}

# * deprecated!!
sub require_by {
    my $self         = shift;
    my $package_name = shift;

    return $self->require_of( $package_name );
}

sub require_of {
    my $self         = shift;
    my $package_name = shift || croak "require package name!";

    my $modules
         = $self->_get_modules( $package_name ) or return 0;

    unshift( @$modules, @{ $self->{_first_loads} })
        if scalar @{ $self->{_first_loads} };

    my $_required        = {};
    my @required_modules = ();
    REQUIRED:
    for my $module ( @$modules ) {
        next REQUIRED if exists $_required->{$module};
        
        $module->require() or croak $@;
        $_required->{$module} = 1;
        push @required_modules, $module;
    }

    return ( wantarray ) ? @required_modules : \@required_modules;
}

sub _get_modules {
    my $self         = shift;
    my $package_name = shift;

    my $path
         = File::Spec->catfile(
            $self->{_path},
            split( '::', $package_name ),
           );

    find( $self->_make_filter_sub_ref(), $path);

    return $self->{_packages};
}

sub _make_filter_sub_ref {
    my $self   = shift;
    
    my $filters = $self->{_filters};
    my $extensions
         = $self->_scalar2array_ref( $self->{_extensions} );

    return sub {
        my $fullname = $File::Find::name;
        my $filename = $_;

        return 0
            unless ( $self->_has_exts_by($fullname, $extensions) );

        for my $filter ( @$filters ) {
            return 0 if $filename =~ /$filter/;
        }

        # * path to package name
        # ** UNIX OS only.. orz
        my $package_name
            = $self->_get_package_name(
                {
                    fullname => $fullname,
                    libpath  => $self->{_path}
                }
              );

        push @{ $self->{_packages} }, $package_name;

        return 1;
    }
}

sub _get_package_name {
    my $self    = shift;
    my $arg_ref = shift;

    my $fullname = $arg_ref->{fullname};
    my $libpath  = $arg_ref->{libpath};

    my $package_name = undef;
    if ( $fullname =~ m|^$libpath/(.+)\..+$| ) {
        $package_name = $1;
        $package_name =~ s/\//::/g;
    }

    return $package_name;
}

sub _has_exts_by {
    my $self       = shift;
    my $fullpath   = shift;
    my $extensions = shift;
    
    my ($name, $path, $ext)
          = fileparse( $fullpath, @$extensions );

    return ( $ext ) ? 1 : 0;
}

sub _scalar2array_ref {
    my $self = shift;
    my $val  = shift;

    return ( ref $val eq 'ARRAY' ) ? $val : [($val)];
}


1;

=head1 NAME

Module::Recursive::Require - This class require module recursively.

=head1 DESCRIPTION

 # ************************************** before
 use MyApp::Foo;
 use MyApp::Foo::CGI;
 use MyApp::Foo::Mail;
 use MyApp::Foo::Mail::Send;
 
 # use use use use use !!
 
 use MyApp::Foo::Hoge::Orz;

 # ************************************** after
 use Module::Recursive::Require;
 use MyApp::Foo;

 my @required_packages
    = Module::Recursive::Require->new()->require_by('MyApp::Foo'); 

=head1 SYNOPSIS

 use Module::Recursive::Require;
 
 my $r = Module::Recursive::Require->new();
 $r->first_loads(
                    qw/
                          MyApp::Foo::Boo
                      /
                );                          # * It loads first.
 $r->add_filter(qr/^Hoge/);                 # * Don't loaded  qr/^Hoge/
 $r->add_filter(qr/Base.pm$/);              # * Don't loaded  qr/Base.pm$/
 
 my @packages = $r->require_of('MyApp::Foo');

 # * or

 my $packages_array_ref
     = $r->require_of('MyApp::Foo');

=head1 METHOD

=head2 new( \%args )

 %args = (
    path       => '/var/www/my/lib', # * default $INC[0]
    extensions => 'pm'             , # * default "pm" and "pl"
 );

=head2 first_loads( @package_names );

=head2 add_filter(qr/regexp/)

=head2 require_of( 'MyApp::Foo' );

=head2 require_by( 'MyApp::Foo' );

Deprecated. For backwards compatibility only.

=head1 SEE ALSO

L<UNIVERSAL::require>

=head1 AUTHOR

Masahiro Funakoshi <masap@cpan.org>

=cut 

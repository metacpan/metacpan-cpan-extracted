package POE::XUL::Logging;
# $Id: Logging.pm 1566 2010-11-03 03:13:32Z fil $
# Copyright Philip Gwyn 2007-2010.  All rights reserved.
#
# Handle logging features for the application
# 

use 5.008;
use strict;
use warnings;

use Carp;
use Scalar::Util qw( reftype blessed openhandle );

use constant DEBUG => 0;

our $VERSION = '0.0601';

require Exporter;
our @ISA = qw( Exporter );

our @EXPORT_OK = qw( xwarn xlog xdebug xcarp xcarp2 );
our @EXPORT = @EXPORT_OK;

our $SINGLETON;

# To interface with log4perl
my %type2level = (
    DEBUG       => 10000,
    LOG         => 20000,
    REQ         => 20000,
    WARN        => 30000,
    SETUP       => 42000
);

############################################################
sub new
{
    my( $package, $args, $log_root ) = @_;

    my $rt = reftype $args;
    if( $args ) {
        if( !$rt or $rt eq 'CODE' or $rt eq 'HASH' or blessed $args ) {
            # ok
        }
        elsif( $rt eq 'ARRAY' ) {
            if( 2 > @$args ) {
                croak "logging parameter must have at least 2 elements";
            }
        }
        else {
            croak "logging parameter must be a CODE ref, ARRAY ref, scalar or a log4perl object";
        }
    }

    my $self = $SINGLETON = 
                bless { logger=>$args, log_root=>$log_root }, $package;

    if( $rt and $rt eq 'HASH' ) {
        $self->{logger}     = $args->{logger};
        $self->{access_log} = $args->{access_log};
        $self->{error_log}  = $args->{error_log};
        $self->__init_apps( $args->{apps} );
    }

    return $SINGLETON;
}

sub __init_apps
{
    my( $self, $apps ) = @_;
    unless( $apps ) {
        $self->{apps} = [];
        return;
    }
    unless( ref $apps ) {
        $apps = { $apps=>$apps };
    }
    elsif( 'ARRAY' eq ref $apps ) {
        my %A;
        @A{@$apps} = @$apps;
        $apps = \%A;
    }
    $self->{apps} = [];
    while( my( $app, $def ) = each %$apps ) {
        push @{ $self->{apps} }, $app;
        foreach my $t ( qw( access error ) ) {
            my $log = "${t}_log";
            my $file;
            unless( ref $def ) {
                $file = File::Spec->catfile( $def, $log );
            }
            elsif( $def->{$log} ) {
                $file = $def->{$log};
            }
            else {
                $file = File::Spec->catfile( $app, $log );
            }
            $self->{"$app-$t-log"} = $file;
        }
    }
    return;
}

############################################################
sub setup
{
    my( $self ) = @_;

    $self->{logger} ||= \&default_sub;
    $self->dispatch( { type      => 'SETUP', 
                       directory => $self->{log_root}
                   } );
}

############################################################
# Dispatch the exception
sub dispatch
{
    my( $self, $exception ) = @_;
    $self = $SINGLETON unless blessed $self;

    $exception = { message => $exception, type => 'LOG' }
                        unless ref $exception;

    my $rt = reftype $self->{logger};
    if( blessed $self->{logger} ) {
        return if $exception->{type} eq 'SETUP';
        my $lvl = $type2level{ $exception->{type} };
        $lvl ||= $type2level{ 'LOG' };
        $self->{logger}->log( $lvl, $exception->{message} );
    }
    elsif( not $rt ) {
        $POE::Kernel::poe_kernel->call( $self->{logger}, 'log', $exception );
    }
    elsif( $rt eq 'ARRAY' ) {
        # warn "POE logger @{ $self->{logger} }";
        $POE::Kernel::poe_kernel->call( @{ $self->{logger} }, $exception );
    }
    elsif( $rt eq 'CODE' ) {
        $self->{logger}->( $exception );
    }
}

############################################################
sub default_sub
{
    my( $ex ) = @_;
    $ex->{type} ||= '';

    if( $ex->{type} eq 'SETUP' ) {
        $SINGLETON->default_setup;
        return;
    }

    if( $ex->{type} and $ex->{type} ne 'REQ' ) {
        $ex->{message} = "$ex->{type} $ex->{message}";
    }
    $SINGLETON->default( @_ ) 
}


############################################################
sub default_setup
{
    my( $self ) = @_;
    $self = $SINGLETON unless blessed $self;

    $self->{stderr_fh} = $self->open_file( qw( error_log error_log ) );
    $self->{error_fh} = $self->{stderr_fh};
    $self->{log_fh}    = $self->open_file( qw( access_log access_log ) );
    $self->{access_fh} = $self->{log_fh};
    foreach my $app ( @{ $self->{apps} } ) {
        foreach my $t ( qw( error access ) ) {
            if( $self->{"$app-$t-log"} ) {
                $self->{"$app-$t-fh"} = 
                        $self->open_file( "$app-$t-log", "$app/${t}_log" );
            }
            else {
                $self->{"$app-$t-fh"} = $self->{"${t}_fh"};
            }
        }
    }
}

############################################################
sub open_file
{
    my( $self, $key, $name ) = @_;    

    my $file = $self->{$key};
    $file ||= File::Spec->catfile( $self->{log_root}, $name ); 
    unless( File::Spec->file_name_is_absolute( $file ) ) {
        $file = File::Spec->catfile( $self->{log_root}, $file );
        $self->{$key} = $file;
    }

    my( $vol, $dir, $f ) = File::Spec->splitpath( $file );

    if( $dir and not -d $dir ) {
        File::Path::mkpath( [ $dir ], 0, 0750 );
    }

    my $fh = IO::File->new;
    unless( $fh->open(">> $file") ) {
        warn "AUGH $file: $!";
        die "Unable to create log file $file: $!";
    }
    $fh->autoflush(1);
    return $fh;
}



############################################################
sub default
{
    my( $self, $exception ) = @_;
    $self = $SINGLETON unless blessed $self;

	my $type = $exception->{type}||'';
	my $msg = $exception->{message};
    $msg = '' unless defined $msg;
    $msg =~ s/\n+$// if $exception->{location};
    if( $msg !~ /\n$/ ) {
        $msg .= " at $exception->{caller}[1] line $exception->{caller}[2]"
					if $exception->{caller};
    	$msg .= "\n";
    }
	
    my $app = $self->{app}||'THERE-IS-NO-APP';
    my $t = $type eq 'REQ' ? 'access' : 'error';
    my $fh = $self->{"$app-$t-fh"} || $self->{"${t}_fh"} || $self->{stderr_fh};
    if( $fh ) {
        $fh->print( $msg );
    }
    else {
        print STDERR $msg;
    }
}



############################################################
sub __mk_exception
{
    my( $package, $type, $level, @msg ) = @_;

    local $, = $,;
    $, = '' unless defined $,;
    return {
            type    => $type,
            message => join( $,, grep {defined} @msg),
            caller  => [ caller( $level ) ]
        };
}

sub xdebug
{
    return carp join( '' , @_ ) unless $SINGLETON;
    $SINGLETON->dispatch( $SINGLETON->__mk_exception( 'DEBUG', 1, @_ ) );
}

sub xwarn
{
    return carp join( '' , @_ ) unless $SINGLETON;
    $SINGLETON->dispatch( $SINGLETON->__mk_exception( 'WARN', 1, @_ ) );
}

sub xcarp
{
    my $ex = $SINGLETON->__mk_exception( 'WARN', 2, @_ );
    $ex->{location} = 1;
    $SINGLETON->dispatch( $ex );
}

sub xcarp2
{
    my $ex = $SINGLETON->__mk_exception( 'WARN', 3, @_ );
    $ex->{location} = 1;
    $SINGLETON->dispatch( $ex );
}

sub xlog
{
    my $ex;
    if( 1==@_ and 'HASH' eq ref $_[0] ) {
        $ex = $_[0];
        $ex->{type}   ||= 'LOG';
        $ex->{caller} ||= [ caller( 0 ) ];
    }
    else {
        $ex = $SINGLETON->__mk_exception( 'LOG', 1, @_ );
    }
    $SINGLETON->dispatch( $ex );
}




1;

__DATA__

=head1 NAME

POE::XUL::Logging - POE::XUL logging 

=head1 SYNOPSIS

    use POE::Component::XUL;
    use POE::Logging;

    POE::Component::XUL->spawn( { logging => $destination } );

    xlog "I'm doing X";
    xwarn "Look at me!"
    xcarp "You did that!";
    xdebug "Something=$something";

=head1 DESCRIPTION

POE::XUL::Logging is a singleton object used by L<POE::XUL> to flexibly
dispatch log messages, warnings and debug messages in an application-defined
manner.  The message destination may be a coderef, a logging object (think
Log4Perl), a POE session or POE session/event tuple.

An application does not instanciate the POE::XUL::Logging singleton
directly.  Rather, this is handled by L<POE::Component::XUL> and controled
by the C<logging> parameter to L<POE::Component::XUL/spawn>.

Each message has a severity level. POE::XUL::Logging defines the following
levels, in order of severity: C<DEBUG>, C<LOG>, C<REQ>, C<WARN>.  REQ and
LOG are synonyms, the difference being that REQ is for logging a static
request, equivalent to apache's access_log.

There is also the C<SETUP> psuedo-level which is used when it is time to
open or reopen any log files.

=head1 CONFIG

POE::XUL::Logging is configured by a logger parameter that is
passed to
POE::Component::XUL's spawn method.

=head2 $message

Regardless of the logger being used, each message is encapsulated in a
message structure.  This structure is a hashref with the following keys:

=over 4

=item type

One of C<DEBUG>, C<LOG>, C<REQ>, C<WARN> or C<SETUP>.  A logger is expected
to handle the message bassed on this field.  C<DEBUG> and C<WARN> messages
might ignored in a production server.  C<REQ> messages might go to a
different file then C<LOG>.  C<SETUP> messages are used by
C<POE::Component::XUL> to tell the logger to open (or reopen) any log files.

=item message

Text of the message.

=item caller

Arrayref of the output of L<perlfunc/caller> at the relevant caller-frame-level.

=back


A logger may be one of the following:

=head2 coderef

    POE::Component::XUL->spawn( { logging => \&my_log } );
    sub my_log {
        my( $message ) = @_;
    }

C<$message> is described above.

=head2 object

    my $logger = Log::Log4perl->get_logger( "My::Logger" );
    POE::Component::XUL->spawn( { logging => $logger } );

All log messages will be dispatched via the object's C<log> method:

    sub log {
        my( $level, $message ) = @_;
    }

C<$level> is the numeric level, compatible with Log::Log4perl.  
C<$message> is described above.

Note that the object will never be passed a SETUP message.


=head2 POE session

    POE::Component::XUL->spawn( { logging => $_[SESSION]->id } );
    
All log messages will be dispatched via the sessions's C<log> event:

    sub log {
        my( $self, $message ) = @_[OBJECT, ARG0];
    }

C<$message> is described above.


=head2 POE session/method tuple

    POE::Component::XUL->spawn( { logging => [ $session, $event ] );
    
All log messages will be dispatched to C<$session>'s C<$event> state.

    sub log_state {
        my( $heap, $message ) = @_[HEAP, ARG0];
    }

C<$message> is described above.



=head1 FUNCTIONS

=head2 xlog

    xlog "Foo", $biff, " bar";

=head2 xwarn

    xwarn "This is going badly";

=head2 xcarp

    xcarp "Don't do that";

Same as L</xwarn>, but C<caller> is one frame higher.

=head2 xdebug

    xdebug "Do you care";

=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 CREDITS

Based on XUL::Node by Ran Eilam.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Philip Gwyn.  All rights reserved;

Copyright 2003-2004 Ran Eilam. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), L<POE::XUL>, L<POE::XUL::Node>.

=cut


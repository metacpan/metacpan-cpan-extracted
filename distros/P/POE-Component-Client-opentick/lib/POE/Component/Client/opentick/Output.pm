package POE::Component::Client::opentick::Output;
#
#   opentick.com POE client
#
#   Diagnostic message output class
#
#   infi/2008
#
#   $Id: Output.pm 56 2009-01-08 16:51:14Z infidel $
#
#   Full POD documentation after __END__
#

use strict;
use warnings;
use Time::HiRes qw( time );

use overload '""' => \&stringify;

use vars qw( $VERSION $TRUE $FALSE $DEBUG $QUIET $PREFIX );

BEGIN {
    require Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( O_DEBUG O_INFO O_NOTICE O_WARN O_ERROR );
    ($VERSION)  = q$Revision: 56 $ =~ /(\d+)/;
}

###
### Variables
###

*TRUE   = \1;
*FALSE  = \0;
$DEBUG  = $FALSE;
$QUIET  = $FALSE;
$PREFIX = $TRUE;

my $output = {
    DEBUG   => *STDERR,
    INFO    => *STDOUT,
    NOTICE  => *STDOUT,
    WARN    => *STDERR,
    ERROR   => *STDERR,
};

###
### Exported functions
###

sub O_DEBUG
{
    my @msg = @_;
    my $msg = join( ' ', @msg );

    _output( $msg, 'DEBUG' ) if $DEBUG and( !defined( wantarray ) );

    return( defined( wantarray )
        and POE::Component::Client::opentick::Output->new( 'DEBUG', $msg ) );
}

sub O_INFO
{
    my @msg = @_;
    my $msg = join( ' ', @msg );

    _output( $msg, 'INFO' ) unless( defined( wantarray ) );

    return( defined( wantarray )
        and POE::Component::Client::opentick::Output->new( 'INFO', $msg ) );
}

sub O_NOTICE
{
    my @msg = @_;
    my $msg = join( ' ', @msg );

    _output( $msg, 'NOTICE' ) unless( defined( wantarray ) );

    return( defined( wantarray )
        and POE::Component::Client::opentick::Output->new( 'NOTICE', $msg ) );
}

sub O_WARN
{
    my @msg = @_;
    my $msg = join( ' ', @msg );

    _output( $msg, 'WARN' ) unless( defined( wantarray ) );

    return( defined( wantarray )
        and POE::Component::Client::opentick::Output->new( 'WARN', $msg ) );
}

sub O_ERROR
{
    my @msg = @_;
    my $msg = join( ' ', @msg );

    _output( $msg, 'ERROR' ) unless( defined( wantarray ) );

    return( defined( wantarray )
        and POE::Component::Client::opentick::Output->new( 'ERROR', $msg ) );
}

###
### Class methods
###

# Constructor
sub new
{
    my( $class, $level, $msg, @args ) = @_;

    my $self = bless( {
        level       => $level,
        message     => $msg,
        timestamp   => time,
    }, 'POE::Component::Client::opentick::Output' );

    $self->initialize( @args );

    return( $self );
}

# Overload this.
sub initialize {}

# And this.
sub stringify
{
    my( $self ) = @_;

    my $message = sprintf( "OT:%s:%s:%s\n",
                           $self->get_level(),
                           $self->get_timestamp(),
                           $self->get_message() );

    return( $message );
}

###
### Accessor methods
###

# Hybrid method; set the DEBUG flag
sub set_debug
{
    my $junk = shift;
    my $value = ref( $junk ) || $junk =~ /::/ ? shift : $junk;

    return( $DEBUG = $value ? $TRUE : $FALSE );
}

# Hybrid method: set the QUIET flag; overrides DEBUG
sub set_quiet
{
    my( $junk ) = shift;
    my $value = ref( $junk ) || $junk =~ /::/ ? shift : $junk;

    return( $QUIET = $value ? $TRUE : $FALSE );
}

# Hybrid method: set the PREFIX flag.
sub set_prefix
{
    my $junk = shift;
    my $value = ref( $junk ) || $junk =~ /::/ ? shift : $junk;

    return( $PREFIX = $value ? $TRUE : $FALSE );
}

# INSTANCE METHOD
sub get_level
{
    my( $self ) = shift;
    return unless( ref( $self ) );

    return( $self->{level} );
}

# INSTANCE METHOD
sub get_message
{
    my( $self ) = shift;
    return unless( ref( $self ) );

    return( $self->{message} );
}

# INSTANCE METHOD
sub get_timestamp
{
    my( $self ) = shift;
    return unless( ref( $self ) );

    return( $self->{timestamp} );
}

###
### Private methods
###

# Private output method
sub _output
{
    return if $QUIET;
    my( $msg, $level ) = @_;

    printf { _get_filehandle( $level ) } "%s%s\n",
                                         $PREFIX
                                         ? 'OT:' . $level . ': '
                                         : '',
                                         $msg;
}

sub _get_filehandle
{
    my( $level ) = @_;

    return( $output->{$level} || *STDOUT );
}

1;

__END__

=pod

=head1 NAME

POE::Component::Client::opentick::Output - Diagnostic message output class.

=head1 SYNOPSIS

 use POE::Component::Client::opentick::Output;

=head1 DESCRIPTION

This module contains diagnostic output routines used by the rest of
POE::Component::Client::opentick, and thus is of no use to anything else.

It also rudely exports a bunch of junk into your namespace.  This is
desirable for the POE component, but why would you want that in your own
module?

Don't fiddle with it.  Ist easy schnappen der Springenwerk, blowen-fusen
und poppen corken mit spitzensparken.

=head1 FUNCTIONS

=over 4

=item B<[$obj = ] O_DEBUG( $msg, $more_msg, .... )>

Print a message at the DEBUG level, or return an object containing the
message.

=item B<[$obj = ] O_INFO( $msg, $more_msg, .... )>

Print a message at the INFO level, or return an object containing the
message.

=item B<[$obj = ] O_NOTICE( $msg, $more_msg, .... )>

Print a message at the NOTICE level, or return an object containing the
message.

=item B<[$obj = ] O_WARN( $msg, $more_msg, .... )>

Print a message at the WARN level, or return an object containing the
message.

=item B<[$obj = ] O_ERROR( $msg, $more_msg, .... )>

Print a message at the ERROR level, or return an object containing the
message.

=item B<$obj = new( @args )>

Create a new object.

=item B<initialize( )>

Initialize the object instance.

=item B<stringify()>

The overloaded stringification method for this object.  It is magic.

Do not gaze upon it lest your brain explode.

=back

=head1 SUBCLASSING

The intent for this module is to be able to be subclassed to redirect
error output to the desired location.

It is thought that the only thing necessary would be to redefine the $output
hashref to do so.  But, to be honest, I haven't tested.

Maybe this will change, in my copious free time.  Feel free to try it.

=head1 ACCESSORS

If you should choose to use this as an object (as happens when it is used
in an exception), here are some accessors to use:

=over 4

=item B<set_debug>      -- CLASS -- set the DEBUG flag

=item B<set_prefix>     -- CLASS -- set the prefix

=item B<set_quiet>      -- CLASS -- set the QUIET flag

=item B<get_level>      -- return the level of this object

=item B<get_message>    -- return the actual message

=item B<get_timestamp>  -- return the timestamp of this object

=back

=head1 NOTES

This module also overloads the stringify() method '""', so using the
object in a string will automagically dump its contents in a useful format.

=head1 SEE ALSO

POE, POE::Component::Client::opentick

L<http://poe.perl.org>

L<http://www.opentick.com/>

perldoc lib

perldoc -q "include path"

=head1 AUTHOR

Jason McManus (INFIDEL) - C<< infidel AT cpan.org >>

=head1 LICENSE

Copyright (c) Jason McManus

This module may be used, modified, and distributed under the same terms
as Perl itself.  Please see the license that came with your Perl
distribution for details.

The data from opentick.com are under an entirely separate license that
varies according to exchange rules, etc.  It is your responsibility to
follow the opentick.com and exchange license agreements with the data.

Further details are available on L<http://www.opentick.com/>.

=cut


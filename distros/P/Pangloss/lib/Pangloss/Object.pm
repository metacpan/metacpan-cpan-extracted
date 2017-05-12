=head1 NAME

Pangloss::Object - base class for all Pangloss objects.

=head1 SYNOPSIS

 package Foo;
 use base qw( Pangloss::Object );

 # Pangloss::accessors is loaded for you:
 use accessors qw( bar );

 my $foo = Foo->new( @optional_args )->bar('baz');

 $Pangloss::DEBUG{ Foo } = 1;
 $Pangloss::DEBUG{ ALL } = 1;

 $foo->emit( 'a message' );

=cut

package Pangloss::Object;

use strict;
use warnings::register;

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.10 $ '))[2];

sub new {
    my $class = shift->class;
    my $self  = bless {}, $class;
    $self->init(@_) || return;
    return $self;
}

sub init {
    my $self = shift;
}

sub emit {
    my $self  = shift;
    my $mesg  = shift;
    my $class = $self->class;
    my ($package, $filename, $line, $subroutine, $hasargs,
	$wantarray, $evaltext, $is_require, $hints, $bitmask) = caller( 1 );
    $subroutine =~ s/.*:://;
    if ($Pangloss::DEBUG{ ALL } || $Pangloss::DEBUG{ $class }) {
	my $warn_str = "[$class\::$subroutine] $mesg";
	$warn_str   .= "\n" unless $mesg =~ /\n/;
	warn( $warn_str );
    }
    return $self;
}

sub class {
    my $thing = shift;
    return ref($thing) || $thing;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Base class for Pangloss objects.

=head1 METHODS

=over 4

=item $obj = $class->new( @args )

creates and returns a new object, if $obj->init( @args ) returns a true value.

=item $bool = $obj->init( @args )

does nothing by default.  a I<false> return value means initialization failed.

=item $obj = $obj->emit( $msg )

emits $msg if debugging is enabled for this object's class.  can also be called
as a class method.

=back

=head1 CLASS VARIABLES

=over 4

=item %Pangloss::DEBUG

hash of classes to enable debugging for, via emit().  If 'ALL' is set,
debugging for all Pangloss classes is enabled.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>,
Similar to L<OpenFrame::Object>.

=cut



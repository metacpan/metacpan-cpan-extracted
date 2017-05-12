=head1 NAME

Pangloss::Term::Status - the status of a term.

=head1 SYNOPSIS

  use Pangloss::Term::Status;
  my $status = new Pangloss::Term::Status();

  $status->pending()
         ->notes( $text )
         ->creator( $user )
         ->date( time );

  do { ... } if $status->is_pending();

=cut

package Pangloss::Term::Status;

use strict;
use warnings::register;

use base qw( Pangloss::StoredObject::Common );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.10 $ '))[2];

use constant PENDING    => 1;
use constant APPROVED   => 2;
use constant REJECTED   => 4;
use constant DEPRECATED => 8;

sub status_codes {
    my $class = shift;
    my %codes = (
		 pending    => $class->PENDING,
		 approved   => $class->APPROVED,
		 rejected   => $class->REJECTED,
		 deprecated => $class->DEPRECATED,
		);
    return wantarray ? %codes : \%codes;
}

sub code {
    my $self = shift;
    return $self->name(@_);
}

sub pending {
    my $self = shift;
    $self->code($self->PENDING);
}

sub approved {
    my $self = shift;
    $self->code($self->APPROVED);
}

sub rejected {
    my $self = shift;
    $self->code($self->REJECTED);
}

sub deprecated {
    my $self = shift;
    $self->code($self->DEPRECATED);
}

sub is_pending {
    my $self = shift;
    return ($self->code & $self->PENDING);
}

sub is_approved {
    my $self = shift;
    return ($self->code & $self->APPROVED);
}

sub is_rejected {
    my $self = shift;
    return ($self->code & $self->REJECTED);
}

sub is_deprecated {
    my $self = shift;
    return ($self->code & $self->DEPRECATED);
}

sub copy {
    my $self = shift;
    return $self->SUPER::copy( @_ );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class represents a status associated with a term.
It inherits from L<Pangloss::StoredObject::Common>.

=head1 FLAGS

The following flags are available as class variables:

  PENDING
  APPROVED
  REJECTED
  DEPRECATED

They are also available as a hash with lowercase keys via $class->status_codes.

=head1 METHODS

=over 4

=item $obj->code

internal method to set/get status code.

=item $obj = $obj->pending, $obj->accepted, $obj->rejected, $obj->deprecated

set this status code to one of the above.  At present, multiple flags can only
be set (ie: approved | deprecated) by setting $obj->code directly.

=item $bool = $obj->is_pending, $obj->is_accepted, $obj->is_rejected,
$obj->is_deprecated

test if this status code is one of the above.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Term>

=cut


package TUI::Validate::Validator;
# ABSTRACT: Abstract base class for validators

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TValidator
  new_TValidator
);

use TUI::toolkit;
use TUI::toolkit::Types qw( :types );

use TUI::Objects::Object;

sub TValidator() { __PACKAGE__ }
sub name() { 'TValidator' };
sub new_TValidator { __PACKAGE__->from(@_) }

extends TObject;

# public attributes
has status  => ( is => 'rw', default => 0 );
has options => ( is => 'rw', default => 0 );

sub error {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  return;
}

sub isValidInput {    # $bool ($s, $suppressFill)
  state $sig = signature(
    method => Object,
    pos    => [Str, Bool],
  );
  $sig->( @_ );
  return true;
}

sub isValid {    # $bool ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  $sig->( @_ );
  return true;
}

sub transfer {    # $n ($s, $buffer, $flags)
  state $sig = signature(
    method => Object,
    pos    => [Str, Any, PositiveOrZeroInt],
  );
  $sig->( @_ );
  return 0;
}

sub validate {    # $bool ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  if ( !$self->isValid( $s ) ) {
    $self->error();
    return false;
  }
  return true;
}

1

__END__

=pod

=head1 NAME

TUI::Validate::Validator - Abstract base class for validator objects

=head1 HIERARCHY

  TObject
    TValidator

=head1 SYNOPSIS

  use TUI::Validate::Validator;

  # Base class for custom validators.
  package MyValidator;
  use TUI::toolkit;
  use TUI::Validate::Validator;

  extends TValidator;

  sub isValid {
    my ( $self, $s ) = @_;
    return $s =~ /\A\d+\z/;
  }

=head1 DESCRIPTION

TValidator defines the common interface used by validation classes in the
framework.

It provides the base contract for three validation phases: incremental input
checks, final acceptance checks, and optional data transfer handling.

The default implementation is neutral and intended as a superclass; concrete
validators specialize behavior for concrete value domains.

=head2 Commonly Used Features

Typical subclasses combine L</isValidInput> for live field checking with
L</isValid> for final acceptance.

Callers that want a single validation entry point usually use L</validate>,
which performs the check and triggers L</error> on failure.

For non-string payloads, subclasses can override L</transfer> to bridge between
widget text and structured data.

=head1 ATTRIBUTES

=head2 options

Read/write bit field for validator options (I<PositiveOrZeroInt>).

=head2 status

Read/write status value set by concrete validator implementations
(I<PositiveOrZeroInt>).

=head1 CONSTRUCTOR

=head2 new

Construction is inherited from L<TObject|TUI::Objects::Object>.

=head2 new_TValidator

  my $obj = new_TValidator();

Factory helper exported by this module.

=head1 METHODS

=head2 error

  $obj->error();

Hook for reporting validation failures. The base implementation is a no-op.

=head2 isValid

  my $ok = $obj->isValid($s);

Checks whether a completed value is valid. The base implementation returns
true.

=head2 isValidInput

  my $ok = $obj->isValidInput( $s, $suppressFill );

Checks whether in-progress input is acceptable. The base implementation
returns true.

=head2 transfer

  my $n = $obj->transfer( $s, $buffer, $flags );

Optional data transfer hook. A non-zero return value means the validator
handled the transfer operation.

=head2 validate

  my $ok = $obj->validate($s);

Calls C<isValid>. If validation fails, C<error> is invoked and false is
returned.

=head1 SEE ALSO

L<TUI::Validate::Const>,
L<TPXPictureValidator|TUI::Validate::PXPictureValidator>,
L<TObject|TUI::Objects::Object>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut

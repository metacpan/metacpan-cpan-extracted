package TUI::Validate::LookupValidator;
# ABSTRACT: abstract base class for lookup-based validation

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TLookupValidator
  new_TLookupValidator
);

use TUI::toolkit;
use TUI::toolkit::Types qw( :types );

use TUI::Validate::Validator;

sub TLookupValidator() { __PACKAGE__ }
sub name() { 'TLookupValidator' };
sub new_TLookupValidator { __PACKAGE__->from(@_) }

extends TValidator;

sub isValid {    # $bool ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  return $self->lookup( $s );
}

sub lookup {    # $bool ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  return true;
}

1

__END__

=pod

=head1 NAME

TUI::Validate::LookupValidator - abstract base class for lookup-based validation

=head1 HIERARCHY

  TObject
    TValidator
      TLookupValidator

=head1 SYNOPSIS

  # This is an abstract base class.
  # Subclass it and override lookup() to implement custom validation logic.

  package MyLookupValidator;
  use parent 'TUI::Validate::LookupValidator';

  sub lookup {
    my ( $self, $s ) = @_;
    # perform your lookup logic
    return $found ? true : false;
  }

=head1 DESCRIPTION

C<TLookupValidator> is an abstract base class for validators that perform
custom lookups to determine validity. It delegates L</isValid> to a L</lookup>
method that subclasses must override. The default L</lookup> returns true
unconditionally, serving as a placeholder for concrete implementations.

=head1 CONSTRUCTOR

=head2 new

Construction is inherited from L<TValidator|TUI::Validate::Validator>.

=head2 new_TLookupValidator

  my $obj = new_TLookupValidator();

Factory helper for creating a new TLookupValidator object in traditional 
I<Turbo Vision> style.

=head1 METHODS

=head2 isValid

  my $ok = $v->isValid( $s );

Delegates to L</lookup>, which subclasses must override.

=head2 lookup

  my $ok = $v->lookup( $s );

Abstract method that subclasses must override.  The default implementation in
this class returns true unconditionally; this is a placeholder for concrete
lookup validators (e.g., dictionary, enum, custom lookup table).

=head1 SEE ALSO

L<TValidator|TUI::Validate::Validator>,
L<TStringLookupValidator|TUI::Validate::StringLookupValidator>

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

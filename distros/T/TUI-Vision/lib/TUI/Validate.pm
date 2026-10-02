package TUI::Validate;
# ABSTRACT: Validation components for the TUI::Vision framework

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::Validate::Const;
use TUI::Validate::FilterValidator;
use TUI::Validate::LookupValidator;
use TUI::Validate::PXPictureValidator;
use TUI::Validate::RangeValidator;
use TUI::Validate::StringLookupValidator;
use TUI::Validate::Validator;

sub import {
  my $target = caller;
  TUI::Validate::Const->import::into( $target, qw( :all ) );
  TUI::Validate::FilterValidator->import::into( $target );
  TUI::Validate::LookupValidator->import::into( $target );
  TUI::Validate::PXPictureValidator->import::into( $target );
  TUI::Validate::RangeValidator->import::into( $target );
  TUI::Validate::StringLookupValidator->import::into( $target );
  TUI::Validate::Validator->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TUI::Validate::Const->unimport::out_of( $caller );
  TUI::Validate::FilterValidator->unimport::out_of( $caller );
  TUI::Validate::LookupValidator->unimport::out_of( $caller );
  TUI::Validate::PXPictureValidator->unimport::out_of( $caller );
  TUI::Validate::RangeValidator->unimport::out_of( $caller );
  TUI::Validate::StringLookupValidator->unimport::out_of( $caller );
  TUI::Validate::Validator->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::Validate - Validation components for the TUI::Vision framework

=head1 SYNOPSIS

  use TUI::Validate;

  # Typical validator setup flow:
  my $filter = TFilterValidator->new( validChars => '[0-9]' );
  my $range  = TRangeValidator->new( min => 1, max => 9999 );

  my $ok1 = $filter->isValid('1234');
  my $ok2 = $range->isValid('42');

=head1 DESCRIPTION

C<TUI::Validate> provides the validator layer for the L<TUI::Vision> framework.
It corresponds to Borland's I<Turbo Vision> validation subsystem and collects 
the validator base classes, concrete validators, and related constants.

Importing this module re-exports the full validator surface, including:

=over 4

=item * L<Const|TUI::Validate::Const>
Symbolic constants for validator status, options, and transfer flags.

=item * Base and generic validator classes -
L<TValidator|TUI::Validate::Validator>,
L<TFilterValidator|TUI::Validate::FilterValidator>,
L<TLookupValidator|TUI::Validate::LookupValidator>.

=item * Lookup-based validator -
L<TStringLookupValidator|TUI::Validate::StringLookupValidator>.

=item * Numeric range validator -
L<TRangeValidator|TUI::Validate::RangeValidator>.

=item * Picture-mask validator -
L<TPXPictureValidator|TUI::Validate::PXPictureValidator>.

=back

Calling C<no TUI::Validate;> forwards to the corresponding C<unimport>
implementations of these modules.

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

Contributors are documented in the POD of the respective framework modules.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut

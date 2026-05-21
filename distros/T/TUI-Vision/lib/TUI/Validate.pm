package TUI::Validate;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::Validate::Const;

sub import {
  my $target = caller;
  TUI::Validate::Const->import::into( $target, qw( :all ) );
}

sub unimport {
  my $caller = caller;
  TUI::Validate::Const->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::Validate - Validation utilities for the TUI::Vision framework

=head1 SYNOPSIS

  use TUI::Validate;

=head1 DESCRIPTION

TUI::Validate provides validation utilities for the TUI::Vision
framework.

This module is the validation-layer collector and currently re-exports
L<TUI::Validate::Const> so applications can import validator constants from
one entry point.

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

package TUI::toolkit::boolean;
# ABSTRACT: Boolean constants for Perl

use strict;
use warnings;

our $VERSION = '0.04';

use Exporter 'import';

our @EXPORT = qw(
  true
  false
);

sub true  () { !!1 }
sub false () { !!0 }

# Perl v5.36 and later have a built-in boolean type, 
# so if it's available, use it.
BEGIN {
  no strict 'refs';
  for my $sub ( @EXPORT ) {
    if ( defined &{ 'builtin::' . $sub } ) {
      no warnings;
      *$sub = \&{ 'builtin::' . $sub };
    }
  }
}

1


__END__

=pod

=head1 NAME

TUI::toolkit::boolean - boolean constants for Perl

=head1 SYNOPSIS

  use TUI::toolkit::boolean;

  if ( true ) {
    print "This is true\n";
  }

  if ( false ) {
    print "This will not print\n";
  }


=head1 DESCRIPTION

This module provides boolean constants C<true> and C<false> for use in Perl 
code. It exports these constants by default. If Perl v5.36 or later is 
available, it will use the built-in boolean type.

=head1 EXPORTS

The module exports the following constants by default:

=over

=item true

Boolean true value.

=item false

Boolean false value.

=back

=head1 SEE ALSO

L<perlfunc/true>, L<perlfunc/false>

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 LICENSE

Copyright (c) 2026 the L</AUTHOR> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

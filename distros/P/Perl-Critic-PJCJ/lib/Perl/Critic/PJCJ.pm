package Perl::Critic::PJCJ v0.1.4;

use v5.26.0;
use strict;
use warnings;

"
How could you leave me
When I needed to possess you?
I hated you, I loved you, too
"

__END__

=pod

=head1 NAME

Perl::Critic::PJCJ - Perl::Critic policies for code style consistency

=head1 VERSION

version v0.1.4

=head1 SYNOPSIS

  # In your .perlcriticrc file:
  include = Perl::Critic::PJCJ

  # Or from the command line:
  perlcritic --include Perl::Critic::PJCJ lib/

=head1 DESCRIPTION

This distribution provides Perl::Critic policies for enforcing consistent coding
practices in Perl code, including string quoting consistency and line length
limits.

=head1 POLICIES

=over 4

=item L<Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting>

Enforces consistent and optimal quoting practices through three simple rules:
reduce punctuation, prefer interpolated strings, and use bracket delimiters in
preference order.

=item L<Perl::Critic::Policy::CodeLayout::ProhibitLongLines>

Enforces a configurable maximum line length to improve code readability. Lines
that exceed the specified limit (default: 80 characters) are flagged as
violations. This helps maintain consistent formatting and readability across
different display contexts.

=back

=head1 AUTHOR

Paul Johnson C<< <paul@pjcj.net> >>

=head1 COPYRIGHT

Copyright 2025 Paul Johnson.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

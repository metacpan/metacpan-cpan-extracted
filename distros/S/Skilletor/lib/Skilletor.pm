package Skilletor;
# ABSTRACT: Retired: skilletor's Perl port; use the skilletor plugin or its install.sh

use strict;
use warnings;

our $VERSION = '0.009000';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor - Retired: skilletor's Perl port; use the skilletor plugin or its install.sh

=head1 VERSION

version 0.009000

=head1 DESCRIPTION

skilletor installs and syncs skills, agents and rules for Claude Code, Codex
and Hermes Agent from git repositories, https tarballs and local directories.
This distribution was its Perl port, and the port is retired: the distribution
holds no library and no engine any more, and its C<skilletor> command only
prints a notice that says where to go instead (L<Skilletor::CLI>).

skilletor itself goes on, as the plugin and command of
L<https://github.com/Getty/skilletor>:

=over

=item * Claude Code: C</plugin marketplace add Getty/marketplace>, then
C</plugin install skilletor@getty>.

=item * Codex: C<codex plugin marketplace add Getty/marketplace>, then
C<codex plugin add skilletor@getty>.

=item * Hermes Agent: C<hermes plugins install Getty/skilletor/hermes/skilletor --enable>;
that plugin runs the C<skilletor> command of the next item.

=item * The command line:
C<curl -fsSL https://raw.githubusercontent.com/Getty/skilletor/main/install.sh | sh>.

=back

What each needs, and the details: L<https://github.com/Getty/skilletor#install>.
The plugin reads the same F<skilletor.json> config files and keeps the same lock
files as the Perl command did, so it takes over what that command installed.
Then remove this distribution with C<cpanm --uninstall Skilletor>.

This last release of the distribution ships its modules as empty stubs, so an
upgrade replaces the earlier library code.

=head1 SEE ALSO

=over

=item * L<Skilletor::CLI>

=item * L<https://github.com/Getty/skilletor#install>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

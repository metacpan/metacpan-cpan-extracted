package Skilletor::Error::Block;
# ABSTRACT: The skilletor markers in an AGENTS.md are malformed (the reference's BlockError)

use Moo;
use namespace::clean;

extends 'Skilletor::Error';

our $VERSION = '0.008000';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Error::Block - The skilletor markers in an AGENTS.md are malformed (the reference's BlockError)

=head1 VERSION

version 0.008000

=head1 DESCRIPTION

Thrown by L<Skilletor::AgentsMD/parse_block> where the reference throws its
C<BlockError>: a C<< <!-- skilletor:begin --> >> or C<< <!-- skilletor:end -->
>> twice, one without the other, or the end before the begin.
L<Skilletor::AgentsMD/inspect_agents_md> turns it into the reason a sync
leaves the pointer alone. See L<Skilletor::Error> for the interface.

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

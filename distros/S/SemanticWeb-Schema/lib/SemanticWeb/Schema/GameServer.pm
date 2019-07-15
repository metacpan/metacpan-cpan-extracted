use utf8;

package SemanticWeb::Schema::GameServer;

# ABSTRACT: Server that provides game interaction in a multiplayer game.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'GameServer';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has game => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'game',
);



has players_online => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'playersOnline',
);



has server_status => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'serverStatus',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::GameServer - Server that provides game interaction in a multiplayer game.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

Server that provides game interaction in a multiplayer game.

=head1 ATTRIBUTES

=head2 C<game>

Video game which is played on this server.

A game should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::VideoGame']>

=back

=head2 C<players_online>

C<playersOnline>

Number of players on the server.

A players_online should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<server_status>

C<serverStatus>

Status of a game server.

A server_status should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GameServerStatus']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

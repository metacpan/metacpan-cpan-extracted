use utf8;

package SemanticWeb::Schema::SportsEvent;

# ABSTRACT: Event type: Sports event.

use Moo;

extends qw/ SemanticWeb::Schema::Event /;


use MooX::JSON_LD 'SportsEvent';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has away_team => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'awayTeam',
);



has competitor => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'competitor',
);



has home_team => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'homeTeam',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::SportsEvent - Event type: Sports event.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

Event type: Sports event.

=head1 ATTRIBUTES

=head2 C<away_team>

C<awayTeam>

The away team in a sports event.

A away_team should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SportsTeam']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<competitor>

A competitor in a sports event.

A competitor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SportsTeam']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<home_team>

C<homeTeam>

The home team in a sports event.

A home_team should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=item C<InstanceOf['SemanticWeb::Schema::SportsTeam']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Event>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

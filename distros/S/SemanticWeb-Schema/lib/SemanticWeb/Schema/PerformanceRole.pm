use utf8;

package SemanticWeb::Schema::PerformanceRole;

# ABSTRACT: A PerformanceRole is a Role that some entity places with regard to a theatrical performance

use Moo;

extends qw/ SemanticWeb::Schema::Role /;


use MooX::JSON_LD 'PerformanceRole';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has character_name => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'characterName',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PerformanceRole - A PerformanceRole is a Role that some entity places with regard to a theatrical performance

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

A PerformanceRole is a Role that some entity places with regard to a
theatrical performance, e.g. in a Movie, TVSeries etc.

=head1 ATTRIBUTES

=head2 C<character_name>

C<characterName>

The name of a character played in some acting or performing role, i.e. in a
PerformanceRole.

A character_name should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Role>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

use utf8;

package SemanticWeb::Schema::HowToSection;

# ABSTRACT: A sub-grouping of steps in the instructions for how to achieve a result (e

use Moo;

extends qw/ SemanticWeb::Schema::ListItem SemanticWeb::Schema::ItemList SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'HowToSection';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has steps => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'steps',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HowToSection - A sub-grouping of steps in the instructions for how to achieve a result (e

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A sub-grouping of steps in the instructions for how to achieve a result
(e.g. steps for making a pie crust within a pie recipe).

=head1 ATTRIBUTES

=head2 C<steps>

A single step item (as HowToStep, text, document, video, etc.) or a
HowToSection (originally misnamed 'steps'; 'step' is preferred).

A steps should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::ItemList']>

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

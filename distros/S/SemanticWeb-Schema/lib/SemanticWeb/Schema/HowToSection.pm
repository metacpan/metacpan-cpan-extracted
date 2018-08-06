package SemanticWeb::Schema::HowToSection;

# ABSTRACT: A sub-grouping of steps in the instructions for how to achieve a result (e

use Moo;

extends qw/ SemanticWeb::Schema::ItemList /;


use MooX::JSON_LD 'HowToSection';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


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

version v0.0.1

=head1 DESCRIPTION

A sub-grouping of steps in the instructions for how to achieve a result
(e.g. steps for making a pie crust within a pie recipe).

=head1 ATTRIBUTES

=head2 C<steps>

The steps in the form of a single item (text, document, video, etc.) or an
ordered list with HowToStep and/or HowToSection items.

A steps should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::ItemList']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::ItemList>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

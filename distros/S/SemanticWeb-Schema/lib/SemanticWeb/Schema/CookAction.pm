use utf8;

package SemanticWeb::Schema::CookAction;

# ABSTRACT: The act of producing/preparing food.

use Moo;

extends qw/ SemanticWeb::Schema::CreateAction /;


use MooX::JSON_LD 'CookAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has food_establishment => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'foodEstablishment',
);



has food_event => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'foodEvent',
);



has recipe => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recipe',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CookAction - The act of producing/preparing food.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

The act of producing/preparing food.

=head1 ATTRIBUTES

=head2 C<food_establishment>

C<foodEstablishment>

A sub property of location. The specific food establishment where the
action occurred.

A food_establishment should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::FoodEstablishment']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<food_event>

C<foodEvent>

A sub property of location. The specific food event where the action
occurred.

A food_event should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::FoodEvent']>

=back

=head2 C<recipe>

A sub property of instrument. The recipe/instructions used to perform the
action.

A recipe should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Recipe']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreateAction>

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

use utf8;

package SemanticWeb::Schema::ChooseAction;

# ABSTRACT: The act of expressing a preference from a set of options or a large or unbounded set of choices/options.

use Moo;

extends qw/ SemanticWeb::Schema::AssessAction /;


use MooX::JSON_LD 'ChooseAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has action_option => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'actionOption',
);



has option => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'option',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ChooseAction - The act of expressing a preference from a set of options or a large or unbounded set of choices/options.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

The act of expressing a preference from a set of options or a large or
unbounded set of choices/options.

=head1 ATTRIBUTES

=head2 C<action_option>

C<actionOption>

A sub property of object. The options subject to this action.

A action_option should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=item C<Str>

=back

=head2 C<option>

A sub property of object. The options subject to this action.

A option should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::AssessAction>

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

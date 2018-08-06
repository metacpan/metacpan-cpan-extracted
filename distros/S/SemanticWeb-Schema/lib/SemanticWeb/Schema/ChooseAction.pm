package SemanticWeb::Schema::ChooseAction;

# ABSTRACT: The act of expressing a preference from a set of options or a large or unbounded set of choices/options.

use Moo;

extends qw/ SemanticWeb::Schema::AssessAction /;


use MooX::JSON_LD 'ChooseAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


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

version v0.0.1

=head1 DESCRIPTION

The act of expressing a preference from a set of options or a large or
unbounded set of choices/options.

=head1 ATTRIBUTES

=head2 C<action_option>

C<actionOption>

A sub property of object. The options subject to this action.

A action_option should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<option>

A sub property of object. The options subject to this action.

A option should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::AssessAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

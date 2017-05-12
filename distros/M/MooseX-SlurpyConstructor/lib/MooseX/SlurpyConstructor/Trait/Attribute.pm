package MooseX::SlurpyConstructor::Trait::Attribute;

our $VERSION = '1.30';

# applied as class_metaroles => { attribute => [ __PACKAGE__ ] }.

use Moose::Role;

use namespace::autoclean;

has slurpy => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

before attach_to_class => sub {
    my ($self, $meta) = @_;

    return if not $self->slurpy;

    # TODO: test these cases

    # save the slurpy attribute in the metaclass, for quick access at
    # object construction time.

    Moose->throw_error('Attempting to use slurpy attribute \'', $self->name,
        '\' in class ', $meta->name,
        ' that does not do the MooseX::SlurpyConstructor::Trait::Class role!')
#        if not $meta->does_role('MooseX::SlurpyConstructor::Trait::Class');
        if not $meta->meta->find_attribute_by_name('slurpy_attr');

    Moose->throw_error('Attempting to use slurpy attribute ', $self->name,
        ' in class ', $meta->name,
        ' that already has a slurpy attribute (', $meta->slurpy_attr->name, ')!')
        if $meta->slurpy_attr;

    $meta->slurpy_attr($self);
};

1;

# ABSTRACT: A role to store the slurpy attribute in the metaclass

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::SlurpyConstructor::Trait::Attribute - A role to store the slurpy attribute in the metaclass

=head1 VERSION

version 1.30

=head1 DESCRIPTION

Adds the C<slurpy> attribute to attributes used in
L<MooseX::SlurpyConstructor>-aware classes, and checks that only one such
attribute is present at any time.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-SlurpyConstructor>
(or L<bug-MooseX-SlurpyConstructor@rt.cpan.org|mailto:bug-MooseX-SlurpyConstructor@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHORS

=over 4

=item *

Mark Morgan <makk384@gmail.com>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

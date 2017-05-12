package MooseX::SlurpyConstructor::Trait::Class;

our $VERSION = '1.30';

# applied as class_metaroles => { class => [ __PACKAGE__ ] }.

use Moose::Role;

use namespace::autoclean;

use B ();

around '_inline_BUILDALL' => sub {
    my $orig = shift;
    my $self = shift;

    my @source = $self->$orig();

    my @attrs = (
        '__INSTANCE__ => 1,',
        map  { B::perlstring($_) . ' => 1,' }
        grep { defined }
        map  { $_->init_arg } $self->get_all_attributes
    );

    my $slurpy_attr = $self->slurpy_attr;

    return (
        @source,
        'my %attrs = (' . ( join ' ', @attrs ) . ');',
        'my @extra = sort grep { !$attrs{$_} } keys %{ $params };',
        'if (@extra){',

        !$slurpy_attr
            ? 'Moose->throw_error("Found extra construction arguments, but there is no \'slurpy\' attribute present!");'
            : (
                'my %slurpy_values;',
                '@slurpy_values{@extra} = @{$params}{@extra};',

                '$instance->meta->slurpy_attr->set_value( $instance, \%slurpy_values );',
            ),
        '}',
    );
}
if Moose->VERSION >= 1.9900;

# quick access to the slurpy attribute
# (which holds the extra constructor arguments)
has slurpy_attr => (
    is => 'rw',
    isa => 'Maybe[Moose::Meta::Attribute]',
    weak_ref => 1,
);

# stores the location of the slurpy attribute; reader also looks up the class
# heirarchy
around slurpy_attr => sub {
    my $orig = shift;
    my $self = shift;

    # writer
    return $self->$orig(@_) if @_;

    # reader

    my $result = $self->$orig;
    return $result if $result;

    # we need to walk the inheritance tree, checking all metaclasses for
    # the one that holds a slurpy_attr with a defined value.
    my @slurpy_attr_values = map {
        my $attr = $_->meta->meta->get_attribute('slurpy_attr');
        !$attr
            ? ()
            : $attr->get_value($_->meta) || ();
    }
    $self->linearized_isa;

    foreach my $ancestor ($self->linearized_isa)
    {
        my $attr = $ancestor->meta->meta->find_attribute_by_name('slurpy_attr');
        next if not $attr;
        my $attr_value = $attr->get_value($ancestor->meta);
        return $attr_value if $attr_value;
    }

    # no slurpy_attrs found
    return;
};

# if the Object role is applied first, and then a superclass added, we just
# lost our BUILDALL modification.
after superclasses => sub
{
    my $self = shift;
    return if not @_;
    Moose::Util::MetaRole::apply_base_class_roles(
        for => $self->name,
        roles => ['MooseX::SlurpyConstructor::Role::Object'],
    )
};

1;

# ABSTRACT: A role to make immutable constructors slurpy, and add meta-information used to find slurpy attributes

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::SlurpyConstructor::Trait::Class - A role to make immutable constructors slurpy, and add meta-information used to find slurpy attributes

=head1 VERSION

version 1.30

=head1 DESCRIPTION

This role simply wraps C<_inline_BUILDALL()> (from
L<Moose::Meta::Class>) so that immutable classes have a
slurpy constructor.

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

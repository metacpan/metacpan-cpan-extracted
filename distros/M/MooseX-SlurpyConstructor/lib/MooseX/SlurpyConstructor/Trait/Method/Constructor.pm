package MooseX::SlurpyConstructor::Trait::Method::Constructor;

our $VERSION = '1.30';

# applied as class_metaroles => { constructor => [ __PACKAGE__ ] }, for Moose 1.2x

use Moose::Role;

use namespace::autoclean;

use B ();

around '_generate_BUILDALL' => sub {
    my $orig = shift;
    my $self = shift;

    my $source = $self->$orig();
    $source .= ";\n" if $source;

    my @attrs = (
        '__INSTANCE__ => 1,',
        map  { B::perlstring($_) . ' => 1,' }
        grep { defined }
        map  { $_->init_arg } @{ $self->_attributes }
    );

    my $slurpy_attr = $self->associated_metaclass->slurpy_attr;

    $source .= join('',
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

    return $source;
};

1;

# ABSTRACT: A role to make immutable constructors slurpy

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::SlurpyConstructor::Trait::Method::Constructor - A role to make immutable constructors slurpy

=head1 VERSION

version 1.30

=head1 DESCRIPTION

This role simply wraps C<_generate_BUILDALL()> (from
L<Moose::Meta::Method::Constructor>) so that immutable classes have a
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

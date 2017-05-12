package MooseX::PrivateSetters;

use strict;
use warnings;

our $VERSION = '0.08';

use Moose 0.94 ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use MooseX::PrivateSetters::Role::Attribute;

my %metaroles = (
    class_metaroles => {
        attribute => ['MooseX::PrivateSetters::Role::Attribute'],
    },
);

$metaroles{role_metaroles} = {
    applied_attribute => ['MooseX::PrivateSetters::Role::Attribute'],
} if $Moose::VERSION >= 1.9900;

Moose::Exporter->setup_import_methods(%metaroles);

1;

__END__

=pod

=head1 NAME

MooseX::PrivateSetters - Names your accessors foo() and _set_foo()

=head1 SYNOPSIS

    use Moose;
    use MooseX::PrivateSetters;

    # make some attributes

    has 'foo' => ( is => 'rw' );
    ...

    package main;

    sub bar {
        $self = shift;
        $self->_set_foo(1) unless $self->foo
    }

=head1 DESCRIPTION

This module does not provide any methods. Simply loading it changes
the default naming policy for the loading class so that accessors are
separated into get and set methods. The get methods have the same name
as the accessor, while set methods are prefixed with C<_set_>.

If you declare an attribute with a leading underscore, then the set
method will start with "_set" (i.e. C<has '_foo'> will get a setter
called C<_set_foo>. Note that if you have attributes C<foo> and
C<_foo>, they will both get a setter called C<_set_foo>, so don't do
that.

If you explicitly set a C<reader> or C<writer> name when creating
an attribute, then that attribute's naming scheme is left unchanged.

Load order of this module is important. It must be C<use>d after
L<Moose>.

=head1 SEE ALSO

There are a number of similar modules on the CPAN.

=head2 L<Moose>

The original. A single mutator method is generated with the same name
as the attribute itself.

=head2 L<MooseX::Accessors::ReadWritePrivate>

Changes the parsing of the C<is> clause, making new options
available. For example,

    has baz => ( is => 'rpwp', # private reader, private writer

gets you C<_get_baz()> and C<_set_baz>.

=head2 L<MooseX::FollowPBP>

Names accessors in the style recommended by I<Perl Best Practices>:
C<get_size> and C<set_size>.

=head2 L<MooseX::SemiAffordanceAccessor>

Has separate methods for getting and setting. The getter has the same
name as the attribute, and the setter is prefixed with C<set_>.

=head1 AUTHOR

brian greenfield C<< <briang@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-moosex-privatesetters@rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2010 brian greenfield

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

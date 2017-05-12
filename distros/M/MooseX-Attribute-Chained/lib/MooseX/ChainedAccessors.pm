#
# This file is part of MooseX-Attribute-Chained
#
# This software is copyright (c) 2017 by Tom Hukins.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MooseX::ChainedAccessors;
$MooseX::ChainedAccessors::VERSION = '1.0.3';
# ABSTRACT: DEPRECATED
use strict;
use warnings;
use Carp qw(confess);
use Try::Tiny;
use base 'Moose::Meta::Method::Accessor';

sub _generate_accessor_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return try {
        $self->_compile_code([
            'sub {',
                'if (@_ > 1) {',
                    $attr->_inline_set_value('$_[0]', '$_[1]'),
                    'return $_[0];',
                '}',
                $attr->_inline_get_value('$_[0]'),
            '}',
        ]);
    }
    catch {
        confess "Could not generate inline accessor because : $_";
    };
}

sub _generate_writer_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return try {
        $self->_compile_code([
            'sub {',
                $attr->_inline_set_value('$_[0]', '$_[1]'),
                '$_[0]',
            '}',
        ]);
    }
    catch {
        confess "Could not generate inline writer because : $_";
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::ChainedAccessors - DEPRECATED

=head1 VERSION

version 1.0.3

=head1 DESCRIPTION

Deprecated in favor of L<MooseX::Attribute::Chained>.

=head1 AUTHORS

=over 4

=item *

Tom Hukins <tom@eborcom.com>

=item *

Moritz Onken <onken@netcubed.de>

=item *

David McLaughlin <david@dmclaughlin.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom Hukins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Attribute-Chained>
or by email to L<bug-moosex-attribute-chained at
rt.cpan.org|mailto:bug-moosex-attribute-chained at rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package MooseX::Getopt::OptionTypeMap;
# ABSTRACT: Storage for the option to type mappings

our $VERSION = '0.78';

use Moose;
use Carp 'confess';
use Scalar::Util 'blessed';
use Moose::Util::TypeConstraints 'find_type_constraint';
use namespace::autoclean;

my %option_type_map = (
    'Bool'     => '!',
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
);

sub has_option_type {
    my (undef, $type_or_name) = @_;

    if (blessed($type_or_name)
        && $type_or_name->isa('Moose::Meta::TypeConstraint::Union')) {
        foreach my $union_type (@{$type_or_name->type_constraints}) {
            return 1
                if __PACKAGE__->has_option_type($union_type);
        }
        return 0;
    }

    return 1 if exists $option_type_map{blessed($type_or_name) ? $type_or_name->name : $type_or_name};

    my $current = blessed($type_or_name) ? $type_or_name : find_type_constraint($type_or_name);

    (defined $current)
        || confess "Could not find the type constraint for '$type_or_name'";

    while (my $parent = $current->parent) {
        return 1 if exists $option_type_map{$parent->name};
        $current = $parent;
    }

    return 0;
}

sub get_option_type {
    my (undef, $type_or_name) = @_;

    if (blessed($type_or_name)
        && $type_or_name->isa('Moose::Meta::TypeConstraint::Union')) {
        foreach my $union_type (@{$type_or_name->type_constraints}) {
            my $option_type = __PACKAGE__->get_option_type($union_type);
            return $option_type
                if defined $option_type;
        }
        return;
    }

    my $name = blessed($type_or_name) ? $type_or_name->name : $type_or_name;

    return $option_type_map{$name} if exists $option_type_map{$name};

    my $current = ref $type_or_name ? $type_or_name : find_type_constraint($type_or_name);

    (defined $current)
        || confess "Could not find the type constraint for '$type_or_name'";

    while ( $current = $current->parent ) {
        return $option_type_map{$current->name}
            if exists $option_type_map{$current->name};
    }

    return;
}

sub add_option_type_to_map {
    my (undef, $type_name, $option_string) = @_;
    (defined $type_name && defined $option_string)
        || confess "You must supply both a type name and an option string";

    if ( blessed($type_name) ) {
        $type_name = $type_name->name;
    } else {
        (find_type_constraint($type_name))
            || confess "The type constraint '$type_name' does not exist";
    }

    $option_type_map{$type_name} = $option_string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Getopt::OptionTypeMap - Storage for the option to type mappings

=head1 VERSION

version 0.78

=head1 DESCRIPTION

See the I<Custom Type Constraints> section in the L<MooseX::Getopt> docs
for more info about how to use this module.

=head1 METHODS

=head2 B<has_option_type ($type_or_name)>

=head2 B<get_option_type ($type_or_name)>

=head2 B<add_option_type_to_map ($type_name, $option_spec)>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Getopt>
(or L<bug-MooseX-Getopt@rt.cpan.org|mailto:bug-MooseX-Getopt@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

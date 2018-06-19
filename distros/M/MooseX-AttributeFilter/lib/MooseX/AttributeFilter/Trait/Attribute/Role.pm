package MooseX::AttributeFilter::Trait::Attribute::Role;
use 5.008009;
use strict;
use warnings;

our $VERSION = "0.09";

use Moose::Role;

has filter => (
    is  => 'ro',
    isa => 'CodeRef|Str',
    predicate => 'has_filter',
);

has bypass_filter_method_check => (
    is  => 'ro',
    isa => 'Bool',
    default => 0,
);

1;

__END__

=encoding utf-8

=head1 NAME

MooseX::AttributeFilter::Trait::Attribute::Role - trait for filtered attributes in roles

=head1 SYNOPSIS

    package My::Role;
    use Moose::Role;
    use MooseX::AttributeFilter;
    
    has field => (
        is     => 'rw',
        filter => 'filterField',
    );
    
    sub filterField {
        my $this = shift;
        return "filtered($_[0])";
    }
    
    package My::Class;
    use Moose;
    with 'My::Role';
    
    package main;
    My::Role->meta->get_attribute("field")->has_filter;  # true

=head1 DESCRIPTION

This basically does nothing but is used when a role containing filtered
attributes is composed into a class. 

=head2 Methods

It has some things for introspection tho. c:

=over

=item C<filter>

Returns the value of the C<filter> option. This may be a string (method name)
or coderef or undef.

=item C<has_filter>

Boolean.

=item C<bypass_filter_method_check>

Boolean.

=back

=head1 SEE ALSO

L<MooseX::AttributeFilter>.

=head1 LICENSE

Copyright (C) 2018 Little Princess Kitten <kitten@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

KITTEN <kitten@cpan.org>

L<https://metacpan.org/author/KITTEN>

L<https://github.com/icklekitten>

<3

=cut


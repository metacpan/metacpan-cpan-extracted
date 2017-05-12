use 5.10.1;
use strict;
use warnings;

package Moose::Meta::Attribute::Custom::Trait::Documented;

our $VERSION = '0.1003'; # VERSION
# ABSTRACT: Register the trait

sub register_implementation {
    return 'MooseX::AttributeDocumented::Meta::Attribute::Trait::Documented';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Meta::Attribute::Custom::Trait::Documented - Register the trait

=head1 VERSION

Version 0.1003, released 2015-01-18.

=head1 SOURCE

L<https://github.com/Csson/p5-MooseX-AttributeDocumented>

=head1 HOMEPAGE

L<https://metacpan.org/release/MooseX-AttributeDocumented>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson <info@code301.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

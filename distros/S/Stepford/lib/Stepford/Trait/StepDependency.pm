package Stepford::Trait::StepDependency;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.004001';

use Moose::Role;

## no critic (Subroutines::ProhibitQualifiedSubDeclarations)
sub Moose::Meta::Attribute::Custom::Trait::StepDependency::register_implementation
{
    return __PACKAGE__;
}

1;

#ABSTRACT: A trait for attributes which are a step dependency

__END__

=pod

=encoding UTF-8

=head1 NAME

Stepford::Trait::StepDependency - A trait for attributes which are a step dependency

=head1 VERSION

version 0.004001

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Stepford/issues>.

=head1 AUTHOR

Dave Rolsky <drolsky@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2017 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

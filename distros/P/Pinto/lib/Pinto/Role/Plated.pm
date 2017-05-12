# ABSTRACT: Something that has chrome plating

package Pinto::Role::Plated;

use Moose::Role;
use MooseX::MarkAsMethods ( autoclean => 1 );

#-----------------------------------------------------------------------------

our $VERSION = '0.12'; # VERSION

#-----------------------------------------------------------------------------

has chrome => (
    is       => 'ro',
    isa      => 'Pinto::Chrome',
    handles  => [qw(show diag info notice warning error)],
    required => 1,
);

#-----------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Role::Plated - Something that has chrome plating

=head1 VERSION

version 0.12

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

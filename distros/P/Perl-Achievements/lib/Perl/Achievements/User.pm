package Perl::Achievements::User;
BEGIN {
  $Perl::Achievements::User::AUTHORITY = 'cpan:YANICK';
}
{
  $Perl::Achievements::User::VERSION = '0.4.0';
}

use strict;
use warnings;

use Moose;

has name => (
    is => 'ro',
    isa => 'Str',
);

has url => (
    is => 'ro',
    isa => 'Str',
);

1;

__END__
=pod

=head1 NAME

Perl::Achievements::User

=head1 VERSION

version 0.4.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


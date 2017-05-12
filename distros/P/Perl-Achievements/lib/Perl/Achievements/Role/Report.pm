package Perl::Achievements::Role::Report;
BEGIN {
  $Perl::Achievements::Role::Report::AUTHORITY = 'cpan:YANICK';
}
{
  $Perl::Achievements::Role::Report::VERSION = '0.4.0';
}

use strict;
use warnings;

use Moose::Role;

requires qw/ generate /;

has who => (
    is => 'ro',
    isa => 'Str|Undef',
);

has history => (
    is => 'ro',
    required => 1,
);

1;

__END__
=pod

=head1 NAME

Perl::Achievements::Role::Report

=head1 VERSION

version 0.4.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


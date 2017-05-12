package Perl::Achievements::Command::report;
BEGIN {
  $Perl::Achievements::Command::report::AUTHORITY = 'cpan:YANICK';
}
{
  $Perl::Achievements::Command::report::VERSION = '0.4.0';
}
# ABSTRACT: generates a report of one's achievements

use 5.10.0;

use strict;
use warnings;


use Moose;

extends 'Perl::Achievements::Command';

sub execute {
    my ( $self ) = @_;

    print $self->generate_report( 'html' );
}

1;

__END__
=pod

=head1 NAME

Perl::Achievements::Command::report - generates a report of one's achievements

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

    perl-achievements report

=head1 DESCRIPTION

Produces a report of the glorious achievements of the user.
Currently the report is printed on STDOUT, and is in HTML.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


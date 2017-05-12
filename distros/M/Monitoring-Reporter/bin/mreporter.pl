#!/usr/bin/perl
# ABSTRACT: Monitoring::Reporter CLI
# PODNAME: mreporter.pl
use strict;
use warnings;

use Monitoring::Reporter::Cmd;

# All the magic is done using MooseX::App::Cmd, App::Cmd and MooseX::Getopt
my $mreporter = Monitoring::Reporter::Cmd::->new();
$mreporter->run();

__END__

=pod

=encoding utf-8

=head1 NAME

mreporter.pl - Monitoring::Reporter CLI

=head1 NAME

zrerpoter - Monitoring::Reporter CLI

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

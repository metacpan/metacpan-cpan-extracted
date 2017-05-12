#!/usr/bin/perl
# ABSTRACT: the monitoring spooler cli
# PODNAME: mon-spooler.pl
use strict;
use warnings;

use Monitoring::Spooler::Cmd;

# All the magic is done using MooseX::App::Cmd, App::Cmd and MooseX::Getopt
my $MonSpooler = Monitoring::Spooler::Cmd::->new();
$MonSpooler->run();

__END__

=pod

=encoding utf-8

=head1 NAME

mon-spooler.pl - the monitoring spooler cli

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

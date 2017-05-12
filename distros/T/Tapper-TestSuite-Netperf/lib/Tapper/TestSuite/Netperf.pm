package Tapper::TestSuite::Netperf;
# git description: v4.1.0-2-gaabc828

BEGIN {
  $Tapper::TestSuite::Netperf::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::TestSuite::Netperf::VERSION = '4.1.1';
}
# ABSTRACT: Tapper - Network performance measurements

use Moose;

with 'MooseX::Log::Log4perl';

1; # End of Tapper::TestSuite::Netperf



=pod

=encoding utf-8

=head1 NAME

Tapper::TestSuite::Netperf - Tapper - Network performance measurements

=head1 SYNOPSIS

You most likely want to run the frontend cmdline tool like this

  # host 1
  $ tapper-testsuite-netperf-server

  # host 2
  $ tapper-testsuite-netperf-client

=head1 DESCRIPTION

This distribution provides Tapper with Network performance measurements.

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut


__END__


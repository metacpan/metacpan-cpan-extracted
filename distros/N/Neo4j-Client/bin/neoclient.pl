#!/usr/bin/env perl
use Neo4j::Client;
use Getopt::Long;
use Pod::Usage;
use strict;
use warnings;

no warnings 'once';
my ($libs, $ccflags);
GetOptions(
  "libs|l" => \$libs,
  "cc|c" => \$ccflags,
 ) or pod2usage(1);

print join(' ', ($ccflags ? $Neo4j::Client::CCFLAGS : ()),
	   ($libs ? $Neo4j::Client::LIBS : ()));
1;

=head1 NAME

neoclient.pl - get compiler and linker options provided by Neo4j::Client

=head1 SYNOPSIS

 $ neoclient.pl [--cc] [--libs]
 
 Print compiler and/or linker flags pointing to libneo4j-client and libssl to
 stdout

=head1 SEE ALSO

L<Neo4j::Client>

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN

=cut


#!/usr/bin/perl
use strict;
use warnings;
use String::ProperCase::Surname qw{ProperCase};

my $syntax  = "$0 lastname";
my $surname = shift or die("$syntax\n");

print ProperCase($surname), "\n";

__END__

=head1 NAME

perl-String-ProperCase-Surname.pl - String::ProperCase::Surname command line script

=cut



#!/usr/bin/env perl

use 5.010;
use utf8;
use strict;
use warnings;
use Getopt::Long;
use lib '../lib';
use Nexus::REST;

my $usage = "$0 BASEURL [--q=KEYWORD] [--g=GROUPID] [--a=ARTIFACTID] [--v=VERSION] [--repositoryId=REPO]\n";
my $URL   = shift or die $usage;

my %opt;
GetOptions(\%opt, 'q=s', 'g=s', 'a=s', 'v=s', 'repositoryId=s') or die $usage;

sub get_credentials {
    my ($userenv, $passenv, %opts) = @_;

    require Term::Prompt; Term::Prompt->import();

    $opts{prompt}      ||= '';
    $opts{userhelp}    ||= '';
    $opts{passhelp}    ||= '';
    $opts{userdefault} ||= $ENV{USER};

    my $user = $ENV{$userenv} || prompt('x', "$opts{prompt} Username: ", $opts{userhelp}, $opts{userdefault});
    my $pass = $ENV{$passenv};
    unless ($pass) {
	$pass = prompt('p', "$opts{prompt} Password: ", $opts{passhelp}, '');
	print "\n";
    }

    return ($user, $pass);
}

my $nexus = Nexus::REST->new($URL, get_credentials('nexususer', 'nexuspass'));

my $search = $nexus->GET('/lucene/search', \%opt);

#use Data::Printer;
#p($search);

foreach my $artifact (@{$search->{data}}) {
    $artifact->{groupId} =~ tr:.:/:;
    say join('/', @{$artifact}{qw/groupId artifactId version/});
}

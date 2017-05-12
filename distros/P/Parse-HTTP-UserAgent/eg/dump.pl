#!/usr/bin/env perl -w
# (c) 2009 Burak Gursoy. Distributed under the Perl License.
# Enables internal pre-parsed structure dumper and then dumps
#    the parsed structure.
use strict;
use vars qw( $VERSION );
use warnings;
use lib qw( ../lib lib );
use Getopt::Long;

$VERSION = '0.11';

my $timediff;
BEGIN {
    *Parse::HTTP::UserAgent::DEBUG = sub () { 1 };
    eval {
        require Time::HiRes;
        Time::HiRes->import('time');
        $timediff = 1;
    };
}

GetOptions(\my %arg, qw(
    normalize
));

use Parse::HTTP::UserAgent;

my $opt = {};
$opt->{normalize} = ':all' if $arg{normalize};

my $str = shift || die "UserAgent?\n";

my $start = time;
my $ua    = Parse::HTTP::UserAgent->new( $str, $opt );
my $end   = time;

print $ua->dumper;
if ( $timediff ) {
    printf "\nTook %.5f seconds.\n", $end - $start;
}

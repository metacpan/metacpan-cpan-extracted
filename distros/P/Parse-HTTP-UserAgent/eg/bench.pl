#!/usr/bin/env perl
# (c) 2009 Burak Gursoy. Distributed under the Perl License.
use strict;
use warnings;
use Getopt::Long;

GetOptions(\my %opt, qw(
    count=i
    single
    timethese
));

use HTTP::BrowserDetect;
use Parse::HTTP::UserAgent;
use HTTP::DetectUserAgent;
use HTML::ParseBrowser;
use Benchmark qw( :all :hireswallclock );
use lib       qw( .. );
use constant COLUMN => q{-} x 80;

our $SILENT = 1;

my $HPB = my $ua = HTML::ParseBrowser->new;

sub html_parsebrowser     { my $ua = HTML::ParseBrowser->new(     shift ); return $ua; }
sub html_parsebrowser2    { my $ua = $HPB->Parse(                 shift ); return $ua; }
sub http_browserdetect    { my $ua = HTTP::BrowserDetect->new(    shift ); return $ua; }
sub http_detectuseragent  { my $ua = HTTP::DetectUserAgent->new(  shift ); return $ua; }
sub parse_http_useragent  { my $ua = Parse::HTTP::UserAgent->new( shift ); return $ua; }
sub parse_http_useragent2 { my $ua = Parse::HTTP::UserAgent->new( shift, {extended=>0} ); return $ua; }

do 't/db.pl';

my $count = $opt{single} ? '10000'
          : $opt{count}  ? $opt{count}
          :                '100'
          ;
my @tests = map { $_->{string} } database({ thaw => 1 });
@tests = ( $tests[ rand @tests ] ) if $opt{single};
my $total = @tests;

my $pok;

$pok = print "*** WARNING !!! --single option is in effect!\n" if $opt{single};
$pok = print <<"ATTENTION";
*** The data integrity is not checked in this run.
*** This is a benchmark for parser speeds.
*** Testing $total User Agent strings on each module with $count iterations each.

This may take a while. Please stand by ...

ATTENTION

my $start = Benchmark->new;

my $test = {
    HTML    => sub { foreach my $s (@tests) { my $ua = html_parsebrowser(     $s ) } },
    HTML2   => sub { foreach my $s (@tests) { my $ua = html_parsebrowser2(    $s ) } },
    Browser => sub { foreach my $s (@tests) { my $ua = http_browserdetect(    $s ) } },
    Detect  => sub { foreach my $s (@tests) { my $ua = http_detectuseragent(  $s ) } },
    Parse   => sub { foreach my $s (@tests) { my $ua = parse_http_useragent(  $s ) } },
    Parse2  => sub { foreach my $s (@tests) { my $ua = parse_http_useragent2( $s ) } },
};

cmpthese( $count, $test );
if ( $opt{timethese} ) {
    $pok = print COLUMN, "\n";
    timethese($count, $test );
}

my $runtime = timestr( timediff(Benchmark->new, $start) );

my $dashes = COLUMN;
$pok = print <<"GOODBYE";

$dashes

The code took: $runtime 

$dashes

List of abbreviations:

HTML      HTML::ParseBrowser v$HTML::ParseBrowser::VERSION
HTML2     HTML::ParseBrowser v$HTML::ParseBrowser::VERSION (re-use the object)
Browser   HTTP::BrowserDetect v$HTTP::BrowserDetect::VERSION
Detect    HTTP::DetectUserAgent v$HTTP::DetectUserAgent::VERSION
Parse     Parse::HTTP::UserAgent v$Parse::HTTP::UserAgent::VERSION
Parse2    Parse::HTTP::UserAgent v$Parse::HTTP::UserAgent::VERSION (without extended probe)
GOODBYE

1;

__END__

#!/usr/bin/perl
#
# Copyright (c) 2006 Peter Karman - perl@peknet.com
#
# mostly from the SWISH::API man page
# plus Search::Tools stuff
#

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use POSIX qw(locale_h);
use locale;

use Carp;
use Data::Dump qw( dump );
use SWISH::API::Object;

use Search::Tools;
use Search::Tools::UTF8;
use Getopt::Long;
use Text::Wrap;
use File::Basename;
use Time::HiRes;

binmode STDOUT, ':utf8';

my %skip       = ();                # properties to skip in output
my $debug      = 0;
my $high       = undef;
my $low        = undef;
my $property   = undef;
my $i          = 'index.swish-e';
my $maxresults = undef;
my $help       = 0;
my $col        = 20;                # width of gutter between props and text
my $script     = basename($0);
my ($charset) = (setlocale(LC_CTYPE) =~ m/^.+?\.(.+)/);
$charset ||= 'iso-8859-1';
my $interactive = 0;

my $usage = <<HELP;

    $script [opts] query
    
    $script is a Perl-based debugger for Swish-e indexes.
    
    $script will dump all properties for matches to 'query'.
    
    In addition, long properties will be snipped
    and highlighted using the Search::Tools modules.

    $script is NOT a replacement for the swish-e tool. It
    is an example of using SWISH::API::Stat and Search::Tools
    together.
    
    $script output will all be in UTF-8 regardless of how
    the properties are stored in the Swish-e index. The current
    LOCALE env settings will be applied to non UTF-8 strings when
    converting to UTF-8.
    
    Options:
    
     --index name       specify index name (default: $i)
     --debug [n]        turn on debugging
     --property propname
                        limit results by 'propname'
     --high val         with --property, set high limit
     --low  val         with --property, set low limit
     --max  n           maximum number of results to print
     --charset charset  convert properties to UTF8 from 'charset' ($charset)
     --help             print this message
     --interactive      make successive queries
     
HELP

GetOptions(
           'debug:i'     => \$debug,
           'index=s'     => \$i,
           'high=s'      => \$high,
           'low=s'       => \$low,
           'property=s'  => \$property,
           'max=i'       => \$maxresults,
           'help'        => \$help,
           'charset'     => \$charset,
           'interactive' => \$interactive,
          )
  or die $usage;

die $usage if $help;

my $trans = Search::Tools::Transliterate->new;

my $swish = open_index($i);

# ignoreWordCount not always on
#$swish->RankScheme( 1 );

if ($interactive)
{
    while (1)
    {
        print "swish> ";
        my $q = <STDIN>;
        chomp($q) if $q;
        search($q);
        print "\n";
    }

}
else
{
    die $usage unless @ARGV;

    search(join(' ', @ARGV));

}

#####################################################

sub open_index
{
    my $i     = shift;
    my $swish = SWISH::API::Object->new(indexes => "$i", log => *{STDERR});

    #my $swish = SWISH::API->new("$i");

    if ($swish->Error)
    {
        print $usage;
        $swish->AbortLastError;
    }
    return $swish;
}

sub search
{
    my $q = shift;

    my $start  = [Time::HiRes::gettimeofday()];
    my $search = $swish->New_Search_Object;

    if ($property)
    {
        $search->SetSearchLimit($property, $low, $high);
        $swish->AbortLastError if $swish->Error;
    }

    #carp dump $search;

    # then in a loop
    my $results = $search->Execute($q);

    # always check for errors (but aborting is not always necessary)

    $swish->AbortLastError
      if $swish->Error;

    # Display a list of results

    my $hits  = $results->Hits;
    my $limit = $maxresults || $hits;

    if (!$hits)
    {
        print "No Results\n";
    }
    else
    {

        print "Found $hits hits\n";
        print "Search time: ";
        printf("%0.4f sec\n",
               Time::HiRes::tv_interval($start, [Time::HiRes::gettimeofday()]));

        my $start_display = [Time::HiRes::gettimeofday()];

        my $wc  = $swish->HeaderValue($i, 'WordCharacters');
        my $igf = $swish->HeaderValue($i, 'IgnoreFirstChar') || '';
        my $igl = $swish->HeaderValue($i, 'IgnoreLastChar') || '';

        my $kwre = Search::Tools->regexp(
            debug   => $debug,
            query   => join(' ', $results->ParsedWords($i)),
            stemmer => $swish->HeaderValue($i, 'Fuzzy Mode') ne 'None'
            ? \&stem
            : undef,
            word_characters   => to_utf8($wc,  $charset),
            ignore_first_char => to_utf8($igf, $charset),
            ignore_last_char  => to_utf8($igl, $charset),
            charset           => $charset,

                                        );
        my $snipper = Search::Tools->snipper(debug => $debug, query => $kwre);

        my $hiliter = Search::Tools->hiliter(
            debug => $debug,
            query => $kwre,
            tty   => 1,
            no_html => 1,   # can screw up objects with ref values
                                            );

        my $fw = $swish->fuzzify($i, $q);

        my @fuzz = $fw->WordList;

        print "fuzzy: ", join(' ', @fuzz), "\n";

        my $stemmed = stem(undef, $q);

        print "stemmed query: $stemmed\n";

        my $count  = 0;
        my $larrow = to_utf8(chr(187));
        my $rarrow = to_utf8(chr(171));

        while (my $result = $results->NextResult)
        {
            last if ++$count > $limit;

            print "~" x 80 . "\n";

          PROP: for my $prop ($swish->props)
            {

                next PROP if exists $skip{$prop};

                my $v = $result->$prop || '';
                unless (ref $v)
                {
                    $v = to_utf8($v);
                }
                else
                {
                    $v = dump($v);
                }

                if ($prop eq 'swishlastmodified')
                {
                    $v = localtime($v);
                }
                else
                {
                    $v = $snipper->snip($v) if length($v) > 80;
                    $v = $hiliter->light($v);
                }

                # Text::Wrap has a undesirable effect of indenting on right side
                # the same amount as left, so we hack around that for prettier printing

                my $space   = ' ' x ($col - length($prop));
                my $gutter  = ' ' x $col;
                my $wrapped = wrap("", "", $v);
                $wrapped =~ s,\n,\n$gutter,g;
                print($prop, $space, $larrow, $wrapped, $rarrow, "\n");

            }

        }

        print "Render time: ";
        printf(
               "%0.4f sec\n",
               Time::HiRes::tv_interval(
                                        $start_display,
                                        [Time::HiRes::gettimeofday()]
                                       )
              );

    }

}

# this function also passed as stemmer param to S::T::KeyWords
sub stem
{
    if ($SWISH::API::VERSION < 0.04)
    {
        die "stem() requires SWISH::API version 0.04 or newer\n";
    }

    my $kwobj = shift;
    my $w     = shift;

    my $fw = $swish->Fuzzify($i, $w);

    my @fuzz = $fw->WordList;

    if (my $e = $fw->WordError)
    {

        warn "Error in Fuzzy WordList ($e): $!\n";
        return undef;

    }

    return $fuzz[0];    # we ignore possible doublemetaphone

}


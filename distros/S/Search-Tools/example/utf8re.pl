#!/usr/bin/perl

use strict;
use warnings;
use Encode;
use Search::Tools::UTF8;

my %text = (

    'latin1'           => "\xe1 abc",
    'utf8'             => "\xc3\xa1 abc",
    'utf8 w/diacritic' => "\x61\xcc\x81 abc",
    'acsii'            => "abc 123"

);

my $w_re = qr/(\w+)/;
my $u_re = qr/((\p{L}\p{M}*|[\-\_0-9])+)/;

binmode STDOUT, ':utf8';

test();

print '=' x 30, 'converting latin1 to utf8', '=' x 30, $/;

for (keys %text)
{
    if (!Encode::is_utf8($text{$_}) && !is_valid_utf8($text{$_}))
    {
        Encode::from_to($text{$_}, 'iso-8859-1', 'utf8');
    }
}

test();

sub test
{

    for my $type (sort keys %text)
    {
        my $str = $text{$type};
        print "$type\n";
        print " Encode says $str is_utf8 = " . Encode::is_utf8($str) . "\n";
        print " STT says $str valid_utf8 = " . is_valid_utf8($str) . "\n";

        # force flag
        if (is_valid_utf8($str))
        {
            Encode::_utf8_on($str);
        }

        print " now Encode says $str is_utf8 = " . Encode::is_utf8($str) . "\n";
        print " now STT says $str valid_utf8 = "
          . is_valid_utf8($str) . "\n";

        while ($str =~ m/$w_re/g)
        {
            print "  $w_re " . pos($str) . " -> $1\n";
        }

        while ($str =~ m/$u_re/g)
        {
            print "  $u_re " . pos($str) . " -> $1\n";
        }
    }

}

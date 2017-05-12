use Test::More tests => 8;
use Template;
use strict;
use warnings;
use utf8;
use Encode;

use_ok 'Template::Plugin::DumbQuotes';

my $tt = Template->new();
#my $tt = Template->new({ PLUGINS => { dq => 'Template::Plugin::DumbQuotes' }});

is tt("nothing"), "nothing";
is ttdq("bzh"), "bzh";
is ttdq("‘’"), "`'";
is ttdq("‘’"), "`'";

my $bigtest = qq/«»”“‘’\x{2014}\x{2013}«……”/;
my $bigresult = qq/""""`'--"......"/;
is ttdq($bigtest), $bigresult;
is ttdq(Encode::encode_utf8($bigtest)), $bigresult;

is ttdq("‘―‒–—’"), qq/`----'/;

sub tt {
    my $chunk = shift;
    $tt->process(\$chunk, {}, \my($out)) or die $tt->error; 
    return $out;
}

sub ttdq {
    return tt('[% USE DumbQuotes %][% |dumb_quotes %]' . shift() . '[% END %]');
}

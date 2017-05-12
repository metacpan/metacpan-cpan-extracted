#!perl

use 5.010;
use strict;
use warnings;

use Perinci::Sub::Convert::default_lang qw(convert_property_default_lang);
use Test::More 0.98;

my $oldmeta = {
    v=>1.1,
    summary => "EN",
    "summary.alt.lang.id_ID" => "ID",
    "summary.alt.lang.fr_FR" => "FR",
    args=>{a=>{default_lang=>"id_ID", summary=>"ID arg.a"},
           b=>{summary=>"EN arg.b"}},
    result=>{"description.alt.lang.id_ID"=>"ID res"},
    examples=>[{"description.alt.lang.en_US"=>"EN ex1"}],
    links=>[{},
            {"description.alt.lang.fr_FR"=>"FR link1"}],
    tags => ['test', {name=>'category', summary=>'EN t1'}],
};

my $newmeta = {
    v=>1.1,
    default_lang=>"id_ID",
    summary => "ID",
    "summary.alt.lang.en_US" => "EN",
    "summary.alt.lang.fr_FR" => "FR",
    args=>{a=>{default_lang=>"id_ID", summary=>"ID arg.a"},
           b=>{default_lang=>"id_ID", "summary.alt.lang.en_US"=>"EN arg.b"}},
    result=>{default_lang=>"id_ID", description=>"ID res"},
    examples=>[{default_lang=>"id_ID", "description.alt.lang.en_US"=>"EN ex1"}],
    links=>[{default_lang=>"id_ID"},
            {default_lang=>"id_ID", "description.alt.lang.fr_FR"=>"FR link1"}],
    tags => ['test',
             {default_lang=>'id_ID', name=>'category',
              "summary.alt.lang.en_US"=>'EN t1'}],
};

my $res = convert_property_default_lang(meta => $oldmeta, new=>'id_ID');
is_deeply($res, $newmeta)
    or diag explain $res;

DONE_TESTING:
done_testing;

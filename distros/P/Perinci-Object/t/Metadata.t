#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;

use Perinci::Object;

my $rimeta = rimeta {
    v => 1.1,
    summary => "English",
    "summary.alt.lang.id_ID" => "Bahasa",

    description => "English d",
    "description.alt.lang.id" => "Bahasa d",
};

{
    local $ENV{LANG};
    local $ENV{LANGUAGE};
    is($rimeta->langprop("summary"), "English",
       "doesn't specify default_lang -> en_US");
}

{
    local $ENV{LANG} = "en_US.UTF-8";
    local $ENV{LANGUAGE};
    is($rimeta->langprop("summary"), "English",
       "value from LANG is trimmed");
}

{
    local $ENV{LANG};
    local $ENV{LANGUAGE} = "en_US.UTF-8";
    is($rimeta->langprop("summary"), "English",
       "value from LANG is trimmed");
}

is($rimeta->langprop({lang=>"id_ID"}, "summary"), "Bahasa",
   "specify lang id_ID");

is($rimeta->langprop({lang=>"id"}, "description"), "Bahasa d",
   "specify lang id");

{
    local $ENV{LANG};
    local $ENV{LANGUAGE} = "id_ID";
    is($rimeta->langprop("summary"), "Bahasa",
       "specify lang id_ID via env LANGUAGE");
}

{
    local $ENV{LANG} = "id_ID";
    local $ENV{LANGUAGE};
    is($rimeta->langprop("summary"), "Bahasa",
       "specify lang id_ID via env LANG");
}

is($rimeta->langprop({lang=>"fr_FR"}, "summary"), "{fr_FR|en_US English}",
   "specify non-existent lang fr_FR -> default_lang + marked");

$rimeta = rimeta {
    v => 1.1,
    default_lang => "id_ID",
    description => "Ba\nhasa\n",
    "description.alt.lang.en_US" => "Eng\nlish\n",
};

{
    local $ENV{LANG};
    local $ENV{LANGUAGE};
    is($rimeta->langprop("description"), "Ba\nhasa\n",
       "default_lang id_ID");
}

is($rimeta->langprop({lang=>"id_ID"}, "description"), "Ba\nhasa\n",
   "specify lang=id_ID");
is($rimeta->langprop({lang=>"en_US"}, "description"), "Eng\nlish\n",
   "specify lang=en_US");
is($rimeta->langprop({lang=>"fr_FR"}, "description"), "{fr_FR|id_ID Ba\nhasa}\n",
   "specify non-existent lang fr_FR -> default_lang id_ID + marked");

is($rimeta->langprop({lang=>"fr_FR", mark_different_lang=>0}, "description"),
   "Ba\nhasa\n",
   "mark_different_lang=0");

subtest set => sub {
    local $ENV{LANG};
    local $ENV{LANGUAGE};

    my $rimeta = rimeta({
        v => 1.1,
        summary => "English",
    });
    $rimeta->langprop("summary", "language");
    is_deeply($$rimeta, {v=>1.1, summary=>"language"});
    $rimeta->langprop({lang=>"id_ID"}, "summary", "bahasa");
    is_deeply($$rimeta, {v=>1.1, summary=>"language",
                         "summary.alt.lang.id_ID"=>"bahasa"});
};

subtest "langprop shortcuts (summary, et al)" => sub {
    local $ENV{LANG};
    local $ENV{LANGUAGE};

    my $rimeta = rimeta({
        v => 1.1,
        name        => "n.en", "name.alt.lang.id_ID"        => "n.id",
        caption     => "c.en", "caption.alt.lang.id_ID"     => "c.id",
        summary     => "s.en", "summary.alt.lang.id_ID"     => "s.id",
        description => "d.en", "description.alt.lang.id_ID" => "d.id",
    });

    is($rimeta->name, "n.en");
    is($rimeta->name({lang=>"id_ID"}), "n.id");
    $rimeta->name("n2.en");
    is($rimeta->name, "n2.en");
    $rimeta->name({lang=>"id_ID"}, "n2.id");
    is($rimeta->name({lang=>"id_ID"}), "n2.id");

    is($rimeta->caption, "c.en");
    is($rimeta->caption({lang=>"id_ID"}), "c.id");
    $rimeta->caption("c2.en");
    is($rimeta->caption, "c2.en");
    $rimeta->caption({lang=>"id_ID"}, "c2.id");
    is($rimeta->caption({lang=>"id_ID"}), "c2.id");

    is($rimeta->summary, "s.en");
    is($rimeta->summary({lang=>"id_ID"}), "s.id");
    $rimeta->summary("s2.en");
    is($rimeta->summary, "s2.en");
    $rimeta->summary({lang=>"id_ID"}, "s2.id");
    is($rimeta->summary({lang=>"id_ID"}), "s2.id");

    is($rimeta->description, "d.en");
    is($rimeta->description({lang=>"id_ID"}), "d.id");
    $rimeta->description("d2.en");
    is($rimeta->description, "d2.en");
    $rimeta->description({lang=>"id_ID"}, "d2.id");
    is($rimeta->description({lang=>"id_ID"}), "d2.id");
};

done_testing;

#!perl

use 5.008001;

use strict;
use warnings FATAL => 'all';

use Test::More;
use Locale::TextDomain::OO;
use Locale::TextDomain::OO::Lexicon::Hash;

{
    package    #
      TestMXLTDOO;

    use Moo;
    with "MooX::Locale::TextDomain::OO";

    sub pure { shift->__("You have chosen your weapon, so fight") }

    sub mayby_plural
    {
        my $self = shift;
        [map { $self->__n("Go away", "Go away", $_) } (1 .. 2)];
    }

    sub ctx { shift->__p("Hamlet", "To be, or not to be") }
}

Locale::TextDomain::OO::Lexicon::Hash->new()->lexicon_ref(
    {
        'tlh:LC_MESSAGES:example' => [
            {
                msgid  => "",
                msgstr => "Language-Team: none\n"
                  . "Language: thl\n"
                  . "MIME-Version: 1.0\n"
                  . "Content-Type: text/plain; charset=ISO-8859-15\n"
                  . "Content-Transfer-Encoding: 8bit\n"
                  . "Plural-Forms: nplurals=2; plural=(n != 1);\n"
            },
            {
                msgid  => "You have chosen your weapon, so fight",
                msgstr => "nuHlIj DawIvpu' vaj yISuv"
            },
            {
                # __n
                msgid         => "Go away",
                msgid_plural  => "Go away",
                msgstr_plural => [
                    # in po file written as msgstr[0]
                    "naDevvo' yIghoS",
                    # in po file written as msgstr[1]
                    "naDevvo' peghoS",
                ]
            },
            {
                msgctxt => "Hamlet",
                msgid   => "To be, or not to be",
                msgstr  => "taH pagh taHbe'"
            },
        ],
        'de:LC_MESSAGES:example' => [
            {
                msgid  => "",
                msgstr => "Language-Team: none\n"
                  . "Language: de\n"
                  . "MIME-Version: 1.0\n"
                  . "Content-Type: text/plain; charset=ISO-8859-15\n"
                  . "Content-Transfer-Encoding: 8bit\n"
                  . "Plural-Forms: nplurals=2; plural=(n != 1);\n"
            },
            {
                msgid  => "You have chosen your weapon, so fight",
                msgstr => "Du hast Deine Waffen gewählt, also kämpfe"
            },
            {
                # __n
                msgid         => "Go away",
                msgid_plural  => "Go away",
                msgstr_plural => [
                    # in po file written as msgstr[0]
                    "Geh weg",
                    # in po file written as msgstr[1]
                    "Geht weg",
                ]
            },
            {
                msgctxt => "Hamlet",
                msgid   => "To be, or not to be",
                msgstr  => "Sein oder Nichtsein"
            },
        ]
    }
);

my $tmxlp = TestMXLTDOO->new();

is $tmxlp->pure, "You have chosen your weapon, so fight", "Pure passed through";
is_deeply $tmxlp->mayby_plural, ["Go away", "Go away"], "Singular and Plural passed through";
is $tmxlp->ctx, "To be, or not to be", "Ctx msg passed through";

Locale::TextDomain::OO->instance()->language("de");
Locale::TextDomain::OO->instance()->category("LC_MESSAGES");
Locale::TextDomain::OO->instance()->domain("example");

is $tmxlp->pure, "Du hast Deine Waffen gewählt, also kämpfe", "Pure passed through";
is_deeply $tmxlp->mayby_plural, ["Geh weg", "Geht weg"], "Singular and Plural passed through";
is $tmxlp->ctx, "Sein oder Nichtsein", "Ctx msg passed through";

Locale::TextDomain::OO->instance()->language("tlh");

is $tmxlp->pure, "nuHlIj DawIvpu' vaj yISuv", "Pure passed through";
is_deeply $tmxlp->mayby_plural, ["naDevvo' yIghoS", "naDevvo' peghoS"], "Singular and Plural passed through";
is $tmxlp->ctx, "taH pagh taHbe'", "Ctx msg passed through";

done_testing();

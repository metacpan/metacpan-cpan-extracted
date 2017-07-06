#!perl
use strict;
use warnings all => 'FATAL';
use FindBin '$Script';
use Test::More;
use Test::Trap;

BEGIN {
    use Module::Runtime qw(use_module);
    eval { use_module("MooX::Locale::TextDomain::OO"); }
        or plan skip_all => "This test needs MooX::Locale::TextDomain::OO";
}

{

    package t;
    use strict;
    use warnings;
    use Moo;
    use MooX::Options with_locale_textdomain_oo => 1;

    option req => (
        is            => 'ro',
        documentation => 'this is mandatory',
        format        => 's',
        required      => 1,
    );

    option neg => (
        is            => 'ro',
        negatable     => 1,
        documentation => 'this is negatable',
    );

    option paths => (
        is            => 'ro',
        repeatable    => 1,
        format        => 's',
        documentation => 'list of some paths',
    );

    1;
}

{
    use Locale::TextDomain::OO::Lexicon::Hash;

    Locale::TextDomain::OO::Lexicon::Hash->new()->lexicon_ref(
        {   'de:LC_MESSAGES:example' => [
                {   msgid  => "",
                    msgstr => "Language-Team: none\n"
                        . "Language: de\n"
                        . "MIME-Version: 1.0\n"
                        . "Content-Type: text/plain; charset=ISO-8859-15\n"
                        . "Content-Transfer-Encoding: 8bit\n"
                        . "Plural-Forms: nplurals=2; plural=(n != 1);\n"
                },
                {   msgid  => "this is mandatory",
                    msgstr => "dies ist erforderlich"
                },
                {   msgid  => "this is negatable",
                    msgstr => "dieser ist negierbar"
                },
                {   msgid  => "show a short help message",
                    msgstr => "Zeigt eine kurze Hilfe"
                },
                {   msgid  => "show a compact help message",
                    msgstr => "Zeigt eine kompakte Hilfe"
                },
                {   msgid  => "show a long help message",
                    msgstr => "Zeigt eine ausführliche Hilfe"
                },
                {   msgid  => "show the manual",
                    msgstr => "Zeigt die Anleitung"
                },
                {   msgid  => "USAGE: %s %s",
                    msgstr => "AUFRUF: %s %s"
                },
                {   msgid  => "String",
                    msgstr => "Zeichenkette"
                },
                {   msgid  => "Int",
                    msgstr => "Ganzzahl"
                },
                {   msgid  => "Ext. Int",
                    msgstr => "erw. Ganzzahl"
                },
                {   msgid  => "Real",
                    msgstr => "reelle Zahl"
                },
                {   msgid  => "[Strings]",
                    msgstr => "[Zeichenketten]"
                },
                {   msgid  => "[Ints]",
                    msgstr => "[Ganzzahlen]"
                },
                {   msgid  => "[Ext. Ints]",
                    msgstr => "[erw. Ganzzahlen]"
                },
                {   msgid  => "[Reals]",
                    msgstr => "[reelle Zahlen]"
                },
                {   msgid  => "Array of Strings",
                    msgstr => "Menge von Zeichenketten"
                },
                {   msgid  => "Array of Integers",
                    msgstr => "Menge von ganzen Zahlen"
                },
                {   msgid  => "Extended Integer",
                    msgstr => "erweiterte ganze Zahl"
                },
                {   msgid  => "Array of extended integers",
                    msgstr => "Menge von erweiterten ganzen Zahlen"
                },
                {   msgid  => "Real number",
                    msgstr => "reelle Zahl"
                },
                {   msgid  => "Array of real numbers",
                    msgstr => "Menge von reellen Zahlen"
                },
                {   msgid  => "SUB COMMANDS AVAILABLE: ",
                    msgstr => "Verfügbare Unterkommandos: "
                },
                {   msgid  => "long options ...",
                    msgstr => "ausgedehnte Parameter ..."
                },
            ]
        }
    );
}

{
    local @ARGV = ('--help');
    my $opt = trap { t->new_with_options(); };
    like( $trap->stdout,
        qr{USAGE:\s\Q$Script\E\s\[\-h\]\s\[long\soptions\s\.\.\.\]}x,
        "Usage itself" );
    like( $trap->stdout, qr{this\sis\snegatable}x, "--neg usage" );
    like( $trap->stdout, qr{this\sis\smandatory}x, "--req usage" );
    like( $trap->stdout, qr{show\sa\sshort\shelp\smessage}x,
        "--usage usage" );
    like( $trap->stdout, qr{show\sa\scompact\shelp\smessage}x, "-h usage" );
    like( $trap->stdout, qr{show\sa\slong\shelp\smessage}x, "--help usage" );
    like( $trap->stdout, qr{show\sthe\smanual}x,            "--man usage" );
}

Locale::TextDomain::OO->instance()->language("de");
Locale::TextDomain::OO->instance()->category("LC_MESSAGES");
Locale::TextDomain::OO->instance()->domain("example");

{
    local @ARGV = ('--help');
    my $opt = trap { t->new_with_options(); };
    like( $trap->stdout,
        qr{AUFRUF:\s\Q$Script\E\s\[\-h\]\s\Q[ausgedehnte Parameter ...]\E}x,
        "Usage itself" );
    like( $trap->stdout, qr{dieser\sist\snegierbar}x,    "--neg aufruf" );
    like( $trap->stdout, qr{dies\sist\serforderlich}x,   "--req aufruf" );
    like( $trap->stdout, qr{Zeigt\seine\skurze\sHilfe}x, "--usage aufruf" );
    like( $trap->stdout, qr{Zeigt\seine\skompakte\sHilfe}x, "-h aufruf" );
    like(
        $trap->stdout,
        qr{Zeigt\seine\sausführliche\sHilfe}x,
        "--help aufruf"
    );
    like( $trap->stdout, qr{Zeigt\sdie\sAnleitung}x, "--man aufruf" );
}

done_testing;

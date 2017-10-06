use warnings;
use strict;
use 5.010;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


plan tests => 2;

use PPR;

$Dios::GRAMMAR = qr{

    # Add a keyword rule to support Dios...
    (?(DEFINE)
        (?<PerlKeyword>

                class                               (?&PerlOWS)
                (?&PerlQualifiedIdentifier)         (?&PerlOWS)
            (?: is (?&PerlNWS) (?&PerlIdentifier)   (?&PerlOWS) )*+
                (?&PerlBlock)
        |
                method                              (?&PerlOWS)
                (?&PerlIdentifier)                  (?&PerlOWS)
            (?: (?&kw_balanced_parens)              (?&PerlOWS) )?+
            (?: (?&PerlAttributes)                  (?&PerlOWS) )?+
                (?&PerlBlock)
        |
                has                                 (?&PerlOWS)
            (?: (?&PerlQualifiedIdentifier)         (?&PerlOWS) )?+
                [\@\$%][.!]?(?&PerlIdentifier)      (?&PerlOWS)
            (?: (?&PerlAttributes)                  (?&PerlOWS) )?+
            (?: (?: // )?+ =                        (?&PerlOWS)
                                (?&PerlExpression)  (?&PerlOWS) )?+
            (?> ; | (?= \} ) | \z )
        )

        (?<kw_balanced_parens>
            \( (?: [^()]++ | (?&kw_balanced_parens) )*+ \)
        )
    )

    # Add all the standard PPR rules...
    $PPR::GRAMMAR
}x;

my $source_code = <<'END_CODE';
use Dios;

class Foo is Bar {
    has $.name = 'Damian';
    has Int $!ID //= gen_ID($name);
    has @.attrs;
    has %private_data = ();

    method foo ($bar, Int $baz, *@etc) { return undef; }
    method bar                         { return map { defined } @attrs; }
    method other ($name --> Str)       { uc $name; }
}

END_CODE

ok $source_code =~ m{ \A (?&PerlDocument) \Z  $Dios::GRAMMAR }x
    => 'Matched Dios code';


my $ORK_GRAMMAR = qr{

    # Add a keyword rule to support Object::Result...
    (?(DEFINE)
        (?<PerlKeyword>
            result                         (?&PerlOWS)
            \{                             (?&PerlOWS)
            (?: (?> (?&PerlIdentifier)
                |   < [[:upper:]]++ >
                )                          (?&PerlOWS)
                (?&PerlParenthesesList)?+  (?&PerlOWS)
                (?&PerlBlock)              (?&PerlOWS)
            )*+
            \}
        )
    )

    # Add all the standard PPR rules...
    $PPR::GRAMMAR
}x;

$source_code = <<'END_CODE';

    use Object::Result;

    sub foo ($config, @data) {
        my $outcome = get_outcome(@data);

        result {
            name           { $outcome->name }
            after ($date)  { grep { $_->date > $data } $outcome->list; }
            has   ($what)  { $config ~~ $what }

            <STR>          { $outcome->as_str; }
            <NUM>          { scalar $outcome->list; }
        }
    }

END_CODE

# Then parse with it...

ok $source_code =~ m{ \A (?&PerlDocument) \Z  $ORK_GRAMMAR }x
    => 'Matched Object::Result code';




done_testing();


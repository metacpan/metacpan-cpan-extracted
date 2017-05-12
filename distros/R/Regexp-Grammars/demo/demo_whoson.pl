use v5.10;
use warnings;
use strict;

use Regexp::Grammars;
use Time::HiRes qw<sleep>;

sub choose { $_[int rand @_]; }

sub agree {
    choose( "Certainly", "That's correct", "Yes",
            "Right!",    "Exactly",        "Indeed"
    );
}

our %man_on = (
    first  => "Who",
    second => "What",
    third  => "I Don't Know"
);

our %position_of = map { lc } reverse %man_on;

our @new_question = (
    "So, who's on first?",
    "I want to know: who's on first?",
    "What's the name of the first baseman?",
    "Let's start again. What's the name of the guy on first?",
    "Okay, then, who's on second?",
    "Well then, who's on third?",
    "Look, what's the name of the fellow on third?",
);

my $costello = qr{
    \A <InterpretStatement>

    <rule: InterpretStatement>
        <MATCH= InterpretAsConfirmationRequest>
      | <MATCH= InterpretAsNameRequest>
      | <MATCH= InterpretAsBaseRequest>

    <rule: InterpretAsConfirmationRequest>
            .*?  <Name>  [i']s on  <Base>
                <MATCH= (?{
                        (lc $man_on{lc $MATCH{Base}} eq lc $MATCH{Name})
                            ? agree()
                            : choose( "No, $man_on{lc $MATCH{Base}}\'s on $MATCH{Base}",
                                      "No, $MATCH{Name}'s on $position_of{lc $MATCH{Name}}"
                                    )
                            ;
                })>

        | 
            .*?  <Name> [i']s the (name of the)?  <Man>  ('s name )?on  <Base>
                <MATCH= (?{
                    (lc $man_on{lc $MATCH{Base}} eq lc $MATCH{Name})
                        ? agree()
                        : "No. \u$MATCH{Name} is on " . $position_of{lc $MATCH{Name}}
                })>

    <rule: InterpretAsBaseRequest>
            .*?  <Name>  (?:is)?
                <MATCH= (?{ "He's on " . $position_of{lc $MATCH{Name}} })>

    <rule: InterpretAsNameRequest>
            (What's the name of )?the  <Base>  baseman
                <MATCH= (?{ $man_on{lc $MATCH{Base}} })>

    <rule: Name>
        who | what | I Don't Know 

    <token: Base>
        first | second | third

    <token: Man>
        man | guy | fellow 

}ixms;

my $abbott = qr{
    \A <InterpretStatement>

    <rule: InterpretStatement>
          <MATCH= InterpretAsQuestion>
        | <MATCH= InterpretAsUnclearReferent>
        | <MATCH= InterpretAsNonSequitur>
        | <MATCH= (?{ choose(@new_question); })>

    <rule: InterpretAsQuestion>
            .*?  <Interrogative>  [i']s on  <Base>
                <MATCH= (?{
                    choose( "Yes, what is the name of the guy on $MATCH{Base}?",
                            "The $MATCH{Base} baseman?",
                            "I'm asking you! $MATCH{Interrogative}?",
                            ("I don't know!") x 2,
                    );
                })>

        | 
            .*?  <Interrogative>
                <MATCH= (?{
                    choose( "That's right, $MATCH{Interrogative}?",
                            "What?",
                            "I don't know!"
                    );
                })>

    <rule: InterpretAsUnclearReferent>
            He's on <Base>
                <MATCH= (?{
                    choose( "Who's on $MATCH{Base}?",
                            "Who is?",
                            "So, what is the name of the guy on $MATCH{Base}?",
                    );
                })>

    <rule: InterpretAsNonSequitur>
        ( Yes | Certainly | That's correct | Exactly | Right | Indeed )
            <MATCH= (?{
                choose( ("$CAPTURE, who?", "What?") x 5, @new_question );
            })>

    <token: Interrogative> 
        who | what

    <token: Base>
        first | second | third
}ixms;



my $line = "Who's on first?";

while (1)
{
    say "<abbott>    $line";
    $line = $line =~ $costello && $/{InterpretStatement};
    sleep 1.5;

    say  "<costello>  $line";
    $line = $line =~ $abbott  && $/{InterpretStatement};
    sleep 1.5;
}



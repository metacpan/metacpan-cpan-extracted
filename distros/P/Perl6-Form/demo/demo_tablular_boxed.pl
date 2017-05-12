use Perl6::Form;

my @play = ( "Othello, The Moor of Venice",
             "Richard III",
             "Hamlet, Prince of Denmark",
           );

my @name = ( "Iago",
             "Henry,\rEarl of Richmond",
             "Claudius,\rKing of Denmark",
           );

    print form
         "+-------------------------------------+",
         "| Index | Character    | Appears in   |",
         "|=====================================|",
         join(
         "|-------------------------------------|\n",
         map( { form
         "|{=][[=}| {=IIIIIIII=} | {=IIIIIIII=} |",
            $_+1,   $name[$_],     $play[$_] } 0..$#name)),
         "+-------------------------------------+";

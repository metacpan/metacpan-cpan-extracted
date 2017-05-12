use strict;
use 5.010;

use Perl6::Form;

my @last = qw(Smith Jones Wright Wong Evans McFee Ho Nuygen Willians Howlett Jones Peters Milford Tam Lam Soma Egon Wilson);
my @first = qw(Jim Jack Wendy Lee Bo Lenord Jan Dana Lindy Kyle Nora Jane Bill Woo John Mick Lazlo Jenna);
my @mid   = ("\xa0", "\xa0", 'A', "\xa0", "B", "\xa0", "\xa0", 'A', "\xa0", "B", "\xa0", "\xa0", 'A', "\xa0", "B", "\xa0", "\xa0", 'A');
my @suf   = ("") x 18;
my @nick = qw(Jim Jack Wendy Lee Bo Lenord Jan Dana Lindy Kyle Nora Jane Bill Woo John Mick Lazlo Jenna);
my @ID = 1..18;

print form
    { 
      page => { length => 15,
                number => 1,
                feed => "\f",
                footer =>            "_____________________________________________________________________\n",
                header => { first => "=====================================================================\n"
                                   . "|                   xxxxxxxxxxxxxxxxxxxxxxxxxxxx                    |\n"
                                   . "|                     xxxxxxxxxxxxxxxxxxxxxx                        |\n"
                                   . "|                                                                   |\n"
                                   . "|                          List of Players                          |\n"
                                   . "|===================================================================|\n"
                                   . "|Last                |First               |MI|Suffix|Nickname  |  ID|\n"
                                   . "|___________________________________________________________________|",
                          other =>   "=====================================================================\n"
                                   . "|                          List of Players                          |\n"
                                   . "|===================================================================|\n"
                                   . "|Last                |First               |MI|Suffix|Nickname  |  ID|\n"
                                   . "|-------------------------------------------------------------------|",
                     }
            }
    },
    "| {]]]]]]]]]]]]]]]]} | {]]]]]]]]]]]]]]]]} |{}| {II} | {]]]]]]} | {} |\n",
        \@last,              \@first,          \@mid,\@suf, \@nick,  \@ID;


// vim: set filetype=PerlPoint:

+ONCOLOR:\EMBED{lang=HTML}<span style="background-color:__c__">__body__</span>\END_EMBED

+ONBLUE:\ONCOLOR{c=blue}<__body__>

=Text Background Colors

\QST

How can I achieve colored background for some words?

\ANS

Define the following macros:

<<MAC
 +ONCOLOR:\EMBED{lang=HTML}<span style="background-color:__c__">__body__</span>\END_EMBED

 +ONBLUE:\ONCOLOR{c=blue}<__body__>
MAC

Then you can use them like: The next words appear on a red background: \\ONCOLOR{c=red}<black on red>

The result is: \ONCOLOR{c=red}<black on red>

\\ONBLUE<\\F{color=white}<white on blue>> yields: \ONBLUE<\F{color=white}<white on blue>>



\DSC

HTML does not directly support background colors for single words. Therefore we use
style sheet elements which are embeded into special tags.



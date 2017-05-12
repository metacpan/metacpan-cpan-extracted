
? flagSet(latex)

//+ONCOLOR:__body__ %%__c__

+ONCOLOR:\EMBED{lang=latex}__body__ %%__c__\END_EMBED

+ONBLUE:__body__

? flagSet(html)

+ONCOLOR:\EMBED{lang=HTML}<span style="background-color:__c__">__body__</span>\END_EMBED

+ONBLUE:\ONCOLOR{c=blue}<__body__>

? 1

=Text Background Colors

Black on red: \ONCOLOR{c=red}<black on red> is beautiful


White on blue: \ONBLUE<\F{color=white}<white on blue>> is also ok


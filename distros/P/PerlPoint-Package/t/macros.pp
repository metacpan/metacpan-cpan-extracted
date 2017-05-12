
=Macros

+RED:\FONT{color=red}<__body__>

+F:\FONT{color=__c__}<__body__>

+IB:\I<\B<__body__>>

+DEFAULTS{value1=default value2="values as set up"}:__value1__ __value2__

This \IB<text> is \RED<colored>.

+HTML:\EMBED{lang=html}

+TEXT:Macros can be used to abbreviate longer
texts as well as other tags
or tag combinations.

Macro options can be preset to contain \DEFAULTS. If you want,
you can assign \DEFAULTS{value1="up to date" value2=values}.

Tags can be \RED<\I<nested>> into macros. And \I<\RED<vice versa>>.
\IB<\F{c=blue}<This>> is formatted by nested macros.
\HTML This is <i>embedded HTML</i>\END_EMBED.

\TEXT
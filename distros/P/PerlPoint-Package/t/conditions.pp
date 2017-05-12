
=Conditions

Conditions allow to maintain all versions of a presentation in one file.

? $language eq 'German'

Bedingungen erlauben es, veschiedensprachige Versionen einer Präsentation
zusammen in einer Vorlage zu pflegen.

? 1

Back to main text.

? flagSet('flag1')

flag1 set.

? 1

? flagSet('flag2')

flag2 set.

? 1

? flagSet(qw(flag1 flag2))

flag1 or flag2 set.

? 1


$var=20

? varValue('var')<10

Variable is smaller than 10.

? 1


? varValue('var')>10

Variable is greater than 10.

? 1



=Variables


$word=word

$words=words words words

$number=17

$string1="double quotes"

$string2='single quotes'

$multiline=one line
next line
3rd line




${noAssignment}=no assignment

Text: $word.

$words at the beginning.

And these are number ($number), double ($string1) and single quoted ($string2) strings.

This was assigned in a multiline: $multiline.





Text: ${word}.

${words} at the beginning.

And these are number (${number}), double (${string1}) and single quoted (${string2}) strings.

This was assigned in a multiline: ${multiline}.





  Variables in
  a code block:
  $word, ${word}.

<<EOM

  Variables in
  a verbatim block:
  $word, ${word}.

EOM





$nondeclared ${variables}.





$value=1st

value is $value.

$value=2nd

value is $value.

$value=3rd

value is $value.




$nested1=$word $value

$nested2=$number $nested1 $number


\EMBED{lang=perl}$main::nested2;\END_EMBED


Predeclared were $VAR1 $VAR2.
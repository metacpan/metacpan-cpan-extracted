
=Cache

\TABLE{bg=blue separator="|" border=2}

Spalte 1  |  Spalte 2  | Spalte 3
xxxx      |  yyyy      |  zzzzz
uuuu      |  vvvv      |  wwwww

\END_TABLE


@|+crazy+@+colsep+|
Spalte 1  |+crazy+@+colsep+|  Spalte 2  |+crazy+@+colsep+| Spalte 3
xxxx      |+crazy+@+colsep+|  yyyy      |+crazy+@+colsep+|  zzzzz
uuuu      |+crazy+@+colsep+|  vvvv      |+crazy+@+colsep+|  wwwww

Simple: \TEST.
Guarded: \\TEST.
Sequence: \TEST\TOAST.

With body: \TOAST<toast>.
Sequence: \TEST<test>\TOAST<toast>.
Nested: \TEST<tested \TOAST<toast>>.

With parameters: \TEST{par1=p1 par2=p2}
Sequence: \TEST{t=test}\TOAST{t=toast}.

Complete: \TEST{t=test}<test>
Sequence: \TEST{t=test}<test>\TOAST{t=toast}<toast>.
Nested: \TEST{t=test}<tested \TOAST{t=toast}<toast>>.

=Tag in a \TEST<headline>

* \TEST<Tags>

# \TOAST<in>

:\FONT{color=blue}<item>: list \TEST<po\TOAST<i>nts>.

   And in
   a \TEST<block>.

<<EOM

  Tags are currently \TEST<not>
  processed in \TOAST<Verbatim blocks>.

EOM

String parameter: \TEST{t=test addr="http://www.perl.com"}<test>


This is a simple text paragraph, a single liner.

This
is
a
multi
liner,
but
still
ONE
paragraph.

Text paragraphs, once started,
 may be continued at
                                                           ANY
position of
                         subsequent lines.

A final one for now.


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




\INCLUDE{file="pfilter-code.pp" type=pp}


||numberLines||=A filtered headline



||numberLines(10)||  A
  filtered
  block.



  With a
  continuation.



||numberLines(80)||  Another
  filtered
  block.

-

  With a non filtered
  successor.



||numberLines||<<EOE
  A

  filtered

  verbatim block.

  With special characters like "\" and ">".
  All right?
EOE



||numberLines||A filtered text with special characters like "\\" and ">".



||numberLines||* A filtered bullet list point.

# A filtered ordered list point.

:A filtered definition: list point.



||numberLines||  A
  filtered
  block
  - following a filtered list.
  \I<This should work!>


\B<A Tag> starts the successor paragraph (should cause no trouble).



||numberLines||* A filtered bullet list point.

# A filtered ordered list point.

:A filtered definition: list point.



\B<A Tag> starts the successor paragraph (should cause no trouble).



=A two stream doc

This document compares two imaginary objects.

~The ignored docstream

This part shall not be made part of the document.

~The first object

Manufacturer, price, and more common data of the 1st item.

~The 2nd object

Manufacturer, price, and more common data of the 2nd item.


==Advantages

What they are good in.

~The first object

Advantages of this 1st item.

~The ignored docstream

This part shall not be made part of the document.


~The 2nd object

Advantages of this 2nd item.



==Suggestions

Talks about things to be improved.

~The first object

1st item can be improved this way.

~The 2nd object

2nd item can be improved this way.

~The ignored docstream

? 0

This part shall not be made part of the document.
Therefore the condition above should be ignored.



==Conclusion

What the editors think and suggest.

~The first object
A short summary about item 1.

~The 2nd object
A short summary about item 2.



<<CODE
 This is a verbatim block.

 Tags are not recognized here.

 Empty lines do not terminate the paragraph.
 Anything could be placed within, even if it has
 special meanings otherwhere.

 A verbatim block is structured like a "here document":
 a user declared string terminates it.

CODE


<<SECOND_VERBATIM_PARAGRAPH

Just another example. Look: verbatim text can start
at the beginning of a line! (Of course, the declared
termination string should be avoided until the real
point of completion:

SECOND_VERBATIM_PARAGRAPH
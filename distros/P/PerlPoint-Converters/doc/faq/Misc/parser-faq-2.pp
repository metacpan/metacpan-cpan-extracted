
=Line indentation in tagged examples

\QST

I used tags in an example and now it's difficult to find the correct line indentation.
The result looks like

  %hash=(
               key1 => value1,
           key2 => value2,
             );

when it should be

  %hash=(
         key1 => value1,
         key2 => value2,
        );



\ANS

Write down the complete example first as pure text and relatively indent the lines as necessary.
Add the wished tags in a second step.


\DSC

This is a common problem with markup languages and not special to PerlPoint. Tags consume
space. While this is no problem in a text dynamically wrapped, it is sometimes an issue in
example authoring: sometimes its difficult to \I<see> how the resulting lines of an example
will be indented:

<<EOE

  \PREFIX<%>\BOLD<hash>=\ITALIC<(>
          \BOLD<\YELLOW<key1>> => \GREEN<value1>,
          \BLACK<\ITALIC<key2>> => value2,
       \ITALIC<)>;

EOE

In order to simplify the task of indenting lines correctly, the "pure" example can
be indented as necessary first

  %hash=(
         key1 => value1,
         key2 => value2,
        );

and then you can add the tags you wish without modifying original indention and spaces.

<<EOE

  \PREFIX<%>\BOLD<hash>=\ITALIC<(>
         \BOLD<\YELLOW<key1>> => \GREEN<value1>,
         \BLACK<\ITALIC<key2>> => value2,
        \ITALIC<)>;

EOE



=How do I place an optionless and bodyless tag or macro before a capitalized character?

\QST

Several tags and macros require neither options nor a body. This means, they do consist of only their name
which is capitalized. If I want to place such a tag/macro before a capitalized character, PerlPoint treats the
\I<combination> of the tag/macro name and following uppercased characters as a tag name as in

  \B<\\BR> before \B<I>: \\BRI

How to separate tag name and subsequent characters?



\ANS

Use an empty variable:

  $empty=

  \\BR\B<${empty}>I



\DSC

To make writing easy, PerlPoint makes numerous assumptions about several things. One is that all uppercased characters
following a backslash are a tag or macro name if currently such a tag or macro is defined. Usually this causes no
trouble because most of all tags need options or have bodies which automatically separate tag/macro name and subsequent
strings. If neither option nor body part need to be present, the combination problem occurs.

Using a separating \I<variable> first lets the parser recognize that the tag or macro name is complete when the variable
begins. Using the variable the \I<symbolic> way separates it itself from the subsequent string (which would otherwise be
treated as part of the variable name). Using an \I<empty> variable avoids variable traces in the result, the string
(\C<"I">) immediately follows the tag result.

Please note that the variable \I<needs> to be set. An unset variable is \I<not> replaced by PerlPoint, so the result would
significantly vary from what one expected.

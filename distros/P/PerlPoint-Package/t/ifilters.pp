
// declare the filter function
\EMBED{lang=perl}

sub lang2pp
 {
  # flag variable
  my $paragraphStart=1;

  # we know that we get the lines in an array, so ...
  foreach (@_ifilterText)
   {
    # recognize empty lines which start new paragraphs
    $paragraphStart=1, next unless /\S/;

    # translate headlines
    $paragraphStart and s/^(\*+)\s*/'=' x length($1)/e and (($paragraphStart=0), next);

    # translate bullet points
    $paragraphStart and s/^-(\s+)/*$1/ and (($paragraphStart=0), next);
   }

  # supply the translated text
  @_ifilterText;
 }

\END_EMBED


=A starting headline

Now the included file:

\INCLUDE{file="ifilters.lang" ifilter=lang2pp type=pp headlinebase=CURRENT_LEVEL}

And now, we embed something in this language. \EMBED{lang=pp ifilter=lang2pp}Oops!

Another lang(usage) source!

- lang is simple

- PerlPoint is simple and powerfull

OK!

\END_EMBED

Well.




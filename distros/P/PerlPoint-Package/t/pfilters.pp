

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



||numberLines(40)||  A filtered block
  at the end of a document (no subsequent lines).
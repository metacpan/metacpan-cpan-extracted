
=Can I process DOS documents on UNIX?


\QST

I wrote a document on DOS and processed it under UNIX. It worked well till I activated
the PerlPoint parser cache. Then chapters disappeared when the document was reparsed.


\ANS

Transform the line endings by replacing \C<"\\r\\n"> by \C<"\\n">. This could be done,
for example, by a Perl one liner like

  perl -pae '\B<s/\\r\\n/\\n/>' dos.pp > unix.pp

On Solaris the \C<dos2unix> utility can be used as well. Take care to call it with
option \C<-ascii>:

  dos2unix -ascii dos.pp > unix.pp

There might be more utilities performing this job.


\DSC

While PerlPoint documents are \I<highly> portable because of their text file nature, things
become difficult when the cache is activated. The cache works on base of paragraphs and
uses Perls \I<paragraph mode> to read in complete paragraphs by one call of the \B<\C<<\>>>
operator. The paragraph is checksummed and stored then.

Well, it happens that although perl can handle line endings correctly both in program and
data files, its paragraph mode cannot. I do not call this a bug, it is well documented that
the usual behaviour is to separate paragraphs by \C</\\n{2,}/>. Unfortunately, \C<\\n> under
UNIX does \I<not> match DOS line endings of \C<\B<\\r>\\n> \I<in paragraph mode>, so the
\I<remaining file> is read in instead of \I<the next paragraph> and checksummed.

After having read in and checksummed a paragraph which does not match an already cached one,
the PerlPoint parser switches back to line reading mode and scans the paragraph line by line,
transforming it into an internal data structure. Line reading mode works fine even for DOS
files under UNIX, it is completely transparent so the paragraph is processed correctly. This
means the parser produces internal data for just this paragraph, not the remaining file.
Finally, this paragraph data is stored in the cache, together with the checksum which was
made \I<for the remaining file>.

Now when the file is processed the next time and remained unchanged, PerlPoint again invokes
paragraph mode, gets the complete file instead of a paragraph and builds a checksum. This time
there is a cache hit for this checksum! The parser restores the paragraph from cache - and
this is really only one paragraph. Then it continues reading \I<after> the "paragraph" read in
in paragraph mode, which was the remaining file, so it finds the file is parsed completely.
The result of all this is that with a cache hit only the first paragraph is restored, and
the remaining parts disappear.

To avoid this, documents need to be transformed. Use any utility you like, but take care to
\I<only> transform line endings. \C<dos2unix> on Solaris, for example, by default also
transforms special characters like umlauts, which could cause special character translation
of certain converters to fail. Thats why \C<dos2unix> is recommended to be invoked with option
\C<-ascii>.




#!inc/bin/testml-cpan

*swim.parse('Byte') == *byte
  :"Swim to ByteCode - +"

*swim.parse('HTML') == *html
  :"Swim to HTML - +"

*swim.parse('Markdown') == *markdown
  :"Swim to Markdown - +"

*swim.parse('Pod') == *pod
  :"Swim to Pod - +"


=== Implicit hyperlink
--- swim
Check out http://example.com for details.
--- html
<p>Check out <a href="http://example.com">http://example.com</a> for details.</p>
--- byte
+para
 Check out 
=hyper http://example.com
  for details.
-para
--- markdown
Check out <http://example.com> for details.
--- pod
Check out L<http://example.com> for details.

=== Explicit hyperlink
--- swim
Check out [http://example.com] for details.
--- html
<p>Check out <a href="http://example.com">http://example.com</a> for details.</p>
--- byte
+para
 Check out 
=hyper http://example.com
  for details.
-para
--- markdown
Check out <http://example.com> for details.
--- pod
Check out L<http://example.com> for details.

=== Named hyperlink
--- swim
Check out "this"[http://example.com] for details.
--- html
<p>Check out <a href="http://example.com">this</a> for details.</p>
--- byte
+para
 Check out 
+hyper http://example.com
 this
-hyper
  for details.
-para
--- markdown
Check out [this](http://example.com) for details.
--- pod
Check out L<this|http://example.com> for details.



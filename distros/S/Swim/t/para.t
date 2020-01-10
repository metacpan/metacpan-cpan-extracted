#!inc/bin/testml-cpan

*swim.parse('Byte') == *byte
  :"Swim to ByteCode - +"

*swim.parse('HTML') == *html
  :"Swim to HTML - +"

*swim.parse('Markdown') == *markdown
  :"Swim to Markdown - +"

*swim.parse('Pod') == *pod
  :"Swim to Pod - +"


=== Blank Lines
--- swim(+)


Paragraph 1


Paragraph 2



--- byte
=blank
=blank
+para
 Paragraph 1
-para
=blank
+para
 Paragraph 2
-para
=blank
=blank
--- html
<br/>

<br/>

<p>Paragraph 1</p>

<br/>

<p>Paragraph 2</p>

<br/>

<br/>
--- markdown
Paragraph 1

Paragraph 2

--- pod
Paragraph 1

Paragraph 2

# vim: set ft=txt:

#!inc/bin/testml-cpan

*swim.parse('HTML') == *html
  :"Swim to HTML - +"


=== Horizontal Rule
--- swim(<)
    foo

    ----

    bar
--- html
<p>foo</p>

<hr/>

<p>bar</p>

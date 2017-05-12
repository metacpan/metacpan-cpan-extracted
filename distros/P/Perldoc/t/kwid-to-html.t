use t::TestPerldoc tests => 1;

run_is kwid => 'html';

sub to_html {
    Perldoc->kwid_to_html(string => @_);
}

__DATA__
=== Convert Kwid to HTML
--- kwid to_html
= Intro to Kwid

This is _Kwid_!! It
really *rocks*.

* Love
* Your
* *Parser*
--- html
<body>
<h1>
Intro to Kwid
</h1>
<p>

This is _Kwid_!! It
really 
<b>
rocks
</b>
.
</p>
<p>
<li>
Love
</li>
<li>
Your
</li>
<li>
<b>
Parser
</b>
</li>
</p>
</body>


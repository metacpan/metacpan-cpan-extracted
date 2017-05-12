use lib 'lib';
use strict;
use Test::More 'no_plan';
use Spork;
my $hub = Spork->new->debug->load_hub;

my @tests = split /^%%%\n/m, join '', <DATA>;
shift @tests;
for my $test (@tests) {
    my ($wiki, $html) = split /^<><><>\n/m, $test;
    my $got_html = $hub->formatter->text_to_html($wiki);
    is($got_html, $html);
}

__END__
%%%
This is {{not *bold* and {image: foo} }}
<><><>
<p>
This is not *bold* and {image: foo} 
</p>
%%%
= Level One Header
=== Level Three Header
===== Level Five Header
======= Level Seven Header
<><><>
<h1>Level One Header</h1>
<h3>Level Three Header</h3>
<h5>Level Five Header</h5>
======= Level Seven Header
%%%
== Simple Header
<><><>
<h2>Simple Header</h2>
%%%
== Another Simple Header
<><><>
<h2>Another Simple Header</h2>
%%%
This is *bold*
<><><>
<p>
This is <strong>bold</strong>
</p>
%%%
== A *Header*
<><><>
<h2>A <strong>Header</strong></h2>
%%%
More *bold*
<><><>
<p>
More <strong>bold</strong>
</p>
%%%
Use *==* for h2s.
<><><>
<p>
Use <strong>==</strong> for h2s.
</p>
%%%
This is *bold
stuff* man
<><><>
<p>
This is <strong>bold
stuff</strong> man
</p>
%%%
Paragraph one.
<><><>
<p>
Paragraph one.
</p>
%%%
Paragraph one.

Paragraph two.
<><><>
<p>
Paragraph one.

</p>
<p>
Paragraph two.
</p>
%%%
This is *bold*

This is not
<><><>
<p>
This is <strong>bold</strong>

</p>
<p>
This is not
</p>

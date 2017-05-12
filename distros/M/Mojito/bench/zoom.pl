use Benchmark qw(:all);
use FindBin qw($Bin);
use lib "$Bin/../data";
use 5.010;

#use Mojito::Template;
use HTML::Zoom;
my $html_frag = '<section id=view_area></section>';
my $doc;
#my $zoom      = HTML::Zoom->new;
my $zoom_view = HTML::Zoom->from_html($html_frag)->select('#view_area');

my $count = 10000;
my $big_chunk =<<'EOH';
Some will argue that overloading CSS selectors to do data stuff is a terrible idea, and possibly even a step towards the "Concrete Javascript" pattern (which I abhor) or Smalltalk's Morphic (which I ignore, except for the part where it keeps reminding me of the late, great Tony Hart's plasticine friend).

To which I say, "eh", "meh", and possibly also "feh". If it really upsets you, either use extra classes for this (and remove them afterwards) or use special fake elements or, well, honestly, just use something different. Template::Semantic provides a similar idea to zoom except using XPath and XML::LibXML transforms rather than a lightweight streaming approach - maybe you'd like that better. Or maybe you really did want Template Toolkit after all. It is still damn good at what it does, after all.

So far, however, I've found that for new sites the designers I'm working with generally want to produce nice semantic HTML with classes that represent the nature of the data rather than the structure of the layout, so sharing them as a common interface works really well for us.

In the absence of any evidence that overloading CSS selectors has killed children or unexpectedly set fire to grandmothers - and given microformats have been around for a while there's been plenty of opportunity for octagenarian combustion - I'd suggest you give it a try and see if you like it.
EOH


my $result = cmpthese(
    $count,
    {
        'replace' => sub {
            $zoom_view->replace_content($big_chunk)->to_html;
        },
#        'divide'  => sub { 1.3 / 2.7 },
#        'conquer' => sub {
#            sub {
#                sub { my $goodness = rand }
#              }
#        },
    }
);

BEGIN {
 $doc =<<'EOH';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
 <head>
  <link rel="stylesheet" href="http://st.pimg.net/tucs/style.css" type="text/css" />
  <link rel="stylesheet" href="http://st.pimg.net/tucs/prettify-21072010/prettify.css" type="text/css" />
<link rel="stylesheet" href="http://st.pimg.net/tucs/print.css" type="text/css" media="print" />
  <link rel="alternate" type="application/rss+xml" title="RSS 1.0" href="http://search.cpan.org/uploads.rdf" />
  <link rel="search" href="http://st.pimg.net/tucs/opensearch.xml" type="application/opensearchdescription+xml" title="SearchCPAN" />
  <title>&#72;&#84;&#77;&#76;::&#90;&#111;&#111;&#109; - search.cpan.org</title>
 <script type="text/javascript">
    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-3528438-1']);
    _gaq.push(["_setCustomVar",2,"Distribution","HTML-Zoom",3]);
    _gaq.push(["_setCustomVar",5,"Release","HTML-Zoom-0.009003",3]);
    _gaq.push(["_setCustomVar",3,"Module","HTML::Zoom",3]);
    _gaq.push(["_setCustomVar",1,"Author","MSTROUT",3]);
    _gaq.push(['_trackPageview']);
  </script>
 </head>
 <body id="cpansearch">
<center><div class="logo"><a href="/"><img src="http://st.pimg.net/tucs/img/cpan_banner.png" alt="CPAN"></a></div></center>
<div class="menubar">
 <a href="/">Home</a>
&middot; <a href="/author/">Authors</a>
&middot; <a href="/recent">Recent</a>
&middot; <a href="http://log.perl.org/cpansearch/">News</a>
&middot; <a href="/mirror">Mirrors</a>
&middot; <a href="/faq.html">FAQ</a>
&middot; <a href="/feedback">Feedback</a>
</div>
<form method="get" action="/search" name="f" class="searchbox">
<input type="text" name="query" value="" size="35">
<br>in <select name="mode">
 <option value="all">All</option>
 <option value="module" >Modules</option>
 <option value="dist" >Distributions</option>
 <option value="author" >Authors</option>
</select>&nbsp;<input type="submit" value="CPAN Search">
</form>


 <a name="_top"></a>
  <div class=path>
<div id=permalink class="noprint"><a href="/perldoc?HTML::Zoom">permalink</a></div>
  <a href="/~mstrout/">&#77;&#97;&#116;&#116; &#83; &#84;&#114;&#111;&#117;&#116;</a> &gt;
  <a href="/~mstrout/HTML-Zoom-0.009003/">&#72;&#84;&#77;&#76;-&#90;&#111;&#111;&#109;-0.009003</a> &gt;
  &#72;&#84;&#77;&#76;::&#90;&#111;&#111;&#109;
 </div>

<div class="noprint" style="float:right;align:left;width:19ex">
<a href="http://hexten.net/cpan-faces/"><img src="http://www.gravatar.com/avatar.php?gravatar_id=4e8e2db385219e064e6dea8fbd386434&rating=G&size=80&default=http%3A%2F%2Fst.pimg.net%2Ftucs%2Fimg%2Fwho.png" width=80 height=80
style="float:right"
/></a>
<br style="clear:both"/>
<p style="text-align:right">Download:<br/> <a href="/CPAN/authors/id/M/MS/MSTROUT/HTML-Zoom-0.009003.tar.gz">HTML-Zoom-0.009003.tar.gz</a></p>
<p style="text-align:right"><a href="http://deps.cpantesters.org/?module=HTML::Zoom;perl=latest">Dependencies</a></p>
<p style="text-align:right"><a href="http://www.annocpan.org/~MSTROUT/HTML-Zoom-0.009003/lib/HTML/Zoom.pm">Annotate this POD
</a></p>

<div style="float:right">
<div class=box style='width:150px'>
<h1 class=t5>CPAN RT</h1>
<div style="margin:2px">
<table style="margin-left:auto;margin-right:auto">
<tr><td>Open&nbsp;</td><td style="text-align:right"> 0</td></tr>
</table>
<a href="https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Zoom">Report a bug</a>
</div>
</div>

</div>
</div>
  Module Version:  0.009003 &nbsp;
<span class="noprint">
  <a href="/src/MSTROUT/HTML-Zoom-0.009003/lib/HTML/Zoom.pm">Source</a> &nbsp;
</span>
<a name="___top"></a>
<div class=pod>
<div class=toc>
<div class='indexgroup'>
<ul   class='indexList indexList1'>
  <li class='indexItem indexItem1'><a href='#NAME'>NAME</a>
  <li class='indexItem indexItem1'><a href='#SYNOPSIS'>SYNOPSIS</a>
  <li class='indexItem indexItem1'><a href='#DANGER_WILL_ROBINSON'>DANGER WILL ROBINSON</a>
  <li class='indexItem indexItem1'><a href='#DESCRIPTION'>DESCRIPTION</a>
  <ul   class='indexList indexList2'>
    <li class='indexItem indexItem2'><a href='#JQUERY_ENVY'>JQUERY ENVY</a>
    <li class='indexItem indexItem2'><a href='#CLEAN_TEMPLATES'>CLEAN TEMPLATES</a>
    <li class='indexItem indexItem2'><a href='#PUTTING_THE_FUN_INTO_FUNCTIONAL'>PUTTING THE FUN INTO FUNCTIONAL</a>
    <li class='indexItem indexItem2'><a href='#LAZINESS_IS_A_VIRTUE'>LAZINESS IS A VIRTUE</a>
    <li class='indexItem indexItem2'><a href='#STOCKTON_TO_DARLINGTON_UNDER_STREAM_POWER'>STOCKTON TO DARLINGTON UNDER STREAM POWER</a>
    <li class='indexItem indexItem2'><a href='#POP!_GOES_THE_WEASEL'>POP! GOES THE WEASEL</a>
    <li class='indexItem indexItem2'><a href='#A_FISTFUL_OF_OBJECTS'>A FISTFUL OF OBJECTS</a>
    <li class='indexItem indexItem2'><a href='#SEMANTIC_DIDACTIC'>SEMANTIC DIDACTIC</a>
    <li class='indexItem indexItem2'><a href='#GET_THEE_TO_A_SUMMARY!'>GET THEE TO A SUMMARY!</a>
  </ul>
  <li class='indexItem indexItem1'><a href='#METHODS'>METHODS</a>
  <ul   class='indexList indexList2'>
    <li class='indexItem indexItem2'><a href='#new'>new</a>
    <li class='indexItem indexItem2'><a href='#zconfig'>zconfig</a>
    <li class='indexItem indexItem2'><a href='#from_html'>from_html</a>
    <li class='indexItem indexItem2'><a href='#from_file'>from_file</a>
    <li class='indexItem indexItem2'><a href='#to_stream'>to_stream</a>
    <li class='indexItem indexItem2'><a href='#to_fh'>to_fh</a>
    <li class='indexItem indexItem2'><a href='#run'>run</a>
    <li class='indexItem indexItem2'><a href='#apply'>apply</a>
    <li class='indexItem indexItem2'><a href='#to_html'>to_html</a>
    <li class='indexItem indexItem2'><a href='#memoize'>memoize</a>
    <li class='indexItem indexItem2'><a href='#with_filter'>with_filter</a>
    <li class='indexItem indexItem2'><a href='#select'>select</a>
    <li class='indexItem indexItem2'><a href='#then'>then</a>
  </ul>
  <li class='indexItem indexItem1'><a href='#AUTHORS'>AUTHORS</a>
  <li class='indexItem indexItem1'><a href='#LICENSE'>LICENSE</a>
</ul>
</div>
</div>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="NAME"
>NAME <img alt='^' src='http://st.pimg.net/tucs/img/up.gif'></a></h1>

<p>HTML::Zoom - selector based streaming template engine</p>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="SYNOPSIS"
>SYNOPSIS <img alt='^' src='http://st.pimg.net/tucs/img/up.gif'></a></h1>

<pre class="prettyprint">  use HTML::Zoom;

  my $template = &#60;&#60;HTML;
  &#60;html&#62;
    &#60;head&#62;
      &#60;title&#62;Hello people&#60;/title&#62;
    &#60;/head&#62;
    &#60;body&#62;
      &#60;h1 id=&#34;greeting&#34;&#62;Placeholder&#60;/h1&#62;
      &#60;div id=&#34;list&#34;&#62;
        &#60;span&#62;
          &#60;p&#62;Name: &#60;span class=&#34;name&#34;&#62;Bob&#60;/span&#62;&#60;/p&#62;
          &#60;p&#62;Age: &#60;span class=&#34;age&#34;&#62;23&#60;/span&#62;&#60;/p&#62;
        &#60;/span&#62;
        &#60;hr class=&#34;between&#34; /&#62;
      &#60;/div&#62;
    &#60;/body&#62;
  &#60;/html&#62;
  HTML

  my $output = HTML::Zoom
    -&#62;from_html($template)
    -&#62;select(&#39;title, #greeting&#39;)-&#62;replace_content(&#39;Hello world &#38; dog!&#39;)
    -&#62;select(&#39;#list&#39;)-&#62;repeat_content(
        [
          sub {
            $_-&#62;select(&#39;.name&#39;)-&#62;replace_content(&#39;Matt&#39;)
              -&#62;select(&#39;.age&#39;)-&#62;replace_content(&#39;26&#39;)
          },
          sub {
            $_-&#62;select(&#39;.name&#39;)-&#62;replace_content(&#39;Mark&#39;)
              -&#62;select(&#39;.age&#39;)-&#62;replace_content(&#39;0x29&#39;)
          },
          sub {
            $_-&#62;select(&#39;.name&#39;)-&#62;replace_content(&#39;Epitaph&#39;)
              -&#62;select(&#39;.age&#39;)-&#62;replace_content(&#39;&#60;redacted&#62;&#39;)
          },
        ],
        { repeat_between =&#62; &#39;.between&#39; }
      )
    -&#62;to_html;</pre>

<p>will produce:</p>

<pre class="prettyprint">  &#60;html&#62;
    &#60;head&#62;
      &#60;title&#62;Hello world &#38;amp; dog!&#60;/title&#62;
    &#60;/head&#62;
    &#60;body&#62;
      &#60;h1 id=&#34;greeting&#34;&#62;Hello world &#38;amp; dog!&#60;/h1&#62;
      &#60;div id=&#34;list&#34;&#62;
        &#60;span&#62;
          &#60;p&#62;Name: &#60;span class=&#34;name&#34;&#62;Matt&#60;/span&#62;&#60;/p&#62;
          &#60;p&#62;Age: &#60;span class=&#34;age&#34;&#62;26&#60;/span&#62;&#60;/p&#62;
        &#60;/span&#62;
        &#60;hr class=&#34;between&#34; /&#62;
        &#60;span&#62;
          &#60;p&#62;Name: &#60;span class=&#34;name&#34;&#62;Mark&#60;/span&#62;&#60;/p&#62;
          &#60;p&#62;Age: &#60;span class=&#34;age&#34;&#62;0x29&#60;/span&#62;&#60;/p&#62;
        &#60;/span&#62;
        &#60;hr class=&#34;between&#34; /&#62;
        &#60;span&#62;
          &#60;p&#62;Name: &#60;span class=&#34;name&#34;&#62;Epitaph&#60;/span&#62;&#60;/p&#62;
          &#60;p&#62;Age: &#60;span class=&#34;age&#34;&#62;&#38;lt;redacted&#38;gt;&#60;/span&#62;&#60;/p&#62;
        &#60;/span&#62;

      &#60;/div&#62;
    &#60;/body&#62;
  &#60;/html&#62;</pre>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="DANGER_WILL_ROBINSON"
>DANGER WILL ROBINSON <img alt='^' src='http://st.pimg.net/tucs/img/up.gif'></a></h1>

<p>This is a 0.9 release. That means that I&#39;m fairly happy the API isn&#39;t going to change in surprising and upsetting ways before 1.0 and a real compatibility freeze. But it also means that if it turns out there&#39;s a mistake the size of a politician&#39;s ego in the API design that I haven&#39;t spotted yet there may be a bit of breakage between here and 1.0. Hopefully not though. Appendages crossed and all that.</p>

<p>Worse still, the rest of the distribution isn&#39;t documented yet. I&#39;m sorry. I suck. But lots of people have been asking me to ship this, docs or no, so having got this class itself at least somewhat documented I figured now was a good time to cut a first real release.</p>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="DESCRIPTION"
>DESCRIPTION <img alt='^' src='http://st.pimg.net/tucs/img/up.gif'></a></h1>

<p>HTML::Zoom is a lazy, stream oriented, streaming capable, mostly functional, CSS selector based semantic templating engine for HTML and HTML-like document formats.</p>

<p>Which is, on the whole, a bit of a mouthful. So let me step back a moment and explain why you care enough to understand what I mean:</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="JQUERY_ENVY"
>JQUERY ENVY</a></h2>

<p>HTML::Zoom is the cure for JQuery envy. When your javascript guy pushes a piece of data into a document by doing:</p>

<pre class="prettyprint">  $(&#39;.username&#39;).replaceAll(username);</pre>

<p>In HTML::Zoom one can write</p>

<pre class="prettyprint">  $zoom-&#62;select(&#39;.username&#39;)-&#62;replace_content($username);</pre>

<p>which is, I hope, almost as clear, hampered only by the fact that Zoom can&#39;t assume a global document and therefore has nothing quite so simple as the $() function to get the initial selection.</p>

<p><a href="/perldoc?HTML%3A%3AZoom%3A%3ASelectorParser" class="podlinkpod"
>HTML::Zoom::SelectorParser</a> implements a subset of the JQuery selector specification, and will continue to track that rather than the W3C standards for the forseeable future on grounds of pragmatism. Also on grounds of their spec is written in EN_US rather than EN_W3C, and I read the former much better.</p>

<p>I am happy to admit that it&#39;s very, very much a subset at the moment - see the <a href="/perldoc?HTML%3A%3AZoom%3A%3ASelectorParser" class="podlinkpod"
>HTML::Zoom::SelectorParser</a> POD for what&#39;s currently there, and expect more and more to be supported over time as we need it and patch it in.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="CLEAN_TEMPLATES"
>CLEAN TEMPLATES</a></h2>

<p>HTML::Zoom is the cure for messy templates. How many times have you looked at templates like this:</p>

<pre class="prettyprint">  &#60;form action=&#34;/somewhere&#34;&#62;
  [% FOREACH field IN fields %]
    &#60;label for=&#34;[% field.id %]&#34;&#62;[% field.label %]&#60;/label&#62;
    &#60;input name=&#34;[% field.name %]&#34; type=&#34;[% field.type %]&#34; value=&#34;[% field.value %]&#34; /&#62;
  [% END %]
  &#60;/form&#62;</pre>

<p>and despaired of the fact that neither the HTML structure nor the logic are remotely easy to read? Fortunately, with HTML::Zoom we can separate the two cleanly:</p>

<pre class="prettyprint">  &#60;form class=&#34;myform&#34; action=&#34;/somewhere&#34;&#62;
    &#60;label /&#62;
    &#60;input /&#62;
  &#60;/form&#62;

  $zoom-&#62;select(&#39;.myform&#39;)-&#62;repeat_content([
    map { my $field = $_; sub {

     $_-&#62;select(&#39;label&#39;)
       -&#62;add_to_attribute( for =&#62; $field-&#62;{id} )
       -&#62;then
       -&#62;replace_content( $field-&#62;{label} )

       -&#62;select(&#39;input&#39;)
       -&#62;add_to_attribute( name =&#62; $field-&#62;{name} )
       -&#62;then
       -&#62;add_to_attribute( type =&#62; $field-&#62;{type} )
       -&#62;then
       -&#62;add_to_attribute( value =&#62; $field-&#62;{value} )

    } } @fields
  ]);</pre>

<p>This is, admittedly, very much not shorter. However, it makes it extremely clear what&#39;s happening and therefore less hassle to maintain. Especially because it allows the designer to fiddle with the HTML without cutting himself on sharp ELSE clauses, and the developer to add available data to the template without getting angle bracket cuts on sensitive parts.</p>

<p>Better still, HTML::Zoom knows that it&#39;s inserting content into HTML and can escape it for you - the example template should really have been:</p>

<pre class="prettyprint">  &#60;form action=&#34;/somewhere&#34;&#62;
  [% FOREACH field IN fields %]
    &#60;label for=&#34;[% field.id | html %]&#34;&#62;[% field.label | html %]&#60;/label&#62;
    &#60;input name=&#34;[% field.name | html %]&#34; type=&#34;[% field.type | html %]&#34; value=&#34;[% field.value | html %]&#34; /&#62;
  [% END %]
  &#60;/form&#62;</pre>

<p>and frankly I&#39;ll take slightly more code any day over *that* crawling horror.</p>

<p>(addendum: I pick on <a href="/perldoc?Template" class="podlinkpod"
>Template Toolkit</a> here specifically because it&#39;s the template system I hate the least - for text templating, I don&#39;t honestly think I&#39;ll ever like anything except the next version of Template Toolkit better - but HTML isn&#39;t text. Zoom knows that. Do you?)</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="PUTTING_THE_FUN_INTO_FUNCTIONAL"
>PUTTING THE FUN INTO FUNCTIONAL</a></h2>

<p>The principle of HTML::Zoom is to provide a reusable, functional container object that lets you build up a set of transforms to be applied; every method call you make on a zoom object returns a new object, so it&#39;s safe to do so on one somebody else gave you without worrying about altering state (with the notable exception of -&#62;next for stream objects, which I&#39;ll come to later).</p>

<p>So:</p>

<pre class="prettyprint">  my $z2 = $z1-&#62;select(&#39;.name&#39;)-&#62;replace_content($name);

  my $z3 = $z2-&#62;select(&#39;.title&#39;)-&#62;replace_content(&#39;Ms.&#39;);</pre>

<p>each time produces a new Zoom object. If you want to package up a set of transforms to re-use, HTML::Zoom provides an &#39;apply&#39; method:</p>

<pre class="prettyprint">  my $add_name = sub { $_-&#62;select(&#39;.name&#39;)-&#62;replace_content($name) };

  my $same_as_z2 = $z1-&#62;apply($add_name);</pre>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="LAZINESS_IS_A_VIRTUE"
>LAZINESS IS A VIRTUE</a></h2>

<p>HTML::Zoom does its best to defer doing anything until it&#39;s absolutely required. The only point at which it descends into state is when you force it to create a stream, directly by:</p>

<pre class="prettyprint">  my $stream = $zoom-&#62;to_stream;

  while (my $evt = $stream-&#62;next) {
    # handle zoom event here
  }</pre>

<p>or indirectly via:</p>

<pre class="prettyprint">  my $final_html = $zoom-&#62;to_html;

  my $fh = $zoom-&#62;to_fh;

  while (my $chunk = $fh-&#62;getline) {
    ...
  }</pre>

<p>Better still, the $fh returned doesn&#39;t create its stream until the first call to getline, which means that until you call that and force it to be stateful you can get back to the original stateless Zoom object via:</p>

<pre class="prettyprint">  my $zoom = $fh-&#62;to_zoom;</pre>

<p>which is exceedingly handy for filtering <a href="/perldoc?Plack" class="podlinkpod"
>Plack</a> PSGI responses, among other things.</p>

<p>Because HTML::Zoom doesn&#39;t try and evaluate everything up front, you can generally put things together in whatever order is most appropriate. This means that:</p>

<pre class="prettyprint">  my $start = HTML::Zoom-&#62;from_html($html);

  my $zoom = $start-&#62;select(&#39;div&#39;)-&#62;replace_content(&#39;THIS IS A DIV!&#39;);</pre>

<p>and:</p>

<pre class="prettyprint">  my $start = HTML::Zoom-&#62;select(&#39;div&#39;)-&#62;replace_content(&#39;THIS IS A DIV!&#39;);

  my $zoom = $start-&#62;from_html($html);</pre>

<p>will produce equivalent final $zoom objects, thus proving that there can be more than one way to do it without one of them being a <a href="/perldoc?Switch" class="podlinkpod"
>bait and switch</a>.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="STOCKTON_TO_DARLINGTON_UNDER_STREAM_POWER"
>STOCKTON TO DARLINGTON UNDER STREAM POWER</a></h2>

<p>HTML::Zoom&#39;s execution always happens in terms of streams under the hood - that is, the basic pattern for doing anything is -</p>

<pre class="prettyprint">  my $stream = get_stream_from_somewhere

  while (my ($evt) = $stream-&#62;next) {
    # do something with the event
  }</pre>

<p>More importantly, all selectors and filters are also built as stream operations, so a selector and filter pair is effectively:</p>

<pre class="prettyprint">  sub next {
    my ($self) = @_;
    my $next_evt = $self-&#62;parent_stream-&#62;next;
    if ($self-&#62;selector_matches($next_evt)) {
      return $self-&#62;apply_filter_to($next_evt);
    } else {
      return $next_evt;
    }
  }</pre>

<p>Internally, things are marginally more complicated than that, but not enough that you as a user should normally need to care.</p>

<p>In fact, an HTML::Zoom object is mostly just a container for the relevant information from which to build the final stream that does the real work. A stream built from a Zoom object is a stream of events from parsing the initial HTML, wrapped in a filter stream per selector/filter pair provided as described above.</p>

<p>The upshot of this is that the application of filters works just as well on streams as on the original Zoom object - in fact, when you run a <a href="#repeat_content" class="podlinkpod"
>&#34;repeat_content&#34;</a> operation your subroutines are applied to the stream for that element of the repeat, rather than constructing a new zoom per repeat element as well.</p>

<p>More concretely:</p>

<pre class="prettyprint">  $_-&#62;select(&#39;div&#39;)-&#62;replace_content(&#39;I AM A DIV!&#39;);</pre>

<p>works on both HTML::Zoom objects themselves and HTML::Zoom stream objects and shares sufficient of the implementation that you can generally forget the difference - barring the fact that a stream already has state attached so things like to_fh are no longer available.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="POP!_GOES_THE_WEASEL"
>POP! GOES THE WEASEL</a></h2>

<p>... and by Weasel, I mean layout.</p>

<p>HTML::Zoom&#39;s filehandle object supports an additional event key, &#39;flush&#39;, that is transparent to the rest of the system but indicates to the filehandle object to end a getline operation at that point and return the HTML so far.</p>

<p>This means that in an environment where streaming output is available, such as a number of the <a href="/perldoc?Plack" class="podlinkpod"
>Plack</a> PSGI handlers, you can add the flush key to an event in order to ensure that the HTML generated so far is flushed through to the browser right now. This can be especially useful if you know you&#39;re about to call a web service or a potentially slow database query or similar to ensure that at least the header/layout of your page renders now, improving perceived user responsiveness while your application waits around for the data it needs.</p>

<p>This is currently exposed by the &#39;flush_before&#39; option to the collect filter, which incidentally also underlies the replace and repeat filters, so to indicate we want this behaviour to happen before a query is executed we can write something like:</p>

<pre class="prettyprint">  $zoom-&#62;select(&#39;.item&#39;)-&#62;repeat(sub {
    if (my $row = $db_thing-&#62;next) {
      return sub { $_-&#62;select(&#39;.item-name&#39;)-&#62;replace_content($row-&#62;name) }
    } else {
      return
    }
  }, { flush_before =&#62; 1 });</pre>

<p>which should have the desired effect given a sufficiently lazy $db_thing (for example a <a href="/perldoc?DBIx%3A%3AClass%3A%3AResultSet" class="podlinkpod"
>DBIx::Class::ResultSet</a> object).</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="A_FISTFUL_OF_OBJECTS"
>A FISTFUL OF OBJECTS</a></h2>

<p>At the core of an HTML::Zoom system lurks an <a href="/perldoc?HTML%3A%3AZoom%3A%3AZConfig" class="podlinkpod"
>HTML::Zoom::ZConfig</a> object, whose purpose is to hang on to the various bits and pieces that things need so that there&#39;s a common way of accessing shared functionality.</p>

<p>Were I a computer scientist I would probably call this an &#34;Inversion of Control&#34; object - which you&#39;d be welcome to google to learn more about, or you can just imagine a computer scientist being suspended upside down over a pit. Either way works for me, I&#39;m a pure maths grad.</p>

<p>The ZConfig object hangs on to one each of the following for you:</p>

<ul>
<li>An HTML parser, normally <a href="/perldoc?HTML%3A%3AZoom%3A%3AParser%3A%3ABuiltIn" class="podlinkpod"
>HTML::Zoom::Parser::BuiltIn</a></li>

<li>An HTML producer (emitter), normally <a href="/perldoc?HTML%3A%3AZoom%3A%3AProducer%3A%3ABuiltIn" class="podlinkpod"
>HTML::Zoom::Producer::BuiltIn</a></li>

<li>An object to build event filters, normally <a href="/~mstrout/HTML-Zoom-0.009003/lib/HTML/Zoom/FilterBuilder.pm" class="podlinkpod"
>HTML::Zoom::FilterBuilder</a></li>

<li>An object to parse CSS selectors, normally <a href="/perldoc?HTML%3A%3AZoom%3A%3ASelectorParser" class="podlinkpod"
>HTML::Zoom::SelectorParser</a></li>

<li>An object to build streams, normally <a href="/perldoc?HTML%3A%3AZoom%3A%3AStreamUtils" class="podlinkpod"
>HTML::Zoom::StreamUtils</a></li>
</ul>

<p>In theory you could replace any of these with anything you like, but in practice you&#39;re probably best restricting yourself to subclasses, or at least things that manage to look like the original if you squint a bit.</p>

<p>If you do something more clever than that, or find yourself overriding things in your ZConfig a lot, please please tell us about it via one of the means mentioned under <a href="#SUPPORT" class="podlinkpod"
>&#34;SUPPORT&#34;</a>.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="SEMANTIC_DIDACTIC"
>SEMANTIC DIDACTIC</a></h2>

<p>Some will argue that overloading CSS selectors to do data stuff is a terrible idea, and possibly even a step towards the &#34;Concrete Javascript&#34; pattern (which I abhor) or Smalltalk&#39;s Morphic (which I ignore, except for the part where it keeps reminding me of the late, great Tony Hart&#39;s plasticine friend).</p>

<p>To which I say, &#34;eh&#34;, &#34;meh&#34;, and possibly also &#34;feh&#34;. If it really upsets you, either use extra classes for this (and remove them afterwards) or use special fake elements or, well, honestly, just use something different. <a href="/perldoc?Template%3A%3ASemantic" class="podlinkpod"
>Template::Semantic</a> provides a similar idea to zoom except using XPath and XML::LibXML transforms rather than a lightweight streaming approach - maybe you&#39;d like that better. Or maybe you really did want <a href="/perldoc?Template" class="podlinkpod"
>Template Toolkit</a> after all. It is still damn good at what it does, after all.</p>

<p>So far, however, I&#39;ve found that for new sites the designers I&#39;m working with generally want to produce nice semantic HTML with classes that represent the nature of the data rather than the structure of the layout, so sharing them as a common interface works really well for us.</p>

<p>In the absence of any evidence that overloading CSS selectors has killed children or unexpectedly set fire to grandmothers - and given microformats have been around for a while there&#39;s been plenty of opportunity for octagenarian combustion - I&#39;d suggest you give it a try and see if you like it.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="GET_THEE_TO_A_SUMMARY!"
>GET THEE TO A SUMMARY!</a></h2>

<p>Erm. Well.</p>

<p>HTML::Zoom is a lazy, stream oriented, streaming capable, mostly functional, CSS selector based semantic templating engine for HTML and HTML-like document formats.</p>

<p>But I said that already. Although hopefully by now you have some idea what I meant when I said it. If you didn&#39;t have any idea the first time. I mean, I&#39;m not trying to call you stupid or anything. Just saying that maybe it wasn&#39;t totally obvious without the explanation. Or something.</p>

<p>Er.</p>

<p>Maybe we should just move on to the method docs.</p>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="METHODS"
>METHODS <img alt='^' src='http://st.pimg.net/tucs/img/up.gif'></a></h1>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="new"
>new</a></h2>

<pre class="prettyprint">  my $zoom = HTML::Zoom-&#62;new;

  my $zoom = HTML::Zoom-&#62;new({ zconfig =&#62; $zconfig });</pre>

<p>Create a new empty Zoom object. You can optionally pass an <a href="/perldoc?HTML%3A%3AZoom%3A%3AZConfig" class="podlinkpod"
>HTML::Zoom::ZConfig</a> instance if you&#39;re trying to override one or more of the default components.</p>

<p>This method isn&#39;t often used directly since several other methods can also act as constructors, notable <a href="#select" class="podlinkpod"
>&#34;select&#34;</a> and <a href="#from_html" class="podlinkpod"
>&#34;from_html&#34;</a></p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="zconfig"
>zconfig</a></h2>
<section id=view_area></section>
<pre class="prettyprint">  my $zconfig = $zoom-&#62;zconfig;</pre>

<p>Retrieve the <a href="/perldoc?HTML%3A%3AZoom%3A%3AZConfig" class="podlinkpod"
>HTML::Zoom::ZConfig</a> instance used by this Zoom object. You shouldn&#39;t usually need to call this yourself.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="from_html"
>from_html</a></h2>

<pre class="prettyprint">  my $zoom = HTML::Zoom-&#62;from_html($html);

  my $z2 = $z1-&#62;from_html($html);</pre>

<p>Parses the HTML using the current zconfig&#39;s parser object and returns a new zoom instance with that as the source HTML to be transformed.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="from_file"
>from_file</a></h2>

<pre class="prettyprint">  my $zoom = HTML::Zoom-&#62;from_file($file);

  my $z2 = $z1-&#62;from_file($file);</pre>

<p>Convenience method - slurps the contents of $file and calls from_html with it.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="to_stream"
>to_stream</a></h2>

<pre class="prettyprint">  my $stream = $zoom-&#62;to_stream;

  while (my ($evt) = $stream-&#62;next) {
    ...</pre>

<p>Creates a stream, starting with a stream of the events from the HTML supplied via <a href="#from_html" class="podlinkpod"
>&#34;from_html&#34;</a> and then wrapping it in turn with each selector+filter pair that have been applied to the zoom object.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="to_fh"
>to_fh</a></h2>

<pre class="prettyprint">  my $fh = $zoom-&#62;to_fh;

  call_something_expecting_a_filehandle($fh);</pre>

<p>Returns an <a href="/perldoc?HTML%3A%3AZoom%3A%3AReadFH" class="podlinkpod"
>HTML::Zoom::ReadFH</a> instance that will create a stream the first time its getline method is called and then return all HTML up to the next event with &#39;flush&#39; set.</p>

<p>You can pass this filehandle to compliant PSGI handlers (and probably most web frameworks).</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="run"
>run</a></h2>

<pre class="prettyprint">  $zoom-&#62;run;</pre>

<p>Runs the zoom object&#39;s transforms without doing anything with the results.</p>

<p>Normally used to get side effects of a zoom run - for example when using <a href="/~mstrout/HTML-Zoom-0.009003/lib/HTML/Zoom/FilterBuilder.pm#collect" class="podlinkpod"
>&#34;collect&#34; in HTML::Zoom::FilterBuilder</a> to slurp events for scraping or layout.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="apply"
>apply</a></h2>

<pre class="prettyprint">  my $z2 = $z1-&#62;apply(sub {
    $_-&#62;select(&#39;div&#39;)-&#62;replace_content(&#39;I AM A DIV!&#39;) })
  });</pre>

<p>Sets $_ to the zoom object and then runs the provided code. Basically syntax sugar, the following is entirely equivalent:</p>

<pre class="prettyprint">  my $sub = sub {
    shift-&#62;select(&#39;div&#39;)-&#62;replace_content(&#39;I AM A DIV!&#39;) })
  };

  my $z2 = $sub-&#62;($z1);</pre>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="to_html"
>to_html</a></h2>

<pre class="prettyprint">  my $html = $zoom-&#62;to_html;</pre>

<p>Runs the zoom processing and returns the resulting HTML.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="memoize"
>memoize</a></h2>

<pre class="prettyprint">  my $z2 = $z1-&#62;memoize;</pre>

<p>Creates a new zoom whose source HTML is the results of the original zoom&#39;s processing. Effectively syntax sugar for:</p>

<pre class="prettyprint">  my $z2 = HTML::Zoom-&#62;from_html($z1-&#62;to_html);</pre>

<p>but preserves your <a href="/perldoc?HTML%3A%3AZoom%3A%3AZConfig" class="podlinkpod"
>HTML::Zoom::ZConfig</a> object.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="with_filter"
>with_filter</a></h2>

<pre class="prettyprint">  my $zoom = HTML::Zoom-&#62;with_filter(
    &#39;div&#39;, $filter_builder-&#62;replace_content(&#39;I AM A DIV!&#39;)
  );

  my $z2 = $z1-&#62;with_filter(
    &#39;div&#39;, $filter_builder-&#62;replace_content(&#39;I AM A DIV!&#39;)
  );</pre>

<p>Lower level interface than <a href="#select" class="podlinkpod"
>&#34;select&#34;</a> to adding filters to your zoom object.</p>

<p>In normal usage, you probably don&#39;t need to call this yourself.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="select"
>select</a></h2>

<pre class="prettyprint">  my $zoom = HTML::Zoom-&#62;select(&#39;div&#39;)-&#62;replace_content(&#39;I AM A DIV!&#39;);

  my $z2 = $z1-&#62;select(&#39;div&#39;)-&#62;replace_content(&#39;I AM A DIV!&#39;);</pre>

<p>Returns an intermediary object of the class <a href="/perldoc?HTML%3A%3AZoom%3A%3ATransformBuilder" class="podlinkpod"
>HTML::Zoom::TransformBuilder</a> on which methods of your <a href="/~mstrout/HTML-Zoom-0.009003/lib/HTML/Zoom/FilterBuilder.pm" class="podlinkpod"
>HTML::Zoom::FilterBuilder</a> object can be called.</p>

<p>In normal usage you should generally always put the pair of method calls together; the intermediary object isn&#39;t designed or expected to stick around.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="then"
>then</a></h2>

<pre class="prettyprint">  my $z2 = $z1-&#62;select(&#39;div&#39;)-&#62;add_to_attribute(class =&#62; &#39;spoon&#39;)
                             -&#62;then
                             -&#62;replace_content(&#39;I AM A DIV!&#39;);</pre>

<p>Re-runs the previous select to allow you to chain actions together on the same selector.</p>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="AUTHORS"
>AUTHORS <img alt='^' src='http://st.pimg.net/tucs/img/up.gif'></a></h1>

<ul>
<li>Matt S. Trout</li>
</ul>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="LICENSE"
>LICENSE <img alt='^' src='http://st.pimg.net/tucs/img/up.gif'></a></h1>

<p>This library is free software, you can redistribute it and/or modify it under the same terms as Perl itself.</p>

</div>


<div class="footer"><div class="cpanstats">64732 Uploads, 21949 Distributions
90161 Modules, 8757 Uploaders
</div>
hosted by <a href="http://www.weblocal.ca">weblocal.ca</a><br/>
<a href="http://www.weblocal.ca"><img alt="Find. Rate. Share." src="http://st.pimg.net/tucs/img/weblocal_logo.gif"></a>
</div>
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript" src="http://ipv4.v6test.develooper.com/cdn/libs/jquery/1.4.2/jquery.min.js"></script>
<script type="text/javascript" src="http://ipv4.v6test.develooper.com/js/v1/v6test.js"></script>
<script type="text/javascript" src="http://st.pimg.net/tucs/jquery-cookie-67fb34f6a.min.js"></script>
<script type="text/javascript" src="http://st.pimg.net/tucs/prettify-21072010/prettify.js"></script>

<script type="text/javascript">
   // v6.target = '';
   if (!v6.target) { v6.only_once = true }
   v6.site = '7A0D89A6-2B82-11DF-B9DA-F61CBD13F020';
   v6.api_server = 'http://ipv4.v6test.develooper.com';
   try {
     v6.test();
   } catch(err) {}
</script>
<script type="text/javascript">
  $(document).ready(function(){
    $("a[href^=http:]").click(function(){
      var href = $(this).attr('href');
      var m = href.match('\/\/([^\/:]+)');
      _gaq.push(['_trackEvent','External',m[1],'Module']);
    });
    $("a[href^=/CPAN/]").click(function(){
      var href = $(this).attr('href');
      _gaq.push(['_trackEvent','Download',href,'Module']);
    });

    if ($.cookie("pretty")) {
      prettyPrint();
    }
  });
</script>
<!-- Tue Feb  8 20:27:11 2011 GMT (0.0599460601806641) @cpansearch1 -->
 </body>
</html>
EOH

}
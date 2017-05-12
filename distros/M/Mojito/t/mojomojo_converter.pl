use strictures 1;
use Test::More;
use Mojito::Filter::MojoMojo::Converter;
use 5.010;

my $content =<<'END_HTML';
<pre lang="Perl">
use Me;
say "Please";
</pre>
and then there was more
<pre lang="SQL">
SELECT * FROM table;
</pre>
END_HTML

my $mm_converter = Mojito::Filter::MojoMojo::Converter->new( content => $content );
$mm_converter->convert_content;
like($mm_converter->content, qr/<pre class="prettyprint">.*?<\/pre>/si, 'convert hightlight pre');

done_testing();

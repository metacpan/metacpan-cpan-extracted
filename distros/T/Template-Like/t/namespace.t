use Test::More tests => 2;

BEGIN { use_ok('Template::Like') };

my $params = { hoge => 'foo' };
my $t = Template::Like->new( NAMESPACE => { "CGI" => { params => $params } } );
my $input  = "[% CGI.params.hoge %]";
my $result = "foo";
my $output;
$t->process(\$input, {}, \$output);
is($result, $output, $input);


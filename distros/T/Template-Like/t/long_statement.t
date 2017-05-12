use Test::More tests => 2;

#BEGIN { use_ok('Template') };
BEGIN { use_ok('Template::Like') };

#my $t = Template->new();
my $t = Template::Like->new();

my $input_scalarref = q{[% hoge.foo.set(bar.baz).get + bar.baz | add(bar.baz) | add(hoge.foo.set(bar.baz).get);bar.baz %]};

my $result = q{123};

my $output1;

#$t = Template->new( DEBUG => 1, FILTERS => { add => [ sub { my ($c,$arg) = @_;return sub { return $_[0] + $arg } }, 1 ] } );
$t = Template::Like->new( DEBUG => 0, FILTERS => { add => sub { return $_[0] + $_[1] } } );

$t->process(\$input_scalarref, { hoge => { foo => TEST_OBJ->new(0) }, bar => { baz => 3 } }, \$output1);

is($result, $output1, "long_statement");

{
  package TEST_OBJ;
  
  sub new {
    my $class = shift;
    my $value = shift;
    bless { value => $value }, $class;
  }
  
  sub set {
    $_[0]->{'value'} = $_[1];
    return $_[0];
  }
  
  sub get {
    return shift->{'value'};
  }
}

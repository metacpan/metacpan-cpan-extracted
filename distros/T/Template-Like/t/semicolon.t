use Test::More tests => 2;

#BEGIN { use_ok('Template') };
BEGIN { use_ok('Template::Like') };

#my $t = Template->new();
my $t = Template::Like->new();

my $input_scalarref = q{
[% GET hoge.foo; hoge.foo %]
[% SET hoge.foo = 2; hoge.foo %]
[% CALL hoge.foo; hoge.foo %]
[% IF hoge.foo == 2; 'tr;ue' %]
true
[% END; 'some' %]
[% FOREACH foo IN hoge.foos; 'tr;ue';baz = foo %]
[% foo; baz %]
[% END; 'some' %]
};

my $result = q{
33
2
2
tr;ue
true
some
tr;ue
44
tr;ue
44
tr;ue
44
some
};

my $output1;

#$t = Template->new( DEBUG => 0, FILTERS => { add => [ sub { my ($c,$arg) = @_;return sub { return $_[0] + $arg } }, 1 ] } );
$t = Template::Like->new( DEBUG => 0, FILTERS => { add => sub { return $_[0] + $_[1] } } );

$t->process(\$input_scalarref, { hoge => { foo => 3, foos => [ 4, 4, 4 ] } }, \$output1);

is($result, $output1, "semicolon");

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

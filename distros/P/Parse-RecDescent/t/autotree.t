use Parse::RecDescent;
use Test::More tests=>9;

foreach my $base ('',
                  ':BaseModule',
                  ':BaseModule::',
              ) {
    my $grammar = "<autotree$base>" . q {
file    : command(s)
command : get | set | vet
get : 'get' ident ';'
set : 'set' ident 'to' value ';'
vet : 'check' ident 'is' value ';'
ident   : /\w+/
value   : /\d+/
};


    my $parser = new Parse::RecDescent($grammar) or die "Bad Grammar";
    pass('created autotree grammar');

    my $text = q{
set a to 3;
get b;
check a is 3;
set c to 4;
check b is 0;
};

    my $tree = $parser->file($text);
    ok $tree, 'parsed input text';
    use Data::Dumper;

    my $package = $base;
    $package =~ s/^:*//;
    $package =~ s/:*$//;
    $package .= '::' if length $package;
    ok("${package}file" eq ref $tree, qq{got "$base" as "$package"});
}



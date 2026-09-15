use strict;
use warnings;
use Test::More;
use Package::Prototype;
BEGIN { plan skip_all => 'named parameters require Perl 5.44' if $] < 5.044 }
my $ok = eval q{
    use feature 'signatures';
    no warnings 'experimental::signature_named_parameters';
    my $greet = sub ($self, :$name, :$suffix = '!') { "$name$suffix" };
    my $obj = Package::Prototype->bless({ greet => $greet });
    is $obj->greet(name => 'Perl'), 'Perl!', 'named default';
    is $obj->greet(suffix => '?', name => 'Perl'), 'Perl?', 'names can be reordered';
    for my $args ([], [name => 'Perl', unknown => 1], [name => 'Perl', 'suffix']) {
        eval { $obj->greet(@$args) };
        ok $@, 'invalid named arguments rejected by Perl';
    }
    $obj->prototype(greet => sub ($self, :$name) { uc $name });
    is $obj->greet(name => 'Perl'), 'PERL', 'dynamic replacement';
    my $explicit = Package::Prototype->create(methods => { greet => $greet });
    is $explicit->greet(name => 'Perl'), 'Perl!', 'create preserves named signature';
    1;
};
ok $ok, 'named parameter checks completed' or diag $@;
done_testing;

use v5.36;
use Test2::V0;
use PerlX::ScopeFunction qw(let);

sub rewrite ($_code) {
    my $code = substr($_code, 3);
    PerlX::ScopeFunction::__rewrite_let( \$code );
    return $code;
}

sub unindented($code) {
    $code =~ s/\A\s*//r =~ s/ *\n */\n/gr
}

subtest "single scalar context statement", sub {
    my $code = rewrite('let ($foo = 1) { ... }');

    is unindented($code), unindented('
        (sub {
            my ($foo);
            $foo = 1;
            Const::Fast::_make_readonly(\$foo,1);
            ...
        })->();
    ');
};

subtest "two scalar context statements", sub {
    my $code = rewrite('let ($foo = 1; $bar=2) { ... }');

    is unindented($code), unindented('
        (sub {
            my ($foo,$bar);
            $foo = 1;
            $bar=2;
            Const::Fast::_make_readonly(\$foo,1);
            Const::Fast::_make_readonly(\$bar,1);
            ...
        })->();
    ');
};

subtest "one list context statements with lvalue being a CommaList", sub {
    my $code = rewrite('let (($foo,$bar) = (1,2)) { ... }');

    is unindented($code), unindented('
        (sub {
            my ($foo,$bar);
            ($foo,$bar) = (1,2);
            Const::Fast::_make_readonly(\$foo,1);
            Const::Fast::_make_readonly(\$bar,1);
            ...
        })->();
    ');
};

subtest "mix bag of statements", sub {
    my $code = rewrite('let ($zzz = 1; ($foo,$bar) = (1,2); @fb = ($foo,$bar)) { ... }');

    is unindented($code), unindented('
        (sub {
            my ($zzz,$foo,$bar,@fb);
            $zzz = 1;
            ($foo,$bar) = (1,2);
            @fb = ($foo,$bar);
            Const::Fast::_make_readonly(\$zzz,1);
            Const::Fast::_make_readonly(\$foo,1);
            Const::Fast::_make_readonly(\$bar,1);
            Const::Fast::_make_readonly(\@fb,1);
            ...
        })->();
    ');
};

done_testing;

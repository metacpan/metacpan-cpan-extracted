use strict;
use warnings;
use utf8;
use Test::More;

{
    package Foo;
    use Smart::Args;

    our ($p, $q);

    sub simple {
        args_pos my $class,
                 my $p,
                 ;

        $Foo::p = $p;
    }

    sub optional {
        args_pos my $class,
                 my $p,
                 my $q => {optional => 1}
                 ;

        $Foo::p = $p;
        $Foo::q = $q;
    }

    sub default_ {
        args_pos my $class,
                 my $p,
                 my $q => {default => 'John'}
                 ;

        $Foo::p = $p;
        $Foo::q = $q;
    }

    sub classname_with_validation {
        args_pos my $class => { isa => 'Str'};
    }
}

sub lovetest {
    my ($name, $code) = @_;
    local $Foo::p;
    local $Foo::q;
    subtest $name, sub { goto $code };
}

lovetest 'simple' => sub {
    lovetest 'success case' => sub {
        Foo->simple(3);
        is $Foo::p, 3;
    };

    lovetest 'less params' => sub {
        eval { Foo->simple(3, 4) };
        ok $@;
    };

    lovetest 'too much params' => sub {
        eval { Foo->simple(3, 4) };
        ok $@;
    };
};

lovetest 'optional' => sub {
    lovetest 'optional' => sub {
        eval { Foo->optional(3) };
        ok !$@;
        is $Foo::p, 3;
        is $Foo::q, undef;
    };
    lovetest 'optional' => sub {
        eval { Foo->optional(3, 4) };
        ok(!$@) or diag($@);
        is $Foo::p, 3;
        is $Foo::q, 4;
    };
    lovetest 'optional' => sub {
        eval { Foo->optional(3, 4, 5) };
        ok $@;
    };
};

lovetest 'default_' => sub {
    lovetest 'default_' => sub {
        eval { Foo->default_(3) };
        ok !$@;
        is $Foo::p, 3;
        is $Foo::q, 'John';
    };
    lovetest 'default_' => sub {
        eval { Foo->default_(3, 4) };
        ok(!$@) or diag($@);
        is $Foo::p, 3;
        is $Foo::q, 4;
    };
    lovetest 'default_' => sub {
        eval { Foo->default_(3, 4, 5) };
        ok $@;
    };
};

lovetest 'classname_with_validation' => sub {
    eval { Foo->classname_with_validation() };
    ok(!$@) or diag $@;

    eval { Foo::classname_with_validation(+{"FA" => "IL"}) };
    ok($@) and like($@, qr{^'class': Validation failed});
};

done_testing;


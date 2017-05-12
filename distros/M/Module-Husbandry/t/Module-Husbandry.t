use Test;
use Module::Husbandry qw( :all );
use strict;

sub _v {
    join(
        ",",
        map( "($_)",
            map {
                my $h = $_;
                join ",", map $h->{$_}, sort keys %$h;
            } @_
        ),
    );
}

sub _m {
    my ( $in, $expected ) = @_;
    @_ = ( _v( parse_module_specs @$in ), $expected, join ",", @$in );
    goto \&ok;
}

sub _d {
    my ( $in, $expected ) = @_;
    @_ = ( _v( parse_dist_specs @$in ), $expected, join ",", @$in );
    goto \&ok;
}

sub _t {
    my ( $in, $expected ) = @_;
    @_ = ( _v( test_scripts_for parse_module_specs @$in ), $expected, join ",", @$in );
    goto \&ok;
}

sub _f {
    my ( $in, $expected ) = @_;
    @_ = ( _v( templates_for parse_module_specs @$in ), $expected, join ",", @$in );
    goto \&ok;
}

$Module::Husbandry::template_dir = "foo";

my ( $options, @params );

my @tests = (
sub { _m [qw( A        )], "(lib/A.pm,A,A)"                  },
sub { _m [qw( lib/A.pm )], "(lib/A.pm,A,lib/A.pm)"           },
sub { _m [qw( A B      )], "(lib/A.pm,A,A),(lib/B.pm,B,B)"   },
sub { _m [qw( A::B     )], "(lib/A/B.pm,A::B,A::B)"          },

sub { _m [qw( lib/A.pm ), { as_dir => 1 }], "(lib/A.pm,A,lib/A.pm)"  },
sub { _m [qw( A        ), { as_dir => 1 }], "(lib/A,A,A)" },
sub { _m [qw( A::B     ), { as_dir => 1 }], "(lib/A/B,A::B,A::B)" },

sub { _d [qw( A        )], "(A,A,A)"         },
sub { _d [qw( A B      )], "(A,A,A),(B,B,B)" },
sub { _d [qw( A::B     )], "(A-B,A::B,A::B)" },
sub { _d [qw( A-B      )], "(A-B,A::B,A-B)"  },

sub { _t [qw( A           )], "(t/A.t)"           },
sub { _t [qw( A B         )], "(t/A.t),(t/B.t)"   },
sub { _t [qw( A::B        )], "(t/A-B.t)"         },
sub { _t [qw( lib/A/B.pm  )], "(t/A-B.t)"         },
sub { _t [qw( lib/A/B.pod )], ""                  },

sub { _f [qw( lib/B.pm lib/B.pod )], "(foo/Template.pm),(foo/Template.pod)" },

sub {
    @params = parse_cli [qw( -a -- -b C )], {
        "-a|--an-option" => "A",
        param_count      => "2",
        examples         => "%p <to> <from>",
    };
    $options = pop @params;
    ok $options->{an_option}, "A", "-a";
},

sub { ok keys %$options, 2, "number of options parsed + 1" },
sub { ok $params[0], "-b", "param 1" },
sub { ok $params[1], "C",  "param 2" },

sub {
    @params = parse_cli [qw( b C )], {
        "-a|--an-option" => "A",
        param_count      => "2",
        examples         => "%p <to> <from>",
    };
    $options = pop @params;
    ok 1;
},

sub { ok keys %$options, 1, "number of options parsed + 1" },
sub { ok $params[0], "b", "param 1" },
sub { ok $params[1], "C", "param 2" },
);

plan tests => 0+@tests;

$_->() for @tests;

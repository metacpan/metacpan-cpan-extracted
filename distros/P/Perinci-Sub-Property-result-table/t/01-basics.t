#!perl

use 5.010;
use strict;
use warnings;

use Perinci::Sub::Wrapper qw(wrap_sub);
use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

my $meta = {
    v=>1.1,
    result=>{
        table => {
            summary => 'Employees',
            spec => {
                fields => {
                    id   => {
                        schema => 'int*',
                        pos => 0,
                    },
                    name => {
                        schema => 'str*',
                        pos => 1,
                    },
                    manager => {
                        summary => 'Whether employee is a manager',
                        schema => 'bool*',
                        pos => 2,
                    },
                },
                pk => 'id',
            },
        },
    }
};
my $sub = sub {
    my %args = @_;
    my $which = $args{-which};
    if ($which eq 'array_nohint') {
        # return array with no table.fields hint, assumed to be pk
        return [200, "OK", [1, 2, 3]];
    } elsif ($which eq 'array_hint') {
        # return array with table.fields hint
        return [200, "OK", [qw/andi budi cinta/], {"table.fields"=>[qw/name/]}];
    } elsif ($which eq 'aoa') {
        return [200, "OK", [[qw/andi 1/], [qw/cinta 0/]],
                {"table.fields"=>[qw/name manager/]}];
    } elsif ($which eq 'aoh') {
        return [200, "OK", [{name=>'andi', manager=>1},
                            {name=>'cinta', manager=>0}]];
    } elsif ($which eq 'aoh_extra') {
        # return aoh with extra fields
        return [200, "OK", [{name=>'andi', manager=>1, salary=>12_000_000},
                            {name=>'cinta', manager=>0, salary=>7_500_000}]];
    } elsif ($which eq 'aoh_underscore') {
        # return aoh with underscore fields
        return [200, "OK", [{name=>'andi', manager=>1, _foo=>1},
                            {name=>'cinta', manager=>0, _bar=>2}]];
    }
    die "BUG: unknown -which";
};
test_wrap(
    name        => 'add format_options',
    wrap_args   => {sub=>$sub, meta=>$meta},
    calls       => [
        {
            # currently not added for array, because dfpc might display it in
            # multicolumns
            argsr => [-which=>'array_nohint'],
            res   => [200, "OK", [1, 2, 3], {}],
        },
        {
            argsr => [-which=>'array_hint'],
            res   => [200, "OK", [qw/andi budi cinta/],
                      {
                          #"table.fields"=>[qw/name manager/],
                          "table.fields"=>[qw/name/],
                      },
                  ],
        },
        {
            argsr => [-which=>'aoa'],
            res   => [200, "OK", [[qw/andi 1/], [qw/cinta 0/]],
                      {
                          #"table.fields"=>[qw/name/],
                          "table.fields"=>undef,
                      },
                  ],
        },
        {
            argsr => [-which=>'aoh'],
            res   => [200, "OK", [{name=>"andi",manager=>1}, {name=>"cinta",manager=>0}],
                      {
                          'table.fields' => [qw/name manager/],
                      },
                  ],
        },
    ],
);

DONE_TESTING:
done_testing;

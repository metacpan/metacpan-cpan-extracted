#!perl

use 5.010;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.96;

use Perinci::Exporter qw();

package TestSource;

# note: in our scenario here, all exports should be /^f/ to make it easy to test

our %SPEC;
$SPEC{f1} = {v=>1.1, tags=>[qw/a b export:default/]};
sub   f1    { [200,"OK","f1"] }
$SPEC{f2} = {v=>1.1, tags=>[qw/a export:default/]};
sub   f2    { [200,"OK","f2"] }
$SPEC{f3} = {v=>1.1, tags=>[qw/b/]};
sub   f3    { [200,"OK","f3"] }
$SPEC{f4} = {v=>1.1, tags=>[qw/c/]};
sub   f4    { [200,"OK","f4"] }
$SPEC{f5} = {v=>1.1, tags=>[qw/a b c export:never/]};
sub   f5    { [200,"OK","f5"] }

# to test @EXPORT & @EXPORT_OK
sub   f91   { [200,"OK","f91"] }
sub   f92   { [200,"OK","f92"] }
sub   f93   { "f93" }            # to test can't wrap sub w/o meta
sub   f99   { [200,"OK","f93"] } # to test extra_exports

# to test import options: wrap, convert, result_naked, curry
$SPEC{fargs} = {
    v=>1.1, result_naked=>1,
    args=>{
        a1 => {pos=>0},
        a2 => {pos=>1},
        a3 => {pos=>2},
    },
};
sub fargs {
    my %args = @_;
    join("",
         "a1=", $args{a1}//"", " ",
         "a2=", $args{a2}//"", " ",
         "a3=", $args{a3}//"");
}

our @EXPORT    = qw(f4 f91);
our @EXPORT_OK = qw(f92 f93);

package TestTarget;

our @_import_args;

package main;

test_export(
    name        => 'default export/import',
    export_args => [],
    import_args => [],
    imported    => [qw(f1 f2 f4 f91)],
    wrapped     => [qw(f1 f2 f4)],
);

{
    # we also test that wrapping is not redone for functions which use default
    # wrapping args
    require Perinci::Sub::Wrapper;
    no warnings 'redefine';
    local *Perinci::Sub::Wrapper::wrap_sub = sub { die };

    test_export(
        name        => 'import individual symbol',
        export_args => [],
        import_args => [qw(f1)],
        imported    => [qw(f1)],
    );
}

test_export(
    name        => 'sanity: importing unknown exports -> dies',
    export_args => [],
    import_args => [qw(f666)],
    import_dies => 1,
);

test_export(
    name        => 'sanity: invalid import args',
    export_args => [],
    import_args => [qw(-opt_without_arg)],
    import_dies => 1,
);

test_export(
    name        => 'export option: default_exports',
    export_args => [default_exports => [qw/f3/]],
    import_args => [],
    imported    => [qw(f1 f2 f3 f4 f91)],
);

test_export(
    name        => 'export option: extra_exports',
    export_args => [extra_exports => [qw/f99/]],
    import_args => [qw(f99)],
    imported    => [qw(f99)],
);

test_export(
    name        => 'export option: default_wrap=0',
    export_args => [default_wrap => 0],
    import_args => [],
    imported    => [qw(f1 f2 f4 f91)],
    wrapped     => [qw()],
);

test_export(
    name        => 'export option: default_on_clash=bail #1',
    preimport   => sub {
        package TestTarget;
        no strict 'refs';
        *{"f4"} = sub {};
        package main;
    },
    export_args => [default_on_clash => 'bail'],
    import_args => [qw(f1)],
    imported    => [qw(f1 f4)], # f4 is actually not imported
);

test_export(
    name        => 'export option: default_on_clash=bail #2',
    preimport   => sub {
        package TestTarget;
        no strict 'refs';
        *{"f4"} = sub {};
        package main;
    },
    export_args => [default_on_clash => 'bail'],
    import_args => [],
    import_dies => 1,
);

test_export(
    name        => 'import tag',
    export_args => [],
    import_args => [qw(:b)],
    imported    => [qw(f1 f3)],
);

test_export(
    name        => 'import tag: all',
    export_args => [],
    import_args => [qw(:all)],
    imported    => [qw(f1 f2 f3 f4 f91 f92 f93 fargs)],
);

test_export(
    name        => 'import option: -prefix',
    export_args => [],
    import_args => [qw(f1 f2 -prefix foo_)],
    imported    => [qw(foo_f1 foo_f2)],
);

test_export(
    name        => 'import option: -suffix',
    export_args => [],
    import_args => [qw(f1 f2 -suffix _bar)],
    imported    => [qw(f1_bar f2_bar)],
);

test_export(
    name        => 'import option: -on_clash=bail',
    export_args => [],
    preimport   => sub {
        package TestTarget;
        no strict 'refs';
        *{"f4"} = sub {};
        package main;
    },
    import_args => [qw(f4 -on_clash bail)],
    import_dies => 1,
);

test_export(
    name        => 'per-symbol import option: as',
    export_args => [],
    import_args => [f1 => {as => 'foo'}],
    imported    => [qw(foo)],
);

test_export(
    name        => 'per-symbol import option: prefix',
    export_args => [],
    import_args => [f1 => {prefix => 'foo_'}],
    imported    => [qw(foo_f1)],
);

test_export(
    name        => 'per-symbol import option: suffix',
    export_args => [],
    import_args => [f1 => {suffix => '_bar'}],
    imported    => [qw(f1_bar)],
);

test_export(
    name        => 'per-symbol import option: wrap=0',
    export_args => [],
    import_args => [fargs => {wrap => 0}],
    imported    => [qw(fargs)],
    wrapped     => [qw()],
);

test_export(
    name        => 'per-symbol import option: wrap=custom',
    export_args => [],
    import_args => [fargs => {wrap => {convert=>{result_naked=>0}}}],
    imported    => [qw(fargs)],
    wrapped     => [qw(fargs)],
    posttest    => sub {
        no strict 'refs';
        is_deeply(&{"TestTarget::fargs"}, [200, "OK", "a1= a2= a3="], "result");
    },
);

test_export(
    name        => 'just to test that fargs\'s default wrapper not overriden',
    export_args => [],
    import_args => [qw(fargs)],
    imported    => [qw(fargs)],
    wrapped     => [qw(fargs)],
    posttest    => sub {
        no strict 'refs';
        is_deeply(&{"TestTarget::fargs"}, "a1= a2= a3=", "result");
    },
);

test_export(
    name        => 'per-symbol import option: convert',
    export_args => [],
    import_args => [fargs => {convert=>{result_naked=>0}}],
    imported    => [qw(fargs)],
    wrapped     => [qw(fargs)],
    posttest    => sub {
        no strict 'refs';
        is_deeply(&{"TestTarget::fargs"}, [200, "OK", "a1= a2= a3="], "result");
    },
);

test_export(
    name        => 'per-symbol import option: args_as=array',
    export_args => [],
    import_args => [fargs => {args_as=>'array'}],
    imported    => [qw(fargs)],
    wrapped     => [qw(fargs)],
    posttest    => sub {
        no strict 'refs';
        is_deeply(&{"TestTarget::fargs"}(1, 2, 3), "a1=1 a2=2 a3=3", "result");
    },
);

test_export(
    name        => 'per-symbol import option: result_naked=0',
    export_args => [],
    import_args => [fargs => {result_naked=>0}],
    imported    => [qw(fargs)],
    wrapped     => [qw(fargs)],
    posttest    => sub {
        no strict 'refs';
        is_deeply(&{"TestTarget::fargs"}, [200, "OK", "a1= a2= a3="], "result");
    },
);

test_export(
    name        => 'per-symbol import option: curry',
    export_args => [],
    import_args => [fargs => {curry=>{a1=>10}}],
    imported    => [qw(fargs)],
    wrapped     => [qw(fargs)],
    posttest    => sub {
        no strict 'refs';
        is_deeply(&{"TestTarget::fargs"}(a2=>2), "a1=10 a2=2 a3=", "result");
    },
);

# XXX test install_import() option: caller_level

DONE_TESTING:
done_testing();

sub test_export {
    my %args = @_;

    subtest $args{name} => sub {

        # clean target packages
        delete $TestTarget::{$_} for grep {/^f/} keys %TestTarget::;

        # install import() in source
        {
            delete $TestSource::{import};
            Perinci::Exporter::install_import(
                @{$args{export_args} // []}, into => 'TestSource');
        }

        if ($args{preimport}) {
            $args{preimport}->();
        }

        my $recap;

        # import()
        @TestTarget::_import_args = @{ $args{import_args} // [] };
        eval {
            package TestTarget;
            $recap = TestSource->import(@_import_args);
            package main;
        };
        my $e = $@;
        if ($args{import_dies}) {
            ok($e, "import dies");
            return;
        } else {
            ok(!$e, "import doesn't die") or do {
                diag $e;
                return;
            };
        }

        my @imported = sort grep {/^f/} keys %TestTarget::;
        if ($args{imported}) {
            my @exp = sort @{$args{imported}};
            is_deeply(\@imported, \@exp, "imported [".join(" ", @exp)."]") or
                diag "imported = ", explain(\@imported);
        }

        if ($args{wrapped}) {
            my @exp = sort @{$args{wrapped}};
            is_deeply($recap->{wrapped}, \@exp, "wrapped [".join(" ", @exp)."]") or
                diag "wrapped = ", explain($recap->{wrapped});
        }

        if ($args{posttest}) {
            $args{posttest}->();
        }

    };
}

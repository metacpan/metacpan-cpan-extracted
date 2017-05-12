#!perl

use 5.010;
use strict;
use warnings;

use Data::Dumper;
use Test::More 0.98;

#test_import(
#    name => '',
#    args => [],
#);

# XXX test default exports
# XXX test importing by tags
# XXX test tag: :default
# XXX test tag: :all
# XXX test by default not wrapping
# XXX test wrapping by specifying convert arg (e.g. result_naked=>1)
# XXX test import option -as
# XXX test import option -prefix
# XXX test import option -suffix
# XXX test import option -wrap=>1
# XXX test import option -wrap=>0 (even if convert specified)
# XXX test error if convert option is invalid
# XXX test error if function is not recognized
# XXX test error if import option is unknown

ok 1;

DONE_TESTING:
done_testing;

sub _dump {
    join(
        '',
        "(", Data::Dumper->new(@_)->Terse(1)->Indent(0)->Dump, ")"
    );
}

sub test_import {
    my %args = @_;

    subtest $args{name} => sub {

        eval join(
            '',
            'package Test::Perinci::Import;',
            'use Perinci::Import ', _dump(@{ $args{args} }), ';',
        );
        my $e = $@;
        if ($args{dies}) {
            ok($e, "import dies");
            return;
        } else {
            ok(!$e, "import doesn't die") or do {
                diag $e;
                return;
            };
        }

        if ($args{posttest}) {
            $args{posttest}->();
        }

    };
}

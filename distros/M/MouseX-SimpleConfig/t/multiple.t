#!/usr/bin/perl
#
# This file is part of MouseX-SimpleConfig
#
# This software is copyright (c) 2011 by Infinity Interactive.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.006;
use strict;
use warnings;

use strict;
use warnings;

use lib 't/lib';
use lib '../t/lib';

BEGIN {
    use Test::More;

    eval "use YAML::Syck ()";
    if ($@) {
        eval "use YAML ()";
        if ($@) {
            plan skip_all => "YAML or YAML::Syck required for this test";
        }
    }

    plan tests => 5;

    use_ok('MXSimpleConfigTest');
}

# Can it load a multiple YAML files with options
{
    my $test_yaml;    # generic filehandle
    open $test_yaml, '>', 'test.yaml' or die "Cannot create test.yaml: $!";
    print {$test_yaml} "direct_attr: 123\ninherited_ro_attr: asdf\n";
    close $test_yaml or die "Cannot close test.yaml: $!";

    open $test_yaml, '>', 'test2.yaml' or die "Cannot create test2.yaml: $!";
    print {$test_yaml} "req_attr: foo\n";
    close $test_yaml or die "Cannot close test.yaml: $!";

    my $foo = eval {
        MXSimpleConfigTest->new_with_config(
            configfile => [ 'test.yaml', 'test2.yaml' ] );
    };
    ok( !$@, 'Did not die with two YAML config files' )
        or diag $@;

    is( $foo->req_attr,          'foo',  'req_attr works' );
    is( $foo->direct_attr,       123,    'direct_attr works' );
    is( $foo->inherited_ro_attr, 'asdf', 'inherited_ro_attr works' );
}

END {
    unlink('test.yaml');
    unlink('test2.yaml');
}

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

    plan tests => 6;

    use_ok('MXSimpleConfigTest');
}

# Does it work with no configfile and not barf?
{
    eval { MXSimpleConfigTest->new( req_attr => 'foo' ) };
    ok( !$@, 'Did not die with no configfile specified' )
        or diag $@;
}

# Can it load a simple YAML file with the options
{
    open( my $test_yaml, '>', 'test.yaml' )
        or die "Cannot create test.yaml: $!";
    print $test_yaml
        "direct_attr: 123\ninherited_ro_attr: asdf\nreq_attr: foo\n";
    close($test_yaml);

    my $foo = eval {
        MXSimpleConfigTest->new_with_config( configfile => 'test.yaml' );
    };
    ok( !$@, 'Did not die with good YAML configfile' )
        or diag $@;

    is( $foo->req_attr,          'foo',  'req_attr works' );
    is( $foo->direct_attr,       123,    'direct_attr works' );
    is( $foo->inherited_ro_attr, 'asdf', 'inherited_ro_attr works' );
}

END { unlink('test.yaml') }

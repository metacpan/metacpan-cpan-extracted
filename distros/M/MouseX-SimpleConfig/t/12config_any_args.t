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

    eval "use Config::General ()";
    if ($@) {
        plan skip_all => "Config::General required for this test";
    }

    plan tests => 6;

    use_ok('MXDriverArgsConfigTest');
}

# Does it work with no configfile and not barf?
{
    eval { MXDriverArgsConfigTest->new( req_attr => 'foo' ) };
    ok( !$@, 'Did not die with no configfile specified' )
        or diag $@;
}

# Can it load a simple YAML file with the options
{
    open( my $test_conf, '>', 'test.conf' )
        or die "Cannot create test.conf: $!";
    print $test_conf <<EOM;
Direct_Attr 123
Inherited_Ro_Attr asdf
Req_Attr foo
EOM
    close($test_conf);

    my $foo = eval {
        MXDriverArgsConfigTest->new_with_config( configfile => 'test.conf' );
    };
    ok( !$@, 'Did not die with good General configfile' )
        or diag $@;

    is( $foo->req_attr,          'foo',  'req_attr works' );
    is( $foo->direct_attr,       123,    'direct_attr works' );
    is( $foo->inherited_ro_attr, 'asdf', 'inherited_ro_attr works' );
}

END { unlink('test.conf') }

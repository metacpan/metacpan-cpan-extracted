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
use Test::More;
our @classes;

BEGIN {

    @classes = qw/ MXDefaultConfigTest MXDefaultMultipleConfigsTest /;

    eval "use YAML::Syck ()";
    if ($@) {
        eval "use YAML ()";
        if ($@) {
            plan skip_all => "YAML or YAML::Syck required for this test";
        }
    }

    use_ok($_) for @classes;
}

# Can it load a simple YAML file with the options
#  based on a default in the configfile attr
{
    open( my $test_yaml, '>', 'test.yaml' )
        or die "Cannot create test.yaml: $!";
    print $test_yaml
        "direct_attr: 123\ninherited_ro_attr: asdf\nreq_attr: foo\n";
    close($test_yaml);

}

foreach my $class (@classes) {
    my $foo = eval { $class->new_with_config(); };
    ok( !$@, 'Did not die with good YAML configfile' )
        or diag $@;

    is( $foo->req_attr,          'foo',  'req_attr works' );
    is( $foo->direct_attr,       123,    'direct_attr works' );
    is( $foo->inherited_ro_attr, 'asdf', 'inherited_ro_attr works' );
}

done_testing;

END { unlink('test.yaml') }

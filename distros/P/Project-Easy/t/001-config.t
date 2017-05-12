#!/usr/bin/perl

use utf8; # for real testing how works our Data::Dumper stringification for unicode
$| = 1;
use strict;
use warnings;
use Data::Dumper;

use Test::More qw(no_plan);

use_ok qw(Project::Easy::Config);

use_ok qw(Project::Easy::Config::File);

is( Project::Easy::Config::patch('',''), undef, ' Project::Easy::Config::patch N1 (both arguments are empty)' );

is( Project::Easy::Config::patch(undef, undef), undef, ' Project::Easy::Config::patch N2 (both arguments are undef)' );

is( Project::Easy::Config::patch({}, {}), undef, ' Project::Easy::Config::patch N3 (empty hashrefs as params)' );

#####
my ($struct, $patch) = (
    { test1 => 1, test2 => 2 },
    { test2 => 3 }
);

Project::Easy::Config::patch($struct, $patch);
is_deeply($struct,
    {
        test1 => 1,
        test2 => 3,
    },
    ' Project::Easy::Config::patch N4 (override param)'
);

#####

($struct, $patch) = (
    { test1 => 1, test2 => 2 },
    { test3 => 'привет' }
);

Project::Easy::Config::patch($struct, $patch);
is_deeply( $struct,
    {
        test1 => 1,
        test2 => 2,
        test3 => 'привет',
    },
    ' Project::Easy::Config::patch N5 (add param)' 
);

##### _recursive_undef_struct

### scalar
$struct = 'test_scalar';

is( Project::Easy::Config::_recursive_undef_struct($struct), undef, ' _recursive_undef_struct test on scalar' );

### array
$struct = [ qw(aaa bbb ccc) ];

is_deeply( Project::Easy::Config::_recursive_undef_struct($struct),
        [ undef, undef, undef ],
        ' _recursive_undef_struct test on array ref' );

### real struct
$struct = { aaa => 111, bbb => 222, ccc => 333,
            ddd => [
                { xyz => 1 },
                qw(aaa bbb ccc)
            ]
        };

is_deeply( Project::Easy::Config::_recursive_undef_struct($struct),
    {
      'bbb' => undef,
      'aaa' => undef,
      'ccc' => undef,
      'ddd' => [
            {
                'xyz' => undef
            },
            undef,
            undef,
            undef
        ]
    },
    '_recursive_undef_struct test on the real word structure' );

#####

($struct, $patch) = (
    { aaa => 1111, bbb => 1222, ccc => 1333,
        ddd => [
            { xyz => 1 },
        ]
    },
    { aaa => 2111, bbb => 2222, ccc => 2333,
        ddd => [
            { xyz => 2 },
            qw(aaa bbb ccc) # !
        ],
        eee => [            # !
            { xyz => 5 },
            qw(aaa bbb ccc)
        ]
    }
);

Project::Easy::Config::patch($struct, $patch, 'undef_keys_in_patch');
# print Dumper('NEW STRUCT', $struct);
is_deeply( $struct,
    { aaa => 1111, bbb => 1222, ccc => 1333,
        ddd => [
            { xyz => 1 },
			# undef, undef, undef
        ],
        eee => [
            { xyz => undef },
            undef, undef, undef
        ]
    },
    'Project::Easy::Config::patch N6 (patching with "undef_keys_in_patch" algorithm)'
);

##### _recursive_traverse_struct

$patch = {
    key1    => 'val1',
    key2    => 'val2',
    key3    => {
        key3_1 => 'val3_1',
        key3_2 => [ qw(aaa bbb ccc), { key3_2_1 => 'val3_2_1' } ],
        key3_3 => { key3_3_1 => 'val3_3_1' },
    }
};


Project::Easy::Config::_recursive_traverse_struct($patch, 'db');

{
    no warnings;
    
    is_deeply(\%Project::Easy::Config::nonexistent_keys_in_config,
    {
        'db.key1' => 1,
        'db.key2' => 1,
        'db.key3.key3_1' => 1,
        'db.key3.key3_2' => 'ARRAY of 4 elements',
        'db.key3.key3_2.key3_2_1' => 1,
        'db.key3.key3_3.key3_3_1' => 1,
    },
    'Project::Easy::Config::_recursive_traverse_struct on "db" section of config');
}

#####

%Project::Easy::Config::nonexistent_keys_in_config = ();
{
    no warnings;
    @Project::Easy::Config::curr_patch_config_path = ();
}

($struct, $patch) = (
    { db_id => { xtest1 => 1, xtest2 => 2 } },
    { db_id => { xtest3 => 'привет'      } }
);

Project::Easy::Config::patch($struct, $patch, 'store_nonexistent_keys_in_struct');
is_deeply( $struct,
    {
        db_id => {
            xtest1 => 1,
            xtest2 => 2,
        }
    },
    'Project::Easy::Config::patch N7 (patching with "store_nonexistent_keys_in_struct" algorithm - check struct)'
);

{
    no warnings;
    
    is_deeply(\%Project::Easy::Config::nonexistent_keys_in_config,
    {
        'db_id.xtest3' => 1,
    },
    'Project::Easy::Config::patch N7 (patching with "store_nonexistent_keys_in_struct" algorithm - check nonexistent keys)');
}

#########################################################
# here we test embedded serializers: perl and json
#########################################################

my $serializer_j = Project::Easy::Config->serializer ('json');
ok ($serializer_j);

is_deeply (
	$struct,
	$serializer_j->parse_string ($serializer_j->dump_struct ($struct))
);

my $serializer_p = Project::Easy::Config->serializer ('perl');
ok ($serializer_p);

is_deeply (
	$struct,
	$serializer_p->parse_string ($serializer_p->dump_struct ($struct))
);

#########################################################
# interface to config files
#########################################################

my $file_name = 'aaa.json';

my $config_file = Project::Easy::Config::File->new ($file_name);

$config_file->serialize ({hello => 'world'});

# testing json and adequateness
ok $config_file->contents =~ /"hello"\s*:\s*"world"/s;

$config_file->patch ({hello => '{$world}'});

ok $config_file->contents =~ /"hello"\s*:\s*"{\$world}"/s;

my $deserialized = $config_file->deserialize ({world => 'planet earth'});

ok scalar (keys %$deserialized) == 1;

ok $deserialized->{hello} eq 'planet earth';

unlink $file_name;

# similar, but for perl

$file_name = 'aaa.pl';

$config_file = Project::Easy::Config::File->new ($file_name);

$config_file->serialize ({hello => 'world'});

# testing json and adequateness
ok $config_file->contents =~ /'hello'\s*=>\s*'world'/s;

$config_file->patch ({hello => '{$world}'});

ok $config_file->contents =~ /'hello'\s*=>\s*'{\$world}'/s;

$deserialized = $config_file->deserialize ({world => 'planet earth'});

ok scalar (keys %$deserialized) == 1;

ok $deserialized->{hello} eq 'planet earth';

unlink $file_name;

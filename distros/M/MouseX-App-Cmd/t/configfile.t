#!perl -T

use strict;
use warnings;
use Test::More;
use Mouse;

BEGIN {
    eval 'require MouseX::ConfigFromFile; require YAML;';
    if ($@) {
        plan skip_all =>
            'These tests require MouseX::ConfigFromFile and YAML';
    }
    else {
        plan tests => 3;
    }
}

use lib 't/lib';
use Test::ConfigFromFile;

my $cmd = Test::ConfigFromFile->new;

{
    local @ARGV = qw(moo);
    eval { $cmd->run };

    like(
        $@,
        qr/Mandatory parameter 'moo' missing in call to ["(]eval[)"]/,
        'command died with the correct string',
    );
}

{
    local @ARGV = qw(moo --configfile=t/lib/Test/ConfigFromFile/config.yaml);
    eval { $cmd->run };

    like(
        $@,
        qr/cows go moo1 moo2 moo3/,
        'command died with the correct string',
    );
}

{
    local @ARGV = qw(boo);
    eval { $cmd->run };

    like( $@, qr/ghosts go moo1 moo2 moo3/, 'default configfile read', );
}

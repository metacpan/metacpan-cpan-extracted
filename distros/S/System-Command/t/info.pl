#!perl
use strict;
use warnings;
use Cwd qw( cwd );
use Data::Dumper;

my $input = $ENV{SYSTEM_COMMAND_INPUT} ? join( '', <> ) : '';

print Data::Dumper->Dump(
    [   {   argv  => \@ARGV,
            env   => \%ENV,
            cwd   => cwd(),
            input => $input,
            name  => $0,
            pid   => $$,
        }
    ],
    ['info']
);

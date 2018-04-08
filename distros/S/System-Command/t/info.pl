#!perl
use strict;
use warnings;
use Cwd qw( cwd );
use Data::Dumper;

my $input = $ENV{SYSTEM_COMMAND_INPUT} ? join( '', <> ) : '';

{
local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Indent = 1;
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
}

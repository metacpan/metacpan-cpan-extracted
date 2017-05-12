#!perl
use strict;
use warnings;
use Cwd qw( cwd );
use Data::Dumper;

$Data::Dumper::Sortkeys++;

my $input = $ENV{SYS_CMD_INPUT} ? join( '', <> ) : '';

binmode STDOUT, ':encoding(utf8)';

print Data::Dumper->Dump(
    [
        {
            argv  => \@ARGV,
            env   => \%ENV,
            cwd   => lc( cwd() ),
            input => $input,
            pid   => $$,
        }
    ],
    ['info']
);

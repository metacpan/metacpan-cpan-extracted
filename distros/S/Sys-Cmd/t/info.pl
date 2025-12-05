#!/usr/bin/env perl
use v5.18;
use warnings;
use Cwd qw( cwd );
use Data::Dumper;
use Encode::Locale 'decode_argv';
use Encode 'decode';

decode_argv(Encode::FB_CROAK);

binmode STDIN,  ':encoding(locale)';
binmode STDOUT, ':encoding(locale)';
binmode STDERR, ':encoding(locale)';

print STDERR decode( locale => $ENV{SYS_CMD_ERR} ), "\n"
  if exists $ENV{SYS_CMD_ERR};

$Data::Dumper::Sortkeys++;
print Data::Dumper->Dump(
    [
        {
            argv  => \@ARGV,
            env   => \%ENV,
            cwd   => fc( cwd() ),
            input => $ENV{SYS_CMD_INPUT} ? join( '', <STDIN> ) : '',
            pid   => $$,
        }
    ],
    ['info']
);

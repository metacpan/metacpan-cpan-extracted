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

my %env;
$env{ decode( locale => $_ ) } = decode( locale => $ENV{$_} ) for keys %ENV;

my $err = $env{SYS_CMD_ERR} // undef;
if ( length $err ) {
    delete $env{SYS_CMD_ERR};
    print STDERR $err, "\n";
}

$Data::Dumper::Sortkeys++;
print Data::Dumper->Dump(
    [
        {
            argv  => \@ARGV,
            env   => \%env,
            cwd   => fc( cwd() ),
            input => $env{SYS_CMD_INPUT} ? join( '', <STDIN> ) : '',
            pid   => $$,
        }
    ],
    ['info']
);

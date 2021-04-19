#!perl
use strict;
use warnings;

=head1 NAME

myriad.pl

=head1 DESCRIPTION

=cut

use Myriad;
use Future::AsyncAwait;
use Time::Moment;
use Syntax::Keyword::Try;
use Sys::Hostname qw(hostname);

use Log::Any::Adapter qw(Stderr), log_level => 'info';
use Log::Any qw($log);

binmode STDIN, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

try {
    my $hostname = hostname();
    $log->infof('Starting Myriad on %s pid %d at %s', $hostname, $$, Time::Moment->now->to_string);
    my $myriad = Myriad->new(
        hostname => hostname(),
        pid      => $$,
    );
    await $myriad->configure_from_argv(@ARGV);
    await $myriad->run;
} catch ($e) {
    $log->errorf('%s failed due to %s', $0, $e);
}

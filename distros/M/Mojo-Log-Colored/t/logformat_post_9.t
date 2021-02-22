use strict;
use warnings;
use Test::More;
use Capture::Tiny 'capture_stderr';
use Term::ANSIColor 'colorstrip';

{
    no warnings 'once';
    $Mojolicious::VERSION = 9.01;

    require Mojo::Log::Colored;
}

my $stderr = capture_stderr {
    Mojo::Log::Colored->new->warn('foo', 'bar', "baz\nqrr");
};

like colorstrip($stderr), qr{foo\sbar\sbaz\nqrr}, "log contains spaces between elements";

done_testing;
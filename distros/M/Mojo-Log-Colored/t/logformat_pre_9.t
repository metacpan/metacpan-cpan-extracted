use strict;
use warnings;
use Test::More;
use Capture::Tiny 'capture_stderr';
use Term::ANSIColor 'colorstrip';

{
    no warnings 'once';
    $Mojolicious::VERSION = 8;

    require Mojo::Log::Colored;
}

my $stderr = capture_stderr {
    Mojo::Log::Colored->new->warn('foo', 'bar', "baz\nqrr");
};

like colorstrip($stderr), qr{foo\nbar\nbaz\nqrr}, "log contains spaces between elements";

done_testing;
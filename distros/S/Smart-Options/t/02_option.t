use strict;
use Test::More;

use Smart::Options;
use Capture::Tiny ':all';
use Try::Tiny;

subtest 'alias' => sub {
    my $opts = Smart::Options->new->alias(r => 'rif');
    my $argv = $opts->parse(qw(--r=55 --xup=9.52));

    is $argv->{rif}, 55;
    is $argv->{xup}, 9.52;
};

subtest 'default' => sub {
    my $opts = Smart::Options->new;
    $opts->default(x => 10);
    $opts->default(y => 10);
    my $argv = $opts->parse(qw(-x 5));

    is $argv->{x}, 5;
    is $argv->{y}, 10;
};

subtest 'boolean' => sub {
    my $opts = Smart::Options->new->boolean('x', 'y', 'z');
    my $argv = $opts->parse(qw(-x -z one two three));

    ok $argv->{x};
    ok !$argv->{y};
    ok $argv->{z};
    is_deeply $argv->{_}, [qw(one two three)];
};

subtest 'demand' => sub {
    my $opts = Smart::Options->new(add_help => 0)
                    ->usage("Usage: $0 -x [num] -y [num]")
                    ->demand('x', 'y');

    my $out = capture_stderr { try { $opts->parse(qw(-x 4.91 -z 2.51)) } };
    is $out, <<"EOS";
Usage: $0 -x [num] -y [num]

Options:
  -x      [required]  
  -y      [required]  


Missing required arguments: y
EOS
};

subtest 'describe' => sub {
    my $opts = Smart::Options->new(add_help => 0)
                    ->usage("Usage: $0 -x [num] -y [num]")
                    ->demand('x', 'y')
                    ->describe(f => 'Load a file', y => 'year');

    my $out = capture_stderr { try { $opts->parse(qw(-x 4.91 -z 2.51)) } };
    is $out, <<"EOS";
Usage: $0 -x [num] -y [num]

Options:
  -f  Load a file                
  -x                 [required]  
  -y  Year           [required]  


Missing required arguments: y
EOS
};

subtest 'options' => sub {
    my $opts = Smart::Options->new(add_help => 0);
    $opts->usage("Usage: $0 -x [num] -y [num]");
    $opts->options(
        f => {
            alias    => 'file',
            default  => '/etc/passwd',
            describe => 'Load a file',
        }
    );

    is $opts->help, <<"EOS";
Usage: $0 -x [num] -y [num]

Options:
  -f, --file  Load a file      [default: /etc/passwd]

EOS

    is $opts->parse()->{file}, '/etc/passwd';
};


done_testing;

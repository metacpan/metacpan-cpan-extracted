#!perl -w
use strict;
use Test;
BEGIN { plan tests => 6 };

ok(capture($^X, 't/args.plx'), '');

ok(capture($^X, 't/args.plx', "foo\nbar", 'baz'),
   qq{'foo\nbar'\n'baz'\n});

ok(capture('./pperl', 't/args.plx'), '');

ok(capture('./pperl', 't/args.plx', "foo\nbar", 'baz'),
   qq{'foo\nbar'\n'baz'\n});

`./pperl -k t/args.plx`;

`./pperl t/env.plx`; # run it once so there's a $ENV{PATH} about

%ENV = ( foo       => "bar\nbaz",
         "quu\nx"  => "wobble",
         null      => '');

ok(capture($^X, 't/env.plx'),
  qq{'foo' => 'bar\nbaz'\n'null' => ''\n'quu\nx' => 'wobble'\n});

ok(capture('./pperl', 't/env.plx'),
  qq{'foo' => 'bar\nbaz'\n'null' => ''\n'quu\nx' => 'wobble'\n});

`./pperl -k t/env.plx`;

sub capture {
    my $pid = open(FH, "-|");
    my $result;
    splice(@_, 1, 0, '-Iblib/lib', '-Iblib/arch');
    if ($pid) { local $/; $result = <FH>; close FH }
    else      { exec(@_) or die "failure to exec $!"; }
    return defined($result) ? $result : '';
}


#!/usr/bin/perl -w
use strict;
use Test::More tests => 11;

use_ok("Module::CPANTS");

my $cpants = Module::CPANTS->new()->data;
my $data = $cpants->{'Acme-Colour-0.20.tar.gz'};

is($data->{author}, "LBROCARD");
is_deeply($data->{files}, ['Makefile.PL', 'README', 'MANIFEST']);

my $m = $data->{requires_module};
is_deeply($, {
          'List::Util' => 0,
          'Test::Simple' => 0,
          'Graphics::ColorNames' => 0
});

my $r = $data->{requires};
is_deeply($r, [
          'Graphics-ColorNames-0.32.tar.gz',
          'Scalar-List-Utils-1.11.tar.gz',
          'Test-Simple-0.47.tar.gz'
]);

my $rr = $data->{requires_recursive};
is_deeply($rr, [
          'File-Spec-0.82.tar.gz',
          'Graphics-ColorNames-0.32.tar.gz',
          'Scalar-List-Utils-1.11.tar.gz',
          'Test-Harness-2.28.tar.gz',
          'Test-Simple-0.47.tar.gz'
]);

my $testers = $data->{testers};
is_deeply($testers, {
      'fail' => 1,
      'pass' => 5,
});

my $lines = $data->{lines};
is_deeply($lines, {
      'nonpod' => 184,
      'pod' => 95,
      'pod_errors' => 0,
      'total' => 265,
      'with_comments' => 8,
});

my $size = $data->{size};
is_deeply($size, {
      'packed' => 3883,
      'unpacked' => 13078,
});

is($data->{releases}, 5);

my $uses = $data->{uses};
is_deeply($uses, [
      'Graphics::ColorNames',
      'List::Util',
      'strict',
      'vars'
    ]
);


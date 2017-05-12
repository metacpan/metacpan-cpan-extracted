#!perl -T
use strict;
use warnings;

package Test::SubPipeline;
use base qw(Exporter);
our @EXPORT = qw(test_pipeline);

use Sub::Pipeline;
use Test::More;

sub test_pipeline {
  my $value = 0;

  # a stupidly simple pipeline that just runs through some things and succeeds
  my $test_pipeline = Sub::Pipeline->new({
    order => [ qw(begin check init run end) ],
    pipe  => {
      begin => sub { cmp_ok($value++, '==', 0, "begin pipeline runs") },
      check => sub { cmp_ok($value++, '==', 1, "check pipeline runs") },
      init  => sub { cmp_ok($value++, '==', 2, "init pipeline runs") },
      run   => sub { cmp_ok($value++, '==', 3, "run pipeline runs") },
      end   => sub {
        cmp_ok($value++, '==', 4, "end pipeline runs");
        Sub::Pipeline::Success->throw;
      },
    },
  });

  return wantarray ? ($test_pipeline, $value) : $test_pipeline;
}

"alaska =====(oil)===== lower48";

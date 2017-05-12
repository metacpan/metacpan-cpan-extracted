use strict;
use warnings;
use Test::More 0.88;

use utf8;
use lib 't/lib';
use MLTests;
use Encode qw/encode encode_utf8/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

{
  package WriterTester;
  use Mixin::Linewise::Writers -writers;

  sub write_handle {
    my ($self, $data, $handle) = @_;
    print {$handle} $data;
  }
}

{
  my $name = "®icardo Sígnes";
  my $raw  = encode_utf8($name);

  my $output = WriterTester->write_string($name);
  is($output, $raw, "wrote a text string and got an octet string (UTF-8)");
}

{
  my $name = "Ĉamomile";
  my $raw  = encode('Latin-3', $name);

  my $output = WriterTester->write_string(
    { binmode => 'encoding(Latin-3)' },
    $name,
  );
  is($output, $raw, "wrote a text string and got an octet string (Latin-3)");
}

done_testing;
# vim: ts=2 sts=2 sw=2 et:

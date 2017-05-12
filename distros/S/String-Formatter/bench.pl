#!perl -l
use strict;
use lib 'lib';

use String::Formatter;

# Ha ha ha.  I am avoiding AutoPrereq from the following.
eval "
  use Benchmark;
  use Template;
  use String::Format;
";

my $hash = {
  a => 'apples',
  b => 'bananas',
};

my $fmt = String::Formatter->new({
  codes => $hash,
});

my $index_format = String::Format->stringfactory($hash);

my $tt2 = Template->new;

print $index_format->("I like to eat %a and %b.");
print $fmt->format("I like to eat %a and %b.");

$tt2->process(\'I like to eat [%a%] and [%b%].', $hash, \my $str);
print $str;

timethese(100_000, {
  dlc  => sub { $index_format->("I like to eat %a and %b.") },
  rjbs => sub { $fmt->format("I like to eat %a and %b.") },
  # tt2  => sub {
  #   $tt2->process(\'I like to eat [%a%] and [%b%].', $hash, \my $str);
  # },
  perl => sub { sprintf("I like to eat %s and %s.", qw(apples bananas)) },
});

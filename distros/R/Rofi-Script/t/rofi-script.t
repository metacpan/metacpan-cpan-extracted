use strict;
use warnings;
use v5.10;

use autodie qw( open close );

use Sub::Name;
use Test2::V0;
use Test2::Tools::Class;
use Test2::Tools::Exception;

use Rofi::Script;
use Rofi::Script::TestHelpers qw( rofi_shows );

my @tests = (
  subname(test_rofi => sub {
    isa_ok
      rofi,
      ['Rofi::Script'],
      'rofi init succeeded';
  }),

  subname(test_add_option => sub {
    rofi->add_option("Hello, world!");
    is
      rofi->{output_rows},
      ['Hello, world!'],
      "add option";

    rofi->add_option("Has mode options",
      foo => 'bar',
    );
    is
      rofi->{output_rows}->[1],
      ["Has mode options", { foo => 'bar' }],
      "add_option works with per-row mode options";
  }),

  subname(test_show => sub {
    my @options = qw( foo bar baz );
    my $want = join("\n", @options)."\n";

    rofi->add_option($_) for @options;

    rofi_shows
      "$want",
      'show prints to the show handle';
  }),

  subname(test_args => sub {
    my @args = qw( foo bar baz);
    rofi->{args} = \@args;
    is
      rofi->get_args,
      \@args,
      'get_args gets the args';

    for my $arg (@args) {
      is
        rofi->shift_arg,
        $arg,
        "shift got $arg";
    }
  }),

  subname(test_set_delim => sub {
    my @options = qw( foo bar baz );

    rofi->set_delim("XXX");
    rofi->add_option($_) for @options;

    rofi_shows
      "\0delim\x1fXXXXXXfooXXXbarXXXbazXXX",
      "set delim sets the delim";
  }),

  subname(test_set_prompt => sub {
    like
      dies {
        rofi->set_prompt();
      },
      qr/Need prompt/,
      'set_prompt dies when no prompt given';

    my $prompt = 'foo';
    rofi->set_prompt($prompt);

    rofi_shows
      "\0prompt\x1f$prompt\n",
      "set_prompt should probably set the prompt";
  }),
);

for my $test (@tests) {
  undef($Rofi::Script::rofi);
  $test->();
}

done_testing;
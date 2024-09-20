#!/bin/perl
use strict;
use warnings;

use Rofi::Script;

exit 1 unless rofi;

if (rofi->is_initial_call) {
  rofi
    ->set_message("Select a value below, or enter your own to see an error")
    ->set_prompt("Please select one")
    ->add_option("Show global options example")
    ->add_option("Show row options example");
}

SWITCH: for (rofi->shift_arg) {
    next unless $_;

    /Show global options example/ && do {
      rofi
        ->set_prompt("markup")
        ->enable_markup_rows
        ->set_no_custom
        ->set_message("This is a message row. It is set as global state. Also, you can't enter custom values now. That's a global state thing.")
        ->add_option("<i>This row uses pango markup. Enabling markup is a global option.</i>")
        ->add_option("This row is urgent. Marking a row as urgent is global state.", urgent => 1)
        ->add_option("Another normal row")
        ->add_option("You can have multiple urgent rows, just set the urgent flag on each row", urgent => 1);
      next;
    };

    /Show row options example/ && do {
      rofi
        ->set_prompt("row options")
        ->set_message(
          'The first row is nonselectable. The second has invisible search terms. Type "foobar" and it will be selected'
        )
        ->add_option(
          "This is nonselectable", (
            nonselectable => 1,
          ),
        )
        ->add_option(
          "This has metadata" => (
            meta => 'foobar'
          ),
        );
      next;
    };

    /Exit/ && do {
        exit 0;
    };

    rofi
      ->set_message("Unsupported option $_")
      ->add_option("Exit");
}

rofi->show;

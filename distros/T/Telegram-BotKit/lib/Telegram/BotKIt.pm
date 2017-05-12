package Telegram::BotKit;
$Telegram::BotKit::VERSION = '0.03';

use base 'Telegram::BotKit::Wizard';

# ABSTRACT: Set of Perl classes for creation of interactive and dynamic Telegram bots. Now bots can only process text, but work in progress :)




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::BotKit - Set of Perl classes for creation of interactive and dynamic Telegram bots. Now bots can only process text, but work in progress :)

=head1 VERSION

version 0.03

=head1 KEY FEATURES

=over 6

=item 1. State machine in JSON file

Allows to create a simple bots for house even for housewife

=item 2. Support of dymanic screens

screen = text [and/or] image [and/or] document [and/or] voice [and/or] location [and/or] reply markup

=item 3. Independent and prev msg dependent screens

Screens can be shown just according sequence in JSON or can depends on previous user reply (callback_msg property)

=item 4. Data validation

Bot can automatically control is last user reply valid and show pre-defined message if reply is not valid

=item 5. Smart serialization

At last screen bot is calling some perl function that uses some external API.

Bot store sequence of user inputs and can process data before calling serialize function

=item 6. Auto 'Go back' key

For convenience

=back

=head1 STATE DIAGRAM

=for html <img src="https://i.imgur.com/PqkaiXD.png" />

=head1 CONFIGURATION EXAMPLE 

Here is example of simple booking bot

=begin javascript




=end javascript

{
  "screens" : [
    { "name": "item_select", "start_command": "/book", "welcome_msg": "Please select an item to book", "keyboard":
      [
        { "key": "Item 1", "answ" : "Good" },
        { "key": "Item 2", "answ" : "Well" },
        { "key": "Item 3", "answ" : "Fine" }
      ] 
    }, 
    { "name": "day_select", "parent": "item_select", "welcome_msg": "Please select a day", "keyboard":
      [
        { "key": "today" }, 
        { "key": "tomorrow" }
      ]
    },
    { "name": "time_range_select", "parent": "day_select", "welcome_msg": "Please select atime range", "keyboard":
      [
        { "key": "morning", "answ" : "You are early bird" },
        { "key": "day", "answ" : "Good choice" },
        { "key": "evening", "answ" : "Owl" }
      ]
    },
    { "name": "morning_time_range_select", 
      "parent": "time_range_select", 
      "callback_msg": "morning", 
      "kb_build_func": "dynamic1_build_func"
    },
    { "name": "dynamic2", 
      "parent": "time_range_select", 
      "callback_msg": "day", 
      "kb_build_func": "dynamic2_build_func"
    },
    { "name": "info", "start_command": "/info", "welcome_msg": "Get info", "kb_build_func": "info_build_func" }
  ]
}

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

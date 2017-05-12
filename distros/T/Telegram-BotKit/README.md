# NAME

Telegram::BotKit - Set of Perl classes for creation of interactive and dynamic Telegram bots. Now bots can only process text, but work in progress :)

# VERSION

version 0.03

# KEY FEATURES

- 1. State machine in JSON file

    Allows to create a simple bots for house even for housewife

- 2. Support of dymanic screens

    screen = text \[and/or\] image \[and/or\] document \[and/or\] voice \[and/or\] location \[and/or\] reply markup

- 3. Independent and prev msg dependent screens

    Screens can be shown just according sequence in JSON or can depends on previous user reply (callback\_msg property)

- 4. Data validation

    Bot can automatically control is last user reply valid and show pre-defined message if reply is not valid

- 5. Smart serialization

    At last screen bot is calling some perl function that uses some external API.

    Bot store sequence of user inputs and can process data before calling serialize function

- 6. Auto 'Go back' key

    For convenience

# STATE DIAGRAM

<div>
    <img src="https://i.imgur.com/PqkaiXD.png" />
</div>

# CONFIGURATION EXAMPLE 

Here is example of simple booking bot

{
  "screens" : \[
    { "name": "item\_select", "start\_command": "/book", "welcome\_msg": "Please select an item to book", "keyboard":
      \[
        { "key": "Item 1", "answ" : "Good" },
        { "key": "Item 2", "answ" : "Well" },
        { "key": "Item 3", "answ" : "Fine" }
      \] 
    }, 
    { "name": "day\_select", "parent": "item\_select", "welcome\_msg": "Please select a day", "keyboard":
      \[
        { "key": "today" }, 
        { "key": "tomorrow" }
      \]
    },
    { "name": "time\_range\_select", "parent": "day\_select", "welcome\_msg": "Please select atime range", "keyboard":
      \[
        { "key": "morning", "answ" : "You are early bird" },
        { "key": "day", "answ" : "Good choice" },
        { "key": "evening", "answ" : "Owl" }
      \]
    },
    { "name": "morning\_time\_range\_select", 
      "parent": "time\_range\_select", 
      "callback\_msg": "morning", 
      "kb\_build\_func": "dynamic1\_build\_func"
    },
    { "name": "dynamic2", 
      "parent": "time\_range\_select", 
      "callback\_msg": "day", 
      "kb\_build\_func": "dynamic2\_build\_func"
    },
    { "name": "info", "start\_command": "/info", "welcome\_msg": "Get info", "kb\_build\_func": "info\_build\_func" }
  \]
}

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

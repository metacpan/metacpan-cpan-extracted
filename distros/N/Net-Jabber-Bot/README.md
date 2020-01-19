[![](https://github.com/toddr/perl-net-jabber-bot/workflows/linux/badge.svg)](https://github.com/toddr/perl-net-jabber-bot/actions) [![](https://github.com/toddr/perl-net-jabber-bot/workflows/macos/badge.svg)](https://github.com/toddr/perl-net-jabber-bot/actions) [![](https://github.com/toddr/perl-net-jabber-bot/workflows/windows/badge.svg)](https://github.com/toddr/perl-net-jabber-bot/actions)

# NAME

Net::Jabber::Bot - Automated Bot creation with safeties

# VERSION

Version 2.1.6

# SYNOPSIS

Program design:
This is a Moose based Class.

The idea behind the module is that someone creating a bot should not really have to know a whole lot about how the Jabber protocol works in order to use it. It also allows us to abstract away all the things that can get a bot maker into trouble. Essentially the object helps protect the coders from their own mistakes.

All someone should have to know and define in the program away from the object is:

- 1. Config - Where to connect, how often to do things, timers, etc
- 2. A subroutine to be called by the bot object when a new message comes in.
- 3. A subroutine to be called by the bot object every so often that lets the user do background activities (check logs, monitor web pages, etc.),

The object at present has the following enforced safeties as long as you do not override safety mode:

- 1. Limits messages per second, configurable at start up, (Max is 5 per second) by requiring a sleep timer in the message sending subroutine each time one is sent.
- 2. Endless loops of responding to self prevented by now allowing the bot message processing subroutine to know about messages from self
- 3. Forum join grace period to prevent bot from reacting to historical messages
- 4. Configurable aliases the bot will respond to per forum
- 5. Limits maximum message size, preventing messages that are too large from being sent (largest configurable message size limit is 1000).
- 6. Automatic chunking of messages to split up large messages in message sending subroutine
- 7. Limit on messages per hour. (max configurable limit of 125) Messages are visible via log4perl, but not ever be sent once the message limit is reached for that hour.

# FUNCTIONS

- **new**

    Minimal:

        my $bot = Net::Jabber::Bot->new(
            server               => 'host.domain.com', # Name of server when sending messages internally.
            conference_server    => 'conference.host.domain.com',
            port                 => 522,
            username             => 'username',
            password             => 'pasword',
            safety_mode          => 1,
            message_function     => \&new_bot_message,
            background_function  => \&background_checks,
            forums_and_responses => \%forum_list
        );

    All options:

        my $bot = Net::Jabber::Bot->new(
            server                  => 'host.domain.com', # Name of server when sending messages internally.
            conference_server       => 'conference.host.domain.com',
            server_host             => 'talk.domain.com', # used to specify what jabber server to connect to on connect?
            tls                     => 0,                    # set to 1 for google
            ssl_ca_path             => '',  # path to your CA cert bundle
            ssl_verify              => 0,   # for testing and for self-signed certificates
            connection_type         => 'tcpip',
            port                    => 522,
            username                => 'username',
            password                => 'pasword',
            alias                   => 'cpan_bot',
            message_function        => \&new_bot_message,
            background_function     => \&background_checks,
            loop_sleep_time         => 15,
            process_timeout         => 5,
            forums_and_responses    => \%forum_list,
            ignore_server_messages  => 1,
            ignore_self_messages    => 1,
            out_messages_per_second => 4,
            max_message_size        => 1000,
            max_messages_per_hour   => 100
        );

    Set up the object and connect to the server. Hash values are passed to new as a hash.

    The following initialization variables can be passed. Only marked variables are required (TODO)

    - **safety\_mode**

            safety_mode = (1,0)

        Determines if the bot safety features are turned on and enforced. This mode is on by default. Many of the safety features are here to assure you do not crash your favorite jabber server with floods, etc. DO NOT turn it off unless you're sure you know what you're doing (not just Sledge Hammer ceratin)

    - **server**

        Jabber server name

    - **server\_host**

        Defaults to the same value set for 'server' above.
        This is where the bot initially connects. For google for instance, you should set this to 'gmail.com'

    - **conference\_server**

        conferencee server (usually conference.$server\_name)

    - **port**

        Defaults to 5222

    - **tls**

        Boolean value. defaults to 0. for google, it is know that this value must be 1 to work.

    - **ssl\_ca\_path**

        The path to your CA cert bundle. This is passed on to XML::Stream eventually.

    - **ssl\_verify**

        Enable or disable server certificate validity check when connecting to server. This is passed on to XML::Stream eventually.

    - **connection\_type**

        defaults to 'tcpip' also takes 'http'

    - **username**

        The user you authenticate with to access the server. Not full name, just the stuff to the left of the @...

    - **password**

        password to get into the server

    - **alias**

        This will be your nickname in rooms, as well as the login resource (which can't have duplicates). I couldn't come up with any reason these should not be the same so hardcoded them to be the same.

    - **forums\_and\_responses**

        A hash ref which lists the forum names to join as the keys and the values are an array reference to a list of strings they are supposed to be responsive to.
        The array is order sensitive and an empty string means it is going to respond to all messages in this forum. Make sure you list this last.

        The found 'response string' is assumed to be at the beginning of the message. The message\_funtion function will be called with the modified string.

            alias = jbot:, attention:

        example1:

            message: 'jbot: help'

            passed to callback: 'help'

    - **message\_function**

        The subroutine the bot will call when a new message is recieved by the bot. Only called if the bot's logic decides it's something you need to know about.

    - **background\_function**

        The subroutine the bot will call when every so often (loop\_sleep\_time) to allow you to do background activities outside jabber stuff (check logs, web pages, etc.)

    - **loop\_sleep\_time**

        Frequency background function is called.

    - **process\_timeout**

        Time Process() will wait if no new activity is received from the server

    - **ignore\_server\_messages**

        Boolean value as to whether we should ignore messages sent to us from the jabber server (addresses can be a little cryptic and hard to process)

    - **ignore\_self\_messages**

        Boolean value as to whether we should ignore messages sent by us.

        BE CAREFUL if you turn this on!!! Turning this on risks potentially endless loops. If you're going to do this, please be sure safety is turned on at least initially.

    - **out\_messages\_per\_second**

        Limits the number of messages per second. Number must be &lt;gt> 0

        default: 5

        safety: 5

    - **max\_message\_size**

        Specify maximimum size a message can be before it's split and sent in pieces.

        default: 1,000,000

        safety: 1,000

    - **max\_messages\_per\_hour**

        Limits the number of messages per hour before we refuse to send them

        default: 125

        safety: 166

- **JoinForum**

    Joins a jabber forum and sleeps safety time. Also prevents the object
    from responding to messages for a grace period in efforts to get it to
    not respond to historical messages. This has failed sometimes.

    NOTE: No error detection for join failure is present at the moment. (TODO)

- **Process**

    Mostly calls it's client connection's "Process" call.
    Also assures a timeout is enforced if not fed to the subroutine
    You really should not have to call this very often.
    You should mostly be calling Start() and just let the Bot kernel handle all this.

- **Start**

    Primary subroutine save new called by the program. Does an endless loop of:

    - 1. Process
    - 2. If Process failed, Reconnect to server over larger and larger timeout
    - 3. run background process fed from new, telling it who I am and how many loops we have been through.
    - 4. Enforce a sleep to prevent server floods.

- **ReconnectToServer**

    You should not ever need to use this. the Start() kernel usually figures this out and calls it.

    Internal process:

        1. Disconnects
        3. Re-initializes

- **Disconnect**

    Disconnects from server if client object is defined. Assures the client object is deleted.

- **IsConnected**

    Reports connect state (true/false) based on the status of client\_start\_time.

- **\_process\_jabber\_message** - DO NOT CALL

    Handles incoming messages.

- **get\_responses**

        $bot->get_ident($forum_name);

    Returns the array of messages we are monitoring for in supplied forum or replies with undef.

- **\_jabber\_in\_iq\_message** - DO NOT CALL

    Called when the client receives new messages during Process of this type.

- **\_jabber\_presence\_message** - DO NOT CALL

    Called when the client receives new presence messages during Process.
    Mostly we are just pushing the data down into the client DB for later processing.

- **respond\_to\_self\_messages**

        $bot->respond_to_self_messages($value = 1);

    Tells the bot to start reacting to it\\'s own messages if non-zero is passed. Default is 1.

- **get\_messages\_this\_hour**

        $bot->get_messages_this_hour();

    replys with number of messages sent so far this hour.

- **get\_safety\_mode**

    Validates that we are in safety mode. Returns a bool as long as we are an object, otherwise returns undef

- **SendGroupMessage**

        $bot->SendGroupMessage($name, $message);

    Tells the bot to send a message to the recipient room name

- **SendPersonalMessage**

        $bot->SendPersonalMessage($recipient, $message);

    How to send an individual message to someone.

    $recipient must read as user@server/Resource or it will not send.

- **SendJabberMessage**

        $bot->SendJabberMessage($recipient, $message, $message_type, $subject);

    The master subroutine to send a message. Called either by the user, SendPersonalMessage, or SendGroupMessage. Sometimes there
    is call to call it directly when you do not feel like figuring you messaged you.
    Assures message size does not exceed a limit and chops it into pieces if need be.

    NOTE: non-printable characters (unicode included) will be stripped before sending to the server via:
        s/\[^\[:print:\]\]+/./xmsg

- **SetForumSubject**

        $bot->SetForumSubject($recipient, $subject);

    Sets the subject of a forum

- **ChangeStatus**

        $bot->ChangeStatus($presence_mode, $status_string);

    Sets the Bot's presence status.
    $presence mode could be something like: (Chat, Available, Away, Ext. Away, Do Not Disturb).
    $status\_string is an optional comment to go with your presence mode. It is not required.

- **GetRoster**

        $bot->GetRoster();

    Returns a list of the people logged into the server.
    I suspect we really want to know who is in a paticular forum right?
    In which case we need another sub for this.

- **GetStatus**

    Need documentation from Yago on this sub.

- **AddUser**

    Need documentation from Yago on this sub.

- **RmUser**

    Need documentation from Yago on this sub.

# AUTHOR

Todd Rinaldo `<perl-net-jabber-bot@googlegroups.com) >`

# BUGS

Please report any bugs or feature requests to
`perl-net-jabber-bot@googlegroups.com`, or through the web interface at
[http://code.google.com/p/perl-net-jabber-bot/issues/entry](http://code.google.com/p/perl-net-jabber-bot/issues/entry).
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Jabber::Bot

You can also look for information at:

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Net-Jabber-Bot](http://annocpan.org/dist/Net-Jabber-Bot)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Net-Jabber-Bot](http://cpanratings.perl.org/d/Net-Jabber-Bot)

- Metacpan

    [https://metacpan.org/pod/Net::Jabber::Bot](https://metacpan.org/pod/Net::Jabber::Bot)

- Github

    [https://github.com/toddr/perl-net-jabber-bot](https://github.com/toddr/perl-net-jabber-bot)

# ACKNOWLEDGEMENTS

# COPYRIGHT & LICENSE

Copyright 2007 Todd E Rinaldo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

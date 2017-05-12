# NAME

Skype::Any - Skype API wrapper for Perl

# SYNOPSIS

    use Skype::Any;

    # ping-pong bot

    my $skype = Skype::Any->new();
    $skype->message_received(sub {
        my ($msg) = @_;
        my $body = $msg->body;
        if ($body eq 'ping') {
            $msg->chat->send_message('pong');
        }
    });
    $skype->run;

## STARTING

1. Start Skype

    If you can use Skype API, you have to start Skype.

2. Allow API access

    When you start the script using Skype::Any, "Skype API Security" dialog will open automatically. Select "Allow this application to use Skype".

    <div><img src="https://raw.github.com/akiym/Skype-Any/master/img/dialog.png" /></div>

3. Manage API access

    You can set the name of your application.

        my $skype = Skype::Any->new(
            name => 'MyApp',
        );

    <div><img src="https://raw.github.com/akiym/Skype-Any/master/img/myapp-dialog.png" /></div>

    You can manage your application and select allow/disallow API access.

    <div><img src="https://raw.github.com/akiym/Skype-Any/master/img/manage.png" /></div>

    It described with Mac, but you can do the same with Linux.

# DESCRIPTION

Skype::Any is Skype API wrapper. It was inspired by Skype4Py.

Note that Skype::Any is using Skype Desktop API. However, Skype Desktop API will stop working in December 2013. You can not use lastest version of Skype.

# METHODS

- `my $skype = Skype::Any->new()`

    Create an instance of Skype::Any.

    - name => 'Skype::Any' : Str

        Name of your application. This name will be shown to the user, when your application uses Skype.

    - protocol => 8 : Num

        Skype protocol number.

- `$skype->attach()`

    Attach to Skype. However, you need not call this method. When you call `$skype->run()`, it will be attach to Skype automatically.

    If you want to manage event loop, you have to call this method. e.g. running with Twiggy:

        $skype->attach;

        my $twiggy = Twiggy::Server->new(
            host => $http_host,
            port => $http_port,
        );
        $twiggy->register_service($app);

        $skype->run;

- `$skype->run()`

    Running an event loop. You have to call this method at the end.

- `$skype->message_received(sub { ... })`

        $skype->message_received(sub {
          my ($chatmessage) = @_;

          ...
        });

    Register 'chatmessage' handler for when a chat message is coming.

- `$skype->create_chat_with($username, $message)`

    Send a $message to $username.

    Alias for:

        $skype->user($username)->chat->send_message($message);

## OBJECTS

- `$skype->user($id)`

    Create new instance of [Skype::Any::Object::User](https://metacpan.org/pod/Skype::Any::Object::User).

        $skype->user(sub { ... })

    Register \_ (default) handler.

        $skype->user($name => sub { ... }, ...)

    Register $name handler.

        $skype->user($id);
        $skype->user(sub {
        });
        $skype->user($name => sub {
        });

    this code similar to:

        $skype->object(user => $id);
        $skype->object(user => sub {
        });
        $skype->object(user => $name => sub {
        });

    `$skype->profile`, `$skype->call`, ..., these methods are the same operation.

- `$skype->profile()`

    Note that this method takes no argument. Profile object doesn't have id.

    [Skype::Any::Object::Profile](https://metacpan.org/pod/Skype::Any::Object::Profile)

- `$skype->call()`

    [Skype::Any::Object::Call](https://metacpan.org/pod/Skype::Any::Object::Call)

- `$skype->message()`

    Deprecated in Skype protocol 3. Use `Skype::Any::Object::ChatMessage`.

    [Skype::Any::Object::Message](https://metacpan.org/pod/Skype::Any::Object::Message)

- `$skype->chat()`

    [Skype::Any::Object::Chat](https://metacpan.org/pod/Skype::Any::Object::Chat)

- `$skype->chatmember()`

    [Skype::Any::Object::ChatMember](https://metacpan.org/pod/Skype::Any::Object::ChatMember)

- `$skype->chatmessage()`

    [Skype::Any::Object::ChatMessage](https://metacpan.org/pod/Skype::Any::Object::ChatMessage)

- `$skype->voicemail()`

    [Skype::Any::Object::VoiceMail](https://metacpan.org/pod/Skype::Any::Object::VoiceMail)

- `$skype->sms()`

    [Skype::Any::Object::SMS](https://metacpan.org/pod/Skype::Any::Object::SMS)

- `$skype->application()`

    [Skype::Any::Object::Application](https://metacpan.org/pod/Skype::Any::Object::Application)

- `$skype->group()`

    [Skype::Any::Object::Group](https://metacpan.org/pod/Skype::Any::Object::Group)

- `$skype->filetransfer()`

    [Skype::Any::Object::FileTransfer](https://metacpan.org/pod/Skype::Any::Object::FileTransfer)

## ATTRIBUTES

- `$skype->api`

    Instance of [Skype::Any::API](https://metacpan.org/pod/Skype::Any::API). You can call Skype API directly. e.g. send "Happy new year!" to all recent chats.

        my $reply = $skype->api->send_command('SEARCH RECENTCHATS')->reply;
        $reply =~ s/^CHATS\s+//;
        for my $chatname (split /,\s+/ $reply) {
            my $chat = $skype->chat($chatname);
            $chat->send_message('Happy new year!");
        }

- `$skype->handler`

    Instance of [Skype::Any::Handler](https://metacpan.org/pod/Skype::Any::Handler). You can also register a handler:

        $skype->handler->register($name, sub { ... });

# SUPPORTS

Skype::Any working on Mac and Linux. But it doesn't support Windows. Patches welcome.

# SEE ALSO

[Public API Reference](https://developer.skype.com/public-api-reference)

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama <t.akiym@gmail.com>

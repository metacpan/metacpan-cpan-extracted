# NAME

TeamCity::Message - Generate TeamCity build messages

# VERSION

version 0.02

# SYNOPSIS

    use TeamCity::Message;

    print STDOUT tc_message(
        type    => 'message',
        content => { text => 'This is a build message.' },
    );

    print STDOUT tc_message(
        type    => 'message',
        content => {
            text   => 'This is a serious build message.',
            status => 'ERROR',
        },
    );

    print STDOUT tc_message(
        type    => 'progressMessage',
        content => 'This is a progress message',
    );

# DESCRIPTION

This module generates TeamCity build messages.

See
[https://confluence.jetbrains.com/display/TCD9/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-reportingMessagesForBuildLogReportingMessagesForBuildLog](https://confluence.jetbrains.com/display/TCD9/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-reportingMessagesForBuildLogReportingMessagesForBuildLog)
for more details on TeamCity build messages.

# API

## tc\_message(...)

Exported by default, this subroutine can be used to generate properly formatted
and escaped TeamCity build message.

This subroutine accepts the following arguments:

- type

    This is the message type, such as "message", "testStarted", "testFinished",
    etc.

    This is required.

- content

    This can be either a string or a hash reference of key/value pairs. This will
    be turned into the content of the message.

    This is required.

When the `content` parameter is a hash reference, this subroutine will always
add a "timestamp" to the message matching the current time. You can provide an
explicit `timestamp` value in the `content` if you want to set this
yourself.

## tc\_timestamp()

Exported on demand, this subroutine will return a string containing the current
timestamp formatted suitably for consumption by TeamCity.  You can pass this
to the `tc_message(...)` function like so:

    my $remembered_timestamp = tc_timestamp();

    # ...time passes...

    print STDOUT tc_message(
        type    => 'message',
        content => {
            text => 'This is a build message.',
            timestamp => $remembered_timestamp,
        }
    );

# SUPPORT

Please report all issues with this code using the GitHub issue tracker at
[https://github.com/maxmind/TeamCity-Message/issues](https://github.com/maxmind/TeamCity-Message/issues).

Bugs may be submitted through [https://github.com/maxmind/TeamCity-Message/issues](https://github.com/maxmind/TeamCity-Message/issues).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Dave Rolsky <drolsky@maxmind.com>
- Mark Fowler <mark@twoshortplanks.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc..

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

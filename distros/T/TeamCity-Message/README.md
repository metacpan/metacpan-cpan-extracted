# NAME

TeamCity::Message - Generate TeamCity build messages

# VERSION

version 0.01

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
https://confluence.jetbrains.com/display/TCD9/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-reportingMessagesForBuildLogReportingMessagesForBuildLog
for more details on TeamCity build messages.

# API

This module provides a single subroutine exported by default, `tc_message`,
which can be used to generate properly formatted and escaped TeamCity build
messages.

## tc\_message(...)

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

# SUPPORT

Please report all issues with this code using the GitHub issue tracker at
[https://github.com/maxmind/TeamCity-Message/issues](https://github.com/maxmind/TeamCity-Message/issues).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTOR

Dave Rolsky <drolsky@maxmind.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by MaxMind, Inc..

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

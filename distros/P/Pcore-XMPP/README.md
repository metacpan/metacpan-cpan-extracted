# NAME

Pcore::XMPP

# SYNOPSIS

    use Pcore::XMPP;

    Pcore::XMPP->add_account(
        username        => 'no-reply@softvisio.net',
        password        => 'password',
        host            => 'talk.google.com',
        port            => undef,              # 5222 by default
        connection_args => undef,
        on_message      => sub ( $from, $data, $reply ) {
            $reply->(time);

            return;
        },
    );

    Pcore::XMPP->sendmsg( 'no-reply@softvisio.net', 'zdm@softvisio.net', 'message' );

# DESCRIPTION

# ATTRIBUTES

# METHODS

# SEE ALSO

# AUTHOR

zdm <zdm@softvisio.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

# NAME

Pcore::XMPP

# SYNOPSIS

    # create handle
    my $xmpp = P->handle('xmpp://username:password@gmail.com?gtalk');

    # send message
    $xmpp->sendmsg( 'to_user@gmail.com', 'message' );

    # create log channel
    P->log->add( 'channel', 'xmpp://username:password@gmail.com?gtalk&to=to_user@gmail.com' );

# DESCRIPTION

# ATTRIBUTES

# METHODS

# SEE ALSO

# AUTHOR

zdm <zdm@softvisio.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

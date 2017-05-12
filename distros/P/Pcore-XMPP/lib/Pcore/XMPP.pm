package Pcore::XMPP v0.8.1;

use Pcore -dist;

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::XMPP

=head1 SYNOPSIS

    # create handle
    my $xmpp = P->handle('xmpp://username:password@gmail.com?gtalk');

    # send message
    $xmpp->sendmsg( 'to_user@gmail.com', 'message' );

    # create log channel
    P->log->add( 'channel', 'xmpp://username:password@gmail.com?gtalk&to=to_user@gmail.com' );

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut

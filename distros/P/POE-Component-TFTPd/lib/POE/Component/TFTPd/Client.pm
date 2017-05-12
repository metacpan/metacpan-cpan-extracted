package POE::Component::TFTPd::Client;

=head1 NAME

POE::Component::TFTPd::Client

=head1 VERSION

See L<POE::Component::TFTPd>

=cut

use strict;
use warnings;
use POE::Component::TFTPd;

my %defaults = (
    id           => undef,
    address      => undef,
    port         => undef,
    retries      => 0,
    timestamp    => 0,
    last_block   => 0,
    block_size   => 0,
    rrq          => 0,
    wrq          => 0,
    filename     => q(),
    mode         => q(),
    rfc          => [], # remember to override in new!
    almost_done  => 0,
    resent_block => 0,
);

=head1 METHODS

=head2 new

=cut

sub new {
    my $class  = shift;
    my $tftpd  = shift;
    my $client = shift;

    return bless {
        %defaults,
        id         => join(":", $client->{'addr'}, $client->{'port'}),
        address    => $client->{'addr'},
        port       => $client->{'port'},
        block_size => POE::Component::TFTPd::TFTP_MIN_BLKSIZE(),
        retries    => $tftpd->retries,
        rfc        => [],
    }, $class;
}

=head2 id

=head2 address

=head2 port

=head2 retries

=head2 timestamp

=head2 last_block

=head2 block_size

=head2 rrq

=head2 wrq

=head2 filename

=head2 mode

=head2 rfc

=head2 almost_done

=head2 resent_block

=cut

{
    no strict 'refs';
    for my $sub (keys %defaults) {
        *$sub = sub :lvalue { shift->{$sub} };
    }
}

=head1 AUTHOR

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

See L<POE::Component::TFTPd>

=cut

1;

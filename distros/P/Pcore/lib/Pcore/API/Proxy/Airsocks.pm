package Pcore::API::Proxy::Airsocks;

use Pcore -class, -res, -const;
use Pcore::API::Proxy;

our $EXPORT = { AIRSOCKS_FP => [qw[$AIRSOCKS_FP_WIN $AIRSOCKS_FP_WIN_FUZZY $AIRSOCKS_FP_WINXP $AIRSOCKS_FP_ANDROID $AIRSOCKS_FP_MACOS $AIRSOCKS_FP_IOS $AIRSOCKS_FP_NT $AIRSOCKS_FP_NT_FUZZY  $AIRSOCKS_FP_UNKNOWN]], };

has proxy       => ( required => 1 );
has session_key => ( required => 1 );
has channel_id  => ( required => 1 );

has changed => ( init_arg => undef );
has ip      => ( init_arg => undef );
has fp      => ( init_arg => undef );

has _change_ip_url => ( init_arg => undef );
has _status_url    => ( init_arg => undef );

const our $AIRSOCKS_FP_WIN       => 'win';            # Windows 7 or 8 (and Windows 8.1)
const our $AIRSOCKS_FP_WIN_FUZZY => 'win fuzzy';      # Windows 7 or 8 [fuzzy] is common on Windows Server 2012
const our $AIRSOCKS_FP_WINXP     => 'winxp';          # Windows XP:
const our $AIRSOCKS_FP_ANDROID   => 'android';        # Android (Linux 2.2.x-3.x):
const our $AIRSOCKS_FP_MACOS     => 'isfuzzy';        # 'Mac OS X [generic][fuzzy]' (MacBook / OS X / iPhone)
const our $AIRSOCKS_FP_IOS       => 'ios';            # 'MacOS X [generic]' less popular option for MacBook / OS X / iPhone
const our $AIRSOCKS_FP_NT        => 'net generic';    # 'Windows NT [generic]' which is the most common OS currently Windows 10 / Windows 2016 Server.
const our $AIRSOCKS_FP_NT_FUZZY  => 'ntfuzzy';        # 'Windows NT [generic][fuzzy]' is an option for Windows 10 / Windows 2016 Server.
const our $AIRSOCKS_FP_UNKNOWN   => 'unknown';        # '???'in the system definition. In other words, Passive OS Fingerprint (TCP/IP) will be hidden.

around new => sub ( $orig, $self, $url, $key ) {
    $url = P->uri($url);

    my $args = {
        proxy       => Pcore::API::Proxy->new($url),
        session_key => $key,
        channel_id  => substr( $url->{port}, -1, 1 ),
    };

    return $self->$orig($args);
};

sub change_ip ( $self, $nowait = undef ) {
    my $url = $self->{_change_ip_url} //= P->uri("http://$self->{proxy}->{uri}->{host}/api/v3/changer_channels/channel_$self->{channel_id}?session=$self->{session_key}");

  REDO:
    my $res = P->http->get($url);

    if ($res) {
        if ( $res->{data}->$* =~ /wait\s+(\d+)s/sm ) {
            return res 400 if $nowait;

            Coro::sleep( $1 + 1 );

            goto REDO;
        }

        my $headers;

        for my $line ( split /\n/sm, $res->{data}->$* ) {
            my ( $k, $v ) = split /:\s*/sm, $line, 2;

            $headers->{ lc $k } = $v;
        }

        $self->{ip}      = $headers->{newip};
        $self->{fp}      = $headers->{osfingeprint};
        $self->{changed} = $headers->{at};
    }

    return res $res;
}

# TODO
# &fp=
sub change_fp ( $self, $fp ) {
    my $url = P->uri( "http://$self->{proxy}->{uri}->{host}/api/v3/changer_channels/channel_$self->{channel_id}?session=$self->{session_key}&fp=" . P->data->to_uri($fp) );

    my $res = P->http->get($url);

    return $res;
}

# TODO
sub get_status ($self) {
    my $url = $self->{_status_url} //= P->uri("http://$self->{proxy}->{uri}->{host}/api/v3/changer_channels/channel_$self->{channel_id}/status?session=$self->{session_key}");

    my $res = P->http->get($url);

    return $res;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Proxy::Airsocks

=head1 SYNOPSIS

    use Pcore::API::Proxy::Airsocks;

    my $proxy = Pcore::API::Proxy::Airsocks->new( 'connect://user:password@host:port', 'session_key' );

    P->http->get( $url, $proxy => proxy->{proxy} );

    $proxy->change_ip;

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut

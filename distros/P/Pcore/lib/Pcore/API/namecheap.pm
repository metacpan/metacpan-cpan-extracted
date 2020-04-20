package Pcore::API::namecheap;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[is_plain_arrayref];

has api_user => ( required => 1 );
has api_key  => ( required => 1 );
has api_ip   => ( required => 1 );
has proxy    => ();

sub test ($self) {
    my $res = $self->check_domains('google.com');

    return $res;
}

# https://www.namecheap.com/support/api/methods/domains/get-tld-list.aspx
sub get_tld_list ($self) {

    my $params = { Command => 'namecheap.domains.gettldlist', };

    my $res = $self->_req($params);

    if ($res) {
        my $data;

        for my $item ( $res->{data}->{Tlds}->[0]->{Tld}->@* ) {
            $data->{ $item->{Name}->[0]->{content} } = 1;
        }

        $res->{data} = $data;
    }

    return $res;
}

# https://www.namecheap.com/support/api/methods/domains/check.aspx
# NOTE max 100 domains are allowed, 30 is recommneded
sub check_domains ( $self, $domains ) {
    $domains = [$domains] if !is_plain_arrayref $domains;

    my $params = {
        Command    => 'namecheap.domains.check',
        DomainList => join( ',', $domains->@* ),
    };

    my $res = $self->_req($params);

    if ($res) {
        my ( $idx, $data );

        for my $item ( $res->{data}->{DomainCheckResult}->@* ) {
            $idx->{ $item->{Domain}->[0]->{content} } = $item->{Available}->[0]->{content} eq 'true' ? 1 : 0;
        }

        for my $domain ( $domains->@* ) {
            $data->{$domain} = $idx->{$domain};
        }

        $res->{data} = $data;
    }

    return $res;
}

sub _req ( $self, $params ) {
    my $url_params = {
        ApiUser  => $self->{api_user},
        ApiKey   => $self->{api_key},
        ClientIp => $self->{api_ip},
        UserName => $self->{api_user},
        $params->%*
    };

    my $res = P->http->get(
        'https://api.namecheap.com/xml.response?' . P->data->to_uri($url_params),
        timeout => 60,
        proxy   => $self->{proxy},
    );

    return res $res if !$res;

    my $data = eval { P->data->from_xml( $res->{data} ) };

    return res [ 500, 'Error decoding xml' ] if $@;

    if ( !$data->{ApiResponse}->{CommandResponse} ) {
        return res [ 400, $data->{ApiResponse}->{Errors}->[0]->{Error}->[0]->{content} || 'Unknown api error' ];
    }

    return res 200, $data->{ApiResponse}->{CommandResponse}->[0];
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::namecheap

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut

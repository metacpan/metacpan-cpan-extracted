package Pcore::API::Sitemap;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[is_uri];

has _host_cv => sub { {} };

sub get_sitemap ( $self, $host, $lastmod = undef ) {
    my $cv = P->cv;

    if ( !$self->{_host_cv}->{$host} ) {
        Coro::async_pool sub ( $host, $lastmod ) {
            $self->_run_sitemap_thread( $host, $lastmod );

            return;
        }, $host, $lastmod;
    }

    push $self->{_host_cv}->{$host}->@*, $cv;

    return $cv->recv;
}

sub _run_sitemap_thread ( $self, $host, $lastmod ) {
    $lastmod = P->date->from_string( $lastmod, lenient => 1 ) if $lastmod;

    my $init_url = "http://$host/sitemap.xml";

    my $idx   = { "$init_url" => undef };
    my $queue = [$init_url];
    my $sitemap;

    while () {
        my $url = shift $queue->@*;

        last if !$url;

        my $res = $self->_get_xml($url);

        if ($res) {
            for my $item ( $res->{data}->{sitemapindex}->{sitemap}->@* ) {
                my $loc = $item->{loc}->[0]->{content};

                next if exists $idx->{$loc};

                my $loc_lastmod = $item->{lastmod}->[0]->{content};

                if ( $lastmod && $loc_lastmod ) {
                    $loc_lastmod = P->date->from_string($loc_lastmod);

                    next if $loc_lastmod <= $lastmod;
                }

                $idx->{$loc} = undef;
                push $queue->@*, $loc;
            }

            for my $item ( $res->{data}->{urlset}->{url}->@* ) {
                my $loc = $item->{loc}->[0]->{content};

                next if exists $sitemap->{$loc};

                my $loc_lastmod = $item->{lastmod}->[0]->{content};

                if ( $lastmod && $loc_lastmod ) {
                    $loc_lastmod = P->date->from_string($loc_lastmod);

                    next if $loc_lastmod <= $lastmod;
                }

                $sitemap->{$loc} = "$loc_lastmod";
            }
        }
    }

    while ( my $cv = shift $self->{_host_cv}->{$host}->@* ) {
        $cv->( res 200, $sitemap );
    }

    delete $self->{_host_cv}->{$host};

    return;
}

sub _get_xml ( $self, $url ) {
    my $res = P->http->get($url);

    if ( $res && $res->{headers}->{'content-type'} =~ m[text/xml]sm ) {
        my $xml = eval {
            my $data = $res->decoded_data;

            $data =~ s[<[?]xml-stylesheet.+?>][]sm;

            P->data->from_xml($data);
        };

        if ($@) {
            $res = res [ 500, 'Bad XML' ];
        }
        else {
            $res = res 200, $xml;
        }
    }

    say "get sitemap: $res, $url";

    return $res;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Sitemap

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut

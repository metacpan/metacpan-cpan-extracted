package TaskPipe::UserAgentManager::UserAgentHandler_WhoIs;

use Moose;
extends 'TaskPipe::UserAgentManager::UserAgentHandler';
use Try::Tiny;
use Encode;
with 'MooseX::ConfigCascade';
use Net::Whois::Raw::Proxied 'whois';

has proxy_addr => (is => 'rw', isa => 'Str');
has proxy_port => (is => 'rw', isa => 'Int');


sub get{
    my ($self, $domain) = @_;

    my $resp_code = '200';
    my $content;

    try {

        $content = whois( 
            $domain,
            undef,
            undef,
            +$self->proxy_addr,
            +$self->proxy_port
        );

    } catch {

        $resp_code = '400';

    };

    my $resp = HTTP::Response->new;
    $resp->code( $resp_code );
    $resp->content( encode('utf-8',$content) );

    return $resp;
                    
}


sub call{
    my ($self, $method, @params) = @_;

    my $resp;

    if ( $method eq 'get' ){

        $resp = $self->get( @params );

    } elsif ( $method eq 'proxy' ){

        $self->set_proxy( @params );

    } else {

        confess "method $method not recognised";

    }

    return $resp;
}


sub set_proxy{
    my ($self,$protocols,$url) = @_;

    my ($scheme,$host,$port) = $url =~ m{^([^:]+)://([^:]+):([^:]+)$};

    if ( $host && $port ){
        $self->proxy_addr( $host );
        $self->proxy_port( $port );
    } else {
        confess "set_proxy called but host and/or port were not defined";
    }
}


1;


    

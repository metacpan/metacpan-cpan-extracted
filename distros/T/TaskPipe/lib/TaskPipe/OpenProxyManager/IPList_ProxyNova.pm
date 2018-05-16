package TaskPipe::OpenProxyManager::IPList_ProxyNova;

use Moose;
extends 'TaskPipe::OpenProxyManager::IPList';
use Web::Scraper;
use Module::Runtime 'require_module';
use Data::Dumper;


has page_index_ws => (is => 'ro', isa => 'Web::Scraper', default => sub{
    scraper {
        process_first 'select[name=proxy_country]', 'country_select' => scraper {
            process 'option', 'country_code[]' => '@value';
            result 'country_code';
        };
        result 'country_select';
    };
});

has ws => (is => 'ro', isa => 'Web::Scraper', default => sub{
    scraper {
        process 'tr[data-proxy-id]', 'tr[]' => scraper {
            process_first 'td:first-child', 'ip' => 'TEXT';
            process_first 'td:nth-child(2) a', port => 'TEXT';
        };
        result 'tr';
    }
});


sub page_index_url{
    my ($self) = @_;

    return +$self->list_settings->countries_url;

}


sub scrape_page_index{
    my ($self,$resp,$url) = @_;

    my $index = $self->page_index_ws->scrape( 
        $resp->decoded_content, 
        $url
    );
    return $index;
}
    



sub url_from_page_index{
    my ($self,$country) = @_;

    my $url = $self->list_settings->url_template;
    $url =~ s/<country_code>/$country/;
    return $url;

}


=head1 NAME

TaskPipe::OpenProxyManager::IPList_ProxyNova - ProxyNova IP List

=head1 DESCRIPTION

Provides methods to get the IP List from the ProxyNova service. It is not recommended to use this package directly

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3


=cut

__PACKAGE__->meta->make_immutable;
1;
        
           

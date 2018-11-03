package TaskPipe::OpenProxyManager::IPList_Xroxy;

use Moose;
extends 'TaskPipe::OpenProxyManager::IPList';
use Web::Scraper;
use Module::Runtime 'require_module';
use Data::Dumper;


has ws => (is => 'ro', isa => 'Web::Scraper', default => sub{
    scraper {
        process 'tr.row0,tr.row1', 'row[]' => scraper {
            process_first 'td:nth-child(2) a', 'ip' => 'TEXT';
            process_first 'td:nth-child(3) a', 'port' => 'TEXT';
        };
        result 'row';
    };
});

has page_index_ws => (is => 'ro', isa => 'Web::Scraper', default => sub{
    scraper {
        process_first 'table.tbl table tr:last-child td b', 'num_proxies' => 'TEXT';
        result 'num_proxies';
    };
});


sub url_from_page_index{
    my ($self,$page_i) = @_;

    my $f_page_i = $page_i - 1;
    my $url = $self->list_settings->url_template;
    $url =~ s/<page>/$page_i/;
    return $url;

}


has list_settings => (
    is => 'ro', 
    isa => 'TaskPipe::OpenProxyManager::IPList_Xroxy::Settings'
);



sub page_index_url{
    my ($self) = @_;

    $self->url_from_page_index( 0 );
}


sub scrape_page_index{
    my ($self,$resp,$url) = @_;

    my $num_proxies = $self->page_index_ws->scrape( $resp->decoded_content, $url );
    my $max_page = int( $num_proxies / +$self->list_settings->proxies_per_page );
    return +[0..$max_page];
}


=head1 NAME

TaskPipe::OpenProxyManager::IPList_Xroxy - Xroxy IP List

=head1 DESCRIPTION

Provides methods to get the IP List from the Xroxy service. It is not recommended to use this package directly

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3


=cut

1;

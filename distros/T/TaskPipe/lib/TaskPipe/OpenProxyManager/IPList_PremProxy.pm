package TaskPipe::OpenProxyManager::IPList_PremProxy;

use Moose;
use WWW::Mechanize::PhantomJS;
use Web::Scraper;
use Data::Dumper;
use Module::Runtime 'require_module';
with 'MooseX::ConfigCascade';
with 'TaskPipe::Role::RunInfo';
extends 'TaskPipe::OpenProxyManager::IPList';



has ws => (is => 'ro', isa => 'Web::Scraper', default => sub{
    scraper {
        process 'td[data-label="IP:port "]', 'ip_port[]' => scraper{
            process_first 'td[data-label="IP:port "]', 'ip' => [ 'TEXT' => sub {
                my ($ip) = $_[0] =~ /(\d+\.\d+\.\d+\.\d+)/;
                return $ip;
            }];
            process_first 'td[data-label="IP:port "]', 'port' => [ 'TEXT' => sub {
                my ($port) = $_[0] =~ /\d+\.\d+\.\d+\.\d+\s*:\s*(\d+)/;
                return $port;
            }];
        };
            
        result 'ip_port';
    };
});


has last_page_index_ws => (is => 'ro', isa => 'Web::Scraper', default => sub{
    scraper {
        process 'ul.pagination li:nth-last-child(2) a', 'page_num' => 'TEXT';
        result 'page_num';
    };
});


sub page_index_url{
    return +$_[0]->url_from_page_index( 1 );
}


sub url_from_page_index{
    my ($self,$page_num) = @_;

    my $page_num_f = sprintf($self->list_settings->page_num_format,$page_num);
    my $url = $self->list_settings->url_template;
    $url =~ s/<page_num>/$page_num_f/;  
    return $url;
}



=head1 NAME

TaskPipe::OpenProxyManager::IPList_PremProxy - PremProxy IP List

=head1 DESCRIPTION

Provides methods to get the IP List from the PremProxy service. It is not recommended to use this package directly

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;

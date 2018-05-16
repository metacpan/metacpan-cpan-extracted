package TaskPipe::Template_Task_SP500ScrapeQuote;

use Moose;
extends 'TaskPipe::Template_Task';

has name => (is => 'ro', isa => 'Str', default => 'Scrape_Quote');
has template => (is => 'ro', isa => 'Str', default => 

q|##################################################################
# 
#     Sample task:
#     Scrape a quote from an S&P500 Company as listed on
#     Wikipedia from the URL Wikipedia provides
#
##################################################################

package <% task_module_prefix %>::<% task_identifier %><% name %>;

use Moose;
use Web::Scraper;
extends 'TaskPipe::Task_Scrape';


has test_pinterp => ( is => 'ro', isa => 'ArrayRef[HashRef]', default => sub{[

    {
        url => 'https://www.nyse.com/quote/XNYS:MMM',
        headers => {
            Referer => 'https://www.google.com'
        }
    }

]});


has ws => (is => 'ro', isa => 'Web::Scraper', default => sub {
    scraper {
        process_first 'span.d-dquote-x3', 'quote' => 'TEXT';
    }
});


sub post_process{
    my ($self,$scraped) = @_;
    return [ $scraped ];
}


has poll_for => (is => 'rw', isa => 'ArrayRef[Str]', default => sub{[
    'span.d-dquote-x3'
]});

1;|);

=head1 NAME

TaskPipe::Template_Task_SP500ScrapeQuote - template for the Scrape_Quote task in the SP500 sample project

=head1 DESCRIPTION

Template for the Scrape_Quote task in the SP500 sample project

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut




1;

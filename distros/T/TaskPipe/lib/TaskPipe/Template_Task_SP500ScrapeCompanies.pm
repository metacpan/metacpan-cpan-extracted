package TaskPipe::Template_Task_SP500ScrapeCompanies;

use Moose;
extends 'TaskPipe::Template_Task';

has name => (is => 'ro', isa => 'Str', default => 'Scrape_Companies');
has template => (is => 'ro', isa => 'Str', default => 

q|##################################################################
# 
#     Sample task:
#     Scrape List of S&P500 Companies from Wikipedia
#
##################################################################

package <% task_module_prefix %>::<% task_identifier %><% name %>;

use Moose;
use Web::Scraper;
extends 'TaskPipe::Task_Scrape';


has test_pinterp => (is => 'ro', isa => 'ArrayRef[HashRef]', default => sub{[

    {
        url => 'https://en.wikipedia.org/wiki/List_of_S%26P_500_companies',
        headers => {
            Referer => 'https://www.google.com'
        }
    }

]});


has ws => (is => 'ro', isa => 'Web::Scraper', default => sub {
    scraper {
        process_first 'table.wikitable', 'table' => scraper {
            process 'tr + tr', 'tr[]' => scraper {
                process_first 'td:nth-child(1) a', 'ticker' => 'TEXT';
                process_first 'td:nth-child(1) a', 'url' => ['@href',sub{ $_[0]->as_string }];
                process_first 'td:nth-child(2) a', 'name' => 'TEXT';
                process_first 'td:nth-child(4)', 'sector' => 'TEXT';
                process_first 'td:nth-child(5)', 'industry' => 'TEXT';
                process_first 'td:nth-child(6)', 'address' => 'TEXT';
                process_first 'td:nth-child(7)', 'date_added' => 'TEXT';
                process_first 'td:nth-child(8)', 'cik' => 'TEXT';
            };
            result 'tr';
        };
        result 'table';
    };
});

1;|);

=head1 NAME

TaskPipe::Template_Task_SP500Scrape_Companies - template for the Scrape_Companies task in the SP500 sample project

=head1 DESCRIPTION

Template for the Scrape_Companies task in the SP500 sample project

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


1;


    

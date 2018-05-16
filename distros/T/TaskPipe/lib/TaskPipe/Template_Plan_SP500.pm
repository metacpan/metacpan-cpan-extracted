package TaskPipe::Template_Plan_SP500;

use Moose;
extends 'TaskPipe::Template_Plan';

has template => (is => 'ro', isa => 'Str', default => q|---
##################################################################
#
#    Sample plan:
#    Scrape S&P500 Companies from Wikipedia and associated quotes 
#    from the URLs which Wikipedia provides
#
##################################################################
#
# (Note this plan is in 'branch' format)

-   _name: Scrape_Companies
    url: https://en.wikipedia.org/wiki/List_of_S%26P_500_companies
    headers:
        Referer: https://www.google.com


-   _name: Scrape_Quote
    url: $this
    headers:
        Referer: https://www.google.com


-   _name: Record
    table: company
    values:
        ticker: $this[1]
        url: $this[1]
        name: $this[1]
        sector: $this[1]
        industry: $this[1]
        address: $this[1]
        date_added: $this[1]
        cik: $this[1]
        quote: $this
|);


=head1 NAME

TaskPipe::Template_Plan_SP500 - template for the SP500 sample project plan

=head1 DESCRIPTION

This is the template which creates the plan for the SP500 sample project

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut



1;

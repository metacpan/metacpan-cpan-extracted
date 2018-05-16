package TaskPipe::Sample_SP500;

use Moose;
extends 'TaskPipe::Sample';

has templates => (is => 'ro', isa => 'ArrayRef', default => sub{[
    'Config_Project_SP500',
    'Task_SP500ScrapeCompanies',
    'Task_SP500ScrapeQuote',
    'Plan_SP500'
]});

has schema_templates => (is => 'ro', isa => 'ArrayRef', default => sub{[
    'Project',
    'Project_SP500'
]});


=head1 NAME

TaskPipe::Sample_SP500 - sample project to scrape quotes for S&P500 companies

=head1 DESCRIPTION

This sample project scrapes company information from wikipedia, and the accompanying stock quote from the links provided on the wikipedia S&P500 page

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


1;
    

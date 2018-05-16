package TaskPipe::Template_Plan_Stub;

use Moose;
extends 'TaskPipe::Template_Plan';

has template => (is => 'ro', isa => 'Str', default => q|---
# A plan is a YAML file with data in 1 of 2 possible formats:
#
# 1. 'branch' format (simpler, but only allows for 1 'branch')

-   _name: SourceFromDB
    table: my_db_table

-   _name: Scrape_Something
    url: http://www.example.com/scrape-me
    headers:
        Referer: http://www.example.com



# 2. 'tree' format. (Slightly more complex, but allows for
#    multiple branches) 

task:
    _name: SourceFromDB
    table: my_db_table

pipe_to:

    task:
        _name: Scrape_Something
        url: http://www.example.com/scrape-me
        headers:
            Referer: http://www.example.com


# The above 2 plans are equivalent. Choose your weapon, delete the other and adapt
# (No, don't try to use this plan without adapting it..!)|);


=head1 NAME

TaskPipe::Template_Plan_Stub - template for the default plan

=head1 DESCRIPTION

This is the template responsible for creating the default plan (ie just a plan stub)

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut



1;

#!/usr/bin/env perl
package UsageSections;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

sub getopt_usage_config {
    return ( usage_sections => ["NAME|SYNOPSIS|OPTIONS|AUTHOR"] );
}

=pod

=head1 NAME

usage_sections - Test usage_sections option.

=head1 SYNOPSIS

 %c [OPTIONS] [MANS]

=head1 OPTIONS

Should get options added under here:

=head1 DESCRIPTION

This should be in manpage but not usage.

=head1 AUTHOR

Invader Flobee 

=cut

1;

package main;
UsageSections->new_with_options;

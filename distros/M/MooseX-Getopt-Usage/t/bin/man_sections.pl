#!/usr/bin/env perl
package ManSections;
use strict;
use warnings;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

sub getopt_usage_config {
    return ( man_sections => ["NAME|SYNOPSIS|OPTIONS|AUTHOR"] );
}

=pod

=head1 NAME

man_sections - Test man_sections option.

=head1 SYNOPSIS

 %c [OPTIONS] [MANS]

=head1 OPTIONS

Some extra options text.

=head1 DESCRIPTION

This should NOT be in manpage as we have not selected it.

=head1 AUTHOR

Invader Scouge

=cut

1;

package main;
ManSections->new_with_options;

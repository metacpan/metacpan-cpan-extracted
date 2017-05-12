#!/usr/bin/env perl
package Simple;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

sub getopt_usage_config {
    return (
        format => "usage: %c <options>",
        usage_sections => ["SYNOPSIS"],
        headings => 0
    );
}

=pod

=head1 NAME

Simple - Super simple usage message. 

=head1 SYNOPSIS

 Should this get overridden by format above?

=head1 DESCRIPTION

Make sure format overrides reading pod and hide everything else.

=head1 AUTHOR

Invader Flobee 

=cut

1;

package main;
Simple->new_with_options;

#!/usr/bin/env perl
package HideOptions;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

sub getopt_usage_config {
    return (
        usage_sections => ["SYNOPSIS"],
        man_sections   => ["!OPTIONS"],
    );
}

=pod

=head1 NAME

hide_options - Test hiding options.

=head1 SYNOPSIS

 %c [OPTIONS] [MANS]

=head1 DESCRIPTION

Test hiding the OPTIONS section (auto generated) via selector.

=head1 AUTHOR

Invader Flobee 

=cut

1;

package main;
HideOptions->new_with_options;

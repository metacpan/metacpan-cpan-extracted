package Parse::CommandLine;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use parent 'Exporter';
our @EXPORT = qw/parse_command_line/;

sub parse_command_line {
    my $str = shift;

    $str =~ s/\A\s+//ms;
    $str =~ s/\s+\z//ms;

    my @argv;
    my $buf;
    my $escaped;
    my $double_quoted;
    my $single_quoted;

    for my $char (split //, $str) {
        if ($escaped) {
            $buf .= $char;
            $escaped = undef;
            next;
        }

        if ($char eq '\\') {
            if ($single_quoted) {
                $buf .= $char;
            }
            else {
                $escaped = 1;
            }
            next;
        }

        if ($char =~ /\s/) {
            if ($single_quoted || $double_quoted) {
                $buf .= $char;
            }
            else {
                push @argv, $buf if defined $buf;
                undef $buf;
            }
            next;
        }

        if ($char eq '"') {
            if ($single_quoted) {
                $buf .= $char;
                next;
            }
            $double_quoted = !$double_quoted;
            next;
        }

        if ($char eq "'") {
            if ($double_quoted) {
                $buf .= $char;
                next;
            }
            $single_quoted = !$single_quoted;
            next;
        }

        $buf .= $char;
    }
    push @argv, $buf if defined $buf;

    if ($escaped || $single_quoted || $double_quoted) {
        die 'invalid command line string';
    }

    @argv;
}

1;
__END__

=encoding utf-8

=head1 NAME

Parse::CommandLine - Parsing string like command line

=head1 SYNOPSIS

    use Parse::CommandLine;
    my @argv = parse_command_line('command --foo=bar --foo');
    #=> ('command', '--foo-bar', '--foo')

=head1 DESCRIPTION

Parse::CommandLine is a module for parsing string like command line into
array of arguments.

=head1 FUNCTION

=head2 C<< @command_and_argv = parse_command_line($str) >>

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

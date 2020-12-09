package Tapper::CLI::Base;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::Base::VERSION = '5.0.7';
use strict;
use warnings;


sub b_print_help {

    my ( $ar_help_array ) = @_;

    my @a_params;
    my $i_param_length = 0;
    for my $ar_parameter ( @{$ar_help_array} ) {
        push @a_params, '--' . (split /=|:|!/, $ar_parameter->[0])[0];
        if ( length $a_params[-1] > $i_param_length ) {
            $i_param_length = length $a_params[-1];
        }
    }
    my $i_counter = 0;
    for my $ar_parameter ( @{$ar_help_array} ) {
        printf {*STDERR} '    %s%' . ($i_param_length-length($a_params[$i_counter])) . "s    %s\n", $a_params[$i_counter], '', $ar_help_array->[$i_counter][1];
        if ( @{$ar_parameter} > 2 ) {
            for my $i_sub_counter ( 2..$#{$ar_parameter} ) {
                printf {*STDERR} '    %' . $i_param_length . "s    %s\n", '', $ar_help_array->[$i_counter][$i_sub_counter];
            }
        }
        $i_counter++;
    }

    print {*STDERR} "\n";

    return 1;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::Base

=head2 b_print_help

print help with a given array reference

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

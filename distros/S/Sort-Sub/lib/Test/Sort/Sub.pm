## no critic: Modules::ProhibitAutomaticExportation

package Test::Sort::Sub;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-25'; # DATE
our $DIST = 'Sort-Sub'; # DIST
our $VERSION = '0.120'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Exporter 'import';
use Sort::Sub ();
use Test::More 0.98;

our @EXPORT = qw(sort_sub_ok);

sub _sort {
    my ($args, $extras, $output_name) = @_;

    my $subname = $args->{subname};
    Sort::Sub->import("$subname$extras", ($args->{args} ? $args->{args} : ()));
    my $res;
    if ($args->{compares_record}) {
        $res = [map {$_->[0]} sort {&{$subname}($a,$b)}
                    (map { [$args->{input}[$_], $_] } 0..$#{ $args->{input} })];
    } else {
        $res = [sort {&{$subname}($a,$b)} @{ $args->{input} }];
    }
    is_deeply($args->{$output_name}, $res) or diag explain $res;
}

sub sort_sub_ok {
    my %args = @_;

    my $subname = $args{subname};
    subtest "sort_sub_ok $subname" => sub {
        my $res;

        if ($args{output}) {
            _sort(\%args, '', 'output');
        }

        if ($args{output_i}) {
            _sort(\%args, '<i>', 'output_i');
        }

        if ($args{output_r}) {
            _sort(\%args, '<r>', 'output_r');
        };

        if ($args{output_ir}) {
            _sort(\%args, '<ir>', 'output_ir');
        };
    };
}

1;
# ABSTRACT: Test Sort::Sub::* subroutine

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Sort::Sub - Test Sort::Sub::* subroutine

=head1 VERSION

This document describes version 0.120 of Test::Sort::Sub (from Perl distribution Sort-Sub), released on 2020-05-25.

=head1 FUNCTIONS

=head2 sort_sub_ok(%args) => bool

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Sub>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Sub>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

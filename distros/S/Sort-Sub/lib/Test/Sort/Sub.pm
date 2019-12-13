package Test::Sort::Sub;

## no critic: Modules::ProhibitAutomaticExportation

our $DATE = '2019-10-26'; # DATE
our $VERSION = '0.111'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Exporter 'import';
use Sort::Sub ();
use Test::More 0.98;

our @EXPORT = qw(sort_sub_ok);

sub sort_sub_ok {
    my %args = @_;

    my $subname = $args{subname};
    subtest "sort_sub_ok $subname" => sub {
        my $res;

        if ($args{output}) {
            Sort::Sub->import("$subname", ($args{args} ? $args{args} : ()));
            $res = [sort {&{$subname}} @{ $args{input} }];
            is_deeply($res, $args{output}, 'result') or diag explain $res;
        }

        if ($args{output_i}) {
            Sort::Sub->import("$subname<i>", ($args{args} ? $args{args} : ()));
            $res = [sort {&{$subname}} @{ $args{input} }];
            is_deeply($res, $args{output_i}, 'result i') or diag explain $res;
        }

        if ($args{output_r}) {
            Sort::Sub->import("$subname<r>", ($args{args} ? $args{args} : ()));
            $res = [sort {&{$subname}} @{ $args{input} }];
            is_deeply($res, $args{output_r}, 'result r') or diag explain $res;
        };

        if ($args{output_ir}) {
            Sort::Sub->import("$subname<ir>", ($args{args} ? $args{args} : ()));
            $res = [sort {&{$subname}} @{ $args{input} }];
            is_deeply($res, $args{output_ir}, 'result ir') or diag explain $res;
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

This document describes version 0.111 of Test::Sort::Sub (from Perl distribution Sort-Sub), released on 2019-10-26.

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

This software is copyright (c) 2019, 2018, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

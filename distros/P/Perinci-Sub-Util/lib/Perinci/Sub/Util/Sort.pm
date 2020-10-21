package Perinci::Sub::Util::Sort;

our $DATE = '2020-10-20'; # DATE
our $VERSION = '0.470'; # VERSION

use 5.010;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       sort_args
               );

our %SPEC;

sub sort_args {
    my $args = shift;
    sort {
        (($args->{$a}{pos} // 9999) <=> ($args->{$b}{pos} // 9999)) ||
            $a cmp $b
        } keys %$args;
}

1;
# ABSTRACT: Sort routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Util::Sort - Sort routines

=head1 VERSION

This document describes version 0.470 of Perinci::Sub::Util::Sort (from Perl distribution Perinci-Sub-Util), released on 2020-10-20.

=head1 SYNOPSIS

 use Perinci::Sub::Util::Sort qw(sort_args);

 my $meta = {
     v => 1.1,
     args => {
         a1 => { pos=>0 },
         a2 => { pos=>1 },
         opt1 => {},
         opt2 => {},
     },
 };
 my @args = sort_args($meta->{args}); # ('a1','a2','opt1','opt2')

=head1 FUNCTIONS

=head2 sort_args(\%args) => LIST

Sort argument in args property by pos, then by name.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

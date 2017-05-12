package Sort::Sub::by_date_in_text;

our $DATE = '2017-04-25'; # DATE
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;

use DateTime;

our $DATE_EXTRACT_MODULE = $ENV{PERL_DATE_EXTRACT_MODULE} // "Date::Extract";

sub gen_sorter {
    my ($is_reverse, $is_ci) = @_;

    my $re_is_num = qr/\A
                       [+-]?
                       (?:\d+|\d*(?:\.\d*)?)
                       (?:[Ee][+-]?\d+)?
                       \z/x;

    my ($parser, $code_parse);
    my $module = $DATE_EXTRACT_MODULE;
    $module = "Date::Extract::$module" unless $module =~ /::/;
    if ($module eq 'Date::Extract') {
        require Date::Extract;
        $parser = Date::Extract->new();
        $code_parse = sub { $parser->extract($_[0]) };
    } elsif ($module eq 'Date::Extract::ID') {
        require Date::Extract::ID;
        $parser = Date::Extract::ID->new();
        $code_parse = sub { $parser->extract($_[0]) };
    } elsif ($module eq 'DateTime::Format::Alami::EN') {
        require DateTime::Format::Alami::EN;
        $parser = DateTime::Format::Alami::EN->new();
        $code_parse = sub { my $h; eval { $h = $parser->parse_datetime($_[0]) }; $h };
    } elsif ($module eq 'DateTime::Format::Alami::ID') {
        require DateTime::Format::Alami::ID;
        $parser = DateTime::Format::Alami::ID->new();
        $code_parse = sub { my $h; eval { $h = $parser->parse_datetime($_[0]) }; $h };
    } else {
        die "Invalid date extract module '$module'";
    }
    eval "use $module"; die if $@;

    sub {
        no strict 'refs';

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        my $cmp;

        # XXX cache

        my $dt_a = $code_parse->($a);
        warn "Found date $dt_a in $a\n" if $ENV{DEBUG} && $dt_a;
        my $dt_b = $code_parse->($b);
        warn "Found date $dt_b in $b\n" if $ENV{DEBUG} && $dt_b;

        {
            if ($dt_a && $dt_b) {
                $cmp = DateTime->compare($dt_a, $dt_b);
                last if $cmp;
            } elsif ($dt_a && !$dt_b) {
                $cmp = -1;
                last;
            } elsif (!$dt_a && $dt_b) {
                $cmp = 1;
                last;
            }

            if ($is_ci) {
                $cmp = lc($a) cmp lc($b);
            } else {
                $cmp = $a cmp $b;
            }
        }

        $is_reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT: Sort by date found in text or (if no date is found) ascibetically

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_date_in_text - Sort by date found in text or (if no date is found) ascibetically

=head1 VERSION

This document describes version 0.008 of Sort::Sub::by_date_in_text (from Perl distribution Sort-Sub-by_date_in_text), released on 2017-04-25.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_date_in_text'; # use '$by_date_in_text<i>' for case-insensitive sorting, '$by_date_in_text<r>' for reverse sorting
 my @sorted = sort $by_date_in_text ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_date_in_text<ir>';
 my @sorted = sort {by_date_in_text} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_date_in_text;
 my $sorter = Sort::Sub::by_date_in_text::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_date_in_text
 % some-cmd | sortsub by_date_in_text --ignore-case -r

=head1 DESCRIPTION

The generated sort routine will sort by date found in text (extracted using
L<Date::Extract>) or (f no date is found in text) ascibetically. Items that have
a date will sort before items that do not.

=for Pod::Coverage ^(gen_sorter)$

=head1 ENVIRONMENT

=head2 DEBUG => bool

If set to true, will print stuffs to stderr.

=head2 PERL_DATE_EXTRACT_MODULE => str

Can be set to L<Date::Extract>, L<Date::Extract::ID>, or
L<DateTime::Format::Alami::EN>, L<DateTime::Format::Alami::ID>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Sub-by_date_in_text>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Sub-by_date_in_text>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub-by_date_in_text>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sort::Sub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

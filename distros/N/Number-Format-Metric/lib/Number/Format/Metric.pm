package Number::Format::Metric;

use 5.010001;
use locale;
use strict;
use utf8;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-09-24'; # DATE
our $DIST = 'Number-Format-Metric'; # DIST
our $VERSION = '0.604'; # VERSION

our @EXPORT_OK = qw(
                       format_metric
               );

sub format_metric {
    my ($num, $opts) = @_;
    $opts //= {};
    $opts->{base} //= 2;

    my $im    = $opts->{i_mark} // 1;
    my $base0 = $opts->{base};
    my $base  = $base0 == 2 ? 1024 : 1000;
    my $uck   = $opts->{uppercase_k};
    my $latin = $opts->{latin_only};
    my $addp  = $opts->{additional_prefix} // '';

    my $rank;
    my $prefix;
    if ($num == 0) {
        $rank = 0;
        $prefix = "";
    } else {
        $rank = int(log(abs($num))/log($base));
        if    ($rank ==  0 && abs($num) >= 1) { $prefix = ""  }
        elsif ($rank ==  1) { my $k = $uck ? "K" : "k"; $prefix = $im && $base0==10 ? "${k}i" : $k } # kilo
        elsif ($rank ==  2) { $prefix = $im && $base0==10 ? "Mi" : "M" } # mega
        elsif ($rank ==  3) { $prefix = $im && $base0==10 ? "Gi" : "G" } # giga
        elsif ($rank ==  4) { $prefix = $im && $base0==10 ? "Ti" : "T" } # tera
        elsif ($rank ==  5) { $prefix = $im && $base0==10 ? "Pi" : "P" } # peta
        elsif ($rank >=  8) { $prefix = $im && $base0==10 ? "Yi" : "Y" } # yotta
        elsif ($rank ==  7) { $prefix = $im && $base0==10 ? "Zi" : "Z" } # zetta
        elsif ($rank ==  6) { $prefix = $im && $base0==10 ? "Ei" : "E" } # exa
        elsif ($rank ==  0) { $prefix = "m" } # milli
        elsif ($rank == -1) { $prefix = $latin ? "mc" : "μ" } # micro
        elsif ($rank == -2) { $prefix = "n" } # nano
        elsif ($rank == -3) { $prefix = "p" } # pico
        elsif ($rank == -4) { $prefix = "f" } # femto
        elsif ($rank == -5) { $prefix = "a" } # atto
        elsif ($rank == -6) { $prefix = "z" } # zepto
        elsif ($rank <= -7) { $prefix = "y" } # yocto
    }
    $prefix .= $addp;

    my $prec = $opts->{precision} // 1;
    $num = $num / $base**($rank <= 0 && abs($num) < 1 ? $rank-1 : $rank);
    if ($opts->{return_array}) {
        return [$num, $prefix];
    } else {
        my $snum = sprintf("%.${prec}f", $num);
        return $snum . $prefix;
    }
}

1;
# ABSTRACT: Format number with metric prefix, with some options

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Format::Metric - Format number with metric prefix, with some options

=head1 VERSION

This document describes version 0.604 of Number::Format::Metric (from Perl distribution Number-Format-Metric), released on 2025-09-24.

=head1 SYNOPSIS

 use Number::Format::Metric qw(format_metric);

 # precision option
 format_metric(14     , {base=>10});               # => "14.0"
 format_metric(14     , {base=>10, precision=>0}); # => "14"

 # base 2 vs base 10
 format_metric(12001  , {base=> 2, precision=>1});                 # => "11.7k"
 format_metric(12001  , {base=>10, precision=>3});                 # => "12.001ki"
 format_metric(-0.0017, {base=>10});                               # => "-1.7m"
 format_metric(1.26e6 , {base=>10});                               # => "1.3Mi"

 # don't use "i" mark for base 10
 format_metric(12001  , {base=>10, precision=>3, i_mark=>0});      # => "12.001k"

 # uppercase_k option
 format_metric(12001  , {base=>10, precision=>3, uppercase_k=>1}); # => "12.001Ki"

 # additional_prefix option
 format_metric(12001  , {base=> 2, precision=>1, additional_prefix=>"b"});    # => "11.7kb"
 format_metric(12001  , {base=>10, precision=>1, additional_prefix=>"bps"});  # => "12.0kbps"

 # latin_only option
 format_metric(2.3e-6 , {base=>10, precision=>1, additional_prefix=>"g"});                # => "2.3μg"
 format_metric(2.3e-6 , {base=>10, precision=>1, additional_prefix=>"g", latin_only=>1}); # => "2.3mcg"

=head1 FUNCTIONS

None exported by default but all of them exportable.

=head2 format_metric($num, \%opts) => STR

Format C<$num> using metric prefix. Locale settings are respected (this module
uses L<locale>).

Might produce non-Latin Unicode characters (e.g. "μ" for 1e-6 prefix), unless if
you set the C<latin_only> option, in which case "μ" will be shown as "mc".

Known options:

=over

=item * base => INT (either 2 or 10, default: 2)

=item * precision => INT

=item * i_mark => BOOL (default: 1)

Give "i" suffix to prefixes when in base 10 for k, M, G, T, and so on.

=item * uppercase_k => BOOL (default: 0)

When set to true, will use "K" instead of "k" for kilo.

=item * latin_only => BOOL (default: 0)

When set to true, will use "mc" instead of "μ" for micro.

=item * additional_prefix => STR

String to add after the prefix, e.g. "b" (for byte), "g" (for gram), etc.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Number-Format-Metric>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Number-Format-Metric>.

=head1 SEE ALSO

=head2 Unformatting numbers

L<Data::Sah::Coerce> coerce module:
L<Data::Sah::Coerce::perl::To_float::From_str::suffix_datasize> and
L<Data::Sah::Coerce::perl::To_float::From_str::suffix_datasize>. Example of
using this can be seen in L<datasize-from-metric> and L<dataspeed-from-metric>
(included in the L<App::DataSizeSpeedUtils> distribution).

=head2 Other number formatting modules

L<Number::Format> can format several kinds of numbers e.g. bytes ("2.3KB") or
prices ("USD 5,000") as well as format using template ("picture") like
`sprintf`. But for metric prefixes it only supports kilo, kibi, mega, mebi,
giga, gibi. It can also unformat numbers back to floating point form.

L<Format::Human::Bytes> supports formatting bytes with prefixes kilo, mega,
giga, and tera.

L<Number::Bytes::Human> supports formatting with prefixes kilo (2^10) to yotta
(2^70), but does not support smaller prefixes, e.g. milli, micro, etc.
Obviously.

L<https://en.wikipedia.org/wiki/Metric_prefix>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Number-Format-Metric>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

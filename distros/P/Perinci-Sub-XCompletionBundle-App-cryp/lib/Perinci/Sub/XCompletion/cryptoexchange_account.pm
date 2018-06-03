package Perinci::Sub::XCompletion::cryptoexchange_account;

our $DATE = '2018-06-01'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Complete::Util qw(complete_array_elem);

our %SPEC;

$SPEC{gen_completion} = {
    v => 1.1,
};
sub gen_completion {
    require PERLANCAR::Module::List;

    my %fargs = @_;

    # XXX only show supported exchange (where corresponding
    # App::cryp::Exchange::* is found) or grab from config

    # XXX grab account from config

    sub {
        my %cargs = @_;
        my $word    = $cargs{word} // '';
        my $cmdline = $cargs{cmdline};
        my $r       = $cargs{r};

        return undef unless $cmdline;

        my %exchanges;

        # grep exchange and account names from config
        {
            # force reading config file
            $r->{read_config} = 1;

            my $res = $cmdline->parse_argv($r);
            for my $s (keys %{ $r->{_config_section_read_order} // {} }) {
                next unless $s =~ m!\Aexchange\s*/\s*(.+?)(?:\s*/\s*(.+))?\z!;
                $exchanges{$1} //= {default=>1};
                $exchanges{$1}{$2} = 1 if defined $2;
            }
        }

        # grep exchange from App::cryp::Exchange::* modules
        {
            my $mods = PERLANCAR::Module::List::list_modules(
                "App::cryp::Exchange::", {list_modules=>1});
            for my $k (keys %$mods) {
                $k =~ s/^App::cryp::Exchange:://;
                $k =~ s/_/-/g;
                $exchanges{$k} //= {default=>1};
            }
        }

        my @ary = map {
            my $xch = $_;
            map { "$xch/$_" } sort keys %{$exchanges{$xch}};
        } sort keys %exchanges;

        complete_array_elem(
            word => $word,
            array => \@ary,
        );
    };
}

1;
# ABSTRACT: Generate completion for cryptoexchange code/name/safename

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::cryptoexchange_account - Generate completion for cryptoexchange code/name/safename

=head1 VERSION

This document describes version 0.001 of Perinci::Sub::XCompletion::cryptoexchange_account (from Perl distribution Perinci-Sub-XCompletionBundle-App-cryp), released on 2018-06-01.

=head1 FUNCTIONS


=head2 gen_completion

Usage:

 gen_completion() -> [status, msg, result, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-XCompletionBundle-App-cryp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-XCompletionBundle-App-cryp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-XCompletionBundle-App-cryp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

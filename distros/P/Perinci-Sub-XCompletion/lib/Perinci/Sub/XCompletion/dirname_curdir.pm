package Perinci::Sub::XCompletion::dirname_curdir;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Complete::Util qw(complete_array_elem);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-18'; # DATE
our $DIST = 'Perinci-Sub-XCompletion'; # DIST
our $VERSION = '0.106'; # VERSION

our %SPEC;

$SPEC{gen_completion} = {
    v => 1.1,
};
sub gen_completion {
    my %fargs = @_;
    my $allow_dot = $fargs{allow_dot} // 1;

    sub {
        my %cargs = @_;
        my @entries;
        opendir my $dh, "." or do { log_warn "Can't opendir(.): $!"; return };
        while (defined(my $e = readdir $dh)) {
            next if $e eq '.' || $e eq '..';
            next if !$allow_dot && $e =~ /\A\./;
            next unless -d $e;
            push @entries, $e;
        }
        complete_array_elem(word=>$cargs{word}, array=>\@entries);
    };
}

1;
# ABSTRACT: Generate completion for directory name in the current directory

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::dirname_curdir - Generate completion for directory name in the current directory

=head1 VERSION

This document describes version 0.106 of Perinci::Sub::XCompletion::dirname_curdir (from Perl distribution Perinci-Sub-XCompletion), released on 2023-11-18.

=head1 DESCRIPTION

=head1 CONFIGURATION

=head2 allow_dot

Bool, default true.

=head1 FUNCTIONS


=head2 gen_completion

Usage:

 gen_completion() -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=for Pod::Coverage ^(.+)$

In L<argument specification|Rinci::function/"args (function property)"> of your
L<Rinci> L<function metadata|Rinci::function>:

 'x.completion' => 'dirname_curdir',

Do not include dotdirs:

 'x.completion' => ['dirname_curdir' => {allow_dot=>0}],

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-XCompletion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-XCompletion>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

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

This software is copyright (c) 2023, 2022, 2019, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-XCompletion>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

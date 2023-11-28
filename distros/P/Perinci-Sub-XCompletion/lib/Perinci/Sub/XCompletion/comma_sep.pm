package Perinci::Sub::XCompletion::comma_sep;

use 5.010001;
use strict;
use warnings;

use Complete::Util qw(hashify_answer);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-18'; # DATE
our $DIST = 'Perinci-Sub-XCompletion'; # DIST
our $VERSION = '0.106'; # VERSION

our %SPEC;

sub _gen {
    my ($submod) = @_;
    my $xcargs;

    if (ref $submod eq 'ARRAY') {
        $xcargs = $submod->[1];
        $submod = $submod->[0];
    } else {
        $xcargs = {};
    }

    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    my $mod = "Perinci::Sub::XCompletion::$submod";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    &{"$mod\::gen_completion"}(%$xcargs);
}

$SPEC{gen_completion} = {
    v => 1.1,
    # XXX parameter 'uniq'
};
sub gen_completion {
    my %fargs = @_;
    sub {
        my %cargs = @_;
        my $word = $cargs{word};

        my $xcompletion = _gen($fargs{xcompletion});

        # XXX grok backslash escape
        my ($prev_items, $cur_item) = $word =~ /\A(.*,)?(.*)/;
        $prev_items //= "";

        my $ans = hashify_answer($xcompletion->(word => $cur_item));
        return unless $ans;
        for my $word (@{ $ans->{words} }) {
            # reattach the previous items
            if (ref $word eq 'HASH') {
                $word->{word} = $prev_items . $word->{word};
            } else {
                $word = $prev_items . $word;
            }
        }
        $ans;
    };
}

1;
# ABSTRACT: Generate completion for completing a comma-separated list of other completion

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::comma_sep - Generate completion for completing a comma-separated list of other completion

=head1 VERSION

This document describes version 0.106 of Perinci::Sub::XCompletion::comma_sep (from Perl distribution Perinci-Sub-XCompletion), released on 2023-11-18.

=head1 SYNOPSIS

In L<argument specification|Rinci::function/"args (function property)"> of your
L<Rinci> L<function metadata|Rinci::function>:

 # complete a comma-separated list of unix users
 'x.completion' => [comma_sep => {xcompletion => 'unix_user'}],

 # complete an argument in the form of FILENAME,UNIX_USER,WORDLIST_MODULE_NAME
 'x.completion' => [comma_sep => {xcompletions => ['filename', 'unix_user', [perl_modname => {ns_prefix=>"WordList"}]]}],

=head1 DESCRIPTION

This completion lets you string several completions together in a
comma-separated list.

=head1 PARAMETERS

=head2 xcompletion

The C<Perinci::Sub::XCompletion::*> module name, without the prefix, to generate
completion for all the items ih the comma-separated list. Or, a 2-element array
containing module name and hash of parameters for the module.

Examples:

 xcompletion => 'unix_user',
 xcompletion => [perl_modname => {ns_prefix=>"WordList"}],

Either this parameter or L</xcompletions> must be specified.

=head2 xcompletions

An array containing list of completions to generate for each corresponding item
in the comma-separated list. Each element of the C<xcompletions> list should be
the C<Perinci::Sub::XCompletion::*> module name without the prefix, or a
2-element array containing module name and hash of parameters for the module.

Example:

 xcompletions => ['filename', 'unix_user', [perl_modname => {ns_prefix=>"WordList"}]],

Either this parameter or L</xcompletion> must be specified.

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-XCompletion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-XCompletion>.

=head1 SEE ALSO

L<Complete::Sequence>

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

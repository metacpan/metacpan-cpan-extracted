package Perinci::Sub::XCompletion::perl_sorter_modname_with_optional_args;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-07'; # DATE
our $DIST = 'Sah-SchemaBundle-Sorter'; # DIST
our $VERSION = '0.002'; # VERSION

sub gen_completion {
    my %gcargs = @_;

    sub {
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

        my %cargs = @_;

        my $word = $cargs{word};

        my ($word_mod, $word_eq, $word_modargs) = $word =~ /\A([^=,]*)([=,])?(.*?)\z/;
        #log_trace "TMP: word_mod, word_eq, word_modargs = %s, %s, %s", $word_mod, $word_eq, $word_modargs;

        unless ($word_eq) {
            require Complete::Module;
            my $modres = Complete::Module::complete_module(
                word => $word_mod,
                ns_prefix => "Sorter::",
                recurse => 1,
            );

            # no module matches, we can't complete
            return [] unless @{ $modres->{words} };

            # multiple module matches, we also don't complete args, just the modules
            return $modres if @{ $modres->{words} } > 1;

            # normalize the module part
            $word_mod = ref $modres->{words}[0] eq 'HASH' ? $modres->{words}[0]{word} : $modres->{words}[0];

            # to start args we use "," by default instead of "=" because "=" is
            # problematic in bash completion because it is used as a
            # word-breaking character by default (along with @><;|&(:
            $word_eq = ",";
        }

        (my $wl_module = $word_mod) =~ s![/.]!::!g;

        my $module = "Sorter::$wl_module";
        (my $module_pm = "$module.pm") =~ s!::!/!g;
        eval { require $module_pm; 1 };
        do { log_trace "Can't load module $module: $@. Skipped checking for arguments"; return [$word_mod] } if $@;

        my $meta = &{"$module\::meta"}->();
        do { log_trace "Module $module does not define meta"; return [$word_mod] } unless $meta;

        do { log_trace "Module $module does not define args"; return [$word_mod] } unless $meta->{args} && keys(%{ $meta->{args} });

        my @args = sort keys %{ $meta->{args} };
        my @args_summaries = map { $meta->{args}{$_}{summary} } @args;
        require Complete::Util;
        my $ccsp_res = Complete::Util::complete_comma_sep_pair(
            word => $word_modargs,
            keys => \@args,
            keys_summaries => \@args_summaries,
            complete_value => sub {
                my %cvargs = @_;
                my $key = $cvargs{key};
                return [] unless $meta->{args}{$key};
                return [] unless $meta->{args}{$key}{schema};

                require Perinci::Sub::Complete;
                Perinci::Sub::Complete::complete_from_schema(
                    word => $cvargs{word},
                    schema => $meta->{args}{$key}{schema},
                );
            },
        );
        Complete::Util::modify_answer(answer => $ccsp_res, prefix => "$word_mod$word_eq");
    },
}

1;
# ABSTRACT: Generate completion for Sorter::* module name with optional params

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::perl_sorter_modname_with_optional_args - Generate completion for Sorter::* module name with optional params

=head1 VERSION

This document describes version 0.002 of Perinci::Sub::XCompletion::perl_sorter_modname_with_optional_args (from Perl distribution Sah-SchemaBundle-Sorter), released on 2024-03-07.

=head1 SYNOPSIS

To use, put this in your L<Sah> schema's C<x.completion> attribute:

 'x.completion' => ['perl_sorter_modname_with_optional_args'],

=for Pod::Coverage ^(gen_completion)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Sorter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Sorter>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Sorter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

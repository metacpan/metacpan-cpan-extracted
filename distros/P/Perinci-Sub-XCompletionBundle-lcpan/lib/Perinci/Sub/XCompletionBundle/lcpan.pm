package Perinci::Sub::XCompletionBundle::lcpan;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-02'; # DATE
our $DIST = 'Perinci-Sub-XCompletionBundle-lcpan'; # DIST
our $VERSION = '0.003'; # VERSION

sub _connect_lcpan {
    no warnings 'once';

    eval "use App::lcpan 0.32"; ## no critic: BuiltinFunctions::ProhibitStringyEval
    if ($@) {
        log_trace("[_cpanm] App::lcpan not available, skipped ".
                         "trying to complete from CPAN module names");
        return;
    }

    require Perinci::CmdLine::Util::Config;

    my %lcpanargs;
    my $res = Perinci::CmdLine::Util::Config::read_config(
        program_name => "lcpan",
    );
    unless ($res->[0] == 200) {
        log_trace("[xcomp.lcpan] Can't get config for lcpan: %s", $res);
        last;
    }
    my $config = $res->[2];

    $res = Perinci::CmdLine::Util::Config::get_args_from_config(
        config => $config,
        args   => \%lcpanargs,
        #subcommand_name => 'update',
        meta   => $App::lcpan::SPEC{update},
    );
    unless ($res->[0] == 200) {
        log_trace("[xcomp.lcpan] Can't get args from config: %s", $res);
        return;
    }
    App::lcpan::_set_args_default(\%lcpanargs);
    my $dbh = App::lcpan::_connect_db('ro', $lcpanargs{cpan}, $lcpanargs{index_name});
}

1;
# ABSTRACT: Completion stuffs using local CPAN database

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletionBundle::lcpan - Completion stuffs using local CPAN database

=head1 VERSION

This document describes version 0.003 of Perinci::Sub::XCompletionBundle::lcpan (from Perl distribution Perinci-Sub-XCompletionBundle-lcpan), released on 2022-09-02.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-XCompletionBundle-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-XCompletionBundle-lcpan>.

=head1 SEE ALSO

L<lcpan> and L<App::lcpan>

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-XCompletionBundle-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

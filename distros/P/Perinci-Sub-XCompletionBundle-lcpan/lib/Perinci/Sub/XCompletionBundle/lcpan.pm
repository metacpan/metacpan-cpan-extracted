package Perinci::Sub::XCompletionBundle::lcpan;

our $DATE = '2019-01-13'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

sub _connect_lcpan {
    no warnings 'once';

    eval "use App::lcpan 0.32";
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

This document describes version 0.001 of Perinci::Sub::XCompletionBundle::lcpan (from Perl distribution Perinci-Sub-XCompletionBundle-lcpan), released on 2019-01-13.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-XCompletionBundle-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-XCompletionBundle-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-XCompletionBundle-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lcpan> and L<App::lcpan>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

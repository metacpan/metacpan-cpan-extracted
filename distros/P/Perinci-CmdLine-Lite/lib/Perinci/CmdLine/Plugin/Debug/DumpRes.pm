package Perinci::CmdLine::Plugin::Debug::DumpRes;

# put pragmas + Log::ger here
use strict;
use warnings;
use Log::ger;
use parent 'Perinci::CmdLine::PluginBase';

# put other modules alphabetically here

# put global variables alphabetically here
our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-23'; # DATE
our $DIST = 'Perinci-CmdLine-Lite'; # DIST
our $VERSION = '1.929'; # VERSION

sub meta {
    return {
        summary => 'Dump result ($r->{res}), by default after action',
        conf => {
            dumper => {
                schema => ['str*', in=>['Data::Dump::Color', 'Data::Dmp']],
                default => 'Data::Dump::Color',
            },
        },
        tags => ['category:debugging'],
    };
}

sub after_action {
    my ($self, $r) = @_;

    my $dumper = $self->{dumper} || 'Data::Dump::Color';
    if ($dumper eq 'Data::Dmp') {
        require Data::Dmp;
        local $Data::Dmp::OPT_DEPARSE = 1;
        Data::Dmp::dd($r->{res});
    } else {
        require Data::Dump::Color;
        Data::Dump::Color::dd($r->{res});
    }

    [200, "OK"];
}

1;
# ABSTRACT: Dump result ($r->{res}), by default after action

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Plugin::Debug::DumpRes - Dump result ($r->{res}), by default after action

=head1 VERSION

This document describes version 1.929 of Perinci::CmdLine::Plugin::Debug::DumpRes (from Perl distribution Perinci-CmdLine-Lite), released on 2023-11-23.

=head1 SYNOPSIS

To use, either specify in environment variable:

 PERINCI_CMDLINE_PLUGINS=-Debug::DumpRes

or in code instantiating L<Perinci::CmdLine>:

 my $app = Perinci::CmdLine::Any->new(
     ...
     plugins => ["Debug::DumpRes"],
 );

By default this plugin acts after the C<action> event. If you want to dump at a
different event:

 my $app = Perinci::CmdLine::Any->new(
     ...
     plugins => [
         'Debug::DumpArgs@after_format_res',
     ],
 );

For list of plugin events available, see L<Perinci::CmdLine::Base/"Plugin
events">.

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite>.

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

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

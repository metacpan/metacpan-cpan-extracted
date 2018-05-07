package Perinci::CmdLine::cryp;

our $DATE = '2018-05-05'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use parent 'Perinci::CmdLine::Lite';

sub hook_config_file_section {
    my ($self, $r, $section_name, $section_content) = @_;

    if ($section_name =~ m!\Aexchange\s*/\s*([^/]+)(?:\s*/\s*(.+))?\z!) {
        my $xchg = $1;
        my $nick = $2 // 'default';
        $r->{_cryp}{exchanges}{$xchg}{$nick} //= {};
        for (keys %$section_content) {
            $r->{_cryp}{exchanges}{$xchg}{$nick}{$_} =
                $section_content->{$_};
        }
        return [204];
    }

    if ($section_name =~ m!\Awallet\s*/\s*([^/]+)(?:\s*/\s*(.+))?\z!) {
        my $coin = $1;
        my $nick = $2 // 'default';
        $r->{_cryp}{wallets}{$coin}{$nick} //= {};
        for (keys %$section_content) {
            $r->{_cryp}{wallets}{$coin}{$nick}{$_} =
                $section_content->{$_};
        }
        return [204];
    }

    if ($section_name =~ m!\Amasternode\s*/\s*([^/]++)(?:\s*/\s*(.+))?\z!) {
        my $coin = $1;
        my $nick = $2 // 'default';
        $r->{_cryp}{masternodes}{$coin}{$nick} //= {};
        for (keys %$section_content) {
            $r->{_cryp}{masternodes}{$coin}{$nick}{$_} =
                $section_content->{$_};
        }
        return [204];
    }

    if ($section_name =~ m!\Aarbit-strategy\s*/\s*([^/]++)\z!) {
        my $strategy = $1;
        $r->{_cryp}{arbit_strategy}{$strategy} //= {};
        for (keys %$section_content) {
            $r->{_cryp}{arbit_strategy}{$strategy}{$_} =
                $section_content->{$_};
        }
        return [204];
    }

    [200];
}

1;
# ABSTRACT: Perinci::CmdLine::Lite subclass to read entities from config

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::cryp - Perinci::CmdLine::Lite subclass to read entities from config

=head1 VERSION

This document describes version 0.005 of Perinci::CmdLine::cryp (from Perl distribution Perinci-CmdLine-cryp), released on 2018-05-05.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-cryp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-cryp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-cryp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::cryp> and other C<App::cryp::*> modules.

L<Perinci::CmdLine::Lite>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

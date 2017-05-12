package Plack::Util::PeriAHS;

our $DATE = '2016-03-16'; # DATE
our $VERSION = '0.60'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(errpage);

use JSON::MaybeXS;

my $json = JSON::MaybeXS->new->allow_nonref;

sub errpage {
    my ($env, $rres) = @_;

    my $fmt = $env->{'riap.request'}{fmt} //
        $env->{"periahs.default_fmt"} // 'json';
    my $pres;

    if ($fmt =~ /^html$/i) {
        $pres = [
            200,
            ["Content-Type" => "text/html"],
            ["<h1>Error $rres->[0]</h1>\n\n$rres->[1]\n"],
        ];
    } elsif ($fmt =~ /text$/i) {
        $pres = [
            200,
            ["Content-Type" => "text/plain"],
            ["Error $rres->[0]: ".$rres->[1].($rres->[1] =~ /\n$/ ? "":"\n")],
        ];
    } else {
        $pres = [
            200,
            ["Content-Type" => "application/json"],
            [$json->encode($rres)]
        ];
    }

    $log->tracef("Returning error page: %s", $pres);
    $pres;
}

1;
# ABSTRACT: Utility routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Util::PeriAHS - Utility routines

=head1 VERSION

This document describes version 0.60 of Plack::Util::PeriAHS (from Perl distribution Perinci-Access-HTTP-Server), released on 2016-03-16.

=head1 FUNCTIONS

=head2 errpage($env, $resp)

Render enveloped response $resp (as specified in L<Rinci::function>) as an error
page PSGI response, either in HTML/JSON/plaintext (according to C<<
$env->{"riap.request"}{fmt} >>). Will default to JSON if C<fmt> is unsupported.

$env is PSGI environment.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-HTTP-Server>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-Access-HTTP-Server>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-HTTP-Server>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

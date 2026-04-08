package Module::CheckVersion::AuthorityScheme::darkpan;

use 5.010001;
use strict;
use warnings;

use File::Temp 'tempfile';
use File::Slurper 'write_binary';
use HTTP::Tiny;
use JSON::MaybeXS;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-04-08'; # DATE
our $DIST = 'Module-CheckVersion'; # DIST
our $VERSION = '0.091'; # VERSION

sub check_latest_version {
    my ($mod, $authority_scheme, $authority_content) = @_;

    my $url = "$authority_content/modules/02packages.details.txt.gz";
    my $res = HTTP::Tiny->new->get($url);
    #use DD; dd $res;
    return [$res->{status}, "Retrieving $url failed: $res->{reason}"] unless $res->{success};

    my ($tempfh, $tempfilename) = tempfile('XXXXXXXX', SUFFIX => '.gz', TMPDIR => 1);
    #print "D:tempfilename=$tempfilename\n";
    write_binary($tempfilename, $res->{content});

    require Parse::CPAN::Packages;
    my $pcp = Parse::CPAN::Packages->new($tempfilename);
    my $m = $pcp->package($mod);
    unless ($m) {
        return [404, "No such module '$mod' in $url"];
    }

    [200, "OK", $m->version];
}

1;
# ABSTRACT: Handler for the "darkpan" authority scheme

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::CheckVersion::AuthorityScheme::darkpan - Handler for the "darkpan" authority scheme

=head1 VERSION

This document describes version 0.091 of Module::CheckVersion::AuthorityScheme::darkpan (from Perl distribution Module-CheckVersion), released on 2026-04-08.

=head1 SYNOPSIS

In F<Some/Module.pm>:

 our $AUTHORITY = 'darkpan:https://github.com/mycompany/my-darkpan/raw/refs/heads/master';

or perhaps:

 our $AUTHORITY = 'darkpan:file:/my/darkpan';

Actually you can also use a CPAN mirror (anything that contains
C<modules/02packages.details.txt.gz>):

 our $AUTHORITY = 'darkpan:https://www.cpan.org/';

=head1 DESCRIPTION

This module will parse the authority as:

 darkpan:<URL>

and retrieve:

 <URL>/modules/02packages.details.txt.gz

using L<HTTP::Tiny>, then parse the downloaded file using
L<Parse::CPAN::Packages>, then check module version from the parsed information.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-CheckVersion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-CheckVersion>.

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-CheckVersion>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

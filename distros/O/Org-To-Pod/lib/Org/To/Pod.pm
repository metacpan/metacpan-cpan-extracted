package Org::To::Pod;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use Log::ger;

our %SPEC;
$SPEC{org_to_pod} = {
    v => 1.1,
    summary => 'Export Org document to Pod',
};
sub org_to_pod {
    [501, "Not yet implemented"];
}

1;
# ABSTRACT: Export Org document to Pod

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::To::Pod - Export Org document to Pod

=head1 VERSION

This document describes version 0.04 of Org::To::Pod (from Perl distribution Org-To-Pod), released on 2017-07-10.

=head1 SYNOPSIS

 use Org::To::Pod qw(org_to_pod);
 my $pod = org_to_pod(source=>$org);

=head1 DESCRIPTION

NOT YET IMPLEMENTED.

=head1 FUNCTIONS


=head2 org_to_pod

Usage:

 org_to_pod() -> [status, msg, result, meta]

Export Org document to Pod.

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

Please visit the project's homepage at L<https://metacpan.org/release/Org-To-Pod>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Org-To-Pod>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-To-Pod>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

For more information about Org document format, visit http://orgmode.org/

L<Org::Parser>

L<Org::To::HTML>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

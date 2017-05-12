package Perinci::Access::Base;

use 5.010001;
use strict;
use warnings;

use URI::Split qw(uri_split);

our $VERSION = '0.33'; # VERSION

sub new {
    my ($class, %opts) = @_;
    $opts{riap_version} //= 1.1;
    bless \%opts, $class;
}

our $re_var     = qr/\A[A-Za-z_][A-Za-z_0-9]*\z/;
our $re_req_key = $re_var;
our $re_action  = $re_var;

# do some basic sanity checks on request
sub check_request {
    my ($self, $req) = @_;

    # XXX schema
    #$req //= {};
    #return [400, "Invalid req: must be hashref"]
    #    unless ref($req) eq 'HASH';

    # skipped for squeezing out performance
    #for my $k (keys %$req) {
    #    return [400, "Invalid request key '$k', ".
    #                "please only use letters/numbers"]
    #        unless $k =~ $re_req_key;
    #}

    $req->{v} //= 1.1;
    return [500, "Protocol version not supported"]
        if $req->{v} ne '1.1' && $req->{v} ne '1.2';

    my $action = $req->{action};
    return [400, "Please specify action"] unless $action;
    return [400, "Invalid action, please only use letters/numbers"]
        unless $action =~ $re_action;

    if (defined $req->{uri}) {
        ($req->{-uri_scheme}, $req->{-uri_auth}, $req->{-uri_path},
         $req->{-uri_query}, $req->{-uri_frag}) = uri_split($req->{uri});
    }

    # return success for further processing
    0;
}

1;
# ABSTRACT: Base class for all Perinci Riap clients

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Access::Base - Base class for all Perinci Riap clients

=head1 VERSION

This document describes version 0.33 of Perinci::Access::Base (from Perl distribution Perinci-Access-Base), released on 2015-09-06.

=head1 DESCRIPTION

This is a thin base class for all Riap clients (C<Perinci::Access::*>). It
currently only provides check_request() which does the following:

=over

=item * perform some basic sanity checking of the Riap request hash C<$req>

=item * split request keys C<uri>

Split result is put in C<< $req->{-uri_scheme} >>, C<< $req->{-uri_auth} >>, C<<
$req->{-uri_path} >>, C<< $req->{-uri_query} >>, and C<< $req->{-uri_frag} >>.

=back

=head1 ATTRIBUTES

=head2 riap_version => float (default: 1.1)

=head1 METHODS

=head2 new(%args) => OBJ

Constructor. Does nothing except creating a blessed hashref from C<%args>.
Subclasses should override this method and do additional stuffs as needed.

=head2 check_request($req) => RESP|undef

Should be called by subclasses during the early phase in C<request()>. Will
return an enveloped error response on error, or undef on success.

=head1 SEE ALSO

L<Perinci::Access>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-Base>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-Access-Base>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-Base>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Perinci::AccessUtil;

our $DATE = '2015-09-06'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

use MIME::Base64;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(insert_riap_stuffs_to_res
                    strip_riap_stuffs_from_res
                    decode_args_in_riap_req);

sub insert_riap_stuffs_to_res {
    my ($res, $def_ver, $nmeta, $encode) = @_;

    $res->[3]{'riap.v'} //= $def_ver // 1.1;
    if ($res->[3]{'riap.v'} >= 1.2) {
        # do we need to base64-encode?
        {
            last unless $encode // 1;
            last if $res->[3]{'riap.result_encoding'};
            if ($nmeta) {
                last unless $nmeta->{result}{schema} &&
                    $nmeta->{result}{schema}[0] eq 'buf';
            }
            last unless defined($res->[2]) && !ref($res->[2]) &&
                $res->[2] =~ /[^\x20-\x7f]/;
            $res->[2] = encode_base64($res->[2], "");
            $res->[3]{'riap.result_encoding'} = 'base64';
        }
    }
    $res;
}

sub strip_riap_stuffs_from_res {
    my $res = shift;

    my $ver = $res->[3]{'riap.v'} // 1.1;
    return [501, "Riap version returned by server ($ver) is not supported, ".
                "only recognize v1.1 and v1.2"]
        unless $ver == 1.1 || $ver == 1.2;

    if ($ver >= 1.2) {
        # check and strip riap.*
        for my $k (keys %{$res->[3]}) {
            next unless $k =~ /\Ariap\./;
            my $val = $res->[3]{$k};
            if ($k eq 'riap.v') {
            } elsif ($k eq 'riap.result_encoding') {
                return [501, "Unknown result_encoding returned by server ".
                            "($val), only base64 is supported"]
                    unless $val eq 'base64';
                $res->[2] = decode_base64($res->[2]//'');
            } else {
                return [501, "Unknown Riap attribute in result metadata ".
                            "returned by server ($k)"];
            }
            delete $res->[3]{$k};
        }
    }

    $res;
}

sub decode_args_in_riap_req {
    my $req = shift;

    my $v = $req->{v} // 1.1;
    if ($v >= 1.2) {
        if ($req->{args}) {
            my $args = $req->{args};
            for (keys %$args) {
                next unless /\A(.+):base64\z/;
                $args->{$1} = decode_base64($args->{$_});
                delete $args->{$_};
            }
        }
    }
    $req;
}

1;
# ABSTRACT: Utility module for Riap client/server

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::AccessUtil - Utility module for Riap client/server

=head1 VERSION

This document describes version 0.06 of Perinci::AccessUtil (from Perl distribution Perinci-AccessUtil), released on 2015-09-06.

=head1 SYNOPSIS

 use Perinci::AccessUtil qw(
     strip_riap_stuffs_from_res
     insert_riap_stuffs_to_res
     decode_args_in_riap_req
 );

 strip_riap_stuffs_from_res([200,"OK",undef,{"riap.v"=>1.1}]); # => [200,"OK",undef]
 strip_riap_stuffs_from_res([200,"OK",undef,{"riap.foo"=>1}]); # => [501, "Unknown Riap attribute in result metadata: riap.foo"]

 insert_riap_stuffs_to_res([200,"OK",undef); # => [200,"OK",undef,{"riap.v"=>1.1}]

 decode_args_in_riap_req({v=>1.2, args=>{"a:base64"=>"AAAA"}}); # => {v=>1.2, args=>{a=>"\0\0\0"}}

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 insert_riap_stuffs_to_res($envres[, $def_ver, $nmeta, $decode]) => array

Starting in Riap protocol v1.2, server is required to return C<riap.v> in result
metadata. This routine does just that. In addition to that, this routine also
encodes result with base64 when necessary.

This routine is used by Riap network server libraries, e.g.
L<Perinci::Access::HTTP::Server> and L<Perinci::Access::Simple::Server>.

=head2 strip_riap_stuffs_from_res($envres) => array

Starting in Riap protocol v1.2, client is required to check and strip all
C<riap.*> keys in result metadata (C<< $envres->[3] >>). This routine does just
that. In addition, this routine also decode result if C<riap.result_encoding> is
set, so the user already gets the decoded content.

This routine is used by Riap client libraries, e.g. L<Perinci::Access::Lite>,
L<Perinci::Access::Perl>, and L<Perinci::Access::HTTP::Client>,
L<Perinci::Access::Simple::Client>.

If there is no error, will return C<$envres> with all C<riap.*> keys already
stripped. If there is an error, an error response will be returned instead.
Either way, you can use the response returned by this function to user.

=head2 decode_args_in_riap_req($req) => $req

Replace C<ARGNAME:base64> keys in C<arg> in Riap request C<$req> with their
decoded values. Only done when C<v> key is at least 1.2.

This routine is used in Riap server libraries like in
L<Perinci::Access::HTTP::Server> and Perinci::Access::Simple::Server::*.

=head1 SEE ALSO

L<Riap>, L<Perinci::Access>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-AccessUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-AccessUtil-Check>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-AccessUtil>

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

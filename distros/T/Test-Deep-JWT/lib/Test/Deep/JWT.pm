package Test::Deep::JWT;
use 5.008005;
use strict;
use warnings;
use MIME::Base64 qw(decode_base64url);
use JSON qw(decode_json);
use Test::Deep ();
use Test::Deep::Cmp;
use Exporter qw(import);

our $VERSION = "0.02";

our @EXPORT = qw(jwt);

sub jwt {
    my ($claims, $header) = @_;
    return __PACKAGE__->new($claims, $header);
}

sub init {
    my ($self, $claims, $header) = @_;
    $self->{claims} = $claims;
    $self->{header} = $header;
}

sub descend {
    my ($self, $got) = @_;
    my ($header, $claims) = eval {
        my ($header, $claims, $sig) = split /\./, $got;
        return (
            decode_json(decode_base64url($header)),
            decode_json(decode_base64url($claims))
        );
    };
    if (my $e = $@) {
        $self->{error} = $e;
        return 0;
    }

    my $header_ok = 1;
    if ($self->{header}) {
        $header_ok = Test::Deep::wrap($self->{header})->descend($header);
    }

    return Test::Deep::wrap($self->{claims})->descend($claims) && $header_ok;
}

sub diagnostics {
    my ($self) = @_;
    return $self->{error} if $self->{error};
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::Deep::JWT - JWT comparison with Test:Deep functionality

=head1 SYNOPSIS

    use Test::Deep;
    use Test::Deep::JWT;

    cmp_deeply 'eyJhbGciOiJub25lIn0.eyJzdWIiOiIxMDAiLCJhdWQiOiIxMjMifQ.', jwt(+{
        sub => '100',
        aud => ignore()
    }, +{
        alg => 'none'
    });

=head1 DESCRIPTION

Test::Deep::JWT is the helper module for comparing JWT string with Test::Deep functionality.
This module will export a function called 'jwt'.

=head2 jwt(\%claims, \%header)

\%claims is the expected claims part of JWT.

\%header is the expected header part of JWT (Optional).

=head1 LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuuki Furuyama E<lt>addsict@gmail.comE<gt>

=head1 THANKS

This module is highly inspired from L<Test::Deep::JSON>.
The most part of implementation is borrowed from that module.

=head1 SEE ALSO

L<Test::Deep>

L<Test::Deep::JSON>

=cut


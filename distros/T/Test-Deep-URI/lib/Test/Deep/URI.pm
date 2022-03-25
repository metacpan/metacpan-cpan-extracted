package Test::Deep::URI;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.04';

# ABSTRACT: Easier testing of URIs for Test::Deep

use base qw(Exporter::Tiny);
our @EXPORT = qw(uri uri_qf);

use URI;
use Test::Deep ();
use Test::Deep::Cmp; # exports "new", other stuff.


################################################################################

sub uri {
    my ($expected_uri) = @_;
    return __PACKAGE__->new($expected_uri);
}

sub uri_qf {
    my ($expected_uri, $expected_query_form) = @_;
    my $self = __PACKAGE__->new($expected_uri, $expected_query_form);
}

sub init
{
    my ($self, $expected_uri, $expected_query_form) = @_;

    my $is_deep_qf = scalar(@_) == 3;

    if (! $is_deep_qf && ! defined $expected_uri) {
        warn "Missing argument to uri()!";
    }
    elsif ($is_deep_qf) {
        warn "Missing uri for uri_qf()!"
            unless defined $expected_uri;
        warn "Missing query form for uri_qf()!"
            unless defined $expected_query_form;
    }

    # URI objects act a little weird on URIs like "//host/path".
    # "/path" can be pulled via path(), but host() dies. Thus I'm
    # copying the host string if necessary.
    if (($expected_uri || '') =~ m{//([^/]+)/}) {
        $self->{host} = $1;
    }
    $self->{uri} = URI->new($expected_uri);
    if ($is_deep_qf) {
        $self->{is_deep_qf} = $is_deep_qf;
        $self->{expected_qf} = $expected_query_form;
    }
}

sub descend
{
    my ($self, $got) = @_;

    my $uri = $self->{uri};
    $got = URI->new($got);

    my @methods;
    push @methods, scheme   => $uri->scheme if $uri->scheme();
    local $@;
    eval {
        # Dies on partial URIs
        push @methods, host => $uri->host;
        # Don't need kludge
        delete $self->{host};
    };
    push @methods, path     => $uri->path;
    push @methods, fragment => $uri->fragment;

    my @expected = (
        $self->_get_expected_qf(),
        Test::Deep::methods(@methods)
    );
    my @received = (
        _to_hashref([ $got->query_form ]),
        $got,
    );

    # Kludge to test host!
    if ($self->{host}) {
        push @expected, $self->{host};
        push @received,
            ($got->can('host'))
                ? $got->host
                : $got =~ m{//([^/]+)/};
    }

    $self->data->{got} = $got;
    return Test::Deep::wrap(\@expected)->descend(\@received);
}

sub _get_expected_qf {
    my ($self) = @_;
    return $self->{expected_qf}
        if exists $self->{expected_qf};
    return _to_hashref([ $self->{uri}->query_form ]);
}

sub _to_hashref
{
    my ($list) = @_;
    my %hash;
    while (my ($key, $val) = splice(@$list, 0, 2))
    {
        if (exists $hash{$key}) {
            $hash{$key} = [ $hash{$key} ]
                unless ref $hash{$key};
            push @{$hash{$key}}, $val;
            next;
        }
        $hash{$key} = $val;
    }
    return \%hash;
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::Deep::URI - Easier testing of URIs for Test::Deep

=for markdown [![Build Status](https://travis-ci.org/nfg/Test-Deep-URI.svg?branch=master)](https://travis-ci.org/nfg/Test-Deep-URI)

=head1 SYNOPSIS

    use Test::Deep;
    use Test::Deep::URI;

    $testing_url = "http://site.com/path?a=1&b=2";
    cmp_deeply(
        $testing_url,
        all(
            uri("http://site.com/path?a=1&b=2"),
            # or
            uri("//site.com/path?a=1&b=2"),
            # or
            uri("/path?b=2&a=1"),
        )
    );

    cmp_deeply(
        $testing_url,
        uri_qf("/path", { a => 1, b => ignore() }),
    );

=head1 DESCRIPTION

Test::Deep::URI provides the functions C<uri($expected)> and
C<uri_qf($expected, $query_form)> for L<Test::Deep>.
Use it in combination with C<cmp_deeply> to test against partial URIs.

In particular I wrote this because I was tired of stumbling across unit
tests that failed because C<http://site.com/?foo=1&bar=2> didn't match
C<http://site.com/?bar=2&foo=1>. This helper is smart enough to compare
query_form parameters separately, while still enforcing the order of values
for duplicate parameters.

=head1 FUNCTIONS

=over 4

=item uri($expected)

Exported by default.

I<$expected> should be a string that can be passed to C<URI-E<gt>new()>.

=item uri_qf($expected, $query_form)

Exported by default.

I<$expected> should be a string that can be passed to C<URI-E<gt>new()>.

I<$query_form> should be whatever structure you want to check the query
form against.

=back

=head1 ERRATA

I've mostly been using this with URLs, but it's built around L<URI>
and should work with all types. Let me know if something doesn't work.

=head1 AUTHOR

Nigel Gregoire E<lt>nigelgregoire@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016 - Nigel Gregoire

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item L<Test::Deep>

=item L<Test::Deep::JSON>

=item L<Test::Deep::Filter>

=back

=cut

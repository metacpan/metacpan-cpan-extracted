package Net::RDAP::Server::Request;
# ABSTRACT: An RDAP request object.
use base qw(HTTP::Request);




sub from_cgi {
    my ($package, $cgi) = @_;

    my $url = URI->new(sprintf(
        '%s://%s:%s%s',
        $cgi->protocol,
        $cgi->virtual_host,
        $cgi->server_port,
        $cgi->request_uri,
    ))->canonical;

    my $request = $package->new($cgi->request_method, $url);

    foreach my $name (map { lc } $cgi->http) {
        my $value = $cgi->http($name);
        $name =~ s/^http_//i;
        $name =~ s/_/-/g;
        $request->header($name => $value);
    }

    $request->{_cgi} = $cgi;

    return $request;
}


sub cgi { shift->{_cgi} }


sub type {
    my $self = shift;

    return [ grep { length > 0 } $self->uri->path_segments ]->[0];
}


sub object {
    my $self = shift;

    # get the segments from the path...
    my @segments = grep { length > 0 } $self->uri->path_segments;

    # remove the leading value (which is the type)
    shift(@segments);

    # join the remaining segments (because CIDR prefixes will contain a slash)
    return join('/', @segments);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::RDAP::Server::Request - An RDAP request object.

=head1 VERSION

version 0.04

=head1 DESCRIPTION

L<Net::RDAP::Server::Request> represents an RDAP query.
L<Net::RDAP::Server::Response> extends L<HTTP::Response>.

=head1 ADDITIONAL METHODS

=head2 from_cgi($cgi)

This method constructs a L<Net::RDAP::Server::Request> object from a L<CGI>
object (L<Net::RDAP::Server> is based on L<HTTP::Server::Simple::CGI> which uses
the CGI API).

=head2 cgi()

This returns the L<CGI> object from which this object was constructed.

=head2 type()

This returns a string containing the RDAP query type (e.g. C<domain>, C<ip>,
etc).

=head2 object()

This returns a string containing the requested object. This value is irrelevant
for help queries and searches.

=head1 AUTHOR

Gavin Brown <gavin.brown@fastmail.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Gavin Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

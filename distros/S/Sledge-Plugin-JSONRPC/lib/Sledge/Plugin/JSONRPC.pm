package Sledge::Plugin::JSONRPC;
use strict;
use warnings;
use JSON::Syck;

our $VERSION = '0.01';

sub import {
    my $self = shift;
    my $pkg  = caller;

    $pkg->register_hook(BEFORE_INIT => sub {
        my $self = shift;
        $self->{_body} = do { local $/; <STDIN> };
    });

    no strict 'refs';
    *{"$pkg\::jsonrpc"} = \&_jsonrpc;
}

sub _jsonrpc {
    my $self = shift;

    my $req;
    # Deserialize request
    eval { $req = _deserialize_jsonrpc($self) };
    if ($@ || !$req) {
        warn qq{Invalid JSONRPC request "$@"};
        _serialize_jsonrpc($self,{
            result => undef,
            eror   => 'Invalid request'
        });
        return 0;
    }

    my $res = 0;
    my $method = $req->{method};
    if ($method) {
        if (my $code = $self->can("jsonrpc_$method")) {
            $res = $self->$code($req);
        } else {
            warn qq{Couldn't find jsonrpc method "$method"};
        }
    }

    # Serialize response
    _serialize_jsonrpc($self,{
        result => $res,
        error  => undef,
        id     => $req->{id},
    });
    return $res;
}

sub _deserialize_jsonrpc {
    my $self = shift;

    my $req = JSON::Syck::Load($self->{_body});
    return $req;
}

sub _serialize_jsonrpc {
    my ($self, $status) = @_;

    my $res = JSON::Syck::Dump($status);

    $self->r->content_type('text/javascript+json');
    $self->set_content_length(length $res);
    $self->send_http_header;
    $self->r->print($res);
    $self->invoke_hook('AFTER_OUTPUT');
    $self->finished(1);
}

=head1 NAME

Sledge::Plugin::JSONRPC - JSONRPC plugin for Sledge

=head1 VERSION

This documentation refers to Sledge::Plugin::JSONRPC version 0.01

=head1 SYNOPSIS

    package Your::Pages;
    use Sledge::Plugin::JSON;
    # entry point
    sub dispatch_jsonrpc {
        shift->jsonrpc;
    }
    
    sub jsonrpc_get {
        my $self = shift;
        .......
        return \@data;
    }

=head1 DESCRIPTION

Sledge::Plugin::JSONRPC is easy to implement JSONRPC plugin for Sledge.

=head1 AUTHOR

Atsushi Kobayashi, C<< <nekokak at gmail.com> >>

=head1 SEE ALSO

L<Sledge::Plugin::XMLRPC>

L<Catalyst::Plugin::JSONRPC>

L<JSON::Syck>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sledge-plugin-jsonrpc at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sledge-Plugin-JSONRPC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sledge::Plugin::JSONRPC

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sledge-Plugin-JSONRPC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sledge-Plugin-JSONRPC>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sledge-Plugin-JSONRPC>

=item * Search CPAN

L<http://search.cpan.org/dist/Sledge-Plugin-JSONRPC>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Atsushi Kobayashi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Sledge::Plugin::JSONRPC

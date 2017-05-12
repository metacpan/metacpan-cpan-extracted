package POEx::Role::PSGIServer::Streamer;
$POEx::Role::PSGIServer::Streamer::VERSION = '1.150280';
#ABSTRACT: (DEPRECATED) Provides streaming filehandle PSGI implementation
use MooseX::Declare;

class POEx::Role::PSGIServer::Streamer {
    use POE::Filter::Map;
    use POE::Filter::Stream;
    use MooseX::Types::Moose(':all');
    use POEx::Types::PSGIServer(':all');
    

    has server_context => (is => 'ro', isa => PSGIServerContext, required => 1);


    has closed_chunk => ( is => 'rw', isa => Bool, default => 0 );

    with 'POEx::Role::Streaming';


    method _build_filter {
        if($self->server_context->{chunked}) {
            POE::Filter::Map->new(
                Get => sub { $_ },
                Put => sub { 
                    my $data = shift;
                    return $data if $data =~ /0\r\n\r\n/;
                    my $len = sprintf "%X", do { use bytes; length($data) };
                    return "$len\r\n$data\r\n";
                }
            );
        }
        else {
            return POE::Filter::Stream->new();
        }
    }


    around done_writing {
        if($self->server_context->{chunked} && !$self->closed_chunk) {
            $self->closed_chunk(1);
            $self->put("0\r\n\r\n");
            return;
        }

        $self->$orig;
    }
}

1;

__END__

=pod

=head1 NAME

POEx::Role::PSGIServer::Streamer - (DEPRECATED) Provides streaming filehandle PSGI implementation

=head1 VERSION

version 1.150280

=head1 PUBLIC_ATTRIBUTES

=head2 server_context

    is: ro, isa: PSGIServerContext, required: 1

This is the server context from POEx::Role::PSGIServer. It is needed to determine the semantics of the current request

=head1 PRIVATE_ATTRIBUTES

=head2 closed_chunk

    is: rw, isa: Bool, default: 0

closed_chunk is a flag used by the advised L</around done_writing> to know whether the chunked transfer encoding needs a terminator or if the terminator has already been written to the output buffer

=head1 PROTECTED_METHODS

=head2 around done_writing

done_writing is advised to check if the context demands a chunked terminator and if one hasn't been sent yet. If so, it marks L</closed_chunk>, puts the terminator into the output buffer, and returns. Upon second invocation when the buffers are flushed, it will execute the original method.

=head1 PRIVATE_METHODS

=head2 _build_filter

_build_filter is overridden to return a L<POE::Filter::Map> filter if the current response is to be chunk transfer encoded. 

=head1 AUTHOR

Nicholas Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

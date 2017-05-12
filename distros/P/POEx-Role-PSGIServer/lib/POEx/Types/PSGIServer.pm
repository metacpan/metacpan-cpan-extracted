package POEx::Types::PSGIServer;
$POEx::Types::PSGIServer::VERSION = '1.150280';
#ABSTRACT: (DEPRECATED) Provides type constraints for use in POEx::Role::PSGIServer
use warnings;
use strict;

use MooseX::Types -declare => [qw/
    PSGIServerContext
    PSGIResponse
    PSGIBody
    HTTPRequest
    HTTPCode
/];

use MooseX::Types::Moose(':all');
use MooseX::Types::Structured(':all');
use POEx::Types(':all');
use HTTP::Request;
use HTTP::Status;
use Plack::Util;
use Scalar::Util;


subtype PSGIServerContext,
    as Dict [
        request => HTTPRequest,
        wheel => Optional[Wheel],
        version => Str,
        protocol => Str, 
        connection => Str,
        keep_alive => Bool,
        chunked => Optional[Maybe[Bool]],
        explicit_length => Optional[Maybe[Bool]],
    ];


subtype HTTPRequest,
    as class_type('HTTP::Request');


subtype HTTPCode,
    as Int,
    where {
        HTTP::Status::is_info($_) 
        || HTTP::Status::is_success($_)
        || HTTP::Status::is_redirect($_)
        || HTTP::Status::is_error($_)
    };


subtype PSGIBody,
    as Ref,
    where {
        Plack::Util::is_real_fh($_)
        || (Scalar::Util::blessed($_) && ($_->can('getline') && $_->can('close')))
    };


subtype PSGIResponse,
    as Tuple [
        HTTPCode,
        ArrayRef,
        Optional[ArrayRef|PSGIBody]
    ];
1;

__END__

=pod

=head1 NAME

POEx::Types::PSGIServer - (DEPRECATED) Provides type constraints for use in POEx::Role::PSGIServer

=head1 VERSION

version 1.150280

=head1 TYPES

=head2 PSGIServerContext

PSGIServerContext is defined as a Hash with the following keys:

    request => HTTPRequest,
    wheel => Optional[Wheel],
    version => Str,
    protocol => Str, 
    connection => Str,
    keep_alive => Bool,
    chunked => Optional[Bool],
    explicit_length => Optional[Bool],

The context is passed around to identify the current connection and what it is expecting

=head2 HTTPRequest

This is a simple class_type for HTTP::Request

=head2 HTTPCode

This constraint uses HTTP::Status to check if the Int is a valid HTTP::Status code

=head2 PSGIBody

The PSGIBody constraint covers two of the three types of body responses valid for PGSI responses: a real filehandle or a blessed reference that duck-types getline and close

=head2 PSGIResponse

This constraint checks responses from PSGI applications for a valid HTTPCode, an ArrayRef of headers, and the Optional PSGIBody or ArrayRef body

=head1 AUTHOR

Nicholas Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

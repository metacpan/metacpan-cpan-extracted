package SOAP::Transport::ActiveWorks::Server;
use base qw(SOAP::Transport::HTTP::Server);

1;

__END__

=head1 NAME

SOAP::Transport::ActiveWorks::Server - Server side ActiveWorks support for SOAP/Perl

=head1 SYNOPSIS

    require SOAP::Transport::ActiveWorks::Server;

    my $s = new SOAP::Transport::ActiveWorks::Server;

    $s->handle_request (
        $request_type,
        $request_class,
        $request_header_reader, 
        $request_content_reader,
        $response_header_writer,
        $response_content_writer,
        $optional_dispatcher
    );

=head1 DESCRIPTION

This package is a minimalist wrapper around SOAP::Transport::HTTP::Server which
may be substituted for this package with no loss of functionality.  This is not
guaranteed to be the case in the future.

=head1 DEPENDENCIES

SOAP::Transport::HTTP::Server;

=head1 AUTHOR

Daniel Yacob, L<yacob@rcn.com|mailto:yacob@rcn.com>

=head1 SEE ALSO

S<perl(1). SOAP(3). SOAP::Transport::ActiveWorks::Client(3).>

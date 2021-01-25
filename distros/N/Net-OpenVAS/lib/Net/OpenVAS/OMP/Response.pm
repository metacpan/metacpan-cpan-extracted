package Net::OpenVAS::OMP::Response;

use strict;
use warnings;
use utf8;
use feature ':5.10';

use Net::OpenVAS::Error;

use Carp;
use XML::Hash::XS;

use overload q|""| => 'raw', fallback => 1;

our $VERSION = '0.200';

sub new {

    my ( $class, %args ) = @_;

    my $request  = $args{'request'};
    my $response = $args{'response'};
    my $command  = $request->command;

    croak q/Net::OpenVAS::OMP::Response ( 'request' => ... ) must be "Net::OpenVAS::OMP::Request" instance/
        if ( !ref $request eq 'Net::OpenVAS::OMP::Request' );

    $response =~ s/<\?xml.*?\?>//;    # Remove XML version and encoding from the response for XML report

    my $status      = ( $response =~ /(status)="([^"]*)"/ )[1];
    my $status_text = ( $response =~ /(status_text)="([^"]*)"/ )[1];
    my $error       = undef;

    if ( $status >= 400 ) {
        $error = Net::OpenVAS::Error->new( $status_text, $status );
    }

    my $self = {
        status      => $status + 0,
        raw         => $response,
        request     => $request,
        status_text => $status_text,
        error       => $error,
        result      => eval { xml2hash $response },
    };

    return bless $self, $class;

}

sub result {
    my ($self) = @_;
    return $self->{result};
}

sub error {
    my ($self) = @_;
    return $self->{error};
}

sub status {
    my ($self) = @_;
    return $self->{status};
}

sub is_ok {
    my ($self) = @_;
    return ( $self->status == 200 ) ? 1 : 0;
}

sub is_created {
    my ($self) = @_;
    return ( $self->status == 201 ) ? 1 : 0;
}

sub is_accepted {
    my ($self) = @_;
    return ( $self->status == 202 ) ? 1 : 0;
}

sub is_forbidden {
    my ($self) = @_;
    return ( $self->status == 403 ) ? 1 : 0;
}

sub is_not_found {
    my ($self) = @_;
    return ( $self->status == 404 ) ? 1 : 0;
}

sub is_busy {
    my ($self) = @_;
    return ( $self->status == 409 ) ? 1 : 0;
}

sub is_server_error {
    my ($self) = @_;
    return ( $self->status >= 500 ) ? 1 : 0;
}

sub status_text {
    my ($self) = @_;
    return $self->{status_text};
}

sub raw {
    my ($self) = @_;
    return $self->{raw};
}

sub command {
    my ($self) = @_;
    return $self->{request}->command;
}

sub request {
    my ($self) = @_;
    return $self->{request};
}

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Net::OpenVAS::OMP::Response - Helper class for Net::OpenVAS::OMP


=head1 SYNOPSIS

    use Net::OpenVAS::OMP::Response;

    my $request = Net::OpenVAS::OMP::Request->new(
        command   => 'create_task',
        arguments => { ... }
    );

    my $response = Net::OpenVAS::OMP::Response->new(
        request => $request,
        response => '<create_task_response>...</create_task_response>'
    );

    if ($response->is_created) {
        say 'Task created:' . $response->status_text;
    }


=head1 CONSTRUCTOR

=head2 Net::OpenVAS::OMP::Response->new ( request => $request, response => $raw_response )

Create a new instance of L<Net::Net::OpenVAS::OMP::Response>.

Params:

=over 4

=item * C<request> : Request instance of L<Net::OpenVAS::OMP::Request>

=item * C<response> : RAW OMP response

=back


=head1 METHODS

=head2 $response->status

Return OMP status code.

    say $response->status; # 200

=head2 $response->status_text

Return OMP status text.

    say $response->status_text; # OK, request submitted

=head2 $response->command

Return OMP command name.

    say $response->command; # get_version

=head2 $response->result

Return OMP command hash result.

=head2 $response->request

Return L<Net::OpenVAS::OMP::Request> instance.

=head2 $response->error

Return L<Net::OpenVAS::Error> instance.

=head2 $response->raw

Return RAW OMP response.


=head2 STATUS HELPERS

=head3 $response->is_ok (200)

=head3 $response->is_created (201)

=head3 $response->is_accepted (202)

=head3 $response->is_forbidden (403)

=head3 $response->is_not_found (404)

=head3 $response->is_busy (409)

=head3 $response->is_server_error (>500)


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-OpenVAS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-OpenVAS>

    git clone https://github.com/giterlizzi/perl-Net-OpenVAS.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

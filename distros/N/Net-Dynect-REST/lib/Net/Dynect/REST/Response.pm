package Net::Dynect::REST::Response;
# $Id: Response.pm 177 2010-09-28 00:50:02Z james $
use strict;
use warnings;
use overload '""' => \&_as_string;
use Net::Dynect::REST::Response::Data;
use Net::Dynect::REST::Response::Msg;
use Carp;
our $VERSION = do { my @r = (q$Revision: 177 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME

Net::Dynect::REST::Response - A response object from a request to Dynect

=head1 SYNOPSIS

 use Net::Dynect::REST;
 my $dynect = Net::Dynect::REST->new(user_name => $user, customer_name => $customer, password => $password);
 use Net::Dynect::REST::Request;
 my $request = Net::Dynect::REST::Request->new(operation => 'read', service => 'Zone');
 $response = $dynect->execute($request);
 print $response . "\n";
 print $response->status . "\n";

=head1 METHODS

=head2 Creating

=over 4

=item new

This creates a new Response object. It can optionally take the arguments (as a hash ref) of:

=over 4

=item * format => $format

The valid format of the mssage, eithe JSON, YAML, XML, or HTML.

=item * content => $content

The decoded content from the HTTP response.

=item * request_duration => $duration

The time (in seconds, as a float) between the request being sent, and this response being returned.

=item * request_time => $time

The time the request was submitted to dynect (ie, this response was recieved as request_time + request_duration).

=back

=cut

sub new {
    my $proto = shift;
    my $self  = bless {}, ref($proto) || $proto;
    my %args  = @_;

    return unless defined $args{format};
    return unless defined $args{content};

    $self->request_duration( $args{request_duration} )
      if defined $args{request_duration};
    $self->request_time( $args{request_time} ) if defined $args{request_time};

    if ( $args{format} eq "JSON" ) {
        require JSON;
        JSON->import('decode_json');
        my $hash = decode_json( $args{content} );
        $self->job_id( $hash->{job_id} );
        $self->status( $hash->{status} );

        foreach ( @{ $hash->{msgs} } ) {
            push @{ $self->{msgs} }, Net::Dynect::REST::Response::Msg->new($_);
        }

        if ( ref( $hash->{data} ) eq "ARRAY" ) {
            foreach ( @{ $hash->{data} } ) {
                push @{ $self->{data} },
                  Net::Dynect::REST::Response::Data->new(
                    data => { value => $_ } );
            }
        }
        else {
            $self->data(
                Net::Dynect::REST::Response::Data->new( data => $hash->{data} )
            );
        }
    }

    return $self;
}

=back

=head2 Attributes

=over 4

=item job_id

This is the job_id for a request. It may be that, if a request takes longer thana  short period to process, a follow up request shoul dbe sent, with his job id, to get the eventual results.

=cut

sub job_id {
    my $self = shift;
    if (@_) {
        my $new = shift;
        return unless defined $new;
        if ( $new !~ /^\d+$/ ) {
            carp "Invalid job id: $new";
            return;
        }
        $self->{job_id} = $new;
    }
    return $self->{job_id};
}

=item status

This is one of 'success', 'failure' or 'incomplete'.

=cut

sub status {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( $new !~ /^success|failure|incomplete$/ ) {
            carp "Invalid status: $new";
            return;
        }
        $self->{status} = $new;
    }
    return $self->{status};
}

=item msgs

This is an array of zero or more messages that were returned. See L<Net::Dynect::REST::Response::Msg> for details of what eachof these look like.

=cut

sub msgs {
    my $self = shift;
    if (@_) {
        my $new = shift;
        $self->{msgs} = $new;
    }
    return $self->{msgs};
}

=item data

This is the data part of the message that was returned.

=cut

sub data {
    my $self = shift;
    if (@_) {
        my $new = shift;
        $self->{data} = $new;
    }
    return $self->{data};
}

=item request_duration 

This is th elengh of time, in seconds as a float, between the request being submitted, and this reponse being received.

=cut

sub request_duration {
    my $self = shift;
    if (@_) {
        my $new_time = shift;
        return unless $new_time =~ /^\d+(\.\d+)?$/;
        $self->{request_duration} = $new_time;
    }
    return $self->{request_duration};
}

=item request_time

This was the time that the corresponding request that this response was built for, was submitted to Dynect.

=cut

sub request_time {
    my $self = shift;
    if (@_) {
        my $new_time = shift;
        return unless $new_time =~ /^\d+$/;
        $self->{request_time} = $new_time;
    }
    return $self->{request_time};
}

sub _as_string {
    my $self = shift;
    my @texts;
    push @texts, sprintf "Job '%s'",    $self->job_id if defined $self->job_id;
    push @texts, sprintf "Status '%s'", $self->status if defined $self->status;
    push @texts, sprintf "Requested %s GMT", scalar gmtime $self->request_time
      if defined $self->request_time;
    push @texts, sprintf "took %s secs", $self->request_duration
      if defined $self->request_duration;
    my $text = join( ', ', @texts ) . "\n";
    $text .= "-- Msgs: " . join( ', ', @{ $self->msgs } ) . "\n"
      if defined $self->msgs;

    if ( ref $self->data eq "ARRAY" ) {
        foreach ( @{ $self->data } ) {
            $text .= "-- Data: " . $_;
        }
    }
    else {
        $text .= "-- Data: " . $self->data if defined $self->data;
    }
    return $text;
}

=back 

=head1 SEE ALSO

L<Net::Dynect::REST>, L<Net::Dynect::REST::Request>, L<Net::Dynect::REST::Response::Data>, L<Net::Dynect::REST::Response::Msg>, L<Net::Dynect::REST::info>.

=head1 AUTHOR

James Bromberger, james@rcpt.to

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by James Bromberger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;

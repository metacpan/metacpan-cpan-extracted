package Net::Dynect::REST::Session;
# $Id: Session.pm 149 2010-09-26 01:33:15Z james $
use strict;
use warnings;
use overload '""' => \&_as_string;
use Carp;
our $VERSION = do { my @r = (q$Revision: 149 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME

Net::Dynect::REST::Session - A session object for the Dynect REST API

=head1 SYNOPSIS

 use Net::Dynect::REST;
 my $dynect = Net::Dynect::REST->new(user_name => $user, customer_name => $customer, password => $password);
 print $dynect->session . "\n";
 print $dynect->session->api_version . "\n";
 $dynect->session->delete;

=head1 METHODS

=head2 Creating

=over 4

=item Net::Dynect::REST::Session->new();

Creates a new (empty) session object. You may supply the following arguments to populate this:

=over 4

=item response => $response

=item token => $token

=item user_name => $user

=item api_version => $version

=item uri => $uri

=back

=back

=cut 

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless $self, $class;

    my %args = @_;
    if ( defined $args{response}
        && ref( $args{response} ) eq "Net::Dynect::REST::Response" )
    {
        $self->token( $args{response}->data->token );
        $self->api_version( $args{response}->data->version );
    }

    $self->token( $args{token} )             if defined $args{token};
    $self->api_version( $args{api_version} ) if defined $args{api_version};
    $self->user_name( $args{user_name} )     if defined $args{user_name};
    $self->uri( $args{uri} )                 if defined $args{uri};

    return $self;
}

=head2 Attributes

=over 4

=item user_name 

This gets (or sets) the user_name that was associated with the session established - as a convenience in case you have multiple sessions open and want to track them.

=cut

sub user_name {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( $new !~ /^\S+$/ ) {
            carp "user_name should not have spaces";
            return;
        }
        $self->{user_name} = $new;
    }
    return $self->{user_name};
}

sub uri {
    my $self = shift;
    if (@_) {
        $self->{uri} = shift;
    }
    return $self->{uri};
}

=item token

This is the value of the B<Auth Token> header that must be sent with each authenticated request.

=cut

sub token {
    my $self = shift;
    if (@_) {
        my $new = shift;
        $self->{token} = $new;
        $self->_token_create_time( time() );
    }
    $self->_last_token_read_time( time() );
    return $self->{token};
}

=item api_version

This is the version of the API that satisfied the call to establish the session.

=cut

sub api_version {
    my $self = shift;
    if (@_) {
        $self->{api_version} = shift;
    }
    return $self->{api_version};
}

sub _as_string {
    my $self = shift;
    return unless defined $self->token;
    return
      sprintf "Auth-Token %s (api version %s) for user %s at uri %s at %s GMT",
      $self->token, $self->api_version || "unknown",
      $self->user_name || "unknown", $self->uri || "unknown",
      scalar( gmtime( $self->_token_create_time ) ) || "unknown";
}

sub _token_create_time {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( $new !~ /^\d+$/ ) {
            carp "Time should only be digits";
            return;
        }
        $self->{token_create_time} = $new;
    }
    return $self->{token_create_time};
}

sub _last_token_read_time {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( $new !~ /^\d+$/ ) {
            carp "Time should only be digits";
            return;
        }
        $self->{token_read_time} = $new;
    }
    return $self->{token_read_time};
}

=back

=head2 Destruction

=over 4

=item delete 

This will remove the session object

=cut

sub delete {
    my $self = shift;
    $self = undef;
}

=back 

=head1 SEE ALSO

L<Net::Dynect::REST>, L<Net::Dynect::REST::info>.

=head1 AUTHOR

James bromberger, james@rcpt.to

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by James Bromberger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.




=cut

1;

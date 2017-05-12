package Net::Sendy::API;

use strict;
use warnings;
use Carp ('croak');
use LWP::UserAgent;
use URI;

our $VERSION = '0.03';

sub new {
    my $class = shift;

    my %self = (
        api_key => '',
        url     => '',
        @_
    );

    return unless ( $self{api_key} && $self{url} );
    return bless \%self, $class;
}

sub subscribe {
    my $self = shift;
    my %args = @_;

    unless ( $args{list} && $args{email} ) {
        croak
"subscribe(): usage error. 'list' and 'email' attributes are required";
    }

    my $url = URI->new_abs( 'subscribe', $self->{url} )->as_string;
    $args{boolean} = "true";
    return $self->post( $url, \%args );
}

sub unsubscribe {
    my $self = shift;
    my %args = @_;

    unless ( $args{list} && $args{email} ) {
        croak
"unsubscribe(): usage error. 'list' and 'email' attributes are required";
    }

    my $url = URI->new_abs( 'unsubscribe', $self->{url} )->as_string;
    $args{boolean} = "true";
    return $self->post( $url, \%args );
}

sub subscription_status {
    my $self = shift;
    my %args = @_;

    unless ( $args{list} && $args{email} ) {
        croak
"subscription_status(): usage error. 'list_id' and 'email' attributes are required";
    }

    $args{api_key} = $self->{api_key};
    $args{list_id} = $args{list};
    delete $args{list};

    my $url =
      URI->new_abs( 'api/subscribers/subscription-status.php', $self->{url} );
    return $self->post( $url, \%args );
}

sub active_subscriber_count {
    my $self = shift;
    my %args = @_;

    unless ( $args{list} ) {
        croak
"active_subscriber_count(): usage error. 'list' attribute is required";
    }

    $args{api_key} = $self->{api_key};
    $args{list_id} = $args{list};
    delete $args{list};

    my $url = URI->new_abs( 'api/subscribers/active-subscriber-count.php',
        $self->{url} );
    return $self->post( $url, \%args );
}

sub _ua {
    my $self = shift;
    return $self->{_UA} if $self->{_UA};
    return $self->{_UA} = LWP::UserAgent->new;
}

sub post {
    my $self = shift;
    my ( $url, $params ) = @_;

    unless ( ref($params) && ( ref($params) eq 'HASH' ) ) {
        croak 'post(): usage error. $params must be a hashref';
    }

    return $self->_ua->post(@_);
}

1;
__END__

=head1 NAME

Net::Sendy::API - Perl SDK to sendy.co

=head1 SYNOPSIS

    use Net::Sendy::API;
    my $sendy = Net::Sendy::API->new(
        api_key => $api_key,
        url     => 'http://www.example.com/sendy/'
    );

    my $r = $sendy->subscribe(email => 'example@example.com', list => 'e');

    unless ( $r->is_success ) {
        die "HTTP request failed" > $r->status_line;
    }

=head1 ABSTRACT

Perl extension to interact with a sendy.co instance.

=head1 DESCRIPTION

This is an interface to http://www.sendy.co/api. As of this writing this is the complete implementation of the Sendy API.

=head1 METHODS

=over 4

=item new(api_key => $key, url => $url);

All the arguments are required. C<api_key> is what you receive in the email, after purchasing Sendy. C<url> is the URL to the folder where sendy is installed.

Returns a class instance. It not expected to fail.

=item subscribe(list => $list_id, email=>$email)

=item subscribe(list => $list_id, email => $email, custom_name => $custom_value,....)

Subscribes an e-mail address to a C<list>, where list is identified by its, what is called, C<an encrypted id>. You can find this C<id> next to each list name in the listing

If your list has custom fields you can enter them by passing more key/value pairs to the method.

Returns an instance of L<HTTP::Response|HTTP::Respone>. Example

    my $r = $sendy->subscribe(list => 'b', email => 'sherzodr@cpan.org', birth_day => "2013-09-12");
    unless ( $r->is_success ) {
        die "HTTP request failed: " . $r->status_line;
    }
    my $message = $r->decoded_content;

$message, according to L<http://www.sendy.co/api>, can be C<1>, C<Some fields are missing.>, C<Invalid email address.>, C<Invalid list ID.>, C<Already subscribed.>.

=item unsubscribe(list => $list_id, email => $email)

All the arguments are required. Unsubscribe an e-mail address from a list. See C<subscribe()> for the definition of the arguments. Returns an instance of L<HTTP::Response>. Example:

    my $r = $sendy->unsubscribe(list => 'b', email => 'sherzodr@example.com');
    unless ( $r->is_success ) {
        die "HTTP request failed: " . $r->status_line;
    }
    my $message = $r->decoded_content;

C<$message>, according to L<http://www.sendy.co/api>, can be C<1>, C<Some fields are missing.>, C<Invalid email address.>

=item subscription_status(list => $list_id, email => $email)

Returns an instance of L<HTTP::Response>. Body of the response can contain C<Subscribed>, C<Unsubscribed>, C<Unconfirmed>, C<Bounced>, C<Soft bounced>, C<Complained>, C<No data passed>, C<API key not passed>, C<Invalid API key>, C<Email not passed>, C<List ID not passed>, C<Email does not exist in list>.

For details on getting the body of the response see above.

=item active_subscriber_cont(list=>$list_id)

Returns an instance of L<HTTP::Response>. Body of the response should contain an integer if the call succeeds. If not, it may contains C<No data passed>, C<API key not passed>, C<Invalid API key>, C<List ID not passed>, C<List does not exist>.

For details on getting the body of the response see above.

=back

=head1 SEE ALSO

L<LWP::UserAgent|LWP::UserAgent>, L<HTTP::Response|HTTP::Response>, L<http://www.sendy.co/api>.

=head1 AUTHOR

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by L<Talibro LLC|https://www.talibro.com/>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

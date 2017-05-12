package SMS::ClickSend;

use strict;
use 5.008_005;
our $VERSION = '0.02';

use Carp;
use LWP::UserAgent;
use JSON;
use MIME::Base64;
use HTTP::Request;
use vars qw/$errstr/;

sub errstr { $errstr }

sub new {
    my $class = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $args{username} or croak 'username is required.';
    $args{api_key}  or croak 'api_key is required.';

    $args{ua} ||= LWP::UserAgent->new;

    return bless \%args, $class;
}

sub send {
    my $self = shift;
    my %params = @_ % 2 ? %{$_[0]} : @_;
    $self->request('send', 'GET', \%params);
}

sub reply {
    my $self = shift;
    my %params = @_ % 2 ? %{$_[0]} : @_;
    $self->request('reply', 'GET', \%params);
}

sub delivery {
    my $self = shift;
    my %params;
    if (scalar(@_) == 1 and ref($_[0]) ne 'HASH') {
        %params = (messageid => $_[0]);
    } else {
        %params = @_ % 2 ? %{$_[0]} : @_;
    }
    $self->request('delivery', 'GET', \%params);
}

sub balance {
    my $self = shift;
    my %params;
    if (scalar(@_) == 1 and ref($_[0]) ne 'HASH') {
        %params = (country => $_[0]);
    } else {
        %params = @_ % 2 ? %{$_[0]} : @_;
    }
    $self->request('balance', 'GET', \%params);
}

sub history {
    my $self = shift;
    my %params = @_ % 2 ? %{$_[0]} : @_;
    $self->request('history', 'GET', \%params);
}

sub request {
    my ($self, $url, $method, $params) = @_;

    $url = 'https://api.clicksend.com/rest/v2/' . $url . '.json';

    $params ||= {};
    $params->{method} = 'rest'; # we prefer rest

    my $uri = URI->new($url);
    $uri->query_form($params);

    my %headers = ();
    $headers{Authorization} = 'Basic ' . encode_base64($self->{username} . ':' . $self->{api_key}, '');

    my $req = HTTP::Request->new($method, $uri, HTTP::Headers->new(%headers));
    my $res = $self->{ua}->request($req);
    if (not $res->header('Content-Type') =~ /json/) {
        $errstr = $res->status_line;
        return;
    }

    return decode_json($res->decoded_content);
}

1;
__END__

=encoding utf-8

=head1 NAME

SMS::ClickSend - SMS gateway for clicksend.com

=head1 SYNOPSIS

    use SMS::ClickSend;

    my $sms = SMS::ClickSend->new(
        username => 'username',
        api_key  => 'API_KEY...',
    );

    my $res = $sms->send(
        to => '+61411111111',
        message => 'This is the message',
    );
    print Dumper(\$res); use Data::Dumper;

=head1 DESCRIPTION

SMS::ClickSend is a sms gateway for L<http://clicksend.us/>

API can be found at L<http://developers.clicksend.com/api/rest/>

=head1 METHODS

=head2 new

=over 4

=item * username

=item * api_key

can be found at L<https://my.clicksend.com/sms_settings_subaccounts.php>

=back

=head2 send

    $sms->send(
        to => '+61411111111',
        message => 'This is the message',
    );

more details can be found at L<http://developers.clicksend.com/api/rest/>

=head2 reply

=head2 delivery

    $sms->delivery('70A1EFA4-3F61-9D72-556C-D918FF3FC41');

=head2 balance

    $sms->balance();
    $sms->balance('AU');

=head2 history

    $sms->history();

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

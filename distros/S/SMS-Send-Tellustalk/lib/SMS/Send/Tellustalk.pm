package SMS::Send::Tellustalk;
use HTTP::Tiny;
use strict;
use warnings;
our $VERSION = '0.01';
use base 'SMS::Send::Driver';
use MIME::Base64;
use JSON;
use Data::Dumper;

sub new {
	my ($class, %args) = @_;
	die "$class needs hash_ref with _login and _password. (Optional _sender.)\n" unless $args{'_login'} && $args{'_password'};
	my $self = bless {%args}, $class;
	my $creds = "$self->{_login}" . ":" . "$self->{_password}";
	chomp($self->{base64_cred} = "Basic " . encode_base64($creds));
	$self->{base_url}    = 'https://tellus-talk.appspot.com';
	$self->{send_url}    = $self->{base_url} . '/send/v1';
	$self->{_sender}     = $self->{_sender} // 'FROM SENDER'; #Add the text that describes who sent the sms if not sent as _sender to new. Max 11 chars.
	return $self;
}

sub send_sms {
	my ($self, %args) = @_;
	my $json_args = {
		text                  => "$args{'text'}",
		to                    => "sms:$args{'to'}",
		sms_originator_source => "text",
		sms_originator_text   => "$self->{_sender}"
	};
	my $response = _post($self, to_json($json_args));
	if ($response->{status} eq "200") {
		return 1;
	}
	return 0;
}

sub _post {
	my ($self, $content) = @_;
	return HTTP::Tiny->new->post(
		$self->{send_url} => {
			content => $content,
			headers => {
				"accept"        => "application/json",
				"content-type"   => "application/json",
				"authorization"  => "$self->{base64_cred}"
			}
		}
	);
}

1;

__END__

=head1 NAME

SMS::Send::Tellustalk - SMS::Send driver to send messages via Tellustalk Rest API

=head1 SYNOPSIS

  use SMS::Send;

  # Create a sender
  my $sender = SMS::Send->new('Tellustalk',
		_login    => 'username',
		_password => 'password',
		_sender   => 'FROM ME', # Optional, max 11 chars.
  );

  # Send a message
  my $sent = $sender->send_sms(
		text => 'This is a test message',
		to   => '+4612345678',
  );

  if ( $sent ) {
		print "Message sent ok\n";
  } else {
		print "Failed to send message\n";
  }


=head1 DESCRIPTION

A driver for SMS::Send to send SMS text messages via Tellustalk Rest API

This is not intended to be used directly, but instead called by SMS::Send
(see synopsis above for a basic illustration, and see SMS::Send's documentation
for further information).


=head1 AUTHOR

Eivin Giske Skaaren, <eivin@sysmystic.com>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015  by Eivin Giske Skaaren

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut

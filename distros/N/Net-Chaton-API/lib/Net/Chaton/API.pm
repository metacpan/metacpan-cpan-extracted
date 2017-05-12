package Net::Chaton::API;

use 5.012001;
use strict;
use warnings;
use Pipe::Between::Object;
use LWP::UserAgent;
use HTTP::Request::Common qw(GET POST);
use JSON;
use utf8;
use Desktop::Notify;
use Encode::Guess qw/shiftjis euc-jp 7bit-jis/;
use Encode qw/from_to decode encode/;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Chaton::API ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';


# Preloaded methods go here.

our $ua = LWP::UserAgent->new;
our $json = JSON->new->allow_nonref;

sub new {#{{{
	my $class = shift;
	my $self = {
		who => 'Net::Chaton::API',
		@_,
	};
	return bless($self, $class);
}#}}}

sub login {#{{{
	my $self = shift;
	defined($self->{'room'}) or die "Error::Room uri is undefined";
	my $apilogin_url = $self->{'room'} . "apilogin";
	my %postdata = (
		who => $self->{who},
		s => 0,
	);	
	my $req = POST($apilogin_url, [%postdata]);
	my $responce = $ua->request($req);
	my $decoded_responce = $json->decode($responce->content);
	$self->{'post-uri'} = $decoded_responce->{'post-uri'};
	$self->{'comet-uri'} = $decoded_responce->{'comet-uri'};
	$self->{'cid'} = $decoded_responce->{'cid'};
	$self->{'pos'} = $decoded_responce->{'pos'};
}#}}}

sub Post {#{{{
	my ($self, $nick, $message) = @_;
	my $enc_nick    = guess_encoding($nick);
	my $enc_message = guess_encoding($message);

	if(ref $enc_nick) {
		from_to($nick,$enc_nick->name, 'utf8');
	}
	if(ref $enc_message) {
		from_to($message,$enc_message->name, 'utf8');
	}
	my %postdata = (
		nick => $nick,
		text => $message,
		cid  => $self->{'cid'},
	);
	my $req = HTTP::Request::Common::POST($self->{'post-uri'}, [%postdata]);
	$ua->request($req);
}#}}}

sub Observe{#{{{
	my ($self,$p, $c) = @_;
	my $decoded_responce;
	if(defined($p) && defined($c)) {
		my $req = GET("$self->{'comet-uri'}?p=$p&c=$c&s=0");
		my $res = $ua->request($req);
		$decoded_responce = $json->decode($res->content);
		$self->{'cid'} = $decoded_responce->{'cid'};
		$self->{'pos'} = $decoded_responce->{'pos'};
		if($decoded_responce->{'content'} eq ""){
			#if responce is empty the observe again immidietry.
			@_ = ($self,$self->{'pid'}, $self->{'cid'});
			goto &Observe;
		}
	}
	else {
		my $req = GET("$self->{'comet-uri'}?p=$self->{'pos'}&c=$self->{'cid'}&s=0");
		my $res = $ua->request($req);
		$decoded_responce = $json->decode($res->content);
		$self->{'cid'} = $decoded_responce->{'cid'};
		$self->{'pos'} = $decoded_responce->{'pos'};

		# if content is empty retry immediately
		if($decoded_responce->{'content'} eq "") {
			@_ = ($self,$self->{'pid'}, $self->{'cid'});
			goto &Observe;
		}
	}	
	my $name = @{$decoded_responce->{'content'}}[0]->[0];
	my $txt = @{$decoded_responce->{'content'}}[0]->[2];

	my $enc_name = guess_encoding($name);
	my $enc_txt  = guess_encoding($txt);

	if(ref $enc_name) {
		from_to($name,$enc_name->name, 'utf8');
	}
	if(ref $enc_txt) {
		from_to($txt,$enc_txt->name, 'utf8');
	}

	my $notify = Desktop::Notify->new();
	$notify->create(
		summary => $name,
		body => $txt,
		timeout => 5000)->show();
	@_ = ($self,$self->{'pid'}, $self->{'cid'});
	goto &Observe;
}#}}}
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::Chaton::API - WebAPI for Chaton.

=head1 SYNOPSIS

  use Net::Chaton::API;
  my $client = Net::Chaton::API->new {
  	room => 'http://practical-scheme.net/chaton/chaton',
  );

  #Login to room
  $client->login();
  #Post Some message
  $client->Post("User Name", "Message");
  #Start Observer the room
  $client->Observer();

=head1 DESCRIPTION

 This is simple module to connect Chaton.
 Chaton: http://practical-scheme.net/chaton

=head1 API

=head2 Constructor

=over

=item new(Room URL)

the constructor method. Return instance of Chaton client.

=back

=head2 API Method

=over 

=item login()

Login to the room.

=item Post(UserName, Message)

Post message to room.

=item Observe()

Start Observing the room.
Notify message if enabled.

=back

=head1 SEE ALSO

=head1 AUTHOR

Pocket, E<lt>poketo7878@yahoo.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Pocket.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

package Net::MyPeople::Bot;
use 5.010;
use utf8;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request::Common;
use JSON;
use Data::Printer;
use URI::Escape;
use File::Util qw(SL);
use Encode qw(is_utf8 _utf8_off);
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

# ABSTRACT: Implements MyPeople-Bot.

our $VERSION = '0.320'; # VERSION



has apikey=>(
	is=>'rw',
	required=>1
);


has web_proxy_base=>(
	is=>'rw',
);

has ua=>(
	is=>'ro',
	default=>sub{return LWP::UserAgent->new;},
);



our $API_BASE = 'https://apis.daum.net/mypeople';
our $API_SEND = $API_BASE . '/buddy/send.json';
our $API_BUDDY = $API_BASE . '/profile/buddy.json';
our $API_GROUP_MEMBERS = $API_BASE . '/group/members.json';
our $API_GROUP_SEND = $API_BASE . '/group/send.json';
our $API_GROUP_EXIT = $API_BASE . '/group/exit.json';
our $API_FILE_DOWNLOAD = $API_BASE . '/file/download.json';

our $API_SEND_LENGTH = 1000;

sub BUILD {
	my $self = shift;
}

sub _call_file {
	my $self = shift;
	my ($apiurl, $param, $path) = @_;
	$apiurl .= '?apikey='.uri_escape($self->apikey);
	$apiurl = $self->web_proxy_base.$apiurl if $self->web_proxy_base;

	my $req = POST( $apiurl, Content=>$param );
	DEBUG $req->as_string;
	my $res = $self->ua->request( $req );

	if( $res->is_success ){
		my $sl = SL;
		$path =~ s@$sl$@@;
		my $filepath;
		if( -d $path ){
			$filepath = $path.SL.$res->filename;
		}
		else{
			$filepath = $path;
		}
		DEBUG $filepath;
		open my $fh, '>', $filepath;
		binmode($fh);
		print $fh $res->content;
		close $fh;
		return $filepath;
	}
	else{
		ERROR p $res;
		return undef;
	}
}
sub _call_multipart {
	my $self = shift;
	my ($apiurl, $param) = @_;
	$apiurl .= '?apikey='.$self->apikey;
	$apiurl = $self->web_proxy_base.$apiurl if $self->web_proxy_base;

	#foreach my $k (keys %{$param}){
	#	$param->{$k} = uri_escape($param->{$k});
	#}

	my $req = POST(	$apiurl, 
		Content_Type => 'form-data',
		Content => $param
		);
	DEBUG $req->as_string;

	my $res = $self->ua->request($req);
	DEBUG p $res;

	if( $res->is_success ){
		return from_json( $res->content , {utf8 => 1} );
	}
	else{
		ERROR p $res;
		return undef;
	}
}
sub _call {
	my $self = shift;
	my ($apiurl, $param) = @_;
	$apiurl .= '?apikey='.uri_escape($self->apikey);
	$apiurl = $self->web_proxy_base.$apiurl if $self->web_proxy_base;

	my $req = POST( $apiurl, 
		#Content_Type => 'form-data',
		Content=>$param 
	);
	DEBUG $req->as_string;
	my $res = $self->ua->request( $req );
	DEBUG p $res;
	
	if( $res->is_success ){
		return from_json( $res->content , {utf8 => 1} );
	}
	else{
		ERROR p $res;
		return undef;
	}
}


sub buddy{
	my $self = shift;
	my ($buddyId) = @_;
	return $self->_call($API_BUDDY, {buddyId=>$buddyId} );
}


sub groupMembers{
	my $self = shift;
	my ($groupId) = @_;
	return $self->_call($API_GROUP_MEMBERS, {groupId=>$groupId} );
}


sub send{
	my $self = shift;
	my ($buddyId, $content, $attach_path, $do_not_split) = @_;
	if( $attach_path && -f $attach_path ){
		return $self->_call_multipart($API_SEND, [buddyId=>$buddyId, attach=>[$attach_path]] );
	}
	else{
		my @chunks;
		if( !$do_not_split && length $content > $API_SEND_LENGTH ){
			@chunks = split(/(.{$API_SEND_LENGTH})/, $content);
		}
		else{
			push(@chunks,$content);
		}

		my $res;
		foreach my $chunk (@chunks){
			_utf8_off($chunk) if is_utf8 $chunk;
			$res = $self->_call($API_SEND, {buddyId=>$buddyId, content=>$chunk} );
		}
		return $res;
	}
}


sub groupSend{
	my $self = shift;
	my ($groupId, $content, $attach_path, $do_not_split) = @_;
	if( $attach_path && -f $attach_path ){
		return $self->_call_multipart($API_GROUP_SEND, [groupId=>$groupId, attach=>[$attach_path]] );
	}
	else{
		my @chunks;
		if( !$do_not_split && length $content > $API_SEND_LENGTH ){
			@chunks = split(/(.{$API_SEND_LENGTH})/, $content);
		}
		else{
			push(@chunks,$content);
		}

		my $res;
		foreach my $chunk (@chunks){
			_utf8_off($chunk) if is_utf8 $chunk;
			$res = $self->_call($API_GROUP_SEND, {groupId=>$groupId, content=>$chunk} );
		}
		return $res;
	}
}


sub groupExit{
	my $self = shift;
	my ($groupId) = @_;
	return $self->_call($API_GROUP_EXIT, {groupId=>$groupId} );
}


sub fileDownload{
	my $self = shift;
	my ($fileId, $path) = @_;
	return $self->_call_file($API_FILE_DOWNLOAD, {fileId=>$fileId} , $path);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::MyPeople::Bot - Implements MyPeople-Bot.

=head1 VERSION

version 0.320

=head1 SYNOPSIS

	#!/usr/bin/env perl 

	use strict;
	use warnings;
	use utf8;

	use Net::MyPeople::Bot;
	use AnyEvent::HTTPD;
	use Data::Printer;
	use JSON;
	use Log::Log4perl qw(:easy);
	Log::Log4perl->easy_init($DEBUG); # you can see requests in Net::MyPeople::Bot.

	my $APIKEY = 'OOOOOOOOOOOOOOOOOOOOOOOOOO'; 
	my $bot = Net::MyPeople::Bot->new(apikey=>$APIKEY);

	# You should set up callback url with below informations. ex) http://MYSERVER:8080/callback
	my $httpd = AnyEvent::HTTPD->new (port => 8080);
	$httpd->reg_cb (
		'/'=> sub{
			my ($httpd, $req) = @_;
			$req->respond( { content => ['text/html','hello'] });
		},
		'/callback' => sub {
			my ($httpd, $req) = @_;

			my $action = $req->parm('action');
			my $buddyId = $req->parm('buddyId');
			my $groupId = $req->parm('groupId');
			my $content = $req->parm('content');

			callback( $action, $buddyId, $groupId, $content );
		}
	);

	sub callback{
		my ($action, $buddyId, $groupId, $content ) = @_;
		p @_;

		if   ( $action eq 'addBuddy' ){ # when someone add this bot as a buddy.
			# $buddyId : buddyId who adds this bot to buddys.
			# $groupId : ""
			# $content : buddy info for buddyId 
			# [
			#    {"buddyId":"XXXXXXXXXXXXXXXXXXXX","isBot":"N","name":"XXXX","photoId":"myp_pub:XXXXXX"},
			# ]

			my $buddy = from_json($content)->[0]; # 
			my $buddy_name = $buddy->{buddys}->{name};
			my $res = $bot->send($buddyId, "Nice to meet you, $buddy_name");

		}
		elsif( $action eq 'sendFromMessage' ){ # when someone send a message to this bot.
			# $buddyId : buddyId who sends message
			# $groupId : ""
			# $content : text

			my @res = $bot->send($buddyId, "$content");
			if($content =~ /^myp_pci:/){
				$bot->fileDownload($content,'./sample.jpg');
				# you can also download a profile image with buddy's photoId,'myp_pub:XXXXXXX'
			}
			if($content =~ /sendtest/){
				$bot->send($buddyId,undef,'./sample.jpg');
			}
			if($content =~ /buddytest/){
				my $buddy = $bot->buddy($buddyId);
				#{"buddys":[{"buddyId":"XXXXXXXXXXXXXXX","name":"XXXX","photoId":"myp_pub:XXXXXXXXXXXXXXX"}],"code":"200","message":"Success"}
				$bot->send($buddyId, to_json($buddy));
			}
		}
		elsif( $action eq 'createGroup' ){ # when this bot invited to a group chat channel.
			# $buddyId : buddyId who creates
			# $groupId : new group id
			# $content : members
			# [
			#    {"buddyId":"XXXXXXXXXXXXXXXXXXXX","isBot":"N","name":"XXXX","photoId":"myp_pub:XXXXXX"},
			#    {"buddyId":"XXXXXXXXXXXXXXXXXXXX","isBot":"N","name":"XXXX","photoId":"myp_pub:XXXXXX"},
			#    {"buddyId":"XXXXXXXXXXXXXXXXXXXX","isBot":"Y","name":"XXXX","photoId":"myp_pub:XXXXXX"}
			# ]

			my $members = from_json($content);
			my @names;
			foreach my $member (@{$members}){
				next if $member->{isBot} eq 'Y';# bot : The group must have only one bot. so, isBot='Y' means bot itself.
				push(@names, $member->{name});
			}

			my $res = $bot->groupSend($groupId, (join(',',@names)).'!! Nice to meet you.');
		
		}
		elsif( $action eq 'inviteToGroup' ){ # when someone in a group chat channel invites user to the channel.
			# $buddyId : buddyId who invites member
			# $groupId : group id where new member is invited
			# $content : 
			# [
			#    {"buddyId":"XXXXXXXXXXXXXXXXXXXX","isBot":"N","name":"XXXX","photoId":"myp_pub:XXXXXX"},
			#    {"buddyId":"XXXXXXXXXXXXXXXXXXXX","isBot":"Y","name":"XXXX","photoId":"myp_pub:XXXXXX"}
			# ]
			my $invited = from_json($content);
			my @names;
			foreach my $member (@{$invited}){
				next if $member->{isBot} eq 'Y';
				push(@names, $member->{name});
			}
			my $res = $bot->groupSend($groupId, (join(',',@names))."!! Can you introduce your self?");

		}
		elsif( $action eq 'exitFromGroup' ){ # when someone in a group chat channel leaves.
			# $buddyId : buddyId who exits
			# $groupId : group id where member exits
			# $content : ""

			my $buddy = $bot->buddy($buddyId); # hashref
			my $buddy_name = $buddy->{buddys}->[0]->{name};
			my $res = $bot->sendGroup($groupId, "I'll miss $buddy_name ...");

		}
		elsif( $action eq 'sendFromGroup'){ # when received from group chat channel
			# $buddyId : buddyId who sends message
			# $groupId : group id where message is sent
			# $content : text

			if( $content eq 'bot.goout' ){ # a reaction for an user defined command, 'bot.goout'
				my $res = $bot->groupSend($groupId, 'Bye~');
				$res = $bot->groupExit($groupId);
			}
			elsif($content =~ /membertest/){
				my $members= $bot->groupMembers($groupId);
				$bot->groupSend($groupId, to_json($members));
			}
			else{

				my $res = $bot->groupSend($groupId, "(GROUP_ECHO) $content");
			}
		}
	}
	print "Bot is started\n";
	$httpd->run;

=head1 DESCRIPTION

MyPeople is an instant messenger service of Daum Communications in Republic of Korea (South Korea).

MyPeople Bot is API interface of MyPeople.

If you want to use this bot API, 
Unfortunately,you must have an account for http://www.daum.net.
And you can understand Korean.

=head2 PROPERTIES 

=over 4

=item apikey 

required. put here MyPeople Bot APIKEY.

=item web_proxy_base

optional. If you don't have public IP, use L<https://github.com/sng2c/mypeople-bot-buffer> and put here as 'http://HOST:IP/proxy/'.
All of API urls are affected like 'http://HOST:IP/proxy/http://...'. 

=back

=head2 METHODS

=over 4

=item $res = $self->buddy( BUDDY_ID )

get infomations of a buddy.

returns buddy info.

	{
		"buddys":
			[
				{
					"buddyId":"XXXXXXXXXXXXXXX",
					"name":"XXXX",
					"photoId":
					"myp_pub:XXXXXXXXXXXXXXX"
				}
			],
			"code":"200",
			"message":"Success"
	}

=item $res = $self->groupMembers( GROUP_ID )

Get members in a group.

returns infos of members in the GROUP.

	{
		"buddys":
			[
				{
					"buddyId":"XXXXXXXXXXXXXXX",
					"name":"XXXX",
					"photoId":
					"myp_pub:XXXXXXXXXXXXXXX"
				},
				{
					"buddyId":"XXXXXXXXXXXXXXX",
					"name":"XXXX",
					"photoId":
					"myp_pub:XXXXXXXXXXXXXXX"
				},

				...
			],
			"code":"200",
			"message":"Success"
	}

=item $res = $self->send( BUDDY_ID, TEXT )

=item $res = $self->send( BUDDY_ID, TEXT, undef, $do_not_split )

=item $res = $self->send( BUDDY_ID, undef, FILEPATH )

send text to a buddy.

If you set FILEPATH, it sends the file to the buddy.

returns result of request.

=item $res = $self->groupSend( GROUP_ID, TEXT )

=item $res = $self->groupSend( GROUP_ID, TEXT, undef, $do_not_split )

=item $res = $self->groupSend( GROUP_ID, undef, FILEPATH )

send text to a group.

If you set FILEPATH, it sends the file to the group.

returns result of request.

=item $res = $self->groupExit( GROUP_ID )

exit from a group.

returns result of request.

=item $res = $self->fileDownload( FILE_ID, DIRPATH_OR_FILEPATH )

download attached file with FILE_ID.

If you set directory path on second argument, the file is named automatically by 'Content-Disposition' header.

returns path of the file saved.

=back

=head2 CALLBACK

See SYNOPSIS.

=head1 SEE ALSO

=over

=item *

MyPeople : L<https://mypeople.daum.net/mypeople/web/main.do>

=item *

MyPeople Bot API Home : L<http://dna.daum.net/apis/mypeople>

=back

=head1 AUTHOR

khs <sng2nara@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by khs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

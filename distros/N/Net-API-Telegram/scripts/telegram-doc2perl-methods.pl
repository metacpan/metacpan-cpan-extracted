#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Telegram API - ~/scripts/telegram-doc2perl-methods.pl
## Version 0.2
## Copyright(c) 2020 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/05/29
## Modified 2020/03/28
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
BEGIN
{
	use strict;
	use lib::mylib;
	use IO::File;
	use File::Basename;
	use URI;
	use HTML::TreeBuilder;
	use LWP::UserAgent;
	use Devel::Confess;
	use File::Spec;
	use DateTime;
	use Pod::Checker;
};

{
	## This tool will read Telegram API documentation online and generate all necessary perl modules + all the necessary methods for Net::API::Telegram and the associated pod documentation
	our $basedir = File::Spec->rel2abs( File::Basename::dirname( __FILE__ ) . '/..' );
	our $script_dir = "$basedir/scripts";
	our $BASE_DIR = "$basedir/scripts";
	our $out = IO::File->new();
	our $err = IO::File->new();
	$out->fdopen( fileno( STDOUT ), 'w' );
	$out->binmode( ":utf8" );
	$out->autoflush( 1 );
	$err->fdopen( fileno( STDERR ), 'w' );
	$err->binmode( ":utf8" );
	$err->autoflush( 1 );
	
	our $ua = LWP::UserAgent->new;
	$ua->timeout( 5 );
	$ua->agent( "Angels, Inc Legal Tech/$VERSION" );
	$ua->cookie_jar({ file => "$script_dir/cookies.txt" });
	
	my $data = &explore;
	my $objects = $data->{objects};
	my $meths = $data->{methods};
	$out->printf( "Found %d objects and %d methods\n", scalar( @{$data->{objects}} ), scalar( @{$data->{methods}} ) );
	$out->print( "Analysing all the possible object types...\n" );
	my $types = {};
	my $all_objects = {};
	my $downloadable_types = {};
	foreach my $ref ( @$objects )
	{
		$all_objects->{ $ref->{name} }++;
		foreach my $f ( @{$ref->{definition}} )
		{
			$types->{ $f->{type} }++;
		}
# 		my @words = split( /[[:blank:]]+/, $ref->{description}->as_trimmed_text );
# 		#$out->print( "$ref->{name} => ", $ref->{description}->as_trimmed_text, "\n" );
# 		## $out->print( join( ' ', @words[0..5] ), "\n" );
# 		my $shortDesc = $ref->{description}->as_trimmed_text;
# 		$shortDesc =~ s/^(This object represents|This[[:blank:]]+object[[:blank:]]+contains|This[[:blank:]]+object[[:blank:]]+represent|Contains|This[[:blank:]]+object[[:blank:]]+describes|Represents)[[:blank:]]+//g;
# 		$shortDesc =~ s/(\w)/\U\1\E/;
# 		my @phrase = split( /\.[[:blank:]]+/, $shortDesc );
# 		$shortDesc = $phrase[0];
# 		$shortDesc =~ s/\.+$//g;
# 		$out->print( $shortDesc, "\n" );
		foreach my $this ( @{$ref->{definition}} )
		{
			if( $this->{field} =~ /file_id/ )
			{
				$out->print( "Module $ref->{name}: $this->{field} is a downloadable file using the getFile method\n" );
				$downloadable_types->{ $this->{field} }++;
			}
		}
	}
	$out->printf( "%d downloadable fields found: %s\n", scalar( keys( %$downloadable_types ) ), join( ', ', sort( keys( %$downloadable_types ) ) ) );
# 	$out->print( "Objects found are:\n" );
# 	foreach my $o ( sort( keys( %$all_objects ) ) )
# 	{
# 		$out->print( "$o\n" );
# 	}
# 	exit;
	$out->print( "Analysing all possible required values...\n" );
	## https://core.telegram.org/bots/api#making-requests
	## methods returns an 'ok' boolean value
	## and description and error_code (integer) if there was error
	## or result with the data returned as a result
	# "The response contains a JSON object, which always has a Boolean field ‘ok’ and may have an optional String field ‘description’ with a human-readable description of the result. If ‘ok’ equals true, the request was successful and the result of the query can be found in the ‘result’ field. In case of an unsuccessful request, ‘ok’ equals false and the error is explained in the ‘description’. An Integer ‘error_code’ field is also returned, but its contents are subject to change in the future. Some errors may also have an optional field ‘parameters’ of the type ResponseParameters, which can help to automatically handle the error."
	# https://core.telegram.org/bots/api#making-requests
	my $requireds = {};
	my $meth_types = {};
	my $cnt = 0;
	## https://core.telegram.org/bots/api#editmessagecaption
	## https://core.telegram.org/bots/api#editmessagemedia
	## https://core.telegram.org/bots/api#editmessagereplymarkup
	## https://core.telegram.org/bots/api#setgamescore
	my $messageOrTrue = qr/^(?:editMessageLiveLocation|stopMessageLiveLocation|editMessageText|editMessageCaption|editMessageMedia|editMessageReplyMarkup|setGameScore)$/;
	my $handler =
	{
	'message_or_true' => sub
		{
			my( $meth, $ref ) = @_;
			$out->print( "${cnt}. Method $meth returns Message object or true (ok field)\n" );
			my $res = <<EOT;
	if( my \$t_error = \$self->_has_telegram_error( \$hash ) )
	{
		return( \$self->error( \$t_error ) );
	}
	elsif( \$hash->{result} )
	{
		my \$o = \$self->_response_to_object( 'Net::API::Telegram::Message', \$hash->{result} ) || 
		return( \$self->error( "Error while getting an object out of hash for this message: ", \$self->error ) );
		return( \$o );
	}
	else
	{
		return( \$hash->{ok} );
	}
EOT
			$ref->{return} = $res;
		},
	## https://core.telegram.org/bots/api#exportchatinvitelink
	'exportChatInviteLink' => sub
		{
			my( $meth, $ref ) = @_;
			$out->print( "${cnt}. Method $meth returns an invite link as a string\n" );
			my $res = <<EOT;
	if( my \$t_error = \$self->_has_telegram_error( \$hash ) )
	{
		return( \$self->error( \$t_error ) );
	}
	else
	{
		return( \$hash->{result} );
	}
EOT
			$ref->{return} = $res;
		},
	## Returns Int on success
	## https://core.telegram.org/bots/api#getchatmemberscount
	'getChatMembersCount' => sub
		{
			my( $meth, $ref ) = @_;
			$out->print( "${cnt}. Method $meth returns an integer\n" );
			my $res = <<EOT;
	if( my \$t_error = \$self->_has_telegram_error( \$hash ) )
	{
		return( \$self->error( \$t_error ) );
	}
	else
	{
		return( \$hash->{result} );
	}
EOT
			$ref->{return} = $res;
		},
	## https://core.telegram.org/bots/api#stoppoll
	'stopPoll' => sub
		{
			my( $meth, $ref ) = @_;
			$out->print( "${cnt}. Method $meth returns Poll object\n" );
			my $res = <<EOT;
	if( my \$t_error = \$self->_has_telegram_error( \$hash ) )
	{
		return( \$self->error( \$t_error ) );
	}
	elsif( \$hash->{result} )
	{
		my \$o = \$self->_response_to_object( 'Net::API::Telegram::Poll', \$hash->{result} ) || 
		return( \$self->error( "Error while getting a Poll object out of hash for this message: ", \$self->error ) );
		return( \$o );
	}
EOT
			$ref->{return} = $res;
		},
	## https://core.telegram.org/bots/api#uploadstickerfile
	'uploadStickerFile' => sub
		{
			my( $meth, $ref ) = @_;
			$out->print( "${cnt}. Method $meth returns File object\n" );
			my $res = <<EOT;
	if( my \$t_error = \$self->_has_telegram_error( \$hash ) )
	{
		return( \$self->error( \$t_error ) );
	}
	elsif( \$hash->{result} )
	{
		my \$o = \$self->_response_to_object( 'Net::API::Telegram::File', \$hash->{result} ) || 
		return( \$self->error( "Error while getting a File object out of hash for this message: ", \$self->error ) );
		return( \$o );
	}
EOT
			$ref->{return} = $res;
		},
	};
	foreach my $ref ( @$meths )
	{
		foreach my $pref ( @{$ref->{definition}} )
		{
			$requireds->{ $pref->{required} }++;
			$meth_types->{ $pref->{type} }++;
		}
		++$cnt;
		my $desc = $ref->{description}->as_trimmed_text;
		my $meth = $ref->{name};
		my $returnObject;
		## https://core.telegram.org/bots/api#editmessagelivelocation
		## https://core.telegram.org/bots/api#stopmessagelivelocation
		if( exists( $handler->{ $meth } ) )
		{
			$handler->{ $meth }->( $meth, $ref );
			next;
		}
		elsif( $meth =~ /$messageOrTrue/ )
		{
			$handler->{message_or_true}->( $meth, $ref );
			next;
		}
		## https://core.telegram.org/bots/api#sendmediagroup
		## https://core.telegram.org/bots/api#getchatadministrators
		## https://core.telegram.org/bots/api#getgamehighscores
		if( $desc =~ /An[[:blank:]]+Array[[:blank:]]+of[[:blank:]]+(\S+)[[:blank:]]+objects[[:blank:]]+is[[:blank:]]+returned/i ||
			$desc =~ /an[[:blank:]]+array[[:blank:]]+of.*?[[:blank:]]+(\S+)[[:blank:]]+is[[:blank:]]+returned/i ||
			$desc =~ /returns[[:blank:]]+an[[:blank:]]+Array[[:blank:]]+of[[:blank:]]+(\S+)[[:blank:]]+objects/i )
		{
			$returnObject = $1;
			## Because this is an array of objects, the object package name maye have an undue 's' at the end
			## If so, we remove it
			if( !exists( $all_objects->{ $returnObject } ) && substr( $returnObject, -1 ) eq 's' && exists( $all_objects->{ substr( $returnObject, 0, -1 ) } ) )
			{
				$returnObject = substr( $returnObject, 0, -1 );
			}
			$out->print( "${cnt}. Method $meth returns array of '$returnObject'\n" );
			die( "Regular expression failed, because object found \"$returnObject\" is unknown.\n" ) if( !exists( $all_objects->{ $returnObject } ) );
			my $res = <<EOT;
	if( my \$t_error = \$self->_has_telegram_error( \$hash ) )
	{
		return( \$self->error( \$t_error ) );
	}
	elsif( \$hash->{result} )
	{
		my \$arr = [];
		foreach my \$h ( \@{\$hash->{result}} )
		{
			my \$o = \$self->_response_to_object( 'Net\::API\::Telegram\::${returnObject}', \$h ) ||
			return( \$self->error( "Unable to create an Net\::API\::Telegram\::${returnObject} object with this data returned: ", sub{ \$self->dumper( \$h ) } ) );
			push( \@\$arr, \$o );
		}
		return( \$arr );
	}
EOT
			$ref->{return} = $res;
		}
		## https://core.telegram.org/bots/api#kickchatmember
		## https://core.telegram.org/bots/api#unbanchatmember
		## https://core.telegram.org/bots/api#restrictchatmember
		## https://core.telegram.org/bots/api#sendchataction
		## https://core.telegram.org/bots/api#promotechatmember
		## https://core.telegram.org/bots/api#setchatphoto
		## https://core.telegram.org/bots/api#deletechatphoto
		## https://core.telegram.org/bots/api#setchattitle
		## https://core.telegram.org/bots/api#setchatdescription
		## https://core.telegram.org/bots/api#pinchatmessage
		## https://core.telegram.org/bots/api#unpinchatmessage
		## https://core.telegram.org/bots/api#leavechat
		## https://core.telegram.org/bots/api#setchatstickerset
		## https://core.telegram.org/bots/api#deletechatstickerset
		## https://core.telegram.org/bots/api#answercallbackquery
		## https://core.telegram.org/bots/api#deletemessage
		## https://core.telegram.org/bots/api#createnewstickerset
		## https://core.telegram.org/bots/api#addstickertoset
		## https://core.telegram.org/bots/api#setstickerpositioninset
		## https://core.telegram.org/bots/api#deletestickerfromset
		## https://core.telegram.org/bots/api#answerinlinequery
		## https://core.telegram.org/bots/api#answershippingquery
		## https://core.telegram.org/bots/api#answerprecheckoutquery
		## https://core.telegram.org/bots/api#setpassportdataerrors
		elsif( $desc =~ /Returns[[:blank:]]+True[[:blank:]]+on[[:blank:]]+success\./i ||
			$desc =~ /On[[:blank:]]+success,[[:blank:]]+True[[:blank:]]+is[[:blank:]]+returned/i )
		{
			$out->print( "${cnt}. Method $meth returns true.\n" );
			my $res = <<EOT;
	if( my \$t_error = \$self->_has_telegram_error( \$hash ) )
	{
		return( \$self->error( \$t_error ) );
	}
	else
	{
		return( \$hash->{ok} );
	}
EOT
			$ref->{return} = $res;
		}
		## https://core.telegram.org/bots/api#sendmessage
		## https://core.telegram.org/bots/api#forwardmessage
		## https://core.telegram.org/bots/api#sendphoto
		## https://core.telegram.org/bots/api#sendaudio
		## https://core.telegram.org/bots/api#senddocument
		## https://core.telegram.org/bots/api#sendvideo
		## https://core.telegram.org/bots/api#sendanimation
		## https://core.telegram.org/bots/api#sendvoice
		## https://core.telegram.org/bots/api#sendvideonote
		## https://core.telegram.org/bots/api#sendlocation
		## https://core.telegram.org/bots/api#sendvenue
		## https://core.telegram.org/bots/api#sendcontact
		## https://core.telegram.org/bots/api#sendpoll
		## https://core.telegram.org/bots/api#getuserprofilephotos
		## On success, a File object is returned
		## https://core.telegram.org/bots/api#getfile
		## https://core.telegram.org/bots/api#getchat
		## https://core.telegram.org/bots/api#getchatmember
		## https://core.telegram.org/bots/api#sendsticker
		## https://core.telegram.org/bots/api#getstickerset
		## https://core.telegram.org/bots/api#sendinvoice
		## https://core.telegram.org/bots/api#sendgame
		## https://core.telegram.org/bots/api#getme
		elsif( $desc =~ /On[[:blank:]]+success,[[:blank:]]+a[[:blank:]]+(\S+)[[:blank:]]+object[[:blank:]]+is[[:blank:]]+returned/i ||
			$desc =~ /Returns[[:blank:]]+.*?in[[:blank:]]+form[[:blank:]]+of[[:blank:]]+a[[:blank:]]+(\S+)[[:blank:]]+object\./i ||
			$desc =~ /(\S+)[[:blank:]]+is[[:blank:]]+returned/i ||
			$desc =~ /returns[[:blank:]]+a[[:blank:]]+(\S+)[[:blank:]]+object/i )
		{
			$returnObject = $1;
			$out->print( "${cnt}. Method $meth returns '$returnObject'\n" );
			die( "Regular expression failed, because object found \"$returnObject\" is unknown.\n" ) if( !exists( $all_objects->{ $returnObject } ) );
			my $res = <<EOT;
	if( my \$t_error = \$self->_has_telegram_error( \$hash ) )
	{
		return( \$self->error( \$t_error ) );
	}
	elsif( \$hash->{result} )
	{
		my \$o = \$self->_response_to_object( 'Net\::API\::Telegram\::${returnObject}', \$hash->{result} ) ||
		return( \$self->error( "Unable to create an Net\::API\::Telegram\::${returnObject} object with this data returned: ", sub{ \$self->dumper( \$h ) } ) );
		return( \$o );
	}
EOT
			$ref->{return} = $res;
		}
		else
		{
			$out->print( "${cnt}. Unknown returned value for method '$meth' with description:\n$desc\n" );
		}
	}
# 	$out->print( "Possible required values are:\n" );
# 	foreach my $r ( sort( keys( %$requireds ) ) )
# 	{
# 		$out->print( "\t$r -> used $requireds->{$r} times\n" );
# 	}
# 	foreach my $t ( sort( keys( %$meth_types ) ) )
# 	{
# 		$out->print( "\t$t -> used $meth_types->{$t} times\n" );
# 	}
#   	exit;
	
	$out->printf( "%d methods found\n", scalar( @{$data->{methods}} ) );
# 	foreach my $ref ( @{$data->{methods}} )
# 	{
# 		$out->printf( "%s\n", $ref->{name} );
# 	}
	
 	$out->printf( "\n%d Object types found are:\n", scalar( keys( %$types ) ) );
# 	foreach my $t ( sort( keys( %$types ) ) )
# 	{
# 		$out->printf( "$t used %d times\n", $types->{ $t } );
# 	}
	#exit( 0 );
	
	my $type2method =
	[
	qr/^Boolean$/			=> "sub %s { return( shift->_set_get_scalar( '%s', \@_ ) ); }",
	qr/^Float$/				=> "sub %s { return( shift->_set_get_number( '%s', \@_ ) ); }",
	qr/^Float[[:blank:]]+number$/		=> "sub %s { return( shift->_set_get_number( '%s', \@_ ) ); }",
	qr/^Integer$/			=> "sub %s { return( shift->_set_get_number( '%s', \@_ ) ); }",
	qr/^String$/			=> "sub %s { return( shift->_set_get_scalar( '%s', \@_ ) ); }",
	qr/^True$/				=> "sub %s { return( shift->_set_get_scalar( '%s', \@_ ) ); }",
	## Array of ShippingOption
	qr/^Array[[:blank:]]+of[[:blank:]]+Array[[:blank:]]+of[[:blank:]]+(?<mod_name>\S+)/	=> "sub %s { return( shift->_set_get_object_array2( '%s', 'Net::API::Telegram::%s', \@_ ) ); }",
	qr/^Array[[:blank:]]+of[[:blank:]]+String$/	=> "sub %s { return( shift->_set_get_array( '%s', @_ ) ); }",
	qr/^Array[[:blank:]]+of[[:blank:]](?<mod_name>\S+)/ => "sub %s { return( shift->_set_get_object_array( '%s', 'Net\::API\::Telegram\::%s', \@_ ) ); }",
	qr/^(?<mod_name>\S+)$/				=> "sub %s { return( shift->_set_get_object( '%s', 'Net\::API\::Telegram\::%s', \@_ ) ); }",
	];
	our $dateSubFmt = "sub %s { return( shift->_set_get_datetime( '%s', \@_ ) ); }";
	#foreach my $p ( keys( %$type2method ) )
# 	for( my $i = 0; $i < scalar( @$type2method ); $i += 2 )
# 	{
# 		my $p = $type2method->[ $i ];
# 		$out->print( "$p\n" );
# 	}
# 	exit;
	#$out->print( ref( qr/^Array[[:blank:]]+of[[:blank:]]+Array[[:blank:]]+of[[:blank:]]+(\S+)/ ), "\n" );exit;
	
# 	foreach my $f ( @ARGV )
# 	{
# 		my( $fname, $path, $ext ) = File::Basename::fileparse( $f );
# 		my $def = {};
# 		my $fh = IO::File->new( "<$file" ) || die( "$f: $!\n" );
# 		while( defined( my $l = $fh->getline ) )
# 		{
# 			next if( $l =~ /^\#/ );
# 			my( $field, $type, $desc ) = split( /[[:blank:]]+/, $l, 3 );
# 		}
# 		$fh->close;
# 	}
	## Write each module
	foreach my $ref ( @{$data->{objects}} )
	{
		# next if( $ref->{name} ne 'Animation' );
		my $name = $ref->{name};
		my $pkg = "$ref->{name}.pm";
		my $hasDownload;
		if( -e( "$basedir/lib/Net/API/Telegram/${pkg}.no-overwrite" ) )
		{
			$out->print( "Instructed not to overwrite $pkg. Skipping.\n" );
			next;
		}
		my $dt = DateTime->now;
		my $today = $dt->strftime( '%Y/%m/%d' );
		$out->print( "Processing packaage file $pkg\n" );
		my $fh = IO::File->new( ">$basedir/lib/Net/API/Telegram/$pkg" ) || die( "$basedir/lib/Net/API/Telegram/$pkg: $!\n" );
		$fh->binmode( ':utf8' );
		$fh->print( <<EOT );
# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/${name}.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack\@deguest.jp>
## Created 2019/05/29
## Modified $today
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net\::API\::Telegram\::${name};
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( \$VERSION ) = '0.1';
};

EOT
		my $def = {};
		my $example_ids = [];
		my $example_ids_str;
		foreach my $this ( @{$ref->{definition}} )
		{
			$def->{ $this->{field} } = $this;
			if( exists( $downloadable_types->{ $this->{field} } ) )
			{
				$hasDownload++;
				$def->{download}++;
				push( @$example_ids, $this->{field} );
			}
		}
		$example_ids_str = join( ' or ', @$example_ids );
		my $boolean_types = [];
		FIELD: foreach my $field ( sort( keys( %$def ) ) )
		{
			my $this = $def->{ $field };
			my $type = $this->{type};
			push( @$boolean_types, $field ) if( $type eq 'Boolean' || $type eq 'True' );
			if( $field eq 'download' )
			{
				$fh->print( "sub download { return( shift->_download( \@_ ) ); }\n\n" );
			}
			elsif( $type eq 'Integer' && ( $field eq 'date' || $field =~ /_date(?:[^a-zA-Z]|$)|(?:[^a-zA-Z]|^)date_/ ) )
			{
				$fh->printf( $dateSubFmt, $field, $field );
				## We change the type so it shows appropriately in the documentation
				$this->{type} = 'Date';
				## No need to go further
				next FIELD;
			}
			for( my $i = 0; $i < scalar( @$type2method ); $i += 2 )
			{
				my $pattern = $type2method->[ $i ];
				next if( ref( $pattern ) ne 'Regexp' );
				if( $type =~ /$pattern/ )
				{
					my $modName = $+{mod_name};
					# $out->print( "module name found for type $type: '$modName'\n" );
					my $fmt = $type2method->[ $i + 1 ];
					if( length( $modName ) )
					{
						$fh->printf( $fmt, $field, $field, $modName );
					}
					else
					{
						$fh->printf( $fmt, $field, $field );
					}
					$fh->print( "\n\n" );
					next FIELD;
				}
			}
		}
		if( scalar( @$boolean_types ) )
		{
			my $boolean_fields = join( ' ', @$boolean_types );
			$fh->print( "sub _is_boolean { return( grep( /^\$_[1]\$/, qw( $boolean_fields ) ) ); }\n\n" );
		}
		$fh->print( "1;\n\n" );
		$fh->print( "__END__\n\n" );
		my $shortDesc = $ref->{description}->as_trimmed_text;
		$shortDesc =~ s/^(This object represents|This[[:blank:]]+object[[:blank:]]+contains|This[[:blank:]]+object[[:blank:]]+represent|Contains|This[[:blank:]]+object[[:blank:]]+describes|Represents)[[:blank:]]+//g;
		$shortDesc =~ s/(\w)/\U\1\E/;
		my @phrase = split( /\.[[:blank:]]+/, $shortDesc );
		$shortDesc = $phrase[0];
		$shortDesc =~ s/\.+$//g;
		## Start making the documentation
		$fh->print( <<EOT );
=encoding utf-8

=head1 NAME

Net::API::Telegram::${name} - ${shortDesc}

=head1 SYNOPSIS

	my \$msg = Net::API::Telegram::${name}->new( \%data ) || 
	die( Net::API::Telegram::${name}->error, "\\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::${name}> is a Telegram Message Object as defined here L<$ref->{link}>

This module has been automatically generated from Telegram API documentation by the script scripts/telegram-doc2perl-methods.pl.

=head1 METHODS

=over 4

=item B<new>( {INIT HASH REF}, \%PARAMETERS )

B<new>() will create a new object for the package, pass any argument it might receive
to the special standard routine B<init> that I<must> exist. 
Then it returns what returns B<init>().

The valid parameters are as follow. Methods available here are also parameters to the B<new> method.

=over 8

=item * I<verbose>

=item * I<debug>

=back

EOT
		
		if( !scalar( keys( %$def ) ) )
		{
			$fh->print( "There is no other method available.\n\n" );
		}
		FIELD: foreach my $field ( sort( keys( %$def ) ) )
		{
			my $this = $def->{ $field };
			my $desc = $this->{desc};
			$desc =~ s/\x{201c}([^\x{201d}]+)\x{201d}/I<$1>/gs;
			my $type = $this->{type};
			if( $field eq 'download' )
			{
				$fh->print( <<EOT );
=item B<download>( file_id, [ file extension ] )

Given a file id like ${example_ids_str}, this will call the B<getFile>() method from the parent L<Net::API::Telegram> package and receive a L<Net::API::Telegram::File> object in return, which contains a file path valid for only one hour according to Telegram api here L<https://core.telegram.org/bots/api#getfile>. With this file path, this B<download> method will issue a http get request and retrieve the file and save it locally in a temproary file generated by L<File::Temp>. If an extension is provided, it will be appended to the temproary file name such as C<myfile.jpg> otherwise the extension will be gussed from the mime type returned by the Telegram http server, if any.

This method returns undef() on error and sets a L<Net::API::Telegram::Error> or, on success, returns a hash reference with the following properties:

=over 8

=item I<filepath>

The full path to the temporary file

=item I<mime>

The mime type returned by the server.

=item I<response>

The L<HTTP::Response>

=item I<size>

The size in bytes of the file fetched

=back
EOT
			}
			elsif( exists( $all_objects->{ $type } ) )
			{
				$type = 'L<Net::API::Telegram::' . $type . '>';
			}
			$fh->print( <<EOT );
=item B<${field}>( $type )

$desc

EOT
		}
		$fh->print( <<EOT );
=back

=head1 COPYRIGHT

Copyright (c) 2000-2019 DEGUEST Pte. Ltd.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack\@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::Telegram>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

EOT
		$fh->close;
	}
	
	my $methods = {};
	## Reorganize data so we can sort them
	$out->print( "\nProducing now the list of methods...\n" );
	foreach my $ref ( @{$data->{methods}} )
	{
		$methods->{ $ref->{name} } = $ref;
	}
	my $fh = IO::File->new( ">$script_dir/methods.pod" ) || die( "$script_dir/methods.pod: $!\n" );
	my $fh2 = IO::File->new( ">$script_dir/methods.pl" ) || die( "$script_dir/methods.pl: $!\n" );
	$fh->binmode( ':utf8' );
	$fh2->binmode( ':utf8' );
	$fh->print( "=encoding utf-8\n\n" );
	$fh->print( "=head1 API METHODS\n\n=over 4\n\n" );
	foreach my $meth ( sort( keys( %$methods ) ) )
	{
		$out->print( "Processing method $meth\n" );
		my $ref = $methods->{ $meth };
		my $has_params = scalar( @{$ref->{definition}} ) ? ' %PARAMETERS ' : '';
		my $meth_desc = $ref->{description}->as_trimmed_text;
		$fh2->print( <<EOT );
sub ${meth}
{
	my \$self = shift( \@_ );
	my \$opts = \$self->_param2hash( \@_ ) || return( undef() );
EOT
		$fh2->print( <<EOT ) if( $meth eq 'setWebhook' );
    \$opts->{certificate} = Net\::API\::Telegram\::InputFile->new( \$self->{ssl_cert} ) if( \$opts->{certificate} && \$self->{ssl_cert} );
EOT
		
		$fh->print( <<EOT );
=item B<${meth}>(${has_params})

${meth_desc}

Reference: L<$ref->{link}>

EOT
		if( length( $has_params ) )
		{
			$fh->print( <<EOT );
This methods takes the following parameters:

=over 8

EOT
			my $packages_to_require = [];
			my $def = {};
			foreach my $this ( @{$ref->{definition}} )
			{
				$def->{ $this->{field} } = $this;
			}
			PARAM: foreach my $field ( sort( keys( %$def ) ) )
			{
				my $this = $def->{ $field };
				my $is_required_or_not = $this->{required} eq 'Optional' ? 'optional' : 'required';
				my $type = $this->{type};
				## $type could be: String, Integer, Boolean, Float, Float number, an object like InputFile
				## or an array of objects like "Array of InlineQueryResult"
				## or an array of objects with multiple possibilities like "Array of InputMediaPhoto and InputMediaVideo"
				## or multiple object possibilities like "InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply"
				$fh->print( <<EOT );
=item I<${field}>

EOT
				if( lc( $this->{required} ) eq 'yes' )
				{
					$fh2->print( <<EOT );
	return( \$self->error( "Missing parameter ${field}" ) ) if( !exists( \$opts->{ '${field}' } ) );
EOT
				}
				
				if( exists( $all_objects->{ $type } ) )
				{
					push( @$packages_to_require, $type );
					$fh->print( <<EOT );
This parameter type is an object L<Net::API::Telegram::$this->{type}> and is ${is_required_or_not}.
EOT
					if( $is_required_or_not eq 'required' )
					{
						$fh2->print( <<EOT );
	return( \$self->error( "Value provided for ${field} is not a Net::API::Telegram::$this->{type} object." ) ) if( ref( \$opts->{ '${field}' } ) ne 'Net::API::Telegram::$this->{type}' );
EOT
					}
					else
					{
						$fh2->print( <<EOT );
	return( \$self->error( "Value provided for ${field} is not a Net::API::Telegram::$this->{type} object." ) ) if( length( \$opts->{ '${field}' } ) && ref( \$opts->{ '${field}' } ) ne 'Net::API::Telegram::$this->{type}' );
EOT
					}
				}
				elsif( $type =~ /^Array[[:blank:]]+of[[:blank:]]+(.*?)$/ )
				{
					my $objects_found = $1;
					## Set this by default
					my $word = 'and';
					if( $objects_found =~ /[[:blank:]]+(and|or)[[:blank:]]+/ )
					{
						$word = $1;
					}
					my @those_objects = grep{ exists( $all_objects->{ $_ } ) } split( /[[:blank:]]+$word[[:blank:]]+/, $objects_found );
					push( @$packages_to_require, @those_objects );
					my @formatted = map( sprintf( 'L<Net::API::Telegram::%s>', $_ ), @those_objects );
					my $formatted_objects = join( " $word ", @formatted );
					$fh->print( <<EOT );
This parameter type is an array of $formatted_objects and is ${is_required_or_not}.
EOT
					my $object_pattern = join( '|', map( sprintf( 'Net::API::Telegram::%s', $_ ), @those_objects ) );
					my $object_list = join( ', ', @those_objects );
					if( lc( $this->{required} ) eq 'yes' )
					{
						$fh2->print( <<EOT );
	return( \$self->error( "Value provided for ${field} is not an array reference." ) ) if( ref( \$opts->{ '${field}' } ) ne 'ARRAY' );
EOT
						if( scalar( @those_objects ) )
						{
							$fh2->print( <<EOT );
	return( \$self->error( "Value provided is not an array of either of this objects: ${object_list}" ) ) if( !\$self->_param_check_array_object( qr\/^\(\?\:${object_pattern}\)\$/, \@_ ) );
EOT
						}
					}
					else
					{
						$fh2->print( <<EOT );
	return( \$self->error( "Value provided for ${field} is not an array reference." ) ) if( length( \$opts->{ '${field}' } ) && ref( \$opts->{ '${field}' } ) ne 'ARRAY' );
EOT
						if( scalar( @those_objects ) )
						{
							$fh2->print( <<EOT );
	return( \$self->error( "Value provided is not an array of either of this objects: ${object_list}" ) ) if( length( \$opts->{ '${field}' } ) && !\$self->_param_check_array_object( qr\/^\(\?\:${object_pattern}\)\$/, \@_ ) );
EOT
						}
					}
				}
				elsif( $type =~ /^(\S+)[[:blank:]](and|or)[[:blank:]]+/ )
				{
					my $word = $2;
					# $out->print( "Type found is '$type' and word is '$word'\n" );
					my @those_objects = split( /[[:blank:]]+${word}[[:blank:]]+/, $type );
					## my @formatted = map( sprintf( 'L<Net::API::Telegram::%s>', $_ ), @those_objects );
					my @formatted = ();
					foreach my $o ( @those_objects )
					{
						# $out->print( "Checking if '$o' is an object: ", exists( $all_objects->{ $o } ) ? 'yes' : 'no', "\n" );
						if( exists( $all_objects->{ $o } ) )
						{
							push( @formatted, sprintf( 'L<%s>', $o ) );
						}
						else
						{
							push( @formatted, $o );
						}
					}
					my $formatted_objects = join( " $word ", @formatted );
					$fh->print( <<EOT );
This parameter type is one of the following $formatted_objects and is ${is_required_or_not}.
EOT
					my $object_pattern = join( '|', map( sprintf( 'Net::API::Telegram::%s', $_ ), grep{ exists( $all_objects->{ $_ } ) } @those_objects ) );
					push( @$packages_to_require, grep{ exists( $all_objects->{ $_ } ) } @those_objects );
					my $object_list = join( ', ', @those_objects );
					## Empty pattern means all of the objects are actually String, Integer or Boolean, ie non-objects
					if( !length( $object_pattern ) )
					{
						if( lc( $this->{required} ) eq 'yes' )
						{
							$fh2->print( <<EOT );
	return( \$self->error( "Value provided for ${field} is not a valid value. I was expecting one of the following: ${object_list}" ) ) if( !length( \$opts->{ '${field}' } ) );
EOT
						}
					}
					else
					{
						if( lc( $this->{required} ) eq 'yes' )
						{
							$fh2->print( <<EOT );
	return( \$self->error( "Value provided for ${field} is not a valid object. I was expecting one of the following: ${object_list}" ) ) if( ref( \$opts->{ '${field}' } ) !~ \/^\(\?\:${object_pattern})\$/ );
EOT
						}
						else
						{
							$fh2->print( <<EOT );
	return( \$self->error( "Value provided for ${field} is not a valid object. I was expecting one of the following: ${object_list}" ) ) if( length( \$opts->{ '${field}' } ) && ref( \$opts->{ '${field}' } ) !~ \/^\(\?\:${object_pattern})\$/ );
EOT
						}
					}
				}
				else
				{
					$fh->print( <<EOT );
This parameter type is $this->{type} and is ${is_required_or_not}.

EOT
				}
				$fh->print( <<EOT );
$this->{desc}

EOT
			}
			$fh->print( "=back\n\n" );
			if( scalar( @$packages_to_require ) )
			{
				$fh2->printf( "    \$self->_load( [qw( %s )] ) || return( undef() );\n", join( ' ', map( 'Net::API::Telegram::' . $_, @$packages_to_require ) ) );
			}
		}
		## No parameter for this method
		else
		{
			$fh->print( "This method does not take any parameter.\n\n" );
		}
		my $methReturn = $ref->{return};
		chomp( $methReturn );
		$fh2->print( <<EOT );
	my \$form = \$self->_options2form( \$opts );
	my \$hash = \$self->query({
		'method' => '${meth}',
		'data' => \$form,
	}) || return( \$self->error( "Unable to make post query for method ${meth}: ", \$self->error->message ) );
${methReturn}
}

EOT
	}
	$fh->print( "=back\n\n" );
	$fh->close;
	$fh2->close;
	my $exit_value = 0;
	if( !defined( my $res = qx{perl -c $script_dir/methods.pl} ) )
	{
		$out->print( "Error found in $script_dir/methods.pl\n" );
		$exit_value = 1;
	}
	my $pod_checker = Pod::Checker->new( %options );
	$pod_checker->parse_from_file( "$script_dir/methods.pod", \*STDERR );
	if( $pod_checker->num_errors )
	{
		$out->printf( "%d errors found in $script_dir/methods.pod\n", $pod_checker->num_errors );
		$exit_value = 1;
	}
	else
	{
		$out->print( "$script_dir/methods.pod syntaxt OK\n" );
	}
	$out->printf( "%d warnings found in $script_dir/methods.pod\n", $pod_checker->num_warnings ) if( $pod_checker->num_warnings );
	
	if( !$exit_value )
	{
		my $main_file = "$basedir/lib/Net/API/Telegram.pm";
		my $new_file = "$basedir/lib/Net/API/Telegram-new.pm";
		my $fh_perl = IO::File->new( "<$script_dir/methods.pl" ) || die( "Unable to open the auto generated methods perl code: $!\n" );
		my $fh_pod = IO::File->new( "<$script_dir/methods.pod" ) || die( "Unable to open the auto generated methods pod documentation: $!\n" );
		my $fh_in = IO::File->new( "<$main_file" ) || die( "Unable to open Telegram.pm in read mode: $!\n" );
		my $fh_out = IO::File->new( ">$new_file" ) || die( "Unable to create new Telegram.pm file in $new_file: $!\n" );
		$fh_perl->binmode( ':utf8' );
		$fh_pod->binmode( ':utf8' );
		$fh_in->binmode( ':utf8' );
		$fh_out->binmode( ':utf8' );
		my $l;
		## 0 = not inside the are yet; 1 = inside; 2 = done; 3 = reached the end limit
		my $method_status = 0;
		my $pod_status = 0;
		while( defined( $l = $fh_in->getline ) )
		{
			if( $l =~ /^## START DYNAMICALLY GENERATED METHODS/ )
			{
				$method_status = 1;
				$fh_out->print( $l );
			}
			elsif( $l =~ /^## END DYNAMICALLY GENERATED METHODS/ )
			{
				$method_status = 3;
				$fh_out->print( $l );
			}
			elsif( $l =~ /^=head1 API METHODS/ )
			{
				$pod_status = 1;
				## This is not an oversight, the generated pod file contains this line already
			}
			elsif( $l =~ /^=head1 COPYRIGHT/ )
			{
				$pod_status = 3;
				$fh_out->print( $l );
			}
			elsif( $method_status == 1 )
			{
				$fh_out->print( $_ ) while( defined( $_ = $fh_perl->getline ) );
				$method_status = 2;
			}
			elsif( $method_status == 2 || $pod_status == 2 )
			{
				next;
			}
			elsif( $pod_status == 1 )
			{
				my $found_start = 0;
				while( defined( $_ = $fh_pod->getline ) )
				{
					$found_start++ if( /^=head1 API METHODS/ );
					next if( !$found_start && $_ !~ /^=head1 API METHODS/ );
					$fh_out->print( $_ );
				}
				$pod_status = 2;
			}
			else
			{
				$fh_out->print( $l );
			}
		}
		$fh_out->close;
		$fh_in->close;
		$fh_perl->close;
		$fh_pod->close;
		if( !$method_status )
		{
			$out->print( "** Failed to find the markeer for the start of auto generated perl methods insertion.\n" );
			$exit_value = 1;
		}
		elsif( !$pod_status )
		{
			$out->print( "** Failed to find the start (=head1 API METHODS) for auto generated pod insertion.\n" );
			$exit_value = 1;
		}
		elsif( -z( $new_file ) )
		{
			$out->print( "** Newly generated Telegram.pm file $new_file is empty!\n" );
			$exit_value = 1;
		}
# 		elsif( -s( $new_file ) < -s( $main_file ) )
# 		{
# 			$out->print( "** Newly created file size is smaller than previous one, which is not normal\n" );
# 			$exit_value = 1;
# 		}
		elsif( !defined( my $res = qx{perl -I${basedir}/lib -c $new_file} ) )
		{
			$out->print( "** Error found in $new_file\n" );
			$exit_value = 1;
		}
		elsif( !rename( $main_file, "$main_file.bak" ) )
		{
			$out->print( "** Unable to move original Telegram.pn file to $main_file.bak\n" );
			$exit_value = 1;
		}
		elsif( !rename( $new_file, $main_file ) )
		{
			$out->print( "** Unable to move new Telegram.pn file to $main_file\n" );
			$exit_value = 1;
		}
	}
	exit( $exit_value );
}

sub explore
{
	my $telegramAPIURL = 'https://core.telegram.org/bots/api';
	my $uri = URI->new( $telegramAPIURL );
	$ua->default_header( 'Content_Type' => 'multipart/form-data' );
	my $cache_file = "$script_dir/telegram-api.html";
	my $html;
	if( -e( $cache_file ) && -s( _ ) )
	{
		$out->print( "Re-using cached html\n" );
		my $tmp = IO::File->new( "<$cache_file" ) || die( "$cache_file: $!\n" );
		$tmp->binmode( ':utf8' );
		$html = join( '', $tmp->getlines );
		$tmp->close;
	}
	else
	{
		my $resp = $ua->get( $uri ) || die( $ua->error, "\n" );
		if( !$resp->is_success )
		{
			die( sprintf( "Unable to access $uri: %s (%s)\n", $resp->message, $resp->code ) );
		}
		$html = $resp->decoded_content;
		$out->print( "Saving html fetched\n" );
		my $tmp = IO::File->new( ">$cache_file" ) || die( "$cache_file: $!\n" );
		$tmp->binmode( ':utf8' );
		$tmp->autoflush( 1 );
		$tmp->print( $html );
		$tmp->close;
	}
	my $t = HTML::TreeBuilder->new;
	$t->parse( $html );
	$t->eof();
	
	my @h4 = $t->look_down( '_tag' => 'h4' );
	my @anchors = ();
	foreach my $title ( @h4 )
	{
		my $a = $title->look_down( '_tag' => 'a', 'name' => qr/\S+/ );
		push( @anchors, { 'name' => $title, 'link' => $a } ) if( defined( $a ) );
	}
	$out->printf( "Found %d anchors\n", scalar( @anchors ) );
	$out->print( "Now checking which one is an anchor for an object definition...\n" );
	my $objects = [];
	my $methods = [];
	ANCHOR: foreach my $info ( @anchors )
	{
		#my $txt = $a->as_trimmed_text;
		my $name = $info->{name};
		my $txt  = $info->{name}->as_trimmed_text;
		my $link = $uri->clone;
		#$link->path( $link->path . $info->{link}->attr( 'href' ) );
		$link->fragment( substr( $info->{link}->attr( 'href' ), 1 ) );
		#$out->printf( "Checking anchor '$txt' (%s)...\n", $a->as_HTML( '' ) );
		$out->printf( "Checking anchor '$txt' (%s)...\n", $link );
		## Object name start with upper case. Methods start with lower case
		if( $txt =~ /^[A-Z]\S+$/ )
		{
			$out->print( "\tok, name looks like an object\n\tChecking for a table in following elements...\n" );
			my $hash = { 'name' => $txt, 'link' => $link, 'type' => 'object' };
			## Now let's look for a table definition that follows...
			## The anchor is contained inside a h4 tag
			#my @next = $a->parent->right;
			my @next = $name->right;
			$out->printf( "\t\tFound %d following elements\n", scalar( @next ) );
			## Let's look for a table within the next 10 rightmost sibllings
			KINS: for( my $i = 0; $i < 10; $i++ )
			{
				my $this = $next[$i];
				next if( !ref( $this ) );
				$out->printf( "\t\t\tChecking tag %s\n", $this->tag );
				if( $this->tag eq 'table' )
				{
					$out->print( "\t" x 4, "Found a table, checking if this is an object definition one...\n" );
					my @ths = $this->look_down( '_tag' => 'th' );
					if( !scalar( @ths ) )
					{
						$out->print( "\tCould not find any th tags in this table for anchor '$txt'\n" );
						next;
					}
					## Yeah, we have a winner !
					my @header = map( $_->as_trimmed_text, @ths );
					$out->printf( ( "\t" x 4 ) . "th1 => '%s', th2 => '%s' and th3 => '%s'\n", @header );
					if( $header[0] eq 'Field' && $header[1] eq 'Type' && $header[2] eq 'Description' )
					{
						my @tds = $this->look_down( '_tag' => 'td' );
						if( scalar( @tds ) % 3 )
						{
							$out->printf( "\tI found a candidate table for object '$txt', but there are %d columns, and I was expecting a multiplier of 3!\n", scalar( @tds ) );
						}
						my $all = [];
						for( my $j = 0; $j < scalar( @tds ); $j += 3 )
						{
							my $def = {};
							$def->{field} = $tds[$j]->as_trimmed_text;
							$def->{type} = $tds[$j+1]->as_trimmed_text;
							$def->{desc} = $tds[$j+2]->as_trimmed_text;
							push( @$all, $def );
						}
						$hash->{definition} = $all;
						## Post processing description
						if( scalar( @{$hash->{description}} ) > 1 )
						{
							my @parts = map( $_->as_HTML( '' ), @{$hash->{description}} );
							## I don't know how else to merger HTML::Element
							my $t = HTML::TreeBuilder->new;
							$t->parse( join( '', @parts ) );
							$t->eof();
							$hash->{description} = $t;
						}
						else
						{
							$hash->{description} = $hash->{description}->[0];
						}
						push( @$objects, $hash );
						$out->printf( "Adding %d types definition for object '$txt'\n", scalar( @$all ) );
						next ANCHOR;
					}
					else
					{
						$out->print( "\t" x 4, "Nope, not the right one\n" );
					}
				}
				elsif( $this->tag eq 'p' && !exists( $hash->{description} ) )
				{
					$out->printf( ( "\t" x 4 ) . "Found tag p with text: '%s'\n", $this->as_trimmed_text );
					## $hash->{description} = $this;
					$hash->{description} = [] if( !exists( $hash->{description} ) );
					push( @{$hash->{description}}, $this );
				}
			}
			
			## I have a description, but no table found. This is likely to be an object with no parameter like InputFile
			if( $hash->{description} && !exists( $hash->{definition} ) )
			{
				## Post processing description
				if( scalar( @{$hash->{description}} ) > 1 )
				{
					my @parts = map( $_->as_HTML( '' ), @{$hash->{description}} );
					## I don't know how else to merger HTML::Element
					my $t = HTML::TreeBuilder->new;
					$t->parse( join( '', @parts ) );
					$t->eof();
					$hash->{description} = $t;
				}
				else
				{
					$hash->{description} = $hash->{description}->[0];
				}
				push( @$objects, $hash );
				$out->printf( "Adding object '$txt', but with no definition\n", scalar( @$all ) );
				next ANCHOR;
			}
		}
		## e.g. answerPreCheckoutQuery
		elsif( $txt =~ /^[a-z]+[A-Z][a-z]+?(?:[a-z]+[A-Z][a-z]+?)*$/ )
		{
			$out->print( "\tok, name looks like a method\n\tChecking for a table in following elements...\n" );
			my $hash = { 'name' => $txt, 'link' => $link, 'type' => 'method' };
			my @next = $name->right;
			$out->printf( "\t\tFound %d following elements\n", scalar( @next ) );
			## Let's look for a table within the next 10 rightmost sibllings
			KINS: for( my $i = 0; $i < 10; $i++ )
			{
				my $this = $next[$i];
				next if( !ref( $this ) );
				$out->printf( "\t\t\tChecking tag %s\n", $this->tag );
				## We stumbled upon another method definition, so we stop right here
				if( $this->tag eq 'h4' && defined( my $next_anchor = $this->look_down( '_tag' => 'a', 'name' => qr/\S+/ ) ) )
				{
					$out->print( "\t" x 4, "Stopping here, because I hit a next element.\n" );
					if( ref( $hash->{description} ) eq 'ARRAY' )
					{
						## Post processing description
						if( scalar( @{$hash->{description}} ) > 1 )
						{
							my @parts = map( $_->as_HTML( '' ), @{$hash->{description}} );
							## I don't know how else to merger HTML::Element
							my $t = HTML::TreeBuilder->new;
							$t->parse( join( '', @parts ) );
							$t->eof();
							$hash->{description} = $t;
						}
						else
						{
							$hash->{description} = $hash->{description}->[0];
						}
					}
					push( @$methods, $hash );
					$out->printf( "Adding %d types definition for object '$txt'\n", scalar( @$all ) );
					last;
				}
				if( $this->tag eq 'table' )
				{
					$out->print( "\t" x 4, "Found a table, checking if this is an object definition one...\n" );
					my @ths = $this->look_down( '_tag' => 'th' );
					if( !scalar( @ths ) )
					{
						$out->print( "\tCould not find any th tags in this table for anchor '$txt'\n" );
						next;
					}
					## Yeah, we have a winner !
					my @header = map( $_->as_trimmed_text, @ths );
					$out->printf( ( "\t" x 4 ) . "th1 => '%s', th2 => '%s' and th3 => '%s'\n", @header );
					if( $header[0] eq 'Parameter' && $header[1] eq 'Type' && $header[2] eq 'Required' && $header[3] eq 'Description' )
					{
						my @tds = $this->look_down( '_tag' => 'td' );
						if( scalar( @tds ) % 4 )
						{
							$out->printf( "\tI found a candidate table for object '$txt', but there are %d columns, and I was expecting a multiplier of 4!\n", scalar( @tds ) );
						}
						my $all = [];
						for( my $j = 0; $j < scalar( @tds ); $j += 4 )
						{
							my $def = {};
							$def->{field} = $tds[$j]->as_trimmed_text;
							$def->{type} = $tds[$j+1]->as_trimmed_text;
							$def->{required} = $tds[$j+2]->as_trimmed_text;
							$def->{desc} = $tds[$j+3]->as_trimmed_text;
							push( @$all, $def );
						}
						$hash->{definition} = $all;
						## Post processing description
						if( scalar( @{$hash->{description}} ) > 1 )
						{
							my @parts = map( $_->as_HTML( '' ), @{$hash->{description}} );
							## I don't know how else to merger HTML::Element
							my $t = HTML::TreeBuilder->new;
							$t->parse( join( '', @parts ) );
							$t->eof();
							$hash->{description} = $t;
						}
						else
						{
							$hash->{description} = $hash->{description}->[0];
						}
						push( @$methods, $hash );
						$out->printf( "Adding %d types definition for object '$txt'\n", scalar( @$all ) );
						next ANCHOR;
					}
					else
					{
						$out->print( "\t" x 4, "Nope, not the right one\n" );
					}
				}
				elsif( $this->tag eq 'p' )
				{
					$out->printf( ( "\t" x 4 ) . "Found tag p with text: '%s'\n", $this->as_trimmed_text );
					$hash->{description} = [] if( !exists( $hash->{description} ) );
					push( @{$hash->{description}}, $this );
				}
			}
		}
	}
# 	$out->printf( "Found %d objects\n", scalar( @$objects ) );
# 	foreach my $ref ( @$objects )
# 	{
# 		$out->printf( "%s => %d type definitions, link => %s, description => '%s'\n", $ref->{name}, scalar( @{$ref->{definition}} ), $ref->{link}, $ref->{description}->as_trimmed_text );
# 	}
	return( { 'objects' => $objects, 'methods' => $methods } );
}

__EMD__

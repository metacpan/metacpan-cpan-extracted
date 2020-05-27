package Service::Engine::Utility::Email;

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Service::Engine;

sub new {
    my ($class,$options) = @_;
    
    # set some defaults
    my $attributes = {'methods'=>{}};
    
    # load options
    if (ref($options) eq 'HASH') {
        foreach my $option (keys %{$options}) {
            $attributes->{$option} = $options->{$option};
        }
    }    
    my $self = bless $attributes, $class;
}

sub send {

    my ($self,$args) = @_;
    
    my $msg = $args->{'msg'};
    my $to = $args->{'to'};
    my $smtp_ip = $args->{'smtp_ip'};
    my $smtp_port = $args->{'smtp_port'};
    my $subject = $args->{'subject'};
    $smtp_ip ||= '127.0.0.1';
    $smtp_port ||= '25';
    my $force_text = $args->{'force_text'};
    $force_text ||= 0;
    
    my $from = $args->{'from'};
    
    if (!$from) {
        warn("Missing 'from' address in $args config " . Dumper($args));
        return 0;
    }
    
    if (!$to) {
        warn("Missing 'to' address in $args config " . Dumper($args));
        return 0;
    }
    
    return $self->_send_email({to=>$to, from=>$from, subject=>$subject, alt_body=>$msg, force_text=>$force_text, 'smtp_ip'=>$smtp_ip, 'smtp_port'=>$smtp_port});

}

sub _send_email {

	my($self,$h) = @_; 
	
    # use Data::Dumper;
	# warn "_mail_alt called: " . Dumper( @_ );
	use MIME::Entity;
	use HTML::TokeParser;
	use HTML::FormatText;
    use Mail::SendGrid::SmtpApiHeader;

    my $debug = 0; # this stops output from going to mail 
    my $sendmail = $^O eq "freebsd" ? '/usr/sbin/sendmail -t' : '/usr/lib/sendmail -t -i -Nfailure';
    my $mailer = $h->{mailer} ? $h->{mailer}  : "SAS-1.0";
    my $success = 0;
    my $host = $h->{'smtp_ip'};
    my $port = $h->{'smtp_port'};

    $h->{cc} ||= '';
    $h->{to} ||= '';

    $h->{to} =~ s/ +//g;
   	$h->{cc} =~ s/ +//g;
   	  
    $h->{cid} ||= 0;
    $h->{delivery_id} ||= 0;
    $h->{body} ||= '';
    $h->{from} ||= '';
    $h->{to} ||= '';
    $h->{cc} ||= '';
    $h->{subject} ||= '';
    $h->{alt_body} ||= '';
    
	$h->{body} =~ s/[^\x00-\x7f]//g;
    $h->{from} =~ s/[^\x00-\x7f]//g;
    $h->{to} =~ s/[^\x00-\x7f]//g;
    $h->{cc} =~ s/[^\x00-\x7f]//g;
    $h->{subject} =~ s/[^\x00-\x7f]//g;
    $h->{alt_body} =~ s/[^\x00-\x7f]//g;

     # create sendgrid header 
	my $sg_header = Mail::SendGrid::SmtpApiHeader->new();
	$sg_header->addFilterSetting( bypass_list_management => 'enable', 1 );
    $sg_header->setUniqueArgs({delivery_id => "$h->{delivery_id}"}) unless !$h->{delivery_id};
    
    # Determine what type of mail we are going to send
    my $force_text = $h->{force_text} ? 1 : 0;
    my $tokenized_body = HTML::TokeParser->new( \$h->{body} ) || warn "that didn't work!"; 
    my $tag = $tokenized_body->get_tag();
    
    my $add_head = ($tag && uc @$tag[0] eq 'HTML' ) ? 0 : 1;
    
    if ($add_head && $tag) {
    	$h->{body} = "<HTML><BODY>" . $h->{body} .  "</BODY></HTML>";
    }
    
    my $type = $tag ? 'multipart/alternative' : 'text/plain';
    
    my $file_path = '';
    if ($h->{file_path} && -e $h->{file_path}) {
        $type = 'multipart/mixed';
        $file_path = $h->{file_path};
    }
    
    if ($force_text) {
    	$type = 'text/plain';
    	$tag = '';
    	$h->{body} = $h->{alt_body} if $h->{alt_body};
    }
    
    $tokenized_body->unget_token();
    
    # if there is no alt_body and it is HTML - then build an alt
    if ($tag && !$h->{alt_body}) {
    	
    	# build alt content
    	require HTML::TreeBuilder;
        my $tree = HTML::TreeBuilder->new->parse($h->{body});
    	my $formated_text = HTML::FormatText->new();
    	$h->{alt_body}=$formated_text->format($tree);
    	
    }
    
    my $msg='';
    my $content = '';
        
    if ($type ne 'text/plain') {
		
		$msg = build MIME::Entity
			From    => $h->{from},
			To      => $h->{to},
			Cc     => $h->{cc},
			Bcc     => $h->{bcc},
			'Reply-To' => $h->{replyto},
			Subject => $h->{subject},
			Type    => $type,
			'X-NetSocial-CID' => $h->{cid},
			'X-Delivery-ID' => $h->{delivery_id},
			'X-Mailer'  => $mailer,
			'X-SMTPAPI' => $sg_header->asJSON;
		
		if ($type eq 'multipart/mixed') {
		    $content = $msg->attach(
                Type => 'multipart/alternative'
            );
		} else {
		    $content = $msg;
		}
		
		### Alternative #1 is the plain text:
		$content->attach(
			Type => 'text/plain',
			Data => $h->{alt_body},
			Encoding => 'quoted-printable'
			);
	
		### Alternative #2 is the HTML-with-content: 
		$content->attach(
			Type => 'text/html',
			Data => $h->{body},
			Encoding => 'quoted-printable'
			);
		
		if ($file_path) {
						
			$msg->attach(
				Filename => $h->{file_name},
				Path => $file_path,
				Type => $h->{file_type},
				Disposition => "attachment",
				Encoding => 'base64'
			);
			
		
		}
		
	} else {
		
		$msg = build MIME::Entity
			From    => $h->{from},
			To      => $h->{to},
			Cc     => $h->{cc},
			Bcc     => $h->{bcc},
			'Reply-To' => $h->{replyto}, 
			Subject => $h->{subject},
			Type    => $type,
			'X-Geekwarriors-CID' => $h->{cid},
			'X-Delivery-ID' => $h->{delivery_id},
			'X-Mailer'  => $mailer,
			'X-SMTPAPI' => $sg_header->asJSON,
			Data => $h->{body};
			
		if ($file_path) {
						
			$msg->attach(
				Filename => $h->{file_name},
				Path => $file_path,
				Type => $h->{file_type},
				Encoding => 'base64'
			);
		
		}
	
	}
	
    # send it out
    if( $h->{to} =~ m/(.*)\@(.*?)\..*/i  && !$debug) {
		use Net::SMTP;
		my $smtp = Net::SMTP->new( "$host:$port" , Debug   => 1);
		if (!$smtp) {
		    warn("SMTP Failure: $@");
		    return 0;
		}
		$smtp->mail( $h->{from} );
		$smtp->to( $h->{to} );
		$smtp->cc( $h->{cc} )unless !$h->{cc};
		$smtp->bcc( $h->{bcc} ) unless !$h->{bcc};
		$smtp->data();
		$smtp->datasend( $msg->stringify );
		$smtp->dataend();
		$success = 1;
		# warn('queued mail to ' . $h->{to});
		# warn($msg->stringify);
	} else {
	    warn('would send to ' . $h->{to} . "\n");
	    warn($msg->stringify . "\n");
	    warn("========\n");
	    # pretend it went out
	    $success = 1;
	}
    
    return $success;

}

1;

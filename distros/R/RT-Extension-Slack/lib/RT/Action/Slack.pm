package RT::Action::Slack;
use strict;
use warnings;
use base 'RT::Action';

sub Prepare {
    my $self = shift;
    RT->Logger->info("Slack Plugin: Action Prepare");
    return 1; 
}

sub Commit {
    my $self = shift;
    RT->Logger->info("Slack Plugin: Action Commit");
    use JSON;
    use RT::Queue;
    use LWP::UserAgent;
    use HTTP::Request::Common qw(POST);
    
    ################################
    ## Set Required Variables

    my $slackURL = RT->Config->Get('slackURL');
    my $rtURL = RT->Config->Get('rtURL');
    my $token = RT->Config->Get('SlackToken');
    
    # RT's "slack_timestamp" global custom field created by make initdb command
    my $rtSlackTimestampCF = "slack_timestamp";
    
    # get queue of this ticket:
    my $queue = $self->TicketObj->QueueObj->Name;
    RT->Logger->debug("Slack Plugin: Queue: $queue");
    
    my $requestorEmail = "";
    $requestorEmail = eval { $self->TicketObj->Requestors->UserMembersObj->First->EmailAddress };
    RT->Logger->debug("Slack Plugin: Requestor Email: ".$requestorEmail);
    
    my $ticketID = $self->TicketObj->id;
    my $ticketURL = '<'.$rtURL.'?id='.$ticketID.'|#'.$ticketID.'>';
    my $ticketSubject = $self->TicketObj->Subject;
    my $ticketStatus = $self->TicketObj->Status;
    my $requestorName = "";
    $requestorName = eval { $self->TicketObj->Requestors->UserMembersObj->First->RealName };
    my $owner = $self->TicketObj->OwnerObj->Name;
    my %queue_config = RT->Config->Get('SlackQueueConfig');

    
    ##############################
    ## Detect Queue Change
    ## This is a tricky transaction.  Let's grab the old queue name:
    ## Get the ID of the old queue from the transaction, create an object, load data into object, get the name.  It's a lot of steps but that's how this works.
    
    my $is_queue_change = 0;
    my $field = $self->TransactionObj->Field // '';
    my $type = $self->TransactionObj->Type // '';
    my $oldQueueName = '';
    
    if ( defined($field) && $field eq "Queue" && $type eq "Set" ){
        $is_queue_change = 1;
        RT->Logger->debug("Slack Plugin: queue change detected.");
        my $oldQueueID = $self->TransactionObj->OldValue;
        my $oldQueueObj = RT::Queue->new($self->TicketObj->CurrentUser);
        $oldQueueObj->Load($oldQueueID);
        $oldQueueName = $oldQueueObj->Name;
        RT->Logger->debug("Slack Plugin: oldQueueName: $oldQueueName");
    } else {
        RT->Logger->debug("Slack Plugin: queue change NOT detected."); 
    }
        
    #######################################################
    ## Configure Message Formatting
    ## ...perhaps this should live in the Slack_Config.pm file
    my %status_formatting = (
        'resolved' => { style => 'strike' }, # Puts ~ around text
        'deleted'  => { style => 'strike_skull' }, # Puts ~ around text and skull emoji
        'deployed' => { style => 'strike' },
        'approved' => { style => 'white_check' },
        'rejected' => { style => 'rejected' },
        'cancelled' => { style => 'rejected' },
        'failed' => { style => 'rejected' },
    );
    
    # Set default configuration based on variables at top of script
    my $channel  = "";
    
    # Look up the configuration for the current queue
    my $config = $queue_config{$queue};
    
    if (defined $config) {
        # Check if this queue uses custom logic
        if (exists $config->{custom_logic} && ref($config->{custom_logic}) eq 'CODE') {
            # Execute the custom logic sub
            # It's expected to return a hash ref, e.g., { channel => "..." }
            my $custom_config = $config->{custom_logic}->($requestorEmail);
            $channel = $custom_config->{channel} if defined $custom_config->{channel};
        } else {
            # Standard config
            $channel = $config->{channel} if exists $config->{channel};
        }
    } else {
        RT->Logger->debug("Slack Plugin: No channel mapping found for queue: $queue. No message will be sent.");
        return 1; 
    }
    
    # If, after all that, we don't have a channel then something is wrong.
    unless ($channel) {
        RT->Logger->debug("Slack Plugin: Mapping found for $queue, but no channel was resolved (check custom_logic?). No message will be sent.");
        return 1;
    }
    
    # Check for and run any custom text logic
    my $customQueueText = '';
    if (exists $config->{custom_text} && ref($config->{custom_text}) eq 'CODE') {
        $customQueueText = $config->{custom_text}->($self->TicketObj);
    }
    
    
    ################################
    ## Defang any URLs that might appear in Subjects so that no one in slack clicks on a malicious link.
    ## Slack tries to be helpful by turning some text into clickable links:
    ## 1. Anything ending in a TLD like .com, .net, etc. becomes clickable.
    ## 2. Anything that includes :// becomes a link.  For example: nonsense://blah is a clickable link in slack.
    
    RT->Logger->debug("Slack Plugin: Ticket Subject: ".$ticketSubject);
    my $ticketSubjectDefanged = $ticketSubject;
    
    # To avoid uninitialized variable errors I switched from using $1, $2, etc to $&
    $ticketSubjectDefanged =~ s/(:\/\/)|(\.edu)|(\.com)|(\.net)|(\.org)|(\.xyz)|(\.co)|(\.us)|(\.shop)|(\.cn)|(\.ru)|(\.tk)/[$&]/g;
    
    RT->Logger->debug("Slack Plugin: Ticket Subject Defanged: ".$ticketSubjectDefanged);
    
    
    ####################################
    ## Take or Steal
    
    # if not owned, show Take link.  If owned, show Steal link & text
    my $stealText = "";
    my $rtAction = "";
    
    if ($owner eq "Nobody"){
        $stealText = "";
        $rtAction = "Take";
    } else {
        $stealText = "from ".$owner;
        $rtAction = "Steal";
    }
    my $ticketActionURL = '<'.$rtURL.'?Action='.$rtAction.';id='.$ticketID.'|'.$rtAction.'>';
    
    
    # Build the message text
    my @message_parts;
    push @message_parts, '['.$ticketStatus.']';
    push @message_parts, $requestorName if (defined $requestorName && $requestorName ne '');
    push @message_parts, '['.$ticketURL.' '.$ticketSubjectDefanged.']';
    push @message_parts, $customQueueText if (defined $customQueueText && $customQueueText ne '');
    push @message_parts, $ticketActionURL;
    push @message_parts, $stealText if (defined $stealText && $stealText ne '');   
    my $messageText = join(' ', @message_parts);    
    
    ####################################
    ## Apply status-based formatting
    if (exists $status_formatting{$ticketStatus}) {
        my $style = $status_formatting{$ticketStatus}->{style};
        if ($style eq 'strike') {
            $messageText = '~' . $messageText . '~';
        } elsif ($style eq 'strike_skull') {
            $messageText = ':skull: ~' . $messageText . '~ :skull:';
        } elsif ($style eq 'white_check') {
            $messageText = ':white_check_mark: ' . $messageText;
        } elsif ($style eq 'rejected') {
            $messageText = ':x: ' . $messageText;
        } elsif ($style eq 'quote') {
            $messageText = '> ' . $messageText; # Prepend blockquote marker
        }
    }
    
    ######################################
    ## Construct the final data payload for Slack
    my $data = {
        channel => $channel,
        text => $messageText
    };
    
    ####################################################
    ## Detect if new post, update, or queue change.
    ## Each requires different handling. 
    # Supposedly this gets us a fresh view of the ticket and not whatever is cached.
    # I don't think it actually solved anything and may not be necessary.
    $self->TicketObj->Load( $self->TicketObj->id );
    
    my $slackTimestampCFValue = $self->TicketObj->FirstCustomFieldValue('slack_timestamp');
    my $json_resp;
    
    if ( $is_queue_change == 1 ) {
        RT->Logger->info("Slack Plugin: Queue change detected, posting new message and updating the previous one.");
        # Post the new message to the new channel
        $json_resp = _slack_api_call("chat.postMessage", $data, $slackURL, $token);
     
        # Update the OLD message
        my $old_config = $queue_config{$oldQueueName};
        my $old_ts = $slackTimestampCFValue;
        
        if (defined $old_config && exists $old_config->{channel} && (defined $old_ts && $old_ts ne '')) {
            my $old_channel_id = $old_config->{channel};
            RT->Logger->debug("Slack Plugin: Attempting to delete old message $old_ts in old channel $old_channel_id");
            
            my $movedText = "~[moved] $ticketURL $ticketSubjectDefanged~";
    
            my $updateData = {
                channel => $old_channel_id,
                ts      => $old_ts,
                text    => $movedText
            };
            
            # We don't really care about the response from this, it's "best effort".
            _slack_api_call("chat.update", $updateData, $slackURL, $token); 
        }
    } elsif ( defined $slackTimestampCFValue && $slackTimestampCFValue ne '' ) {
        # Not new post or queue change.  Update existing.
        RT->Logger->debug("Slack Plugin: Timestamp already set, updating existing message.");
        $data->{'ts'} = $slackTimestampCFValue;
        $json_resp = _slack_api_call("chat.update", $data, $slackURL, $token);
    } else { 
        RT->Logger->debug("Slack Plugin: Timestamp not set, posting new message.");
        $json_resp = _slack_api_call("chat.postMessage", $data, $slackURL, $token);
        RT->Logger->debug("Slack Plugin: Message posted...theoretically");
    }
    
    
    #################################
    ## Process the response from the main API call
    
    # Check if $json_resp is defined (meaning the API call was successful)
    if (defined $json_resp) {
        RT->Logger->debug('Slack Plugin: Main Slack API call successful!');
        
        # extract slack message timestamp
        my $ts = $json_resp->{'ts'};
    
        # We save the timestamp if:
        # 1. We got a timestamp back
        # 2. AND ( The timestamp field was blank OR this was a queue change )
        if ( $ts && ( !defined $slackTimestampCFValue || $slackTimestampCFValue eq '' || $is_queue_change == 1 ) ) {   
            RT->Logger->debug("Slack Plugin: Attempting to save new timestamp $ts to $rtSlackTimestampCF");
            
            # Record the slack timestamp to RT
            my ($status, $msg) = $self->TicketObj->AddCustomFieldValue( Field =>$rtSlackTimestampCF, Value => $ts );
            if (!$status) {
                RT->Logger->debug("Slack Plugin: Failed to set $rtSlackTimestampCF custom field: $msg");
            } else {
                 RT->Logger->info("Slack Plugin: Successfully set $rtSlackTimestampCF custom field to $ts");
            }
        } elsif (!$ts) {
            RT->Logger->debug("Slack Plugin: Slack post successful but no timestamp (ts) was returned.");
        }
    } else {
        RT->Logger->debug("Slack Plugin: Main Slack API call failed.");
    }   
    return 1;
}


sub _slack_api_call {
    my ($endpoint, $payload, $base_url, $auth_token) = @_;
    
    my $post_url = $base_url . $endpoint;
    my $header = ['Content-type' => 'application/json', 'Authorization' => $auth_token];
    my $encoded_data;
    
    eval {
        $encoded_data = encode_json($payload);
    };
    if ($@) {
        RT->Logger->debug("Slack Plugin: Failed to encode JSON payload for $endpoint: $@");
        return undef;
    }

    my $r = HTTP::Request->new('POST', $post_url, $header, $encoded_data); 
    #RT->Logger->debug("Slack Plugin: Action Commit - HTTP request is: $post_url $header $payload $encoded_data");
    my $ua = LWP::UserAgent->new;
    $ua->ssl_opts( verify_hostname => 1 );
    $ua->timeout(10); # 10 second timeout

    my $resp = $ua->request($r);
    if ($resp->is_success) {
        my $decoded_resp = $resp->decoded_content;
        
        if (!defined $decoded_resp || $decoded_resp eq '') {
            RT->Logger->debug("Slack Plugin: Slack API call $endpoint successful with no content.");
            return { ok => 1, ts => undef }; 
        }
        
        my $json_decoded_resp;
        eval {
            $json_decoded_resp = decode_json($decoded_resp);
        };
        if ($@) {
            RT->Logger->debug("Slack Plugin: Failed to decode JSON response from Slack ($endpoint): $@");
            return undef;
        }
        if (exists $json_decoded_resp->{ok} && !$json_decoded_resp->{ok}) {
             RT->Logger->debug("Slack Plugin: Slack API call $endpoint failed: $json_decoded_resp->{error}");
             return undef;
        }
        return $json_decoded_resp; # Success! Return the decoded JSON
        
    } else {
        RT->Logger->debug("Slack Plugin: Failed post to slack $endpoint, status is:" . $resp->status_line . " | URL was: " . $post_url);
        return undef; # Failure
    }
}

sub Describe {
    my $self = shift;
    return "Slack Plugin: Customizable and synced RT ticket notifications in Slack";
}

1;

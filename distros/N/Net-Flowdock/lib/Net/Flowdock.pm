package Net::Flowdock;
{
  $Net::Flowdock::VERSION = '0.03';
}
use Moose;

# ABSTRACT: Flowdock API

use Net::HTTP::Spore;


has '_client' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        
        my $client = Net::HTTP::Spore->new_from_string(
            '{
                "name": "Flowdock",
                "authority": "GITHUB:gphat",
                "version": "1.0",
                "methods": {
                    "get_flows": {
                        "path": "/v2/flows",
                        "method": "GET",
                        "authentication": true
                    },
                    "get_flow": {
                        "path": "/v2/flows/:organization/:flow",
                        "required_params": [
                            "organization", "flow"
                        ],
                        "method": "GET",
                        "authentication": true
                    },
                    "push_team_inbox": {
                        "path": "/v2/messages/team_inbox/:key",
                        "required_params": [
                            "source", "from_address", "subject", "content"
                        ],
                        "optional_params": [
                            "from_name", "project", "format", "tags", "link"
                        ],
                        "method": "POST",
                        "authentication": false
                    },
                    "push_chat": {
                        "path": "/v2/messages/chat/:key",
                        "required_params": [
                            "content", "external_user_name"
                        ],
                        "optional_params": [
                            "tags"
                        ],
                        "method": "POST",
                        "authentication": false
                    },
                    "send_message": {
                         "path": "/v2/flows/:organization/:flow/messages",
                         "required_params": [
                             "event", "content"
                         ],
                         "optional_params": [
                             "tags"
                         ],
                         "method": "POST",
                         "authentication": true
                     }
                }
            }',
            base_url => $self->url,
            trace => $self->debug
        );
        $client->enable('Format::JSON');
        $client->enable('Auth::Basic', username => $self->username, password => $self->password);
        return $client
    }
);


has 'debug' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);


has 'key' => (
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    default => sub { die "This call requires a key to be set" },
);


has 'password' => (
    is => 'rw',
    isa => 'Str'
);


has 'url' => (
    is => 'rw',
    isa => 'Str',
    default => 'https://api.flowdock.com'
);


has 'username' => (
    is => 'rw',
    isa => 'Str'
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;

    my $params = $self->$orig(@_);
    my $token = delete $params->{token};
    if ($token) {
        $params->{username} = $token;
        $params->{password} = '';
    }

    return $params;
};


sub get_flow {
    my $self = shift;
    my $args = shift;
    
    return $self->_client->get_flow(
        organization => $args->{organization},
        flow => $args->{flow}
    );
}


sub get_flows {
    my $self = shift;
    my $args = shift;
    
    return $self->_client->get_flows;
}


sub send_message {
    my $self = shift;
    my $args = shift;
    
    return $self->_client->send_message(
        organization => $args->{organization},
        flow => $args->{flow},
        event => $args->{event},
        content => $args->{content},
        tags => $args->{tags}
    );
}


sub push_team_inbox {
    my $self = shift;
    my $args = shift;
    
    return $self->_client->push_team_inbox(
        key => $self->key,
        source => $args->{source},
        from_address => $args->{from_address},
        from_name => $args->{from_name},
        subject => $args->{subject},
        content => $args->{content},
        project => $args->{project},
        format => $args->{format},
        tags => $args->{tags},
        link => $args->{link}
    );
}


sub push_chat {
    my $self = shift;
    my $args = shift;

    return $self->_client->push_chat(
        key => $self->key,
        content => $args->{content},
        external_user_name => $args->{external_user_name},
        tags => $args->{tags}
    );
}

1;

__END__
=pod

=head1 NAME

Net::Flowdock - Flowdock API

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Net::Flowdock;

    my $client = Net::Flowdock->new(key => 'find-your-own');

    # Or, if you need to use authenticated methods
    
    my $client = Net::Flowdock->new(key => 'find-your-own', username => 'foo', password => 'bar');

    $client->push_team_inbox({
        source => 'CPAN',
        from_address => 'gphat@cpan.org',
        from_name => 'Cory Watson',
        subject => 'Uploaded Net::Flowdock',
        content => "Sho' nuff",
        project => 'Open Source',
        tags => 'wow,yeah,poop',
        link => 'http://search.cpan.org'
    });

=head1 DESCRIPTION

Net::Flowdock is a simple client for using the L<Flowdock API|https://www.flowdock.com/api>.
It specifically speaks to the L<REST|https://www.flowdock.com/api/rest> and
L<Push|https://www.flowdock.com/api/push> APIs.

=head1 ATTRIBUTES

=head2 debug

Set/Get the debug flag.

=head2 key

Set/Get the key to use when connecting to Flowdock.

To obtain the API Token go to Settings -> Team Inbox inside a flow. 

=head2 password

Set/Get the password for authenticated request.

=head2 url

Set/Get the URL for Flowdock. Defaults to https://api.flowdock.com.

=head2 username

Set/Get the username for authenticated request.

=head1 METHODS

=head2 get_flow (organization => $org, flow => $flow)

Get a single flow. Single flow information always includes user list of flow. Otherwise the data format is identical to the list.

=head2 get_flows

Lists the flows that the authenticated user has access to.

=head2 send_message (organization => $org, flow => $flow, event => $event, content => $content, tags => $tags)

Send a messge to a flow.

=over 4

=item event

One of the valid Flowdock message events. Determines the type of message being sent to Flowdock. See Message Types section below. Required.

=item content

The actual message. The format of content depends on the event. Required. Types are message (normal chat), status, (status update), mail (team inbox).

item tags

List of tags to be added to the message. Can be either an array (JSON only) or a string with tags delimited with commas. User tags should start with '@'. Hashtags can optionally be prefixed with "#". Tags are case insensitive.

=back

Some examples:

A status update:

    $client->send_message({
        organization => 'iinteractive',
        flow => 'testing',
        event => 'status',
        content => 'Away for a bit',
    });

A message in chat:

    $client->send_message({
        organization => 'iinteractive',
        flow => 'testing',
        event => 'message',
        content => 'I am a robot',
        tags => 'foo, bar'
    });

XXX Todo: mail

=head2 push_team_inbox ({ source => $source, from_address => $email })

Required fields:

=over 4

=item source

Human readable identifier of the application that uses the Flowdock API. Only alphanumeric characters, underscores and whitespace can be used. This identifier will be used as the primary method of categorization for the messages. 

Example value: Awesome Issue Management App

=item from_address

Email address of the message sender. The email address is used to show a avatar of the sender. You can customize the avatar by registering the address in

Example value: john.doe@yourdomain.com

=item subject

Subject line of the message, will be displayed as the title of Team Inbox message.

=item content

Content of the message, will be displayed as the body of Team Inbox message. 

Following HTML tags can be used: a abbr acronym address article aside b big blockquote br caption cite code dd del details dfn div dl dt em figcaption figure footer h1 h2 h3 h4 h5 h6 header hgroup hr i img ins kbd li nav ol p pre samp section small span strong sub summary sup table tbody td tfoot th thead tr tt ul var wb

=back

Optional fields:

=over 4

=item from_name

Name of the message sender.

Example value: John Doe

=item project

Human readable identifier for more detailed message categorization. Only alphanumeric characters, underscores and whitespace can be used. This identifier will be used as the secondary method of categorization for the messages.

Example value: My Project

=item format

Format of the message content, default value is "html". Only HTML is currently supported. 

Example value: html

=item tags

Tags of the message, separated by commas.

Example value: cool,stuff

=item link

Link associated with the message. This will be used to link the message subject in Team Inbox.

Example value: http://www.flowdock.com/

=back

=head2 push_chat ({ content => $content, external_user_name => $username })

=over 4

=item content

Content of the message. Tags will be automatically parsed from the message content. Required.

=item external_user_name

Name of the "user" sending the message. Required.

=item tags

Tags of the message, separated by commas. Optional.

Example value: cool,stuff

=back

=head1 AUTHENTICATED

=head1 ANONYMOUS

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


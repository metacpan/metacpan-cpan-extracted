package OpenAIGPT4;

use strict;
use warnings;

our $VERSION = '0.18'; # Incremented version number

use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request::Common qw(POST);
use JSON;

=head1 NAME

OpenAIGPT4 - Interact with the OpenAI GPT-3,4 API

=head1 VERSION

Version 0.18

=head1 SYNOPSIS

    use OpenAIGPT4;

    my $gpt = OpenAIGPT4->new('<your_api_key>');

    print "ChatGPT: Hello! Let's start a conversation.\n";

    while (1) {
        print "User: ";
        my $user_input = <STDIN>;
        chomp $user_input;

        # Send the user's input to the API and receive a response
        my $response = $gpt->generate_text($user_input);

        # Display the response
        print "ChatGPT: $response\n";

        # Check for exit condition (e.g., input of the keyword "exit")
        if ($user_input eq 'exit') {
            last; # Exit the loop to end the conversation
        }
    }

=head1 DESCRIPTION

OpenAIGPT4 is a Perl module that enables developers to interface with the OpenAI GPT-3,4 API. With this module, you can easily generate natural language text. It also supports a debug flag to log HTTP request and response details.

=head1 METHODS

=head2 new

    my $gpt = OpenAIGPT4->new('<your_api_key>', 'http://open_ai_host_url', 1);

This constructor returns a new OpenAIGPT4 object. You must pass your OpenAI API key as the argument. The open ai host url is optional, and can be used for running against a LocalAI API server. The last parameter is the debug flag. If set to 1, the module will print HTTP request and response details to STDOUT.

=head2 generate_text

    my $response = $gpt->generate_text('Hello, how are you?', 'gpt-4');

This method generates text given a prompt. The first argument should be a string containing the prompt. The second argument is optional and can be used to specify the model to be used for the generation. If no model is specified, it defaults to 'gpt-3.5-turbo-0613'. It returns the generated text.

=head1 AUTHOR

Kawamura Shingo, <pannakoota@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2023 Kawamura Shingo.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

sub new {
    my ($class, $api_key, $api_host, $debug) = @_;

    my $self = {
        api_key => $api_key,
        ua      => LWP::UserAgent->new,
        api_host => $api_host // 'https://api.openai.com',
        history => [], # Keep track of conversation history
        debug   => $debug // 0, # Add debug flag
    };

    return bless $self, $class;
}

sub generate_text {
    my ($self, $prompt, $model, $temperature) = @_;

    $model //= 'gpt-3.5-turbo-0613';
    $temperature //= 0.7;

    push @{$self->{history}}, {role => 'user', content => $prompt};

    my $req = POST $self->{api_host}.'/v1/chat/completions',
        Content_Type => 'application/json',
        Content => to_json({
            model => $model,
            messages => $self->{history},
            temperature => $temperature,
        }),
        Authorization => 'Bearer ' . $self->{api_key};

    # Log request if debug flag is set
    if($self->{debug}){
        print "Request: ", $req->as_string, "\n";
    }

    my $res = $self->{ua}->request($req);

    # Log response if debug flag is set
    if($self->{debug}){
        print "Response: ", $res->as_string, "\n";
    }

    if ($res->is_success) {
        my $data = from_json($res->decoded_content);
        my $reply = $data->{choices}[0]{message}{content};

        # Add the model's reply to the conversation history
        push @{$self->{history}}, {role => 'system', content => $reply};

        return $reply;
    }
    else {
        my $error_message = $res->status_line;
        if ($res->content) {
            my $error_data = eval { from_json($res->content) };
            if ($@) {
                $error_message .= " Error decoding response body: $@";
            } else {
                $error_message .= " Response body: " . to_json($error_data);
            }
        }
        die $error_message;
    }
}
1;

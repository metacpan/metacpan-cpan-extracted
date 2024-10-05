#!/usr/bin/env perl

use 5.016;    # minimum version OpenAPI::Client supports
use strict;
use warnings;
use lib 'lib';
use OpenAPI::Client::OpenAI;
use Feature::Compat::Try;

my $model          = 'gpt-3.5-turbo';
my $system_message = { "role" => "system", "content" => "You are a friendly assistant, but you stutter." };
my @messages       = (
    # the system message is a prompt that tells the AI how to behave
    $system_message,
);

my $client = OpenAPI::Client::OpenAI->new;
print <<"END";
Welcome to the OpenAI chat client. You can chat with the AI by typing a
message and pressing Enter. Note that this version tends to stutter.

Type 'exit' or 'quit' to exit the chat (or just CTRL-C).
END

CHAT: while (1) {
    print "> ";
    chomp( my $query = <STDIN> );
    last CHAT if $query =~ /^exit|q(?:uit)$/i;
    push @messages, { "role" => "user", "content" => $query };
    my $response = $client->createChatCompletion( {
        body => {
            model       => $model,
            messages    => \@messages,
            temperature => .5,
        }
    } );
    if ( $response->res->is_success ) {
        try {
            my $message = $response->res->json->{choices}[0]{message};
            push @messages, $message;
            say $message->{content};
        } catch ($e) {
            die "Error decoding JSON: $e\n";
        }
    } else {
        die Dumper( $response->res );
    }
}

__END__

=head1 NAME

chat.pl - Chat with the OpenAI API

=head1 SYNOPSIS

    perl chat.pl

=head1 DESCRIPTION

This script allows you to chat with the OpenAI API using the `gpt-3.5-turbo`
model.  It remembers past messages so you can ask about previous messages.
Note that this is an example script. In reality, you might need to ensure you
don't keep too many messages in memory.

See also L<An OpenAI Chatbot in Perl|https://curtispoe.org/articles/an-openai-chatbot-in-perl.html>.

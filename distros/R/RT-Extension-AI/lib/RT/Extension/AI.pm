use strict;
use warnings;

package RT::Extension::AI;

our $VERSION = '0.06';

require RT::Extension::AI::Provider;
require RT::Extension::AI::Provider::OpenAI;
require RT::Extension::AI::Provider::Gemini;

RT->AddJavaScript('rt-extension-ai.js');
RT->AddJavaScript('ai-chat.js');
RT->AddStyleSheets('rt-extension-ai.css');

if ( RT->Config->can('RegisterPluginConfig') ) {
    RT->Config->RegisterPluginConfig(
        Plugin  => 'AI',
        Content => [
            {   Name => 'RT_AI_Provider',
                Help => 'Configuration options for adding AI providers to RT.',
            },
        ],
        Meta => {
            RT_AI_Provider       => { Type => 'HASH' },
        }
    );
}

=head2 GenerateTicketSummary

Generate a formatted summary of ticket conversations for AI processing. This function
extracts Create and Correspond transactions from a ticket and formats them using
XML-like tags similar to the context file format.

=cut

sub GenerateTicketSummary {
    my %args = @_;
    my $ticket = $args{TicketObj} or return '';
    my $type = $args{TransactionType} || 'Correspond';
    my $include_create = defined $args{IncludeCreate} ? $args{IncludeCreate} : 1;
    my $transaction_limit = 20; # Maximum number of transactions to include (excluding Create)

    # Get Create transaction separately if requested
    my $create_transaction = '';
    if ($include_create) {
        my $create_txns = $ticket->Transactions;
        $create_txns->Limit(FIELD => 'Type', VALUE => 'Create', OPERATOR => '=');
        $create_txns->OrderBy(FIELD => 'Created', ORDER => 'ASC');
        if (my $create_txn = $create_txns->First) {
            my $content = $create_txn->Content || '';
            $content = CleanTransactionContent($content);
            if ($content) {
                my $creator_id = $create_txn->CreatorObj->Id;
                my $creator = $create_txn->CreatorObj;
                my $privilege_type = $creator->Privileged ? 'Privileged' : 'Unprivileged';
                $create_transaction = sprintf "<InitialRequest user=\"User1\" privilege=\"%s\" sequence=\"1\">%s</InitialRequest>\n",
                    $privilege_type, $content;
            }
        }
    }

    # Get the most recent transactions of the specified type (limit 20)
    my $transactions = $ticket->Transactions;
    if ($type ne 'Create') {
        $transactions->Limit(FIELD => 'Type', VALUE => $type, OPERATOR => '=');
    } else {
        # If only Create is requested and already handled above, return early
        return $create_transaction;
    }
    $transactions->OrderBy(FIELD => 'Created', ORDER => 'DESC');
    $transactions->RowsPerPage($transaction_limit);

    # Collect transactions in reverse order (most recent first) then reverse for chronological
    my @txn_list = ();
    while (my $txn = $transactions->Next) {
        push @txn_list, $txn;
    }
    @txn_list = reverse @txn_list; # Now in chronological order (oldest first)

    my $conversation = '';
    my $sequence = $include_create ? 2 : 1; # Start at 2 if Create transaction exists

    # Track users for anonymization (reserve User1 for Create if it exists)
    my %user_map = ();
    my $user_counter = $include_create ? 2 : 1;

    for my $txn (@txn_list) {
        my $creator_id = $txn->CreatorObj->Id;
        my $creator = $txn->CreatorObj;
        my $content = $txn->Content || '';

        # Skip empty content
        next unless $content;

        # Create anonymous user mapping with privilege info
        unless (exists $user_map{$creator_id}) {
            my $privilege_type = $creator->Privileged ? 'Privileged' : 'Unprivileged';
            $user_map{$creator_id} = {
                name => "User$user_counter",
                privileged => $privilege_type
            };
            $user_counter++;
        }

        my $user_info = $user_map{$creator_id};

        # Clean up the content (remove RT's standard headers, etc.)
        $content = CleanTransactionContent($content);

        if ($content) {
            $conversation .= sprintf "<Message user=\"%s\" privilege=\"%s\" sequence=\"%d\">%s</Message>\n",
                $user_info->{name},
                $user_info->{privileged},
                $sequence,
                $content;
            $sequence++;
        }
    }

    return $create_transaction . $conversation;
}

=head2 CleanTransactionContent

Clean up transaction content by removing RT email headers, signatures, and excessive
whitespace. Also escapes XML characters for safe inclusion in XML output.

=cut

sub CleanTransactionContent {
    my $content = shift;
    return '' unless $content;

    # Remove common RT email headers and signatures
    $content =~ s/^>.*$//gm;  # Remove quoted lines starting with >
    $content =~ s/^On.*wrote:.*$//gm;  # Remove "On ... wrote:" lines
    $content =~ s/^\s*--\s*\n.*$//ms;  # Remove signature blocks starting with --

    # Remove excessive whitespace
    $content =~ s/\n\s*\n/\n\n/g;  # Normalize multiple blank lines to double newlines
    $content =~ s/^\s+//;  # Remove leading whitespace
    $content =~ s/\s+$//;  # Remove trailing whitespace

    # Escape XML characters
    $content =~ s/&/&amp;/g;
    $content =~ s/</&lt;/g;
    $content =~ s/>/&gt;/g;

    return $content;
}

=head2 LoadContextFile

Load and return the contents of a context file for AI processing. This function
searches for relevant context files in the configured directory and returns
the content for inclusion in AI API requests.

=cut

sub LoadContextFile {
    my %args = @_;
    my $config = $args{config} || {};
    my $queue = $args{queue} || 'Default';
    my $ticket_id = $args{ticket_id};

    # Check if context files are enabled
    return undef unless $config->{use_context_files};
    return undef unless $config->{context_file_path};

    my $context_dir = $config->{context_file_path};

    # Ensure the directory exists
    unless (-d $context_dir) {
        RT->Logger->debug("Context file directory does not exist: $context_dir");
        return undef;
    }

    # Look for context files in the directory
    # Priority order: queue-specific files, then general files
    my @potential_files = ();

    if (opendir(my $dh, $context_dir)) {
        my @files = grep { /\.txt$|\.xml$/ && -f "$context_dir/$_" } readdir($dh);
        closedir($dh);

        # Sort files by modification time (newest first)
        @files = sort {
            (stat("$context_dir/$b"))[9] <=> (stat("$context_dir/$a"))[9]
        } @files;

        # Prefer queue-specific files if available
        for my $file (@files) {
            if ($file =~ /\Q$queue\E/i) {
                unshift @potential_files, $file;
            } else {
                push @potential_files, $file;
            }
        }
    } else {
        RT->Logger->error("Cannot read context file directory: $context_dir");
        return undef;
    }

    # Try to load the most suitable context file
    for my $filename (@potential_files) {
        my $filepath = "$context_dir/$filename";

        if (open(my $fh, '<:encoding(UTF-8)', $filepath)) {
            my $content = do { local $/; <$fh> };
            close($fh);

            if ($content && length($content) > 0) {
                RT->Logger->debug("Loaded context file: $filename");
                return $content;
            }
        } else {
            RT->Logger->debug("Cannot read context file: $filepath");
        }
    }

    RT->Logger->debug("No suitable context file found in: $context_dir");
    return undef;
}

=head1 NAME

RT-Extension-AI - Add various AI Features to Request Tracker

=head1 DESCRIPTION

This RT extension introduces various AI-powered features to RT. AI assistance is
added via scrips and also interactively through the RT editor.

=head1 RT VERSION

Works with RT 6.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::AI');

See below for additional configuration details.

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

An example configuration file is provided in C<etc/RT_AI_Config.pm>. The
configuration defines both the details of the service you want to connect to
and details of the specific features, like prompts for different features.

Here is a sample configuration with Gemini:

    Set( %RT_AI_Provider,
          'Default' => {
             name    => 'Gemini',
             api_key => 'YOUR_API_KEY',
             timeout => 15,
             url     => 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
             prompts => {
                summarize_ticket => 'You are a helpdesk assistant. Summarize the ticket conversation precisely. Focus on key points, decisions made, and any follow-up actions required.',
                assess_sentiment => 'Classify the overall sentiment as Satisfied, Dissatisfied, or Neutral. Provide reasoning if possible.',
                adjust_tone => 'Paraphrase the text for clarity and professionalism. Ensure the tone is polite, concise, and customer-friendly.',
                suggest_response => 'Provide clear, practical advice or suggestions based on the given question or scenario.',
                translate_content => 'Translate the provided text, maintaining accuracy and idiomatic expressions.',
                autocomplete_text => 'Predict the next three words based on the input text without explanations.',
             },
             editor_features => [ 'adjust_tone', 'suggest_response', 'translate_content', 'autocomplete_text' ],
             queue_creation_assistant => 1,  # Set to 0 to disable the AI queue creation assistant
             use_context_files => 0,  # Set to 1 to enable context file usage for suggest_response
             context_file_path => "$RT::EtcPath/ai/context",  # Directory containing context files
             suggest_response_context_prompt => "Here are examples of similar previous conversations for context:",  # Text that introduces the context
          },
    );

Below shows a sample configuration with OpenAI:

    Set( %RT_AI_Provider,
          'Default' => {
            name    => 'OpenAI',
            api_key => 'YOUR_API_KEY',
            timeout => 15,
            url     => 'https://api.openai.com/v1/chat/completions',
            default_model => {
                name        => 'gpt-4',
                max_tokens  => 300,
                temperature => 0.5,
            },
            autocomplete_model => {
                name        => 'gpt-3.5-turbo',
                max_tokens  => 20,
                temperature => 0.7,
            },
            prompts => {
                summarize_ticket => 'You are a helpdesk assistant. Summarize the ticket conversation precisely. Focus on key points, decisions made, and any follow-up actions required.',
                assess_sentiment => 'Classify the overall sentiment as Satisfied, Dissatisfied, or Neutral. Provide reasoning if possible.',
                adjust_tone => 'Paraphrase the text for clarity and professionalism. Ensure the tone is polite, concise, and customer-friendly.',
                suggest_response => 'Provide clear, practical advice or suggestions based on the given question or scenario.',
                translate_content => 'Translate the provided text, maintaining accuracy and idiomatic expressions.',
                autocomplete_text => 'Predict the next three words based on the input text without explanations.',
            },
            editor_features => [ 'adjust_tone', 'suggest_response', 'translate_content', 'autocomplete_text' ],
            queue_creation_assistant => 1,  # Set to 0 to disable the AI queue creation assistant
            use_context_files => 0,  # Set to 1 to enable context file usage for suggest_response
            context_file_path => "$RT::EtcPath/ai/context",  # Directory containing context files
            suggest_response_context_prompt => "Context: The following are complete conversation histories from similar resolved support tickets. Use these examples to understand typical issue patterns, effective troubleshooting approaches, and professional response tone. Each <Ticket> contains chronological messages between users (customers/requesters) and support staff (privileged users). Apply these patterns to craft an appropriate response:",  # Text that introduces the context
          },
    );

=head2 Global and Queue-specific Configuration

The block of configuration defined for the "Default" key, as shown above, is used
as the default global settings for your RT. You can define per-queue configuration
by adding sections with queue names as keys. In any context where RT can associate
the AI action with a ticket or queue, it will load the matching queue
configuration, if available.

Some features, like the editor autocomplete, may call the AI service many times. To
limit AI features to selected queues only, do not provide a C<Default> configuration
and only add configuration for the queues you want. The AI menu in the editor
will only appear for configured queues and autocomplete will also run only for
configured queues.

=head2 Using Different AI Providers

This extension is designed to work with any AI provider with a REST API. The
features currently all use the conversation AI feature. To interface with
a system, you need the REST API URL for the conversation endpoint.

Authentication can be different for different providers and may require some
custom coding. Most require a token as indicated in the configuration.
We have tested with the following providers.

=over

=item *

OpenAPI, URL: https://api.openai.com/v1/chat/completions

=item *

Gemini, URL: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent

=back

=head2 Models

Some API providers have different models that are optimized for different tasks.
Currently most AI features use the general model. The autocomplete feature,
however, requires fast responses, so we provide a way to set a different model
for that feature. ChatGPT, for example, has a turbo model that is optimized for
speed and makes the autocomplete work much better.

=head2 Prompts

You can define different prompts for different AI features. The keys in the
prompts section describe what they are used for. These prompts are sent with
every request to the AI for the defined feature. You will likely need to
experiment with your selected AI to find wording that correctly processes the
prompt along with the content sent in each request.

=head2 Context Files

The AI response suggestion feature can optionally use context files generated by the
C<rt-build-context-files> utility. These files contain structured conversation data
from similar tickets to help the AI generate more contextually appropriate responses.

To enable context file usage:

    use_context_files => 1,
    context_file_path => "$RT::EtcPath/ai/context",
    suggest_response_context_prompt => "Context: The following are complete conversation histories from similar resolved support tickets. Use these examples to understand typical issue patterns, effective troubleshooting approaches, and professional response tone. Each <Ticket> contains chronological messages between users (customers/requesters) and support staff (privileged users). Apply these patterns to craft an appropriate response:",

When enabled, the C<suggest_response> feature will look for relevant context files
in the specified directory and include that information in AI requests to improve
response quality. The C<suggest_response_context_prompt> setting allows you to customize the
introductory text that explains the context to the AI for suggest_response requests.

=head2 Queue Creation Assistant

To enable the queue creation assistant, add the following to your provider
configuration:

    queue_creation_assistant => 1,

See L</Queue Creation Assistant> under FEATURES below for details.

=head2 CKEditor Integration

Some AI features are integrated into RT's editor and are accessible via
buttons in the editor toolbar. To load the editor features, some additional
configuration is needed. It is provided in the sample C<etc/RT_AI_Config.pm>
file and should be loaded automatically when you enable the extension. If
you don't see the AI button, you can copy the configuration into your local
site configuration.

The AI Suggestion feature works directly within the editor, inserting responses
at the end of existing content rather than replacing it. This allows users to
quote parts of incoming messages and have AI suggestions appended appropriately.

=head1 FEATURES

=head2 Scrips

The following scrips are provided to update information on tickets
when configured with whatever conditions you prefer. The sample scrips are
configured with "On Correspond" conditions. These are just
examples and you can use the actions in any new scrips you want to create.

These scrips are applied globally as part of the installation. If you are just
testing, you may want to update the scrips and limit them to just one queue.

=over

=item On Correspond Summarize Ticket History

=item On Correspond Assess Reply Sentiment

=back

=head3 Scrip Actions

The actions below are included with the extension and can be used with
any conditions to create scrips that make sense for your system.

=over

=item Analyze Ticket Sentiment

Content from the ticket is sent to the AI provider and analyzed to assess
the sentiment of the end user. Responses are Satisfied, Dissatisfied, or Neutral
and the value is saved in the "Ticket Summary" custom field on the ticket.

=item Generate Ticket Summary

Content from the ticket is sent to the AI provider and a concise summary is
requested. The result is saved in the "Ticket Sentiment" custom field on the ticket.

=back

=head2 Editor Features

The following features are available in RT's editor.

=over

=item Autocomplete

As you type, suggestions are provided for the next few words. The behavior of
the suggestions can be modified with the prompt.

=item Adjust Tone

You can submit a block of text to your AI provider and ask it to change the
tone to something different.

=item AI Suggestion

Your AI provider can suggest a response to the current question on the ticket.
The AI response is inserted directly into the editor at the end of any existing
content, preserving paragraph structure and newlines.

=item Translate

Translate the provided content from the current language to another selected
language.

=back

=head2 Queue Creation Assistant

An interactive chat interface under Admin > Queues > Create with AI that
guides administrators through setting up a new queue. Through a multi-turn
conversation, the AI gathers workflow details and generates a complete
configuration including a custom lifecycle, queue, groups, custom fields, ACL
rights, and queue watchers. The admin reviews a summary of the proposed
configuration and creates all objects with a single click. See
L</Queue Creation Assistant> above for configuration details.

=head1 DEVELOPER

=head2 CKEditor Plugin RtExtensionAi

A new custom CKEditor plugin RtExtensionAi provides the AI integration with the
RT editor.

=head2 Updating the plugin

The plugin uses Vite to build the assets loaded into RT. Information on working
with CKEditor plugins can be found on the L<CKEditor website|https://ckeditor.com/docs/ckeditor5/latest/framework/tutorials/creating-simple-plugin-timestamp.html>.

We use Vite to build the CKEditor plugin.

    npm install
    npm run build

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head2 Initial Prototype

Parag Shah E<lt>paragsha@buffalo.eduE<gt>

Neel Patel E<lt>neelvish@buffalo.eduE<gt>

Abhinandan Vijan E<lt>abhinandanvijan98@gmail.comE<gt>

Ayush Goel E<lt>ayushgoe@buffalo.eduE<gt>

Shivan Mathur E<lt>shivanmthr18@gmail.comE<gt>

=head1 BUGS

All bugs should be reported via email to: L<bug-RT-Extension-AI@rt.cpan.org|mailto:bug-RT-Extension-AI@rt.cpan.org>

Or via the web at: L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-AI>.

=head1 COPYRIGHT

This extension is Copyright (C) 2013-2026 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

=head2 LoadQueueCreationPrompt

Load the system prompt for the queue creation assistant from
F<etc/ai/prompts/create-queue.md>. Searches the local etc directory,
the default etc directory, and installed plugin paths.

=cut

sub LoadQueueCreationPrompt {
    my @search_paths = (
        "$RT::LocalEtcPath/ai/prompts/create-queue.md",
        "$RT::EtcPath/ai/prompts/create-queue.md",
    );

    # Also check plugin paths
    my @plugins = RT->Config->Get('Plugins');
    for my $plugin ( @plugins ) {
        next unless $plugin =~ /AI/;
        my $dir = RT->Config->Get('PluginPath') || '';
        if ( $dir ) {
            push @search_paths, "$dir/$plugin/etc/ai/prompts/create-queue.md";
        }
    }

    # Check installed plugin location
    push @search_paths, map {
        "$_/etc/ai/prompts/create-queue.md"
    } RT->PluginDirs('');

    for my $path ( @search_paths ) {
        if ( -f $path && open( my $fh, '<:encoding(UTF-8)', $path ) ) {
            my $content = do { local $/; <$fh> };
            close $fh;
            RT->Logger->debug("Loaded queue creation prompt from $path");
            return $content;
        }
    }

    RT->Logger->error("Could not find queue creation prompt (create-queue.md) in any search path");
    return undef;
}

1;

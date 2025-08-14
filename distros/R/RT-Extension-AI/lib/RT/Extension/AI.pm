use strict;
use warnings;

package RT::Extension::AI;

our $VERSION = '0.05';

require RT::Extension::AI::Provider;
require RT::Extension::AI::Provider::OpenAI;
require RT::Extension::AI::Provider::Gemini;

RT->AddJavaScript('rt-extension-ai.js');
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

=head2 CKEditor Integration

Some AI features are integrated into RT's editor and are accessible via
buttons in the editor toolbar. To load the editor features, some additional
configuration is needed. It is provided in the sample C<etc/RT_AI_Config.pm>
file and should be loaded automatically when you enable the extension. If
you don't see the AI button, you can copy the configuration into your local
site configuration.

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

=item Translate

Translate the provided content from the current language to another selected
language.

=back

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

This extension is Copyright (C) 2013-2025 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;

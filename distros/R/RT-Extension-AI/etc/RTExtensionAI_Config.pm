=pod

Copy the configuration below to your RT configuration file and update
at least the name and api_key.

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
            generate_ticketsql => 'You are an expert in Request Tracker (RT) search. Given a natural language description, generate a TicketSQL query to find tickets. If the request references desired columns in the output, also generate a Format string to display the results appropriately. Use the provided TicketSQL and Format grammar references to ensure correctness. Consider what columns would be most useful to display based on the user request.',
         },
         editor_features => [ 'adjust_tone', 'suggest_response', 'translate_content', 'autocomplete_text' ],
         queue_creation_assistant => 0,  # Set to 1 to enable the AI queue creation assistant under Admin > Queues
         use_context_files => 0,  # Set to 1 to enable context file usage for suggest_response
         context_file_path => "$RT::EtcPath/ai/context",  # Directory containing context files
         suggest_response_context_prompt => "Context: The following are conversation histories from similar support tickets. Use these examples to understand typical support ticket patterns, effective troubleshooting approaches, ways to ask for more information, and the standard corporate tone and voice. Each <Ticket> contains chronological messages between end users (customers/requesters) and support staff (privileged users). Apply these patterns to craft an appropriate response:",  # Text that introduces the context for suggest_response
      },
);

=cut

my $messageBoxRichTextInitArguments
    = RT->Config->Get('MessageBoxRichTextInitArguments');

$messageBoxRichTextInitArguments->{extraPlugins} //= [];
push @{ $messageBoxRichTextInitArguments->{extraPlugins} }, 'RtExtensionAi';

# Add 'aiSuggestion' to the toolbar before sourceEditing
my @temp_toolbar;
foreach my $item (
    @{  ref $messageBoxRichTextInitArguments->{toolbar} eq 'HASH'
        ? $messageBoxRichTextInitArguments->{toolbar}{items}
        : $messageBoxRichTextInitArguments->{toolbar}
     }
    )
{
    if ( $item eq 'sourceEditing' ) {
        push @temp_toolbar, 'aiSuggestion', 'sourceEditing';
    }
    else {
        push @temp_toolbar, $item;
    }
}

if ( ref $messageBoxRichTextInitArguments->{toolbar} eq 'HASH' ) {
    @{$messageBoxRichTextInitArguments->{toolbar}{items}} = @temp_toolbar;
}
else {
    @{$messageBoxRichTextInitArguments->{toolbar}} = @temp_toolbar;
}

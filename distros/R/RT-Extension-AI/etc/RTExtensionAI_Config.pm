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
         },
         editor_features => [ 'adjust_tone', 'suggest_response', 'translate_content', 'autocomplete_text' ],
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

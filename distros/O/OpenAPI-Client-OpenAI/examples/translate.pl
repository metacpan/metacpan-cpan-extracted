#!/usr/bin/env perl

use 5.016;    # minimum version OpenAPI::Client supports
use lib 'lib';
use experimental qw( signatures );
use Data::Dumper;
use OpenAPI::Client::OpenAI;
use Feature::Compat::Try;
use Text::CSV_XS qw( csv );
use Term::ProgressBar;

sub get_rows ( $csv, $filename ) {
    open my $in_fh, "<:encoding(utf8)", $filename or die "Can't open $filename for reading: $!";
    my $aoa = $csv->getline_all($in_fh);
    close $in_fh;
    return $aoa;
}

sub to_csv ( $csv, $row ) {
    $csv->combine(@$row);
    return $csv->string;
}

sub translate (%arg_for) {
    my $client    = $arg_for{client};
    my $from_lang = $arg_for{from};
    my $to_lang   = $arg_for{to};
    my $text      = $arg_for{text};
    state $total_tokens   = 0;
    state $total_requests = 0;
    $total_requests++;

    # This method defaults to 16 max tokens. gpt-3.5-turbo-instruct has a
    # context size of 4097 tokens. However, the prompt is 1814 tokens (more
    # is presumably the system prompt), so I need to choose max tokens low
    # enough to avoid the error:
    #
    #     "This model's maximum context length is 4097 tokens, however you
    #     requested 5911 tokens (1814 in your prompt; 4097 for the completion).
    #     Please reduce your prompt; or completion length."
    #
    # For my use case, 2200 tokens is around 1,600 words, which is plenty. If
    # you need to translate more, you may need to considering chunking the
    # text, but be aware that you can easily lose the text's context.
    my $max_tokens = 2200;

    # this method also accepts Davinci-002 and Babbage-002. Babbage-002 and
    # Davinci-002 have a 16K context size, but they're base-models and need
    # to be fine-tuned. gpt-3.5-turbo-instruct only has a 4K context size, but
    # can be used out of the box and is good enough for this use case.
    my $model = 'gpt-3.5-turbo-instruct';

    # yup, I need to figure out a cleaner way to do this
    my $response = $client->createCompletion( {
        body => {
            model       => $model,
            prompt      => "Translate the following text from $from_lang to $to_lang:\n\n$text",
            temperature => 0,             # be as accurate as possible
            max_tokens  => $max_tokens,
        }
    } );
    my $result = $response->result;
    if ( $result->is_success ) {
        try {
            my $json    = $result->json;
            my $message = trim( $json->{choices}[0]{text} );
            my $headers = $result->headers;

            # we're not actually using this here, but it's good to know.
            my $limit_requests     = $headers->header('x-ratelimit-limit-requests');
            my $limit_tokens       = $headers->header('x-ratelimit-limit-tokens');
            my $remaining_requests = $headers->header('x-ratelimit-remaining-requests');
            my $remaining_tokens   = $headers->header('x-ratelimit-remaining-tokens');
            my $reset_requests     = $headers->header('x-ratelimit-reset-requests');
            my $reset_tokens       = $headers->header('x-ratelimit-reset-tokens');
            $total_tokens += $json->{usage}{total_tokens};

            #print <<~"END";
            #Request number     : $total_requests
            #Response           : $message
            #Total tokens       : $total_tokens
            #Limit requests     : $limit_requests
            #Limit tokens       : $limit_tokens
            #Remaining requests : $remaining_requests
            #Remaining tokens   : $remaining_tokens
            #Reset requests     : $reset_requests
            #Reset tokens       : $reset_tokens
            #END
            return ( $message, $total_tokens );
        } catch ($e) {
            die "Error decoding JSON: $e\n";
        }
    } else {
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Sortkeys = 1;
        die Dumper( $response->res );
    }
}

sub trim($text) {
    $text =~ s/^\s+|\s+$//g;
    return $text;
}

my $client = OpenAPI::Client::OpenAI->new;
my $csv    = Text::CSV_XS->new( { binary => 1, auto_diag => 1 } );
my $aoa    = get_rows( $csv, 'in.csv' );

open my $out_fh, ">:encoding(utf8)", 'out.csv' or die "Can't open out.csv for writing: $!";

my $num_rows = @$aoa;

# ETA was useless. It kept saying about 20 minutes, but it took 5 hours for my data.
my $progress = Term::ProgressBar->new( { name => 'Rows', count => $num_rows, ETA => 'linear' } );
say {$out_fh} to_csv( $csv, shift @$aoa );    # headers
my $count = 0;

my %seen;                                     # we don't want to re-translate the same phrase (saves time and money)
my $seen_count   = 0;
my $total_count  = 0;
my $total_tokens = 0;
foreach my $row (@$aoa) {
    $progress->update( $count++ );
    $total_count += 2;
    my $title       = $row->[2];
    my $description = $row->[3];

    if ( !$seen{$title} ) {
        ( $row->[2], $total_tokens )
            = translate( client => $client, text => $title, from => "German", to => "English" );
        $seen{$title} = $row->[2];
        $seen_count++;
    } else {
        $row->[2] = $seen{$title};
    }
    if ( !$seen{$description} ) {
        ( $row->[3], $total_tokens )
            = translate( client => $client, text => $title, from => "German", to => "English" );
        $seen{$description} = $row->[3];
        $seen_count++;
    } else {
        $row->[3] = $seen{$description};
    }
    my $csv_row = $csv->combine(@$row);
    say {$out_fh} $csv->string;
}
$progress->update($num_rows);
say "Translated $seen_count unique phrases out of $total_count total phrases. Total tokens used: $total_tokens";

__END__

=head1 NAME

translate.pl - Translate a CSV file from German to English

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

B<Note>: You should read this code because without the sample CSV file, it
won't work.

This is real code I wrote to solve a problem for a client. They provided
access to their data to a graduate student who as working with a vector
database to analyze a bunch of the company data for his thesis. There was no
guarantee that the database would be useful for the client, but they asked me
if it would make a good replacement for their search system.

I received a CSV file with about 14,000 sample rows and put them into the
ChromaDB vector database and wrote some python code, using the student's code,
to issue queries. However, the results were in German and I couldn't
understand them. I wrote this code to translate the results from German to
English so I could understand them.

The code uses the OpenAI API to translate the text. For the volume of data I
was translating, it would have taken a professional translator weeks to do the
work at a cost of tens of thousands of dollars. The OpenAI API did the work in
five hours at a cost of $3.89. I spot-checked the results and they were pretty
good. I didn't need perfect translations, just enough to understand the data.

Note that my solution is not perfect. It was a quick hack to get the job done.
If you want to use this code, you'll need to adjust it for your needs.

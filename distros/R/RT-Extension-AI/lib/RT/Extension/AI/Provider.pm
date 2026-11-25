package RT::Extension::AI::Provider;

use strict;
use warnings;
use LWP::UserAgent;
use Time::HiRes qw(gettimeofday tv_interval);

sub default_headers {
    my ( $class, $config ) = @_;
    return {
        'Authorization' => "Bearer $config->{api_key}",
        'Content-Type'  => 'application/json'
    };
}

=head2 new config => %config

Accepts a hash that is the main AI config for the current queue.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $config = $args{config};

    unless ( $config->{url} ) {
        RT->Logger->error("Missing $class API URL");
        return;
    }
    unless ( $config->{api_key} ) {
        RT->Logger->error("Missing $class API key");
        return;
    }

    $config->{ua} = $class->create_user_agent(
        timeout => $config->{timeout},
        headers => $class->default_headers($config)
    );

    $config->{api_url} = $config->{url};

    return bless $config, $class;
}

=head2 process_request prompt => $prompt, raw_text => $text, model_config => \%model, feature => $name

Sends a request to the AI provider and returns a hashref with C<success>
and either C<result> (the text returned by the model) or C<error>. C<raw>
contains the decoded response from the provider.

C<feature> is optional and names the RT feature making the request, such as
C<summarize_ticket>. It is used only for logging.

This method times the request and logs the provider, model, feature,
outcome, elapsed time and token usage (when the provider reports it). The
prompt, the text sent and the response are not logged. Providers implement
the request itself in L</_process_request>.

=cut

sub process_request {
    my ( $self, %args ) = @_;

    my $start      = [gettimeofday];
    my $response   = eval { $self->_process_request(%args) };
    my $error      = $@;
    my $elapsed_ms = int( tv_interval($start) * 1000 );

    my $provider = ref $self;
    $provider =~ s/^RT::Extension::AI::Provider:://;

    my $model   = $args{model_config} && $args{model_config}{name};
    my $feature = $args{feature};
    $feature =~ s/[^\w-]//g if defined $feature;

    my @details = (
        "provider=$provider",
        "model=" . ( defined $model && length $model ? $model : 'unknown' ),
        "feature=" . ( defined $feature && length $feature ? $feature : 'unknown' ),
        "elapsed_ms=$elapsed_ms",
    );

    if ($error) {
        ( my $message = "$error" ) =~ s/[\r\n]+/ /g;
        $message =~ s/\s+$//;
        RT->Logger->warning("AI request died: @details error=\"$message\"");
        die $error;
    }

    if ( $response && $response->{success} ) {
        my $usage = $self->_usage( $response->{raw} ) || {};
        push @details, "input_tokens=$usage->{input_tokens}"
            if defined $usage->{input_tokens};
        push @details, "output_tokens=$usage->{output_tokens}"
            if defined $usage->{output_tokens};
        RT->Logger->info("AI request succeeded: @details");
    }
    else {
        my $message = ( $response && $response->{error} ) || 'Unknown error';
        $message =~ s/[\r\n]+/ /g;
        RT->Logger->warning("AI request failed: @details error=\"$message\"");
    }

    return $response;
}

=head2 _process_request %args

Providers must implement this method. It receives the same arguments as
L</process_request>, sends the request and returns the response hashref
described there.

=cut

sub _process_request {
    die "Method '_process_request' not implemented in the provider";
}

=head2 _usage $raw

Providers can implement this method to report token usage. It receives the
C<raw> value from a successful response and returns a hashref with
C<input_tokens> and C<output_tokens>. Either may be left out if the provider
does not report it. The default returns an empty hashref.

=cut

sub _usage {
    return {};
}

sub create_user_agent {
    my $self = shift;
    my (%args) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->timeout($args{timeout} // 10);
    $ua->env_proxy;

    if ( $args{headers} ) {
        foreach my $header ( keys %{ $args{headers} } ) {
            $ua->default_header( $header => $args{headers}{$header} );
        }
    }

    return $ua;
}

1;

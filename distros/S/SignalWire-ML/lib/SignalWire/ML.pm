package SignalWire::ML;

use strict;
use warnings;
use JSON;
use YAML::PP qw( Dump );

our $VERSION = '1.22';

sub new {
    my ($class, $args) = @_;
    my $self = {
        _content => {
            version => $args->{version} // '1.0.0',
        },
        _prompt => {},
        _params => {},
        _hints => [],
        _SWAIG => {
            defaults => {},
            functions => [],
            includes => [],
            native_functions => [],
        },
        _pronounce => [],
        _languages => [],
        _post_prompt => {},
    };
    return bless($self, $class);
}

sub add_aiapplication {
    my ($self, $section) = @_;
    my $app = "ai";
    my $args = {};

    for my $data (qw(post_prompt post_prompt_url post_prompt_auth_user post_prompt_auth_password languages hints params prompt SWAIG pronounce global_data)) {
        $args->{$data} = $self->{"_$data"} if exists $self->{"_$data"};
    }

    push @{$self->{_content}{sections}{$section}}, { $app => $args };
}

sub set_context_steps {
    my ($self, $context_name, $steps) = @_;
    $self->{_prompt}{contexts}{$context_name}{steps} = $steps;
}

sub add_context_steps {
    my ($self, $context_name, $steps) = @_;
    push @{$self->{_prompt}{contexts}{$context_name}{steps}}, @$steps;
}

sub set_prompt_contexts {
    my ($self, $contexts) = @_;
    $self->{_prompt}{contexts} = $contexts;
}

sub add_application {
    my ($self, $section, $app, $args) = @_;
    $args //= {};
    push @{$self->{_content}{sections}{$section}}, { $app => $args };
}

sub set_aipost_prompt_url {
    my ($self, $postprompt) = @_;
    while (my ($k, $v) = each %$postprompt) {
        $self->{"_$k"} = $v;
    }
}

sub set_global_data {
    my ($self, $data) = @_;
    $self->{_global_data} = $data;
}

sub set_aiparams {
    my ($self, $params) = @_;
    $self->{_params} = $params;
}

sub add_aiparams {
    my ($self, $params) = @_;
    my @numeric_keys = qw(end_of_speech_timeout attention_timeout outbound_attention_timeout background_file_loops background_file_volume digit_timeout energy_level);

    while (my ($k, $v) = each %$params) {
        if (grep { $_ eq $k } @numeric_keys) {
            $self->{_params}{$k} = defined $v ? $v + 0 : 0;
        } else {
            $self->{_params}{$k} = $v;
        }
    }
}

sub set_aihints {
    my ($self, @hints) = @_;
    $self->{_hints} = \@hints;
}

sub add_aihints {
    my ($self, @hints) = @_;
    my %seen;
    push @{$self->{_hints}}, @hints;
    @{$self->{_hints}} = grep { !$seen{$_}++ } @{$self->{_hints}};
}

sub add_aiswaigdefaults {
    my ($self, $SWAIG) = @_;
    while (my ($k, $v) = each %$SWAIG) {
        $self->{_SWAIG}{defaults}{$k} = $v;
    }
}

sub add_aiswaigfunction {
    my ($self, $SWAIG) = @_;
    push @{$self->{_SWAIG}{functions}}, $SWAIG;
}

sub set_aipronounce {
    my ($self, $pronounce) = @_;
    $self->{_pronounce} = $pronounce;
}

sub add_aipronounce {
    my ($self, $pronounce) = @_;
    push @{$self->{_pronounce}}, $pronounce;
}

sub set_ailanguage {
    my ($self, $language) = @_;
    $self->{_languages} = $language;
}

sub add_ailanguage {
    my ($self, $language) = @_;
    push @{$self->{_languages}}, $language;
}

sub add_aiinclude {
    my ($self, $include) = @_;
    push @{$self->{_SWAIG}{includes}}, $include;
}

sub add_ainativefunction {
    my ($self, $native) = @_;
    push @{$self->{_SWAIG}{native_functions}}, $native;
}

sub set_aipost_prompt {
    my ($self, $postprompt) = @_;
    my @numeric_keys = qw(confidence barge_confidence top_p temperature frequency_penalty presence_penalty);

    while (my ($k, $v) = each %$postprompt) {
        if (grep { $_ eq $k } @numeric_keys) {
            $self->{_post_prompt}{$k} = defined $v ? $v + 0 : 0;
        } else {
            $self->{_post_prompt}{$k} = $v;
        }
    }
}

sub set_aiprompt {
    my ($self, $prompt) = @_;
    my @numeric_keys = qw(confidence barge_confidence top_p temperature frequency_penalty presence_penalty);

    while (my ($k, $v) = each %$prompt) {
        if (grep { $_ eq $k } @numeric_keys) {
            $self->{_prompt}{$k} = defined $v ? $v + 0 : 0;
        } else {
            $self->{_prompt}{$k} = $v;
        }
    }
}

sub swaig_response {
    my ($self, $response) = @_;
    return $response;
}

sub swaig_response_json {
    my ($self, $response) = @_;
    return JSON->new->pretty->utf8->encode($response);
}

sub render {
    my ($self) = @_;
    return $self->{_content};
}

sub render_json {
    my ($self) = @_;
    return JSON->new->pretty->utf8->encode($self->{_content});
}

sub render_yaml {
    my ($self) = @_;
    return Dump $self->{_content};
}

1;

__END__

=encoding utf8

=head1 NAME

SignalWire::ML - Light and fast SWML generator

=head1 METHODS

=head2 new($class, $args)

Constructor method. Creates a new SignalWire::ML object with default values.

=head2 Example

Here's an example of how to use SignalWire::ML:

    use SignalWire::ML;

    # Create a new SignalWire::ML object
    my $ml = SignalWire::ML->new({
        version => '1.0.0'
    });

    # Set AI prompt
    $ml->set_aiprompt({
        text => "What's the weather like today?",
        temperature => 0.7,
        top_p => 0.9
    });

    # Set AI parameters
    $ml->set_aiparams({
        max_tokens => 150
    });

    # Add an AI application to a section
    $ml->add_aiapplication('main');

    # Render the result
    my $json_output = $ml->render_json();
    print $json_output;

This example demonstrates creating a SignalWire::ML object, setting various parameters and contexts, adding applications, and then rendering the result as JSON.


=head2 add_aiapplication($self, $section)

Adds an AI application to the specified section.

=head2 set_context_steps($self, $context_name, $steps)

Sets the steps for a specific context in the prompt.

=head2 add_context_steps($self, $context_name, $steps)

Adds steps to an existing context in the prompt.

=head2 set_prompt_contexts($self, $contexts)

Sets the contexts for the prompt.

=head2 add_application($self, $section, $app, $args)

Adds an application to the specified section with given arguments.

This method is used to add an application to a specific section in the SignalWire::ML object. 

Example usage:

    my $swml = SignalWire::ML->new({version => '1.0.0'});
    
    $swml->add_application("main", "answer");
    
    $swml->add_application("main", "play",
        { urls => [ "https://github.com/freeswitch/freeswitch-sounds/raw/master/en/us/callie/ivr/48000/ivr-welcome_to_freeswitch.wav" ] });
    
    $swml->add_application("main", "hangup");
    
    $swml->add_aiapplication('main');
    
    print $swml->render_json;

This example demonstrates creating a SignalWire::ML object, adding various applications including an answer, play, and hangup application, then adding an AI application to the 'main' section, and finally rendering the result as JSON.

=head2 set_aipost_prompt_url($self, $postprompt)

Sets the AI post-prompt URL and related parameters.

=head2 set_global_data($self, $data)

Sets the global data for the ML object.

=head2 set_aiparams($self, $params)

Sets the AI parameters.

=head2 add_aiparams($self, $params)

Adds additional AI parameters.

=head2 set_aipost_prompt($self, $postprompt)

Sets the AI post-prompt parameters.

=head2 set_aiprompt($self, $prompt)

Sets the AI prompt parameters.

=head2 swaig_response($self, $response)

Processes and returns the SWAIG response.

=head2 swaig_response_json($self, $response)

Processes the SWAIG response and returns it as JSON.

=head2 render($self)

Renders the content of the ML object.

=head2 render_json($self)

Renders the content of the ML object as JSON.

=head2 render_yaml($self)

Renders the content of the ML object as YAML.


=head1 SYNOPSIS

TODO

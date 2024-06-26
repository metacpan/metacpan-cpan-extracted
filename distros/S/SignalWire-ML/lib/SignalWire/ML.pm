package SignalWire::ML;

use strict;
use warnings;
use JSON;
use YAML::PP qw( Dump );
use Data::Dumper;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

our $VERSION = '1.20';
our $AUTOLOAD;

sub new {
    my $proto = shift;
    my $args  = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    
    $self->{_content}->{version}        = $args->{version} ||= '1.0.0';
    return bless($self, $class);
}

# This adds the ai application to the section provided in the args,
# taking all the previously set params and options for the AI and
# attaching them to the application.
sub add_aiapplication {
    my $self    = shift;
    my $section = shift;
    my $app     = "ai";
    my $args    = {};

    foreach my $data ('post_prompt', 'post_prompt_url', 'post_prompt_auth_user', 'post_prompt_auth_password', 'languages', 'hints', 'params', 'prompt', 'SWAIG', 'pronounce', 'global_data') {
	next unless $self->{"_$data"};
	$args->{$data} = $self->{"_$data"};
    }

    push @{$self->{_content}->{sections}->{$section} },  { $app =>  $args };

    return;
}

# Set context steps, overriding any existing steps
sub set_context_steps {
    my $self = shift;
    my $context_name = shift;
    my $steps = shift;

    $self->{_prompt}->{contexts}->{$context_name}->{steps} = $steps;

    return;
}

# Add steps to context, appending to any existing steps
sub add_context_steps {
    my $self = shift;
    my $context_name = shift;
    my $steps = shift;

    $self->{_prompt}->{contexts}->{$context_name}->{steps} //= [];
    push @{$self->{_prompt}->{contexts}->{$context_name}->{steps}}, @$steps;

    return;
}

# Set contexts for prompt, allowing for initial setup of multiple contexts
sub set_prompt_contexts {
    my $self = shift;
    my $contexts = shift;

    $self->{_prompt}->{contexts} = $contexts;

    return;
}

# add application to section, providing all the app args.
sub add_application {
    my $self    = shift;
    my $section = shift;
    my $app     = shift;
    my $args    = shift || {};

    push @{$self->{_content}->{sections}->{$section} },  { $app =>  $args };

    return;
}

# set post_url and optionally pass in post_user and post_password
sub set_aipost_prompt_url {
    my $self       = shift;
    my $postprompt = shift;

    while ( my ($k,$v) = each(%{$postprompt}) ) {
	$self->{"_$k"} = $postprompt->{$k};
    }

    return;
}

# Set global_data 
sub set_global_data {
    my $self = shift;

    $self->{_global_data} = shift;

    return;
}

# Set params overriding any previously set params
sub set_aiparams {
    my $self = shift;

    $self->{_params} = shift;

    return;
}

# Add one or more params
sub add_aiparams {
    my $self   = shift;
    my $params = shift;
    my @keys = ("end_of_speech_timeout", "attention_timeout", "outbound_attention_timeout", "background_file_loops", "background_file_volume", "digit_timeout", "energy_level" );

    while ( my ($k,$v) = each(%{$params}) ) {
	if ( grep { $_ eq $k } @keys ) {
            $self->{_params}->{$k} = $v + 0;
	} else {
            $self->{_params}->{$k} = $v;
	}
    }

    return;
}

# Set hints overriding any previously set hints
sub set_aihints {
    my $self  = shift;
    my @hints = @_;

    $self->{_hints} = \@hints;

    return;
}

# Add hints, and make sure they are uniq
sub add_aihints {
    my $self  = shift;
    my @hints = @_;
    my %seen;

    push  @{ $self->{_hints} }, @hints;
    @{ $self->{_hints} } = grep { !$seen{$_}++ } @{ $self->{_hints} };

    return;
}

# set SWAIG defaults overriding previous defaults
sub add_aiswaigdefaults {
    my $self  = shift;
    my $SWAIG = shift;
    $self->{_SWAIG}->{defaults} //= {};
    
    while ( my ($k,$v) = each(%{$SWAIG}) ) {
	$self->{_SWAIG}->{defaults}->{$k} = $v;
    }

    return;
}

# set SWAIG function
sub add_aiswaigfunction {
    my $self  = shift;
    my $SWAIG = shift;
    $self->{_SWAIG}->{functions} //= [];
    
    @{ $self->{_SWAIG}->{functions} } = (@{ $self->{_SWAIG}->{functions} }, $SWAIG);

    return;
}

# set pronounces overriding previous pronounces
sub set_aipronounce {
    my $self      = shift;
    my $pronounce = shift;
    $self->{_pronounce} //= [];
    
    $self->{_pronounce} = $pronounce;

    return;
}

# add pronounces appending to the list
sub add_aipronounce {
    my $self      = shift;
    my $pronounce = shift;
    $self->{_pronounce} //= [];
    
    @{ $self->{_pronounce} } = (@{ $self->{_pronounce} }, $pronounce);

    return;
}

# set lanugages overriding previous languages
sub set_ailanguage {
    my $self     = shift;
    my $language = shift;
    $self->{_languages} //= [];
    
    $self->{_languages} = $language;

    return;
}

# Add language appending to the list
sub add_ailanguage {
    my $self     = shift;
    my $language = shift;
    $self->{_languages} //= [];
    
    @{ $self->{_languages} } = (@{ $self->{_languages} }, $language);

    return;
}

# Function included in SWAIG
sub add_aiinclude {
    my $self = shift;
    my $include = shift;
    $self->{_SWAIG}->{includes} //= [];
    
    @{ $self->{_SWAIG}->{includes} } = (@{ $self->{_SWAIG}->{includes}}, $include);
    
    return;
}

# Function included in native SWAIG
sub add_ainativefunction {
    my $self   = shift;
    my $native = shift;
    $self->{_SWAIG}->{native_functions} //= [];
    
    @{ $self->{_SWAIG}->{native_functions} } = (@{ $self->{_SWAIG}->{native_functions}}, $native);

    return;
}

#set post_prompt
sub set_aipost_prompt {
    my $self       = shift;
    my $postprompt = shift;
    my @keys = ("confidence", "barge_confidence", "top_p", "temperature", "frequency_penalty", "presence_penalty");
    
    while ( my ($k,$v) = each(%{$postprompt}) ) {
	if ( grep { $_ eq $k } @keys ) {
            $self->{_post_prompt}->{$k} = $v + 0;
	} else {
            $self->{_post_prompt}->{$k} = $v;
	}
    }

    return;
}

# Set the prompt text and other settings
sub set_aiprompt {
    my $self = shift;
    my $prompt = shift;
    my @keys = ("confidence", "barge_confidence", "top_p", "temperature", "frequency_penalty", "presence_penalty");

    while ( my ($k,$v) = each(%{$prompt}) ) {
        if ( grep { $_ eq $k } @keys ) {
            $self->{_prompt}->{$k} = $v + 0;
        } else {
            $self->{_prompt}->{$k} = $v;
        }
    }

    return;
}

# Return a SWAIG response with optional SWML if sections exist. 
sub swaig_response {
    my $self     = shift;
    my $response = shift;

    return $response;
}

sub swaig_response_json {
    my $self     = shift;
    my $response = shift;
    my $json = JSON->new->allow_nonref;

    return $json->pretty->utf8->encode( $response );
}

# Return oject as a perl ref
sub render {
    my $self = shift;

    return $self->{_content};
}

# Render the object to JSON;
sub render_json {
    my $self = shift;
    my $json = JSON->new->allow_nonref;

    return $json->pretty->utf8->encode( $self->{_content} )
}

# Render the object to YAML;
sub render_yaml {
    my $self = shift;

    return Dump $self->{_content};
}

1;
__END__

=encoding utf8

=head1 NAME

SignalWire::ML - Light and fast SWML generator

=head1 SYNOPSIS

TODO

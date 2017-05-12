package NLP::Service;

use 5.010000;
use feature ':5.10';
use common::sense;
use Carp ();

BEGIN {
    use Exporter();
    our @ISA     = qw(Exporter);
    our $VERSION = '0.02';
    use NLP::StanfordParser;
}

use Dancer qw(:tests); # we do not want the tests exporting the wrong functions.
use Dancer::Plugin::REST;

my %_nlp = ();

prepare_serializer_for_format;

any [qw/get post/] => '/' => sub {

    #TODO: show a UI form based thing for easy use for the end user.
    return 'This is ' . config->{appname} . "\n";
};

any [qw/get post/] => '/nlp/models.:format' => sub {
    return [ keys %_nlp ];
};

any [qw/get post/] => '/nlp/languages.:format' => sub {
    return [qw/en/];
};

any [qw/get post/] => '/nlp/info.:format' => sub {
    return {
        version        => $NLP::Service::VERSION,
        nlplib_name    => 'Stanford Parser',
        nlplib_source  => PARSER_SOURCE_URI,
        nlplib_release => PARSER_RELEASE_DATE,
    };
};

any [qw/get post/] => '/nlp/relations.:format' => sub {
    return NLP::StanfordParser::relations();
};

#Dancer::forward does not forward the parameters, hence we have to explicitly
#forward them.
any [qw/get post/] => '/nlp/parse.:format' => sub {
    my $model = 'en_pcfg';
    my $route = "/nlp/parse/$model." . params->{format};
    debug "Forwarding to $route";
    if ( request->{method} eq 'GET' ) {
        return forward $route,
          {
            format => params->{format},
            model  => $model,
            data   => params->{data}
          };
    } else {

        # HACK inserted until Dancer's forwarding bug gets fixed.
        # https://github.com/sukria/Dancer/pull/545
        #
        my $data = params->{data};
        $data =~ s/^\s+//g;
        $data =~ s/\s+$//g;
        my $data = params->{data}
          or return send_error( { error => "Empty 'data' parameter" }, 500 );
        debug "Data is $data\n";
        if ( defined $_nlp{$model} ) {
            my $str = $_nlp{$model}->parse($data);
            my $aref = eval $str or Carp::carp "Unable to eval $str";
            return defined $aref ? $aref : "$str\n";
        }
        return send_error( { error => "Invalid NLP object for $model" }, 500 );
    }
};

any [qw/get post/] => '/nlp/parse/:model.:format' => sub {
    my $model = params->{model};
    debug "Model is $model";
    return send_error( { error => "Unknown parsing model $model" }, 500 )
      unless defined $_nlp{$model};
    my $data = params->{data};
    $data =~ s/^\s+//g;
    $data =~ s/\s+$//g;
    my $data = params->{data}
      or return send_error( { error => "Empty 'data' parameter" }, 500 );
    debug "Data is $data\n";

    if ( defined $_nlp{$model} ) {
        my $str = $_nlp{$model}->parse($data);
        my $aref = eval $str or Carp::carp "Unable to eval $str";
        return defined $aref ? $aref : "$str\n";
    }
    return send_error( { error => "Invalid NLP object for $model" }, 500 );
};

sub load_models {
    my ( $force, $jarpath ) = @_;
    say 'Forcing loading of all NLP models.' if $force;
    %_nlp = ();
    $_nlp{en_pcfg} = new NLP::StanfordParser( model => MODEL_EN_PCFG )
      or Carp::croak 'Unable to create MODEL_EN_PCFG for NLP::StanfordParser';

    # PCFG load times are reasonable ~ 5 sec. We force load on startup.
    $_nlp{en_pcfg}->parser if $force;
    $_nlp{en_factored} = new NLP::StanfordParser( model => MODEL_EN_FACTORED )
      or Carp::croak
      'Unable to create MODEL_EN_FACTORED for NLP::StanfordParser';

    # Factored load times can be quite slow ~ 30 sec. We force load on startup.
    $_nlp{en_factored}->parser if $force;

    # PCFG WSJ takes ~ 2-3 seconds to load
    $_nlp{en_pcfgwsj} = new NLP::StanfordParser( model => MODEL_EN_PCFG_WSJ )
      or Carp::croak
      'Unable to create MODEL_EN_PCFG_WSJ for NLP::StanfordParser';
    $_nlp{en_pcfgwsj}->parser if $force;
    $_nlp{en_factoredwsj} =
         new NLP::StanfordParser( model => MODEL_EN_FACTORED_WSJ )
      or Carp::croak
      'Unable to create MODEL_EN_FACTORED_WSJ for NLP::StanfordParser';

    # FACTORED WSJ takes ~ 20 seconds to load
    $_nlp{en_factoredwsj}->parser if $force;
    return unless defined wantarray;    # void context returns nothing
    return wantarray ? %_nlp : scalar( keys(%_nlp) );
}

sub run {
    my %args   = @_;
    my $force  = $args{force} if scalar( keys(%args) );
    my $config = $args{config} if scalar( keys(%args) );
    if ( defined $config and ref $config eq 'HASH' ) {
        map { set( $_ => $config->{$_} ) } keys %$config;
    } else {
        set log          => 'error';
        set logger       => 'console';
        set show_errors  => 1;
        set startup_info => 0;
    }
    load_models($force);
    dance;    # invoke Dancer
}

1;
__END__
COPYRIGHT: 2011. Vikas Naresh Kumar.
AUTHOR: Vikas Naresh Kumar
DATE: 25th March 2011
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 NAME

NLP::Service

=head1 SYNOPSIS

NLP::Service is a RESTful web service based off Dancer to provide natural language parsing for English.

=head1 VERSION

0.02

=head1 METHODS

=over

=item B<run()>

The C<run()> function starts up the NLP::Service, and listens to requests. It currently takes no parameters.
It makes sure that the NLP Engines that are being used are loaded up before the web service is ready.

It takes a hash as an argument with the following keys:

=over 8

=item B<force>

Forces the loading of all NLP models before doing anything. The value expected
is anything that is not 0 or undef, to be able to do this. Example,

C<NLP::Service::run(force =E<gt> 1);>

=item B<config>

Takes in a configuration for the internal service implementation.
Currently the implementation is using Dancer, and all of these keys correspond
to Dancer::Config. For more details, refer to Dancer config for the acceptable
values. Example,

C<NLP::Service::run(config =E<gt> { logger =E<gt> 'console' });>

=back

=item B<load_models()>

The C<load_models()> function creates all the required NLP models that are
supported. This is internally called by the C<run()> function, so the user does
not explicitly need to call them. It is useful however, for explicit loading of
the models, if the models need to be used in unit tests or elsewhere.

In void context it returns nothing, but in scalar context returns the number of
models that were loaded, and in list context returns a hash with the keys being
model names and the values being the actual references to the perl objects that
represent the models. This is rarely necessary for the user to be using.

It takes a single argument which is a boolean to forcibly load the parsers or
not. By default the lazy load option is assumed unless explicitly set by the
user. For example,
C<NLP::Service::load_models(1)> for forced loading and
C<NLP::Service::load_models()> for lazy loading.

=back

=head1 RESTful API

Multiple formats are supported in the API. Most notably they are XML, YAML and JSON.
The URIs need to end with C<.xml>, C<.yml> and C<.json> for XML, YAML and JSON, respectively.

=over

=item B<GET> I</nlp/models.(json|xml|yml)> 

Returns an array of loaded models. These are the model names that will be used
in the other RESTful API URI strings.

=item B<GET> I</nlp/languages.(json|xml|yml)>

Returns an array of supported languages. Default is "en" for English.

=item B<GET> I</nlp/info.(json|xml|yml)>

Returns a hashref of details about the NLP tool being used.

=item B<GET/POST> I</nlp/relations.(json|xml|yml)>

The user can get a list of all the english grammatical relations supported by
the NLP backend.

=item B<GET/POST> I</nlp/parse/B<$model>.(json|xml|yml)>

The user can make GET or POST requests to the above URI constructed by the user
or their programs. The C<$model> corresponds to one of the available models such
as "en_pcfg", "en_factored", etc. The list of supported models are returned by
the GET request to C</nlp/models.(json|xml|yml)> URI.

The return value is a Part of Speech tagged variation of the input parameter
I<data>.

The parameters needed are as follows:

=over 2

=item B<data>

One of the parameters expected is I<data> which should contain the text that
needs to be parsed and whose NLP formation of Part-of-Speech tagging needs to
be returned.

=back

=item B<GET/POST> I</nlp/parse.(json|xml|yml)>

This performs the same function as above, but picks the default model which is
C<en_pcfg>. It expects the same parameters as above.

=back

=head1 COPYRIGHT

Copyright (C) 2011. B<Vikas Naresh Kumar> <vikas@cpan.org>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Started on 25th March 2011.


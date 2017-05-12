#!/usr/bin/perl

package Template::Multipass;
use base qw/Template/;

use strict;
use warnings;

our $VERSION = "0.03";

use Data::Visitor::Callback;

use Template::Multipass::Provider;

sub _init {
    my ( $self, $config, @args ) = @_;

    # this config is captured and then localized.
    # no guarantee as to which parts in TT respect a change of config, but it works for most values (e.g. START_TAG, END_TAG)
    $self->{_multipass}{captured_config} = $config;

    # this is where meta config overrides are stored
    my $opts = $config->{MULTIPASS};
    $self->{_multipass}{config} = $opts;

    $self->{_multipass}{vars} = $opts->{VARS} || {};

    my $overlay = {
        $self->default_meta_options,
        %$opts,
    };

    delete $overlay->{VARS};

    $self->{_multipass}{config_overlay} = $overlay;

    $self->SUPER::_init( $config, @args );

    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        'Template::Base'     => "visit_ref",
        'Template::Provider' => sub { $_ = Template::Multipass::Provider->new( provider => $_, template => $self, config => $config ) },
    )->visit( $self );

    return $self;
}

sub default_meta_options {
    my $self = shift;

    return (
        START_TAG => '{%',
        END_TAG   => '%}',
        WRAPPER   => undef,
    );
}

# this is called by the top level code. It steals some of the multipass specific options and keeps them safe.
# it also lets the normal template have the meta vars.
sub process {
    my ($self, $template, $vars, $outstream, @opts) = @_;

    my $options = (@opts == 1) && UNIVERSAL::isa($opts[0], 'HASH')
        ? shift(@opts) : { @opts };

    my $meta_vars = {
        %{ $self->{_multipass}{vars} }, # captured by _init
        %{ $options->{meta_vars} || {} }
    };

    local $self->{_multipass}{captured_process_opts} = $options;
    local $self->{_multipass}{merged_meta_vars}      = $meta_vars;

    $self->SUPER::process(
        $template, 
        { %$meta_vars, %$vars }, # merge all the meta vars so that the normal template can also see them
        $outstream,
        $options,
    );
}

# called by the provider from within the process
# this will wrap all returned documents from the real provider, and run it
# through the meta pass, creating a document from the result of processing the
# original
sub process_meta_template {
    my ( $self, $provider, $method, @args ) = @_;

    # ignore all other providers in the recursion
    local $self->context->{LOAD_TEMPLATES} = [ $provider ];
    local $self->context->{PREFIX_MAP} = {};

    # process( ...., { meta_opts => { blah } } )  causes { blah } to be given to the inner process used on the meta template
    my $opts = $self->{_multipass}{captured_process_opts}{meta_opts} || {};

    # calculate the configuration and variables for the meta pass
    my $overlay = $self->{_multipass}{config_overlay}; # constructed at _init
    local @{ $self->{_multipass}{captured_config} }{ keys %$overlay } = values %$overlay; # START_TAG, END_TAG etc
    my $vars = $self->{_multipass}{merged_meta_vars}; # merged by process at the top of the call chain

    local $@;

    # dispatch the original method on the provider, getting the original result
    my ( $doc, $error ) = $provider->$method( @args ); # method is _fetch or _load, or in the case of scalar refs a coderef prepared by the wrapper provider

    my $out;

    # reconfigure WRAPPER, PRE_PROCES, PROCESS etc for the meta pass by
    # localizing and reinitializing with the localized config
    my $service = $self->service;
    local @{ $service }{ keys %$service } = ( values %$service );
    $service->_init($self->{_multipass}{captured_config});

    # Perform the actual meta pass here:

    if ( !$error && eval { $self->process( $doc, $vars, \$out, $opts ) } ) {
        return ({ name => $doc->{name}, path => $doc->{path}, time => $doc->{modtime}, text => $out, load => 0 }, $error );
    } else {
        return ( $doc, $error );
    }
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Template::Multipass - Add a meta template pass to TT

=head1 SYNOPSIS

   
    my $t = Template::Multipass->new(
        INCLUDE_PATH => [ file(__FILE__)->parent->subdir("templates")->stringify ],
        COMPILE_EXT  => "c",
        MULTIPASS => {
            VARS => {
                lang => "en",
                loc => sub { $lang_handle->maketext(@_) },
            }
        },
    );

    $t->process( ... );


    # ORIGINAL TT

    [% loc("hello") %] [% user.name %],
    [% loc("instructions") %]


    # MULTIPASS TEMPLATE

    {% loc("hello") %} [% user.name %],
    {% loc("instructions") %}


    # RESULTING CACHED TEMPLATE

    Hello, [% user.name %]
    Please select a Moose

=head1 DESCRIPTION

This module was written to precompute the static parts of templates (text based
on variables which are not runtime dependant, and can thus be precomputed).

The most prominent example of this is localization of constant strings. This is
demonstrated in the L</SYNOPSIS>.

Template::Multipass will first process the template with only the meta
variables, and cache the result. Then it will process the file again with all
of the variables. Subsequent runs will not have to recompute the meta var run
unless the variables have been changed.

=head1 CONFIGURATION

The configuration values inside C<MULTIPASS> in the top level config will be
overlayed on top of the normal config during meta template processing. This
works for values such as C<START_TAG> and C<END_TAG> (which default to C<{%>
and C<%}>), and may work for other values.

Additionallly the C<MULTIPASS> hash can take a C<VARS> hash to be used as the
meta vars in all runs.

This var hash can be further added by passing them as an option to process:

    $t->process( $template, $vars, $output, { meta_vars => { ... more vars ... } } );

Values in options will override those in the configuration.

Lastly the L<MANGLE_METHOD> and L<MANGLE_HASH_VARS> values may also be set in
the C<MULTIPASS> configuration, and will be discussed in L</CACHING>.

=head1 METHODS

See L<Template>. The API is unchanged except for:

=over 4

=item process

Also accepts the C<meta_vars> option.

=back

=head1 CAVEAT

=head2 Wrappers

Wrappers processed at meta time (C<{% WRAPPER blah %}...{% END %}>) will
require the use of C<{% %}> tags to embed the content. Otherwise the content is
lost till the C<[% %]> run starts.

=head1 CACHING

Caching is done using the native L<Template> caching mechanism (C<COMPILE_EXT>, etc).

See L<Template/Caching_and_Compiling_Options>.

The only difference is that meta templates are cached using filenames that
incorperate their meta vars.

There are two methods to mangle the file name, using a recursive MD5 hash of
the variable hash, or just the top level non reference ones (the default). This
is controlled using C<MANGLE_HASH_VARS>.

In order to properly utilize the default method to ease debugging (clearer file
names) pass in simple top level values. For example if you have a C<loc>
function or a C<lang_handle> var to run L<Locale::Maketext> localization, also
add a C<lang> top level var containing the language code. The resulting file
name will be C<lang-$lang,$template_name.ttc>.

If your meta templates require caching based on values inside references or
you'd rather not bother with creating top level strings simply enable
C<MANGLE_HASH_VARS>, which will result in a file name like
C<8a1fad1d1f3313b3647ac90b29eaac95-$template_name.ttc>.

=head1 INTERNALS OVERVIEW

The way this module works is by wrapping all the providers in a normally
instantiated L<Template> object with L<Template::Multipass::Provider>. This
provider will delegate to it's wrapped provider and then call back to the top
level object for meta template processing. It'll then cache the result with the
mangled name, and return the output of the template run as the input of the
original template.

=cut

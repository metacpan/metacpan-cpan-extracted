#!/usr/bin/perl

package Template::Multipass::Provider;
use base qw/Template::Provider/;

use File::Basename qw/dirname basename/;
use Scalar::Util qw/weaken/;
use File::Spec;

use strict;
use warnings;

sub _init {
    my ( $self, $p, @args ) = @_;
    @{ $self }{ keys %$p } = values %$p;

    %$self = (%{ $self->{provider} }, %$self ); # steal all the config keys from the provider we're wrapping

    weaken($self->{template});

    $self;
}

sub _load {
    my ( $self, $template, @args ) = @_;

    if ( ref $template ) {
        # scalar reference templates are special cased here, to also call _compile after the _load
        # this is to make the return value homogeneous for process_meta_template IIRC
        $self->{template}->process_meta_template(
            $self->{provider},
            sub {
                my ( $self, @args ) = @_;
                my ( $data, $error ) = $self->_load(@args);
                ($data, $error) = $self->_compile($data) unless $error;
                $data = $data->{ data } unless $error;
                return ( $data, $error );
            },
            $template,
            @args
        );
    } else {
        return $self->SUPER::_load( $template, @args );
    }
}

sub _fetch {
    my ( $self, @args ) = @_;
    my ( $name, $t_name ) = @args;

    local $self->{meta_vars} = $self->{template}{_multipass}{merged_meta_vars};

    if ($self->_compiled_is_current($name)) {
        my $compiled_template = $self->_load_compiled( my $n = $self->_compiled_filename($name) );

        return $self->store( $self->_mangle_name_wrapper($name), $compiled_template ) if $compiled_template;
    }

    my ( $loaded, $error ) = $self->{template}->process_meta_template( $self->{provider}, "_fetch", @args );

    unless ( $error ) {
        my ( $data, $error) = $self->_compile($loaded, $self->_compiled_filename($name));
        return ( ( $error ? undef : $data->{data} ), $error );
    } else {
        return ( undef, $error );
    }
}

sub _compiled_filename {
    my ( $self, $filename ) = @_;

    $self->SUPER::_compiled_filename( $self->_mangle_name_wrapper( $filename ) );
}

sub _mangle_name_wrapper {
    my ( $self, $filename ) = @_;
    
    my $vars = $self->{meta_vars};

    my $method = $self->{config}{MULTIPASS}{MANGLE_METHOD} || "_mangle_name";

    $self->$method( $filename, $vars );
}

sub _mangle_name {
    my ( $self, $filename, $vars ) = @_;

    my $method = $self->{config}{MULTIPASS}{MANGLE_HASH_VARS} ? "_mangle_name_hash" : "_mangle_name_flat";

    $self->$method( $filename, $vars );
}

sub _mangle_name_flat {
    my ( $self, $filename, $vars ) = @_;

    my @non_ref_keys = grep { not ref $vars->{$_} } keys %$vars;

    my %filtered_vars;
    @filtered_vars{ @non_ref_keys } = @{ $vars }{ @non_ref_keys };

    $self->_concat_vars_into_name( $filename, \%filtered_vars );
}

sub _concat_vars_into_name {
    my ( $self, $filename, $vars ) = @_;

    $self->_prefix_filename(
        $filename,
        join( ",", ( map { "$_-$vars->{$_}" } sort keys %$vars ), '' ),
    );
}

sub _mangle_name_hash {
    my ( $self, $filename, $vars ) = @_;

    require Storable;
    require Digest::MD5;
    local $Storable::canonical = 1;
    my $hash = Digest::MD5::md5_hex(
        Storable::nfreeze($vars)
    );

    $self->_prefix_filename(
        $filename,
        $hash . "-",
    );
}

sub _prefix_filename {
    my ( $self, $filename, $prefix ) = @_;

    File::Spec->catfile(
        dirname($filename),
        $prefix . basename($filename),
    );
}

__PACKAGE__

__END__

=pod

=head1 NAME

Template::Multipass::Provider - template provider wrapper for multipass hooks

=head1 SYNOPSIS

    # not user servicable
    # see Template::Multipass

=head1 DESCRIPTION

See L<Template::Multipass/INTERNALS OVERVIEW>

=cut

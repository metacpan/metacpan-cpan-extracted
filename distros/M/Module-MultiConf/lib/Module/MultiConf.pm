#
# $Id: MultiConf.pm 1384 2007-09-30 13:49:29Z oliver $
#
package Module::MultiConf;

use strict;
use warnings FATAL => 'all';

use Carp;
use Symbol;
use UNIVERSAL;
use Scalar::Util 'blessed';
use Config::Any;
use Params::Validate ':all';
use Class::Data::Inheritable;

our $VERSION = '1.0401';
$VERSION = eval $VERSION; # numify for warning-free dev releases

sub import {
    my $caller = caller(0);
    return if $caller eq 'main'; # testing abuse

    my $class = shift;
    my %args  = @_;

    # fake up use base...
    push @{*{Symbol::qualify_to_ref('ISA',$caller)}},
        'Class::Data::Inheritable', __PACKAGE__;

    # push useful things into caller's namespace
    foreach my $t (qw/SCALAR ARRAYREF HASHREF CODEREF GLOB GLOBREF
                    SCALARREF HANDLE BOOLEAN UNDEF OBJECT/) {
        *{Symbol::qualify_to_ref($t,$caller)} =
            *{Symbol::qualify_to_ref($t)}{CODE};
    }

    $caller->mk_classdata(Validate => {});
    $caller->mk_classdata(Force    => {});
    $caller->mk_classdata(Defaults => {
        allow_extra   => 1,
        on_fail       => sub { croak $_[0] },
        no_validation => 0,
        %args,
    });
}

*{Symbol::qualify_to_ref('parse')} = \&new;

sub new {
    my $self = shift;
    my @args = @_;

    return $self->_load_args() if scalar @args == 0;

    foreach (@args) {
        my $config = $_;

        # if arg is a filename, "convert" to a hashref by loading
        if (!ref $config) {
            my $loaded = Config::Any->load_files(
                {files => [$config], use_ext => 1});
            croak "Failed to parse contents of filename '$config'"
                if scalar @$loaded == 0;

            (undef, $config) = each %{$loaded->[0]};
        }

        croak "Config does not build a HASHREF"
            unless ref $config eq 'HASH' or blessed $config;

        $self = $self->_load_args($config);
    }

    return $self;
}

sub _load_args {
    my $self = shift;

    # factory
    $self = bless {}, $self if !ref $self;

    my $args = shift || {};
    my %copy = %$self;    # copy for validation and munging
    my $pkg  = ref $self; # package into which we look for Validation spec

    # load in new content
    foreach my $k (keys %$args) {
        croak "Loaded config must be a HASHREF of HASHREFs"
            if ref $args->{$k} ne 'HASH';
        @{$copy{$k}}{keys %{$args->{$k}}} = (values %{$args->{$k}});
    }

    # validate new content
    my $validate = $pkg->Validate;
    my $no_valid = $pkg->Defaults->{'no_validation'} || 0;

    {
        local $Params::Validate::NO_VALIDATION = $no_valid;
        foreach my $k (keys %$validate) {
            %{$copy{$k}} = validate_with(
                params      => $copy{$k} || {},
                spec        => $validate->{$k},
                %{ $pkg->Defaults },
            );
        }
    }

    # squash things which are enforced
    my $force = $pkg->Force;
    foreach my $k (keys %$force) {
        @{$copy{$k}}{keys %{$force->{$k}}} = (values %{$force->{$k}});
    }

    foreach my $k (keys %copy) {
        next if UNIVERSAL::can($self, $k);
        next if UNIVERSAL::can('main', $k); # testing abuse

        *{Symbol::qualify_to_ref($k, $pkg)} = sub {
            my $self = shift;
            my $pkg  = ref $self;

            # squash things which are enforced
            my $force = $pkg->Force;
            foreach my $k (keys %$force) {
                @{$self->{$k}}{keys %{$force->{$k}}} = (values %{$force->{$k}});
            }

            return ( wantarray ? %{$self->{$k}} : $self->{$k} );
        };
    }

    %$self = %copy; # restore validated and merged params into self
    return $self;
}

sub me {
    my $self = shift;
    (my $me = lc (scalar caller(0))) =~ s/::/_/g;
    return $self->$me;
}

1;

__END__

=head1 NAME

Module::MultiConf - Configure and validate your app modules in one go

=head1 VERSION

This document refers to version 1.0401 of Module::MultiConf

=head1 SYNOPSIS

 # first define the structure of your application configuration:
 
 package MyApp::Config;
 use Module::MultiConf;
 
 __PACKAGE__->Validate({
     first_module  => { ... }, # a Params::Validate specification
     second_module => { ... }, # a Params::Validate specification
 });
 
 # make some module parameters "read-only"
 __PACKAGE__->Force({
     first_module  => { var1 => 'val', var2 => 'val' },
 });
 
 # then use that to validate config passing through your app:
 
 package MyApp::ComponentThingy;
 use Another::Module;
 use MyApp::Config;
  
 sub new {
     my $class = shift;
     my $params = MyApp::Config->parse(@_);
         # @_ will be validated, and transferred to $params

     my $var1 = $params->myapp_componentthingy->{var1}; # gets a value
     my $var2 = $params->me->{var1}; # same thing, "me" aliases current package

     # you can update the contents of $params, and add new data
     $params->me->{new_cached_obj} =
        Another::Module->new( $params->another_module );
  
     return $class->SUPER::new($params);
 };
 
 # in addition, you can do things like this:
 
 # override, or add to, the passed in parameters
 my $params = MyApp::Config->parse(@_, {module => {foo => 12345}});
  
 # load a bunch of default config from a file (using Config::Any)
     # and you can still add an override hashref, as in the above example.
 my $params = MyApp::Config->parse('/path/to/some/file.yml');

=head1 DESCRIPTION

This module might help you to manage your application configuration, if most
of the config is actually for other modules which you use. The idea here is
that you store all that config in one place, probably an external file.

You can optionally use a validation specification, as described by
Params::Validate, to check you are not missing anything when the config is
loaded or passed around.

The interface to the stored config provides an object method per blob of
configuration, which returns a reference to the hash of that blob's content.

You can load config using a filename parameter, which is passed to
L<Config::Any>, or a hash reference of hash references, each representing the
config for one module. Each of these may be repeated as you like, with later
items overriding earlier ones.

Be aware that C<Config::Any> is called with the C<use_ext> parameter, meaning
you I<must> use file extensions on your config files. I am sorry about having
to do this, but it makes things just too unpredictable not to enable it.

Please refer to the bundled example files and tests for further details. It
would also be worth reading the L<Params::Validate> and L<Config::Any> manual
pages.

To have Params::Validate construct your mix of default and override options
whilst not validating for missing options, load the module like so:

 use MyApp::Config no_validation => 1;

=head1 SEE ALSO

=over 4

=item L<http://jc.ngo.org.uk/blog/2007/01/15/perl-parameter-validation-and-error-handling/>

=item L<Params::Validate>

=item L<Params::Util>

=item L<Config::Model>

=back

=head1 AUTHOR

Oliver Gorwits C<< <oliver.gorwits@oucs.ox.ac.uk> >>

Tests were written by myself and Ray Miller.

=head1 COPYRIGHT & LICENSE

Copyright (c) The University of Oxford 2008.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut


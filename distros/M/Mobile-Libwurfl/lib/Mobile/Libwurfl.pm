package Mobile::Libwurfl;

use 5.014002;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    WURFL_CACHE_PROVIDER_DOUBLE_LRU
    WURFL_CACHE_PROVIDER_LRU
    WURFL_CACHE_PROVIDER_NONE
    WURFL_ENGINE_TARGET_HIGH_ACCURACY
    WURFL_ENGINE_TARGET_HIGH_PERFORMANCE
    WURFL_MATCH_TYPE_CACHED
    WURFL_MATCH_TYPE_CATCHALL
    WURFL_MATCH_TYPE_CONCLUSIVE
    WURFL_MATCH_TYPE_EXACT
    WURFL_MATCH_TYPE_HIGHPERFORMANCE
    WURFL_MATCH_TYPE_NONE
    WURFL_MATCH_TYPE_RECOVERY
    WURFL_OK
    WURFL_ERROR_ALREADY_LOAD
    WURFL_ERROR_CANT_LOAD_CAPABILITY_NOT_FOUND
    WURFL_ERROR_CANT_LOAD_VIRTUAL_CAPABILITY_NOT_FOUND
    WURFL_ERROR_CAPABILITY_GROUP_MISMATCH
    WURFL_ERROR_CAPABILITY_GROUP_NOT_FOUND
    WURFL_ERROR_CAPABILITY_NOT_FOUND
    WURFL_ERROR_DEVICE_ALREADY_DEFINED
    WURFL_ERROR_DEVICE_HIERARCHY_CIRCULAR_REFERENCE
    WURFL_ERROR_DEVICE_NOT_FOUND
    WURFL_ERROR_EMPTY_ID
    WURFL_ERROR_FILE_NOT_FOUND
    WURFL_ERROR_INPUT_OUTPUT_FAILURE
    WURFL_ERROR_INVALID_CAPABILITY_VALUE
    WURFL_ERROR_INVALID_HANDLE
    WURFL_ERROR_INVALID_PARAMETER
    WURFL_ERROR_UNEXPECTED_END_OF_FILE
    WURFL_ERROR_UNKNOWN
    WURFL_ERROR_USERAGENT_ALREADY_DEFINED
    WURFL_ERROR_VIRTUAL_CAPABILITY_NOT_FOUND
);

our @EXPORT_OK = @EXPORT;

our %EXPORT_TAGS = ( 'all' => [@EXPORT] );

use constant + { @EXPORT };

our $VERSION = '0.02';


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Mobile::Libwurfl::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }

    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Mobile::Libwurfl', $VERSION);

use Mobile::Libwurfl::Device;
# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub new {
    my ($class, $dbfile) = @_;
    my $self = {};
    bless($self, $class);
    $self->{_wurfl} = wurfl_create();
    $self->load($dbfile)
        if ($dbfile);
    return $self;
}

sub load {
    my ($self, $dbfile) = @_;
    my $err = wurfl_set_root($self->{_wurfl}, $dbfile);
    if ($err != $self->WURFL_OK) {
        warn $self->error_message;
        return undef;
    }
    $err = wurfl_load($self->{_wurfl});
    if ($err != $self->WURFL_OK) {
        warn $self->error_message;
        return undef;
    }
    return $self;
}

sub lookup_useragent {
    my ($self, $uagent) = @_;
    my $device = wurfl_lookup_useragent($self->{_wurfl}, $uagent);

    return Mobile::Libwurfl::Device->new($self, $device);
}

sub get_device {
    my ($self, $id) = @_;
    my $device = wurfl_get_device($self->{_wurfl}, $id);
    return Mobile::Libwurfl::Device->new($self, $device);
}

sub add_patch {
    my ($self, $pfile) = @_;
    my $err = wurfl_add_patch($self->{_wurfl}, $pfile);
    if ($err != $self->WURFL_OK) {
        warn wurfl_get_error_message($self->{_wurfl});
        return 0;
    }
    return 1;
}

sub set_engine {
    my ($self, $engine) = @_;
    if ($engine != $self->WURFL_ENGINE_TARGET_HIGH_ACCURACY && 
        $engine != $self->WURFL_ENGINE_TARGET_HIGH_PERFORMANCE)
    {
        warn "Wrong engine type. " .
             "MUST be : WURFL_ENGINE_TARGET_HIGH_ACCURACY or WURFL_ENGINE_TARGET_HIGH_PERFORMANCE";
        return 0;
    }
    return wurfl_set_engine_target($self->{_wurfl}, $engine);
}

sub set_cache_provider {
    my ($self, $provider, $config) = @_;
    if ($provider != $self->WURFL_CACHE_PROVIDER_NONE && 
        $provider != $self->WURFL_CACHE_PROVIDER_LRU && 
        $provider != $self->WURFL_CACHE_PROVIDER_DOUBLE_LRU)
    {
        warn "Wrong provider type. " .
             "MUST be : WURFL_CACHE_PROVIDER_NONE ".
             "or WURFL_CACHE_PROVIDER_LRU ".
             "or WURFL_CACHE_PROVIDER_DOUBLE_LRU";
         return 0;
    }
    return wurfl_set_cache_provider($self->{_wurfl}, $provider, $config);
}

sub error_message {
    my $self = shift;
    return wurfl_get_error_message($self->{_wurfl});
}

sub has_error_message {
    my $self = shift;
    return wurfl_has_error_message($self->{_wurfl});
}

sub clear_error_message {
    my $self = shift;
    return wurfl_clear_error_message($self->{_wurfl});
}

sub DESTROY {
    my $self = shift;
    wurfl_destroy($self->{_wurfl});
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mobile::Libwurfl - Perl bindings to the commercial wurfl library (from ScientiaMobile)

=head1 SYNOPSIS

  use Wurfl;
  
  $wurfl = Wurfl->new();

  ###
  # optionally you can set the engine mode or the cache_provider
  # (refer to libwurfl documentation for more details)

  $err = $wurfl->set_engine(WURFL_ENGINE_TARGET_HIGH_PERFORMANCE);
  if ($err != WURFL_OK) {
    die $wurfl->error_message;
  }

  $err = $wurfl->set_cache_provider(WURFL_CACHE_PROVIDER_DOUBLE_LRU, "10000,3000");
  if ($err != WURFL_OK) {
    die $wurfl->error_message;
  }
  ####


  $wurfl->load("/usr/share/wurfl/wurfl.xml");

  # you can also provide the database file directly to the constructor
  # (default engine mode and cache provider will be used)
  $wurfl = Wurfl->new("/usr/share/wurfl/wurfl.xml");

  $device = $wurfl->lookup_useragent(USERAGENT);

  # get an hashref with all known capabilities
  $capabilities = $device->capabilities;

  # or access a specific capability directly
  $viewport_width = $device->get_capability('viewport_width');

  All functions from libwurfl have been mapped, refer to the
  Mobile::Libwurfl::Device documentation for a list of methods

=head1 DESCRIPTION

Perl bindings to the commercial C library to access wurfl databases

=head1 METHODS

=over 4

=item * new ($dbfile)

Creates a new Wurfl object. if $dbfile is provided it will be immediately
loaded using the default engine mode and cache provider


=item * load ($dbfile)

Load the database file at the path pointed by $dbfile

=item * lookup_useragent ($ua_string)

Returns a Mobile::Libwurfl::Device object representing the best match for the provided useragent string

=item * get_device ($id)

Returns a new Mobile::Libwurfl::Device object for the provided device id (if any)

=item * set_engine ($mode)

Sets the engine mode. This method can be called only before loading a database file.
If called once a database file has been already loaded WURFL_ERROR_ALREADY_LOAD will be returned

Valid values for the $mode argument are : WURFL_ENGINE_TARGET_HIGH_ACCURACY and WURFL_ENGINE_TARGET_HIGH_ACCURACY

=item * set_cache_provider ($provider, $config)

Sets and configure the cache provider. This method can be called only before loading a database file.
If called once a database file has been already loaded WURFL_ERROR_ALREADY_LOAD will be returned

Valid values for the $mode argument are : WURFL_CACHE_PROVIDER_NONE, WURFL_CACHE_PROVIDER_LRU and WURFL_CACHE_PROVIDER_DOUBLE_LRU

Check libwurfl documnetation for further details on their meaning and what expected in the $config param. 

=item * error_message ()

=item * has_error_message ()

=item * clear_error_message ()

=item * add_patch ($patch_file)

=head2 EXPORT

  WURFL_CACHE_PROVIDER_DOUBLE_LRU
  WURFL_CACHE_PROVIDER_LRU
  WURFL_CACHE_PROVIDER_NONE
  WURFL_ENGINE_TARGET_HIGH_ACCURACY
  WURFL_ENGINE_TARGET_HIGH_PERFORMANCE
  WURFL_ERROR_ALREADY_LOAD
  WURFL_ERROR_CANT_LOAD_CAPABILITY_NOT_FOUND
  WURFL_ERROR_CANT_LOAD_VIRTUAL_CAPABILITY_NOT_FOUND
  WURFL_ERROR_CAPABILITY_GROUP_MISMATCH
  WURFL_ERROR_CAPABILITY_GROUP_NOT_FOUND
  WURFL_ERROR_CAPABILITY_NOT_FOUND
  WURFL_ERROR_DEVICE_ALREADY_DEFINED
  WURFL_ERROR_DEVICE_HIERARCHY_CIRCULAR_REFERENCE
  WURFL_ERROR_DEVICE_NOT_FOUND
  WURFL_ERROR_EMPTY_ID
  WURFL_ERROR_FILE_NOT_FOUND
  WURFL_ERROR_INPUT_OUTPUT_FAILURE
  WURFL_ERROR_INVALID_CAPABILITY_VALUE
  WURFL_ERROR_INVALID_HANDLE
  WURFL_ERROR_INVALID_PARAMETER
  WURFL_ERROR_UNEXPECTED_END_OF_FILE
  WURFL_ERROR_UNKNOWN
  WURFL_ERROR_USERAGENT_ALREADY_DEFINED
  WURFL_ERROR_VIRTUAL_CAPABILITY_NOT_FOUND
  WURFL_MATCH_TYPE_CACHED
  WURFL_MATCH_TYPE_CATCHALL
  WURFL_MATCH_TYPE_CONCLUSIVE
  WURFL_MATCH_TYPE_EXACT
  WURFL_MATCH_TYPE_HIGHPERFORMANCE
  WURFL_MATCH_TYPE_NONE
  WURFL_MATCH_TYPE_RECOVERY
  WURFL_OK

=head1 SEE ALSO

 Mobile::Libwurfl::Device

=head1 AUTHOR

Andrea Guzzo, E<lt>xant@xant.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Andrea Guzzo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

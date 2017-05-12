package Mobile::Libwurfl::Device;
use strict;
use warnings;

use Wurfl;

my %CONVERT_BOOLEAN = (true => 1, false => 0);

sub new {
    my ($class, $wurfl, $device) = @_;

    return if !($wurfl && $device);

    my $self = {
                 _wurfl => $wurfl,
                 _device => $device
               };
    bless $self, $class;
    return $self;
}

sub _fetch_capabilities {
    my ($enumerator) = @_;
    my $caps;
    while (Mobile::Libwurfl::wurfl_device_capability_enumerator_is_valid($enumerator)) {
        my $name = Mobile::Libwurfl::wurfl_device_capability_enumerator_get_name($enumerator);
        my $val = Mobile::Libwurfl::wurfl_device_capability_enumerator_get_value($enumerator);

        $caps->{$name} = $CONVERT_BOOLEAN{$val} // $val;

        Mobile::Libwurfl::wurfl_device_capability_enumerator_move_next($enumerator);
    }
    return $caps;
}

sub capabilities {
    my ($self) = @_;
    my $hdevicecaps = Mobile::Libwurfl::wurfl_device_get_capability_enumerator($self->{_device});
    my $caps = _fetch_capabilities($hdevicecaps);
    Mobile::Libwurfl::wurfl_device_capability_enumerator_destroy($hdevicecaps);
    return $caps;
}

sub virtual_capabilities {
    my ($self) = @_;
    my $hdevicecaps = Mobile::Libwurfl::wurfl_device_get_virtual_capability_enumerator($self->{_device});
    my $caps = _fetch_capabilities($hdevicecaps);
    Mobile::Libwurfl::wurfl_device_capability_enumerator_destroy($hdevicecaps);
    return $caps;
}

sub id {
    my ($self, $capability) = @_;
    return Mobile::Libwurfl::wurfl_device_get_id($self->{_device});
}

sub useragent {
    my ($self) = @_;
    return Mobile::Libwurfl::wurfl_device_get_useragent($self->{_device});
}

sub get_capability {
    my ($self, $capability) = @_;
    my $val = Mobile::Libwurfl::wurfl_device_get_capability($self->{_device}, $capability);
    return $CONVERT_BOOLEAN{$val} // $val;
}

sub has_capability {
    my ($self, $capability) = @_;
    return Mobile::Libwurfl::wurfl_device_has_capability($self->{_device}, $capability);
}

sub has_virtual_capability {
    my ($self, $capability) = @_;
    return Mobile::Libwurfl::wurfl_device_has_virtual_capability($self->{_device}, $capability);
}

sub get_virtual_capability {
    my ($self, $capability) = @_;
    my $val = Mobile::Libwurfl::wurfl_device_get_virtual_capability($self->{_device}, $capability);
    return $CONVERT_BOOLEAN{$val} // $val;
}

sub match_type {
    my ($self) = @_;
    return Mobile::Libwurfl::wurfl_device_get_match_type($self->{_device});
}

sub matcher_name {
    my ($self) = @_;
    return Mobile::Libwurfl::wurfl_device_get_matcher_name($self->{_device});
}

sub DESTROY {
    my $self = shift;

    Mobile::Libwurfl::wurfl_device_destroy($self->{_device});
}

=head1 NAME

Mobile::Libwurfl::Device - Device perl wrapper to wurfl_device_handle

(Perl bindings for the wurfl commercial library)

=head1 SYNOPSIS

  use Wurfl;
  
  $wurfl = Wurfl->new(PATH_TO_WURFL_XML_FILE);

  $device = $wurfl->lookup_useragent(USERAGENT);
  # or
  $device = $wurfl->get_device(DEVICE_ID);

  # get an hashref with all known capabilities
  $capabilities = $device->capabilities;

  # or access a specific capability directly
  $viewport_width = $device->get_capability('viewport_width');

=head1 DESCRIPTION

Perl bindings to the commercial C library to access wurfl databases

=head1 METHODS

=over 4

=item * new ($wurfl, $device)

Creates a new Device object.
Both $wurfl and $device must be defined.
$wurfl must point to a valid Wurfl object
$device must be a valid wurfl_device_handle pointer returned by the underlying C API

=item * capabilities

Rerturns an hashref with all the known capabilities applicable to the current device

=item * id

Returns the id of the current device. The id can be used later with Mobile::Libwurfl::get_device()
to obtain a new instance of this same device

=item * useragent

Returns the default useragent string for the current device

=item * get_capability ($capability)

Returns the value of the specific $capability (if it is a valid capability, undef otherwise)

=item * has_capability ($capability)

Returns true if $capability is a valid capability applicable to the current device, undef otherwise

Note that this doesn't check the actual value of the capability (if boolean it can still be 'false')
but it just checks the existance of $capability among the known capabilities

=item * get_virtual_capability ($capability)

=item * has_virtual_capability ($capability)

=item * match_type ()

Returns the type of match for the current device.
returned value can be any of :

WURFL_MATCH_TYPE_EXACT
WURFL_MATCH_TYPE_CONCLUSIVE
WURFL_MATCH_TYPE_RECOVERY
WURFL_MATCH_TYPE_CATCHALL
WURFL_MATCH_TYPE_HIGHPERFORMANCE
WURFL_MATCH_TYPE_NONE
WURFL_MATCH_TYPE_CACHED

Such constants are exported by the Wurfl.
Check libwurfl documentation for more details about matcher types and strings

=item * matcher_name ()

Returns the string identifying the 'matcher' which matched the current device

Check libwurfl documentation for more details about matcher types and strings

=head1 SEE ALSO

 Mobile::Libwurfl

=head1 AUTHOR

Andrea Guzzo, E<lt>xant@xant.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Andrea Guzzo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
1;

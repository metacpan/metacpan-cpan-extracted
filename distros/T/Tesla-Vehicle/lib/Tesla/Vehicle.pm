package Tesla::Vehicle;

use warnings;
use strict;

use parent 'Tesla::API';

use Carp qw(croak confess);
use Data::Dumper;

our $VERSION = '0.07';

use constant {
    DEBUG_ONLINE    => $ENV{TESLA_DEBUG_ONLINE},
    DEBUG_API_RETRY => $ENV{TESLA_DEBUG_API_RETRY},
    API_RETRIES     => 5,
    WAKE_TIMEOUT    => 30,
    WAKE_INTERVAL   => 2,
    WAKE_BACKOFF    => 1.15
};

# Object Related

sub new {
    my ($class, %params) = @_;

    # See Tesla::API new() for params the parent handles
    my $self = $class->SUPER::new(%params);

    $self->warn($params{warn});
    $self->_id($params{id});
    $self->auto_wake($params{auto_wake});

    return $self;
}
sub auto_wake {
    my ($self, $auto_wake) = @_;

    if (defined $auto_wake) {
        $self->{auto_wake} = $auto_wake;
    }

    return $self->{auto_wake} // 0;
}
sub warn {
    my ($self, $warn) = @_;
    $self->{warn} = $warn if defined $warn;
    return $self->{warn} // 1;
}

# Vehicle Summary Methods

sub in_service {
    return $_[0]->summary->{in_service};
}
sub options {
    my ($self) = @_;
    my $vehicle_options = $self->summary->{option_codes};

    my $option_codes = $self->option_codes;

    my %option_definitions;

    for (split /,/, $vehicle_options) {
        $option_definitions{$_} = $option_codes->{$_};
    }

    return \%option_definitions;
}
sub vehicle_id {
    return $_[0]->summary->{vehicle_id};
}
sub vin {
    return $_[0]->summary->{vin};
}

# Vehicle Identification Methods

sub id {
    # Tries to figure out the ID to use in API calls
    my ($self, $id) = @_;

    if (! defined $id) {
        $id = $self->_id;
    }

    if (! $id) {
        confess "Method called that requires an \$id param, but it wasn't sent in";
    }

    return $id;
}
sub list {
    my ($self) = @_;

    return $self->{vehicles} if $self->{vehicles};

    my $vehicles = $self->api(endpoint => 'VEHICLE_LIST');

    for (@$vehicles) {
        $self->{data}{vehicles}{$_->{id}} = $_->{display_name};
    }

    return $self->{data}{vehicles};
}
sub name {
    my ($self) = @_;
    return $self->list->{$self->id};
}

# Top Level Data Structure Methods

sub data {
    my ($self) = @_;
    $self->_online_check;

    my $data = $self->api(endpoint => 'VEHICLE_DATA', id => $self->id);

    if (ref $data ne 'HASH') {
        CORE::warn "Tesla API timed out. Please retry the call\n";
        return {};
    }

    if (! defined $data->{drive_state}{shift_state}) {

        for (1 .. API_RETRIES) {
            print "API retry attempt $_\n" if DEBUG_API_RETRY;

            $self->api_cache_clear;

            $data = $self->api(endpoint => 'VEHICLE_DATA', id => $self->id);

            if (defined $data->{drive_state}{shift_state}) {
                last;
            }
        }

        if (! defined $data->{drive_state}{shift_state}) {
            $data->{drive_state}{shift_state} = 'U';
        }
    }

    return $data;
}
sub state {
    my ($self) = @_;
    $self->_online_check;
    return $self->data->{vehicle_state};
}
sub summary {
    return $_[0]->api(endpoint => 'VEHICLE_SUMMARY', id => $_[0]->id);
}
sub charge_state {
    my ($self) = @_;
    $self->_online_check;
    return $self->data->{charge_state};
}
sub climate_state {
    my ($self) = @_;
    $self->_online_check;
    return $self->data->{climate_state};
}
sub drive_state {
    my ($self) = @_;
    $self->_online_check;
    return $self->data->{drive_state};
}
sub vehicle_config {
    my ($self) = @_;
    $self->_online_check;
    return $self->data->{vehicle_config};
}

# Vehicle State Methods

sub dashcam {
    return $_[0]->data->{vehicle_state}{dashcam_state};
}
sub locked {
    return $_[0]->data->{vehicle_state}{locked};
}
sub online {
    my $status = $_[0]->summary->{state};
    return $status eq 'online' ? 1 : 0;
}
sub odometer {
    return $_[0]->data->{vehicle_state}{odometer};
}
sub sentry_mode {
    return $_[0]->data->{vehicle_state}{sentry_mode};
}
sub santa_mode {
    return $_[0]->data->{vehicle_state}{santa_mode};
}
sub trunk_front {
    return $_[0]->data->{vehicle_state}{rt};
}
sub trunk_rear {
    return $_[0]->data->{vehicle_state}{rt};
}
sub user_present {
    return $_[0]->data->{vehicle_state}{is_user_present};
}

# Drive State Methods

sub gear {
    return $_[0]->data->{drive_state}{shift_state};
}
sub gps_as_of {
    return $_[0]->data->{drive_state}{gps_as_of};
}
sub heading {
    return $_[0]->data->{drive_state}{heading};
}
sub latitude {
    return $_[0]->data->{drive_state}{latitude};
}
sub longitude {
    return $_[0]->data->{drive_state}{longitude};
}
sub power {
    return $_[0]->data->{drive_state}{power};
}
sub speed {
    return $_[0]->data->{drive_state}{speed} // 0;
}

# Charge State Methods

sub battery_level {
    return $_[0]->data->{charge_state}{battery_level};
}
sub charge_amps {
    return $_[0]->data->{charge_state}{charge_amps};
}
sub charge_actual_current {
    return $_[0]->data->{charge_state}{charge_actual_current};
}
sub charge_limit_soc {
    return $_[0]->data->{charge_state}{charge_limit_soc};
}
sub charge_limit_soc_std {
    return $_[0]->data->{charge_state}{charge_limit_soc_std};
}
sub charge_limit_soc_min {
    return $_[0]->data->{charge_state}{charge_limit_soc_min};
}
sub charge_limit_soc_max {
    return $_[0]->data->{charge_state}{charge_limit_soc_max};
}
sub charge_port_color {
    return $_[0]->data->{charge_state}{charge_port_color};
}
sub charger_voltage {
    return $_[0]->data->{charge_state}{charger_voltage};
}
sub charging_sites_nearby {
    my ($self) = @_;
    $self->_online_check;
    my $sites = $self->api(endpoint => 'NEARBY_CHARGING_SITES', id => $self->id);

    my $super_chargers = $sites->{superchargers};
    my $destination_chargers = $sites->{destination_charging};

    my %stations;

    my $cmp = 'distance_miles';

    for (sort { $a->{$cmp} <=> $b->{$cmp} } @$super_chargers) {
        next if $_->{available_stalls} == 0;
        push @{ $stations{super_chargers} }, $_;
    }

    for (sort { $a->{$cmp} <=> $b->{$cmp} } @$destination_chargers) {
        next if $_->{available_stalls} == 0;
        push @{ $stations{destination_chargers} }, $_;
    }

    return \%stations;
}
sub charging_state {
        return $_[0]->data->{charge_state}{charging_state};
    }
sub minutes_to_full_charge {
    return $_[0]->data->{charge_state}{minutes_to_full_charge};
}

# Climate State Methods

sub bioweapon_mode {
    return $_[0]->data->{climate_state}{bioweapon_mode};
}

sub defroster_front {
    return $_[0]->data->{climate_state}{front_defroster};
}
sub defroster_rear {
    return $_[0]->data->{climate_state}{rear_defroster};
}

sub fan_status {
    return $_[0]->data->{climate_state}{fan_status};
}

sub heater_battery {
    return $_[0]->data->{climate_state}{battery_heater};
}
sub heater_seat_driver {
    return $_[0]->data->{climate_state}{seat_heater_left};
}
sub heater_seat_passenger {
    return $_[0]->data->{climate_state}{seat_heater_right};
}
sub heater_side_mirrors {
    return $_[0]->data->{climate_state}{side_mirror_heaters};
}
sub heater_steering_wheel{
    return $_[0]->data->{climate_state}{steering_wheel_heater};
}
sub heater_wipers {
    return $_[0]->data->{climate_state}{outside_temp};
}

sub is_climate_on {
    return $_[0]->data->{climate_state}{is_climate_on};
}
sub is_air_conditioning_on {
    return $_[0]->data->{climate_state}{is_air_conditioning_on};
}

sub temperature_inside {
    return $_[0]->data->{climate_state}{inside_temp};
}
sub temperature_outside {
    return $_[0]->data->{climate_state}{outside_temp};
}
sub temperature_setting_driver {
    return $_[0]->data->{climate_state}{driver_temp_setting};
}
sub temperature_setting_passenger {
    return $_[0]->data->{climate_state}{passenger_temp_setting};
}

# Command Related Methods

sub charge_limit_set {
    my ($self, $percent) = @_;

    if (! defined $percent || $percent !~ /^\d+$/ || $percent > 100 || $percent < 1) {
        croak "charge_limit_set() requires a percent integer between 1 and 100";
    }

    $self->_online_check;

    my $return = $self->api(
        endpoint    => 'CHANGE_CHARGE_LIMIT',
        id          => $self->id,
        api_params  => { percent => $percent }
    );

    $self->api_cache_clear;

    if (! $return->{result} && $self->warn) {
        print "Couldn't set charge limit: '$return->{reason}'\n";
    }

    return $return->{result};
}

sub bioweapon_mode_toggle {
    my ($self) = @_;
    $self->_online_check;

    my $return = $self->api(endpoint => 'HVAC_BIOWEAPON_MODE', id => $self->id);

    $self->api_cache_clear;

    if (! $return->{result} && $self->warn) {
        print "Couldn't toggle bioweapon mode: '$return->{reason}'\n";
    }

    return $return->{result};
}
sub climate_on {
    my ($self) = @_;
    $self->_online_check;
    my $return = $self->api(endpoint => 'CLIMATE_ON', id => $self->id);

    $self->api_cache_clear;

    if (! $return->{result} && $self->warn) {
        print "Couldn't turn climate on: '$return->{reason}'\n";
    }

    return $return->{result};
}
sub climate_off {
    my ($self) = @_;
    $self->_online_check;

    my $return = $self->api(endpoint => 'CLIMATE_OFF', id => $self->id);

    $self->api_cache_clear;

    if (! $return->{result} && $self->warn) {
        print "Couldn't turn climate off: '$return->{reason}'\n";
    }

    return $return->{result};
}
sub climate_defrost_max {
    my ($self) = @_;
    $self->_online_check;

    my $return = $self->api(endpoint => 'MAX_DEFROST', id => $self->id);

    $self->api_cache_clear;

    if (! $return->{result} && $self->warn) {
        print "Couldn't enable the defroster: '$return->{reason}'\n";
    }

    return $return->{result};
}

sub doors_lock {
    my ($self) = @_;
    $self->_online_check;

    my $return = $self->api(endpoint => 'LOCK', id => $self->id);

    $self->api_cache_clear;

    if (! $return->{result} && $self->warn) {
        print "Couldn't lock the doors: '$return->{reason}'\n";
    }

    return $return->{result};
}
sub doors_unlock {
    my ($self) = @_;
    $self->_online_check;

    my $return = $self->api(endpoint => 'UNLOCK', id => $self->id);

    $self->api_cache_clear;

    if (! $return->{result} && $self->warn) {
        print "Couldn't unlock the doors: '$return->{reason}'\n";
    }

    return $return->{result};
}

sub horn_honk {
    my ($self) = @_;
    $self->_online_check;

    my $return = $self->api(endpoint => 'HONK_HORN', id => $self->id);

    if (! $return->{result} && $self->warn) {
        print "Couldn't honk the horn: '$return->{reason}'\n";
    }

    return $return->{result};
}

sub lights_flash {
    my ($self) = @_;
    $self->_online_check;

    my $return = $self->api(endpoint => 'FLASH_LIGHTS', id => $self->id);

    if (! $return->{result} && $self->warn) {
        print "Couldn't flash the exterior lights: '$return->{reason}'\n";
    }

    return $return->{result};
}

sub media_playback_toggle {
    my ($self) = @_;
    $self->_online_check;

    my $return = $self->api(endpoint => 'MEDIA_TOGGLE_PLAYBACK', id => $self->id);

    if (! $return->{result} && $self->warn) {
        print "Couldn't toggle audio playback: '$return->{reason}'\n";
    }

    return $return->{result};
}
sub media_track_next {
    my ($self) = @_;
    $self->_online_check;

    my $return = $self->api(endpoint => 'MEDIA_NEXT_TRACK', id => $self->id);

    if (! $return->{result} && $self->warn) {
        print "Couldn't skip to next audio track: '$return->{reason}'\n";
    }

    return $return->{result};
}
sub media_track_previous {
    my ($self) = @_;
    $self->_online_check;

    my $return = $self->api(endpoint => 'MEDIA_PREVIOUS_TRACK', id => $self->id);

    if (! $return->{result} && $self->warn) {
        print "Couldn't skip to previous audio track: '$return->{reason}'\n";
    }

    return $return->{result};
}
sub media_volume_down {
    my ($self) = @_;
    $self->_online_check;

    my $return = $self->api(endpoint => 'MEDIA_VOLUME_DOWN', id => $self->id);

    if (! $return->{result} && $self->warn) {
        print "Couldn't turn volume down: '$return->{reason}'\n";
    }

    return $return->{result};
}
sub media_volume_up {
    my ($self) = @_;
    $self->_online_check;

    my $return = $self->api(endpoint => 'MEDIA_VOLUME_UP', id => $self->id);

    if (! $return->{result} && $self->warn) {
        print "Couldn't turn volume up: '$return->{reason}'\n";
    }

    return $return->{result};
}

sub trunk_front_actuate {
    my ($self) = @_;

    $self->_online_check;

    my $return = $self->api(
        endpoint    => 'ACTUATE_TRUNK',
        id          => $self->id,
        api_params  => { which_trunk => 'front' }
    );

    $self->api_cache_clear;

    if (! $return->{result} && $self->warn) {
        print "Couldn't actuate front trunk: '$return->{reason}'\n";
    }

    return $return->{result};
}
sub trunk_rear_actuate {
    my ($self) = @_;

    $self->_online_check;

    my $return = $self->api(
        endpoint    => 'ACTUATE_TRUNK',
        id          => $self->id,
        api_params  => { which_trunk => 'rear' }
    );

    $self->api_cache_clear;

    if (! $return->{result} && $self->warn) {
        print "Couldn't actuate rear trunk: '$return->{reason}'\n";
    }

    return $return->{result};
}

sub wake {
    my ($self) = @_;

    if (! $self->online) {

        $self->api(endpoint => 'WAKE_UP', id => $self->id);

        my $wakeup_called_at = time;
        my $wake_interval = WAKE_INTERVAL;

        while (! $self->online) {
            select(undef, undef, undef, $wake_interval);
            if ($wakeup_called_at + WAKE_TIMEOUT - $wake_interval < time) {
                printf(
                    "\nVehicle with ID %d couldn't be woken up within %d " .
                    "seconds. Exiting...\n\n",
                    $self->id,
                    WAKE_TIMEOUT
                );
                exit;
            }
            $wake_interval *= WAKE_BACKOFF;
        }
    }
}

# Private Methods

sub _id {
    my ($self, $id) = @_;

    return $self->{data}{vehicle_id} if $self->{data}{vehicle_id};

    if (defined $id) {
        $self->{data}{vehicle_id} = $id;
    }
    else {
        my @vehicle_ids = keys %{$self->list};
        $self->{data}{vehicle_id} = $vehicle_ids[0];
    }

    return $self->{data}{vehicle_id} || -1;
}
sub _online_check {
    my ($self) = @_;

    if (DEBUG_ONLINE) {
        my $online = $self->online;
        printf "Vehicle is %s\n", $online ? 'ONLINE' : 'OFFLINE';
    }

    if (! $self->online) {
        if ($self->auto_wake) {
            $self->wake;
        }
        else {
            printf(
                "\nVehicle with ID %d is offline. Either wake it up with a call to " .
                    "wake(), or set 'auto_wake => 1' in your call to new()\n\n",
                $self->id
            );
            exit;
        }
    }
}

sub __placeholder{}

1;

=head1 NAME

Tesla::Vehicle - Access information and command Tesla automobiles via the API

=for html
<a href="https://github.com/stevieb9/tesla-vehicle/actions"><img src="https://github.com/stevieb9/tesla-vehicle/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/tesla-vehicle?branch=main'><img src='https://coveralls.io/repos/stevieb9/tesla-vehicle/badge.svg?branch=main&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Tesla::Vehicle;

    my $car = Tesla::Vehicle->new;

    $car->wake if ! $car->online;

    if ($car->locked) {
        $car->doors_unlock;
        $car->climate_on;

        if ($car->temperature_outside < 0) { # Freezing!
            $car->climate_defrost_max;
        }
    }

    printf(
        "%s is at %d%% charge, is moving %d MPH and is using %.2f kWh per mile\n",
        $car->name,
        $car->battery_level,
        $car->speed,
        $car->power
    );

=head1 DESCRIPTION

This distribution provides methods for accessing and updating aspects of your
Tesla vehicle. Not all attributes available through Tesla's API have methods
listed here yet, but more will be added as time goes on.

To access attributes that we don't have methods for, see the
L</AGGREGATE DATA METHODS> section, pull that data, then extract out the info
you want. If we don't have an aggregate data method for something you want yet,
see L<Tesla::API> to be able to get this yourself.

As always, requests for updates to my software is encouraged. Please just open
an L<issue|https://github.com/stevieb9/tesla-vehicle/issues>.

=head1 IMPORTANT

The parent module L<Tesla::API> that we inherit the Tesla API access code from
has a complex caching mechanism in place that you ought to know about. Please do
read through the L<Tesla API Caching|Tesla::API/API CACHING> documentation.

=head1 OBJECT MANAGEMENT METHODS

=head2 new(%params)

Instantiates and returns a new L<Tesla::Vehicle> object. We subclass L<Tesla::API>
so there are several things inherited.

B<Parameters>:

All parameters are sent in as a hash. See the documentation for L<Tesla::API>
for further parameters that can be sent into this method.

    id

I<Optional, Integer>: The ID of the vehicle you want to associate this object
with. Most methods require this to be set. You can send it in after
instantiation by using the C<id()> method. If you don't know what the ID is,
you can instantiate the object, and dump the returned hashref from a call to
C<list()>.

As a last case resort, we will try to figure out the ID by ourselves. If we
can't, and no ID has been set, methods that require an ID will C<croak()>.

    auto_wake

I<Optional, Bool>: If set, we will automatically wake up your vehicle on calls
that require the car to be in an online state to retrieve data (via a call to
C<wake()>). If not set and the car is asleep, we will print a warning and exit.
You can set this after instantiation by a call to C<auto_wake()>.

I<Default>: False.

    api_cache_time

I<Optional, Integer>: The number of seconds to cache data returned from Tesla's
API.

I<Default>: 2

    warn

Enables or disables the warnings that we receive from Tesla if there's a failure
to execute one of the L</COMMAND METHODS>.

If enabled, we print these warnings to C<STDOUT>.

I<Optional, Bool>: True (C<1>) to enable, false (C<0>) to disable the warnings.

I<Default>: True

=head2 auto_wake($bool)

Informs this software if we should automatically wake a vehicle for calls that
require it online, and the vehicle is currently offline.

Send in a true value to allow us to do this.

I<Default>: False

=head2 warn($bool)

Enables or disables the warnings that we receive from Tesla if there's a failure
to execute one of the L</COMMAND METHODS>.

If enabled, we print these warnings to C<STDOUT>.

B<Parameters>:

    $bool

I<Optional, Bool>: True (C<1>) to enable, false (C<0>) to disable the warnings.

I<Default>: True

=head1 VEHICLE IDENTIFICATION METHODS

=head2 id($id)

Sets/gets your primary vehicle ID. If set, we will use this in all API calls
that require it.

B<Parameters>:

    $id

I<Optional, Integer>: The vehicle ID you want to use in all API calls that require
one. This can be set as a parameter in C<new()>. If you attempt an API call that
requires and ID and one isn't set, we C<croak()>.

If you only have a single Tesla vehicle registered under your account, we will
set C<id()> to that ID when you instantiate the object.

You can also have this auto-populated in C<new()> by sending it in with the
C<< id => $id >> parameter.

If you don't know the ID of the vehicle you want to use, make a call to
C<list()>, and it will return a hash reference where each key is a vehice ID, and
the value is the name you've assigned your vehicle.

=head2 name

Returns the name you associated with your vehicle under your Tesla account.

B<NOTE>:L</id($id)> must have already been set, either through the C<id()>
method, or in C<new()>.

=head2 list

Returns a hash reference of your listed vehicles. The key is the vehicle ID,
and the value is the name you've assigned to that vehicle.

Example:

    {
        1234567891011 => "Dream machine",
        1234567891012 => "Steve's Model S",
    }

=head1 VEHICLE SUMMARY METHODS

=head2 in_service

Returns a bool whether your vehicle is in service mode or not.

=head2 options

B<NOTE>: The Tesla API, since 2019, has been returning wrong information about
vehicle option codes, so do not trust them. For my Model X, I'm getting
returned option codes for a Model 3. Several people I've spoken to about the
issue see the same thing for their Model S.

Returns a hash reference of the options available on your vehicle. The key is
the option code, and the value is the option description.

    {
        'APH3' => 'Autopilot 2.5 Hardware',
        'RENA' => 'Region: North America',
        'MR31' => 'Uplevel Mirrors',
        'GLFR' => 'Final Assembly Fremont',
    }

=head2 vehicle_id

Returns an integer of Tesla's representation of the vehicle identification of
your vehicle. This is not the same as the ID you use to access the API.

=head2 vin

Returns an alpha-numeric string that contains the actual Vehicle Identification
Number of your vehicle. This value is located on a stamped plate on the driver's
side bottom on the outside of your windshield.

=head1 COMMAND METHODS

All command methods return a true value (C<1>)if the operation was successful,
and a false value (C<0>) if the command failed.

We will also print to C<STDOUT> the reason for the failure if one occurred.
This warning includes the message we received from Tesla.

You can disable these warnings from being displayed by sending in a false value
to C<warn()>, or instantiate the object with C<new(warn => 0)>.

Example warning:

    $vehicle->media_volume_up;

    # Output

    Couldn't turn volume up: 'user_not_present'

=head2 bioweapon_mode_toggle

Toggles the HVAC Bio Weapon mode on or off.

Returns true on success, false on failure.

=head2 climate_on

Turns the climate system on to whatever settings they last had.

Returns true on success.

Follow up with a call to C<is_climate_on()> to verify.

=head2 climate_off

Turns the climate system off.

Returns true on success.

Follow up with a call to C<is_climate_on()> to verify.

=head2 climate_defrost_max

Returns true if the call was successful, false otherwise.

=head2 doors_lock

Locks the car doors. Returns true on success.

Follow up with a call to C<locked()> to verify.

=head2 doors_unlock

Unlocks the car doors. Returns true on success.

Follow up with a call to C<locked()> to verify.

=head2 horn_honk

Honks the horn once. Returns true on success.

=head2 lights_flash

Flashes the exterior lights of the vehicle.

Returns true on success.

=head2 media_playback_toggle

Play/Pause the currently loaded audio in the vehicle.

Returns true on success, false on failure.

I<NOTE>: Most often reason for fail is "User Not Present".

=head2 media_track_next

Skips to the next audio track.

Returns true on success, false on failure.

I<NOTE>: Most often reason for fail is "User Not Present".

=head2 media_track_previous

Skips to the previous audio track.

Returns true on success, false on failure.

I<NOTE>: Most often reason for fail is "User Not Present".

=head2 media_volume_down

Turns down the audio volume by one notch.

Returns true on success, false on failure.

I<NOTE>: Most often reason for fail is "User Not Present".

=head2 media_volume_up

Turns up the audio volume by one notch.

Returns true on success, false on failure.

I<NOTE>: Most often reason for fail is "User Not Present".

=head2 charge_limit_set($percent)

Sets the limit in percent the battery can be charged to.

Returns true if the operation was successful, and false if not.

Follow up with a call to C<battery_level()>.

=head2 trunk_rear_actuate

Opens or closes the rear trunk.

Returns true if the operation was successful, and false if not.

You must give time for the trunk to shut before checking its status with the
C<trunk_rear()> call.

=head2 trunk_front_actuate

Opens or closes the rear trunk.

Returns true if the operation was successful, and false if not.

You must give time for the trunk to shut before checking its status with the
C<trunk_front()> call.

=head2 wake

Attempt to wake the vehicle up from sleep mode. Most method calls against this
object require the vehicle to be awake.

We don't return anything; the vehicle will be woken up, or it won't and your
next method call will fail.

By default, this software does not wake up the car automatically, it just
C<croak>s if the car isn't awake and you attempt something it can't do while
sleeping.

Set C<< auto_wake => 1 >> in C<new()> or C<auto_wake(1)> to allow us to
automatically wake the vehicle up.

=head1 AGGREGATE DATA METHODS

These methods aggregate all attributes of the vehicle that relate to a specific
aspect of the vehicle. Methods that allow access to individual attributes of
these larger aggregates are listed below. For example, C<charge_state()> will
return the C<battery_level> attribute, but so will C<battery_level()>. By using
the aggregate method, you'll have to fish that attribute out yourself.

=head2 data

Returns a hash reference containing all available API data that Tesla provides
for your vehicles.

C<croak()>s if you haven't specified a vehicle ID through C<new()> or C<id()>,
and we weren't able to figure one out automatically.

This data will be retained and re-used for a period of two (C<2>) seconds to
reduce API calls through the Tesla API. This timing can be overridden in the
C<new()> method by specifying the C<< refresh => $seconds >> parameter, or by
a call to the object's C<delay($seconds)> method.

I<Return>: Hash reference. Contains every attribute Tesla has available through
their API for their vehicles.

The data accessor methods listed below use this data, simply selecting out
individual parts of it.

=head2 summary

Returns an important list of information about your vehicle, and Tesla's API
access.

The most important piece of information is the vehicle's C<state>, which shows
whether the car is online or not. Other information includes C<in_service>,
C<vin>, the C<display_name> etc.

I<Return>: Hash reference.

=head2 state

Returns the C<vehicle_state> section of Tesla's vehicle data. This includes
things like whether the car is locked, whether there is media playing, the
odometer reading, whether sentry mode is enabled or not etc.

I<Return>: Hash reference.

=head2 charge_state

Returns information regarding battery and charging information of your vehicle.

I<Return>: Hash reference.

=head2 climate_state

Returns information regarding the climate state of the vehicle.

I<Return>: Hash reference.

=head2 drive_state

Returns the information about the operation of the vehicle.

I<Return>: Hash reference.

=head2 vehicle_config

Returns attributes related to the actual configuration of your vehicle.

I<Return>: Hash reference.

=head1 VEHICLE STATE ATTRIBUTE METHODS

=head2 dashcam

Returns a string of the state of the dashcam (eg. "Recording").

=head2 locked

Returns true if the doors are locked, false if not.

=head2 online

Returns true if the vehicle is online and ready to communicate, and false if

=head2 odometer

Returns the number of miles the vehicle is traveled since new, as a floating point
number.

=head2 sentry_mode

Returns a bool indicating whether the vehicle is in sentry mode or not.

=head2 santa_mode

Returns a bool whether the vehicle is in "Santa" mode or not.

=head2 trunk_front

Returns true if the front trunk (ie. Frunk) is open, and false if it's
closed.

=head2 trunk_rear

Returns true if the rear trunk is open, and false if it's closed.

=head2 user_present

Returns a bool indicating whether someone with a valid FOB key is in proximity
of the vehicle.

=head1 DRIVE STATE ATTRIBUTE METHODS

Retrieves information regarding the actual operation and location of the
vehicle.

=head2 gear

Returns a single alpha character representing the gear the vehicle is in.

One of C<P> for parked, C<N> for Neutral, C<D> for Drive and C<R> for reverse.

This value is very often retured as undefined by Tesla, so a custom value of
C<U> is returned if the Tesla API doesn't return a valid value after
C<API_RETRIES> attempts to get one.

=head2 gps_as_of

Returns an integer that is the timestamp that the GPS data was last refreshed
from the vehicle.

=head2 heading

Returns an integer between C<0> and C<360> which is the current compass
heading of the vehicle.

=head2 latitude

Returns a signed float of the current Latitude of the vehicle.

=head2 longitude

Returns a signed float of the current Longitude of the vehicle.

=head2 power

Returns a signed float that contains the current kWh (Kilowatt-hours) per mile
the car is currently consuming in its operation.

A negative value indicates that either the car is plugged in and charging, or
that the regenerative brakes are engaged and are replenishing the battery (eg.
the car is going downhill and the car is decelerating).

=head2 speed

Returns a float of the vehicle's speed in MPH.

=head1 CHARGE STATE ATTRIBUTE METHODS

=head2 battery_level

Returns an integer of the percent that the battery is charged to.

=head2 charge_amps

Returns a float indicating how many Amps the vehicle is set to draw through the
current charger connection.

=head2 charge_actual_current

Returns a float indicating how many Amps are actually being drawn through the
charger.

=head2 charge_limit_soc

Returns an integer stating what percentage of battery level you've indicated
the charging will be cut off at.

"soc" stands for "State of Charge"

=head2 charge_limit_soc_std

Returns an integer stating Tesla's default B<charge_limit_soc> is set to.

=head2 charge_limit_soc_min

Returns an integer stating what the minimum number you can set as the Charge
Limit SOC (C<charge_limit_soc>).

=head2 charge_limit_soc_max

Returns an integer stating what the maximum number you can set as the Charge
Limit SOC (C<charge_limit_soc>).

=head2 charge_port_color

Returns a string containing the color of the vehicle's charge port (eg. "Green
Flashing" etc).

=head2 charger_voltage

Returns a float containing the actual Voltage level that the charger is connected
through.

=head2 charging_sites_nearby

Returns a hash reference of arrays. The keys are C<super_chargers> and
C<destination_chargers>. Under each key is an array of charging station
details, each in a hash reference. The hash references are sorted in the
array as closest first, farthest last. All stations with no available stalls
have been removed. Each station has the following properties:

    {
        total_stalls     => 8,
        site_closed      => $VAR1->{'super_chargers'}[0]{'site_closed'},
        location => {
            long => '-119.429277',
            lat  => '49.885799'
        },
        name             => 'Kelowna, BC',
        type             => 'supercharger',
        distance_miles   => '26.259798',
        available_stalls => 4
    }

=head2 charging_state

Returns a string that identifies the state of the vehicle's charger. Eg.
"Disconnected", "Connected" etc.

=head2 minutes_to_full_charge

Returns an integer containing the estimated number of minutes to fully charge
the batteries, taking into consideration voltage level, Amps requested and
drawn etc.

=head1 CLIMATE STATE ATTRIBUTE METHODS

=head2 bioweapon_mode

Yes, this is truly a thing. At least my Tesla vehicle has a mode that seals the
vehicle from all outside air, and puts positive pressure inside the cabin to
ensure that no contaminents can enter the vehicle.

This method returns a bool to indicate whether this mode is enabled or not.

=head2 defroster_front

Is the front windshield defroster on or not

=head2 defroster_rear

Is the rear window defroster on or not.

=head2 fan_status

Returns an integer that represents the climate fan speed.

=head2 heater_battery

Is the battery warmer on or not.

=head2 heater_seat_driver

Is the driver's seat warmer on.

=head2 heater_seat_passenger

Is the passenger's seat warmer on.

=head2 heater_side_mirrors

Is the wing mirror heater on.

=head2 heater_steering_wheel

Is the steering wheel warmer on or not

=head2 heater_wipers

Is the windshield wiper warmer on.

=head2 is_climate_on

Is the climate system currently active.

=head2 is_air_conditioning_on

Is the air conditioning unit active.

=head2 temperature_inside

The current temperature inside of the vehicle cabin.

=head2 temperature_outside

The temperature outside of the vehicle.

=head2 temperature_setting_driver

What the driver's side temperature setting is set to.

=head2 temperature_setting_passenger

What the passenger's side temperature setting is set to.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

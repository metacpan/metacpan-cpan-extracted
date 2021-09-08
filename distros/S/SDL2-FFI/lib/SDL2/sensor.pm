package SDL2::sensor 0.01 {
    use SDL2::Utils;
    #
    use SDL2::stdinc;
    use SDL2::error;

    package SDL2::Sensor {
        use SDL2::Utils;
        our $TYPE = has();
    };
    ffi->type( 'sint32' => 'SDL_SensorID' );
    enum SDL_SensorType => [
        [ SDL_SENSOR_INVALID => -1 ], qw[SDL_SENSOR_UNKNOWN
            SDL_SENSOR_ACCEL
            SDL_SENSOR_GYRO]
    ];
    define sensor => [ [ SDL_STANDARD_GRAVITY => 9.80665 ] ];
    attach sensor => {
        SDL_LockSensors                    => [ [] ],
        SDL_UnlockSensors                  => [ [] ],
        SDL_NumSensors                     => [ [],               'int' ],
        SDL_SensorGetDeviceName            => [ ['int'],          'string' ],
        SDL_SensorGetDeviceType            => [ ['int'],          'SDL_SensorType' ],
        SDL_SensorGetDeviceNonPortableType => [ ['int'],          'int' ],
        SDL_SensorGetDeviceInstanceID      => [ ['int'],          'SDL_SensorID' ],
        SDL_SensorOpen                     => [ ['int'],          'SDL_Sensor' ],
        SDL_SensorFromInstanceID           => [ ['SDL_SensorID'], 'SDL_Sensor' ],
        SDL_SensorGetName                  => [ ['SDL_Sensor'],   'string' ],
        SDL_SensorGetType                  => [ ['SDL_Sensor'],   'SDL_SensorType' ],
        SDL_SensorGetNonPortableType       => [ ['SDL_Sensor'],   'int' ],
        SDL_SensorGetInstanceID            => [ ['SDL_Sensor'],   'SDL_SensorID' ],
        SDL_SensorGetData                  => [ [ 'SDL_Sensor', 'float*', 'int' ], 'int' ],
        SDL_SensorClose                    => [ ['SDL_Sensor'] ],
        SDL_SensorUpdate                   => [ [] ],
    };

=encoding utf-8

=head1 NAME

SDL2::sensor - SDL Sensor Event Handling

=head1 SYNOPSIS

    use SDL2 qw[:sensor];

=head1 DESCRIPTION

In order to use these functions, C<SDL_Init( ... )> must have been called with
the C<SDL_INIT_SENSOR> flag.  This causes SDL to scan the system for sensors,
and load appropriate drivers.

=head1 Functions

You may import these by name or with the C<:sensor> tag.

=head2 C<SDL_LockSensors( )>

Locking for multi-threaded access to the sensor API.

If you are using the sensor API or handling events from multiple threads you
should use these locking functions to protect access to the sensors.

In particular, you are guaranteed that the sensor list won't change, so the API
functions that take a sensor index will be valid, and sensor events will not be
delivered.

=head2 C<SDL_UnlockSensors( )>

Unlocking for multi-threaded access to the sensor API

If you are using the sensor API or handling events from multiple threads you
should use these locking functions to protect access to the sensors.

In particular, you are guaranteed that the sensor list won't change, so the API
functions that take a sensor index will be valid, and sensor events will not be
delivered.

=head2 C<SDL_NumSensors( )>

Count the number of sensors attached to the system right now.

Returns the number of sensors detected.

=head2 C<SDL_SensorGetDeviceName( ... )>

Get the implementation dependent name of a sensor.

Expected parameters include:

=over

=item C<device_index> - the sensor to obtain name from

=back

Returns The sensor name, or C<undef> if C<device_index> is out of range.

=head2 C<SDL_SensorGetDeviceType( ... )>

Get the type of a sensor.

Expected parameters include:

=over

=item C<device_index> - the sensor to get the type from

=back

Returns the C<SDL_SensorType>, or C<SDL_SENSOR_INVALID> if C<device_index> is
out of range.

=head2 C<SDL_SensorGetDeviceNonPortableType( ... )>

Get the platform dependent type of a sensor.

Expected parameters include:

=over

=item C<device_index> - the sensor to check

=back

Returns the sensor platform dependent type, or C<-1> if C<device_index> is out
of range.

=head2 C<SDL_SensorGetDeviceInstanceID( ... )>

Get the instance ID of a sensor.

Expected parameters include:

=over

=item C<device_index> - the sensor to get instance id from

=back

Returns the sensor instance ID, or C<-1> if C<device_index> is out of range.

=head2 C<SDL_SensorOpen( ... )>

Open a sensor for use.

Expected parameters include:

=over

=item C<device_index> - the sensor to open

=back

Returns an L<SDL2::Sensor> sensor object, or C<undef> if an error occurred.

=head2 C<SDL_SensorFromInstanceID( ... )>

Return the SDL_Sensor associated with an instance id.

Expected parameters include:

=over

=item C<instance_id> - the sensor from instance id

=back

Returns an L<SDL2::Sensor> object.

=head2 C<SDL_SensorGetName( ... )>

Get the implementation dependent name of a sensor

Expected parameters include:

=over

=item C<sensor> - the L<SDL2::Sensor> object

=back

Returns the sensor name, or C<undef> if C<sensor> is C<undef>.

=head2 C<SDL_SensorGetType( ... )>
/**
 * Get the type of a sensor.

Expected parameters include:

=over

=item C<sensor> - the L<SDL2::Sensor> object to inspect

=back

Returns the C<SDL_SensorType> type, or C<SDL_SENSOR_INVALID> if C<sensor> is
C<undef>.

=head2 C<SDL_SensorGetNonPortableType( ... )>

Get the platform dependent type of a sensor.

Expected parameters include:

=over

=item C<sensor> - the L<SDL2::Sensor> object to inspect

=back

Returns the sensor platform dependent type, or C<-1> if C<sensor> is C<undef>.

=head2 C<SDL_SensorGetInstanceID( ... )>

Get the instance ID of a sensor.

Expected parameters include:

=over

=item C<sensor> - the L<SDL2::Sensor> object to inspect

=back

Returns the sensor instance ID, or C<-1> if C<sensor> is C<undef>.

=head2 C<SDL_SensorGetData( ... )>

Get the current state of an opened sensor.

The number of values and interpretation of the data is sensor dependent.

Expected parameters include:

=over

=item C<sensor> - the L<SDL2::Sensor> object to query

=item C<data> - a pointer filled with the current sensor state

=item C<num_values> - the number of values to write to data

=back

Returns C<0> or C<-1> if an error occurred.

=head2 C<SDL_SensorClose( ... )>

Close a sensor previously opened with L<< C<SDL_SensorOpen( ...
)>|/C<SDL_SensorOpen( ... )> >>.

Expected parameters include:

=over

=item C<sensor> - the L<SDL2::Sensor> object to close

=back

=head2 C<SDL_SensorUpdate( )>

Update the current state of the open sensors.

This is called automatically by the event loop if sensor events are enabled.

This needs to be called from the thread that initialized the sensor subsystem.

=head1 Defined Types, Values, and Enumerations

These may be imported by name or with the C<:sensor> tag.

=head2 C<SDL_SensorID>

This is a unique ID for a sensor for the time it is connected to the system,
and is never reused for the lifetime of the application.

The ID value starts at C<0> and increments from there. The value C<-1> is an
invalid ID.

=head2 C<SDL_SensorType>

The different sensors defined by SDL.

Additional sensors may be available, using platform dependent semantics.

Here are the additional Android sensors:
L<https://developer.android.com/reference/android/hardware/SensorEvent.html#values>

=over

=item C<SDL_SENSOR_INVALID> - Returned for an invalid sensor

=item C<SDL_SENSOR_UNKNOWN> - Unknown sensor type

=item C<SDL_SENSOR_ACCEL> - Accelerometer

=item C<SDL_SENSOR_GYRO> - Gyroscope

=back

=head2 C<SDL_STANDARD_GRAVITY>

This is the standard value for gravitational acceleration.

=head1 Accelerometer Sensor

The accelerometer returns the current acceleration in SI meters per second
squared. This measurement includes the force of gravity, so a device at rest
will have an value of C<SDL_STANDARD_GRAVITY> away from the center of the
earth.

    values[0]: Acceleration on the x axis
    values[1]: Acceleration on the y axis
    values[2]: Acceleration on the z axis

For phones held in portrait mode and game controllers held in front of you, the
axes are defined as follows:

    -X ... +X : left    ... right
    -Y ... +Y : bottom  ... top
    -Z ... +Z : farther ... closer

The axis data is not changed when the phone is rotated.

=head1 Gyroscope Sensor

The gyroscope returns the current rate of rotation in radians per second. The
rotation is positive in the counter-clockwise direction. That is, an observer
looking from a positive location on one of the axes would see positive rotation
on that axis when it appeared to be rotating  counter-clockwise.

	values[0]: Angular speed around the x axis (pitch)
	values[1]: Angular speed around the y axis (yaw)
	values[2]: Angular speed around the z axis (roll)

For phones held in portrait mode and game controllers held in front of you, the
axes are defined as follows:

	-X ... +X : left    ... right
	-Y ... +Y : bottom  ... top
	-Z ... +Z : farther ... closer

The axis data is not changed when the phone or controller is rotated.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

=end stopwords

=cut

};
1;

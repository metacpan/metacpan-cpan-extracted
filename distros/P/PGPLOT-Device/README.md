# NAME

PGPLOT::Device - autogenerate PGPLOT device names

# VERSION

version 0.13

# SYNOPSIS

    use PGPLOT::Device;

    $device = PGPLOT::Device->new( $spec );
    $device = PGPLOT::Device->new( \%specs );

    # straight PGPLOT
    pgbegin( 0, $device, 1, 1);

    # PDL
    $win = PDL::Graphics::PGPLOT::Window->new({ Device => $device} );

# DESCRIPTION

**Note!**  It's much easier to use [PGPLOT::Device::PGWin](https://metacpan.org/pod/PGPLOT%3A%3ADevice%3A%3APGWin)
instead of using PGPLOT::Device directly. It handles much of the
complexity of dealing with interactive devices.

It is sometimes surprisingly difficult to create an appropriate PGPLOT
device.  Coding for both interactive and hardcopy devices can lead to
code which repeatedly has to check the device type to generate the
correct device name.  If an application outputs multiple plots, it
needs to meld unique names (usually based upon the output format) to
the user's choice of output device.  The user should be given some
flexibility in specifying a device or hardcopy filename output
specification without making life difficult for the developer.

This module tries to help reduce the agony.  It does this by creating
an object which will resolve to a legal PGPLOT device specification.
The object can handle auto-incrementing of interactive window ids,
interpolation of variables into file names, automatic generation of
output suffices for hardcopy devices, etc.

Here's the general scheme:

- The application creates the object, using the user's PGPLOT device
specification to initialize it.
- Before creating a new plot, the application specifies the output
filename it would like to have.  The filename may use interpolated
variables.  This is ignored if the device is interactive, as it is
meaningless in that context
- Each time that the object value is retrieved using the `next()`
method, the internal window id is incremented, any variables in the
filename are interpolated, and the result is returned.

## Interactive devices

Currently, the `/xs` and `/xw` devices are recognized as being
interactive.  PGPLOT allows more than one such window to be displayed;
this is accomplished by preceding the device name with an integer id,
e.g. `2/xs`.  If a program generates several independent plots, it can
either prompt between overwriting plots in a single window, or it may
choose to use multiple plotting windows.  This module assists in the
latter case by implementing auto-increment of the window id.  The
device specification syntax is extended to `+N/xs` where `N` is an
integer indicating the initial window id.

## Hardcopy devices

Hardcopy device specifications (i.e. not `/xs` or `/xw`) are
specified as `filename/device`.  The filename is optional, and will
automatically be given the extension appropriate to the output file
format.  If a filename is specified in the specification passed to the
**new** method, it cannot be overridden.  This allows the user to
specify a single output file for all hardcopy plots.  This works well
for PostScript, which can handle multiple pages per file, but for the
PNG device, this results in multiple output files with numbered
suffices.  It's not pretty!  This module needs to be extended so it
knows if a single output file can handle more than one page.

Variables may be interpolated into the filenames using the
`${variable}` syntax (curly brackets are required).  Note that only
simple scalars may be interpolated (not hash or array elements). The
values may be formatted using **sprintf** by appending the format, i.e.
`${variable:format}`.  Variables which are available to be
interpolated are either those declared using **our**, or those passed
into the class constructor.

The  internal counter which tracks the number of times the device object has
been used is available as `${devn}`.

# METHODS

## new

    $dev = PGPLOT::Device->new( $spec, \%opts );

This constructs a new object.  **$spec** is the PGPLOT device
specification, with the following allowed representations:

- _/device_

    This results in the default PGPLOT behavior for the device.

- _N/device_

    N is an integer.  This resolves to a constant output device. Usually
    _device_ is `/xw` or `/xs`.

- _+N/device_

    N is an integer.  Each plot will be went to a device with a different
    device id.  The initial id is `N` and subsequent ids are
    auto-incremented from the last.  Usually _device_ is `/xw` or
    `/xs`.

- _filename/device_

    _filename_ is an output file name.  Its format is as described in
    ["Hardcopy devices"](#hardcopy-devices).  An extension will be automatically added, if
    required.

The `%opts` hash is available to pass other options to the
constructor.  These are:

- vars

    This is a hashref containing values to be interpolated into filenames.
    **PGPLOT::Device** dereferences the hashref at interpolation time, so
    will track any changes made by the application.   For example:

        my %vars;
        $dev = PGPLOT::Device->new( "foo${a}${b}/ps",
                                    { vars => \%vars } );

        $vars{a} = 3;
        $vars{b} = 4;

        print $dev->next, "\n";

    will result in `foo34.ps`.  Additionally, if the values are scalar
    references, they will be dereferenced.  This way the application is
    not forced to use a hash for its internal use:

        my ( $a, $b );
        my %vars = ( a => \$a, b => \$b )

        $dev = PGPLOT::Device->new( "foo${a}${b}/ps",
                                     { vars => \%vars } );

        $a = 3;
        $b = 4;
        print $dev->next, "\n";

    will also result in `foo34.ps`.

- ask

    Whether the user should be prompted after each plot.

    If not specified, the user is prompted if

    - the device is interactive; and
    - the device id is constant.

    Set to a true or false value to override the automatic configuration.

## override

    $dev->override( $filename, \%opts );

This method is used to override the initial values of `$filename`
passed to the **new()** method for non-interactive devices.  This
allows the user control over the interactive device, but gives
the application more control over hardcopy destinations.

Note that **$filename** may include a PGPLOT device specification,
which will override any specified earlier, but this is frowned upon.

It takes the same options as does the **new()** method.

## devn

    $devn = $dev->devn;
    $dev->devn( $new_value);

This is an accessor which retrieves and/or sets the device number for
interactive devices.

## ask

    if ( $device->ask ) { .. }

This is true if the device is interactive and constant, so that
new plots erase old plots.  This can be used with the **pgask()**
PGPLOT subroutine to ensure that the user will see all of the plots.
See ["EXAMPLES"](#examples).

## next

    $dev_str = $dev->next;

This method is the basis for the automatic updating of the device
specification when the object is used as a string.  If desired it may
 be used directly.  It will return the next device specification. It
increments the device number.

## current

    $dev_str = $dev->current;

This returns the device string which would be generated in the current
environment.  It does not alter the environment.

## last

    $dev_str = $dev->current;

This returns the last generated device string.  It does not alter the
environment.

## is\_const

    if ( $dev->is_const ) { ... }

This method returns true if the device specification does not
interpolate any variables or device numbers.

## would\_change

    if ( $dev->would_change ) { ... }

This method returns true if the last generated device specification
would differ from one generated with the current environment. It
returns true if no device specification has yet been generated.

It does not change the current environment.

## is\_interactive

    if ( $dev->is_interactive ) { ... }

This method returns true if the device is an interactive device.

## is\_ephemeral

    if ( $dev->is_ephemeral ) { ... }

This method returns true if the plot display will disappear if the
device is closed (e.g., the `/xw` device ).

# EXAMPLES

- Here's the prototypical example.  The application outputs multiple
plots and the user is allowed to specify an output device.  The device
is initialized directly from the user's input:

        $device = PGPLOT::Device->new( $user_device_spec );

    Before each call to `pgbegin` or `PDL::G::P::Window-`new>, indicate
    via the **override** method the new hardcopy filename, without any
    suffix.  The filename will be ignored if the user has specified an
    interactive device:

        $device->override( 'out_${theta:%05.2f}' );

    Use **next()** to retrieve the value:

        pgbegin( 0, $device->next, 1, );
        $win = PDL::Graphics::PGPLOT::Window->new({ Device => $device->next} );

- The application outputs multiple plots, and the user should be able to
decide whether a single interactive device window should be used, or
whether multiple ones should be used.  In the first instance, the user
specifies the device as `/xs`, in the second `+/xs` or `+1/xs`:

        $device = PGPLOT::Device->new( $user_device_spec );

        $device->override( 'hardcopy-${vara}-${varb}' );

        $win = PDL::Graphics::PGPLOT::Window->new({ Device => $device->next} );

        [... generate plot 1 ... ]

        # do this after generating the plot, because Window
        # be constant, and that'll confuse is_const()
        pgask( $device->ask );

        # next plot.

        if ( $device->would_change )
        {
          $win->close;
          $win = PDL::Graphics::PGPLOT::Window->new({ Device => $device->next} );
        }

        # etc.

        # make sure that the user is prompted before the device is closed
        # if the device will disappear.
        pgask( 1 ) if $device->ephemeral;
        $win->close;

    Note that **would\_change()** will return true if no specification has
    yet been generated.  This allows one to simplify coding if plots
    are generated within loops:

        my $win;

        my %vars;
        my $device = PGPLOT::Device->new( $user_device_spec );
        $device->override( 'file-${a}-${b}', { vars => \%vars } );
        my $not_first = 0;
        for my $plot ( @plots )
        {
          $vars{a} = $plot->{a};
          $vars{b} = $plot->{b};

          # prompt user before displaying second and subsequent plots if
          # a new plot will erase the previous one
          pgask( $param{device}->ask ) if $not_first++;

          if ( $device->would_change )
          {
            $win->close if defined $win;
            $win = PDL::Graphics::PGPLOT::Window->new({ Device => $device->next} );
          }

          [... plot stuff ...]
        }

        if ( defined $win )
        {
         # make sure that the plot stays up until the user is done with it
         pgask(1) if $device->ephemeral;
         $win->close;
        }

# SUPPORT

## Bugs

Please report any bugs or feature requests to bug-pgplot-device@rt.cpan.org  or through the web interface at: [https://rt.cpan.org/Public/Dist/Display.html?Name=PGPLOT-Device](https://rt.cpan.org/Public/Dist/Display.html?Name=PGPLOT-Device)

## Source

Source is available at

    https://gitlab.com/djerius/pgplot-device

and may be cloned from

    https://gitlab.com/djerius/pgplot-device.git

# SEE ALSO

Please see those modules/websites for more information related to this module.

- [PGPLOT](https://metacpan.org/pod/PGPLOT)
- [PDL](https://metacpan.org/pod/PDL)
- [PDL::Graphics::PGPLOT::Window](https://metacpan.org/pod/PDL%3A%3AGraphics%3A%3APGPLOT%3A%3AWindow)

# AUTHOR

Diab Jerius <djerius@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007

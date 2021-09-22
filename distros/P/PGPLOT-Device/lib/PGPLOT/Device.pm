package PGPLOT::Device;

# ABSTRACT: autogenerate PGPLOT device names

use strict;
use warnings;

our $VERSION = '0.12';


our %Default = ( device => 'xs', );

our $ephemeral = qr{^xw$};
our $NDevices;
our %PGDevice;
our %DevMap;

sub _croak {
    require Carp;
    goto \&Carp::croak;
}








































































sub new {
    my $class = shift;

    _class_init();

    my $self = {
        devn => 1,
        last => undef,
        vars => {} };
    bless $self, $class;

    $self->_initialize( @_ );

    # need to keep track of whether there was an initial prefix
    $self->{init_prefix} = defined $self->{prefix};

    $self;
}

sub _class_init {
    return if $NDevices;

    require PGPLOT;
    PGPLOT::pgqndt( $NDevices );

    my @devices;

    for my $didx ( 1 .. $NDevices ) {
        my ( $type, $tlen, $descr, $dlen, $inter );
        PGPLOT::pgqdt( $didx, $type, $tlen, $descr, $dlen, $inter );
        $type =~ s{/}{};
        $PGDevice{ lc $type } = {
            idx   => $didx,
            type  => lc( $type ),
            tlen  => $tlen,
            descr => $descr,
            dlen  => $dlen,
            inter => $inter,
        };

        push @devices, lc $type;
    }

    require Text::Abbrev;
    Text::Abbrev::abbrev( \%DevMap, @devices );
}


sub _initialize {
    my $opts = 'HASH' eq ref $_[-1] ? pop @_ : {};

    my ( $self, $spec ) = @_;

    my %spec = defined $spec ? $self->_parse_spec( $spec ) : ();

    # don't allow an override to change the device
    delete $spec{device} if defined $self->{device};

    # don't allow an override to change an initial prefix
    delete $spec{prefix} if $self->{init_prefix};

    # fill the object
    $self->{$_} = $spec{$_} for keys %spec;

    unless ( defined $self->{device} ) {
        $self->{device}  = $Default{device};
        $self->{devinfo} = $PGDevice{ $DevMap{ $Default{device} } };
    }

    if ( exists $opts->{vars} ) {
        _croak( "vars attribute must be a hash\n" )
          unless 'HASH' eq ref $opts->{vars};

        $self->{vars} = $opts->{vars};
    }


    $self->{ask} = $self->is_interactive && $self->is_const;


    $self;
}

















sub override {
    my $self = shift;

    if ( !$self->is_interactive() ) {
        $self->_initialize( @_ );
    }

    $self;
}











sub devn {
    my $self = shift;
    my $old  = $self->{devn};
    $self->{devn} = shift if @_;

    $old;
}












sub ask { $_[0]->{ask} }


sub _parse_spec {
    my ( $self, $spec ) = @_;
    my ( $prefix, $device );
    my %spec;


    # split into prefix and /device.  set to prefix only, if no match,
    # as that'll be the case if no device was specified.
    $prefix = $spec
      if 0 == ( ( $prefix, $device ) = $spec =~ m{(.*)/([^/]+)$} );


    # be careful that a multi-directory path (dir/prefix) doesn't get
    # translated into file/device.  If /prefix looks like a real PGPLOT
    # device, this will fail horribly.

    # if there's already a device, discard /device if it looks like
    # a PGPLOT device, else append it to prefix.

    # if there's not already a device, /device had better look like
    # a PGPLOT device.

    if ( defined $device && !exists $DevMap{ lc $device } ) {
        if ( defined $self->{device} ) {
            $prefix .= '/' . $device;
            undef $device;
        }

        # no pre-existing device.  make sure that the device is a real one
        else {
            _croak( "unknown PGPLOT device: $device\n" );
        }
    }

    # if device isn't defined, use the existing one for the object
    $spec{device}  = defined $device ? lc( $device ) : $self->{device};
    $spec{devinfo} = $PGDevice{ $DevMap{ $spec{device} } };
    $spec{prefix}  = $prefix;

    if ( $prefix ) {
        # numeric (possibly autoincrement)
        if ( $prefix =~ /^([+])?(\d+)?$/ ) {
            $spec{devn} = defined $2 ? $2 : 1;

            # if +, autoincrement device number
            # we use interpolation to handle this case
            $spec{prefix} = defined $1 ? '${devn}' : $2;
        }

        elsif ( defined $spec{device} ) {
            if ( !$spec{devinfo}{inter} ) {
                my $ext
                  = ( $spec{device} =~ m{^v?c?(ps)$}i )
                  ? ".$1"
                  : '.' . $spec{device};

                # make sure the appropriate suffix is in there
                $prefix =~ s/${ext}$//;
                $prefix .= $ext;
                $spec{prefix} = $prefix;
            }

         # we've got a situation here. an interactive device with a nonparseable
         # prefix.  better bail
            else {
                _croak(
                    "error: interactive device with unparseable prefix: $spec\n"
                );
            }
        }
    }

    # only defined keys get through. makes it easier to override
    # things
    delete $spec{$_}
      for grep { !defined $spec{$_} || '' eq $spec{$_} } keys %spec;

    %spec;
}












sub next {
    my $self = shift;

    $self->{last} = $self->_stringify;
    $self->{devn}++;
    $self->{last};
}










sub current {
    my $self = shift;

    $self->_stringify;
}










sub last {
    my $self = shift;
    $self->{last};
}

sub _compare {
    my ( $self, $other, $reverse ) = @_;

    $reverse ? $other cmp $self->_stringify : $self->_stringify cmp $other;
}










sub is_const {
    my $self = shift;
    defined $self->{prefix}
      ? ( $self->_stringify eq $self->{prefix} . '/' . $self->{device} )
      : 1;
}













sub would_change {
    my $self = shift;

    return defined $self->{last} ? $self->_stringify ne $self->{last} : 1;
}









sub is_interactive {
    my $self = shift;

    $self->{devinfo}{inter};
}










sub is_ephemeral {
    my $self = shift;
    $self->{device} =~ /$ephemeral/;
}


sub _stringify {
    my $self = shift;

    # handle interpolated values
    my $prefix = defined $self->{prefix} ? $self->{prefix} : '';

    # get calling package

    my ( $fmt, $val );

    ## no critic ( ProhibitNoStrict );
    no strict 'refs';
    my $pkg = ( caller( 1 ) )[0];
    1 while $prefix =~ s/ \$\{ (\w+) (?::([^\}]+))? } /
        $fmt = defined $2 ? $2 : '%s';

        $val =

        # special: device id
           $1 eq 'devn' ? $self->{devn} :

        # part of the user passed set of variables?
           exists $self->{vars}{$1} ?

        # dereference it if it's a scalar ref, else use it directly
        ( 'SCALAR' eq ref $self->{vars}{$1} ?
          ${$self->{vars}{$1}} : $self->{vars}{$1} ) :

        # is it in the parent package?
          defined ${*{"${pkg}::$1"}{SCALAR}} ? ${*{"${pkg}::$1"}{SCALAR}} :

        # nothing
          undef;

        sprintf( $fmt, $val ) if defined $val;
  /ex;

    $prefix . '/' . $self->{device};
}

1;

#
# This file is part of PGPLOT-Device
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

PGPLOT::Device - autogenerate PGPLOT device names

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use PGPLOT::Device;

  $device = PGPLOT::Device->new( $spec );
  $device = PGPLOT::Device->new( \%specs );

  # straight PGPLOT
  pgbegin( 0, $device, 1, 1);

  # PDL
  $win = PDL::Graphics::PGPLOT::Window->new({ Device => $device} );

=head1 DESCRIPTION

B<Note!>  It's much easier to use L<PGPLOT::Device::PGWin>
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

=over

=item *

The application creates the object, using the user's PGPLOT device
specification to initialize it.

=item *

Before creating a new plot, the application specifies the output
filename it would like to have.  The filename may use interpolated
variables.  This is ignored if the device is interactive, as it is
meaningless in that context

=item *

Each time that the object value is retrieved using the C<next()>
method, the internal window id is incremented, any variables in the
filename are interpolated, and the result is returned.

=back

=head2 Interactive devices

Currently, the C</xs> and C</xw> devices are recognized as being
interactive.  PGPLOT allows more than one such window to be displayed;
this is accomplished by preceding the device name with an integer id,
e.g. C<2/xs>.  If a program generates several independent plots, it can
either prompt between overwriting plots in a single window, or it may
choose to use multiple plotting windows.  This module assists in the
latter case by implementing auto-increment of the window id.  The
device specification syntax is extended to C<+N/xs> where C<N> is an
integer indicating the initial window id.

=head2 Hardcopy devices

Hardcopy device specifications (i.e. not C</xs> or C</xw>) are
specified as C<filename/device>.  The filename is optional, and will
automatically be given the extension appropriate to the output file
format.  If a filename is specified in the specification passed to the
B<new> method, it cannot be overridden.  This allows the user to
specify a single output file for all hardcopy plots.  This works well
for PostScript, which can handle multiple pages per file, but for the
PNG device, this results in multiple output files with numbered
suffices.  It's not pretty!  This module needs to be extended so it
knows if a single output file can handle more than one page.

Variables may be interpolated into the filenames using the
C<${variable}> syntax (curly brackets are required).  Note that only
simple scalars may be interpolated (not hash or array elements). The
values may be formatted using B<sprintf> by appending the format, i.e.
C<${variable:format}>.  Variables which are available to be
interpolated are either those declared using B<our>, or those passed
into the class constructor.

The  internal counter which tracks the number of times the device object has
been used is available as C<${devn}>.

=head1 METHODS

=head2 new

  $dev = PGPLOT::Device->new( $spec, \%opts );

This constructs a new object.  B<$spec> is the PGPLOT device
specification, with the following allowed representations:

=over

=item I</device>

This results in the default PGPLOT behavior for the device.

=item I<N/device>

N is an integer.  This resolves to a constant output device. Usually
I<device> is C</xw> or C</xs>.

=item I<+N/device>

N is an integer.  This will create a device which
autoincrements. Usually I<device> is C</xw> or C</xs>.

=item I<filename/device>

I<filename> is an output file name.  Its format is as described in
L</Hardcopy devices>.  An extension will be automatically added, if
required.

=back

The C<%opts> hash is available to pass other options to the
constructor.  These are:

=over

=item vars

This is a hashref containing values to be interpolated into filenames.
B<PGPLOT::Device> dereferences the hashref at interpolation time, so
will track any changes made by the application.   For example:

  my %vars;
  $dev = PGPLOT::Device->new( "foo${a}${b}/ps",
                              { vars => \%vars } );

  $vars{a} = 3;
  $vars{b} = 4;

  print $dev->next, "\n";

will result in C<foo34.ps>.  Additionally, if the values are scalar
references, they will be dereferenced.  This way the application is
not forced to use a hash for its internal use:

  my ( $a, $b );
  my %vars = ( a => \$a, b => \$b )

  $dev = PGPLOT::Device->new( "foo${a}${b}/ps",
                               { vars => \%vars } );

  $a = 3;
  $b = 4;
  print $dev->next, "\n";

will also result in C<foo34.ps>.

=back

=head2 override

  $dev->override( $filename, \%opts );

This method is used to override the initial values of C<$filename>
passed to the B<new()> method for non-interactive devices.  This
allows the user control over the interactive device, but gives
the application more control over hardcopy destinations.

Note that B<$filename> may include a PGPLOT device specification,
which will override any specified earlier, but this is frowned upon.

It takes the same options as does the B<new()> method.

=head2 devn

  $devn = $dev->devn;
  $dev->devn( $new_value);

This is an accessor which retrieves and/or sets the device number for
interactive devices.

=head2 ask

  if ( $device->ask ) { .. }

This is true if the device is interactive and constant, so that
new plots erase old plots.  This can be used with the B<pgask()>
PGPLOT subroutine to ensure that the user will see all of the plots.
See L</EXAMPLES>.

=head2 next

  $dev_str = $dev->next;

This method is the basis for the automatic updating of the device
specification when the object is used as a string.  If desired it may
 be used directly.  It will return the next device specification. It
increments the device number.

=head2 current

  $dev_str = $dev->current;

This returns the device string which would be generated in the current
environment.  It does not alter the environment.

=head2 last

  $dev_str = $dev->current;

This returns the last generated device string.  It does not alter the
environment.

=head2 is_const

  if ( $dev->is_const ) { ... }

This method returns true if the device specification does not
interpolate any variables or device numbers.

=head2 would_change

  if ( $dev->would_change ) { ... }

This method returns true if the last generated device specification
would differ from one generated with the current environment. It
returns true if no device specification has yet been generated.

It does not change the current environment.

=head2 is_interactive

  if ( $dev->is_interactive ) { ... }

This method returns true if the device is an interactive device.

=head2 is_ephemeral

  if ( $dev->is_ephemeral ) { ... }

This method returns true if the plot display will disappear if the
device is closed (e.g., the C</xw> device ).

=head1 EXAMPLES

=over

=item *

Here's the prototypical example.  The application outputs multiple
plots and the user is allowed to specify an output device.  The device
is initialized directly from the user's input:

  $device = PGPLOT::Device->new( $user_device_spec );

Before each call to C<pgbegin> or C<PDL::G::P::Window->new>, indicate
via the B<override> method the new hardcopy filename, without any
suffix.  The filename will be ignored if the user has specified an
interactive device:

  $device->override( 'out_${theta:%05.2f}' );

Use B<next()> to retrieve the value:

  pgbegin( 0, $device->next, 1, );
  $win = PDL::Graphics::PGPLOT::Window->new({ Device => $device->next} );

=item *

The application outputs multiple plots, and the user should be able to
decide whether a single interactive device window should be used, or
whether multiple ones should be used.  In the first instance, the user
specifies the device as C</xs>, in the second C<+/xs> or C<+1/xs>:

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

Note that B<would_change()> will return true if no specification has
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

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-pgplot-device@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=PGPLOT-Device

=head2 Source

Source is available at

  https://gitlab.com/djerius/pgplot-device

and may be cloned from

  https://gitlab.com/djerius/pgplot-device.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<PGPLOT>

=item *

L<PDL>

=item *

L<PDL::Graphics::PGPLOT::Window>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

package PGPLOT::Device::PGWin;

# ABSTRACT: convenience class for PDL::Graphics::PGPLOT::Window

use strict;
use warnings;

use v5.10;

our @ISA = qw();

our $VERSION = '0.12';

use List::Util 1.33;

use PGPLOT::Device;
use PGPLOT                        ();
use PDL::Graphics::PGPLOT::Window ();




























sub new {
    my ( $class, $opt ) = @_;

    my %opt = List::Util::pairmap { lc( $a ) => $b }
    winopts => {},
      defined $opt ? %$opt : ();

    my $self = {};
    $self->{device} = PGPLOT::Device->new(
        defined $opt{device}  ? $opt{device}  : (),
        defined $opt{devopts} ? $opt{devopts} : (),
    );
    $self->{not_first}     = 0;
    $self->{win}           = undef;
    $self->{winopts}       = { %{ $opt{winopts} } };

    bless $self, $class;

    $self;
}








sub winopts {
    return { %{ $_[0]->{winopts} } };
}

sub _update_winopts {
    my ( $self, $new ) = @_;

    my $orig = $self->{winopts};
    $self->{winopts} = { %{$new} };

    # keys of the elements that aren't the same between the
    # new and old winopts.
    my %lc_orig = map { lc $_ => $orig->{$_} } keys %$orig;
    my %lc_new  = map { lc $_ => $new->{$_} } keys %$new;

    my @diffs = grep {
        !(
            ( exists $lc_new{$_} && exists $lc_orig{$_} )
            && (   ( !defined $lc_new{$_} && !defined $lc_orig{$_} )
                || ( $lc_new{$_} eq $lc_orig{$_} ) ) )
    } List::Util::uniq( keys %lc_new, keys %lc_orig );


    return unless @diffs && defined $self->{win};
    my $win = $self->{win};

    my %diffs;
    @diffs{@diffs} = ();

    if ( exists $diffs{justify} ) {
        for my $options ( 'PlotOptions', 'Options' ) {
            my $defaults = $win->{$options}->defaults;
            $defaults->{Justify} = $lc_new{justify};
            $win->{$options}->defaults( $defaults );
        }
    }

    # try to do something if just the number of panels are being changed
    if ( exists $diffs{nxpanel} || exists $diffs{nypanel} ) {
        my ( $NX, $NY )
          = ( $lc_new{nxpanel} // 1, $lc_new{nypanel} // 1 );

        # don't look!  PDL::Graphics::PGPLOT::Window doesn't understand
        # how to change the number of panels while a device is open,
        # so need to do it manually and then poke at the object's innards
        # so that it will know the new panel grid and clear the device
        # in advance of the next plot
        PGPLOT::pgsubp( $NX, $NY );
        $win->{NX}           = $NX;
        $win->{NY}           = $NY;
        $win->{CurrentPanel} = $NX * $NY;
    }
}









sub device { $_[0]->{device} }




































sub next {
    my $self = shift;
    my $winopts = 'HASH' eq ref $_[0] ? shift : undef;

    $self->override( @_ ) if @_;

    # prompt user before displaying second and subsequent plots if
    # a new plot will erase the previous one
    PGPLOT::pgask( $self->{device}->ask )
      if $self->{not_first}++;

    if ( $self->{device}->would_change ) {
        $self->finish;
        $self->{winopts} = { %$winopts } if defined $winopts;
        $self->{win} = PDL::Graphics::PGPLOT::Window->new( {
                Device => $self->{device}->next,
                %{ $self->{winopts} } } );
    }
    else {
        $self->_update_winopts( $winopts ) if defined $winopts;
    }

    $self->{win};
}










sub override {
    my $self = shift;
    $self->{device}->override( @_ );
}
















sub finish {
    my ( $self ) = @_;
    # make sure that the plot stays up until the user is done with it
    if ( defined $self->{win} ) {
        PGPLOT::pgask( 1 ) if $self->{device}->is_ephemeral;
        $self->{win}->close;
    }
}

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory devopts winopts

=head1 NAME

PGPLOT::Device::PGWin - convenience class for PDL::Graphics::PGPLOT::Window

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  $pgwin = PGPLOT::Device::PGWin->new( { device => $user_device_spec,
                                         winopts => \%opts } );

  $pgwin->override( $override );
  $win = $pgwin->next;
  $win->env( ... );

  $pgwin->finish;

=head1 DESCRIPTION

B<PGPLOT::Device::PGWin> is a convenience class which combines
L<PGPLOT::Device> and L<PDL::Graphics::PGPLOT::Window>.  It provides
the logic to handle interactive devices (as illustrated in the
Examples section of the B<PGPLOT::Device> documentation).

Note that the L<PDL::Graphics::PGPLOT::Window/close> method should
B<never> be called when using this module, as that will surely mess
things up.

=head1 METHODS

=head2 new

  $pgwin = PGPLOT::Device::PGWin->new( \%opts );

Create a new object.  The possible options are:

=over

=item device

The device specification.  This is passed directly to
L<PGPLOT::Device/new>, so see its documentation.

=item devopts

A hashref containing options to pass to L<PGPLOT::Device/new>.

=item winopts

A hashref containing options to pass to
L<PDL::Graphics::PGPLOT::Windows/new>.  Do not include a C<Device>
option as that will break things.

=back

=head2 winopts

  # retrieve a copy of the current set of dinwo options.
  $winopts = $pgwin->winopts;

=head2 device

  $dev = $pgwin->device

This method returns the underlying L<PGPLOT::Device> object.

=head2 next

  $win = $pgwin->next( ?\%winopts, ?$spec  );

Return the window handle to use for constructing the next plot.  If the device
is not changing, simply returns the existing window handle.

=over

=item C<%winopts>

If C<%winopts> is provided, it will be used to replace the previous
set of window options. To merely amend that, set

  %winopts = ( %{ $pgwin->winopts }, %newoptions );

If the device is not changing, some poking at
PDL::Graphics::PGPLOT::Window innards must be performed so that the
current window will pay attention to the new options.  Only the
following options are handled:

  Justify NXPanel NYPanel

=item C<$spec>

If the optional argument C<$spec> is provided, it is
equivalent to

  $pgwin->override( $spec );
  $pgwin->next;

=back

=head2 override

  $pgwin->override( ... );

This calls the B<override> method of the associated
L<PGPLOT::Device> object.

=head2 finish

  $pgwin->finish();

Close the associated device.  This must be called to handle prompting
for ephemeral interactive graphic devices before a program finishes
execution.

This is B<not> automatically called upon object destruction as there
seems to be an ordering problem in destructors called during Perl's
cleanup phase such that the underlying
L<PDL::Graphics::PGPLOT::Window> object is destroyed I<before> this
object.

=head1 EXAMPLES

  my $pgwin = PGPLOT::Device::PGWin->new( { Device => $user_spec } );

  eval {

    for my $plot in ( qw/ plot1 plot2 / )
    {
      $pgwin->override( $plot );
      my $win = $pgwin->next();
      $win->env( ... );
      ...
    }
  };
  my $error = $@;
  $pgwin->finish;
  die $error if $error;

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

L<PGPLOT::Device|PGPLOT::Device>

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

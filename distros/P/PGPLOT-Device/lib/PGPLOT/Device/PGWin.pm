package PGPLOT::Device::PGWin;

# ABSTRACT: convenience class for PDL::Graphics::PGPLOT::Window

use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.11';


use PGPLOT::Device;
use PGPLOT ();
use PDL::Graphics::PGPLOT::Window ();




























sub new
{
  my ( $class, $opt ) = @_;

  my %opt = ( WinOpts => {},
              defined $opt ? %$opt : () );

  my $self = {};
  $self->{device} =
    PGPLOT::Device->new(
                        defined $opt{Device}  ? $opt{Device}  : (),
                        defined $opt{DevOpts} ? $opt{DevOpts} : (),
                       );
  $self->{not_first} = 0;
  $self->{win} = undef;
  $self->{WinOpts} = $opt{WinOpts};

  bless $self, $class;

  $self;
}









sub device { $_[0]->{device} }















sub next
{
  my $self = shift;

  $self->override( @_ ) if @_;

  # prompt user before displaying second and subsequent plots if
  # a new plot will erase the previous one
  PGPLOT::pgask( $self->{device}->ask )
    if $self->{not_first}++;

  if ( $self->{device}->would_change )
  {
    $self->{win}->close if defined $self->{win};
    $self->{win} =
      PDL::Graphics::PGPLOT::Window->new({ Device => $self->{device}->next,
                                           %{$self->{WinOpts}} } );
  }

  $self->{win};
}










sub override
{
  my $self = shift;
  $self->{device}->override( @_ );
}
















sub finish
{
  my ( $self ) = @_;
  # make sure that the plot stays up until the user is done with it
  if ( defined $self->{win} )
  {
    PGPLOT::pgask(1) if $self->{device}->is_ephemeral;
    $self->{win}->close;
  }
}

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

PGPLOT::Device::PGWin - convenience class for PDL::Graphics::PGPLOT::Window

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  $pgwin = PGPLOT::Device::PGWin->new( { device => $user_device_spec,
                                         WinOpts => \%opts } );

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

=item Device

The device specification.  This is passed directly to
L<PGPLOT::Device/new>, so see it's documentation.

=item DevOpts

A hashref containing options to pass to L<PGPLOT::Device/new>.

=item WinOpts

A hashref containing options to pass to
L<PDL::Graphics::PGPLOT::Windows/new>.  Do not include a C<Device>
option as that will break things.

=back

=head2 device

  $dev = $pgwin->device

This method returns the underlying L<PGPLOT::Device> object.

=head2 next

  $win = $pgwin->next(  );
  $win = $pgwin->next( $override );

This method returns the window handle to use for constructing the next
plot.  If the optional argument is specified, it is equivalent to the
following call sequence:

  $pgwin->override( $override );
  $pgwin->next;

=head2 override

  $pgwin->override( ... );

This is calls the B<override> method of the associated
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

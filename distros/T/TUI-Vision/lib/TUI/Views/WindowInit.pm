package TUI::Views::WindowInit;
# ABSTRACT: A class for initializing a frame for TWindows.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TWindowInit
  new_TWindowInit
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  CodeRef
  Object
);

sub TWindowInit() { __PACKAGE__ }
sub new_TWindowInit { __PACKAGE__->from(@_) }

# declare attributes
has createFrame => ( is => 'bare' );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      createFrame => CodeRef, { alias => 'cFrame' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $obj ($cFrame)
  state $sig = signature(
    method => 1,
    pos    => [CodeRef],
  );
  my ( $class, $cFrame ) = $sig->( @_ );
  return $class->new( cFrame => $cFrame );
}

sub createFrame {    # $frame ($r)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $r ) = $sig->( @_ );
  my ( $class, $code ) = ( ref $self, $self->{createFrame} );
  return $class->$code( $r );
}

1

__END__

=pod

=head1 NAME

TUI::Views::WindowInit - class for initializing a frame for TWindows.

=head1 SYNOPSIS

  use TUI::Views;

  my $winInit = TWindowsInit->new($cFrame => sub { ... } );

=head1 DESCRIPTION

The TWindowsInit class is used to initialize the frame in TWindows. It provides 
methods to start and complete the initialization process. This class is 
essential for setting up the user interface elements in a TWindow class.

=head1 ATTRIBUTES

=over

=item createFrame

A subroutine reference used to create the frame for a window. (CodeRef)

=back

=head1 METHODS

=head2 new

  my $obj = TWindowInit->new(%args);

Initializes the code reference for a frame.

=over

=item cFrame

Required parameter to specify the frame creation subroutine. (CodeRef)

=back

=head2 from

  my $obj = TWindowInit->from($cFrame);

Creates a TWindowInit object from the specified frame creation subroutine.

=head2 createFrame

  my $frame = $self->createFrame($r);

Creates the frame for a TWindow using the specified TRect parameter $r.

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). 

=cut

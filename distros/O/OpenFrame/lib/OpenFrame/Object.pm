package OpenFrame::Object;

use strict;
use warnings::register;

use OpenFrame;

our $VERSION=3.05;

sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;
  $self->init(@_);
  return $self;
}

sub init {
  my $self = shift;
}

sub error {
  my $self = shift;
  my $mesg = shift;
  my $pack = ref( $self );
  my ($package, $filename, $line, $subroutine, $hasargs,
      $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller( 1 );
  if ($OpenFrame::DEBUG{ ALL } || $OpenFrame::DEBUG{ $pack }) {
    warnings::warn("[$pack\::$subroutine] $mesg");
  }
}

1;

__END__

=head1 NAME

OpenFrame::Object - An internal class

=head1 SYNOPSIS

  # None

=head1 DESCRIPTION

This class is used internally by OpenFrame.

=head1 AUTHOR

James Duncan <jduncan@fotango.com>

=cut


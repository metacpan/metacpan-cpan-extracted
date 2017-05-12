package OpenFrame::AppKit::Segment::LogFile;

use strict;
use warnings::register;

use Pipeline::Segment;
use base qw ( Pipeline::Segment );

sub dispatch {
  my $self  = shift;
  my $pipe  = shift;
  my $store = $pipe->store();

  my $request = $store->get('OpenFrame::Request');
  $self->emit($request->uri->path)
}

1;

=head1 NAME

OpenFrame::AppKit::Segment::LogFile - segment for outputting a little bit of logging

=head1 SYNOPSIS

  use OpenFrame::AppKit::Segment::LogFile;

  my $logfile = OpenFrame::AppKit::Segment::LogFile->new();
  $pipeline->add_segment( $logfile );

=head1 DESCRIPTION

C<OpenFrame::AppKit::Segment::LogFile> outputs information about the request to STDERR
when a true C<debug()> is set.  C<OpenFrame::AppKit::Segment::LogFile> inherits from 
C<Pipeline::Segment>.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 SEE ALSO

  Pipeline::Segment

=cut

















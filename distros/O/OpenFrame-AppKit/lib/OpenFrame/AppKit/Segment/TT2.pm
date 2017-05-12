package OpenFrame::AppKit::Segment::TT2;

use strict;
use warnings::register;

use Template;
use File::Spec;
use Pipeline::Segment;
use OpenFrame::Response;

our $VERSION=3.03;

use base qw ( Pipeline::Segment );

my $TT2 = Template->new();

sub directory {
  my $self = shift;
  my $dir  = shift;
  if (defined($dir)) {
    $self->{template_directory} = $dir;
    return $self;
  } else {
    return $self->{template_directory};
  }
}

sub dispatch {
  my $self = shift;
  my $pipe = shift;

  ## get the path from the request, via the store.
  my $path = $pipe->store->get('OpenFrame::Request')->uri->path();

  ## split it up so we know where we are
  my ($volume, $dirs, $file) = File::Spec->splitpath( $path );

  ## make sure we have a file
  if (!$file) {
    $file = "index.html";
  }

  ## get the reconstituted path, with index.html tagged on if there was no file.
  my $reconstituted = File::Spec->catfile( $self->directory, $dirs, $file );
  my $response = OpenFrame::Response->new();

  if (!-e $reconstituted) {
    $self->emit("file $reconstituted not found");
    $response->code(ofERROR);
    my $date = localtime(time());
    $response->message(
		       qq{
			  <html>
			  <head>
			  <title>File Not Found</title>
			  </head>
			  <body>
			  <h1>File Not Found</h1>
			  <p>
			  The file $path was not found.
			  </p>
			  <hr>
			  <i>$date, OpenFrame $OpenFrame::VERSION=3.03;
			  </body>
			  </html>
			}
		      );
    return $response;
  } else {
    my $output;
    $self->tt2->process(
			$reconstituted,
			$pipe->store->get('OpenFrame::AppKit::Session'),
			\$output
		       );

    if (!$output) {
      ## another class of error, it didn't process it properly
      my $date = localtime(time());
      $self->emit("access forbidden to file $reconstituted");
      $response->code( ofERROR );
      $response->message(
			 qq{
			    <html>
			    <head>
			    <title>Access Forbidden</title>
			    </head>
			    <body>
			    <h1>Access Forbidden</h1>
			    <p>
			    You aren't allowed to access the file $path
			    </p>
			    <hr>
			    <i>$date, OpenFrame $OpenFrame::VERSION=3.03;
			    </body>
			    </html>
			   } #'}
			);
      return $response;
    }

    ## create the response
    $response->code( ofOK );
    $response->message( $output );
    ## return it
    return $response;
  }
}

##
## the tt2 method simply returns a Template object.
##
sub tt2 {
  my $self = shift;
  my $tt2  = shift;
  if (defined($tt2)) {
    $TT2 = $tt2;
  } else {
    return $TT2;
  }
}

1;

=head1 NAME

OpenFrame::AppKit::Segment::TT2 - a pipeline segment to manage sessions

=head1 SYNOPSIS

  use OpenFrame::AppKit;
  my $template_engine = OpenFrame::Segment::TT2->new();

=head1 DESCRIPTION

The C<OpenFrame::AppKit::Segment::TT2> class is a pipeline segment and inherits its
interface from there. It provides additional interface in the form of the director()
method, which gets and sets the root template directory that the template engine will
examine.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd. All Rights Reserved

This program is released under the same license as Perl itself.



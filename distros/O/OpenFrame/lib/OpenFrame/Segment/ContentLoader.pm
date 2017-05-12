package OpenFrame::Segment::ContentLoader;

use strict;
use warnings::register;

use File::Type;
use File::Spec;
use FileHandle;
use OpenFrame::Response;

use Pipeline::Segment;
use OpenFrame::Object;
use base qw ( Pipeline::Segment OpenFrame::Object );

our $VERSION=3.05;

sub init {
  my $self = shift;
  $self->{directory} = undef;
  $self->SUPER::init(@_);
}

sub directory {
  my $self = shift;
  my $dir  = shift;
  if (defined( $dir )) {
    $self->{directory} = $dir;
    return $self;
  } else {
    return $self->{directory};
  }
}

sub dispatch {
  my $self  = shift;
  my $store = shift->store();

  my $request = $store->get('OpenFrame::Request');

  if (!$request) {
    return undef;
  }

  my $uri     = $request->uri();
  my $path    = $uri->path();

  my ($volume, $dirs, $file) = File::Spec->splitpath( $path );
  if (!$file) {
    $file = "index.html";
  }

  my $response      = OpenFrame::Response->new();
  my $reconstituted = File::Spec->catfile( $self->directory, $dirs, $file );
  if (!-e $reconstituted) {
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
			  <i>$date, OpenFrame $OpenFrame::VERSION</i>
			  </body>
			  </html>
			}
		      );
    $self->error("could not find file $path");
    return $response;
    
  } else {
    my $mm  = File::Type->new();
    my $res = $mm->checktype_filename( $reconstituted );
    my $fh  = FileHandle->new( "<$reconstituted" );
    if ( $fh ) {
      local $/ = undef;
      my $data = <$fh>;
      $fh->close();
      $response->code( ofOK );
      $response->message( $data );
      $response->mimetype( $res );
      return $response;
    } else {
      my $date = localtime(time());
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
			    <i>$date, OpenFrame $OpenFrame::VERSION</i>
			    </body>
			    </html>
			   } #'}
			);

      $self->error("could not access file $path: permission denied");
      return $response;
    }
  }

}

1;

__END__

=head1 NAME

OpenFrame::Segment::ContentLoader - simple file based loader for web
content under OpenFrame

=head1 SYNOPSIS

  use OpenFrame::Segment::ContentLoader;

  my $cl = OpenFrame::Segment::ContentLoader->new();
  $cl->directory("/path/to/pages");
  $pipeline->add_segment($cl);

=head1 DESCRIPTION

C<OpenFrame::Segment::ContentLoader> is a pipeline segment used by
OpenFrame's example webserver. It creates C<OpenFrame::Response>
objects. The objects it creates will either contain the contents of
the file requested, an error displaying a file not found message, or
an error message displaying an access forbidden message.

=head1 SEE ALSO

OpenFrame(3), Pipeline(3)

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=cut

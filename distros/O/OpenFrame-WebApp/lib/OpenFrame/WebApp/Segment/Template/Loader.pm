=head1 NAME

OpenFrame::WebApp::Segment::Template::Loader - a pipeline segment to load
templates.

=head1 SYNOPSIS

  use Pipeline;
  use OpenFrame::WebApp;

  my $pipe = new Pipeline;
  # ... add segments that put a Template in the store ...
  $pipe->add_segment(new OpenFrame::WebApp::Segment::Template::Loader);

  $pipe->dispatch;  # will load any OpenFrame::WebApp::Template in the store.

=cut

package OpenFrame::WebApp::Segment::Template::Loader;

use strict;
use warnings::register;

use Error qw( :try );
use OpenFrame::Response;
use OpenFrame::WebApp::Template;
use OpenFrame::WebApp::Template::Error;

our $VERSION = (split(/ /, '$Revision: 1.1 $'))[1];

use base qw( OpenFrame::WebApp::Segment::Template );


## dispatch this segment
sub dispatch {
    my $self     = shift;
    my $template = $self->get_template_from_store;
    if ($template) {
	return $self->process_template( $template );
    }
}

## process template given
sub process_template {
    my $self     = shift;
    my $template = shift;
    my $response;

    try {
	$response = $template->process;
    } catch OpenFrame::WebApp::Template::Error with {
	my $e = shift;
	if ($e->flag eq eTemplateNotFound) {
	    $response = $self->template_not_found( $e->template );
	} elsif ($e->flag eq eTemplateError) {
	    $response = $self->template_error( $e->message );
	} else {
	    $response = $self->template_error( 'unknown error' );
	}
    };

    return $response;
}

## generate response if template not found
sub template_not_found {
    my $self     = shift;
    my $file     = shift;
    my $request  = $self->store->get('OpenFrame::Request');
    my $response = new OpenFrame::Response;
    my $uri      = $request->uri if $request;

    $response->code(ofERROR);
    my $date = localtime(time());
    $response->message(
		       qq{
			  <html>
			  <head>
			  <title>Template Not Found</title>
			  </head>
			  <body>
			  <h1>Template Not Found</h1>
			  <p>The template associated with $uri was not found.</p>
			  <p>Template file: $file</p>
			  <hr>
			  <i>$date, OpenFrame $OpenFrame::VERSION (WebApp $OpenFrame::WebApp::VERSION)</i>
			  </body>
			  </html>
			}
		      );
    return $response;
}

## generate response if template error
sub template_error {
    my $self     = shift;
    my $message  = shift;
    my $request  = $self->store->get('OpenFrame::Request');
    my $response = new OpenFrame::Response;
    my $uri      = $request->uri if $request;

    $response->code(ofERROR);
    my $date = localtime(time());
    $response->message(
		       qq{
			  <html>
			  <head>
			  <title>Template Error</title>
			  </head>
			  <body>
			  <h1>Template Error</h1>
			  <p>There was an error in the template associated with $uri.</p>
			  <p>Error message:</p>
                          <xmp>$message</xmp>
			  <hr>
			  <i>$date, OpenFrame $OpenFrame::VERSION (WebApp $OpenFrame::WebApp::VERSION)</i>
			  </body>
			  </html>
			}
		      );
    return $response;
}

1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Segment::Template::Loader> class is an
C<OpenFrame::WebApp::Segment::Template> segment and inherits its interface from
there.  On dispatch(), it looks for a C<OpenFrame::WebApp::Template> object
(see below), calls its process() method, and returns the result.

=head1 METHODS

=over 4

=item $ofResponse = $obj->dispatch

process first template found in the store & returns the result (if any).

=item $ofResponse = $obj->process_template( $template )

process template & return an C<OpenFrame::Response>.

=item $ofResponse = $obj->template_not_found( $file )

generate response when template not found.

=item $ofResponse = $obj->template_error( $message )

generate response on template error.

=back

=head1 TODO

Only include detailed error messages if in debug mode (ie: on a development,
not production server).

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::Template>,
L<OpenFrame::Response>

=cut

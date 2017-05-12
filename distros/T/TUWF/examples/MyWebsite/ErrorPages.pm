
# This example demonstrates how to create your custom error pages.


# This file is a Perl module, and since this file is called
# MyWebsite/ErrorPages.pm, we should use the namespace MyWebsite::Errorpages.
package MyWebsite::ErrorPages;


# import the html generation functions
use TUWF ':html';


# Set the error handlers
TUWF::set(
  error_500_handler => \&error_500,
  error_404_handler => \&error_404,
);


# Register the URI '/500', which will explicitely die() and thus trigger a 500
# page to be generated.
TUWF::register(
  qr/500/ => sub { die("This page contains an error!\n") },
);


# the 500 handler is called with an extra argument containing the error
# message. You generally don't want to output this message to your visitors, as
# it only makes sense for the developers of your website (you), and the same
# error is already written to the log file - assuming you have the 'logfile'
# option set.
sub error_500 {
  my($self, $error) = @_;

  # it's a 500, so set the correct HTTP status code
  $self->resStatus(500);

  # generate a simple HTML page
  html;
   body;
    h1 'Internal Server Error';
    p 'It appears something went wrong on our side.';

    # contradicting the above explanation about how you shouldn't output the
    # error message to your visitors, we can of course still output it when
    # running in debug mode.
    p $error if $self->debug;
   end;
  end;
}


# and a simple 404 page
sub error_404 {
  my $self = shift;

  $self->resStatus(404);
  html;
   body;
    h1 'Our custom 404 page';
   end;
  end;
}


# this file is loaded like any other Perl module, so it will have to return a
# true value.
1;


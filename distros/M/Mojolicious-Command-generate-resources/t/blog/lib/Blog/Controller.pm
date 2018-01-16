package Blog::Controller;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# Common functionality for all controllers.
sub debug {

  # my ($package, $filename, $line, $subroutine) = caller(0);
  state $log = $_[0]->app->log;
  return $log->debug(
                     @_[1 .. $#_]    #, "    at $filename:$line"
                    );
}

1;


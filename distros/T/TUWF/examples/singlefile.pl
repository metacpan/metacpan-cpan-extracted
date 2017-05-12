#!/usr/bin/perl

# Very simple single-file example of TUWF.

use strict;
use warnings;


# This is a trick I always use to get the absolute path of a file if we only
# know its location relative to the location of this script. It does not rely
# on getcwd() or environment variables, and thus works quite well.
#
# Of course, you won't need this when TUWF is properly installed (and thus
# available in @INC) and all other files you are using, too.

use Cwd 'abs_path';
our $ROOT;
BEGIN { ($ROOT = abs_path $0) =~ s{/examples/singlefile.pl$}{}; }
use lib $ROOT.'/lib';


# load TUWF and import all html functions
use TUWF ':html';


# "register" URIs, and map them to a function
TUWF::register(
  # an empty regex only matches the 'root' page (/)
  qr// => \&home,

  # and this regex matches all URIs below /sub/, and passes the part after
  # /sub/ as the second argument to subpage().
  qr/sub\/(.*)/ => \&subpage,

  # all requests for non-registered URIs will throw a 404
);


# "run" the framework. The script will now accept requests either through CGI
# or FastCGI.
TUWF::run();


sub home {
  # first argument of any function called by TUWF is the global object, commonly
  # called "$self", since it is also the object that you build your code upon.
  my $self = shift;

  # Generate an overly simple html page
  html;
   body;
    h1 'Hello World!';
    p 'Check out the following awesome links!';
    ul;
     for (qw|awesome cool etc|) {
       li; a href => "/sub/$_", $_; end;
     }
    end;
   end;
  end;
}


sub subpage {
  my($self, $uri) = @_;
  
  # output a plain text file containing $uri
  $self->resHeader('Content-Type' => 'text/plain; charset=UTF-8');
  lit $uri;
}



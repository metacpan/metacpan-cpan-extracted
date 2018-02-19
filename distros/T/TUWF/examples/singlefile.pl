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
use TUWF ':Html5', 'mkclass';

TUWF::set debug => 1;
TUWF::set xml_pretty => 1;

# Register a handle for the root path, i.e. "GET /"
TUWF::get '/' => sub {
  # Generate an overly simple html page
  Html sub {
    Body sub {
      H1 'Hello World!';
      P 'Check out the following awesome links!';
      Ul sub {
        for (qw|awesome cool etc|) {
          Li sub {
            A href => "/sub/$_", mkclass(awesome => $_ eq 'awesome'), $_;
          };
        }
      };
    };
  };
};


# Register a route handler for "GET /sub/*"
TUWF::get qr{/sub/(?<capturename>.*)} => sub {
  # output a plain text file containing $uri
  tuwf->resHeader('Content-Type' => 'text/plain; charset=UTF-8');
  Lit tuwf->capture(1);
  Lit "\n";
  Lit tuwf->capture('capturename');
};


# Register a handler for "POST /api/echoapi.json"
TUWF::post '/api/echoapi.json' => sub {
  tuwf->resJSON(tuwf->reqJSON);
};


# "run" the framework. The script will now accept requests either through CGI,
# FastCGI, or run as a standalone server.
TUWF::run();

#!/usr/bin/env perl
use warnings;
use strict;

use Log::Report      qw/persona/;

use CGI                      ();
use Mozilla::Persona::Server ();

my $persona = Mozilla::Persona::Server
  ->fromConfig('__CONFIG__');

my %actions =
  ( is_logged_in => sub { $persona->actionIsLoggedIn(@_) }
  , login        => sub { $persona->actionLogin(@_)      }
  , sign         => sub { $persona->actionSign(@_)       }
  , ping         => sub { $persona->actionPing(@_)       }  # check setup
  );

my $cgi    = CGI->new;
my $action = $cgi->param('action');

my $do     = $actions{$action}
    or error __x"cannot find action {name}", name => $action;

eval { $do->($cgi) };
if($@)                  # we do not want to explain what happens!
{   print $cgi->header(-status => 500);
    exit 1;
}

exit 0;

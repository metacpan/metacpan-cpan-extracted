package Plack::Auth::SSO::ResponseParser;

use Catmandu::Sane;
use Moo::Role;

our $VERSION = "0.011";

with "Catmandu::Logger";

requires "parse";

1;

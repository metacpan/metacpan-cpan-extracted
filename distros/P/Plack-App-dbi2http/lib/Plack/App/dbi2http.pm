package Plack::App::dbi2http;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.06'; # VERSION
our $DATE = '2015-09-06'; # DATE

1;
# ABSTRACT: Export DBI database as HTTP API (Riap::HTTP)

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::dbi2http - Export DBI database as HTTP API (Riap::HTTP)

=head1 VERSION

This document describes version 0.06 of Plack::App::dbi2http (from Perl distribution Plack-App-dbi2http), released on 2015-09-06.

=head1 SYNOPSIS

Prepare and edit a config file:

 % cp share/sample-config/dbi2http.conf.yaml ~
 % emacs ~/dbi2http.conf.yaml; # edit log path and supply DBI dsn/user/password

Run service:

 % cd share/www
 % plackup dbi2http.psgi
 HTTP::Server::PSGI: Accepting connections at http://0:5000/

From another console, access HTTP API via, e.g. curl:

 % curl http://localhost:5000/list_tables
 countries
 continents

 % curl http://localhost:5000/list_columns?table=countries
 id
 ind_name
 eng_name
 tags

 % curl 'http://localhost:5000/list_columns?table=countries&detail=1&-riap-fmt=json-pretty'
 [
    200,
   "OK",
   [
      {
         "pos" : 1,
         "name" : "id",
         "type" : "text"
      },
      {
         "name" : "ind_name",
         "pos" : 2,
         "type" : "text"
      },
      {
         "type" : "text",
         "name" : "eng_name",
         "pos" : 3
      },
      {
         "pos" : 4,
         "name" : "tags",
         "type" : "text"
      }
   ]
 ]

 % curl 'http://localhost:5000/list_rows?table=countries'
 China   cn      Cina    panda
 Indonesia       id      Indonesia       bali,tropical
 Singapore       sg      Singapura       tropical
 United States of America        us      Amerika Serikat

 % curl 'http://localhost:5000/list_rows?table=countries&-riap-fmt=text-pretty'
 .-----------------------------------------------------------------.
 | eng_name                   id   ind_name          tags          |
 |                                                                 |
 | China                      cn   Cina              panda         |
 | Indonesia                  id   Indonesia         bali,tropical |
 | Singapore                  sg   Singapura         tropical      |
 | United States of America   us   Amerika Serikat                 |
 `-----------------------------------------------------------------'

Or use L<App::riap>, a client shell for Riap (with filesystem-like API browsing
and shell tab completion):

 % riap http://localhost:5000/
 riap /> ls
 list_columns
 list_rows
 list_tables

 riap /> list_tables
 countries
 continents

 riap /> list_columns --table countries --detail

 riap /> list_rows --table countries

=head1 DESCRIPTION

This module provides a sample Plack application, which you can customize, to
export a DBI database as a HTTP API service.

I was reading Yanick's blog entry today,
L<http://techblog.babyl.ca/entry/waack>, titled I<Instant REST API for Any
Databases> and I thought I'd quickly cobble up something similar using a
different toolbox. Granted, the resulting HTTP API is not REST (read: it's
better :-) and at 0.01 the API functions are somewhat limited
(L<DBIx::FunctionalAPI>) but this demonstrates how easy it is to create
something usable.

The tools and frameworks are: L<DBIx::FunctionalAPI> which provides a set of
functions: C<list_tables>, C<list_columns>, C<list_rows>, C<create_table>,
C<create_row>, C<rename_table>, etc. These are normal Perl functions that accept
C<dbh>, C<table> arguments and so on.

Next we have L<Perinci::Access::HTTP::Server>, a set of L<Plack> middlewares
that let you access Perl functions over HTTP using the L<Riap::HTTP> protocol.
We compose the middlewares in a PSGI application called C<dbi2http.psgi>.

All you need to do now is just run the PSGI application with L<Plack>, using one
of the many available PSGI servers. There is a configuration file required, to
be put in the home directory, and can be copied from the provided sample config.
All you need to set is basically just path to log file and the DBI connection
information (db_dsn, db_user, db_password) and you're good to go.

After the PSGI application is running, you can connect using a plain HTTP client
like B<curl>. Riap::HTTP exposes Perl modules and functions directly as URL
paths. For example, you can just request the root URL first, and a help message
is returned:

 % curl http://localhost:5000/
 function        list_columns
 function        list_rows
 function        list_tables

 Tips:
 * To call a function, try:
     http://localhost:5000/api/list_tables
 * Function arguments can be given via GET/POST params or JSON hash in req body
 * To find out which arguments a function supports, try:
     http://localhost:5000/api/list_tables?-riap-action=meta
 * To find out all available actions on an entity, try:
     http://localhost:5000/api/list_columns?-riap-action=actions
 * This server uses Riap protocol for great autodiscoverability, for more info:
     https://metacpan.org/module/Riap

We can see there are 3 top-level functions available. Let's call the
C<list_tables> function to, well, list available tables.

 % curl http://localhost:5000/list_tables
 "main"."continents"
 "main"."countries"
 "main"."sqlite_master"
 "temp"."sqlite_temp_master"
 "main"."continents"
 "main"."countries"

Functions usually return data structure and the PSGI application formats it as a
presentable text to the client. To get the raw data, use the C<-riap-fmt>
special argument:

 % curl http://localhost:5000/list_tables?-riap-fmt=json-pretty
 [
   200,
   "OK",
   [
      "\"main\".\"continents\"",
      "\"main\".\"countries\"",
      "\"main\".\"sqlite_master\"",
      "\"temp\".\"sqlite_temp_master\"",
      "\"main\".\"continents\"",
      "\"main\".\"countries\""
   ]
 ]

Actually, Riap provides more than just RPC (function call). It can also expose
function metadata so the protocol is super-self-discoverable. For example,
instead of the default C<call> action, let's call the C<meta> action to request
the function metadata:

 % curl 'http://localhost:5000/list_tables?-riap-action=meta&-riap-fmt=json-pretty'
 [
   200,
   "OK (meta action)",
   {
      "entity_v" : "0.01",
      "result_naked" : "0",
      "entity_date" : "2014-06-15",
      "features" : {},
      "summary": "List available tables",
      "x.perinci.sub.wrapper.logs" : [
         {
            "normalize_schema" : "1",
            "validate_args" : "1",
            "validate_result" : "1"
         }
      ],
      "args_as" : "hash",
      "v" : "1.1",
      "args" : {}
   }
]

Let's check the metadata of another function:

 % curl 'http://localhost:5000/list_columns?-riap-action=meta&-riap-fmt=json-pretty'
 [
   200,
   "OK (meta action)",
   {
      "summary": "List columns of a table",
      "args" : {
         "detail" : {
            "summary" : "Whether to return detailed records instead of just items/strings",
            "schema" : [
               "bool",
               {},
               {}
            ]
         },
         "table" : {
            "schema" : [
               "str",
               {
                  "req" : 1
               },
               {}
            ],
            "req" : 1,
            "summary" : "Table name"
         }
      },
      "args_as" : "hash",
      "v" : 1.1,
      "result_naked" : 0,
      "x.perinci.sub.wrapper.logs" : [
         {
            "validate_args" : "1",
            "validate_result" : "1",
            "normalize_schema" : "1"
         }
      ],
      "features" : {},
      "entity_date" : "2014-06-15",
      "entity_v" : "0.01"
   }
 ]

We can see from the above that the C<list_columns> function accepts arguments
C<table> (a string, required) and C<detail> (bool).

For the full specification of the metadata format, see L<Rinci>.

Aside from using a low-level HTTP client, we can also use L<App::riap>, a Riap
client (just to note that Riap can also be accessed via transport protocol other
than HTTP, but it's another subject matter). The client is a command-line shell
with some conveniences like filesystem-like browsing of API tree, tab
completion, debugging, command history, and others. Let's install the client and
try it out:

 % cpanm -n App::riap
 % riap http://localhost:5000/
 riap />

We are first presented with a prompt. Let's try listing what's available in the
top-level directory:

 riap /> ls -l
 .-------------------------.
 | type       uri          |
 |                         |
 | function   list_columns |
 | function   list_rows    |
 | function   list_tables  |
 `-------------------------'

We see that there are three functions available. To call a function, you can run
it like a running a program:

 riap /> list_tables
 .-----------------------------------------------------------.
 | "main"."continents"           "temp"."sqlite_temp_master" |
 | "main"."countries"            "main"."continents"         |
 | "main"."sqlite_master"        "main"."countries"          |
 `-----------------------------------------------------------'

Note that you can do completion on the command-line. You can even call with
C<--help> option like a normal program:

 riap /> list_columns --help
 Usage
   /list_columns --help (or -h, -?) [--verbose]
   /list_columns [options]
 Options
   --[no]detail
     Whether to return detailed records instead of just items/strings.
   --help, -h, -?
     Display this help message.
   --table=s [str] (required)
     Table name.

This help message is generated from the metadata (so in the background, the
client performs a C<meta> request and converts it to a formatted help message).

To add HTTP authentication (or do any other customization), you can just add a
Plack middleware to the PSGI application.

Last word, exporting a database as a public API service is usually B<not a good
idea>. In case you don't realize that ;-)

=head1 SEE ALSO

L<Rinci>, L<Riap>, L<Riap::HTTP>, L<DBIx::FunctionalAPI>, L<App::riap>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Plack-App-dbi2http>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Plack-App-dbi2http>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Plack-App-dbi2http>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

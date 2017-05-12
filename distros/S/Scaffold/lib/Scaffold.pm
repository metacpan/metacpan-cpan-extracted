package Scaffold;

use 5.8.8;
use warnings;
use strict;

our $VERSION = '0.10';

1; 

__END__

=head1 NAME

Scaffold - Web Application Infrastructure

=head1 INTRODUCTION

What do I mean by "Web Application Infrastructure"? While my primary job is
systems administration, so I deal with operating systems and hardware on a
daily basis. So when developing Scaffold I started to think along those lines. 
Just what type of support does a web based application need? 

An operating system provides coordinated access to resources. It provides a 
way to authenticate and authorize access to those resources. It provides 
an API to manipulate those resources. That API is hopefully portable enough
so that the underlying hardware is not determinatal to your applications.

A web based application also needs that same supporting infrastructure.

=head2 The Lock Manager

A lock manager is used to coodinate access to resources. The default
one is based on Unix semaphores and shared memory. The optional one supports
a distributed lock manager in the form of Keyedmutex. Others could be easily
written as there is a standard api for lock managers. 

=head2 The Cache Manager

Caching is important for performance reasons. It is much quicker to read 
something from cache then disk. The default one uses a memory mapped file. 
The optional one uses memcached. Once again, using a standard api, it is 
fairly easy to write differant caching backends. The cache manager 
perodicatly purges items from the cache. Long term storage needs to go to 
a backing store on disk.

=head2 The Session Manager

The session manager stores session information in the caching system, 
using the lock manager to coordinate access. Sessions are automatically
created upon the first request to the application. They are tracked with 
a temporary cookie from the browser. The cookie has no meaning other 
then it has to be unique.

=head2 Authorization and Authentication

The provided autorization and authentication framework is designed to be
extended and overridden. This functonality is exposed thru a mixin class. 
Authenticated access is tracked by a temporary cookie, seperate from the 
session. Once again the cookie has no meaning, other then being unique.

=head2 URL Dispatching

The buzz word for this is "Routing". But what is routing? Routing is the
parsing of the incomming URL and dispatching to a routine to handle
that request. That's it, nothing more, nothing less. There are many ways
of doing this. Every framework seems to do it somewhat differently 
from the rest and CPAN is full of standalone implementations. Scaffold does 
this with simple regex's. 

=head2 Plack and psgi

Scaffold is built upon plack and the psgi standard. In this way a Scaffold
based application is abstracted away from the details of the backend web
server. Your application can run on any platform that supports the psgi 
standard and has a plack interface available.

=head2 The Operating Environment

An operating system provides some sort of environment for when you
access the system. This can be as simple as a command line where you type 
commands and wait for the result, to a very sophisticated GUI based interface,
where multiple events are being acted upon at once. All these actions require 
some sort of input, output and a backing store for long term storage. From the 
end user perspective, this functionality is just there. They don't have to 
do anything special.

Scaffold strives to do the same thing. The abilities mentioned above are there
by default. You don't have to do anything special to make them happen. You
may want to change how they work and you can do this thru the configuration
of the environment. 

Input is done automatically by exposing the Plack request object to your 
application. Output can be done thru a templating system or as a raw data 
stream. Presitent database connections are maintained to speed access to 
your data. Cookies are collected, maintained, then automatically posted 
back to the browser for the next request cycle.

=head2 Expandability

A Scaffold based application is expandable. If you application starts using
more resoures than a single web server can provide, all you need to do is
change the cache manager and lock manager to the distributed versions. 
Depending on how your database is configured a simple restart may be all
that is needed to expand to multiple web servers.

=head1 JUST THE FACTS MA'AM

The Scaffold infrastructure has three main components and several supporting
modules. Scaffold is written in object oriented Perl5. There are many differant 
ways to write OO code in Perl5, but the easiest is to pick a predefined 
framework and use it. In this vein, I have chosen the Badger framework. 
Badger was developed by Andy Wardell of Template Toolkit fame. The following 
are the components and modules used by Scaffold.

=head2 Scaffold::Engine

This ties Scaffold to the Plack backend. Using configuration sections, you 
can define how the engine interacts with Plack. Additional information is 
available here: L<Scaffold::Engine|Scaffold::Engine>.

=head2 Scaffold::Server

The server module defines the environment that your application runs in, 
initilizes various components and dispatches to the various handlers 
depending on the defined routes. Additional information is available here: 
L<Scaffold::Server|Scaffold::Server>.

=head2 Scaffold::Handler

The handlers are the backbone of an application. Your application will
inherit from and extend Scaffold::Handler to perform whatever action is 
desired. Additional information is available here:
L<Scaffold::Handler|Scaffold::Handler>.

=head2 The Supporting Cast

The following are the supporting modules for Scaffold. They provide the 
neccessary services that an infrastucture should provide an application.

=head3 Scaffold::Cache

This is the base class for caching within Scaffold. The actual caching is done
by these supporting modules: 
L<Scaffold::Cache::FastMmap|Scaffold::Cache::FastMmap> for a memory mapped file and
L<Scaffold::Cache::Memcached|Scaffold::Cache::Memcached> for distributed caching. 
L<Scaffold::Cache::Manager|Scaffold::Cache::Manager> manages the cache and
removes expired items. It is also an example of a Scaffold plugin. By default
the server will load Scaffold::Cache::FastMmap with default parameters 
and Scaffold::Cache::Manager.

=head3 Scaffold::Lockmgr

This is the base class for resource locking. The actual locking is done by 
these supporting modules: L<Scaffold::Lockmgr::UnixMutex|Scaffold::Lockmgr::UnixMutex> which
provides locking using semaphores and shared memory, and: 
L<Scaffold::Lockmgr::Keyedmutex|Scaffold::Lockmgr::Keyedmutex> for 
distributed locking. By default the server will load Scaffold::Lockmgr::UnixMutex 
with default parameters.

=head3 Scaffold::Stash

The stash provides a convient place to place items for later retrieval. 
The support for this is provided by these modules: L<Scaffold::Stash::View|Scaffold::Stash::View>,
L<Scaffold::Stash::Cookies|Scaffold::Stash::Cookies> and 
L<Scaffold::Stash::Controller|Scaffold::Stash::Controller>. For example 
Scaffold::Stash::View is used to store items for later rendering by the Render.
L<Scaffold::Stash::Manager|Scaffold::Stash::Manager> is used to post cookies 
into the response to the request.

=head3 Scaffold::Render

This is the base class for renderers. A render will format the output 
before it is sent back to the response. The following modules are provided: 
L<Scaffold::Render::Default|Scaffold::Render::Default> which just passes 
the output onto the response and L<Scaffold::Render::TT|Scaffold::Render::TT> 
which uses the Template Toolkit to formats the output before sending it onto 
the response. By default the server will load Scaffold::Render::Default.

=head1 BOOK'M DANO

The above is a rather brief overview of what Scaffold is trying to achieve. 
So this begs the question, how does one write a Scaffold based application? 
The following is a simple, static page, application to help demostrate how 
this is done.

 use Scaffold::Server;

 my $psgi_handler;

 main: {

     my $server = Scaffold::Server->new(
         configs => {
             static_search => 'html'
         },
         locations => [
             {
                 route   => qr{/favicon.ico$},
                 handler => 'Scaffold::Handler::Favicon'
             },{
                 route   => qr{^/robots.txt$},
                 handler => 'Scaffold::Handler::Robots'
             },{
                 route   => qr{^/(.*)$},
                 handler => 'Scaffold::Handler::Static'
             }
         ]
     );

     $psgi_handler = $server->engine->psgi_handler();

 }

Cut and paste the above into a file named app.psgi and you can do the following:

 # plackup app.psgi

And then you can connect to the web server with your favorite browser and 
enjoy your first Scaffold based application. But what is really going on here?

This simple application is using some bundled handlers to perform specific
tasks. First the configuration defines a "static_search" variable so that 
L<Scaffold::Handler::Static|Scaffold::Handler::Static> knows where to look
for files to output. Next some routes are defined to be handled by the 
bundled handlers. 

L<Scaffold::Handler::Favicon|Scaffold::Handler::Favicon>
handles the favicon.ico request that most browsers randomly perform. Where 
that file is located is defined by the configuration variable of "doc_rootp". 
This variable has the default value of "html". An additional variable of 
"favicon" has the default value of "favicon.ico". Both of these are used 
to find the actual favicon file, which by default exists at 
"html/favicon.ico". This of course completely overrides what the browser 
requests. This file is cached for subsequent requests.

L<Scaffold::Handler::Robots|Scaffold::Handler::Robots> handles the request for
a "robots.txt" file. Well behaved crawlers always ask for this file. Once again
this uses the configuration variable of "doc_rootp" to locate this file. Which
by default exists at "html/robots.txt". This file is cached for subsequent 
requests.

L<Scaffold::Handler::Static|Scaffold::Handler::Static> is the workhorse here.
It accepts all other requests and looks for the files in the search path 
defined by "static_search". This is first come first served search. If the 
file is not found, a nice debug page will be displayed to help figure out 
why. Otherwise the file will be sent to the browser and cached for subsequent
requsts.

While this is a contrived example, there are a lot of things going on in
the background. A session was automatically established. Resource locking
is automatically performed. Pages are being cached for subsequent 
retrieval. The cache itself is automatically being maintained. All of this 
without intervention by the application programmer. Gee, just like an
real operating system.

This is what "Web Application Infrastructure" does for you. 

=head1 PHILOSOPHY ON THE BACK OF A CEREAL BOX

Right about now I can here the "Ahh, what the world needs, "yet another 
web application framework"" and a Perl one at that. So, what makes mine 
better then the others? Nothing really. Scaffold was born out of my 
frustrations with trying to use another "web application framework". 
The whole ESR scratch your itch thingy.

Scaffold is an OO based system and OO in Perl5 can be done many different 
ways. Some are considered the "next best thing", a "best practice" or 
even "modern perl" and everybody should use it, regardless of usability or 
fitness for that purpose. I choose to use the Badger framework. Why, 
because it makes sense, it doesen't try to make Perl5 something it isn't.

So what does Scaffold give you? Well, it won't create a stand alone 
application from a simple command line. It won't give you yet another 
ORMish way to access your databases. It won't auto-generate a lot of boiler 
plate code. It won't even boast about how independent it is from CPAN. 
Scaffold won't be so encasping that it throws the kitchen sink in for free.
Nor will it attempt to re-invent Ruby-on-Rails, Django, Code Igniter or 
whatever the framework dejour currently is.

What it does give you is the freedom to write your web based applications as 
you see fit and hopefully get out of the way.

=head1 SEE ALSO

 Scaffold::Base
 Scaffold::Class
 Scaffold::Constants
 Scaffold::Engine
 Scaffold::Server
 Scaffold::Utils

 Scaffold::Cache
 Scaffold::Cache::FastMmap
 Scaffold::Cache::Manager
 Scaffold::Cache::Memcached

 Scaffold::Handler
 Scaffold::Handler::ExtDirect
 Scaffold::Handler::ExtPoll
 Scaffold::Handler::Default
 Scaffold::Handler::Favicon
 Scaffold::Handler::Robots
 Scaffold::Handler::Static

 Scaffold::Lockmgr
 Scaffold::Lockmgr::KeyedMutex
 Scaffold::Lockmgr::UnixMutex

 Scaffold::Plugins

 Scaffold::Render
 Scaffold::Render::Default
 Scaffold::Render::TT

 Scaffold::Routes

 Scaffold::Session::Manager
 Scaffold::Session::Store
 Scaffold::Session::Store::Cache

 Scaffold::Stash
 Scaffold::Stash::Controller
 Scaffold::Stash::Cookies
 Scaffold::Stash::Manager
 Scaffold::Stash::View

 Scaffold::Uaf::Authenticate
 Scaffold::Uaf::AuthorizeFactory
 Scaffold::Uaf::Authorize
 Scaffold::Uaf::GrantAllRule
 Scaffold::Uaf::Login
 Scaffold::Uaf::Logout
 Scaffold::Uaf::Manager
 Scaffold::Uaf::Rule
 Scaffold::Uaf::User

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Scaffold

The latest and greatest version is always at 
http://svn.kesteb.us/repos/Scaffold

=head1 COPYRIGHT & LICENSE

Copyright 2010 Kevin L. Esteb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# NAME

Plasp - PerlScript/ASP

# VERSION

version 1.08

# SYNOPSIS

In `MyApp.pm`

    package MyApp;

    use Moo;

    with 'Plasp::App';

    1;

In `app.psgi`

    use MyApp;

    $app = MyApp->new;

# DESCRIPTION

Plasp is [CatalystX::ASP](https://metacpan.org/pod/CatalystX%3A%3AASP), which is a plugin for Catalyst to support ASP
(PerlScript) but with Catalyst ripped out.

This is largely based off of Joshua Chamas's [Apache::ASP](https://metacpan.org/pod/Apache%3A%3AASP), as the application
I've been working with was written for [Apache::ASP](https://metacpan.org/pod/Apache%3A%3AASP). Thus, this was designed
to be almost a drop-in replacement. However, there were many features that I
chose not to implement.

Plasp is a framework built on Plack, which can process ASP scripts. Simply
apply the [Plasp::App](https://metacpan.org/pod/Plasp%3A%3AApp) role to your app class and create a new PSGI app with
`MyApp->new`.

Just to be clear, the [Parser](https://metacpan.org/pod/Plasp%3A%3AParser) is almost totally ripped
off of Joshua Chamas's parser in [Apache::ASP](https://metacpan.org/pod/Apache%3A%3AASP). Similarly with the
[Compiler](https://metacpan.org/pod/Plasp%3A%3ACompiler) and [GlobalASA](https://metacpan.org/pod/Plasp%3A%3AGlobalASA).
However, the other components are reimplementations.

# CONFIGURATION

You can configure Plasp by calling the class method `$class->config` and
passing in a hash ref

    MyApp->config({
      ApplicationRoot => '/var/www',
      DocumentRoot    => 'public',
      Global          => 'lib',
      GlobalPackage   => 'MyApp',
      IncludesDir     => 'templates',
      MailHost        => 'localhost',
      MailFrom        => 'myapp@localhost',
      XMLSubsMatch    => '(?:myapp):\w+',
      Debug           => 0,
    }):

The following documentation is also plagiarized from Joshua Chamas.

- ApplicationRoot

    The Application root is where relative paths will be based off. By default,
    it'll be the the current working directory.

- DocumentRoot

    An Apache::ASP compiles and processes paths based on files within the
    DocumentRoot. This makes configuration similar to Apache::ASP which took the
    DocumentRoot from the Apache configuration. By default, it'll be the
    subdirectory `public` relative to the ApplicationRoot.

- Global

    Global is the nerve center of an Apache::ASP application, in which the
    global.asa may reside defining the web application's event handlers.

    Includes, specified with `<!--#include file=somefile.inc-->` or
    `$Response->Include()` syntax, may also be in this directory, please see
    section on includes for more information.

- GlobalPackage

    Perl package namespace that all scripts, includes, & global.asa events are
    compiled into.  By default, GlobalPackage is some obscure name that is uniquely
    generated from the file path of the Global directory, and global.asa file. The
    use of explicitly naming the GlobalPackage is to allow scripts access to globals
    and subs defined in a perl module that is included with commands like:

        __PACKAGE__->config({
          GlobalPackage => 'MyApp' });

- IncludesDir

    No default. If set, this directory will also be used to look for includes when
    compiling scripts. By default the directory the script is in, and the Global
    directory are checked for includes.

    This extension was added so that includes could be easily shared between ASP
    applications, whereas placing includes in the Global directory only allows
    sharing between scripts in an application.

        __PACKAGE__->config({
          IncludeDirs => '.' });

    Also, multiple includes directories may be set:

        __PACKAGE__->config({
          IncludeDirs => ['../shared', '/usr/local/asp/shared'] });

    Using IncludesDir in this way creates an includes search path that would look
    like `.`, `Global`, `../shared`, `/usr/local/asp/shared`. The current
    directory of the executing script is checked first whenever an include is
    specified, then the `Global` directory in which the `global.asa` resides, and
    finally the `IncludesDir` setting.

- MailHost

    The mail host is the SMTP server that the below Mail\* config directives will
    use when sending their emails. By default [Net::SMTP](https://metacpan.org/pod/Net%3A%3ASMTP) uses SMTP mail hosts
    configured in [Net::Config](https://metacpan.org/pod/Net%3A%3AConfig), which is set up at install time, but this setting
    can be used to override this config.

    The mail hosts specified in the Net::Config file will be used as backup SMTP
    servers to the `MailHost` specified here, should this primary server not be
    working.

        __PACKAGE__->config({
          MailHost => 'smtp.yourdomain.com.foobar' });

- MailFrom

    No default. Set this to specify the default mail address placed in the `From:`
    mail header for the `$Server->Mail()` API extension

        __PACKAGE__->config({
          MailFrom => 'youremail@yourdomain.com.foobar' });

- XMLSubsMatch

    Default is not defined. Set to some regexp pattern that will match all XML and
    HTML tags that you want to have perl subroutines handle. The is
    ["XMLSubs" in Apache::ASP](https://metacpan.org/pod/Apache%3A%3AASP#XMLSubs)'s custom tag technology ported to Plasp, and can
     be used to create powerful extensions to your XML and HTML rendering.

    Please see XML/XSLT section for instructions on its use.

        __PACKAGE__->config({
          XMLSubsMatch => 'my:[\w\-]+' });

- Error404Path

    Path of the page in `DocumentRoot` to serve when page not found. This page
    will go through ASP processing, so ensure this page is simple and does not have
    opportunity for error.

- Error500Path

    Path of the page in `DocumentRoot` to serve when error in application, or in
    Plasp. This page will go through ASP processing, so ensure this page is simple
    and does not have opportunity for error.

- FormFill

    default 0, if true will auto fill HTML forms with values from $Request->Form().
    This functionality is provided by use of [HTML::FillInForm::ForceUTF8](https://metacpan.org/pod/HTML%3A%3AFillInForm%3A%3AForceUTF8). For
    more information please see "perldoc HTML::FillInForm::ForceUTF8"

    This feature can be enabled on a per form basis at runtime with
    `$Response->{FormFill} = 1`

- Debug

    Simply sets the log level to debug

# OBJECTS

The beauty of the ASP Object Model is that it takes the burden of CGI and
Session Management off the developer, and puts them in objects accessible from
any ASP script and include. For the perl programmer, treat these objects as
globals accessible from anywhere in your ASP application.

The Plasp object model supports the following:

    Object        Function
    ------        --------
    $Session      - user session state
    $Response     - output to browser
    $Request      - input from browser
    $Application  - application state
    $Server       - general methods

These objects, and their methods are further defined in their respective
pod.

- [Plasp::Session](https://metacpan.org/pod/Plasp%3A%3ASession)
- [Plasp::Response](https://metacpan.org/pod/Plasp%3A%3AResponse)
- [Plasp::Request](https://metacpan.org/pod/Plasp%3A%3ARequest)
- [Plasp::Application](https://metacpan.org/pod/Plasp%3A%3AApplication)
- [Plasp::Server](https://metacpan.org/pod/Plasp%3A%3AServer)

If you would like to define your own global objects for use in your scripts and
includes, you can initialize them in the `global.asa` `Script_OnStart` like:

    use vars qw( $Form $App ); # declare globals
    sub Script_OnStart {
      $App  = MyApp->new;     # init $App object
      $Form = $Request->Form; # alias form data
    }

In this way you can create site wide application objects and simple aliases for
common functions.

# METHODS

These are methods available for the `Plasp` object

- $self->search\_includes\_dir($include)

    Returns the full path to the include if found in IncludesDir

- $self->file\_id($file)

    Returns a file id that can be used a subroutine name when compiled

- $self->execute($code)

    Eval the given `$code`. The `$code` can be a ref to CODE or a SCALAR, ie. a
    string of code to execute. Alternatively, `$code` can be the absolute name of
    a subroutine.

- $self->cleanup()

    Cleans up objects that are transient. Get ready for the next request

# BUGS/CAVEATS

Obviously there are no bugs ;-) As of now, every known bug has been addressed.
However, a caveat is that not everything from Apache::ASP is implemented here.
Though the module touts itself to be a drop-in replacement, don't believe the
author and try it out for yourself first. You've been warned :-)

# AUTHOR

Steven Leung < sleung@cpan.org >

Joshua Chamas < asp-dev@chamas.com >

# SEE ALSO

- [Plasp::App](https://metacpan.org/pod/Plasp%3A%3AApp)
- [Plack](https://metacpan.org/pod/Plack)
- [Apache::ASP](https://metacpan.org/pod/Apache%3A%3AASP)

# LICENSE AND COPYRIGHT

Copyright (C) 2020 Steven Leung

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.

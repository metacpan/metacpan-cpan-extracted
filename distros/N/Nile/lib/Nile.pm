#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile - Android Like Visual Web App Framework Separating Code From Design Multi Lingual And Multi Theme.

=head1 SYNOPSIS
    
    #!/usr/bin/perl

    use Nile;

    my $app = Nile->new();
    
    # initialize the application with the shared and safe sessions settings
    $app->init({
        # base application path, auto detected if not set
        path        =>  dirname(File::Spec->rel2abs(__FILE__)),
        
        # load config files, default extension is xml
        config      => [ qw(config) ],

        # force run mode if not auto detected by default. modes: "psgi", "fcgi" (direct), "cgi" (direct)
        #mode   =>  "fcgi", # psgi, cgi, fcgi
    });
    
    # inline actions, return content. url: /forum/home
    $app->action("get", "/forum/home", sub {
        my ($self) = @_;
        # $self is set to the application context object same as $self->app in plugins
        my $content = "Host: " . ($self->request->virtual_host || "") ."<br>\n";
        $content .= "Request method: " . ($self->request->request_method || "") . "<br>\n";
        $content .= "App Mode: " . $self->mode . "<br>\n";
        $content .= "Time: ". time . "<br>\n";
        $content .= "Hello world from inline action /forum/home" ."<br>\n";
        $content .= "أحمد الششتاوى" ."<br>\n";
        $self->response->encoded(0); # encode content
        return $content;
    });

    # inline actions, capture print statements, ignore the return value. url: /accounts/login
    $app->capture("get", "/accounts/login", sub {
        my ($self) = @_;
        # $self is set to the application context object same as $self->app in plugins
        say "Host: " . ($self->request->virtual_host || "") . "<br>\n";
        say "Request method: " . ($self->request->request_method || "") . "<br>\n";
        say "App Mode: " . $self->mode . "<br>\n";
        say "Time: ". time . "<br>\n";
        say "Hello world from inline action with capture /accounts/login", "<br>\n";
        say $self->encode("أحمد الششتاوى ") ."<br>\n";
        $self->response->encoded(1); # content already encoded
    });

    # inline actions, capture print statements and the return value. url: /blog/new
    $app->command("get", "/blog/new", sub {
        my ($self) = @_;
        # $self is set to the application context object same as $self->app in plugins
        say "Host: " . ($self->request->virtual_host || "") . "<br>\n";
        say "Request method: " . ($self->request->request_method || "") . "<br>\n";
        say "App Mode: " . $self->mode . "<br>\n";
        say "Time: ". time . "<br>\n";
        say "Hello world from inline action with capture /blog/new and return value.", "<br>\n";
        say $self->encode("أحمد الششتاوى ") ."<br>\n";
        $self->response->encoded(1); # content already encoded
        return " This value is returned from the command.";
    });

    # run the application and return the PSGI response or print to the output
    # the run process will also run plugins with matched routes files loaded
    $app->run();

=head1 DESCRIPTION

Nile - Android Like Visual Web App Framework Separating Code From Design Multi Lingual And Multi Theme.

B<Beta> version, API may change. The project's homepage L<https://github.com/mewsoft/Nile>.

The main idea in this framework is to separate all the html design and layout from programming. 
The framework uses html templates for the design with special xml tags for inserting the dynamic output into the templates.
All the application text is separated in langauge files in xml format supporting multi lingual applications with easy translating and modifying all the text.
The framework supports PSGI and also direct CGI and direct FCGI without any modifications to your applications.

=head1 EXAMPLE APPLICATION

Download and uncompress the module file. You will find an example application folder named B<app>.

=head1 URLs

This framework support SEO friendly url's, routing specific urls and short urls to actions.

The url routing system works in the following formats:

    http://domain.com/module/controller/action  # mapped from route file or to Module/Controller/action
    http://domain.com/module/action         # mapped from route file or to Module/Module/action or Module/Module/index
    http://domain.com/module            # mapped from route file or to Module/Module/module or Module/Module/index
    http://domain.com/index.cgi?action=module/controller/action
    http://domain.com/?action=module/controller/action
    http://domain.com/blog/2014/11/28   # route mapped from route file and args passed as request params

The following urls formats are all the same and all are mapped to the route /Home/Home/index or /Home/Home/home (/Module/Controller/Action):
    
    # direct cgi call, you can use action=home, route=home, or cmd=home
    http://domain.com/index.cgi?action=home

    # using .htaccess to redirect to index.cgi
    http://domain.com/?action=home

    # SEO url using with .htaccess. route is auto detected from url.
    http://domain.com/home

=head1 APPLICATION DIRECTORY STRUCTURE

Applications built with this framework must have basic folder structure. Applications may have any additional directories.

The following is the basic application folder tree that must be created manually before runing:

    ├───api
    ├───cache
    ├───cmd
    ├───config
    ├───cron
    ├───data
    ├───file
    ├───lang
    │   ├───ar
    │   └───en-US
    ├───lib
    │   └───Nile
    │       ├───Module
    │       │   └───Home
    │       └───Plugin
    ├───log
    ├───route
    ├───temp
    ├───theme
    │   └───default
    │       ├───css
    │       ├───icon
    │       ├───image
    │       ├───js
    │       ├───view
    │       └───widget
    └───web

=head1 CREATING YOUR FIRST MODULE 'HOME' 

To create your first module called Home for your site home page, create a folder called B<Home> in your application path
C</path/lib/Nile/Module/Home>, then create the module Controller file say B<Home.pm> and put the following code:

    package Nile::Module::Home::Home;

    our $VERSION = '0.55';

    use Nile::Module; # automatically extends Nile::Module
    use DateTime qw();
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # plugin action, return content. url is routed direct or from routes files. url: /home
    sub home : GET Action {
        
        my ($self, $app) = @_;
        
        # $app is set to the application context object, same as $self->app inside any method
        #my $app = $self->app;
        
        my $view = $app->view("home");
        
        $view->var(
            fname           =>  'Ahmed',
            lname           =>  'Elsheshtawy',
            email           =>  'sales@mewsoft.com',
            website     =>  'http://www.mewsoft.com',
            singleline      =>  'Single line variable <b>Good</b>',
            multiline       =>  'Multi line variable <b>Nice</b>',
        );
        
        #my $var = $view->block();
        #say "block: " . $app->dump($view->block("first/second/third/fourth/fifth"));
        #$view->block("first/second/third/fourth/fifth", "Block Modified ");
        #say "block: " . $app->dump($view->block("first/second/third/fourth/fifth"));

        $view->block("first", "1st Block New Content ");
        $view->block("six", "6th Block New Content ");

        #say "dump: " . $app->dump($view->block->{first}->{second}->{third}->{fourth}->{fifth});
        
        # module settings from config files
        my $setting = $self->setting();
        
        # plugin session must be enabled in config.xml
        if (!$app->session->{first_visit}) {
            $app->session->{first_visit} = time;
        }
        my $dt = DateTime->from_epoch(epoch => $app->session->{first_visit});
        $view->set("first_visit", $dt->strftime("%a, %d %b %Y %H:%M:%S"));
        
        # save visitors count to the cache
        $app->cache->set("visitor_count", $app->cache->get("visitor_count") + 1, "1 year");
        $view->set("visitor_count", $app->cache->get("visitor_count"));

        return $view->out();
    }
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # run action and capture print statements, no returns. url: /home/news
    sub news: GET Capture {

        my ($self, $app) = @_;

        say qq{Hello world. This content is captured from print statements.
            The action must be marked by 'Capture' attribute. No returns.};

    }
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # run action and capture print statements and the return value. url: /home/info
    sub info: GET Command {

        my ($self, $app) = @_;

        say qq{This content is captured from print statements.
            The action marked by 'Command' attribute. };
        
        return qq{This content is the return value on the action.};
    }
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # regular method, can be invoked by views:
    # <vars type="module" method="Home::Home->welcome" message="Welcome back!" />
    sub welcome {
        my ($self, %args) = @_;
        my $app = $self->app();
        return "Nice to see you, " . $args{message};
    }
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    1;

=head1 YOUR FIRST VIEW 'home'

Create an html file name it as B<home.html>, put it in the default theme folder B</path/theme/default/views>
and put in this file the following code:

    <vars type="widget" name="header" charset_name="UTF-8" lang_name="en" />

    {first_name} <vars name="fname" /><br>
    {last_name} <vars name="lname" /><br>
    {email} <vars type="var" name='email' /><br>
    {website} <vars type="var" name="website" /><br>
    <br>

    global variables:<br>
    language: <vars name='lang' /><br>
    theme: <vars name="theme" /><br>
    base url: <vars name="base_url" /><br>
    image url: <vars name="image_url" /><br>
    css url: <vars name="css_url" /><br>
    new url: <a href="<vars name="base_url" />comments" >comments</a><br>
    image: <img src="<vars name="image_url" />logo.png" /><br>
    <br>
    first visit: <vars name="first_visit" /><br>
    <br>

    {date_now} <vars type="plugin" method="Date->date" format="%a, %d %b %Y %H:%M:%S" /><br>
    {time_now} <vars type="plugin" method="Date->time" format="%A %d, %B %Y  %T %p" /><br>
    {date_time} <vars type="plugin" method="Date::now" capture="1" format="%B %d, %Y  %r" /><br>

    <br>
    <vars type="module" method="Home::Home->welcome" message="Welcome back!" /><br>
    <br>

    Our Version: <vars type="perl"><![CDATA[print $self->app->VERSION; return;]]></vars><br>
    <br>

    <pre>
    <vars type="perl">system ('dir *.cgi');</vars>
    </pre>
    <br>

    <vars type="var" name="singleline" width="400px" height="300px" content="ahmed<b>class/subclass">
    cdata start here is may have html tags and 'single' and "double" qoutes
    </vars>
    <br>

    <vars type="var" name="multiline" width="400px" height="300px"><![CDATA[ 
        cdata start here is may have html tags <b>hello</b> and 'single' and "double" qoutes
        another cdata line
    ]]></vars>
    <br>

    <vars type="perl"><![CDATA[ 
        say "";
        say "<br>active language: " . $self->app->var->get("lang");
        say "<br>active theme: " . $self->app->var->get("theme");
        say "<br>app path: " . $self->app->var->get("path");
        say "<br>";
    ]]></vars>
    <br><br>

    html content 1-5 top
    <!--block:first-->
        <table border="1" style="color:red;">
        <tr class="lines">
            <td align="left" valign="<--valign-->">
                <b>bold</b><a href="http://www.mewsoft.com">mewsoft</a>
                <!--hello--> <--again--><!--world-->
                some html content here 1 top
                <!--block:second-->
                    some html content here 2 top
                    <!--block:third-->
                        some html content here 3 top
                        <!--block:fourth-->
                        some html content here 4 top
                            <!--block:fifth-->
                                some html content here 5a
                                some html content here 5b
                            <!--endblock-->
                        <!--endblock-->
                        some html content here 3a
                    some html content here 3b
                <!--endblock-->
            some html content here 2 bottom
            </tr>
        <!--endblock-->
        some html content here 1 bottom
    </table>
    <!--endblock-->
    html content 1-5 bottom

    <br><br>

    html content 6-8 top
    <!--block:six-->
        some html content here 6 top
        <!--block:seven-->
            some html content here 7 top
            <!--block:eight-->
                some html content here 8a
                some html content here 8b
            <!--endblock-->
            some html content here 7 bottom
        <!--endblock-->
        some html content here 6 bottom
    <!--endblock-->
    html content 6-8 bottom

    <br><br>

    <vars type="widget" name="footer" title="cairo" lang="ar" />

=head1 YOUR FIRST WIDGETS 'header' AND 'footer'

The framework supports widgets, widgets are small views that can be repeated in many views for easy layout and design.
For example, you could make the site header template as a widget called B<header> and the site footer template as a 
widget called B<footer> and just put the required xml special tag for these widgets in all the B<Views> you want.
Widgets files are html files located in the theme B<'widget'> folder

Example widget B<header.html>

    <!doctype html>
    <html lang="{lang_code}">
     <head>
      <meta http-equiv="content-type" content="text/html; charset=[:charset_name:]" />
      <title>{page_title}</title>
      <meta name="Keywords" content="{meta_keywords}" />
      <meta name="Description" content="{meta_description}" />
     </head>
     <body>

Example widget B<footer.html>

    </body>
    </html>

then all you need to include the widget in the view is to insert these tags:

    <vars type="widget" name="header" charset_name="UTF-8" />
    <vars type="widget" name="footer" />

You can pass args to the widget like B<charset_name> to the widget above and will be replaced with their values.


=head1 LANGUAGES

All application text is located in text files in xml format. Each language supported should be put under a folder named
with the iso name of the langauge under the folder path/lang.

Example langauge file B<'general.xml'>:

    <?xml version="1.0" encoding="UTF-8" ?>

    <lang_code>en</lang_code>
    <site_name>Site Name</site_name>
    <home>Home</home>
    <register>Register</register>
    <contact>Contact</contact>
    <about>About</about>
    <copyright>Copyright</copyright>
    <privacy>Privacy</privacy>

    <page_title>Create New Account</page_title>
    <first_name>First name:</first_name>
    <middle_name>Middle name:</middle_name>
    <last_name>Last name:</last_name>
    <full_name>Full name:</full_name>
    <email>Email:</email>
    <job>Job title:</job>
    <website>Website:</website>
    <agree>Agree:</agree>
    <company>Company</company>

    <date_now>Date: </date_now>
    <time_now>Time: </time_now>
    <date_time>Now: </date_time>

=head1 Routing

The framework supports url routing, route specific short name actions like 'register' to specific plugins like Accounts/Register/create.

Below is B<route.xml> file example should be created under the path/route folder.

    <?xml version="1.0" encoding="UTF-8" ?>

    <home route="/home" action="/Home/Home/home" method="get" />
    <register route="/register" action="/Accounts/Register/register" method="get" defaults="year=1900|month=1|day=23" />
    <post route="/blog/post/{cid:\d+}/{id:\d+}" action="/Blog/Article/Post" method="post" />
    <browse route="/blog/{id:\d+}" action="/Blog/Article/Browse" method="get" />
    <view route="/blog/view/{id:\d+}" action="/Blog/Article/View" method="get" />
    <edit route="/blog/edit/{id:\d+}" action="/Blog/Article/Edit" method="get" />

=head1 CONFIG

The framework supports loading and working with config files in xml formate located in the folder 'config'.

Example config file path/config/config.xml:

    <?xml version="1.0" encoding="UTF-8" ?>

    <app>
        <config></config>
        <route>route.xml</route>
        <log_file>log.pm</log_file>
        <action_name>action,route,cmd</action_name>
        <default_route>/Home/Home/home</default_route>
        <charset>utf-8</charset>
        <theme>default</theme>
        <lang>en-US</lang>
        <lang_param_key>lang</lang_param_key>
        <lang_cookie_key>lang</lang_cookie_key>
        <lang_session_key>lang</lang_session_key>
        <lang_file>general</lang_file>
    </app>

    <admin>
        <user>admin_user</user>
        <password>admin_pass</password>
    </admin>

    <dbi>
        <driver>mysql</driver>
        <host>localhost</host>
        <dsn></dsn>
        <port>3306</port>
        <name>auctions</name>
        <user>auctions</user>
        <pass>auctions</pass>
        <attr>
        </attr>
        <encoding>utf8</encoding>
    </dbi>

    <module>
        <home>
            <header>home</header>
            <footer>footer</footer>
        </home>
    </module>

    <plugin>
        <email>
            <transport>Sendmail</transport>
            <sendmail>/usr/sbin/sendmail</sendmail>
        </email>

        <session>
            <autoload>1</autoload>
            <key>nile_session_key</key>
            <expire>1 year</expire>
            <cache>
                <driver>File</driver>
                <root_dir></root_dir>
                <namespace>session</namespace>
            </cache>
            <cookie>
                <path>/</path>
                <secure></secure>
                <domain></domain>
                <httponly></httponly>
            </cookie>
        </session>

        <cache>
            <autoload>0</autoload>
        </cache>
    </plugin>

=head1 APPLICATION INSTANCE SHARED DATA

The framework is fully Object-oriented to allow multiple separate instances. Inside any module or plugin
you will be able to access the application instance by calling the method C<< $self->app >> which is automatically
injected into all modules with the application instance.

The plugins and modules files will have the following features.

Moose enabled
Strict and Warnings enabled.
a Moose attribute called C<app> injected holds the application singleton instance to access all the data and methods.

Inside your modules and plugins, you will be able to access the application instance by:
    
    my $app = $self->app;

Then you can access the application methods and objects like:
    
    $app->request->param("username");
    # same as
    $self->app->request->param("username");

    $app->response->code(200);

    $app->var->set("name", "value");

=head1 URL REWRITE .htaccess for CGI and FCGI

To hide the script name B<index.cgi> from the url and allow nice SEO url routing, you need to turn on url rewrite on
your web server and have .htaccess file in the application folder with the index.cgi.

Below is a sample .htaccess which redirects all requests to index.cgi file and hides index.cgi from the url, 
so instead of calling the application as:

    http://domain.com/index.cgi?action=register

using the .htaccess you will be able to call it as:

    http://domain.com/register

without any changes in the code.

For direct FCGI, just replace .cgi with .fcgi in the .htaccess and rename index.cgi to index.fcgi.

    # Don't show directory listings for URLs which map to a directory.
    Options -Indexes -MultiViews

    # Follow symbolic links in this directory.
    Options +FollowSymLinks

    #Note that AllowOverride Options and AllowOverride FileInfo must both be in effect for these directives to have any effect, 
    #i.e. AllowOverride All in httpd.conf
    Options +ExecCGI
    AddHandler cgi-script cgi pl 

    # Set the default handler.
    DirectoryIndex index.cgi index.html index.shtml

    # save this file as UTF-8 and enable the next line for utf contents
    #AddDefaultCharset UTF-8

    # REQUIRED: requires mod_rewrite to be enabled in Apache.
    # Please check that, if you get an "Internal Server Error".
    RewriteEngine On
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # force use www with http and https so http://domain.com redirect to http://www.domain.com
    #add www with https support - you have to put this in .htaccess file in the site root folder
    # skip local host
    RewriteCond %{HTTP_HOST} !^localhost
    # skip IP addresses
    RewriteCond %{HTTP_HOST} ^([a-z.]+)$ [NC]
    RewriteCond %{HTTP_HOST} !^www\. 
    RewriteCond %{HTTPS}s ^on(s)|''
    RewriteRule ^ http%1://www.%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} !=/favicon.ico
    RewriteRule ^(.*)$ index.cgi [L,QSA]

=head1 REQUEST

The http request is available as a shared object extending the L<CGI::Simple> module. This means that all methods supported
by L<CGI::Simple> is available with the additions of these few methods:

    is_ajax
    is_post
    is_get
    is_head
    is_put
    is_delete
    is_patch

You access the request object by $self->app->request.

=head1 ERRORS, WARNINGS, ABORTING
    
To abort the application at anytime with optional message and stacktrace, call the method:
    
    $self->app->abort("application error, can not find file required");

For fatal errors with custom error message
    
    $self->app->error("error message");

For fatal errors with custom error message and  full starcktrace
    
    $self->app->errors("error message");

For displaying warning message

    $self->app->warning("warning message");

=head1 LOGS

The framework supports a log object which is a L<Log::Tiny> object which supports unlimited log categories, so simply
you can do this:

    $app->log->info("application run start");
    $app->log->DEBUG("application run start");
    $app->log->ERROR("application run start");
    $app->log->INFO("application run start");
    $app->log->ANYTHING("application run start");

=head1 FILE

The file object provides tools for reading files, folders, and most of the functions in the modules L<File::Spec> and L<File::Basename>.

to get file content as single string or array of strings:
    
    $content = $app->file->get($file);
    @lines = $app->file->get($file);

supports options same as L<File::Slurp>.

To get list of files in a specific folder:
    
    #files($dir, $match, $relative)
    @files = $app->file->files("c:/apache/htdocs/nile/", "*.pm, *.cgi");
    
    #files_tree($dir, $match, $relative, $depth)
    @files = $app->file->files_tree("c:/apache/htdocs/nile/", "*.pm, *.cgi");

    #folders($dir, $match, $relative)
    @folders = $app->file->folders("c:/apache/htdocs/nile/", "", 1);

    #folders_tree($dir, $match, $relative, $depth)
    @folders = $app->file->folders_tree("c:/apache/htdocs/nile/", "", 1);

=head1 XML

Loads xml files into hash tree using L<XML::TreePP>
    
    $xml = $app->xml->load("configs.xml");

=head1 DBI

See L<Nile::DBI>

The DBI class provides methods for connecting to the sql database and easy methods for sql operations.

=head1 METHODS

=cut
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# the first thing to do, catch and show errors nicely
BEGIN {
    $|=1;
    use CGI::Carp qw(fatalsToBrowser warningsToBrowser set_message);
    use Devel::StackTrace;
    use Devel::StackTrace::AsHTML;
    use PadWalker;
    use Devel::StackTrace::WithLexicals;

    sub handle_errors {
        my $msg = shift;
        #my $trace = Devel::StackTrace->new(indent => 1, message => $msg, ignore_package => [qw(Carp CGI::Carp)]);
        my $trace = Devel::StackTrace::WithLexicals->new(indent => 1, message => $msg, ignore_package => [qw(Carp CGI::Carp)]);
        #$trace->frames(reverse $trace->frames);
        print $trace->as_html;
    }
    set_message(\&handle_errors);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use Moose;
use namespace::autoclean;
use MooseX::MethodAttributes;
#use MooseX::ClassAttribute;

use utf8;
use File::Spec;
use File::Basename;
use Cwd;
use URI;
use Encode ();
use URI::Escape;
use Crypt::RC4;
#use Crypt::CBC;
use Capture::Tiny ();
use Time::Local;
use File::Slurp;
use Time::HiRes qw(gettimeofday tv_interval);
use MIME::Base64 3.11 qw(encode_base64 decode_base64 decode_base64url encode_base64url);

use Data::Dumper;
$Data::Dumper::Deparse = 1; #stringify coderefs
#use LWP::UserAgent;

#no warnings qw(void once uninitialized numeric);

use Nile::App;
use Nile::Say;
use Nile::Plugin;
use Nile::Plugin::Object;
use Nile::Module;
use Nile::View;
use Nile::XML;
use Nile::Var;
use Nile::File;
use Nile::Lang;
use Nile::Config;
use Nile::Router;
use Nile::Dispatcher;
use Nile::DBI;
use Nile::Setting;
use Nile::Timer;
use Nile::HTTP::Request;
use Nile::HTTP::Response;

#use base 'Import::Base';
use Import::Into;
use Module::Load;
use Module::Runtime qw(use_module);
our @EXPORT_MODULES = (
        #strict => [],
        #warnings => [],
        Moose => [],
        utf8 => [],
        #'File::Spec' => [],
        #'File::Basename' => [],
        Cwd => [],
        'Nile::Say' => [],
        'MooseX::MethodAttributes' => [],
    );

use base 'Exporter';
our @EXPORT = qw();
our @EXPORT_OK = qw();
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub import {

    my ($class, @args) = @_;

    my ($package, $script) = caller;
    
    # import list of modules to the calling package
    my @modules = @EXPORT_MODULES;
    while (@modules) {
        my $module = shift @modules;
        my $imports = ref $modules[0] eq 'ARRAY' ? shift @modules : [];
        use_module($module)->import::into($package, @{$imports});
    }
    #------------------------------------------------------
    $class->detect_app_path($script);
    #------------------------------------------------------
    my $caller = $class.'::';
    {
        no strict 'refs';
        @{$caller.'EXPORT'} = @EXPORT;
        foreach my $sub (@EXPORT) {
            next if (*{"$caller$sub"}{CODE});
            *{"$caller$sub"} = \*{$sub};
        }
    }

    $class->export_to_level(1, $class, @args);
    #------------------------------------------------------
  }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub detect_app_path {

    my ($self, $script) = @_;

    $script ||= (caller)[1];

    my ($vol, $dirs, $name) =   File::Spec->splitpath(File::Spec->rel2abs($script));

    if (-d (my $fulldir = File::Spec->catdir($dirs, $name))) {
        $dirs = $fulldir;
        $name = "";
    }

    my $path = $vol? File::Spec->catpath($vol, $dirs) : File::Spec->catdir($dirs);
    
    $ENV{NILE_APP_DIR} = $path;

    return ($path);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub BUILD { # our sub new {...}
    my ($self, $arg) = @_;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 init()
    
    use Nile;

    my $app = Nile->new();

    $app->init({
        # base application path, auto detected if not set
        path        =>  dirname(File::Spec->rel2abs(__FILE__)),
        
        # load config files, default extension is xml
        config      => [ qw(config) ],

        # force run mode if not auto detected by default. modes: "psgi", "fcgi" (direct), "cgi" (direct)
        #mode   =>  "fcgi", # psgi, cgi, fcgi
    });

Initialize the application with the shared and safe sessions settings.

=cut

has 'init' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} }
);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 var()
    
See L<Nile::Var>.

=cut

has 'var' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
            shift->object ("Nile::Var", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 config()
    
See L<Nile::Config>.

=cut

has 'config' => (
      is      => 'rw',
      isa     => 'Nile::Config',
      lazy  => 1,
      default => sub {
            shift->object("Nile::Config", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 run()
    
    $app->run();

Run the application and dispatch the command.

=cut

sub run {

    my ($self, $arg) = @_;
    
    #$self->log->info("application run start in mode: ". uc($self->mode));
    #say "run_time: " . $self->run_time->total;
    #------------------------------------------------------
    $arg = $self->init();

    my ($package, $script) = caller;
    
    $arg->{path} ||= $self->detect_app_path($script);

    my $file = $self->file;

    # setup the path for the app folders
    foreach (qw(api cache cmd config cron data file lib log route temp web)) {
        $self->var->set($_."_dir" => $file->catdir($arg->{path}, $_));
    }

    $self->var->set(
            'path'              =>  $arg->{path},
            'base_dir'          =>  $arg->{path},
            'langs_dir'         =>  $file->catdir($arg->{path}, "lang"),
            'themes_dir'        =>  $file->catdir($arg->{path}, "theme"),
            'log_file'          =>  $arg->{log_file} || "log.pm",
            'action_name'       =>  $arg->{action_name} || "action,route,cmd",
            'default_route'     =>  $arg->{default_route} || "/Home/Home/index",
        );
    
    push @INC, $self->var->get("lib_dir");
    #------------------------------------------------------
    # detect and load request and response handler classes
    $arg->{mode} ||= "cgi";
    $arg->{mode} = lc($arg->{mode});
    $self->mode($arg->{mode});
    
    #$self->log->debug("mode: $arg{mode}");

    # force PSGI if PLACK_ENV is set
    if ($ENV{'PLACK_ENV'}) {
        $self->mode("psgi");
    }
    #$self->log->debug("mode after PLACK_ENV: $arg{mode}");
    
    # FCGI sets $ENV{GATEWAY_INTERFACE }=> 'CGI/1.1' inside the accept request loop but nothing is set before the accept loop
    # command line invocations will not set this variable also
    if ($self->mode() ne "psgi") {
        if (exists $ENV{GATEWAY_INTERFACE} ) {
            # CGI
            $self->mode("cgi");
        }
        else {
            # FCGI or command line
            $self->mode("fcgi");
        }
    }
    
    #$self->log->debug("mode to run: $arg{mode}");

    if ($self->mode() eq "psgi") {
        load Nile::HTTP::Request::PSGI;
        load Nile::Handler::PSGI;
    }
    elsif ($self->mode() eq "fcgi") {
        load Nile::HTTP::Request;
        load Nile::Handler::CGI;
        load Nile::Handler::FCGI;
    }
    else {
        load Nile::HTTP::Request;
        load Nile::Handler::CGI;
    }
    #------------------------------------------------------
    # load config files from init
    foreach (@{$arg->{config}}) {
        #$self->config->xml->keep_order(1);
        $self->config->load($_);
    }
    #------------------------------------------------------
    #------------------------------------------------------
    # load extra config files from config files settings
    foreach my $config ($self->config->get("app/config")) {
        $config = $self->filter->trim($config);
        $self->config->load($config) if ($config);
    }
    #------------------------------------------------------
    # load route files
    foreach my $route($self->config->get("app/route")) {
        $route = $self->filter->trim($route);
        $self->router->load($route) if ($route);
    }
    #------------------------------------------------------
    foreach my $config (qw(charset action_name lang theme default_route log_file)) {
        if ($self->config->get("app/$config")) {
            $self->var->set($config, $self->config->get("app/$config"));
        }
    }
    #------------------------------------------------------
    my $class = "Nile::Handler::" . uc($self->mode());
    my $handler = $self->object($class);
    my $psgi = $handler->run();

    #say "run_time: " . $self->run_time->total;
    #$self->log->info("application run end");
    
    # return the PSGI app
    return $psgi;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 prefix()
    
    # from here, any route handler is defined to /forum/*:
    $app->prefix("/forum");
    
    # will match '/forum/login'
    $app->action("get", "/login", sub {return "Forum login"});

Defines a prefix for each route handler from now on.

=cut

has 'prefix' => (
      is      => 'rw',
      default => "",
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 action()
    
    # inline actions, return content. url: /forum/home
    $app->action("get", "/forum/home", sub {
        my ($self) = @_;
        # $self is set to the application context object same as $self->app in plugins
        my $content = "Host: " . ($self->request->virtual_host || "") ."<br>\n";
        $content .= "Request method: " . ($self->request->request_method || "") . "<br>\n";
        $content .= "App Mode: " . $self->mode . "<br>\n";
        $content .= "Time: ". time . "<br>\n";
        $content .= "Hello world from inline action /forum/home" ."<br>\n";
        $content .= "أحمد الششتاوى" ."<br>\n";
        $self->response->encoded(0); # encode content
        return $content;
    });

Add inline action, return content to the dispatcher.

=cut

sub action {
    my $self = shift;
    $self->add_action_route(undef, @_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 capture()
    
    # inline actions, capture print statements, no returns. url: /accounts/login
    $app->capture("get", "/accounts/login", sub {
        my ($self) = @_;
        # $self is set to the application context object same as $self->app in plugins
        say "Host: " . ($self->request->virtual_host || "") . "<br>\n";
        say "Request method: " . ($self->request->request_method || "") . "<br>\n";
        say "App Mode: " . $self->mode . "<br>\n";
        say "Time: ". time . "<br>\n";
        say "Hello world from inline action with capture /accounts/login", "<br>\n";
        say $self->encode("أحمد الششتاوى ") ."<br>\n";
        $self->response->encoded(1); # content already encoded
    });

Add inline action, capture print statements, no returns to the dispatcher.

=cut

sub capture {
    my $self = shift;
    $self->add_action_route("capture", @_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 command()
    
    # inline actions, capture print statements and return value. url: /blog/new
    $app->command("get", "/blog/new", sub {
        my ($self) = @_;
        # $self is set to the application context object same as $self->app in plugins
        say "Host: " . ($self->request->virtual_host || "") . "<br>\n";
        say "Request method: " . ($self->request->request_method || "") . "<br>\n";
        say "App Mode: " . $self->mode . "<br>\n";
        say "Time: ". time . "<br>\n";
        say "Hello world from inline action with capture /blog/new and return value.", "<br>\n";
        say $self->encode("أحمد الششتاوى ") ."<br>\n";
        $self->response->encoded(1); # content already encoded
        return " This value is returned from the command.";
    });

Add inline action, capture print statements and returns to the dispatcher.

=cut

sub command {
    my $self = shift;
    $self->add_action_route("command", @_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub add_action_route {
    my $self = shift;
    my $type = shift;
    my ($method, $route, $action) = $self->action_args(@_);
    if ($self->prefix) {
        $route = $self->prefix.$route;
    }
    $self->router->add_route(
                            name  => "",
                            path  => $route,
                            target  => $action,
                            method  => $method,
                            defaults  => {
                                    #id => 1
                                },
                            attributes => $type,
                        );
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub action_args {
    
    my $self = shift;

    #my @methods = qw(get post put patch delete options head);

    my ($method, $route, $action);

    if (@_ == 1) {
        #$app->action(sub {});
        ($action) = @_;
    }
    elsif (@_ == 2) {
        #$app->action("/home", sub {});
        ($route, $action) = @_;
    }
    elsif (@_ == 3) {
        #$app->action("get", "/home", sub {});
        ($method, $route, $action) = @_;
    }
    else {
        $self->abort("Action error. Empty action and route. Syntax \$app->action(\$method, \$route, \$coderef) ");
    }

    $method ||= "";
    $route ||= "/";
    
    if (ref($action) ne "CODE") {
        $self->abort("Action error, must be a valid code reference. Syntax \$app->action(\$method, \$route, \$coderef) ");
    }
    
    return ($method, $route, $action);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 router()
    
See L<Nile::Router>.

=cut

has 'router' => (
      is      => 'rw',
      isa    => 'Nile::Router',
      lazy  => 1,
      default => sub {
            shift->object("Nile::Router", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 filter()
    
See L<Nile::Filter>.

=cut

has 'filter' => (
      is      => 'rw',
      isa    => 'Nile::Filter',
      lazy  => 1,
      default => sub {
            load Nile::Filter;
            shift->object("Nile::Filter", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 file()

See L<Nile::File>.

=cut

has 'file' => (
      is      => 'rw',
      default => sub {
            shift->object("Nile::File", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 xml()
    
See L<Nile::XML>.

=cut

has 'xml' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
            my $self = shift;
            $self->object("Nile::XML", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 mode()
    
    my $mode = $app->mode;

Returns the current application mode PSGI, FCGI or CGI.

=cut

has 'mode' => (
      is      => 'rw',
      isa     => 'Str',
      default => "cgi",
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 lang()
    
See L<Nile::Lang>.

=cut

has 'lang' => (
      is      => 'rw',
      isa    => 'Nile::Lang',
      lazy  => 1,
      default => sub {
            shift->object("Nile::Lang", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 object()
    
    $obj = $app->object("Nile::MyClass", @args);
    $obj = $app->object("Nile::Plugin::MyClass", @args);
    $obj = $app->object("Nile::Module::MyClass", @args);

    #...

    $me = $obj->app;
    
Creates and returns an object. This automatically adds the method L<me> to the object
and sets it to the current context so your object or class can access the current instance.

=cut

sub object {

    my ($self, $class, @args) = @_;
    my ($object);
    
    #if (@args == 1 && ref($args[0]) eq "HASH") {
    #   # Moose single arguments must be hash ref
    #   $object = $class->new(@args);
    #}

    if (@args && @args % 2) {
        # Moose needs args as hash, so convert odd size arrays to even for hashing
        $object = $class->new(@args, undef);
    }
    else {
        $object = $class->new(@args);
    }

    #$meta->add_method( 'hello' => sub { return "Hello inside hello method. @_" } );
    #$meta->add_class_attribute( $_, %options ) for @{$attrs}; #MooseX::ClassAttribute
    #$meta->add_class_attribute( 'cash', ());

    # add attribute "app" to the object
    $self->add_object_context($object);
    
    # if class has defined "main" method, then call it
    if ($object->can("main")) {
        my %ret = $object->main(@args);
        if ($ret{rebless}) {
            $object = $ret{rebless};
        }
    }
        
    return $object;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub add_object_context {
    my ($self, $object) = @_;
    my $meta = $object->meta;
    # add method "app" or one of its alt
    if (!$object->can("app")) {
        $meta->add_attribute(app => (is => 'rw', default => sub{$self}));
    }
    $object->app($self);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 dump()
    
    $app->dump({...});

Print object to the STDOUT. Same as C<say Dumper (@_);>.

=cut

sub dump {
    my $self = shift;
    say Dumper (@_);
    return;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 is_loaded()
    
    if ($app->is_loaded("Nile::SomeModule")) {
        #...
    }
    
    if ($app->is_loaded("Nile/SomeModule.pm")) {
        #...
    }

Returns true if module is loaded, false otherwise.

=cut

sub is_loaded {
    my ($self, $module) = @_;
    (my $file = $module) =~ s/::/\//g;
    $file .= '.pm' unless ($file =~ /\.pm$/);
    #note: do() does unconditional loading -- no lookup in the %INC hash is made.
    exists $INC{$file};
    #return eval { $module->can( 'can' ) };
    #return UNIVERSAL::can($module,'can');
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has 'loaded_modules' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} }
);
=head2 load_once()
    
    $app->load_once("Module::SomeModule");

Load modules if not already loaded.

=cut

sub load_once {
    my ($self, $module, @arg) = @_;
    if (!exists $self->loaded_modules->{$module}) {
        load $module;
        $self->loaded_modules->{$module} = 1;
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 load_class()
    
    $app->load_class("Module::SomeModule");

Load modules if not already loaded.

=cut

sub load_class {
    my ($self, $module, @arg) = @_;

    if (!$self->is_loaded($module)) {
        load $module;
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 cli_mode()
    
    if ($app->cli_mode) {
        say "Running from the command line";
    }
    else {
        say "Running from web server";
    }

Returns true if running from the command line interface, false if called from web server.

=cut

sub cli_mode {
    my ($self) = @_;
    
    if  (exists $ENV{REQUEST_METHOD} || defined $ENV{GATEWAY_INTERFACE} ||  exists $ENV{HTTP_HOST}){
        return 0;
    }
    
    # PSGI
    if  (exists $self->env->{REQUEST_METHOD} || defined $self->env->{GATEWAY_INTERFACE} ||  exists $self->env->{HTTP_HOST}){
        return 0;
    }
    
    # CLI
    return 1;

    #if (-t STDIN) { }
    #use IO::Interactive qw(is_interactive interactive busy);if ( is_interactive() ) {print "Running interactively\n";}
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 error()
    
    $app->error("error message");

Fatal errors with custom error message. This is the same as C<croak> in L<CGI::Carp|CGI::Carp/croak>.

=cut

sub error {
    my $self = shift;
    goto &CGI::Carp::croak;
}

=head2 errors()
    
    $app->errors("error message");

Fatal errors with custom error message and full starcktrace. This is the same as C<confess> in L<CGI::Carp|CGI::Carp/confess>.

=cut

sub errors {
    my $self = shift;
    goto &CGI::Carp::confess;
}

=head2 warn()
    
    $app->warn("warning  message");

Display warning message. This is the same as C<carp> in L<CGI::Carp|CGI::Carp/carp>.

To view warnings in the browser, switch to the view source mode since warnings appear as
a comment at the top of the page.

=cut

sub warn {
    my $self = shift;
    # warnings appear commented at the top of the page, use view source
    warningsToBrowser(1) unless ($self->cli_mode);
    goto &CGI::Carp::carp;
}

=head2 warns()
    
    $app->warns("warning  message");

Display warning message and full starcktrace. This is the same as C<cluck> in L<CGI::Carp|CGI::Carp/cluck>.

To view warnings in the browser, switch to the view source mode since warnings appear as
a comment at the top of the page.

=cut

sub warns {
    my $self = shift;
    # warnings appear commented at the top of the page, use view source
    warningsToBrowser(1) unless ($self->cli_mode);
    goto &CGI::Carp::cluck;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 abort()
    
    $app->abort("error message");

    $app->abort("error title", "error message");

Stop and quit the application and display message to the user. See L<Nile::Abort> module.

=cut

sub abort {
    my ($self) = shift;
    load Nile::Abort;
    Nile::Abort->abort(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#__PACKAGE__->meta->make_immutable;#(inline_constructor => 0)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 Sub Modules

App L<Nile::App>.

Views   L<Nile::View>.

Shared Vars L<Nile::Var>.

Langauge    L<Nile::Lang>.

Request L<Nile::HTTP::Request>.

PSGI Request    L<Nile::HTTP::Request::PSGI>.

PSGI Request Base   L<Nile::HTTP::PSGI>.

Response    L<Nile::HTTP::Response>.

PSGI Handler L<Nile::Handler::PSGI>.

FCGI Handler L<Nile::Handler::FCGI>.

CGI Handler L<Nile::Handler::CGI>.

Dispatcher L<Nile::Dispatcher>.

Router L<Nile::Router>.

File Utils L<Nile::File>.

DBI L<Nile::DBI>.

DBI Table L<Nile::DBI::Table>.

XML L<Nile::XML>.

Settings    L<Nile::Setting>.

Serializer L<Nile::Serializer>.

Deserializer L<Nile::Deserializer>.

Serialization Base L<Nile::Serialization>.

Filter  L<Nile::Filter>.

MIME L<Nile::MIME>.

Timer   L<Nile::Timer>.

Plugin  L<Nile::Plugin>.

Session L<Nile::Plugin::Session>.

Cache L<Nile::Plugin::Cache>.

Cache Redis L<Nile::Plugin::Cache::Redis>.

Email L<Nile::Plugin::Email>.

Paginatation L<Nile::Plugin::Paginate>.

MongoDB L<Nile::Plugin::MongoDB>.

Redis L<Nile::Plugin::Redis>.

Memcached L<Nile::Plugin::Memcached>.

Module L<Nile::Module>.

Hook L<Nile::Hook>.

Base L<Nile::Base>.

Abort L<Nile::Abort>.

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


1;
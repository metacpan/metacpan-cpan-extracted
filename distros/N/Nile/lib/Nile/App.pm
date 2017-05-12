#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::App;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::App - App base class for the Nile framework.

=head1 SYNOPSIS

=head1 DESCRIPTION

Nile::App - App base class for the Nile framework.

=cut

use Module::Load;
use Data::Dumper;
$Data::Dumper::Deparse = 1; #stringify coderefs
use HTTP::AcceptLanguage;
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
use DateTime ();

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
use Nile::Timer;
use Nile::HTTP::Request;
use Nile::HTTP::Response;

use Nile::Base;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Application 'Nile' object instance
has 'app' => (
    is => 'rw',
    default => undef
);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub BUILD {
    my ($self, $arg) = @_;
    $self->app($arg->{app});
    # start the app page load timer
    $self->run_time->start();
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 object()
    
    $obj = $app->object("Nile::MyClass", @args);
    $obj = $app->object("Nile::Plugin::MyClass", @args);
    $obj = $app->object("Nile::Module::MyClass", @args);

    #...

    $app = $obj->app;
    $request = $app->request;
    $response = $app->response;
    
Creates and returns an object. This automatically adds the method L<app> to the object
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
=head2 start()
    
    $app->start;

Set the application startup variables.

=cut

sub start {

    my ($self) = @_;
    #------------------------------------------------------
    my $app = $self->app;
    my $file = $self->file;
    
    # shared vars
    my %arg = $app->var->vars();

    $self->var->set(%arg);

    #$self->dump({$app->var->vars()});
    #$self->dump({$self->var->vars()});

    my $path = $self->var->get("path");

    $arg{lang} ||= "";
    $arg{theme} ||= "default";

    # detect user language
    $arg{lang} = $self->detect_user_language($arg{lang});
    
    foreach (qw(api cache cmd config cron data file lib log route temp web)) {
        $self->var->set($_."_dir" => $file->catdir($path, $_));
    }

    $self->var->set(
            'lang'              =>  $arg{lang},
            'theme'             =>  $arg{theme},
            'lang_dir'          =>  $file->catdir($path, "lang", $arg{lang}),
            'theme_dir'         =>  $file->catdir($path, "theme", $arg{theme}),
        );
    
    # load language files
    foreach ($self->config->get("app/lang_file")) {
        $self->lang->load($_);
    }
    #------------------------------------------------------
    #$self->hook->on_start;

    my $req = $self->request;

    # global variables, safe to render in views
    $self->var->set(
            url => $req->url,
            base_url => $req->base_url,
            abs_url => $req->abs_url,
            url_path => $req->url_path,
        );

    #$self->uri_mode(1);
    # app folders url's
    foreach (qw(api cache file temp web)) {
        $self->var->set($_."_url" => $self->uri_for("$_/"));
    }
    
    # themes and current theme url's
    $self->var->set(
            themes_url => $self->uri_for("theme/"),
            theme_url => $self->uri_for("theme/$arg{theme}/"),
        );
    
    # theme folders
    foreach (qw(css icon image js view widget)) {
        $self->var->set($_."_url" => $self->uri_for("theme/$arg{theme}/$_/"));
        $self->var->set($_."_dir" => $file->catdir($self->var->get("theme_dir"), $_));
    }
    #------------------------------------------------------
    # load plugins set to autoload in the config files
    while (my ($name, $plugin) = each %{$self->config->get("plugin")} ) {
        next if (!$plugin->{autoload});
        $name = ucfirst($name);
        my $class = "Nile::Plugin::$name";
        if (!$self->is_loaded($class)) {
            load $class;
            $self->plugin->$name;
        }
    }
    #------------------------------------------------------
    # connect to database
    if ($self->config->get("db_connect")) {
        $self->connect;
    }
    #------------------------------------------------------
    #$self->hook->off_start;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 mode()
    
    my $mode = $app->mode;

Returns the current application mode PSGI, FCGI or CGI.

=cut

has 'mode' => (
      is      => 'rw',
      isa     => 'Str',
      lazy  => 1,
      default => sub {shift->app->mode(@_)},
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 config()
    
See L<Nile::Config>.

=cut

has 'config' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
          shift->app->config(@_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 router()
    
See L<Nile::Router>.

=cut

has 'router' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
            shift->app->router(@_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 lang()
    
See L<Nile::Lang>.

=cut

has 'lang' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
            #shift->app->lang(@_);
            shift->object("Nile::Lang", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 uri_mode()
    
    # uri mode: 0=full, 1=absolute, 2=relative
    $app->uri_mode(1);

Set the uri mode. The values allowed are: 0= full, 1=absolute, 2=relative

=cut

has 'uri_mode' => (
    is => 'rw',
    default => 0, # 0= full, 1=absolute, 2=relative
);

=head2 uri_for()
    
    $url = $app->uri_for("/users", [$mode]);

Returns the uri for specific action or route. The mode parameter is optional. The mode values allowed are: 0= full, 1=absolute, 2=relative.

=cut

sub uri_for {
    my ($self, $uri, $mode) = @_;
    
    if (!defined $mode) {
        $mode = $self->uri_mode;
    }

    if ($self->uri_mode == 1) {
        return $self->var->get("abs_url") . $uri;
    }
    else {
        return $self->var->get("base_url") . $uri;
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub forward {
    my ($self, $uri) = @_;
    
    #$me->forward($uri);

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 debug()
    
    # 1=enabled, 0=disabled
    $app->debug(1);

Enable or disable debugging flag.

=cut

has 'debug' => (
      is      => 'rw',
      isa     => 'Bool',
      default => 0,
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 bm()
    
    $app->bm->lap("start task");
    ....
    $app->bm->lap("end task");
    
    say $app->bm->stop->summary;

    # NAME          TIME        CUMULATIVE      PERCENTAGE
    # start task        0.123       0.123           34.462%
    # end task      0.234       0.357           65.530%
    # _stop_        0.000       0.357           0.008%
    
    say "Total time: " . $app->bm->total_time;

Benchmark specific parts of your code. This is a L<Benchmark::Stopwatch> object.

=cut

has 'bm' => (
      is      => 'rw',
      lazy  => 1,
      default => sub{
          #autoload, load CGI, ':all';
          load Benchmark::Stopwatch;
          Benchmark::Stopwatch->new->start;
      }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 file()
    
See L<Nile::File>.

=cut

has 'file' => (
      is      => 'rw',
      lazy  => 1,
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
            shift->object("Nile::XML", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 setting()
    
See L<Nile::Setting>.

=cut

has 'setting' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
            load Nile::Setting;
            shift->object("Nile::Setting", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 mime()
    
See L<Nile::MIME>.

=cut

has 'mime' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
            load Nile::MIME;
            shift->object("Nile::MIME", only_complete => 1);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 dispatcher()
    
See L<Nile::Dispatcher>.

=cut

has 'dispatcher' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
            shift->object("Nile::Dispatcher", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 logger()
    
Returns L<Log::Tiny> object.

=cut

has 'logger' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
            my $self = shift;
            load Log::Tiny;
            Log::Tiny->new($self->file->catfile($self->var->get("log_dir"), $self->var->get("log_file") || 'log.pm'));
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 log()

    $app->log->info("application run start");
    $app->log->DEBUG("application run start");
    $app->log->ERROR("application run start");
    $app->log->INFO("application run start");
    $app->log->ANYTHING("application run start");

 Log object L<Log::Tiny> supports unlimited log categories.

=cut

sub log {
    my $self = shift;
    $self->start_logger if (!$self->logger);
    $self->logger(@_);
}

=head2 start_logger()
    
    $app->start_logger();

Start the log object and open the log file for writing logs.

=cut

sub start_logger {
    my $self = shift;
    $self->stop_logger;
    $self->logger(Log::Tiny->new($self->file->catfile($self->var->get("log_dir"), $self->var->get("log_file") || 'log.pm')));
}

=head2 stop_logger()
    
    $app->stop_logger();

Stops the log object and close the log file.

=cut

sub stop_logger {
    my $self = shift;
    # close log file
    $self->logger(undef);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 timer()
    
    # start the timer
    $app->timer->start;
    
    # do some operations...
    
    # get time elapsed since start called
    say $app->timer->lap;

    # do some other operations...

    # get time elapsed since last lap called
    say $app->timer->lap;

    # get another timer object, timer automatically starts
    my $timer = $app->timer->new;
    say $timer->lap;
    #...
    say $timer->lap;
    #...
    say $timer->total;

Returns L<Nile::Timer> object. See L<Nile::Timer> for more details.

=cut

has 'timer' => (
      is      => 'rw',
      #lazy => 1,
      default => sub{
          Nile::Timer->new;
      }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# page load timer, run time

=head2 run_time()
    
    # get time elapsed since app started
    say $app->run_time->lap;

    # do some other operations...

    # get time elapsed since last lap called
    say $app->run_time->lap;

Returns L<Nile::Timer> object. Timer automatically starts with the application.

=cut

has 'run_time' => (
      is      => 'rw',
      #lazy => 1,
      default => sub{
          Nile::Timer->new;
      }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 var()
    
See L<Nile::Var>.

=cut

has 'var' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
          shift->object("Nile::Var", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 env()
    
    $request_uri = $app->env->{REQUEST_URI};

Application env object for CGI and Plack/PSGI.

=cut

has 'env' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { \%ENV }
);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 browser()
    
    $browser = $app->browser;
    say $browser->version;
    say $browser->browser_string;
    say $browser->os_string;
    if ($browser->mobile) { say "Mobile device"; }

Determine Web browser, version, and platform. Returns L<HTTP::BrowserDetect> object.

=cut

has 'browsers' => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        load HTTP::BrowserDetect;
        HTTP::BrowserDetect->new(shift->env->{HTTP_USER_AGENT})
    }
);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 request()
    
See L<Nile::Request>.

=cut

has 'request' => (
    is      => 'rw',
    lazy    => 1,
    default => sub {},
);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 response()
    
See L<Nile::Response>.

=cut

has 'response' => (
      is      => 'rw',
      isa    => 'Nile::HTTP::Response',
      lazy  => 1,
      default => sub {
            shift->object("Nile::HTTP::Response", @_);
        }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 plugin()
    
See L<Nile::Plugin>.

=cut

has 'plugin_object' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
            shift->object("Nile::Plugin::Object", @_);
        }
  );

has 'plugin_loaded' => (
    is => 'rw',
    lazy    => 1,
    isa => 'HashRef',
    default => sub { +{} }
  );

sub plugin {

    my ($self, $plugin) = @_;

    if (!$plugin) {
        return $self->plugin_object;
    }

    if ($plugin !~ /::/) {
        return $self->plugin_object->$plugin;
    }

    my $name = "Nile::Plugin::" . ucfirst($plugin);

	
	return $self->plugin_loaded->{$plugin} if ($self->plugin_loaded->{$plugin});

    eval "use $name";
    
    if ($@) {
        $self->abort("Plugin Error: $name. $@");
    }

    $self->plugin_loaded->{$plugin}= $self->object($name, @_);

    return $self->plugin_loaded->{$plugin};
}

sub plugins {
    my ($self, $plugin) = @_;
    if ($plugin !~ /::/) {
        return $self->plugin->$plugin;
    }

    my $name = "Nile::Plugin::" . ucfirst($plugin);

	
	return $self->plugin_loaded->{$plugin} if ($self->plugin_loaded->{$plugin});

    eval "use $name";
    
    if ($@) {
        $self->abort("Plugins Error: $name. $@");
    }

    $self->plugin_loaded->{$plugin}= $self->object($name, @_);

    return $self->plugin_loaded->{$plugin};

    #$self->object("Nile::Plugin::Object", $plugin);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 helper()
    
    # add helper method to the framework
    
    $app->helper($method => $coderef);
    
    # add method "echo"
    $app->helper("echo" => sub{shift; say @_;});

    # access the helper method normal from plugins and modules
    $app->echo("Helper echo example.");

=cut

sub helper {
    my ($self, %arg) = @_;
    while (my($name, $code) = each %arg) {
        if (ref($code) ne "CODE") {
            $self->abort("Helper setup error: helper '$name' code should be a code ref. $code");
        }

        if (!$self->can($name)) {
            $self->meta->add_method($name => $code);
        }
        else {
            $self->abort("Helper setup error: helper '$name' method already exists. $code");
        }

    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 attr()
    
    # add attr to the framework
    
    $app->attr($name => $default);
    
    # add attribute "PI"
    $app->attr("PI" => 4 * atan2(1, 1));
    
    # or
    $app->attr("PI" => sub{4 * atan2(1, 1)});

    # get the attribute value
    say $app->PI;

    # set the the attribute value to new value
    $app->PI(3.14159265358979);

=cut

sub attr {
    my ($self, %arg) = @_;
    while (my($name, $code) = each %arg) {
        if (!$self->can($name)) {
            $self->meta->add_attribute($name => (is => 'rw', lazy=>1, default => $code));
        }
        else {
            $self->abort("Attr setup error: attr '$name' already exists. $code");
        }
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 ua()
    
    my $response = $app->ua->get('http://example.com/');
    say $response->{content} if length $response->{content};
    
    $response = $app->ua->get($url, \%options);
    $response = $app->ua->head($url);
    
    $response = $app->ua->post_form($url, $form_data);
    $response = $app->ua->post_form($url, $form_data, \%options);

Simple HTTP client. This is a L<HTTP::Tiny> object.

=cut

has 'ua' => (
      is      => 'rw',
      isa    => 'HTTP::Tiny',
      lazy  => 1,
      #trigger => sub {shift->clearer},
      default => sub {
          load HTTP::Tiny;
          HTTP::Tiny->new;
      }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 uri()
    
    my $uri = $app->uri('http://mewsoft.com/');

Returns L<URI> object.

=cut

has 'uri' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
          load URI;
          URI->new;
      }
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 charset()
    
    $app->charset('utf8');
    $charset = $app->charset;

Set or return the charset for encoding and decoding. Default is C<utf8>.

=cut

has 'charset' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {shift->var->get("charset")}
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 freeze()
    
See L<Nile::Serializer>.

=cut

has 'freeze' => (
      is      => 'rw',
      isa    => 'Nile::Serializer',
      lazy  => 1,
      default => sub {
          load Nile::Serializer;
          Nile::Serializer->new;
      }
  );
sub serialize {shift->freeze(@_);}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 thaw()
    
See L<Nile::Deserializer>.

=cut

has 'thaw' => (
      is      => 'rw',
      isa    => 'Nile::Deserializer',
      lazy  => 1,
      default => sub {
          load Nile::Deserializer;
          Nile::Deserializer->new;
      }
  );
sub deserialize {shift->thaw(@_);}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 module()
    
    # load module Nile::Module::Home::Contact and create a new object
    $contact = $me->module("Home::Contact");

    # to get another new instance
    $contact1 = $me->module("Home::MyModule")->new();
    # or
    $contact2 = $contact->new();

    # if you are calling from inside the Home module, you can just use
    $contact = $me->module("Contact");

    # of course you can load sub classes
    $send = $me->module("Home::Contact::Send");

    # if you are calling from inside the Home module, you can just use
    $send = $me->module("Contact::Send");

    # all the above is the same as
    use Nile::Module::Home::Contact;
    $contact = Nile::Module::Home::Contact->new();
    $contact->main() if ($contact->can("main"));

Load modules classes.

=cut

sub module {
    
    my ($self, $module) = @_;
    
    my ($package, $script) = caller;
    my ($class, $method) = $package =~ /^(.*)::(\w+)$/;
    
    $module = ucfirst($module);
    my $name;

    if ($module =~ /::/) {
        # module("Home::Contact") called from any module
        $name = "Nile::Module::" . $module;
    }
    else {
        # module("Contact") called from Home module
        $name = $class . "::" . $module;
    }

    return $self->{module}->{$name} if ($self->{module}->{$name});

    eval "use $name";
    
    if ($@) {
        $self->abort("Module Load Error: $name . $@");
    }

    $self->{module}->{$name} = $self->object($name, @_);

    return $self->{module}->{$name};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 hook()
    
See L<Nile::Hook>.

=cut

has 'hook' => (
      is      => 'rw',
      lazy  => 1,
      default => sub {
            load Nile::Hook;
            shift->object("Nile::Hook", @_);
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
=head2 session()
    
See session plugin L<Nile::Plugin::Session>.

=cut

has 'session' => (
    is => 'rw',
    lazy    => 1,
    isa => 'HashRef',
    default => sub { +{} }
);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 date()

    # get date object with time set to from epoch time
    my $dt = $app->date(time());
    
    # the same
    my $dt = $app->date(epoch => time());
    
    # object with time component
    my $dt = $app->date(
            year       => 2014,
            month      => 9,
            day        => 3,
            hour       => 22,
            minute     => 12,
            second     => 24,
            nanosecond => 500000000,
            time_zone  => 'Africa/Cairo',
        );
    
    # get date object with time set to now
    my $dt = $app->date;

    # then all methods of DateTime module is available
    $dt->set_time_zone('America/Chicago');
    $dt->strftime("%a, %d %b %Y %H:%M:%S");
    $ymd = $dt->ymd('/');

Date and time object wrapper around L<DateTime> module.

=cut

sub date {
    my ($self) = shift;
    if (scalar @_ == 1) {
        return DateTime->from_epoch(epoch => shift);
    }
    elsif (scalar @_ > 1) {
        my %arg = @_;
        if (exists $arg{epoch}) {
            return DateTime->from_epoch(epoch => $arg{epoch});
        }
        return DateTime->new(%arg);
        
    }
    else {
        return DateTime->now;
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has 'dbh' => (
      is      => 'rw',
  );

has 'db' => (
      is      => 'rw',
  );

sub connect {
    my $self = shift;
    $self->db($self->object("Nile::DBI"));
    $self->dbh($self->db->connect(@_));
    $self->db;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new_request {
    
    my ($self, $env) = @_;

    if (defined($env) && ref ($env) eq "HASH") {
        $self->mode("psgi");
        #load Nile::HTTP::PSGI;
        $self->request($self->object("Nile::HTTP::Request::PSGI", $env));
    }
    else {
        $self->request($self->object("Nile::HTTP::Request"));
    }
    
    $self->request();
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 detect_user_language()
    
    $user_lang = $app->detect_user_language;

Detects and retuns the user langauge.

=cut

sub detect_user_language {
    my ($self, $default) = @_;

    if ($self->request->param($self->config->get("app/lang_param_key"))) {
        return $self->request->param($self->config->get("app/lang_param_key"));
    }
    
    if ($self->session->{$self->config->get("app/lang_session_key")}) {
        return $self->session->{$self->config->get("app/lang_session_key")};
    }

    if ($self->request->cookie($self->config->get("app/lang_cookie_key"))) {
        return $self->request->cookie($self->config->get("app/lang_cookie_key"));
    }

    # detect user browser language settings
    my @langs = $self->lang_list();
    my $lang = HTTP::AcceptLanguage->new($ENV{HTTP_ACCEPT_LANGUAGE})->match(@langs);

    $lang ||= $default ||= $langs[0] ||= "en-US";

    return $lang;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 view()
    
Returns L<Nile::View> object.

=cut

sub view {
    my ($self) = shift;
    return $self->object("Nile::View", @_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 dbi()
    
Returns L<Nile::DBI> object.

=cut

sub dbi {
    my ($self) = shift;
    return $self->object("Nile::DBI", @_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 theme_list()
    
    @themes = $app->theme_list;

Returns themes names installed.

=cut

sub theme_list {
    my ($self) = @_;
    my @folders = ($self->file->folders($self->var->get("themes_dir"), "", 1));
    return grep (/^[^_]/, @folders);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 lang_list()
    
    @langs = $app->lang_list;

Returns languages names installed.

=cut

sub lang_list {
    my ($self) = @_;
    my @folders = ($self->file->folders($self->var->get("langs_dir"), "", 1));
    return grep (/^[^_]/, @folders);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 dump()
    
    $app->dump({...});

Print object to the STDOUT. Same as C<say Dumper (@_);>.

=cut

sub dump {
    return shift->app->dump(@_);
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
    shift->app->is_loaded(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub load_once {
    shift->app->load_once(@_);
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
    shift->app->cli_mode(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 utf8_safe()
    
    $str_utf8 = $app->utf8_safe($str);

Encode data in C<utf8> safely.

=cut

sub utf8_safe {
    my ($self, $str) = @_;
    if (utf8::is_utf8($str)) {
        utf8::encode($str);
    }
    $str;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 encode()
    
    $encoded = $app->encode($data);

Encode data using the current L</charset>.

=cut

sub encode {
    my ($self, $data) = @_;
    return Encode::encode($self->charset, $data);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 decode()
    
    $data = $app->decode($encoded);

Decode data using the current L</charset>.

=cut

sub decode {
    my ($self, $data) = @_;
    return Encode::decode($self->charset, $data);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 instance_isa()
    
    $app->instance_isa($object, $class);

Test for an object of a particular class in a strictly correct manner.

Returns the object itself or C<undef> if the value provided is not an object of that type.

=cut

sub instance_isa ($$) {
    #my ($self, $object, $class) = @_;
    (Scalar::Util::blessed($_[1]) and $_[1]->isa($_[2])) ? $_[1] : undef;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub content_type_text {
    my ($self, $content_type) = @_;
    return $content_type =~ /(\bx(?:ht)?ml\b|text|json|javascript)/;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub result {
    my ($self, @data) = @_;
    use Nile::Result;
    Nile::Result->new(@data);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_result {
    my ($self, $result) = @_;
    ref($result) eq "Nile::Result";
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 abort()
    
    $app->abort("error message");

    $app->abort("error title", "error message");

Stop and quit the application and display message to the user. See L<Nile::Abort> module.

=cut

sub abort {
    shift->app->abort(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

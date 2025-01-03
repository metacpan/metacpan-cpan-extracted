package SMS::Send::Driver::WebService;
use strict;
use warnings;
use base qw{SMS::Send::Driver};
use URI qw{};
use Path::Class qw{};
use Config::IniFiles qw{};
use HTTP::Tiny qw{};

our $VERSION = '0.08';
our $PACKAGE = __PACKAGE__;

=head1 NAME

SMS::Send::Driver::WebService - SMS::Send driver base class for web services

=head1 SYNOPSIS

  package SMS::Send::My::Driver;
  use base qw{SMS::Send::Driver::WebService};
  sub send_sms {
    my $self = shift;
    my $ua   = $self->ua;  #isa LWP::UserAgent
    my $uat  = $self->uat; #isa HTTP::Tiny
    my $cfg  = self->cfg;  #isa Config::IniFiles
    #call web service die on critical error
    #parse return with a package like XML::Simple or JSON::XS
    #return 1 for successful or 0 for unsuccessful
  }

=head1 DESCRIPTION

The SMS::Send::Driver::WebService package provides an L<SMS::Send> driver base class to support two common needs.  The first need is a base class that provides L<LWP::UserAgent> as a simple method. The second need is a way to configure various setting for multiple SMS providers without having to rebuild the SMS::Send driver concept.

=head1 USAGE

  use base qw{SMS::Send::Driver::WebService};

=head1 METHODS

=head2 new

SMS::Send API; Note: $service isa SMS::Send object in this syntax

  my $service = SMS::Send->new("My::Driver",
                                          _username => $username,
                                          _password => $password,
                                          );

Driver API; Note: $service isa SMS::Send::My::Driver object in this syntax

  my $service = SMS::Send::My::Driver->new(
                                           username => $username,
                                           password => $password,
                                          );

SMS::Send API with SMS-Send.ini file

  SMS-Send.ini
  [My::Driver1]
  username=user1
  password=pass1

  [My::Driver2]
  username=user2
  password=pass2

  my $service1 = SMS::Send->new("My::Driver1"); #username and password read from SMS-Send.ini
  my $service2 = SMS::Send->new("My::Driver2"); #username and password read from SMS-Send.ini

Driver API with SMS-Send.ini file

  my $service = SMS::Send::My::Driver1->new;

=cut

sub new {
  my $this=shift;
  my $class=ref($this) || $this;
  my $self={};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head2 initialize

Initializes data to compensate for the API deltas between SMS::Send and this package (i.e. removes underscore "_" from all parameters passed)

In this example

  SMS::Send->new("My::Driver", _password => "mypassword");

_password would be available to the driver as password=>"mypassword";

=cut

sub initialize {
  my $self=shift;
  my %hash=@_;
  #SMS::Send API deltas
  foreach my $key (keys %hash) {
    if ($key =~ m/^_(.*)/) {
      my $newkey=$1;
      $hash{$newkey}=delete($hash{$key});
    }
  }
  %$self=%hash;
  return $self;
}

=head2 send_sms

You will need to overload this method in your sub class.

Override in sub class (Example from Kannel SMSBox implementation)

  sub send_sms {
    my $self = shift;
    my %argv = @_;
    my $to   = $argv{"to"} or die("Error: to address required");
    my $text = defined($argv{"text"}) ? $argv{"text"} : ''; #use < 5.10 syntax to support older Perls
    my $url  = $self->url; #isa URI
    my @form = (
                 username   => $self->username,
                 password   => $self->password,
                 to         => $to,
                 text       => $text,
               );
    $url->query_form(\@form); #isa URI
    my $response = $self->ua->get($url); #isa HTTP::Response see LWP::UserAgent->get
    die(sprintf("HTTP Error: %s", $response->status_line)) unless $response->is_success;
    my $content  = $response->decoded_content;
    return $content =~ m/^0:/ ? 1 : 0; #0: Accepted for delivery
  }

=head1 PROPERTIES

=head2 username

Sets and returns the username string value

Override in sub class

  sub _username_default {"myusername"};

Override in configuration

  [My::Driver]
  username=myusername

=cut

sub username {
  my $self=shift;
  $self->{'username'}=shift if @_;
  $self->{'username'}=$self->cfg_property('username', $self->_username_default) unless defined $self->{'username'};
  die('Error: username property required') unless defined $self->{'username'};
  return $self->{'username'};
}

sub _username_default {undef};

=head2 password

Sets and returns the password string value (passed to the web service as PWD)

Override in sub class

  sub _password_default {"mypassword"};

Override in configuration

  [My::Driver]
  password=mypassword

=cut

sub password {
  my $self=shift;
  $self->{'password'}=shift if @_;
  $self->{'password'}=$self->cfg_property('password', $self->_password_default) unless defined $self->{'password'};
  die('Error: password property required') unless defined $self->{'password'};
  return $self->{'password'};
}

sub _password_default {undef};

=head2 host

Default: 127.0.0.1

Override in sub class

  sub _host_default {"myhost.domain.tld"};

Override in configuration

  [My::Driver]
  host=myhost.domain.tld

=cut

sub host {
  my $self=shift;
  $self->{'host'}=shift if @_;
  $self->{'host'}=$self->cfg_property('host', $self->_host_default) unless defined $self->{'host'};
  return $self->{'host'};
}

sub _host_default {'127.0.0.1'};

=head2 protocol

Default: http

Override in sub class

  sub _protocol_default {"https"};

Override in configuration

  [My::Driver]
  protocol=https

=cut

sub protocol {
  my $self=shift;
  $self->{'protocol'}=shift if @_;
  $self->{'protocol'}=$self->cfg_property('protocol', $self->_protocol_default) unless defined $self->{'protocol'};
  return $self->{'protocol'};
}

sub _protocol_default {'http'};

=head2 port

Default: 80

Override in sub class

  sub _port_default {443};

Override in configuration

  [My::Driver]
  port=443

=cut

sub port {
  my $self=shift;
  $self->{'port'}=shift if @_;
  $self->{'port'}=$self->cfg_property('port', $self->_port_default) unless defined $self->{'port'};
  return $self->{'port'};
}

sub _port_default {'80'};

=head2 script_name

Default: /cgi-bin/sendsms

Override in sub class

  sub _script_name_default {"/path/file"};

Override in configuration

  [My::Driver]
  script_name=/path/file

=cut

sub script_name {
  my $self=shift;
  $self->{'script_name'}=shift if @_;
  $self->{'script_name'}=$self->cfg_property('script_name', $self->_script_name_default) unless defined $self->{'script_name'};
  return $self->{'script_name'};
}

sub _script_name_default {'/cgi-bin/sendsms'};

=head2 url

Returns a L<URI> object based on above properties OR returns a string from sub class or configuration file.

Override in sub class (Can be a string or any object that stringifies to a URL)

  sub _url_default {"http://myservice.domain.tld/path/file"};

Override in configuration

  [My::Driver]
  url=http://myservice.domain.tld/path/file

Overriding the url method in the sub class or the configuration makes the protocol, host, port, and script_name methods inoperable.

=cut

sub url {
  my $self=shift;
  $self->{'url'}=shift if @_;
  $self->{'url'}=$self->cfg_property('url', $self->_url_default) unless defined $self->{'url'};
  unless (defined $self->{'url'}) {
    my $url=URI->new();
    $url->scheme($self->protocol);
    $url->host($self->host);
    $url->port($self->port);
    $url->path($self->script_name);
    $self->{'url'}=$url; #object assignment
  }
  #print $self->{'url'}, "\n";
  return $self->{'url'};
}

sub _url_default {undef};

=head1 OBJECT ACCESSORS

=head2 uat

Returns a lazy loaded L<HTTP::Tiny> object

=cut

sub uat {
  my $self       = shift;
  unless ($self->{'uat'}) {
    $self->{'uat'} = HTTP::Tiny->new(
                                     keep_alive => 0, #override bad default
                                     agent      => $self->_http_agent,
                                    );
  }
  return $self->{'uat'};
}

=head2 ua

Returns a lazy loaded L<LWP::UserAgent> object

=cut

sub ua {
  my $self = shift;
  unless ($self->{'ua'}) {
    local $@;
    eval 'use LWP::UserAgent'; #Lazy Load Package
    my $error     = $@;
    die($error) if $error;
    $self->{'ua'} = LWP::UserAgent->new(
                                        env_proxy => 1, #override bad default
                                        agent     => $self->_http_agent,
                                       );
  }
  return $self->{'ua'};
}

sub _http_agent {
  my $self               = shift;
  $self->{'_http_agent'} = shift if @_;
  $self->{'_http_agent'} = "Mozilla/5.0 (compatible; $PACKAGE/$VERSION; See rt.cpan.org 35173)"
    unless defined $self->{'_http_agent'};
  return $self->{'_http_agent'};
}

=head2 cfg

Returns a lazy loaded L<Config::IniFiles> object so that you can read settings from the INI file.

  my $cfg=$driver->cfg; #isa Config::IniFiles

=cut

sub cfg {
  my $self=shift;
  unless (exists $self->{'cfg'}) {
    my $file=$self->cfg_file;
    if ($file and -r $file) {
      $self->{'cfg'}=Config::IniFiles->new(-file=>"$file")
    } else {
      $self->{'cfg'}=undef;
    }
  }
  return $self->{'cfg'};
}


=head2 cfg_file

Sets or returns the profile INI filename

  my $file=$driver->cfg_file;
  my $file=$driver->cfg_file("./my.ini");

Set on construction

  my $driver=SMS::Send::My::Driver->new(cfg_file=>"./my.ini");

Default: SMS-Send.ini

=cut

sub cfg_file {
  my $self=shift;
  if (@_) {
    $self->{'cfg_file'}=shift;
    die(sprintf(qq{Error: Cannot read file "%s".}, $self->{'cfg_file'})) unless -r $self->{'cfg_file'};
  }
  unless (defined $self->{'cfg_file'}) {
    die(sprintf(qq{Error: path method returned a "%s"; expecting an array reference.}, ref($self->cfg_path)))
      unless ref($self->cfg_path) eq 'ARRAY';
    foreach my $path (@{$self->cfg_path}) {
      $self->{'cfg_file'}=Path::Class::file($path, $self->_cfg_file_default);
      last if -r $self->{'cfg_file'};
    }
  }
  #We may not have a vaild file here?  We'll let Config::IniFiles catch the error.
  return $self->{'cfg_file'};
}

sub _cfg_file_default {'SMS-Send.ini'};

=head2 cfg_path

Sets and returns a list of search paths for the INI file.

  my $path=$driver->cfg_path;            # []
  my $path=$driver->cfg_path(".", ".."); # []

Default: ["."]
Default: [".", 'C:\Windows'] on Windows-like systems that have Win32 installed
Default: [".", "/etc"] on other systems that have Sys::Path installed

override in sub class

  sub cfg_path {["/my/path"]};

=cut

sub cfg_path {
  my $self=shift;
  $self->{'path'}=[@_] if @_;
  unless (ref($self->{'path'}) eq 'ARRAY') {
    my @path=('.');
    if ($^O eq 'MSWin32') {
      eval('use Win32');
      push @path, eval('Win32::GetFolderPath(Win32::CSIDL_WINDOWS)') unless $@;
    } else {
      eval('use Sys::Path');
      push @path, eval('Sys::Path->sysconfdir') unless $@;
    }
    $self->{'path'}=\@path;
  }
  return $self->{'path'};
}

=head2 cfg_section

Returns driver name as specified by package namespace

Example
  package SMS::Send::My::Driver;

Configuration in SMS-Send.ini file

  [My::Driver]
  username=myuser
  password=mypass
  host=myserver

=cut

sub cfg_section {
  my $self=shift;
  $self->{'cfg_section'}=shift if @_;
  unless ($self->{'cfg_section'}) {
    my $section=ref($self);
    $section =~ s/\ASMS::Send:://;
    $self->{'cfg_section'}=$section;
  }
  return $self->{'cfg_section'};
}

=head2 cfg_property

  my $property=$self->cfg_property("username");
  my $property=$self->cfg_property("host", "mydefault");

=cut

sub cfg_property {
  my $self     = shift;
  my $property = shift or die('Error: property name required');
  my $default  = shift; #|| undef
  my $cfg      = $self->cfg;
  if ($cfg) { #if config object
    return $self->cfg->val($self->cfg_section, $property, $default);
  } else {
    return $default;
  }
}

=head2 warnings

Enable warnings to STDERR for issues such as failed resource and web calls

  $ws->warnings(1);

Default: 0

Override in sub class

  sub _warnings_default {1};

Override in configuration

  [My::Driver]
  warnings=1

=cut

sub warnings {
  my $self=shift;
  $self->{'warnings'}=shift if @_;
  $self->{'warnings'}=$self->cfg_property('warnings', $self->_warnings_default) unless defined $self->{'warnings'};
  return $self->{'warnings'};
}

sub _warnings_default {0};

=head2 debug

Enable debug level to STDOUT for logging information such as steps, urls, and parameters

  $ws->debug(5);

Default: 0

Override in sub class

  sub _debug_default {5};

Override in configuration

  [My::Driver]
  debug=5


=cut

sub debug {
  my $self=shift;
  $self->{'debug'}=shift if @_;
  $self->{'debug'}=$self->cfg_property('debug', $self->_debug_default) unless defined $self->{'debug'};
  return $self->{'debug'};
}

sub _debug_default {0};

=head1 ISSUES

Please open issue on GitHub

=head1 AUTHOR

  Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 Michael R. Davis

MIT License

=head1 SEE ALSO

L<SMS::Send>

=cut

1;

# NAME

SMS::Send::Driver::WebService - SMS::Send driver base class for web services

# SYNOPSIS

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

# DESCRIPTION

The SMS::Send::Driver::WebService package provides an [SMS::Send](https://metacpan.org/pod/SMS::Send) driver base class to support two common needs.  The first need is a base class that provides [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) as a simple method. The second need is a way to configure various setting for multiple SMS providers without having to rebuild the SMS::Send driver concept.

# USAGE

    use base qw{SMS::Send::Driver::WebService};

# METHODS

## new

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

## initialize

Initializes data to compensate for the API deltas between SMS::Send and this package (i.e. removes underscore "\_" from all parameters passed)

In this example

    SMS::Send->new("My::Driver", _password => "mypassword");

\_password would be available to the driver as password=>"mypassword";

## send\_sms

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

# PROPERTIES

## username

Sets and returns the username string value

Override in sub class

    sub _username_default {"myusername"};

Override in configuration

    [My::Driver]
    username=myusername

## password

Sets and returns the password string value (passed to the web service as PWD)

Override in sub class

    sub _password_default {"mypassword"};

Override in configuration

    [My::Driver]
    password=mypassword

## host

Default: 127.0.0.1

Override in sub class

    sub _host_default {"myhost.domain.tld"};

Override in configuration

    [My::Driver]
    host=myhost.domain.tld

## protocol

Default: http

Override in sub class

    sub _protocol_default {"https"};

Override in configuration

    [My::Driver]
    protocol=https

## port

Default: 80

Override in sub class

    sub _port_default {443};

Override in configuration

    [My::Driver]
    port=443

## script\_name

Default: /cgi-bin/sendsms

Override in sub class

    sub _script_name_default {"/path/file"};

Override in configuration

    [My::Driver]
    script_name=/path/file

## url

Returns a [URI](https://metacpan.org/pod/URI) object based on above properties OR returns a string from sub class or configuration file.

Override in sub class (Can be a string or any object that stringifies to a URL)

    sub _url_default {"http://myservice.domain.tld/path/file"};

Override in configuration

    [My::Driver]
    url=http://myservice.domain.tld/path/file

Overriding the url method in the sub class or the configuration makes the protocol, host, port, and script\_name methods inoperable.

# OBJECT ACCESSORS

## uat

Returns a lazy loaded [HTTP::Tiny](https://metacpan.org/pod/HTTP::Tiny) object

## ua

Returns a lazy loaded [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object

## cfg

Returns a lazy loaded [Config::IniFiles](https://metacpan.org/pod/Config::IniFiles) object so that you can read settings from the INI file.

    my $cfg=$driver->cfg; #isa Config::IniFiles

## cfg\_file

Sets or returns the profile INI filename

    my $file=$driver->cfg_file;
    my $file=$driver->cfg_file("./my.ini");

Set on construction

    my $driver=SMS::Send::My::Driver->new(cfg_file=>"./my.ini");

Default: SMS-Send.ini

## cfg\_path

Sets and returns a list of search paths for the INI file.

    my $path=$driver->cfg_path;            # []
    my $path=$driver->cfg_path(".", ".."); # []

Default: \["."\]
Default: \[".", 'C:\\Windows'\] on Windows-like systems that have Win32 installed
Default: \[".", "/etc"\] on other systems that have Sys::Path installed

override in sub class

    sub cfg_path {["/my/path"]};

## cfg\_section

Returns driver name as specified by package namespace

Example
  package SMS::Send::My::Driver;

Configuration in SMS-Send.ini file

    [My::Driver]
    username=myuser
    password=mypass
    host=myserver

## cfg\_property

    my $property=$self->cfg_property("username");
    my $property=$self->cfg_property("host", "mydefault");

## warnings

Enable warnings to STDERR for issues such as failed resource and web calls

    $ws->warnings(1);

Default: 0

Override in sub class

    sub _warnings_default {1};

Override in configuration

    [My::Driver]
    warnings=1

## debug

Enable debug level to STDOUT for logging information such as steps, urls, and parameters

    $ws->debug(5);

Default: 0

Override in sub class

    sub _debug_default {5};

Override in configuration

    [My::Driver]
    debug=5

# ISSUES

Please open issue on GitHub

# AUTHOR

    Michael R. Davis

# COPYRIGHT AND LICENSE

Copyright (c) 2025 Michael R. Davis

MIT License

# SEE ALSO

[SMS::Send](https://metacpan.org/pod/SMS::Send)

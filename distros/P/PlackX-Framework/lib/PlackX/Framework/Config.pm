use v5.36;
package PlackX::Framework::Config {
  use Carp qw(croak);

  sub import ($class, @options) {
    my $config = $class->load_config(@options);
    $class->export_config($config);
  }

  sub load_config ($class, @options) {
    my $env_prefix = $class->class_to_env_key_prefix;
    my $fn = shift @options || $ENV{$env_prefix};

    croak "$class - No config file specified, maybe try \$ENV{'$env_prefix'}"
      unless defined $fn and length $fn;

    croak "$class - Config file $fn does not exist"
      unless -e $fn;

    my $type = eval {
      no warnings;
      return 'pl' if lc(substr($fn, -3, 3)) eq '.pl';
      return 'pl' if $ENV{$env_prefix.'_CONFIG_TYPE'} =~ m/^PL|PERL$/i;
      return '';
    };

    return $class->load_pl_config($fn) if $type eq 'pl';
    return $class->load_other_config($fn);
  }

  sub export_config ($class, $config) {
    my ($namespace) = $class =~ m/^(.+)::Config/;
    my $sub = sub { $config };

    no strict 'refs';
    *{$namespace.'::config'}         = $sub;
    *{$namespace.'::Config::config'} = $sub;
    return;
  }

  sub class_to_env_key_prefix ($class) {
    $class =~ s/::/_/g;
    return uc($class);
  }

  sub load_pl_config ($class, $fn) {
    local @INC = ();
    my $result = do $fn;
    croak "$class - Error reading config file $fn:\n$!"
      unless $result;
    croak "$class - Config file $fn did not return a hashref"
      unless ref $result and ref $result eq 'HASH';
    return $result;
  }

  sub load_other_config ($class, $fn) {
    my $result = eval {
      require Config::Any;
      Config::Any->load_files({ use_ext => 1, files => [$fn] })->[0]->{$fn};
    };
    croak "$class - Error reading config file $fn:\n$@$!"
      unless $result;
    croak "$class - Config file $fn did not result in a hashref"
      unless ref $result and ref $result eq 'HASH';
    return $result;
  }

}

1;

=pod

This module is offered as a convenience to the user, and is not used to
configure PlackX::Framework directly.

It will load and parse the specific configuration file and make the resulting
data structure available in a config() method/functino of your application's
main class, and also a ::Config class.

IMPORT: This module does NOT export the config() function to the caller, but
rather to your application's namespace! See the examples below for
clarification!

Option one is to have PXF automatically generate your ::Config subclass.

Store your config filename in an environment variable, in accordance with the
convention described below:

  My::Web::App => $ENV{'MY_WEB_APP_CONFIG'}

or pass it in your use statement.

Example 1:

  package My::WebApp {
    use PlackX::Framework qw(:config);
    use My::WebApp::Config '/path/to/config_file';

    my $some_value = config->{some_key};

    # May also be written as:
    #   My::WebApp->config
    #   My::WebApp::config()
    #   My::WebApp::Config->config
    #   My::WebApp::Config::config()
  }

Alternatively, create an empty ::Config subclass. This technique must be used
if you want to load your configuration before loading the rest of your app.

Example 2:

  # You must create a subclass of PlackX::Framework::Config!
  # It MUST be named [NameOfApp]::Config!

  # My/WebApp/Config.pm:
  package My::WebApp::Config {
    use parent 'PlackX::Framework::Config';
  }

  # My/WebApp.pm
  package My::WebApp {
    use PlackX::Framework;
    use My::WebApp::Router;
    use Data::Dumper;
    route '/' => sub ($request, $response) {
      $response->print(Dumper config());
    }
  }

  # app.psgi
  use My::WebApp::Config '/path/to/config_file';
  use My::WebApp;

If the config file ends in .pl or if $ENV{MYAPP_CONFIG_TYPE} is set to
'PERL', or 'PL', this module will use perl to "do" the file and return
a perl data structure; otherwise Config::Any will be loaded to attempt
to parse the file based on its extension.

If you would like to write your own custom config-file parsing routine,
override load_config() in your ::Config subclass, returning a reference
to the perl data structure.

  package My::WebApp::Config {
    use parent 'PlackX::Framework::Config';
    sub load_config ($class, @options) {
      my $fname = shift @options || $ENV{..};
      require My::Parser::Module;
      my $config = My::Parser::Module->parse($fname);
      return $config;
    }
  }

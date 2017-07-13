package Number::MuPhone::Config;
use strictures 2;
use Exporter;
use Carp;

# load config, if exists
# options are:
# - ENV{MUPHONE_CONF_FILEPATH}
# - $ENV{HOME}/.muphone_conf.yaml

# your config MUST contain the elements 'default_country', 'countries' and 'dialer'

# default empty config 
$Number::MuPhone::Config::config = {
  # two letter country code
  # if a number is supplied withoput a country attr and doesn't begin with +CODE
  # try to parse the number as if it's in this country
  default_country => '',

  countries => {
    US => {

    },
  },
  dialer => {
    # what is the pause / wait for extension character for your dialer
    pause => ','
  },
  is_default => 1,
};

my $home_conf = $ENV{HOME}
                ? "$ENV{HOME}/.muphone_conf.yaml"
                : '';

my $file_path = $ENV{MUPHONE_CONF_FILEPATH} || $home_conf;

if ( -f $file_path ) {
  # only try and load YMAL::XS if config exists
  eval { use YAML::XS qw(LoadFile); };
  if ($@) {
    croak "YAML::XS >= v0.21 is not installed - cannot load config: $@";
  }
  else {
    $Number::MuPhone::Config::config = LoadFile($file_path);
  }
}

1;


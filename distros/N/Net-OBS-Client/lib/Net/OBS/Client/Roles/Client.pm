package Net::OBS::Client::Roles::Client;

use Moose::Role;

use LWP::UserAgent;
use XML::Structured;
use Config::Tiny;
use HTTP::Request;
use HTTP::Cookies;
use Carp qw/croak/;
use File::Path qw/make_path/;

use Net::OBS::SigAuth;

has use_oscrc => (
  is      =>    'rw',
  isa     =>    'Bool',
);

has apiurl => (
  is      =>    'rw',
  isa     =>    'Str',
  lazy    =>    1,
  default =>    sub {
    return ($_[0]->use_oscrc)
     ? $_[0]->oscrc->{general}->{apiurl}
     : 'https://api.opensuse.org/public';
  },
);

has user => (
  is      =>    'rw',
  isa     =>    'Str|Undef',
  lazy    =>    1,
  default =>    sub {
    my $self = shift;
    return $self->oscrc->{$self->apiurl}->{user} if ($self->use_oscrc);
    return q{};
  },
);

has pass => (
  is      =>    'rw',
  isa     =>    'Str|Undef',
  lazy    =>    1,
  default =>    sub {
    my $self = shift;
    return $self->oscrc->{$self->apiurl}->{pass} if ($self->use_oscrc);
    return q{};
  },
);

has user_agent => (
  is      =>    'rw',
  isa     =>    'Object',
  lazy    =>    1,
  default => sub {
    my $ua = LWP::UserAgent->new(
      cookie_jar => $_[0]->cookie_jar
    );
    if ($ENV{NET_OBS_CLIENT_DEBUG}) {
      eval {
        require LWP::ConsoleLogger::Easy;
        LWP::ConsoleLogger::Easy->import('debug_ua');
        debug_ua($ua, $ENV{NET_OBS_CLIENT_DEBUG});
      };
      warn "$@" if $@;
    }
    $ua->timeout(10);
    $ua->env_proxy;

    return $ua
  },
);

has oscrc => (
  is      =>    'rw',
  isa     =>    'Object',
  lazy    =>    1,
  default =>    sub {
    my $rc;
    if ( -f "$ENV{HOME}/.oscrc" ) {
      $rc = "$ENV{HOME}/.oscrc";
    } elsif (-f "$ENV{HOME}/.config/osc/oscrc") {
      $rc = "$ENV{HOME}/.config/osc/oscrc";
    } else {
      die "No oscrc found\n";
    }
    my $cf =  Config::Tiny->read($rc);
    die "Cannot open .oscrc\n" if ! $cf;
    return $cf;
  },
);

has repository => (
  is      =>    'rw',
  isa     =>    'Str',
);

has arch => (
  is      =>    'rw',
  isa     =>    'Str',
);

has api_path => (
  is      =>    'rw',
  isa     =>    'Str',
);

has cookie_jar => (
  is      =>    'rw',
  isa     =>    'Object',
  lazy    =>    1,
  default =>    sub {
    HTTP::Cookies->new(
      file => $_[0]->cookie_jar_file,
      autosave => 1,
    )
  },
);

has cookie_jar_file => (
  is      =>    'rw',
  isa     =>    'Str',
  lazy    =>    1,
  default =>    sub {
    if ($_[0]->use_oscrc) {
      for my $i ("$::ENV{HOME}/.local/state/osc/cookiejar", "$::ENV{HOME}/.osc_cookiejar") {
        return $i if (-f $i);
      }
    }
    my $state_dir = "$::ENV{HOME}/.local/state/Net_OBS_Client";
    -d $state_dir || make_path($state_dir);
    return "$state_dir/cookie_jar";
  },
);

sub debug {
  my @lines = @_;
  return if (! $::ENV{NET_OBS_CLIENT_DEBUG} );
  for (@lines) {print "$_\n"};
  return;
}

sub request {
  my $self      = shift;
  my $method    = shift;
  my $api_path  = shift;
  $self->api_path($api_path) if $api_path;

  my $ua = $self->user_agent();
  my $url = $self->apiurl . $self->api_path;

  debug(" $method: $url");

  my $req = HTTP::Request->new($method => $url);
  $req->uri->authority($self->user.'@'.$req->uri->authority) if ($self->user && !$self->pass && $req->uri->authority !~ /\@/);

  $req->authorization_basic($self->user, $self->pass) if ($self->user && $self->pass);
  my $response = $ua->request($req);

  if (!$response->is_success) {
    die $response->status_line . " while $method Request on ".$req->uri->canonical."\n";
  }

  return $response->decoded_content;  # or whatever
}

1; # End of Net::OBS::Client

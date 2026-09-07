package Gate;

use strict;
use warnings;
use Punk;

# Compile time, so the `challenge` keyword and the bare `challenge_guard`
# exist by the time the statements below are parsed. `plugin 'Challenge'`
# runs at RUNTIME of this package body, long after `challenge for => ...`
# has been compiled - a keyword installed only there is one perl has already
# refused to parse.
use Punk::Plugin::Challenge;

our $VERSION = '0.01';

# If this ran behind nginx, an ELB or a CDN, the next line would be
#
#     proxy;
#
# and without it every visitor on the internet would be one subject: one
# solve would clear them all. See "BEHIND A REVERSE PROXY" in the plugin's
# documentation. The demo is served directly, so it is left out.

config 'config/punk.yml';

plugin 'Challenge' => {
    secret => secret('challenge.key'),   # never minted here; see config/punk.yml
    bits   => 16,                        # the default: about a moment on a laptop
    ttl    => 3600,                      # a clearance holds for an hour
};

# Everyone proves themselves before the login form: the route an attacker
# retries. A browser gets the interstitial once, solves it in a Worker, and
# arrives at the form with a clearance cookie that holds for `ttl`.
challenge for => '/login', always => 1;

# The API: the first thirty requests a minute per /24 are free; past that, a
# puzzle instead of a 429. A human who happened to share the NAT with a
# scraper proves it in a moment; the scraper pays for every clearance.
#
# Counted in Hyperman's shared arena. Under any other server there is no
# arena and this rule is inert - the application says so once, at the first
# request under it. `plackup -s Hyperman app.psgi` is the server this wants.
challenge for => '/api', after => { limit => 30, window => 60 }, tag => 'api';

get  '/'        => 'Web::Root#index',  { name => 'home' };
get  '/login'   => 'Web::Root#form',   { name => 'login' };
post '/login'   => 'Web::Root#login';
get  '/welcome' => 'Web::Root#welcome', { name => 'welcome' };
post '/logout'  => 'Web::Root#logout';
get  '/api/time' => 'Web::Root#time',  { name => 'time' };

1;

__END__

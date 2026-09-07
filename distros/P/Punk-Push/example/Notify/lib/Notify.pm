package Notify;

use strict;
use warnings;
use Punk;

# Compile time, so the plugin's keyword-free surface is loaded before the
# statements below are parsed.
use Punk::Plugin::Push;

our $VERSION = '0.01';

config 'config/punk.yml';

# Push subscriptions belong to a user, so /push/subscribe is guarded and this
# application needs somebody to be signed in. `auth` is the whole battery:
# $c->login, $c->auth_id, password hashing. It needs `session`, declared in
# config/punk.yml.
auth model => 'User';

# The keys are configuration and are never generated: a pair minted at boot
# would differ per worker and per restart, and every subscription made against
# the old one would be undeliverable in silence. `punk push keys` prints a
# pair; bin/seed.pl puts one in var/ for the demo.
plugin 'Push' => {
    subject     => $ENV{PUSH_SUBJECT}  || 'mailto:demo@example.com',
    public_key  => $ENV{VAPID_PUBLIC}  || '',
    private_key => $ENV{VAPID_PRIVATE} || '',
};

get  '/'       => 'Web::Root#index',  { name => 'home' };
get  '/login'  => 'Web::Root#login_form', { name => 'login' };
post '/login'  => 'Web::Root#login';
post '/logout' => 'Web::Root#logout';

# The one route that actually sends. In a real application this would be
# something that happened - a report finished, an order shipped - rather than
# a button.
post '/notify' => 'Web::Root#notify';

1;

__END__
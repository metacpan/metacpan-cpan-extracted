#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::RealBin/../3rd/lib/perl5";
use lib "$FindBin::RealBin/../lib";

use Mojolicious::Lite;

my $SERVER = $ENV{AD_SERVER} // die "AD_SERVER env variable not set";

app->secrets(['My secret passphrase here']);

plugin 'SPNEGO', ad_server => $SERVER;

get '/' => sub {
    my $c = shift;
    if (not $c->session('user')){
        $c->ntlm_auth(
            auth_success_cb => sub {
                my $c = shift;
                my $user = shift;
                my $ldap = shift; # bound Net::LDAP::SPNEGO connection
                $c->session('user',$user->{samaccountname});
                $c->session('name',$user->{displayname});
                my $groups = $ldap->get_ad_groups($user->{samaccountname});
                $c->session('groups',[ sort keys %$groups]);
                return 1;
            }
        ) or return;
    }
} => 'index';

app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
<title>NTLM Auth Test</title>
</head>
<body>
<h1>Hello <%= session 'name' %></h1>
<div>Your account '<%= session 'user' %>' belongs to the following groups:</div>
<ul>
% for my $group (@{session 'groups' }) {
    <li>'<%= $group %>'</li>
% }
</ul>
</body>
</html>

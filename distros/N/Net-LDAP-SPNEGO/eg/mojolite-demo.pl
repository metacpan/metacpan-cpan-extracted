#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::RealBin/../3rd/lib/perl5";
use lib "$FindBin::RealBin/../lib";

use Net::LDAP::SPNEGO;
use Mojolicious::Lite;

my $SERVER = $ENV{AD_SERVER} // die "AD_SERVER env variable not set";

my %cCache;

app->secrets(['My secret passphrase here']);

hook before_dispatch => sub {
    my $c = shift;

    # once the user property is set, we are happy
    # and don't try to re-authenticate
    return if $c->session('user');

    my $cId = $c->tx->connection;
    my $cCache = $cCache{$cId} //= { status => 'init' };
    my $authorization = $c->req->headers->header('Authorization') // '';
    my ($AuthBase64) = ($authorization =~ /^NTLM\s(.+)$/);
    for ($AuthBase64 and $cCache->{status} =~ /^expect(Type\d)/){
        my $ldap = $cCache->{ldapObj} //= Net::LDAP::SPNEGO->new($SERVER,debug=>0);
        /^Type1/ && do {
            my $mesg = $ldap->bind_type1($AuthBase64);
            if ($mesg->{ntlm_type2_base64}){
                $c->res->headers->header( 'WWW-Authenticate' => 'NTLM '.$mesg->{ntlm_type2_base64});
                $c->render( text => 'Waiting for Type3 NTLM Token', status => 401);
                $cCache->{status} = 'expectType3';
                return;
            }
            # lets try with a new connection
            $ldap->unbind;
            delete $cCache->{ldapObj};
        };
        /^Type3/ && do {
            my $mesg = $ldap->bind_type3($AuthBase64);
            if (my $user = $mesg->{ldap_user_entry}){
                $c->session('user',$user->{samaccountname});
                $c->session('name',$user->{displayname});
                my $groups = $ldap->get_ad_groups($user->{samaccountname});
                $c->session('groups',[ sort keys %$groups]);
            }
            $ldap->unbind;
            delete $cCache->{ldapObj};
        };
    }
    $c->res->headers->header( 'WWW-Authenticate' => 'NTLM' );
    $c->render( text => 'Waiting for Type 1 NTLM Token', status => 401 );
    $cCache->{status} = 'expectType1';
};

get '/' => 'index';

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

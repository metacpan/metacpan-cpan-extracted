#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/../3rd/lib/perl5";
use lib "$FindBin::RealBin/../lib";
use Mojolicious::Lite -signatures;
use Mojo::Util qw(dumper);
use Net::LDAP;

plugin 'GSSAPI';

my $ad_server = 'adserver.myad.domain';
my $ad_user = 'ldapsearch@MYAD.DOMAIN';
my $ad_password = 'myadpassword';

get '/' => sub ($c) {
    my $user = $c->gssapi_auth or return;
    $c->log->error("user $user authenticated");
    my $ldap = Net::LDAP->new( $ad_server,
        # debug => 1,
        onerror=> sub ($msg) { 
            $c->log->error("LDAP ERROR: " . $msg->error);
            #return $msg;
        },
        timeout => 5,
    );
    $ldap->start_tls(verify=>'none');
    $ldap->bind($ad_user, 
        password => $ad_password);
    my $base = get_base_dn($ldap);
    $c->log->debug("BaseDN $base");
    my $msg = $ldap->search(
        base => $base,
        filter => '(userprincipalname='.$user.')',
    );
    if ($msg->count == 0) {
        return 
            $c->render(text=>"<h1>$user</h1><div>Not found in $base LDAP</div>", state=>404);
    }
    $c->render(text=>"<h1>$user</h1><pre>".$msg->entry(0)->ldif."</pre>");
};

app->start;

sub get_base_dn ($ldap) {
    if (not $ldap->{baseDN}){
        my $rootDSE = $ldap->search(
            base => '',
            filter => '(objectclass=*)',
            scope => 'base',
            attrs => ['defaultNamingContext'],
        )->entry(0);
        $ldap->{baseDN} = $rootDSE->get_value('defaultnamingcontext');
    }
    return $ldap->{baseDN};
}

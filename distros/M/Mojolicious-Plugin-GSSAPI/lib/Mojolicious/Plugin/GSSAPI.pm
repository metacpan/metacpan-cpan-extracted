package Mojolicious::Plugin::GSSAPI;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojo::Util qw(b64_decode);
use GSSAPI;
our $VERSION = '0.1.2';

my $gss_exit = sub ($c,$errmsg,$status) {
    my @major_errors = $status->generic_message();
    my @minor_errors = $status->specific_message();

    $c->log->error($errmsg);
    for my $s (@major_errors) {
        $c->log->error("  MAJOR::$s");
    }
    for my $s (@minor_errors) {
        $c->log->error("  MINOR::$s");
    }

    $c->render(status=>403,text=>'Negotiation failed! Check server log '.gmtime(time).(' ' x 512));
    return;
};

my $get_token = sub ($c,$cfg) {
    my $auth = $cfg->{web_proxy_mode} 
        ? $c->req->headers->proxy_authorization
        : $c->req->headers->authorization;
    if ($auth and $auth =~ /^Negotiate\s+(\S.*)$/) {
        my $token = b64_decode($1);
        if ($token =~ /^NTLMSSP/) {
            my $host = $c->req->headers->host;
            $c->log->error('The client tried to authenticate using NTLM. This is not supported. Probably the client does not consider the host "'.$host.'" to be an auth server. Under windows this means to add the host to "Internet Properties -> Security -> Local intranet -> Sites -> Advanced"');
            $c->render(status=>403,text=>'ntlm tokens are not supported, enable kerberos auththentication for host "'.$host.'"'.(' ' x 1024));
            return;
        }
        $c->log->debug("got a kerberos token from the client");
        return $token;
    }
    $c->log->debug("ask client to send a negotiation token");
    if ($cfg->{web_proxy_mode}){
        $c->res->headers->proxy_authenticate("Negotiate");
    }
    else {
        $c->res->headers->www_authenticate("Negotiate");
    }
    $c->render(
        status=>$cfg->{web_proxy_mode} ? 407 : 401,
        text=>'If you see this message it could mean that your borwser '.
            'is not configured to support the "Negotiate" autentication '.
            'mechanism" (aka Kerberos authentication)!');
    return;
};

my $get_user = sub ($c,$gss_input_token) {
    my $server_context;
    my $status = GSSAPI::Context::accept(
        $server_context,
        GSS_C_NO_CREDENTIAL, # we have no credential
        $gss_input_token,
        GSS_C_NO_CHANNEL_BINDINGS, # we have no channel bindings object 
        my $gss_client_name,
        undef,
        my $gss_output_token,
        my $out_flags,
        my $out_time,
        my $gss_delegated_cred
    );
    $status or 
        return $gss_exit->($c,"unable to accept security context", $status);
    my $user;
    $status = $gss_client_name->display($user);
    $status or 
        return $gss_exit->($c,"unable to extract client name", $status);
    return $user;
};

sub register ($self,$app,$cfg={}) {
    $app->helper(
        gssapi_auth => sub ($c) {
            my $token = $get_token->($c,$cfg) or return;
            return $get_user->($c,$token);
        }
    );
}
1;

__END__

=head1 NAME

Mojolicious::Plugin::GSSAPI - Provide Kerberos authentication.

=head1 SYNOPSIS

 use Mojolicious::Lite;

 plugin 'GSSAPI';

 get '/' => sub ($c) {
    my $user = $c->gssapi_auth or return;
    $c->render(text=>'hello '.$user);
 };
 app->start;

=head1 DESCRIPTION

The `Mojolicious::Plugin::GSSAPI` plugin lets you use kerberos authentication
in your mojo app. The plugin uses
the L<GSSAPI> module for the heavy lifting.

If you want to use kerberos to SSO in a webproxy, use the F<web_proxy_mode> option:

 plugin 'GSSAPI',web_proxy_mode => 1;

The included example script F<gssapi-demo.pl> shows how to use the plugin
to implement Kerberos SSO authentication for a L<Mojolicious::Lite> web application.

If your machine is not yet part of the AD Domain, get it added to the ad server especially the dns entry including reveres lookup is important.

Then, make sure the F</etc/resolv.conf> or F</etc/systemd/resolved.conf> points to your ad server.

For some reason it seems best to have the ad server also added to your F</etc/hosts> file.

Add the ad `realm` to the F</etc/krb5.conf> file

 [libdefaults]
    default_realm = MY-AD.DOMAIN

Now use the `adcli` tool to join the AD domain and add a `http` service entry.


 adcli join \
    --login-type user \
    --login-user Administrator \
    --domain-controller adserver.my-ad.domain \
    --service-name http


If you do not have the Administrator password for your AD server, you may also get a 'one-time-password' from your friendly ad admin person to join your machine to the AD domain.

And now about actually testing the plugin: 

 $ perl Makefile.PL
 $ make 3rd
 $ sudo ./eg/gssapi-demo.pl deamon


The sudo in the example above is necessary for the app to be able to read information from the F</etc/krb5.keytab>. You could also provide the demo with a copy of the file and use F<export KRB5CCNAME=/opt/demo/my.keytab> to tell the demo where to find the keytab file.

For your browser todo kerberos sso, you will have to let it know that your test machine is part of the 'realm'. On windows this is done by adding the name of your linux box to "Internet Properties -> Security -> Local intranet -> Sites -> Advanced"

=head1 COPYRIGHT

Copyright OETIKER+PARTNER AG 2021. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2021-03-22 to 0.1.0 initial version

=cut
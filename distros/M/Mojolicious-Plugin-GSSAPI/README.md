# NAME

Mojolicious::Plugin::GSSAPI - Provide Kerberos authentication.

# SYNOPSIS

```perl
use Mojolicious::Lite;

plugin 'GSSAPI';

get '/' => sub ($c) {
   my $user = $c->gssapi_auth or return;
   $c->render(text=>'hello '.$user);
};
app->start;
```

# DESCRIPTION

The \`Mojolicious::Plugin::GSSAPI\` plugin lets you use kerberos authentication
in your mojo app. The plugin uses
the [GSSAPI](https://metacpan.org/pod/GSSAPI) module for the heavy lifting.

If you want to use kerberos to SSO in a webproxy, use the `web_proxy_mode` option:

```perl
plugin 'GSSAPI',web_proxy_mode => 1;
```

The included example script `gssapi-demo.pl` shows how to use the plugin
to implement Kerberos SSO authentication for a [Mojolicious::Lite](https://metacpan.org/pod/Mojolicious%3A%3ALite) web application.

If your machine is not yet part of the AD Domain, get it added to the ad server especially the dns entry including reveres lookup is important.

Then, make sure the `/etc/resolv.conf` or `/etc/systemd/resolved.conf` points to your ad server.

For some reason it seems best to have the ad server also added to your `/etc/hosts` file.

Add the ad \`realm\` to the `/etc/krb5.conf` file

```
[libdefaults]
   default_realm = MY-AD.DOMAIN
```

Now use the \`adcli\` tool to join the AD domain and add a \`http\` service entry.

```perl
adcli join \
   --login-type user \
   --login-user Administrator \
   --domain-controller adserver.my-ad.domain \
   --service-name http
```

If you do not have the Administrator password for your AD server, you may also get a 'one-time-password' from your friendly ad admin person to join your machine to the AD domain.

And now about actually testing the plugin: 

```
$ perl Makefile.PL
$ make 3rd
$ sudo ./eg/gssapi-demo.pl deamon
```

The sudo in the example above is necessary for the app to be able to read information from the `/etc/krb5.keytab`. You could also provide the demo with a copy of the file and use `export KRB5CCNAME=/opt/demo/my.keytab` to tell the demo where to find the keytab file.

For your browser todo kerberos sso, you will have to let it know that your test machine is part of the 'realm'. On windows this is done by adding the name of your linux box to "Internet Properties -> Security -> Local intranet -> Sites -> Advanced"

# COPYRIGHT

Copyright OETIKER+PARTNER AG 2021. All rights reserved.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tobias Oetiker <tobi@oetiker.ch>

# HISTORY

```
2021-03-22 to 0.1.0 initial version
```

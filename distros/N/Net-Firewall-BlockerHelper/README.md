# Net-Firewall-BlockerHelper

Helps manage (un)blocking IPs via various firewalls.

Currently included backends are for...

- ipfw
- pf

The following generic backends are available.

- shell

And the following example/testing backends are available.

- dummy

On the todo list...

- iptables

```perl
    use Net::Firewall::BlockerHelper;

    # create a instance named ssh with a ipfw backend for port 22 tcp
    my $fw_helper;
    eval {
        $fw_helper = Net::Firewall::BlockerHelper->new(
                backend => 'ipfw',
                ports => ['22'],
                protocols => ['tcp'],
                name => 'ssh',
            );
    };
    if ($@) {
        print 'Error: '
            . $Error::Helper::error
            . "\nError String: "
            . $Error::Helper::errorString
            . "\nError Flag: "
            . $Error::Helper::errorFlag . "\n";
    }

    # start the backend
    $fw_helper->init_backend;

    # ban some IPs
    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->ban(ban => '5.6.7.8');

    # unban a IP
    $fw_helper->unban(ban => '1.2.3.4');

    # get a list of banned IPs
    my @banned = $fw_helper->list;
    foreach my $ip (@banned) {
        print 'Banned IP: '.$ip."\n";
    }

    # teardown the backend, re-init, and re-ban everything
    $fw_helper->re_init;

    # teardown the backend
    $fw_helper->teardown;
```

# Install

Rquirements...

- Regexp::IPv4
- Regexp::IPv6
- Error::Helper

To install...

```shell
perl Makefile.PL
make
make test
make install
```

Or via cpanm...

```
cpanm Net::Firewall::BlockerHelper
```

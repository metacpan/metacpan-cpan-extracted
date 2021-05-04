# NAME

Net::Async::DigitalOcean - Async client for DigitalOcean REST APIv2

# SYNOPSIS

    use IO::Async::Loop;
    my $loop = IO::Async::Loop->new;      # the god-like event loop

    use Net::Async::DigitalOcean;
    my $do = Net::Async::DigitalOcean->new( loop => $loop );
    $do->start_actionables;               # activate polling incomplete actions

    # create a domain, wait for it
    $do->create_domain( {name => "example.com"} )
       ->get;   # block here

    # create a droplet, wait for it
    my $dr = $do->create_droplet({
        "name"       => "www.example.com",
        "region"     => "nyc3",
        "size"       => "s-1vcpu-1gb",
        "image"      => "openfaas-18-04",
        "ssh_keys"   => [],
        "backups"    => 'true',
        "ipv6"       => 'true',
        "monitoring" => 'true',
                                  })
       ->get; $dr = $dr->{droplet}; # skip type

    # reboot
    $do->reboot(id => $dr->{id})->get;
    # reboot all droplets tagged with 'prod:web'
    $do->reboot(tag => 'prod:web')->get;

    

# OVERVIEW

## Platform

[DigitalOcean](https://www.digitalocean.com/) is a cloud provider which offers you to spin up
servers (droplets) with a specified OS, predefined sizes in predefined regions. You can also procure
storage volumes, attach those to the droplets, make snapshots of the volumes or the whole
droplet. There are also interfaces to create and manage domains and domain record, ssh keys, various
kinds of images or tags to tag the above things. On top of that you can build systems with load
balancers, firewalls, distributable objects (Spaces, similar to Amazon's S3). Or, you can go along
with the Docker pathway and/or create and run kubernetes structures.

See the [DigitalOcean Platform](https://docs.digitalocean.com/products/platform/) for more.

DigitalOcean offers a web console to administrate all this, but also a
[RESTy interface](https://docs.digitalocean.com/reference/api/).

## REST API, asynchronous

This client library can be used by applications to talk to the various DigitalOcean REST endpoints. But in contrast
to similar libraries, such as [DigitalOcean](https://metacpan.org/pod/DigitalOcean) or [WebService::DigitalOcean](https://metacpan.org/pod/WebService::DigitalOcean), this library operates in _asynchronous_ mode:

Firstly, all HTTP requests are launched asynchronously, without blocking until their respective responses come in.

But more importantly, [long-lasting actions](https://www.digitalocean.com/community/tutorials/how-to-use-and-understand-action-objects-and-the-digitalocean-api), 
such as creating a droplet, snapshoting volumes or rebooting a set of droplets are handled by the
library itself; the application does not need to keep track of these open actions, or keep polling
for their completion.

The way this works is that the application first has to create the event loop and - with it -
create a handle to the DigitalOcean API server:

    use IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    use Net::Async::DigitalOcean;
    my $do = Net::Async::DigitalOcean->new( loop => $loop );
    $do->start_actionables;

You also should start a timer _actionables_. In regular intervals it will check with the
server, whether open actions have been completed or not.

With that, every method (except a few) return a [Future](https://metacpan.org/pod/Future) object, such when creating
a droplet:

    my $f = $do->create_droplet({
        "name"       => "example.com",
        "region"     => "nyc3",
        "size"       => "s-1vcpu-1gb",
        "image"      => "openfaas-18-04",
        ....
                                  });

The application can either choose to wait synchronously:

    my $d = $f->get; # wait, and receive the response as HASH

or, alternatively, can specify what should happen once the result comes in:

    $f->on_done( sub { my $d = shift;
                       warn "droplet $d->{droplet}->{name} ready (well, almost)"; } );

Futures can also be combined in various ways; one extremely useful is to wait for several actions to
complete in one go:

    Future->wait_all(
                      map { $do->create_volume( ... ) }
                      qw(one two another) )->get;

## Success and Failure

When futures succeed, the application will usually get a result in form of a Perl HASH (see below). If
a future fails and the failure is not handled specifically (by adding a `->on_fail` handler),
then an exception will be raised. The library tries to figure out what the real message from the
server was.

## Data Structures

Another difference to other libraries in this arena is that it does not try to artifically
_objectify_ things into classes, such as for the _droplet_, _image_ and other concepts.

Instead, the library truthfully transports Perl HASHes and LISTs via JSON to the server and back;
even to the point to **exactly** reflect the [API specification](https://developers.digitalocean.com/documentation/v2/) .
That way you can always look up what to precisely expect as result.

But as the server chooses to _type_ results, the application will have to cope with that

    my $d = $do->create_droplet({
        "name"       => "example.com",
        ....
                                })->get;
    $d = $d->{droplet}; # now I have the droplet itself

# INSTALLATION OPTIONS

- installation via cpanm (or similar)

        sudo cpanm Net::Async::DigitalOcean

- installation via downloaded .tgz file

        ls -al Net-Async-DigitalOcean-*.tar.gz
        tar zxvf Net*
        pushd Net-Async-DigitalOcean-*
        perl Build.PL
        sudo ./Build installdeps
        sudo ./Build install

- access to proprietary Debian repository http://packages.devc.at/

        sudo wget -O - http://packages.devc.at/stretch/templescript.list > /etc/apt/sources.list.d/templescript.list
        sudo wget -O - http://packages.devc.at/jessie/archive.key|apt-key add -
        sudo apt update
        sudo apt install libnet-async-digitalocean-perl

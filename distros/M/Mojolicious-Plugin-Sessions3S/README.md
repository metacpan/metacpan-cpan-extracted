# NAME

Mojolicious::Plugin::Sessions3S - Manage mojolicious sessions Storage, State and SID generation

# DESCRIPTION

This plugins puts you in control of how your sessions are stored, how the state persists
in the client browser and how session Ids are generated.

It provides a drop in replacement for the standard Mojolicious::Sessions mechanism and
will NOT require any change of your application code (except the setup of course).

# SYNOPSIS

    $app->plugin( 'Sessions3S' => {
       state => ..,
       storage => ...,
       sidgen => ...
    });

See [Mojolicious::Sessions::ThreeS](https://metacpan.org/pod/Mojolicious::Sessions::ThreeS) for the parameters description.

If no arguments are provided, this fallsback to the stock [Mojolicious::Sessions](https://metacpan.org/pod/Mojolicious::Sessions) behaviour.

You can then use [Mojolicious::Controller](https://metacpan.org/pod/Mojolicious::Controller) session related methods (`session`, `flash`) as usual.

With the addition of the following methods (helpers):

## session\_id

Always returns the ID of the current session:

    my $session_id = $c->session_id();

## register

Implementation for [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) base class

# COPYRIGHT

This is copyright Jerome Eteve (JETEVE) 2016

With the support of Broadbean UK Ltd. [http://www.broadbean.co.uk](http://www.broadbean.co.uk)

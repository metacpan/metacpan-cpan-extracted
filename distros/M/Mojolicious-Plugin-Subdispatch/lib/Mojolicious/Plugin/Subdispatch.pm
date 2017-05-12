package Mojolicious::Plugin::Subdispatch;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::UserAgent::Transactor;

our $VERSION = '0.04';

has app         => sub { die 'not registered!' };
has transactor  => sub { Mojo::UserAgent::Transactor->new };
has 'base_url';

sub _subdispatch {
    my ($self, $method, @args) = @_;

    # extract post data
    my $post_data = (uc $method eq 'POST' and ref $args[-1] eq 'HASH') ?
        pop @args : undef;

    # build request url
    my $url = $self->app->url_for(@args);
    $url->base($self->base_url) if defined $self->base_url;

    # build transaction
    my $tx = $post_data ?
        $self->transactor->tx($method => $url => form => $post_data)
        : $self->transactor->tx($method => $url);

    # dispatch
    $self->app->handler($tx);

    return $tx;
}

# Mojo::UserAgent like interface
# we don't really need post_form, but Mojo::UA uses it.
{
    no strict 'refs';
    for my $name (qw(DELETE GET HEAD POST POST_FORM PUT)) {
        *{__PACKAGE__ . '::' . lc($name)} = sub {
            my $self = shift;
            my $method = $name eq 'POST_FORM' ? 'POST' : $name;
            return $self->_subdispatch($method => @_)->res;
        };
    }
}

sub register {
    my ($self, $app, $conf) = @_;
    $self->app($app);

    # does your base are belong to us?
    if (defined $conf->{base_url}) {
        my $base_url = $conf->{base_url};
        $base_url = Mojo::URL->new($base_url) unless ref $base_url;
        $self->base_url($base_url);
    }

    # add subdispatch helper
    $app->helper(subdispatch => sub {
        my $s = shift;

        # Mojo::UserAgent like interface usage
        return $self unless @_;

        # direct subdispatch call
        return $self->_subdispatch(@_);
    });
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Subdispatch - create requests to your Mojolicious actions

=head1 SYNOPSIS

    plugin 'Subdispatch';

    [web app stuff...]

    my $html = app->subdispatch->get('route_name', foo => 'bar')->body;

=head1 DESCRIPTION

This Mojolicious plugin creates a `subdispatch` helper, which helps you
creating a request for your actions, and returns the response object with
your fully rendered HTML content.

The interface has some similarities to Mojo::UserAgent:
just use your request method (DELETE, GET, HEAD, POST, PUT) as the method name
and pass the same arguments as you would do for `url_for`:

To build a post request with data, append the data hash at the end:

    my $res = app->subdispatch->post('route', foo => 'bar', {with => 'data'});

If you want to access the transaction object around the response, use the
subdispatch helper with arguments like this:

    my $tx = app->subdispatch(GET  => 'route', foo => 'bar');
    my $tx = app->subdispatch(POST => 'route', foo => 'bar', {with => 'data'});

For some reasons, it seamed important to me to be able to set the base url of
the resulting requests, so this is possible via

    plugin 'Subdispatch', base_url => 'http://example.org';

This is an early version and may change without warning. I'll use it to create
static HTML pages from a Mojolicious blog, but if you find another good way
to use it, please let me know!

=head1 REPOSITORY AND ISSUE TRACKING

This plugin lives in github:
L<http://github.com/memowe/mojolicious-plugin-subdispatch>.
You're welcome to use github's issue tracker to report bugs or discuss the code:
L<http://github.com/memowe/mojolicious-plugin-subdispatch/issues>

=head1 AUTHOR AND LICENSE

Copyright Mirko Westermeier E<lt>mail@memowe.deE<gt>

Licensed under the same terms as Perl itself.

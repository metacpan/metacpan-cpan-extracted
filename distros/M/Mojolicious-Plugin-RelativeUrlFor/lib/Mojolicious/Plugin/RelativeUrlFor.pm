package Mojolicious::Plugin::RelativeUrlFor;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.052';

# function version of the deleted Mojo::URL::to_rel method
# from Mojolicious repository revision 551a31
sub url_to_rel {
    my $self = shift;

    my $rel = $self->clone;
    return $rel unless $rel->is_abs;

    # Scheme and host
    my $base = shift || $rel->base;
    $rel->base($base)->scheme(undef);
    $rel->userinfo(undef)->host(undef)->port(undef) if $base->host;

    # Path
    my @parts       = @{$rel->path->parts};
    my $base_path   = $base->path;
    my @base_parts  = @{$base_path->parts};
    pop @base_parts unless $base_path->trailing_slash;
    while (@parts && @base_parts && $parts[0] eq $base_parts[0]) {
        shift @$_ for \@parts, \@base_parts;
    }
    my $path = $rel->path(Mojo::Path->new)->path;
    $path->leading_slash(1) if $rel->host;
    $path->parts([('..') x @base_parts, @parts]);
    $path->trailing_slash(1) if $self->path->trailing_slash;

    return $rel;
}

sub register {
    my ($self, $app, $conf) = @_;

    # url_for helper backup
    my $url_for = *Mojolicious::Controller::url_for{CODE};

    # helper sub ref
    my $rel_url_for = sub {
        my $c = shift;

        # create urls
        my $url     = $url_for->($c, @_)->to_abs;
        my $req_url = $c->req->url->to_abs;

        # return relative version if request url exists
        if ($req_url->to_string) {

            # repair if empty
            my $rel_url = url_to_rel($url, $req_url);
            return Mojo::URL->new('./') unless $rel_url->to_string;
            return $rel_url;
        }

        # change nothing without request url
        return $url;
    };

    # register rel(ative)_url_for helpers
    $app->helper(relative_url_for   => $rel_url_for);
    $app->helper(rel_url_for        => $rel_url_for);

    # replace url_for helper
    if ($conf->{replace_url_for}) {
        no strict 'refs';
        no warnings 'redefine';
        *Mojolicious::Controller::url_for = $rel_url_for;
    }
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::RelativeUrlFor - relative links in Mojolicious, really.

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('RelativeUrlFor');

    # Mojolicious::Lite
    plugin 'RelativeUrlFor';

=head1 DESCRIPTION

This Mojolicious plugin adds a new helper to your web app: C<relative_url_for>,
together with its short alias C<rel_url_for>. Mojo's URL objects already had a
method for this before 4.90, but to get really relative URLs like I<../foo.html>
you had to add the request url like this:

    my $url     = $self->url_to('foo', bar => 'baz');
    my $rel_url = $url->to_rel($self->req->url);

The new helper method gets the job done for you:

    my $rel_url = $self->rel_url_for('foo', bar => 'baz');

Generated URLs are always relative to the request url. 

=head2 In templates

Since this is a helper method, it's available in templates after using
this plugin:

    <%= rel_url_for 'foo', bar => 'baz' %>

=head2 Replacing C<url_for>

To use relative URLs in your whole web app without rewriting the code, this
plugin can replace Mojolicious' C<url_for> helper for you, which is used by
useful things like C<link_to> and C<form_for>. You need to set the
C<replace_url_for> option for this:

    # Mojolicious
    $self->plugin(RelativeUrlFor => { replace_url_for => 1 });

    # Mojolicious::Lite
    plugin RelativeUrlFor => { replace_url_for => 1 };

=head1 REPOSITORY AND ISSUE TRACKING

This plugin lives in github:
L<http://github.com/memowe/mojolicious-plugin-relativeurlfor>.
You're welcome to use github's issue tracker to report bugs or discuss the code:
L<http://github.com/memowe/mojolicious-plugin-relativeurlfor/issues>

=head1 AUTHOR AND LICENSE

Copyright Mirko Westermeier E<lt>mirko@westermeier.deE<gt>

This software is released under the MIT license. See MIT-LICENSE for details.

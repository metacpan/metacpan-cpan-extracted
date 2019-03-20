package Mojolicious::Plugin::Wordpress;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::DOM;
use Mojo::UserAgent;
use Mojo::Util 'trim';

use constant DEBUG => $ENV{MOJO_WORDPRESS_DEBUG} || 0;

our $VERSION = '0.01';

has base_url       => 'http://localhost/wp-json';     # Will become a Mojo::URL object
has post_processor => undef;
has ua             => sub { Mojo::UserAgent->new };
has yoast_meta_key => 'yoast_meta';

sub register {
  my ($self, $app, $config) = @_;
  my $prefix = $config->{prefix} || 'wp';

  $self->$_($config->{$_}) for grep { $config->{$_} } qw(base_url post_processor yoast_meta_key ua);
  $self->base_url(Mojo::URL->new($self->base_url)) unless ref $self->base_url;

  $app->helper("$prefix.meta_from" => sub { $self->_helper_meta_from(@_) });

  my $default_post_types = [qw(pages posts)];
  for my $type (@{$config->{post_types} || $default_post_types}) {
    (my $singular = $type) =~ s!s$!!;
    $app->helper("$prefix.get_${singular}_p" => sub { $self->_helper_get_post_p($type => @_) });
    $app->helper("$prefix.get_${type}_p" => sub { $self->_helper_get_posts_p($type => @_) });
  }
}

sub _arr { ref $_[0] eq 'ARRAY' ? $_[0] : [] }

sub _description {
  my $dom  = Mojo::DOM->new(shift->{content}{rendered} || '');
  my $text = trim($dom->all_text);
  return 297 < length $text ? sprintf '%s...', substr $text, 0, 297 : $text;
}

sub _helper_meta_from {
  my ($self, $c, $post) = @_;
  return undef unless ref $post eq 'HASH';

  my ($yoast_key, %meta) = ($self->yoast_meta_key);
  for my $key (keys %{$post->{x_metadata} || {}}, keys %{$post->{$yoast_key} || {}}) {
    next unless my $val = $post->{x_metadata}{$key} || $post->{$yoast_key}{$key};
    my $meta_key = $key;
    next unless $meta_key =~ s!^_?yoast_wpseo_!!;
    $meta{$meta_key} ||= $val;
  }

  $meta{description}
    ||= delete $meta{metadesc} || $meta{opengraph_description} || $meta{twitter_description} || _description($post);
  $meta{title} ||= $meta{opengraph_title} || $meta{twitter_title} || '';
  $meta{"opengraph_$_"}      ||= $meta{"twitter_$_"} || $meta{$_} for qw(description title);
  $meta{twitter_description} ||= $meta{opengraph_description};
  $meta{twitter_title} ||= $meta{opengraph_title} || $meta{title};

  return \%meta;
}

sub _helper_get_post_p {
  my ($self, $type, $c, $params) = @_;
  $params = {slug => $params} unless ref $params;

  my %query = %$params;
  delete $params->{post_processor};

  my $processor = $params->{post_processor} || $self->post_processor;
  return $self->_raw(get_p => "wp/v2/$type", \%query)->then(sub {
    my $wp_res = shift->res;
    my $post   = _arr($wp_res->json)->[0];
    return $post && $processor ? $c->$processor($post) : $post;
  });
}

sub _helper_get_posts_p {
  my ($self, $type, $c, $params) = @_;

  my %query = %{$params || {}};
  delete $query{$_} for qw(all post_processor);
  $query{page}     = 1   if $params->{all};
  $query{per_page} = 100 if $params->{all} and !$query{per_page};

  my $processor = $params->{post_processor} || $self->post_processor;
  my ($gather, @posts);
  $gather = sub {
    my $wp_res = shift->res;

    for my $post (@{$wp_res->json || []}) {
      push @posts, $processor ? $c->$processor($post) : $post;
    }

    # Done getting all posts
    my $n_pages = $wp_res->headers->header('x-wp-totalpages') || 1;
    return \@posts if !$params->{all} or $n_pages <= $query{page};

    # Fetch more
    $query{page}++;
    $self->_raw(get_p => 'wp/v2/posts', \%query)->then($gather);
  };

  return $self->_raw(get_p => "wp/v2/$type", \%query)->then($gather);
}

sub _raw {
  my ($self, $method, $path, $query, @data) = @_;
  my $url = $self->base_url->clone;

  # Want the query params sorted to improve caching
  $url->query(ref $query eq 'ARRAY' ? $query : [map { ($_ => $query->{$_}) } sort keys %$query]);
  push @{$url->path}, split '/', $path;

  warn "[Wordpress] $method $url\n" if DEBUG;

  return $self->ua->$method($url, @data);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Wordpress - Use Wordpress as a headless CMS

=head1 SYNOPSIS

  use Mojolicious::Lite;
  plugin wordpress => {base_url => "https://wordpress.example.com/wp-json"};

  get "/page/:slug" => sub {
    my $c = shift->render_later;
    $c->wp->get_page_p($c->stash("slug"))->then(sub {
      my $page = shift;
      $c->render(json => $page);
    });
  };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Wordpress> is a plugin for getting data using the
Wordpress JSON API.

This plugin is currently EXPERIMENTAL. Let me know if you have any feedback at
L<https://github.com/jhthorsen/mojolicious-plugin-wordpress/issues>.

=head1 HELPERS

=head2 get_post_p

  my $promise = $c->wp->get_post_p;
  my $promise = $c->wp->get_post_p{$slug);
  my $promise = $c->wp->get_post_p{\%query};

This helper will be available, dependent on what you set L</post_types> to. It
will return a L<Mojo::Promise> that will get a C<$post> hash-ref or C<undef> in
the fullfillment callback. The C<$post> hash-ref will be exactly what was
returned through the API from Wordpress, or whatever the L</post_processor> has
changed it to.

=head2 get_posts_p

  my $promise = $c->wp->get_posts_p;
  my $promise = $c->wp->get_posts_p{\%query};
  my $promise = $c->wp->get_posts_p{{all => 1, post_processor => sub { ... }}};

This helper will be available, dependent on what you set L</post_types> to. It
will return a L<Mojo::Promise> that will get an array-ref of C<$post> hash refs
in the fullfillment callback. A C<$post> hash-ref will be exactly what was
returned through the API from Wordpress, or whatever the L</post_processor> has
changed it to.

=head2 meta_from

  my $meta = $c->wp->meta_from(\%post);

This helper will extract meta information from the Wordpress post and return a
C<%hash> with the following keys set:

  {
    canonical             => "",
    title                 => "",
    description           => "",
    opengraph_title       => "",
    opengraph_description => "",
    twitter_title         => "",
    twitter_description   => "",
    ...
  }

Note that some keys might be missing or some keys might be added, depending on
how the Wordpress server has been set up.

Suggested Wordpress plugins: L<https://wordpress.org/plugins/wordpress-seo/>
and L<https://github.com/niels-garve/yoast-to-rest-api>.

=head1 ATTRIBUTES

=head2 base_url

  my $url = $wp->base_url;
  my $wp  = $wp->base_url("https://wordpress.example.com/wp-json");

Holds the base URL to the Wordpress server API, including "/wp-json".

=head2 post_processor

  my $cb = $wp->post_processor;
  my $wp = $wp->post_processor(sub { my ($c, $post) = @_ });

A code block that can be used to post process the JSON response from Wordpress.

=head2 ua

  my $ua = $wp->ua;
  my $wp = $wp->ua(Mojo::UserAgent->new);

Holds a L<Mojo::UserAgent> object that is used to get data from Wordpress.

=head2 yoast_meta_key

  my $str = $wp->yaost_meta_key;
  my $wp  = $wp->yaost_meta_key("yoast_meta");

The key in the post JSON response that holds
L<YOAST|https://wordpress.org/plugins/wordpress-seo/> meta information.

=head1 METHODS

=head2 register

  $wp->register($app, \%config);
  $app->plugin(wordpress => \%config);

Used to register this plugin. C<%config> can have:

=over 2

=item * base_url

See L</base_url>.

=item * post_processor

See L</post_processor>.

=item * post_types

A list of post types available in the CMS. Defaults to:

  ["pages", "posts"]

This list will generate helpers to fetch data from Wordpress. Example default
helpers are:

  my $p = $c->wp->get_page_p(...);
  my $p = $c->wp->get_pages_p(...);
  my $p = $c->wp->get_post_p(...);
  my $p = $c->wp->get_posts_p(...);

See L</get_post_p> and L</get_posts_p> for more information.

Suggested Wordpress plugin:
L<https://wordpress.org/plugins/custom-post-type-maker/>

=item * prefix

The prefix for the helpers. Defaults to "wp".

=item * ua

See L</ua>.

=item * yoast_meta_key

See L</yoast_meta_key>.

=back

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C), Jan Henning Thorsen.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

package Mojolicious::Plugin::Renderer::WithoutCache;
use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::Renderer::WithoutCache::Cache;

=head1 NAME

Mojolicious::Plugin::Renderer::WithoutCache - Disable the template cache in your Mojo app

=begin html

<p>
<a href="https://travis-ci.org/simbabque/Mojolicious-Plugin-Renderer-WithoutCache"><img src="https://travis-ci.org/simbabque/Mojolicious-Plugin-Renderer-WithoutCache.svg?branch=master"></a>
<a href='https://coveralls.io/github/simbabque/Mojolicious-Plugin-Renderer-WithoutCache?branch=master'><img src='https://coveralls.io/repos/github/simbabque/Mojolicious-Plugin-Renderer-WithoutCache/badge.svg?branch=master' alt='Coverage Status' /></a>
</p>

=end html

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

This plugin turns off the renderer's cache in L<Mojolicious> and L<Mojo::Lite> applications.

    use Mojolicious::Lite;
    plugin 'Renderer::WithoutCache';

=head1 DESCRIPTION

This does what it says on the box. It turns off caching for the L<Mojolicious::Renderer>
or any other renderer that's inside C<$app-E<gt>renderer> by injecting a cache object that
does not do anything. This is supperior to setting the C<max_keys> of L<Mojo::Cache>
to C<0> if you plan to do a lot of uncached requests, becase L<Mojolicious::Renderer>
will still try to cache, and every time L<Mojo::Cache> sets a value in the cache it
looks at the C<max_keys>, and then stops.

Doing nothing at all is cheaper. But not a lot really.

=head1 METHODS

=head2 register

Register the plugin in a L<Mojolicious> application.

    $plugin->register(Mojolicious->new);

=cut

sub register {
    my ( $self, $app ) = @_;
    $app->renderer->cache( Mojolicious::Plugin::Renderer::WithoutCache::Cache->new );
}

=head1 AUTHOR

simbabque, C<< <simbabque at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through an issue
on github at L<https://github.com/simbabque/Mojolicious-Plugin-Renderer-WithoutCache/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::Renderer::WithoutCache

=head2 Why would I want to turn off the cache?

I don't know.

=head1 ACKNOWLEDGEMENTS

This plugin was inspired by Tom Hunt asking about turning the cache off
on L<Stack Overflow|http://stackoverflow.com/q/41750243/1331451>.

=head1 LICENSE

Copyright (C) simbabque.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;


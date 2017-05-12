package Mojolicious::Plugin::Renderer::WithoutCache::Cache;
use Mojo::Base -base;

=head1 NAME

Mojolicious::Plugin::Renderer::WithoutCache::Cache - Mojo::Cache that doesn't cache

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

You probably don't want to use this directly.

    my $cache = Mojolicious::Plugin::Renderer::WithoutCache::Cache->new;
    # this cache does nothing

=head1 DESCRIPTION

A cache object that's compatible to Mojo::Cache but does nothing. It does
not save or return any values. It's always empty.

=head1 METHODS

=head2 get

Does nothing. Returns C<undef>.

=cut

sub get {}

=head2 set

Does nothing. Returns C<$self> so chaining is possible.

=cut

sub set { shift; }

=head2 max_keys

Always returns zero. Can't be set. We don't want any keys.

=cut

sub max_keys { 0 }

=head1 AUTHOR

simbabque, C<< <simbabque at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through an issue
on github at L<https://github.com/simbabque/Mojolicious-Plugin-Renderer-WithoutCache/issues>.

=head1 LICENSE

Copyright (C) simbabque.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

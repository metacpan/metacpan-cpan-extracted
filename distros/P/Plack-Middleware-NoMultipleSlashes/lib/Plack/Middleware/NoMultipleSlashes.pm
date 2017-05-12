use strict;
use warnings;
package Plack::Middleware::NoMultipleSlashes;
BEGIN {
  $Plack::Middleware::NoMultipleSlashes::VERSION = '0.001';
}
# ABSTRACT: Remove multiple slashes in your paths automatically

use parent qw(Plack::Middleware);

sub call {
    my($self, $env) = @_;
    $env->{'PATH_INFO'} =~ s{/+}{/}g;
    $self->app->($env);
};

1;



=pod

=head1 NAME

Plack::Middleware::NoMultipleSlashes - Remove multiple slashes in your paths automatically

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Pure Plack:

    # in your app.psgi
    use Plack::Builder;

    my $app = sub { ... };

    builder {
        enable 'NoMultipleSlashes';
        $app;
    };

Or in your Dancer app:

    # in config.yml
    plack_middlewares:
        - [ NoMultipleSlashes ]

=head1 DESCRIPTION

In short: this removes all multiple slashes from your B<PATH_INFO>. Read on,
if you care why.

Multiple slashes in requests are a common problem, which many share.
Apparently, the RFC states that you should be able to expect different results
from I<http://server/> and I<http://server//> (notice the second slash), so
if the frameworks wish to maintain RFC compatibility, they cannot remove those
extra slashes for you.

While you can handle this issue in a reverse proxy, in a rewrite module or
in your code, I find it more comfortable to have Plack take care of it in the
thin layer called Middlewares.

By enabling this middleware, all multiple slashes in your requests will
automatically be cut. I<//hello///world> becomes I</hello/world>. Simple as
that.

=head1 ORIGIN

This Plack middleware was written originally after the issue was raised in
the L<Dancer> (L<http://perldancer.org>) community.

If you're using Dancer, this is the prefered way to handle this issue.

=head1 AUTHOR

  Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


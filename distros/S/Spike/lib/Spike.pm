package Spike;

use strict;
use warnings;

our $VERSION = 2.0004;

use 5.10.1;

use Plack 1.0030;
use List::Util 1.45;
use File::ShareDir;

use base qw(Spike::Site::Router);

1;

__END__

=head1 NAME

Spike-2.0 - Simple L<Plack::Request>-based web framework

=head1 SYNOPSIS

=head2 Quick start

1. Install Spike package

2. C<spike add MySite>

3. C<cd MySite>

4. C<rm -r web/mysite>

5. C<ln -s /path/to/web/static/files web/mysite>

6. C<plackup script/mysite.psgi>

=head2 Simple site

=head3 startup.psgi

    use FindBin;
    use lib "$FindBin::Bin/../lib";

    use DeadBeef::Site;

    DeadBeef::Site->run;

=head3 DeadBeef::Site

    package DeadBeef::Site;

    use base qw(Spike);

    sub startup {
        my $self = shift;

        $self->route
            ->prepare(sub {
                my ($req, $res) = @_;
                # place code here
            })
            ->finalize(sub {
                my ($req, $res) = @_;
                # place code here
            })
            ->error(404 => sub {
                my ($req, $res) = @_;
                # place code here
            })
            ->error(500 => sub {
                my ($req, $res) = @_;
                # place code here
            })
            ->get('/' => sub {
                my ($req, $res) = @_;
                # place code here
            })
            ->post('/' => sub {
                my ($req, $res) = @_;
                # place code here
            });
    }

    1;

=head2 Routes and handlers

    $new_route = $route->route('level1')
    $new_route = $route->route('level1/level2/...')
    $new_route = $route->route('*')
    $new_route = $route->route('#name')
    $new_route = $route->route('#name' => [qw(value1 value2 ...)])
    $new_route = $route->route('#name' => qr/regexp/ })
    $new_route = $route->route('#name' => sub { ... })

    # all of the above together
    $new_route = $route->route('l1/#n1/l3' => sub { ... })
        ->route('*/#n2/l6' => sub { ... })

    $route = $route->get(sub { ... })
    $route = $route->get('path' => sub { ... })
    $route = $route->post(sub { ... })
    $route = $route->post('path' => sub { ... })
    $route = $route->all(sub { ... })
    $route = $route->all('path' => sub { ... })

    $route = $route->error(sub { ... })
    $route = $route->error(404 => sub { ... })
    $route = $route->error(Spike::Error::Class => sub { ... })

    $route = $route->prepare(sub { ... })
    $route = $route->finalize(sub { ... })

=head1 SEE ALSO

L<Plack>, L<Plack::Request>, L<Plack::Response>

=head1 AUTHOR

Aleksandr Aleshin <silencer2k@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2016 Aleksandr Aleshin

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

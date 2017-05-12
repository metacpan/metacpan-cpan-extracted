package Plack::Middleware::Debug::Redis::Info;

# ABSTRACT: Redis info debug panel

use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base Plack::Middleware::Debug::Redis);

our $VERSION = '0.03'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

sub prepare_app {
    my ($self) = @_;

    $self->redis_connect;
}

sub run {
    my ($self, $env, $panel) = @_;

    $panel->title('Redis::Info');
    $panel->nav_title($panel->title);

    my $info = $self->redis->info;

    # tweak db keys
    foreach my $db (grep { /^db\d{1,2}/ } keys %$info) {
        my $flatten = $self->flatten_db($db, $info->{$db});
        my @keys_flatten = keys %$flatten;
        @$info{@keys_flatten} = @$flatten{@keys_flatten};
        delete $info->{$db};
    }

    $panel->nav_subtitle('Version: ' . $info->{redis_version});

    return sub {
        $panel->content($self->render_hash($info));
    };
}

sub flatten_db {
    my ($self, $database, $value) = @_;

    my %flatten = ();

    %flatten = map {
        my @ary = split /=/;
        $database . '_' . $ary[0] => $ary[1];
    } split /,/, $value;

    \%flatten;
}

1; # End of Plack::Middleware::Debug::Redis::Info

__END__

=pod

=head1 NAME

Plack::Middleware::Debug::Redis::Info - Redis info debug panel

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    # inside your psgi app
    enable 'Debug',
        panels => [
            [ 'Redis::Info', instance => 'redis.example.com:6379' ],
        ];

=head1 DESCRIPTION

Plack::Middleware::Debug::Redis::Info extends Plack::Middleware::Debug by adding redis server info debug panel.
Panel displays data which available through INFO command issued in redis-cli. Before displaying info some tweaks
were processed. Normally INFO command shows total and expires keys in one line such as

    db0 => 'keys=167,expires=145',
    db1 => 'keys=75,expires=0',

This module turn in to

    db0_expires => '145',
    db0_keys    => '167',
    db1_expires => '0',
    db1_keys    => '75',

=head1 METHODS

=head2 prepare_app

See L<Plack::Middleware::Debug>

=head2 run

See L<Plack::Middleware::Debug>

=head2 redis_connect

See L<Plack::Middleware::Debug::Redis>

=head2 redis

See L<Plack::Middleware::Debug::Redis>

=head2 flatten_db

Flatten some complex data structures got from redis' INFO command. At the moment this is keys' composition of the database.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Debug-Redis/issues>

=head1 SEE ALSO

L<Plack::Middleware::Debug::Redis>

L<Plack::Middleware::Debug>

L<Redis>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

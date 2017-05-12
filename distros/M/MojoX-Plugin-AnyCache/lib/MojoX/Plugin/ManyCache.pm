package MojoX::Plugin::ManyCache;

use Mojo::Base 'Mojolicious::Plugin';
use MojoX::Plugin::AnyCache;

has 'pool';

sub register {
    my ($self, $app, %args) = @_;

    my @cache_names = @{$args{names}};
    my $config      = $args{config};

    $self->pool({});
    
    foreach my $name (@cache_names) {
        die "Missing cache configuration for cache '$name'" unless exists $config->{$name};
        $self->pool->{$name} = MojoX::Plugin::AnyCache->new( $config->{$name} );
    }

    $app->helper(cache => sub { 
        my (undef, $name) = @_;
        die "Unknown cache '$name' " unless exists $self->pool->{$name};
        $self->pool->{$name}
    });
}

1;

=encoding utf8

=head1 NAME

MojoX::Plugin::ManyCache - Multi-Cache plugin with blocking and non-blocking support

=head1 SYNOPSIS

  $app->plugin('MojoX::Plugin::ManyCache', 
        names => qw[ cache_one cache_two ],
        config => {
            cache_one => {
                backend => 'MojoX::Plugin::AnyCache::Backend::Redis',
                server => '127.0.0.1:6379',
            },
            cache_two => {
                backend => 'MojoX::Plugin::AnyCache::Backend::Redis',
                server => '10.1.1.1:6379',
            }
        }
  );

  $app->cache('cache_one')->set('key', 'value')l

=head1 DESCRIPTION

MojoX::Plugin::ManyCache provides an interface to multiple AnyCache instances.

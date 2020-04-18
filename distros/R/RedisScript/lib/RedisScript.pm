package RedisScript;

use 5.026001;
use strict;
use warnings;
use Carp;

our $VERSION = '0.02';

my @_needed_args_for_new = qw{ redis code };


sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;

  ## init args
  defined $args{ $_ }
    and $self->{ $_ } = $args{ $_ }
    for @_needed_args_for_new;

  ## args validation
  croak( q{missing redis args or invalid redis object} )
    unless( defined( $self->{redis} )
            and ( UNIVERSAL::isa( $self->{redis}, q{Redis} )
                  or $self->{redis}->can( q{script_load} )
                )
          );

  $self->__init_code();

  return $self;
}

sub __init_code {
  my $self = shift;

  ## any cached hash??
  if( ! exists $self->{_sha_cache} ) {
    ## need to load script
    $self->__load_script();
    return;
  }

  ## check if script is loaded
  if( $self->{ redis }->script_exists( $self->{_sha_cache} ) ne 1 ) {
    $self->__load_script();
    return;
  }
  return;
}

sub __load_script {
  my $self = shift;

  my $sha = $self->{redis}->script_load( $self->{ code } );
  $self->{_sha_cache} = $sha;

  return;
}

sub runit {
  my $self = shift;
  my %args = @_;

  $self->__init_code();

  croak( q{need two array ref as args (keys and args)} )
    unless( ( defined( $args{keys} )
              and ( ref( $args{keys} ) eq q{ARRAY} )
            )
            and ( defined( $args{args} )
                  and ( ref( $args{args} ) eq q{ARRAY} ) )
          );

  return $self->{redis}->evalsha( $self->{_sha_cache},
                                  scalar @{ $args{keys} },
                                  @{ $args{keys} },
                                  @{ $args{args} },
                                );
}


1;
__END__

=head1 NAME

RedisScript - Perl extension to help load and run Lua script in Redis server.

=head1 SYNOPSIS

  use RedisScript;
  use Redis;

  my $rs_o = RedisScript->new( redis => Redis->new(),
                               code => <<EOB,
local key1 = KEYS[1]
local res = redis.call( 'setmx', key1, ARGV[1], ARGV[2] )
return 1
EOB
                             );
  my @res = $rs_o->runit( keys => [ qw/ a / ], args => [ 1, 300 ] );

=head1 DESCRIPTION

The extension serve to help load and run Lua script in Redis servers.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Please see Redis documentation about running Lua script (https://redis.io/commands#scripting)

=head1 AUTHOR

pedro.frazao

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by pedro.frazao

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

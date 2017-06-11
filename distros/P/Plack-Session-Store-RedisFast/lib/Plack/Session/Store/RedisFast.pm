package Plack::Session::Store::RedisFast;

use strict;
use warnings;

use 5.008_005;

use Carp qw( carp );
use Plack::Util::Accessor qw( prefix redis inflate deflate expire );
use Time::Seconds qw( ONE_MONTH );

use parent 'Plack::Session::Store';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:AKZHAN';

sub new {
    my ( $class, %param ) = @_;
    $param{prefix} = __PACKAGE__ . ':' unless defined $param{prefix};
    $param{expire} = ONE_MONTH         unless exists $param{expire};

    $param{inflate} ||= \&_inflate;
    $param{deflate} ||= \&_deflate;

    unless ( $param{redis} ) {
        my $builder = $param{builder} || \&_build_redis;
        delete $param{builder};
        $param{redis} = $builder->();
    }

    bless {%param} => $class;
}

sub _build_redis {
    my $instance;
    eval {
        require Redis::Fast;
        $instance = Redis::Fast->new;
        1;
    } or do {
        require Redis;
        $instance = Redis->new;
    };
    $instance;
}

sub _build_encoder {
    my $instance;
    eval {
        require JSON::XS;
        $instance = JSON::XS->new->utf8->allow_nonref;
        1;
    } or do {
        require JSON;
        $instance = JSON->new->utf8->allow_nonref;
    };
    $instance;
}

my $_encoder = undef;

sub _encoder {
    $_encoder ||= _build_encoder();
}

sub _inflate {
    my ($session) = @_;
    _encoder->encode($session);
}

sub _deflate {
    my ($data) = @_;
    _encoder->decode($data);
}

sub fetch {
    my ( $self, $session_id ) = @_;
    my $data = $self->redis->get( $self->prefix . $session_id );
    return undef unless defined $data;
    $self->deflate->($data);
}

sub store {
    my ( $self, $session_id, $session ) = @_;
    unless ( defined $session ) {
        carp "store: no session provided";
        return;
    }
    my $data = $self->inflate->($session);
    $self->redis->set(
        $self->prefix . $session_id => $data,
        ( defined( $self->expire ) ? ( EX => $self->expire ) : () ),
    );
}

sub remove {
    my ( $self, $session_id ) = @_;
    $self->redis->del( $self->prefix . $session_id );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Plack::Session::Store::RedisFast - Redis session store.

Default implementation of Redis handle is L<Redis::Fast>; otherwise L<Redis>.

May be overriden through L</redis> or  L</builder> param.

Default implementation of serializer handle is L<JSON::XS>; otherwise L<JSON>.

May be overriden through L</inflate> and L</deflate> param.

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Session::Store::RedisFast;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session',
          store => Plack::Session::Store::RedisFast->new;
      $app;
  };

=head1 DESCRIPTION

This will persist session data using L<Redis::Fast> or L<Redis>.

This is a subclass of L<Plack::Session::Store> and implements
its full interface.

=head1 METHODS

=over 4

=item B<new ( %params )>

=item B<redis>

A simple accessor for the Redis handle.

=item B<builder>

A simple builder for the Redis handle if L</redis> not set.

=item B<inflate>

A simple serializer, JSON::XS->new->utf8->allow_nonref->encode
or JSON->new->utf8->allow_nonref->encode by default.

=item B<deflate>

A simple deserializer, JSON::XS->new->utf8->allow_nonref->decode
or JSON->new->utf8->allow_nonref->decode by default.

=item B<prefix>

A prefix for Redis session ids. 'Plack::Session::Store::RedisFast:' by default.

=item B<expire>

An expire for Redis sessions. L<Time::Seconds/ONE_MONTH> by default.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please fill in GitHub issues.

=head1 AUTHOR

Akzhan Abdulin E<lt>akzhan.abdulin@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Akzhan Abdulin

=head1 LICENSE

MIT License

=cut

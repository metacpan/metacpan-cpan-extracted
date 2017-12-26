package Mojolicious::Plugin::PgLock;
use Mojo::Base 'Mojolicious::Plugin';

use Mojolicious::Plugin::PgLock::Sentinel;

our $VERSION = "0.01";

sub register {
    my( $plugin, $app, $conf ) =  @_;
    $app->helper( get_lock => sub { push @_, $conf->{pg}; &get_lock }  );
}

sub get_lock {
    my $self = shift;
    my $pg   = pop;
    my $params = @_ % 2 ? $_[0] : { @_ };
    $params->{app} = $self->app;
    $params->{db}  = $pg->db;
    $params->{name} //= ( caller(2) )[0];
    my $sentinel = Mojolicious::Plugin::PgLock::Sentinel->new($params);
    return $sentinel->lock;
}

1;

__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::PgLock - postgres advisory locks for Mojolicious application

=head1 SYNOPSIS

  my $pg = Mojo::Pg->new('postgresql://...');
  $app->plugin( PgLock => { pg => $pg } );

  if ( my $lock = $app->get_lock ) {
    # make something exclusively
  }

=head1 DESCRIPTION

Mojolicious::Plugin::PgLock implements get_lock helper. It is a shugar for
L<postgres advisory lock functions|https://www.postgresql.org/docs/current/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS>.

=head1 HELPERS

L<Mojolicious::Plugin::PgLock> implements the following helper.

=head2 get_lock

  my $lock = $app->get_lock
      or die "another process is running";

  # use a name and try to get a shared lock
  my $shared_lock = $app->get_lock( name => 'mySharedLock', shared => 1 );

  # use explicit id and wait until a lock is granted
  my $lock = $app->get_lock( id => 9874738, wait => 1 );

C<get_lock> helper uses one of postgres advisory lock function C<pg_try_advisory_lock>,
 C<pg_advisory_lock>, C<pg_advisory_lock_shared>, C<pg_advisory_lock_shared>
to get an exclusive or shared lock depending on parameters.

C<get_lock> helper returns a L<Mojolicious::Plugin::PgLock::Sentinel> object which holds
the lock while it is alive.

=over

=item B<id>

C<id> parameter is used as integer key argument in postgres advisory lock function call.
Default value for C<id> is CRC32 hash of C<name> parameter.

=item B<name>

C<name> is used for C<id> calculation only if C<id> is not set.
Default value for C<name> is C<(caller(2))[0]>. It allows to use C<get_helper>
without parameters in L<Mojolicious::Commands> modules

=item B<shared>

C<shared> parameter chose shared or exclusive lock. Default is false.

=item B<wait>

If C<wait> is true then function will wait until a lock is granted.

=back

=head1 LICENSE

Copyright (C) Alexander Onokhov E<lt>onokhov@cpan.orgE<gt>.

This library is free software; you can redistribute it and/or modify
it under the MIT license terms.

=head1 AUTHOR

Copyright (C) Alexander Onokhov E<lt>onokhov@cpan.orgE<gt>.

=cut

package Net::ZooKeeper::Lock;
{
  $Net::ZooKeeper::Lock::VERSION = '0.03';
}

use strict;
use warnings;

use Net::ZooKeeper qw(:events :node_flags :acls);
use Params::Validate qw(:all);

# ABSTRACT: distributed locks via ZooKeeper



sub new {
    my $class = shift;
    my $p = validate(@_, {
        blocking      => { type => BOOLEAN, default => 1 },
        zkh           => { isa => 'Net::ZooKeeper' },
        lock_prefix   => { type => SCALAR, regex => qr{^/.+}o, default => '/lock' },
        lock_name     => { type => SCALAR, regex => qr{^[^/]+$}o },
        create_prefix => { type => BOOLEAN, default => 1 },
        watch_timeout => { type => SCALAR, regex => qr/^\d+$/o, default => 86400 * 1000 },
        data          => { type => SCALAR, default => 0 },
    });
    $p->{lock_prefix} =~ s{/$}{};

    my $self = $p;
    bless $self, $class;

    if ($self->_lock) {
        return $self;
    } else {
        return;
    }
}


sub lock_path {
    my $self = shift;
    return $self->{lock_path};
}


sub unlock {
    my $self = shift;
    $self->{zkh}->delete($self->{lock_path}) if ($self->{lock_path});
}

sub _create_cyclic_path {
    my ($self, $path) = @_;

    my $current_index = 1;
    while ($current_index > 0) {
        $current_index = index($path, "/", $current_index + 1);
        my $current_path;
        if ($current_index > 0) {
            $current_path = substr($path, 0, $current_index);
        } else {
            $current_path = $path;
        }

        if (!$self->{zkh}->exists($current_path)) {
            $self->{zkh}->create($current_path, '0',
                acl => ZOO_OPEN_ACL_UNSAFE
            );
        }
    }
}
sub _lock {
    my $self = shift;

    my $zkh = $self->{zkh};
    my $lock_prefix = $self->{lock_prefix};
    my $lock_name = $self->{lock_name};

    if ($self->{create_prefix}) {
        $self->_create_cyclic_path($lock_prefix);
    }

    my $lock_tmpl = $lock_prefix . "/" . $lock_name . "-";
    my $lock_path = $zkh->create($lock_tmpl, $self->{data},
        flags => (ZOO_EPHEMERAL | ZOO_SEQUENCE),
        acl   => ZOO_OPEN_ACL_UNSAFE) or
    die "unable to create sequence znode $lock_tmpl: " . $zkh->get_error . "\n";

    $self->{lock_path} = $lock_path;

    while (1) {
        my @child_names = $zkh->get_children($lock_prefix);
        die "no childs\n" unless (scalar(@child_names));

        my @less_than_me = sort
                           grep { ($_ =~ m/^${lock_name}-\d+$/) &&
                                  ($lock_prefix . "/" . $_ lt $lock_path) }
                           @child_names;

        unless (@less_than_me) {
            return 1;
        }

        unless ($self->{blocking}) {
            $self->unlock;
            return 0;
        }

        $self->_exists($lock_prefix . "/" . $less_than_me[-1]);
    }
}

sub _exists {
    my ($self, $path) = @_;

    my $zkh = $self->{zkh};

    my $watcher = $zkh->watch(timeout => $self->{watch_timeout});
    while (1) {
        my $exists = $zkh->exists(
            $path,
            watch => $watcher,
        );

        if (!$exists) {
            next;
        } else {
            my $ret = $watcher->wait;
            unless ($ret) {
                next;
            }

            if ($watcher->{event} == ZOO_DELETED_EVENT) {
                last;
            } else {
                next;
            }
        }
    }
}

sub DESTROY {
    local $@;

    my $self = shift;

    $self->unlock;
};


1;

__END__

=pod

=head1 NAME

Net::ZooKeeper::Lock - distributed locks via ZooKeeper

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Net::ZooKeeper::Lock;

  # take a lock
  my $lock = Net::ZooKeeper::Lock->new({
      zkh => Net::ZooKeeper->new('localhost:2181'),
      lock_name   => 'bar',
  });

  # release a lock
  $lock->unlock;
  # or
  undef $lock;

=head1 DESCRIPTION

This module implements distributed locks via ZooKeeper using L<Net::ZooKeeper> and ZooKeeper recipe described at L<http://zookeeper.apache.org/doc/trunk/recipes.html#sc_recipes_Locks>. It doesn't implements shared locks, it will appear in the next releases.

=head1 METHODS

=over 4

=item new($options)

Takes a lock and returns object that holds this lock. Throws exception if something goes wrong.

C<$options> is a hashref with following keys:

=over 4

=item blocking (optional)

By default module blocks in the C<new> method if lock already taken. If C<blocking> is C<false>, then C<new> doesn't wait if lock already taken and returns undef.

=item zkh

C<Net::ZooKeeper> object.

=item lock_prefix (optional)

"Directory" where sequential znodes for lock will be placed. It is good to make different prefixes for different locks if you have many locks (in this case C<Net::ZooKeeper::get_children()> will return data relevant only for one concrete lock. For example, it may looks like "/lock/foo1/" for "foo1" lock and "/lock/foo2" for "foo2" lock.

Default is just "lock".

=item lock_name

Name of your lock (it will be concatenated with C<lock_prefix> for creating template for sequential znodes).

=item create_prefix (optional)

If you want to store ephemeral znodes in C<lock_prefix>, then znode with name C<lock_prefix> should be created before creation of ephemeral znodes.

You can create this prefix znode once in your code. Or you can use C<create_prefix> flag, it will check and create C<lock_prefix> znode every time when you try to make new lock with C<lock_prefix>.

Default is 1.

=item data

Data to be stored in lock znode.

It may be useful to store the hostname and pid of the process, that created the lock.

Default is '0'.

=back

=item lock_path

Returns the path of lock znode.

=item unlock

Releases getted lock. This method calls in destructor, so your lock releases when you go out of C<$lock> scope or when you call C<undef($lock)>.

=back

=head1 MISCELLANEOUS

It seems that C<$SIG{PIPE}> signal doesn't occurs in C<Net::ZooKeeper> with new versions of ZooKeeper.

In this case following situation is possible: some process on some machine have taken the lock, then network disappeared on this machine, then another process on another machine can take the lock after C<session_limit>. And you have 2 processes that holds the same lock.

For such a case you can create some separate check-script that will test connection with ZooKeeper every N seconds < C<session_limit>. If connection lost, then this script can kill all processes on this machine that holds ZooKeeper locks.

=head1 SEE ALSO

L<Net::ZooKeeper>

L<http://zookeeper.apache.org/doc/trunk/recipes.html#sc_recipes_Locks>

=head1 ACKNOWLEDGEMENTS

Oleg Komarov

=head1 AUTHOR

Yury Zavarin <yury.zavarin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yury Zavarin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

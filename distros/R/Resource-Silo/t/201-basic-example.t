#!/usr/bin/perl

=head1 DESCRIPTION

Use Resource::Silo DLS with some fake classes,
make sure the most typical happy paths work.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

my %effect;
my $config_data = {
    db => {
        user => 'myuser',
    },
};

BEGIN {
    package My::Config;
    sub load {
        my $class = shift;
        $effect{config}++;
        return $config_data;
    };

    package My::Database;
    my $conn_id;
    sub connect {
        my ($class, $user) = @_;
        defined $user or die "Nope, no user given";
        $effect{database}{$user}++;
        return bless {
            conn_id => ++$conn_id,
            user    => $user,
        }, $class;
    };
    sub id { return $_[0]->{conn_id} };
    sub DESTROY {
        my $self = shift;
        $effect{database}{$self->{user}}--;
    };

    package My::Res;
    use Resource::Silo -class;

    resource config      => sub { My::Config->load; };
    resource dbh         => sub {
        my $self = shift;
        my $conf = $self->config->{db};
        My::Database->connect( $conf->{user} );
    };

    my $pmfile = __PACKAGE__;
    $pmfile =~ s#::#/#g;
    $INC{ "$pmfile.pm" } = __FILE__;
    1;
};

use My::Res;

subtest 'imports & instantiation' => sub {
    can_ok 'main', 'silo';
    is ref silo(), 'My::Res', 'silo is of correct package';
    isa_ok silo(), 'Resource::Silo::Container';
    is_deeply \%effect, {}, 'No resources loaded so far';
};

subtest 'load by dependencies' => sub {
    lives_ok {
        silo->ctl->meta->self_check;
    } "self-check lives";
    my $dbh = silo->dbh;
    is ref $dbh, 'My::Database', 'can connect to "database"';
    is $dbh->id, 1, 'corrent db connection id';
    is silo->dbh->id, 1, "connection was cached";
    is_deeply \%effect, { config => 1, database => { myuser => 1 } },
        "both config and database were loaded";
};

subtest 'config caching' => sub {
    my $conf = silo->config;
    is $conf->{db}{user}, 'myuser', 'actually loaded some config';
    is_deeply \%effect, { config => 1, database => { myuser => 1 } },
        "config wasn't re-read";
};

subtest 'separate container' => sub {
    do {
        my $temp = (ref silo)->new;
        is ref $temp, 'My::Res', 'same package';
        my $dbh = $temp->dbh;
        is $dbh->id, 2, 'a different db connection id';
        is_deeply \%effect, { config => 2, database => { myuser => 2 } },
            "everything was re-instantiated";
    };
    is_deeply \%effect, { config => 2, database => { myuser => 1 } },
        "connection to db was closed";
};

for my $name( silo->ctl->meta->list ) {
    note "resource $name";
    note explain silo->ctl->meta->show($name);
};

done_testing;

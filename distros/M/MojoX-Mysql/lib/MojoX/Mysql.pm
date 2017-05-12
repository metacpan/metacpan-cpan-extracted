package MojoX::Mysql;
use Mojo::Base -base;
use List::Util qw(shuffle);
use Time::HiRes qw(sleep gettimeofday);
use Mojo::Util qw(dumper);
use DBI;
use Carp qw(croak);

our $VERSION  = '0.22';

use MojoX::Mysql::DB;
use MojoX::Mysql::Result;
use MojoX::Mysql::Util;

has [qw(async slave)];
has [qw(id)] => '_default';
has 'db'=> sub {
	my $self = shift;
	return MojoX::Mysql::DB->new(config=>$self->{'config'});
};

has 'result'=> sub {
	my $self = shift;
	return MojoX::Mysql::Result->new();
};

has 'util'=> sub {
	my $self = shift;
	return MojoX::Mysql::Util->new(config=>$self->{'config'});
};

sub new {
	my $class = shift;
	my %args  = @_;

	my %config = ();
	if(exists $args{'server'}){
		for my $server (@{$args{'server'}}){

			# Add the global login
			$server->{'user'} = $args{'user'} if(!exists $server->{'user'} && exists $args{'user'});

			# Add the global password
			$server->{'password'} = $args{'password'} if(!exists $server->{'password'} && exists $args{'password'});

			# Add the global write_timeout
			$server->{'write_timeout'} = $args{'write_timeout'} if(!exists $server->{'write_timeout'} && exists $args{'write_timeout'});

			# Add the global read_timeout
			$server->{'read_timeout'} = $args{'read_timeout'} if(!exists $server->{'read_timeout'} && exists $args{'read_timeout'});

			# Add the global read_timeout
			$server->{'read_timeout'} = $args{'read_timeout'} if(!exists $server->{'read_timeout'} && exists $args{'read_timeout'});

			# Add the global connect_timeout
			$server->{'connect_timeout'} = $args{'connect_timeout'} if(!exists $server->{'connect_timeout'} && exists $args{'connect_timeout'});


			$server->{'id'} = '_default'      if(!exists $server->{'id'});
			$server->{'type'} = 'slave'       if(!exists $server->{'type'});
			$server->{'weight'} = 1           if(!exists $server->{'weight'});
			$server->{'write_timeout'}   = 60 if(!exists $server->{'write_timeout'});
			$server->{'read_timeout'}    = 60 if(!exists $server->{'read_timeout'});
			$server->{'connect_timeout'} = 15 if(!exists $server->{'connect_timeout'});

			my $id = $server->{'id'};
			if($server->{'type'} eq 'slave'){
				for(1..$server->{'weight'}){
					push(@{$config{$id}}, $server);
				}
			}
			else{
				push(@{$config{$id}}, $server);
			}
		}
	}

	my %migration = ();
	my %fake = ();
	while(my($id,$data) = each(%config)){
		my @master = grep($_->{'type'} eq 'master', @{$data});
		my @slave = grep($_->{'type'} eq 'slave', @{$data});
		@slave = shuffle @slave;
		my $master = {};
		$master = $master[0] if(@master);
		$config{$id} = {master=>$master, slave=>\@slave};
		$migration{$id} = $master->{'migration'};
	}
	return $class->SUPER::new(config=>\%config, migration=>\%migration, app=>$args{'app'});
}

sub do {
	my ($self,$sql) = (shift,shift);
	my $id = $self->id;
	$self->flush;

	my $dbh = $self->db->id($id)->connect_master;
	warn "sql do $sql" if(defined $ENV{'MOJO_MYSQL_DEBUG'});

	my $counter = $dbh->do($sql,undef,@_) or die $dbh->errstr;
	my $insertid = int $dbh->{'mysql_insertid'};
	return wantarray ? ($insertid,$counter) : $insertid;
}

sub query {
	my ($self, $query) = (shift, shift);
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

	my $id    = $self->id;
	my $slave = $self->slave;
	my $async = $self->async;
	$self->flush;

	my $dbh;
	if(defined $async && defined $slave){
		$dbh = $self->db->id($id)->connect_slave;
		croak 'No connect server' if(ref $dbh ne 'DBI::db');
		$dbh = $dbh->clone;
	}
	elsif(defined $async){
		$dbh = $self->db->id($id)->connect_master;
		if(ref $dbh ne 'DBI::db'){
			$dbh = $self->db->id($id)->connect_slave;
		}
		croak 'No connect server' if(ref $dbh ne 'DBI::db');
		$dbh = $dbh->clone;
	}
	elsif(defined $slave){
		$dbh = $self->db->id($id)->connect_slave;
		croak 'No connect server' if(ref $dbh ne 'DBI::db');
	}
	else{
		$dbh = $self->db->id($id)->connect_master;
		if(ref $dbh ne 'DBI::db'){
			$dbh = $self->db->id($id)->connect_slave;
		}
		croak 'No connect server' if(ref $dbh ne 'DBI::db');
	}

	warn "sql query $query" if(defined $ENV{'MOJO_MYSQL_DEBUG'});

	if(defined $async){
		my $sth = $dbh->prepare($query, {async=>1}) or croak $dbh->errstr;
		$sth->execute(@_) or croak $dbh->errstr;
		return ($sth,$dbh);
	}
	else{
		my $sth = $dbh->prepare($query) or croak $dbh->errstr;
		my $counter = $sth->execute(@_) or croak $dbh->errstr;
		my $collection = $self->result->collection($sth,$cb);
		return wantarray ? ($collection,$counter,$sth,$dbh,$id) : $collection;
	}
}

sub flush {
	my $self = shift;
	$self->id('_default');
	$self->slave(undef);
	$self->async(undef);
}

1;

=encoding utf8

=head1 NAME

MojoX::Mysql - Mojolicious ♥ Mysql
 
=head1 SYNOPSIS

    use MojoX::Mysql;
    use Mojo::Util qw(dumper);

    my %config = (
        user=>'root',
        password=>undef,
        server=>[
            {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'master'},
            {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'slave'},
            {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'master'},
            {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'slave'},
            {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'master'},
            {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'slave'},
        ]
    );

    my $mysql = MojoX::Mysql->new(%config);

=head1 DESCRIPTION

MojoX::Mysql is a tiny wrapper around DBD::mysql that makes Mysql a lot of fun to use with the Mojolicious real-time web framework.

=head1 ATTRIBUTES

=head2 id

    $mysql->id(1); # choice id server

=head2 slave

    $mysql->slave(1); # query only slave server

=head2 async

    $mysql->async(1); # query async mode

=head1 METHODS

=head2 db

    $mysql->db;

Return L<MojoX::Mysql::DB> object.

=head2 do

    my ($insertid,$counter) = $mysql->do('INSERT INTO `names` (`id`,`name`) VALUES(1,?)', 'Lilu Kazerogova');

=head2 do (choice server)

    my ($insertid,$counter) = $mysql->id(1)->do('INSERT INTO `names` (`id`,`name`) VALUES(1,?)', 'Lilu Kazerogova');

=head2 query

    my $collection_object = $mysql->query('SELECT * FROM `names` WHERE id = ?', 1);

    # or

    my ($collection,$counter,$sth,$dbh) = $mysql->query('SELECT * FROM `names` WHERE id = ?', 1);

    # or callback

    $mysql->query('SELECT `text` FROM `test` WHERE `id` = ? LIMIT 1', $insertid, sub {
        my ($self,$data) = @_;
        say dumper $data;
    });

Return L<Mojo::Collection> object.

=head2 query (choice server)

    my $collection_object = $mysql->id(1)->query('SELECT * FROM `names` WHERE id = ?', 1);

    # or

    my ($collection,$counter,$sth,$dbh) = $mysql->id(1)->query('SELECT * FROM `names` WHERE id = ?', 1);

=head2 query (async)

    my ($sth1,$dbh1) = $mysql->id(1)->async(1)->query('SELECT SLEEP(?) as `sleep`', 1); # Automatically new connection
    my ($sth2,$dbh2) = $mysql->id(1)->async(1)->query('SELECT SLEEP(?) as `sleep`', 1); # Automatically new connection

    my $collection_object1 = $mysql->result->async($sth1,$dbh1); # Automatically executed methods finish, commit, disconnect
    my $collection_object2 = $mysql->result->async($sth2,$dbh2); # Automatically executed methods finish, commit, disconnect

    # Performed concurrently (1 seconds)

Return L<Mojo::Collection> object.

=head2 query (slave server)

    my $collection_object = $mysql->id(1)->slave(1)->query('SELECT * FROM `names` WHERE id = ?', 1);

    # or

    my ($collection,$counter,$sth,$dbh) = $mysql->id(1)->slave(1)->query('SELECT * FROM `names` WHERE id = ?', 1);

=head2 commit, rollback, disconnect

    $mysql->db->commit;
    $mysql->db->rollback;
    $mysql->db->disconnect;

=head2 quote

    $mysql->util->quote("test'test");

=head2 id

    $mysql->util->id;

Return id servers in L<Mojo::Collection> object.

=head1 Mojolicious Plugin

SEE ALSO L<Mojolicious::Plugin::Mysql>

=head1 AUTHOR

Kostya Ten, C<kostya@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Kostya Ten.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache License version 2.0.

=cut


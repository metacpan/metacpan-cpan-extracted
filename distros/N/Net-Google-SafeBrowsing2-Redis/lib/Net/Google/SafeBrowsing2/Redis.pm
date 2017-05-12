package Net::Google::SafeBrowsing2::Redis;

use strict;
use warnings;

use base 'Net::Google::SafeBrowsing2::Storage';


use Carp;
use Redis::hiredis;
use Net::Google::SafeBrowsing2;


our $VERSION = '0.7';


=head1 NAME

Net::Google::SafeBrowsing2::Redis - Redis as back-end storage for the Google Safe Browsing v2 database.

The source code is available on github at L<https://github.com/juliensobrier/Net-Google-SafeBrowsing2-Redis>.

=head1 SYNOPSIS

  use Net::Google::SafeBrowsing2::Redis;

  my $storage = Net::Google::SafeBrowsing2::Redis->new(host => '127.0.0.1', database => 1);
  ...

=head1 DESCRIPTION

This is an implementation of L<Net::Google::SafeBrowsing2::Storage> using Redis.

=cut


=head1 CONSTRUCTOR

=over 4

=head2 new()

Create a Net::Google::SafeBrowsing2::Redis object

  my $storage = Net::Google::SafeBrowsing2::Redis->new(
      host     => '127.0.0.1', 
      database => 0, 
  );

Arguments

=over 4

=item host

Optional. Redis host name. "127.0.01" by default

=item database

Optional. Redis database name to connect to. 0 by default.

=item port

Optional. Redis port number to connect to. 6379 by default.

=item backward_compatible

Optional. Stay backward compatible with 0.3, but requires a bigger Redis database. 0 (disabled) by default

=item keep_all

Optional. Keel all full hashes, even after they expire (45 minutes). 0 (disabled) by default

=back

=back

=cut

sub new {
	my ($class, %args) = @_;

	my $self = { # default arguments
		host		=> '127.0.0.1',
		database	=> 0,
		port		=> 6379,
		backward_compatible	=> 0,
		keep_all	=> 0,

		%args,
	};

	bless $self, $class or croak "Can't bless $class: $!";

    return $self;
}

=head1 PUBLIC FUNCTIONS

=over 4

See L<Net::Google::SafeBrowsing2::Storage> for the list of public functions.

=cut


sub redis {
	my ($self, %args) 	= @_;

	if (! exists ($self->{redis})) {
		my $redis = Redis::hiredis->new();
		$redis->connect( $self->{host}, $self->{port} );
		$redis->select( $self->{database} );
		$self->{redis} = $redis;
	}

	return $self->{redis};
}

my %mapping = (
	Net::Google::SafeBrowsing2::MALWARE 	=> 'm', 
	Net::Google::SafeBrowsing2::PHISHING 	=> 'p',

	'm'	=> Net::Google::SafeBrowsing2::MALWARE,
	'p'	=> Net::Google::SafeBrowsing2::PHISHING,
);

sub map {
	my ($self, $key) 	= @_;

	return $key if ($self->{backward_compatible});

	return $mapping{$key} || $key;
}


sub add_chunks {
	my ($self, %args) 	= @_;
	my $type			= $args{type}		|| 'a';
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

	$list = $self->map($list) unless ($self->{backward_compatible});

	if ($type eq 's') {
		$self->add_chunks_s(chunknum => $chunknum, chunks => $chunks, list => $list);
	}
	elsif ($type eq 'a') {
		$self->add_chunks_a(chunknum => $chunknum, chunks => $chunks, list => $list);
	}

	my $redis = $self->redis();

	my $key = $type . $list;
	$redis->zadd($key, $chunknum, $chunknum);

	if (scalar @$chunks == 0) { # keep empty chunks
		my $key = $type . $chunknum . $list;

		$redis->sadd($type . "l$chunknum$list", $key);
	}
}

sub add_chunks_a {
	my ($self, %args) 	= @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

	# list already mapped by add_chunks
	my $redis = $self->redis();

	foreach my $chunk (@$chunks) {
		my $key = "a$chunknum" . $chunk->{host} . $chunk->{prefix} . $list;
		$redis->hmset($key, "list", $list, "hostkey", $chunk->{host}, "prefix", $chunk->{prefix}, "chunknum", $chunknum);
		
		$redis->sadd("al$chunknum$list", $key);
		$redis->sadd("ah" . $chunk->{host}, $key);
	}
}

sub add_chunks_s {
	my ($self, %args) 	= @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

	# list already mapped by add_chunks
	my $redis = $self->redis();

	foreach my $chunk (@$chunks) {
		my $key = "s$chunknum" . $chunk->{host} . $chunk->{prefix} . $chunk->{add_chunknum} . $list;
		$redis->hmset($key, "list", $list, "hostkey", $chunk->{host}, "prefix", $chunk->{prefix}, "addchunknum", $chunk->{add_chunknum}, "chunknum", $chunknum);

		$redis->sadd("sl$chunknum$list", $key);
		$redis->sadd("sh" . $chunk->{host}, $key);
	}
}


# TODO: avoid duplicate code
sub get_add_chunks {
	my ($self, %args) 	= @_;
	my $hostkey			= $args{hostkey}	|| '';

	my @list = ();
	my $redis = $self->redis();

	my $keys = $redis->smembers("ah$hostkey");

	foreach my $key (@$keys) {
		if (! $redis->exists($key)) { # clean up
			$redis->srem("ah$hostkey", $key);
			next;
		}
		my $chunk = to_hash($redis->hgetall($key));
		$chunk->{list} = $self->map($chunk->{list}) unless ($self->{backward_compatible});
		push(@list, $chunk) if ($chunk->{hostkey} eq $hostkey);
	}

	return @list;
}

sub get_sub_chunks {
	my ($self, %args) = @_;
	my $hostkey			= $args{hostkey}	|| '';

	my @list = ();
	my $redis = $self->redis();
	my $keys = $redis->smembers("sh$hostkey");

	foreach my $key (@$keys) {
		if (! $redis->exists($key)) { # cleanup
			$redis->srem("sh$hostkey", $key);
			next;
		}

		my $chunk = to_hash($redis->hgetall($key));
		$chunk->{list} = $self->map($chunk->{list}) unless ($self->{backward_compatible});
		push(@list, $chunk) if ($chunk->{hostkey} eq $hostkey);
	}

	return @list;
}

sub get_add_chunks_nums {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}		|| '';

	# list already mapped by get_chunks_nums
	return $self->get_chunks_nums(type => 'a', list => $list);
}

sub get_sub_chunks_nums {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}		|| '';

	# list already mapped by get_chunks_nums
	return $self->get_chunks_nums(type => 's', list => $list);
}

sub get_chunks_nums {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}		|| '';
	my $type			= $args{type}		|| 'a';

	$list = $self->map($list) unless ($self->{backward_compatible});
	my $key = "$type$list";
	my $values = $self->redis()->zrangebyscore($key, "-inf", "+inf");
	return @$values;
}


sub delete_add_ckunks {
	my ($self, %args) 	= @_;
	my $chunknums		= $args{chunknums}	|| [];
	my $list		= $args{'list'}		|| '';

	$list = $self->map($list) unless ($self->{backward_compatible});
	my $redis = $self->redis();

	foreach my $num (@$chunknums) {
		my $list2 = "al$num$list";
		while ($redis->scard($list2) > 0) {
			my $key = $redis->spop($list2);

			my $host = $redis->hget($key, 'hostkey');
			# Remove key from this list
			$redis->srem("ah$host", $key);
			if ($redis->scard("ah$host") == 0) {
				$redis->del("ah$host");
			}

			$redis->del($key);
		}
		$redis->del($list); # list is empty now

		$redis->zrem("a$list", $num);

		# empty chunks
		$redis->del("a$num" . $list);
	}
}


sub delete_sub_ckunks {
	my ($self, %args) 	= @_;
	my $chunknums		= $args{chunknums}	|| [];
	my $list		= $args{'list'}		|| '';

	$list = $self->map($list) unless ($self->{backward_compatible});
	my $redis = $self->redis();

	foreach my $num (@$chunknums) {
		my $list2 = "sl$num$list";
		while ($redis->scard($list2) > 0) {
			my $key = $redis->spop($list2);

			my $host = $redis->hget($key, 'hostkey');
			# Remove key from this list
			$redis->srem("sh$host", $key);
			if ($redis->scard("sh$host") == 0) {
				$redis->del("sh$host");
			}

			$redis->del($key);
		}
		$redis->del($list); # list is empty now

		$redis->zrem("s$list", $num);

		# empty chunks
		$redis->del("s$num" . $list);
	}
}

sub get_full_hashes {
	my ($self, %args) = @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $timestamp		= $args{timestamp}	|| 0;
	my $list			= $args{list}		|| '';

	$list = $self->map($list) unless ($self->{backward_compatible});
	my @hashes = ();
	my $redis = $self->redis();

	my $keys = $redis->keys("h$chunknum*$list");
	foreach my $key (@$keys) {
		my $chunk = to_hash($redis->hgetall($key));
		push(@hashes, $chunk->{hash}) if ($chunk->{chunknum} == $chunknum 
			&& exists($chunk->{timestamp}) && exists($chunk->{hash})
			&& $chunk->{timestamp} >= $timestamp);
	}

	return @hashes;
}

sub updated {
	my ($self, %args) 	= @_;
	my $time			= $args{'time'}	|| time();
	my $wait			= $args{'wait'}	|| 1800;
	my $list			= $args{'list'}	|| '';

	$list = $self->map($list) unless ($self->{backward_compatible});
	$self->redis()->hmset($list, "time", $time, "errors", 0, "wait", $wait);
}

sub update_error {
	my ($self, %args) 	= @_;
	my $time			= $args{'time'}	|| time();
	my $list			= $args{'list'}	|| '';
	my $wait			= $args{'wait'}	|| 60;
	my $errors			= $args{errors}	|| 1;

	$list = $self->map($list) unless ($self->{backward_compatible});
	$self->redis()->hmset($list, "time", $time, "errors", $errors, "wait", $wait);
}

sub last_update {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}	|| '';

	$list = $self->map($list) unless ($self->{backward_compatible});
	my $keys = $self->redis()->keys($list);
	if (scalar @$keys > 0) {
		return to_hash($self->redis()->hgetall($keys->[0]));
	}
	else { 
		return {'time' => 0, 'wait' => 0, errors => 0};
	}
}

sub add_full_hashes {
	my ($self, %args) 	= @_;
	my $timestamp		= $args{timestamp}		|| time();
	my $full_hashes		= $args{full_hashes}	|| [];

	my $redis = $self->redis();

	foreach my $hash (@$full_hashes) {
		my $key = "h" . $hash->{chunknum} . $hash->{hash} . $self->map( $hash->{list} );
		$redis->hmset($key, "chunknum",  $hash->{chunknum}, "hash",  $hash->{hash}, "timestamp", $timestamp);
		$redis->expire($key, 45 * 60) unless ($self->{keep_all});
	}
}


sub delete_full_hashes {
	my ($self, %args) 	= @_;
	my $chunknums		= $args{chunknums}	|| [];
	my $list			= $args{list}		|| croak "Missing list name\n";

	$list = $self->map($list) unless ($self->{backward_compatible});
	my $redis = $self->redis();

	my @keys = $redis->keys("h*$list");
	foreach my $key (@keys) {
		foreach my $num (@$chunknums) {
			$redis->del($key) if ($key =~ /^h$num/);
		}
	}
}


sub full_hash_error {
	my ($self, %args) 	= @_;
	my $timestamp		= $args{timestamp}	|| time();
	my $prefix			= $args{prefix}		|| '';

	my $key = "eh$prefix";

	my $keys = $self->redis()->keys($key);
	if (scalar(@$keys) == 0) {
			$self->redis()->hmset($key, "prefix", $prefix, "errors", 0, "timestamp", $timestamp);
	}
	else {
		$self->redis()->hincrby($key, "errors", 1);
		$self->redis()->hset($key, "timestamp", $timestamp);
	}
}

sub full_hash_ok {
	my ($self, %args) 	= @_;
	my $timestamp		= $args{timestamp}	|| time();
	my $prefix			= $args{prefix}		|| '';

	$self->redis()->del("eh$prefix");
}

sub get_full_hash_error {
	my ($self, %args) 	= @_;
	my $prefix			= $args{prefix}		|| '';

	my $key = "eh$prefix";
	my $keys = $self->redis()->keys($key);

	if (scalar(@$keys) > 0 ) {
		return to_hash( $self->redis()->hgetall($key) );
	}
	else {
		# no error
		return undef;
	}
}

# TODO: init() to set empty mac keys
sub get_mac_keys {
	my ($self, %args) 	= @_;

	if (scalar($self->redis()->keys("mac")) == 0) {
		return { client_key => '', wrapped_key => '' };
	}
	else {
		return to_hash($self->redis()->hgetall("mac"));
	}
}

sub add_mac_keys {
	my ($self, %args) 	= @_;
	my $client_key		= $args{client_key}		|| '';
	my $wrapped_key		= $args{wrapped_key}	|| '';

	$self->redis()->hmset("mac", "client_key", $client_key, "wrapped_key", $wrapped_key);
}

sub delete_mac_keys {
	my ($self, %args) 	= @_;

	$self->redis()->hmset("mac", "client_key", '', "wrapped_key", '');
}


sub reset {
	my ($self, %args) 	= @_;

	$self->redis()->flushdb();
}

sub close {
	my ($self, %args) 	= @_;
}


sub to_hash {
	my ($data) = @_;

	my $result = { };

	my @elements = @$data;
	while(my ($key, $value) = splice(@elements,0,2)) {
		$result->{$key} = $value
	}

	return $result;
}

=back

=head1 BENCHMARK

=over 4

Here are some numbers comparing the MySQL 0.6 back-end and Redis 0.4 back-end:

Database update, from empty to full update:
MySQL: 1330s
Redis 2.4: 351s

10,000 URLs lookup
MySQL: 6s
Redis 2.4: 5s

Storage:
MySQL: 154MB
Redis 2.4: 780MB

=back


=head1 CHANGELOG

=over 4

=item 0.7

FIX: chunks were not deleted correctly.

=item 0.6

FIX: some keys were never deleted from Redis.

=item 0.4

New options backward_compatible and keep_all.

Save 140MB in Redis (as of 08/01/2012)

=item 0.3

Break backward compatibility with previous versions. Make sure you start from a fresh database (reset your existing database if needed).

Improve performances, fixes lookup. Requires 920MB for a full database (as of 07/31/2012)

=back

=head1 SEE ALSO

See L<Net::Google::SafeBrowsing2> for handling Google Safe Browsing v2.

See L<Net::Google::SafeBrowsing2::Storage> for the list of public functions.

See L<Net::Google::SafeBrowsing2::Sqlite> for a back-end using Sqlite.

Google Safe Browsing v2 API: L<http://code.google.com/apis/safebrowsing/developers_guide_v2.html>


=head1 AUTHOR

Julien Sobrier, E<lt>jsobrier@zscaler.comE<gt> or E<lt>julien@sobrier.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Julien Sobrier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
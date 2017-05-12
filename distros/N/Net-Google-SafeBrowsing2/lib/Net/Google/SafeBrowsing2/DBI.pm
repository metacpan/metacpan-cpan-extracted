package Net::Google::SafeBrowsing2::DBI;

use strict;
use warnings;

use base 'Net::Google::SafeBrowsing2::Storage';

use Carp;
use DBI;
use List::Util qw(first);


our $VERSION = '1.01';


=head1 NAME

Net::Google::SafeBrowsing2::DBI - Base class for all DBI-based back-end storage for the Google Safe Browsing v2 database

=head1 SYNOPSIS

Net::Google::SafeBrowsing2::DBI cannot be used directly. Instead, use a class inheriting Net::Google::SafeBrowsing2::DBI, like L<Net::Google::SafeBrowsing2::MySQL>.


  use Net::Google::SafeBrowsing2::MySQL;

  my $storage = Net::Google::SafeBrowsing2::MySQL->new(host => '127.0.0.1', database => 'GoogleSafeBrowsingv2');
  ...
  $storage->close();

=head1 DESCRIPTION

This is a base implementation of L<Net::Google::SafeBrowsing2::Storage> using DBI.

=cut


=head1 CONSTRUCTOR

=over 4

=back

=head2 new()

This method should be overwritten.

Arguments

=over 4

=item keep_all

Optional. Set to 1 to keep old information (such as expiring full hashes) in the database. 0 (delete) by default.


=back

=cut

sub new {
	my ($class, %args) = @_;

	my $self = { # default arguments
		keep_all	=> 0,
		%args,
	};

	bless $self, $class or croak "Can't bless $class: $!";


	$self->init();

    return $self;
}

=head1 PUBLIC FUNCTIONS

=over 4

See L<Net::Google::SafeBrowsing2::Storage> for a complete list of public functions.

=back

=head2 close()

Cleanup old full hashes, and close the connection to the database.

  $storage->close();


=cut

sub close {
	my ($self, %args) = @_;


	if ($self->{keep_all} == 0) {
		$self->{dbh}->do('DELETE FROM full_hashes WHERE timestamp < ?', { }, time() - Net::Google::SafeBrowsing2::FULL_HASH_TIME);
	}

	$self->{dbh}->disconnect;
}


=head2 export()

Export add chunks and sub chunks to a file. The file content looks like what Google sends in redirections. The file can be used with the C<import_chunks> function from C<Net::Google::SafeBrowsing2>. This is useful when moving from one back-end storage to another

  $storage->export(list => MALWARE);

Arguments

=over 4

=item list

Required. The Google Safe Browsing list to export.

=item file

Optional. Filename to export to. Uses "$list.dat" by default.

=back

=cut

sub export {
	my ($self, %args) 	= @_;
	my $list			= $args{list}	|| '';
	my $file			= $args{file}	|| "$list.dat";


	open EXPORT, "> $file" or croak "Cannot open $file: $!\n";
	binmode EXPORT;

	# Add chunks
	my $num = 0;
	my $chunk_data = '';
	my $hostkey = '';
	my $prefixes = '';
	my $count = 0;

	my $sth = $self->{dbh}->prepare("SELECT * FROM a_chunks WHERE list = ? ORDER BY num ASC");
	$sth->execute($list);

	while (my $row = $sth->fetchrow_hashref()) {
		if (($num != $row->{num} && $num != 0) || $num > 1000) { # if num is too bif, we can not print chr($num) a a single byte
			$chunk_data .= $hostkey;
			$chunk_data .= chr($count);
			$chunk_data .= $prefixes;
			
			print EXPORT "a:", $num, ":", length($hostkey), ":", length($chunk_data), "\n";
			print EXPORT $chunk_data;

			$num = $row->{num};
			$chunk_data = '';
			$hostkey = '';
			$prefixes = '';
			$count = 0;
		}
		elsif ($num == 0) {
			$num = $row->{num};
			$hostkey = $row->{hostkey};
		}
		if ($hostkey ne $row->{hostkey} && $hostkey ne '') {
			$chunk_data .= $hostkey;
			$chunk_data .= chr($count);
			$chunk_data .= $prefixes;
		
			$count = 0;
			$prefixes = '';
		}
		$hostkey = $row->{hostkey};
		if (length($row->{prefix}) > 0) {
			$prefixes .= $row->{prefix};
			$count++;
		}
	}
	$sth->finish();

	$chunk_data .= $hostkey;
	$chunk_data .= chr($count);
	$chunk_data .= $prefixes;
	print EXPORT "a:", $num, ":", length($hostkey), ":", length($chunk_data) , "\n";
	print EXPORT $chunk_data;


	# sub chunks
	$num = 0;
	$chunk_data = '';
	$hostkey = '';
	$prefixes = '';
	$count = 0;

	$sth = $self->{dbh}->prepare("SELECT * FROM s_chunks WHERE list = ? ORDER BY num ASC");
	$sth->execute($list);


	while (my $row = $sth->fetchrow_hashref()) {
		if (($num != $row->{num} && $num != 0) || $num > 1000) { # if num is too bif, we can not print chr($num) a a single byte
			$chunk_data .= $hostkey;
			$chunk_data .= chr($count) if (length($hostkey) > 0);
			$chunk_data .= $prefixes;
			
			print EXPORT "s:", $num, ":", length($hostkey), ":", length($chunk_data), "\n";
			print EXPORT $chunk_data;

			$num = $row->{num};
			$chunk_data = '';
			$hostkey = '';
			$prefixes = '';
			$count = 0;
		}
		elsif ($num == 0) {
			$num = $row->{num};
			$hostkey = $row->{hostkey};
		}
		if ($hostkey ne $row->{hostkey} && $hostkey ne '') {
			$chunk_data .= $hostkey;
			$chunk_data .= chr($count) if (length($hostkey) > 0);
			$chunk_data .= $prefixes;
		
			$count = 0;
			$prefixes = '';
		}
		$hostkey = $row->{hostkey};
		if ($row->{add_num} > 0) {
			$prefixes .= $self->ascii_to_hex( sprintf("%08x", $row->{add_num}) );
		}

		if (length($row->{prefix}) > 0 && $row->{add_num} > 0) {
			$prefixes .= $row->{prefix};
			$count++;
		}
	}
	$sth->finish();

	$chunk_data .= $hostkey;
	$chunk_data .= chr($count) if (length($hostkey) > 0);
	$chunk_data .= $prefixes;
	print EXPORT "s:", $num, ":", length($hostkey), ":", length($chunk_data) , "\n";
	print EXPORT $chunk_data;

	CORE::close(EXPORT);
}

sub init {
	my ($self, %args) = @_;

	# Should connect to database
	# Should check if all tables exist
}


sub create_table_updates {
	my ($self, %args) = @_;

	my $schema = qq{	
		CREATE TABLE updates (
			last INT NOT NULL DEFAULT '0',
			wait INT NOT NULL DEFAULT '0',
			errors INT NOT NULL DEFAULT '1800',
			list VARCHAR( 50 ) NOT NULL
		);
	}; # Need to handle errors

	$self->{dbh}->do($schema);
}

sub create_table_a_chunks {
	my ($self, %args) = @_;

	my $schema = qq{
		CREATE TABLE a_chunks (
			hostkey VARCHAR( 8 ),
			prefix VARCHAR( 8 ),
			num INT NOT NULL,
			list VARCHAR( 50 ) NOT NULL
		);
	};

	$self->{dbh}->do($schema);

	my $index = qq{
		CREATE INDEX a_chunks_hostkey ON a_chunks (
			hostkey
		);
	};
	$self->{dbh}->do($index);

	$index = qq{
		CREATE INDEX a_chunks_num_list ON a_chunks (
			num,
			list
		);
	};
	$self->{dbh}->do($index);

	$index = qq{
		CREATE UNIQUE INDEX a_chunks_unique ON a_chunks (
			hostkey,
			prefix,
			num,
			list
		);
	};
	$self->{dbh}->do($index);
}

sub create_table_s_chunks {
	my ($self, %args) = @_;

	my $schema = qq{
		CREATE TABLE s_chunks (
			hostkey VARCHAR( 8 ),
			prefix VARCHAR( 8 ),
			num INT NOT NULL,
			add_num INT  Default '0',
			list VARCHAR( 50 ) NOT NULL
		);
	};

	$self->{dbh}->do($schema);

	my $index = qq{
		CREATE INDEX s_chunks_hostkey ON s_chunks (
			hostkey
		);
	};
	$self->{dbh}->do($index);

	$index = qq{
		CREATE INDEX s_chunks_num ON s_chunks (
			num
		);
	};
	$self->{dbh}->do($index);

	$index = qq{
		CREATE INDEX s_chunks_num_list ON s_chunks (
			num,
			list
		);
	};
	$self->{dbh}->do($index);

	$index = qq{
		CREATE UNIQUE INDEX s_chunks_unique ON s_chunks (
			hostkey,
			prefix,
			num,
			add_num,
			list
		);
	};
	$self->{dbh}->do($index);
}

sub create_table_full_hashes {
	my ($self, %args) = @_;

	my $schema = qq{
		CREATE TABLE full_hashes (
			id INT AUTO_INCREMENT PRIMARY KEY,
			num INT,
			hash VARCHAR( 32 ),
			list VARCHAR( 50 ),
			timestamp INT Default '0'
		);
	};

	$self->{dbh}->do($schema);

	my $index = qq{
		CREATE UNIQUE INDEX hash ON full_hashes (
			num,
			hash,
			list
		);
	};
	$self->{dbh}->do($index);
}

sub create_table_full_hashes_errors {
	my ($self, %args) = @_;

	my $schema = qq{
		CREATE TABLE full_hashes_errors (
			id INT AUTO_INCREMENT PRIMARY KEY,
			errors INT Default '0',
			prefix VARCHAR( 8 ),
			timestamp INT Default '0'
		);
	};

	$self->{dbh}->do($schema);
}

sub create_table_mac_keys{
	my ($self, %args) = @_;

	my $schema = qq{
		CREATE TABLE mac_keys (
			client_key VARCHAR( 50 ) Default '',
			wrapped_key VARCHAR( 50 ) Default ''
		);
	};

	$self->{dbh}->do($schema);
}


sub add_chunks {
	my ($self, %args) 	= @_;
	my $type			= $args{type}		|| 'a';
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

# 	$self->{dbh}->do("PRAGMA journal_mode = OFF");
# 	$self->{dbh}->do("PRAGMA synchronous = OFF"); 

	if ($type eq 's') {
		$self->add_chunks_s(chunknum => $chunknum, chunks => $chunks, list => $list);
	}
	elsif ($type eq 'a') {
		$self->add_chunks_a(chunknum => $chunknum, chunks => $chunks, list => $list);
	}

# 	$self->{dbh}->do("PRAGMA journal_mode = DELETE");
# 	$self->{dbh}->do("PRAGMA synchronous = FULL"); 
}

sub add_chunks_s {
	my ($self, %args) 	= @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

	my $add = $self->{dbh}->prepare('INSERT INTO s_chunks (hostkey, prefix, num, add_num, list) VALUES (?, ?, ?, ?, ?)');
	my $del = $self->{dbh}->prepare('DELETE FROM s_chunks WHERE hostkey = ? AND prefix = ? AND num = ? AND add_num = ? AND list = ?');

	foreach my $chunk (@$chunks) {
		$del->execute( $chunk->{host}, $chunk->{prefix}, $chunknum, $chunk->{add_chunknum}, $list );
		$add->execute( $chunk->{host}, $chunk->{prefix}, $chunknum, $chunk->{add_chunknum}, $list );
	}

	if (scalar @$chunks == 0) { # keep empty chunks
		$del->execute( '', '', $chunknum, '', $list );
		$add->execute( '', '', $chunknum, '', $list );
	}
}

sub add_chunks_a {
	my ($self, %args) 	= @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

	my $add = $self->{dbh}->prepare('INSERT INTO a_chunks (hostkey, prefix, num, list) VALUES (?, ?, ?, ?)');
	my $del = $self->{dbh}->prepare('DELETE FROM a_chunks WHERE hostkey = ? AND  prefix  = ? AND num = ? AND  list  = ?');

	foreach my $chunk (@$chunks) {
		$del->execute( $chunk->{host}, $chunk->{prefix}, $chunknum, $list );
		$add->execute( $chunk->{host}, $chunk->{prefix}, $chunknum, $list );
	}

	if (scalar @$chunks == 0) { # keep empty chunks
		$del->execute( '', '', $chunknum, $list );
		$add->execute( '', '', $chunknum, $list );
	}
}


sub get_add_chunks {
	my ($self, %args) = @_;
	my $hostkey			= $args{hostkey}	|| '';
# 	my $list			= $args{'list'}		|| '';

	my @list = ();
# 	my $rows = $self->{dbh}->selectall_arrayref("SELECT * FROM a_chunks WHERE hostkey = ? AND list = ?", { Slice => {} }, $hostkey, $list);
	my $rows = $self->{dbh}->selectall_arrayref("SELECT * FROM a_chunks WHERE hostkey = ?", { Slice => {} }, $hostkey);

	foreach my $row (@$rows) {
		push(@list, { chunknum => $row->{num}, prefix => $row->{prefix}, list => $row->{list}, hostkey => $hostkey });
	}

	return @list;
}

sub get_sub_chunks {
	my ($self, %args) = @_;
	my $hostkey			= $args{hostkey}	|| '';
# 	my $list			= $args{'list'}		|| '';

	my @list = ();
# 	my $rows = $self->{dbh}->selectall_arrayref("SELECT * FROM s_chunks WHERE hostkey = ? AND list = ?", { Slice => {} }, $hostkey, $list);
	my $rows = $self->{dbh}->selectall_arrayref("SELECT * FROM s_chunks WHERE hostkey = ?", { Slice => {} }, $hostkey);

	foreach my $row (@$rows) {
		push(@list, { chunknum => $row->{num}, prefix => $row->{prefix}, addchunknum => $row->{add_num}, list => $row->{list}  });
	}

	return @list;
}

sub get_add_chunks_nums {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}		|| '';
	
	my @list = ();
	my $rows = $self->{dbh}->selectall_arrayref("SELECT DISTINCT(num) FROM a_chunks WHERE list = ? ORDER BY num ASC", { Slice => {} }, $list);
	foreach my $row (@$rows) {
		push(@list, $row->{num});
	}

	return @list;
}

sub get_sub_chunks_nums {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}		|| '';
	
	my @list = ();
	my $rows = $self->{dbh}->selectall_arrayref("SELECT DISTINCT(num) FROM s_chunks WHERE list = ? ORDER BY num ASC", { Slice => {} }, $list);
	foreach my $row (@$rows) {
		push(@list, $row->{num});
	}

	return @list;
}


sub delete_add_ckunks {
	my ($self, %args) 	= @_;
	my $chunknums		= $args{chunknums}	|| [];
	my $list			= $args{'list'}		|| '';

	my $sth = $self->{dbh}->prepare("DELETE FROM a_chunks WHERE num = ? AND list = ?");

	foreach my $num (@$chunknums) {
		$sth->execute($num, $list);
	}
}


sub delete_sub_ckunks {
	my ($self, %args) = @_;
	my $chunknums		= $args{chunknums}	|| [];
	my $list			= $args{'list'}		|| '';

	my $sth = $self->{dbh}->prepare("DELETE FROM s_chunks WHERE num = ? AND list = ?");

	foreach my $num (@$chunknums) {
		$sth->execute($num, $list);
	}


}

sub get_full_hashes {
	my ($self, %args) = @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $timestamp		= $args{timestamp}	|| 0;
	my $list			= $args{list}		|| '';

	my @hashes = ();

	my $rows = $self->{dbh}->selectall_arrayref("SELECT hash FROM full_hashes WHERE timestamp >= ? AND num = ? AND list = ?", { Slice => {} }, $timestamp, $chunknum, $list);
	foreach my $row (@$rows) {
		push(@hashes, $row->{hash});
	}

	return @hashes;
}


sub updated {
	my ($self, %args) 	= @_;
	my $time			= $args{'time'}	|| time;
	my $wait			= $args{'wait'}	|| 1800;
	my $list			= $args{'list'}	|| '';

	if ($self->last_update(list => $list)->{'time'} == 0) {
		$self->{dbh}->do("INSERT INTO updates (last, wait, errors, list) VALUES (?, ?, 0, ?)", undef, $time, $wait, $list);
	}
	else {
		$self->{dbh}->do("UPDATE updates SET last = ?, wait = ?, errors = 0 WHERE list = ?", undef, $time, $wait, $list);
	}
}

sub update_error {
	my ($self, %args) 	= @_;
	my $time			= $args{'time'}	|| time;
	my $list			= $args{'list'}	|| '';
	my $wait			= $args{'wait'}	|| 60;
	my $errors			= $args{errors}	|| 1;

	if ($self->last_update(list => $list)->{'time'} == 0) {
		$self->{dbh}->do("INSERT INTO updates (last, wait, errors, list) VALUES (?, ?, ?, ?)", undef, $time, $wait, $errors, $list);
	}
	else {
		$self->{dbh}->do("UPDATE updates SET last = ?, wait = ?, errors = ?, list = ? WHERE 1", undef, $time, $wait, $errors, $list);
	}
}

sub last_update {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}	|| '';

	my $rows = $self->{dbh}->selectall_arrayref("SELECT last, wait, errors FROM updates WHERE list = ? LIMIT 1", { Slice => {} }, $list);

	foreach my $row (@$rows) {
		return {'time' => $row->{'last'} || 0, 'wait' => $row->{'wait'} || 1800, errors	=> $row->{'errors'} || 0};
	}

	return {'time' => 0, 'wait' => 1800};
}

sub add_full_hashes {
	my ($self, %args) 	= @_;
	my $timestamp		= $args{timestamp}		|| time();
	my $full_hashes		= $args{full_hashes}	|| [];

	foreach my $hash (@$full_hashes) {
# 		$self->{dbh}->do("INSERT OR REPLACE INTO full_hashes (num, hash, list, timestamp) VALUES (?, ?, ?, ?)", { }, $hash->{chunknum}, $hash->{hash}, $hash->{list}, $timestamp);
		$self->{dbh}->do("DELETE FROM full_hashes WHERE num = ? AND hash = ? AND list = ?", { }, $hash->{chunknum}, $hash->{hash}, $hash->{list});
		$self->{dbh}->do("INSERT INTO full_hashes (num, hash, list, timestamp) VALUES (?, ?, ?, ?)", { }, $hash->{chunknum}, $hash->{hash}, $hash->{list}, $timestamp);
	}
}

sub delete_full_hashes {
	my ($self, %args) 	= @_;
	my $chunknums		= $args{chunknums}	|| [];
	my $list			= $args{list}		|| croak "Missing list name\n";

	my $sth = $self->{dbh}->prepare("DELETE FROM full_hashes WHERE num = ? AND list = ?");

	foreach my $num (@$chunknums) {
		$sth->execute($num, $list);
	}
}

sub full_hash_error {
	my ($self, %args) 	= @_;
	my $timestamp		= $args{timestamp}	|| time();
	my $prefix			= $args{prefix}		|| '';

	my $rows = $self->{dbh}->selectall_arrayref("SELECT id, errors FROM full_hashes_errors WHERE prefix = ? LIMIT 1", { Slice => {} }, $prefix);

	if (scalar @$rows == 0) {
		$self->{dbh}->do("INSERT INTO full_hashes_errors (prefix, errors, timestamp) VALUES (?, 1, ?)", { }, $prefix, $timestamp);
	}
	else {
		my $errors = $rows->[0]->{errors} + 1;
		$self->{dbh}->do("UPDATE full_hashes_errors SET errors = ?, timestamp = ? WHERE id = ?", $errors, $timestamp, $rows->[0]->{id});
	}
}

sub full_hash_ok {
	my ($self, %args) 	= @_;
	my $timestamp		= $args{timestamp}	|| time();
	my $prefix			= $args{prefix}		|| '';

	my $rows = $self->{dbh}->selectall_arrayref("SELECT id, errors FROM full_hashes_errors WHERE prefix = ? AND errors > 0 LIMIT 1", { Slice => {} }, $prefix);

	if (scalar @$rows > 0) {
		$self->{dbh}->do("UPDATE full_hashes_errors SET errors = 0, timestamp = ? WHERE id = ?", $timestamp, $rows->[0]->{id});
		$self->{dbh}->do("DELETE FROM full_hashes_errors WHERE id = ?", $rows->[0]->{id});
	}
}

sub get_full_hash_error {
	my ($self, %args) 	= @_;
	my $prefix			= $args{prefix}		|| '';

	my $rows = $self->{dbh}->selectall_arrayref("SELECT timestamp, errors FROM full_hashes_errors WHERE prefix = ? LIMIT 1", { Slice => {} }, $prefix);
	
	if (scalar @$rows == 0) {
		return undef;
	}
	else {
		return $rows->[0];
	}
}

sub get_mac_keys {
	my ($self, %args) 	= @_;


	my $rows = $self->{dbh}->selectall_arrayref("SELECT client_key, wrapped_key FROM mac_keys LIMIT 1", { Slice => {} });

	if (scalar @$rows == 0) {
		return { client_key => '', wrapped_key => '' };
	}
	else {
		return $rows->[0];
	}
}

sub add_mac_keys {
	my ($self, %args) 	= @_;
	my $client_key		= $args{client_key}		|| '';
	my $wrapped_key		= $args{wrapped_key}	|| '';


	$self->delete_mac_keys();

	$self->{dbh}->do("INSERT INTO mac_keys (client_key, wrapped_key) VALUES (?, ?)", { }, $client_key, $wrapped_key);

}

sub delete_mac_keys {
	my ($self, %args) 	= @_;

	$self->{dbh}->do("DELETE FROM mac_keys WHERE 1");
}

sub reset {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}		|| '';

	my $sth = $self->{dbh}->prepare('DELETE FROM s_chunks WHERE list = ?');
	$sth->execute( $list );

	$sth = $self->{dbh}->prepare('DELETE FROM a_chunks WHERE list = ?');
	$sth->execute( $list );

	$sth = $self->{dbh}->prepare('DELETE FROM full_hashes WHERE list = ?');
	$sth->execute( $list );

	$sth = $self->{dbh}->prepare('DELETE FROM full_hashes_errors');
	$sth->execute();

	$sth = $self->{dbh}->prepare('DELETE FROM updates WHERE list = ?');
	$sth->execute( $list );
}

sub create_range {
	my ($self, %args) 	= @_;
	my $numbers			= $args{numbers}	|| []; # should already be ordered

	return '' if (scalar @$numbers == 0);

	my $range = $$numbers[0];
	my $new_range = 0;
	for(my $i = 1; $i < scalar @$numbers; $i++) {
# 		next if ($$numbers[$i] == $$numbers[$i-1]); # should not happen

		if ($$numbers[$i] != $$numbers[$i-1] + 1) {
			$range .= $$numbers[$i-1] if ($i > 1 && $new_range == 1);
			$range .= ',' . $$numbers[$i];

			$new_range = 0
		}
		elsif ($new_range == 0) {
			$range .= "-";
			$new_range = 1;
		}
	}
	$range .= $$numbers[scalar @$numbers - 1] if ($new_range == 1);

	return $range;
}

=head1 CHANGELOG

=over 4

=item 0.7.1

Fix for empty sub chunks.

=item 0.7

New C<export()> function.

Keep empty sub chunks.

Fix index for sub chunks.

=item 0.6

Add option keep_all to keep expired full hashes. Useful for debugging.

=item 0.5

Return the hostkey in get_add_chunks.

=item 0.4

Fix duplicate insert of add chunks and sub chunks.

=item 0.3

Add reset function to reset all tables for a given list

=item 0.2

Replace "INSERT OR REPLACE" statements by DELETE + INSERT to work with all databases

=back

=head1 SEE ALSO

See L<Net::Google::SafeBrowsing2> for handling Google Safe Browsing v2.

See L<Net::Google::SafeBrowsing2::Storage> for the list of public functions.

See L<Net::Google::SafeBrowsing2::Sqlite> for a back-end using Sqlite.

Google Safe Browsing v2 API: L<http://code.google.com/apis/safebrowsing/developers_guide_v2.html>


=head1 AUTHOR

Julien Sobrier, E<lt>jsobrier@zscaler.comE<gt> or E<lt>julien@sobrier.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julien Sobrier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;

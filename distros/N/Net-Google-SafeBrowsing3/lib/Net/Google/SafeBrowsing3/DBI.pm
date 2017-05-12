package Net::Google::SafeBrowsing3::DBI;

use strict;
use warnings;

use base 'Net::Google::SafeBrowsing3::Storage';

use Carp;
use DBI;
use List::Util qw(first);


our $VERSION = '0.3';


=head1 NAME

Net::Google::SafeBrowsing3::DBI - Base class for all DBI-based back-end storage for the Google Safe Browsing v3 database

=head1 SYNOPSIS

Net::Google::SafeBrowsing3::DBI cannot be used directly. Instead, use a class inheriting Net::Google::SafeBrowsing3::DBI, like L<Net::Google::SafeBrowsing3::MySQL>.


  use Net::Google::SafeBrowsing3::MySQL;

  my $storage = Net::Google::SafeBrowsing3::MySQL->new(host => '127.0.0.1', database => 'GoogleSafeBrowsingv3');
  ...
  $storage->close();

=head1 DESCRIPTION

This is a base implementation of L<Net::Google::SafeBrowsing3::Storage> using DBI.

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
		debug			=> 0,
		keep_all	=> 0,
		%args,
	};

	bless $self, $class or croak "Can't bless $class: $!";


	$self->init();

    return $self;
}

=head1 PUBLIC FUNCTIONS

=over 4

See L<Net::Google::SafeBrowsing3::Storage> for a complete list of public functions.

=back

=head2 close()

Cleanup old full hashes, and close the connection to the database.

  $storage->close();


=cut

sub close {
	my ($self, %args) = @_;

	if ($self->{keep_all} == 0) {
		$self->{dbh}->do('DELETE FROM full_hashes WHERE `end` < ?', { }, time());
	}

	$self->{dbh}->disconnect;
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

	my $index = qq{
		CREATE UNIQUE INDEX list_unique ON updates (list);
	};
	$self->{dbh}->do($index);
}

sub create_table_a_chunks {
	my ($self, %args) = @_;

	my $schema = qq{
		CREATE TABLE a_chunks (
			hostkey VARCHAR( 8 ),
			prefix VARCHAR( 32 ),
			num INT NOT NULL,
			list VARCHAR( 25 ) NOT NULL
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
			prefix VARCHAR( 32 ),
			num INT NOT NULL,
			add_num INT  Default '0',
			list VARCHAR( 25 ) NOT NULL
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
			list VARCHAR( 25 ),
			end INT Default '0',
			type INT Default '0'
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
			prefix VARCHAR( 32 ),
			timestamp INT Default '0'
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

	my $add = $self->{dbh}->prepare('INSERT INTO s_chunks (prefix, num, add_num, list) VALUES (?, ?, ?, ?)');
	my $del = $self->{dbh}->prepare('DELETE FROM s_chunks WHERE prefix = ? AND num = ? AND add_num = ? AND list = ?');

	foreach my $chunk (@$chunks) {
		$del->execute( $chunk->{prefix}, $chunknum, $chunk->{add_chunknum}, $list );
		$add->execute( $chunk->{prefix}, $chunknum, $chunk->{add_chunknum}, $list );
	}

	if (scalar @$chunks == 0) { # keep empty chunks
		$del->execute( '', $chunknum, '', $list );
		$add->execute( '', $chunknum, '', $list );
	}
}

sub add_chunks_a {
	my ($self, %args) 	= @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

	my $add = $self->{dbh}->prepare('INSERT INTO a_chunks (prefix, num, list) VALUES (?, ?, ?, ?)');
	my $del = $self->{dbh}->prepare('DELETE FROM a_chunks WHERE prefix  = ? AND num = ? AND  list  = ?');

	foreach my $chunk (@$chunks) {
		$del->execute( $chunk->{prefix}, $chunknum, $list );
		$add->execute(  $chunk->{prefix}, $chunknum, $list );
	}

	if (scalar @$chunks == 0) { # keep empty chunks
		$del->execute( '', $chunknum, $list );
		$add->execute( '', $chunknum, $list );
	}
}

sub get_add_chunks {
	my ($self, %args) = @_;
	my $prefix			= $args{prefix}	|| '';

	my @list = ();
	my $rows = $self->{dbh}->selectall_arrayref("SELECT * FROM a_chunks WHERE prefix = ?", { Slice => {} }, $prefix);

	foreach my $row (@$rows) {
		push(@list, { chunknum => $row->{num}, prefix => $prefix, list => $row->{list} });
	}

	return @list;
}

sub get_sub_chunks {
	my ($self, %args) = @_;
	my $prefix			= $args{prefix}	|| '';

	my @list = ();
	my $rows = $self->{dbh}->selectall_arrayref("SELECT * FROM s_chunks WHERE prefix = ?", { Slice => {} }, $prefix);

	foreach my $row (@$rows) {
		push(@list, { chunknum => $row->{num}, prefix => $prefix, addchunknum => $row->{add_num}, list => $row->{list}  });
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
	my $chunknums			= $args{chunknums}	|| [];
	my $list					= $args{'list'}		|| '';

	my $num = $self->{dbh}->do("DELETE FROM a_chunks WHERE num IN (" . join(',', @{ $args{chunknums} }) .  ") AND list = ?", { }, $list);
	$self->debug("Rows deleted: $num\n"); 
}


sub delete_sub_ckunks {
	my ($self, %args) = @_;
	my $chunknums		= $args{chunknums}	|| [];
	my $list			= $args{'list'}		|| '';

	my $num = $self->{dbh}->do("DELETE FROM s_chunks WHERE num IN (" . join(',', @{ $args{chunknums} }) . ") AND list = ?" , { }, $list);
	$self->debug("Rows deleted: $num\n"); 
}

sub get_full_hashes {
	my ($self, %args) = @_;
	my $hash					= $args{hash}		|| '';
	my $list					= $args{list}		|| '';
	my $timestamp			= time();

	my @hashes = ();
	my $rows = $self->{dbh}->selectall_arrayref("SELECT hash, type FROM full_hashes WHERE `end` >= ? AND list = ? AND hash = ?", { Slice => {} }, $timestamp, $list, $hash);

	foreach my $row (@$rows) {
		push(@hashes, $row);
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
		$self->{dbh}->do("UPDATE updates SET last = ?, wait = ?, errors = ? WHERE list = ?", undef, $time, $wait, $errors, $list);
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
	my $timestamp			= $args{timestamp}		|| time();
	my $full_hashes		= $args{full_hashes}	|| [];

	foreach my $hash (@$full_hashes) {
		$self->{dbh}->do("DELETE FROM full_hashes WHERE hash = ? AND list = ?", { }, $hash->{hash}, $hash->{list});
		$self->{dbh}->do("INSERT INTO full_hashes (hash, list, `end`, type) VALUES (?, ?, ?, ?)", { }, $hash->{hash}, $hash->{list}, $timestamp + $hash->{life}, $hash->{type} || 0);
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

sub reset_full_hashes {
	my ($self, %args) 	= @_;
	my $list					= $args{'list'}		|| '';

	return if ($self->{keep_all} == 1);

	$self->{delete_full_hashes} ||= $self->{dbh}->prepare('DELETE FROM full_hashes WHERE list = ?');
	my $sth = $self->{delete_full_hashes};
	$sth->execute( $list );
}

sub reset {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}		|| '';

	my $sth = $self->{dbh}->prepare('DELETE FROM s_chunks WHERE list = ?');
	$sth->execute( $list );

	$sth = $self->{dbh}->prepare('DELETE FROM a_chunks WHERE list = ?');
	$sth->execute( $list );

	$self->{delete_full_hashes} ||= $self->{dbh}->prepare('DELETE FROM full_hashes WHERE list = ?');
	$sth = $self->{delete_full_hashes};
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

sub debug {
	my ($self, @messages) = @_;

	print join('', @messages) if ($self->{debug} > 0);
}


=head1 CHANGELOG

=over 4

=item 0.3

Fix deletion of add and sub chunks

=item 0.2

Fix duplicate update records. Speed up deletion of chunks.


=item 0.1

Initial release.

=back

=head1 SEE ALSO

See L<Net::Google::SafeBrowsing3> for handling Google Safe Browsing v3.

See L<Net::Google::SafeBrowsing3::Storage> for the list of public functions.

See L<Net::Google::SafeBrowsing3::Sqlite> for a back-end using Sqlite.

Google Safe Browsing v3 API: L<https://developers.google.com/safe-browsing/developers_guide_v3>


=head1 AUTHOR

Julien Sobrier, E<lt>julien@sobrier.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julien Sobrier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;

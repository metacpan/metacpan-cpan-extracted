package Net::Google::SafeBrowsing2::Sqlite;

use strict;
use warnings;

use base 'Net::Google::SafeBrowsing2::DBI';

use Carp;
use DBI;
use List::Util qw(first);


our $VERSION = '0.9';


=head1 NAME

Net::Google::SafeBrowsing2::Sqlite - Sqlite as back-end storage for the Google Safe Browsing v2 database

=head1 SYNOPSIS

  use Net::Google::SafeBrowsing2::Sqlite;

  my $storage = Net::Google::SafeBrowsing2::Sqlite->new(file => 'google-v2.db');
  ...
  $storage->close();

=head1 DESCRIPTION

This is an implementation of L<Net::Google::SafeBrowsing2::Storage> using Sqlite.

=cut


=head1 CONSTRUCTOR

=over 4

=back

=head2 new()

Create a Net::Google::SafeBrowsing2::Sqlite object

  my $storage = Net::Google::SafeBrowsing2::Sqlite->new(file => 'google-v2.db');

Arguments

=over 4

=item file

Required. File to store the database.

=item keep_all

Optional. Set to 1 to keep old information (such as expiring full hashes) in the database. 0 (delete) by default.

=item cache_size

Sqlite cache size. 20000 by default.

=back


=cut

sub new {
	my ($class, %args) = @_;

	my $self = { # default arguments
		keep_all	=> 0,
		file		=> 'gsb2.db',
		cache_size 	=> 20000,

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

sub init {
	my ($self, %args) = @_;

	$self->{dbh} = DBI->connect("dbi:SQLite:dbname=" . $self->{file}, "", "");
	$self->{dbh}->do("PRAGMA journal_mode = OFF");
	$self->{dbh}->do("PRAGMA synchronous = OFF"); 
	$self->{dbh}->do("PRAGMA cache_size = " . $self->{cache_size}); 

	my @tables = $self->{dbh}->tables;

	if (! defined first { $_ eq '"main"."updates"' || $_ eq '"updates"' } @tables) {
		$self->create_table_updates();
	}
	if (! defined first { $_ eq '"main"."a_chunks"' ||  $_ eq '"a_chunks"' } @tables) {
		$self->create_table_a_chunks();
	}
	if (! defined first { $_ eq '"main"."s_chunks"' || $_ eq '"s_chunks"' } @tables) { 
		$self->create_table_s_chunks();
	}
	if (! defined first { $_ eq '"main"."full_hashes"' || $_ eq '"full_hashes"' } @tables) {
		$self->create_table_full_hashes();
	}
	if (! defined first { $_ eq '"main"."full_hashes_errors"' || $_ eq '"full_hashes_errors"' } @tables) { 
		$self->create_table_full_hashes_errors();
	}
	if (! defined first { $_ eq '"main"."mac_keys"' || $_ eq '"mac_keys"' } @tables) { 
		$self->create_table_mac_keys();
	}

	# Remove indexes created in previous versions
	$self->{dbh}->do('DROP INDEX IF EXISTS a_chunks_hostkey;');
	$self->{dbh}->do('DROP INDEX IF EXISTS a_chunks_num_list;');

	$self->{dbh}->do('DROP INDEX IF EXISTS s_chunks_hostkey;');
	$self->{dbh}->do('DROP INDEX IF EXISTS s_chunks_num;');
}


sub create_table_updates {
	my ($self, %args) = @_;

	my $schema = qq{	
		CREATE TABLE updates (
			last INTEGER DEFAULT 0,
			wait INTEGER DEFAULT 1800,
			errors INTEGER DEFAULT 0,
			list TEXT
		);
	}; # Need to handle errors

	$self->{dbh}->do($schema);
}

sub create_table_a_chunks {
	my ($self, %args) = @_;

	my $schema = qq{
		CREATE TABLE a_chunks (
			hostkey TEXT,
			prefix TEXT,
			num INTEGER,
			list TEXT
		);
	};

	$self->{dbh}->do($schema);

	my $index = qq{
		CREATE INDEX a_chunks_hostkey ON a_chunks (
			hostkey
		);
	};
# 	$self->{dbh}->do($index);

	$index = qq{
		CREATE INDEX a_chunks_num_list ON a_chunks (
			num,
			list
		);
	};
# 	$self->{dbh}->do($index);

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
			hostkey TEXT,
			prefix TEXT,
			num INTEGER,
			add_num INTEGER,
			list TEXT
		);
	};

	$self->{dbh}->do($schema);

	my $index = qq{
		CREATE INDEX s_chunks_hostkey ON s_chunks (
			hostkey
		);
	};
# 	$self->{dbh}->do($index);

	$index = qq{
		CREATE INDEX s_chunks_num ON s_chunks (
			num
		);
	};
# 	$self->{dbh}->do($index);

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
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			num INTEGER,
			hash TEXT,
			list TEXT,
			timestamp INTEGER
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
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			errors INTEGER,
			prefix TEXT,
			timestamp INTEGER
		);
	};

	$self->{dbh}->do($schema);
}

sub create_table_mac_keys{
	my ($self, %args) = @_;

	my $schema = qq{
		CREATE TABLE mac_keys (
			client_key TEXT Default '',
			wrapped_key TEXT Default ''
		);
	};

	$self->{dbh}->do($schema);
}


sub add_chunks_s {
	my ($self, %args) 	= @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

	my $add = $self->{dbh}->prepare('INSERT OR IGNORE INTO s_chunks (hostkey, prefix, num, add_num, list) VALUES (?, ?, ?, ?, ?)');

	$self->{dbh}->begin_work;
	foreach my $chunk (@$chunks) {
		$add->execute( $chunk->{host}, $chunk->{prefix}, $chunknum, $chunk->{add_chunknum}, $list );
	}

	if (scalar @$chunks == 0) { # keep empty chunks
		$add->execute( '', '', $chunknum, '', $list );
	}
	$self->{dbh}->commit;
}

sub add_chunks_a {
	my ($self, %args) 	= @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

	my $add = $self->{dbh}->prepare('INSERT OR IGNORE INTO a_chunks (hostkey, prefix, num, list) VALUES (?, ?, ?, ?)');

	$self->{dbh}->begin_work;
	foreach my $chunk (@$chunks) {
		$add->execute( $chunk->{host}, $chunk->{prefix}, $chunknum, $list );
	}

	if (scalar @$chunks == 0) { # keep empty chunks
		$add->execute( '', '', $chunknum, $list );
	}
	$self->{dbh}->commit;
}


=head1 CHANGELOG

=over 4

=item 0.9

Keep empty sub chunks. Improve performances (remove sone idexes, use trnsactions).

New cache_size option.

=item 0.8

Index s_chunks_unique was created at the wrong place. Thanks to colinmkeith.

=item 0.7

Add option keep_all to keep expired full hashes. Useful for debugging.

=item 0.6

Use more efficient add_chunk_a and add_chunk_s functions.

=item 0.5

Use base class L<Net::Google::SafeBrowsing2::DBI>.

=item 0.4

Disable journalization. This speeds up updated by about 10x.

=item 0.3

Fix typos in the documentation.

=item 0.2

Add close() function to clean up old full hashes, and to close the connection to the database cleanly.

Add table and function to store and retrieve the Message Authentication Code (MAC) key.

In some environments, the module was trying to re-create existing tables. Fixed (Thank you to  Luis Alberto Perez).

=back

=head1 SEE ALSO

See L<Net::Google::SafeBrowsing2> for handling Google Safe Browsing v2.

See L<Net::Google::SafeBrowsing2::Storage> for the list of public functions.

See L<Net::Google::SafeBrowsing2::MySQL> for a back-end using Sqlite.

Google Safe Browsing v2 API: L<http://code.google.com/apis/safebrowsing/developers_guide_v2.html>


=head1 AUTHOR

Julien Sobrier, E<lt>jsobrier@zscaler.comE<gt> or E<lt>julien@sobrier.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Julien Sobrier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;

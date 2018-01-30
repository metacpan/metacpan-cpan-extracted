package Net::Google::SafeBrowsing3::Sqlite;

use strict;
use warnings;

use base 'Net::Google::SafeBrowsing3::DBI';

use Carp;
use DBI;
use List::Util qw(first);


our $VERSION = '0.1';


=head1 NAME

Net::Google::SafeBrowsing3::Sqlite - Sqlite as back-end storage for the Google Safe Browsing v3 database

=head1 SYNOPSIS

  use Net::Google::SafeBrowsing3::Sqlite;

  my $storage = Net::Google::SafeBrowsing3::Sqlite->new(file => 'google-v3.db');
  ...
  $storage->close();

=head1 DESCRIPTION

This is an implementation of L<Net::Google::SafeBrowsing3::Storage> using Sqlite.

=cut


=head1 CONSTRUCTOR

=over 4

=back

=head2 new()

Create a Net::Google::SafeBrowsing3::Sqlite object

  my $storage = Net::Google::SafeBrowsing3::Sqlite->new(file => 'google-v3.db');

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
		file		=> 'gsb3.db',
		cache_size 	=> 20000,
		debug		=> 0,

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
			prefix TEXT,
			num INTEGER,
			list TEXT
		);
	};

	$self->{dbh}->do($schema);

	my $index = qq{
		CREATE INDEX a_chunks_num_list ON a_chunks (
			num,
			list
		);
	};
# 	$self->{dbh}->do($index);

	$index = qq{
		CREATE UNIQUE INDEX a_chunks_unique ON a_chunks (
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
			prefix TEXT,
			num INTEGER,
			add_num INTEGER,
			list TEXT
		);
	};

	$self->{dbh}->do($schema);

	my $index = qq{
		CREATE INDEX s_chunks_num ON s_chunks (
			num
		);
	};
# 	$self->{dbh}->do($index);

	$index = qq{
		CREATE UNIQUE INDEX s_chunks_unique ON s_chunks (
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
			hash TEXT,
			list TEXT,
			end INTEGER,
			type INTEGER
		);
	};

	$self->{dbh}->do($schema);

	my $index = qq{
		CREATE UNIQUE INDEX hash ON full_hashes (
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


sub add_chunks_s {
	my ($self, %args) 	= @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

	my $add = $self->{dbh}->prepare('INSERT OR IGNORE INTO s_chunks (prefix, num, add_num, list) VALUES (?, ?, ?, ?)');

	$self->{dbh}->begin_work;
	foreach my $chunk (@$chunks) {
		$add->execute( $chunk->{prefix}, $chunknum, $chunk->{add_chunknum}, $list );
	}

	if (scalar @$chunks == 0) { # keep empty chunks
		$add->execute( '', $chunknum, '', $list );
	}
	$self->{dbh}->commit;
}

sub add_chunks_a {
	my ($self, %args) 	= @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

	my $add = $self->{dbh}->prepare('INSERT OR IGNORE INTO a_chunks (prefix, num, list) VALUES (?, ?, ?)');

	$self->{dbh}->begin_work;
	foreach my $chunk (@$chunks) {
		$add->execute( $chunk->{prefix}, $chunknum, $list );
	}

	if (scalar @$chunks == 0) { # keep empty chunks
		$add->execute( '', $chunknum, $list );
	}
	$self->{dbh}->commit;
}


=head1 CHANGELOG

=over 4


=item 0.1

Initial release

=back

=head1 SEE ALSO

See L<Net::Google::SafeBrowsing3> for handling Google Safe Browsing v3.

See L<Net::Google::SafeBrowsing3::Storage> for the list of public functions.

See L<Net::Google::SafeBrowsing3::MySQL> for a back-end using Sqlite.

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

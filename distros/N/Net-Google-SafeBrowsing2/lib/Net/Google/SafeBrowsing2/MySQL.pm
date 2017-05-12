package Net::Google::SafeBrowsing2::MySQL;

use strict;
use warnings;

use base 'Net::Google::SafeBrowsing2::DBI';

use Carp;
use DBI;
use List::Util qw(first);


our $VERSION = '1.0';


=head1 NAME

Net::Google::SafeBrowsing2::MySQL - MySQL as back-end storage for the Google Safe Browsing v2 database

=head1 SYNOPSIS

  use Net::Google::SafeBrowsing2::MySQL;

  my $storage = Net::Google::SafeBrowsing2::MySQL->new(host => '127.0.0.1', database => 'GoogleSafeBrowsingv2');
  ...
  $storage->close();

=head1 DESCRIPTION

This is an implementation of L<Net::Google::SafeBrowsing2::Storage> using MySQL.

=cut


=head1 CONSTRUCTOR

=over 4

=back

=head2 new()

Create a Net::Google::SafeBrowsing2::MySQL object

  my $storage = Net::Google::SafeBrowsing2::MySQL->new(
      host     => '127.0.0.1', 
      database => 'GoogleSafeBrowsingv2', 
      username => 'foo', 
      password => 'bar'
  );

Arguments

=over 4

=item host

Required. MySQL host name

=item database

Required. MySQL database name to connect to.

=item username

Required. MySQL username.

=item password

Required. MySQL password.

=item port

Optional. MySQL port number to connect to.

=item keep_all

Optional. Set to 1 to keep old information (such as expiring full hashes) in the database. 0 (delete) by default.

=back


=cut

sub new {
	my ($class, %args) = @_;

	my $self = { # default arguments
		host		=> '127.0.0.1',
		database	=> 'GoogleSafeBrowsingv2',
		port		=> 3306,
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

sub init {
	my ($self, %args) = @_;

	$self->{dbh} = DBI->connect("DBI:mysql:database=" . $self->{database} . ";host=" . $self->{host} . ";port=" . $self->{port}, $self->{username}, $self->{password}, {'RaiseError' => 1});

	my @tables = $self->{dbh}->tables;

	if (! defined first { $_ =~ '`updates`' } @tables) {
		$self->create_table_updates();
	}
	if (! defined first { $_ =~ '`a_chunks`' } @tables) {
		$self->create_table_a_chunks();
	}
	if (! defined first { $_ =~ '`s_chunks`' } @tables) { 
		$self->create_table_s_chunks();
	}
	if (! defined first { $_ =~ '`full_hashes`' } @tables) {
		$self->create_table_full_hashes();
	}
	if (! defined first { $_ =~ '`full_hashes_errors`' } @tables) { 
		$self->create_table_full_hashes_errors();
	}
	if (! defined first { $_ =~ '`mac_keys`' } @tables) { 
		$self->create_table_mac_keys();
	}

	# Remove indexes previously created
	$self->{dbh}->do("ALTER TABLE `a_chunks` DROP INDEX `a_chunks_hostkey`") if ($self->{dbh}->do("SHOW INDEX FROM `a_chunks`WHERE KEY_NAME = 'a_chunks_hostkey'") > 0);
	$self->{dbh}->do("ALTER TABLE `a_chunks` DROP INDEX `a_chunks_num_list`") if ($self->{dbh}->do("SHOW INDEX FROM `a_chunks`WHERE KEY_NAME = 'a_chunks_num_list'") > 0);

	$self->{dbh}->do("ALTER TABLE `s_chunks` DROP INDEX `s_chunks_hostkey`") if ($self->{dbh}->do("SHOW INDEX FROM `s_chunks`WHERE KEY_NAME = 's_chunks_hostkey'") > 0);
	$self->{dbh}->do("ALTER TABLE `s_chunks` DROP INDEX `s_chunks_num`") if ($self->{dbh}->do("SHOW INDEX FROM `s_chunks`WHERE KEY_NAME = 's_chunks_num'") > 0);
	$self->{dbh}->do("ALTER TABLE `s_chunks` DROP INDEX `s_chunks_num_list`") if ($self->{dbh}->do("SHOW INDEX FROM `s_chunks`WHERE KEY_NAME = 's_chunks_num_list'") > 0);
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
			hostkey VARBINARY( 8 ),
			prefix VARBINARY( 8 ),
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
			hostkey VARBINARY( 8 ),
			prefix VARBINARY( 8 ),
			num INT NOT NULL,
			add_num INT DEFAULT 0,
			list VARCHAR( 50 ) NOT NULL
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
		CREATE INDEX s_chunks_num_list ON s_chunks (
			num,
			list
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
			id INT AUTO_INCREMENT PRIMARY KEY,
			num INT,
			hash VARBINARY( 32 ),
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
			prefix VARBINARY( 8 ),
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


sub add_chunks_s {
	my ($self, %args) 	= @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

	my $add = $self->{dbh}->prepare('INSERT IGNORE INTO s_chunks (hostkey, prefix, num, add_num, list) VALUES (?, ?, ?, ?, ?)');
	$self->{dbh}->{AutoCommit} = 0;

	foreach my $chunk (@$chunks) {
		$add->execute( $chunk->{host}, $chunk->{prefix}, $chunknum, $chunk->{add_chunknum}, $list );
	}

	if (scalar @$chunks == 0) { # keep empty chunks
		$add->execute( '', '',  $chunknum, '', $list );
	}

	$self->{dbh}->commit;
	$self->{dbh}->{AutoCommit} = 1;
}

sub add_chunks_a {
	my ($self, %args) 	= @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';

	my $add = $self->{dbh}->prepare('INSERT IGNORE INTO a_chunks (hostkey, prefix, num, list) VALUES (?, ?, ?, ?)');
	$self->{dbh}->{AutoCommit} = 0;

	foreach my $chunk (@$chunks) {
		# 32-byte prefix seen at chunk 69961
		# If this becomes more of a problem, the schema will have to be adjusted.
		if (length($chunk->{prefix}) > 8) {
			$chunk->{prefix} = substr $chunk->{prefix}, 0, 4;
		}

		$add->execute( $chunk->{host}, $chunk->{prefix}, $chunknum, $list );
	}

	if (scalar @$chunks == 0) { # keep empty chunks
		$add->execute( '', '', $chunknum, $list );
	}

	$self->{dbh}->commit;
	$self->{dbh}->{AutoCommit} = 1;
}

=head1 CHANGELOG

=over 4

=item 0.6

Remove some indexes to speed up INSERTs.

=item 0.5

Keep empty sub chunks. Shorten prefixes greater than 8 bytes (workaround to keep schema tight)

=item 0.4

Add option keep_all to keep expired full hashes. Useful for debugging.

=item 0.3

Use more efficient add_chunk_a and add_chunk_s functions.
Change data type for prefixes from VARCHAR to VARBINARY.


=back

=head1 SEE ALSO

See L<Net::Google::SafeBrowsing2> for handling Google Safe Browsing v2.

See L<Net::Google::SafeBrowsing2::Storage> for the list of public functions.

See L<Net::Google::SafeBrowsing2::Sqlite> for a back-end using Sqlite.

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

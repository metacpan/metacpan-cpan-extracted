package Net::Google::SafeBrowsing2::Storage;


use strict;
use warnings;

use Carp;


our $VERSION = '0.4';

=head1 NAME

Net::Google::SafeBrowsing2::Storage - Base class for storing the Google Safe Browsing v2 database

=head1 SYNOPSIS

  package Net::Google::SafeBrowsing2::Sqlite;

  use base 'Net::Google::SafeBrowsing2::Storage';

=head1 DESCRIPTION

This is the base class for implementing a storage mechanism for the Google Safe Browsing v2 database. See L<Net::Google::SafeBrowsing2::Sqlite> for an example of implementation.

This module cannot be used on its own as it does not actually store anything. All methods should redefined. Check the code to see which arguments are used, and what should be returned.

=cut


=head1 CONSTRUCTOR

=over 4

=back

=head2 new()

  Create a Net::Google::SafeBrowsing2::Storage object

  my $storage	=> Net::Google::SafeBrowsing2::Storage->new();

=cut

sub new {
	my ($class, %args) = @_;

	my $self = {
		%args,
	};

	bless $self, $class or croak "Can't bless $class: $!";
    return $self;
}

=head1 PUBLIC FUNCTIONS

=over 4

=back

=head2 add_chunks()

Add chunk information to the local database

  $storage->add_chunks(type => 'a', chunknum => 2154, chunks => [{host => HEX, prefix => ''}], list => 'goog-malware-shavar');

Does not return anything.


Arguments

=over 4

=item type

Required. Type of chunk: 'a' (add chunk) or 's' (sub chunk).

=item chunknum

Required. Chunk number.

=item chunks

Required. Array of chunks

For add chunks, each element of the array is an hash reference in the following format:

  {
    host => HEX,
	prefix => HEX
  }

For sub chunks, each element of the array is an hash reference in the following format:

  {
    host => HEX,
	prefix => HEX,
    add_chunknum => INTEGER
  }

=item list

Required. Google Safe Browsing list name.


=back

=cut

sub add_chunks {
	my ($self, %args) 	= @_;
	my $type			= $args{type}		|| 'a';
	my $chunknum		= $args{chunknum}	|| 0;
	my $chunks			= $args{chunks}		|| [];
	my $list			= $args{'list'}		|| '';


	# Save { type => $type, host => $chunk->{host}, prefix => $chunk->{prefix}, chunknum => $chunknum, list => $list }
}

=head2 get_add_chunks()

Returns a list of chunks for a given host key for all lists.

	my @chunks = $storage->get_add_chunks(hostkey => HEX);


Arguments

=over 4

=item hostkey.

Required. Host key.

=back


Return value

=over 4

Array of add chunks in the same format as described above:

    (
		{ 
			chunknum	=> 25121,
			hostkey		=> hex('12345678'),
			prefix		=> '',
			list		=> 'goog-malware-shavar'
		},
		{ 
			chunknum	=> '25121',
			hostkey		=> hex('12345678'),
			prefix		=> hex('2fc96b9f'),
			list		=> 'goog-malware-shavar'
		},
	);

=back

=cut

sub get_add_chunks {
	my ($self, %args) = @_;
	my $hostkey			= $args{hostkey}	|| '';

	return (
		{ 
			chunknum	=> 25121,
			prefix		=> '',
			hostkey		=> $hostkey,
			list		=> 'goog-malware-shavar'
		},
		{ 
			chunknum	=> '25121',
			prefix		=> $self->ascii_to_hex('2fc96b9f'),
			hostkey		=> $hostkey,
			list		=> 'goog-malware-shavar'
		},
	);
}

=head2 get_sub_chunks()

Returns a list of sub chunks for a given host key for all lists.

	my @chunks = $storage->get_sub_chunks(hostkey => HEX);


Arguments

=over 4

=item hostkey

Required. Host key.

=back


Return value

=over 4

Array of add chunks in the same format as described above:

    (
		{ 
			chunknum	=> 37441,
			prefix		=> '',
			addchunknum	=> 23911,
			list		=> 'goog-malware-shavar'
		},
		{ 
			chunknum	=> 37441,
			prefix		=> '',
			addchunknum	=> 22107,
			list		=> 'goog-malware-shavar'
		},
	);

=back

=cut

sub get_sub_chunks {
	my ($self, %args) = @_;
	my $hostkey			= $args{hostkey}	|| '';


	return (
		{ 
			chunknum	=> 37441,
			prefix		=> '',
			addchunknum	=> 23911,
			list		=> 'goog-malware-shavar'
		},
		{ 
			chunknum	=> 37441,
			prefix		=> '',
			addchunknum	=> 22107,
			list		=> 'goog-malware-shavar'
		},
	);
}

=head2 get_add_chunks_nums()

Returns a list of unique add chunk numbers for a specific list. 

B<IMPORTANT>: this list should be sorted in ascendant order.

	my @ids = $storage->get_add_chunks_nums(list => 'goog-malware-shavar');


Arguments

=over 4

=item list

Required. Google Safe Browsing list name

=back


Return value

=over 4

Array of integers sorted in ascendant order:

    qw(25121 25122 25123 25124 25125 25126)

=back

=cut

sub get_add_chunks_nums {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}		|| '';

	return qw(25121 25122 25123 25124 25125 25126);
}

=head2 get_sub_chunks_nums()

Returns a list of unique sub chunk numbers for a specific list. 

B<IMPORTANT>: this list should be sorted in ascendant order.

	my @ids = $storage->get_sub_chunks_nums(list => 'goog-malware-shavar');


Arguments

=over 4

=item list

Required. Google Safe Browsing list name

=back


Return value

=over 4

Array of integers sorted in ascendant order:

    qw(37441 37442 37443 37444 37445 37446 37447 37448 37449 37450)

=back

=cut

sub get_sub_chunks_nums {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}		|| '';
	
	return qw(37441 37442 37443 37444 37445 37446 37447 37448 37449 37450);
}

=head2 delete_add_chunks()

Delete add chunks from the local database

	$storage->delete_add_chunks(chunknums => [qw/37444 37445 37446/], list => 'goog-malware-shavar');


Arguments

=over 4

=item chunknums

Required. Array of chunk numbers

=item list

Required. Google Safe Browsing list name

=back


No return value


=cut

sub delete_add_ckunks {
	my ($self, %args) 	= @_;
	my $chunknums		= $args{chunknums}	|| [];
	my $list			= $args{'list'}		|| '';

	foreach my $num (@$chunknums) {
		# DELETE FROM [...] WHERE chunknumber = $num AND list = $list
	}
}

=head2 delete_sub_chunks()

Delete sub chunks from the local database

	$storage->delete_sub_chunks(chunknums => [qw/37444 37445 37446/], list => 'goog-malware-shavar');


Arguments

=over 4

=item chunknums

Required. Array of chunk numbers

=item list

Required. Google Safe Browsing list name

=back


No return value


=cut

sub delete_sub_ckunks {
	my ($self, %args) = @_;
	my $chunknums		= $args{chunknums}	|| [];
	my $list			= $args{'list'}		|| '';

	foreach my $num (@$chunknums) {
		# DELETE FROM [...] WHERE chunknumber = $num AND list = $list
	}
}

=head2 get_full_hashes()

Return a list of full hashes

	$storage->get_full_hashes(chunknum => 37444, timestamp => time() - 45 * 60 * 60, list => 'goog-malware-shavar');


Arguments

=over 4

=item chunknum

Required. Add chunk number

=item timestamp

Required. Request hashes retrieved after this timestamp value.

=item list

Required. Google Safe Browsing list name

=back

Return value

=over 4

Array of full hashes:

    (HEX, HEX, HEX)

=back


=cut

sub get_full_hashes {
	my ($self, %args) = @_;
	my $chunknum		= $args{chunknum}	|| 0;
	my $timestamp		= $args{timestamp}	|| 0;
	my $list			= $args{list}		|| '';

	return (
		$self->ascii_to_hex('eb9744c011d332ad9c92442d18d5a0f913328ad5623983822fc86fad1aab649d'),
		$self->ascii_to_hex('2ae11a967a5517e24c7be3fa0b8f56e7a13358ce3b07556dc251bc6b650f0f59')
	);
}

=head2 updated()

Save information about a successful database update

	$storage->updated('time' => time(), wait => 1800, list => 'goog-malware-shavar');


Arguments

=over 4

=item time

Required. Time of the update.

=item wait

Required. Number o seconds to wait before doing the next update.

=item list

Required. Google Safe Browsing list name.

=back


No return value

=cut

sub updated {
	my ($self, %args) 	= @_;
	my $time			= $args{'time'}	|| time();
	my $wait			= $args{'wait'}	|| 1800;
	my $list			= $args{'list'}	|| '';

	# INSERT INTO [...] (last, wait, errors, list) VALUES (?, ?, 0, ?)", $time, $wait, $list);
}

=head2 update_error()

Save information about a failed database update

	$storage->update_error('time' => time(), wait => 60, list => 'goog-malware-shavar', errors => 1);


Arguments

=over 4

=item time

Required. Time of the update.

=item wait

Required. Number o seconds to wait before doing the next update.

=item list

Required. Google Safe Browsing list name.

=item errors

Required. Number of errors.

=back


No return value

=cut

sub update_error {
	my ($self, %args) 	= @_;
	my $time			= $args{'time'}	|| time();
	my $list			= $args{'list'}	|| '';
	my $wait			= $args{'wait'}	|| 60;
	my $errors			= $args{errors}	|| 1;

	# UPDATE updates SET last = $time, wait = $wait, errors = $errors, list = $list
}

=head2 last_update()

Return information about the last database update

	my $info = $storage->last_update(list => 'goog-malware-shavar');


Arguments

=over 4

=item list

Required. Google Safe Browsing list name.

=back


Return value

=over 4

Hash reference

	{
		time	=> time(),
		wait	=> 1800,
		errors	=> 0
	}

=back

=cut

sub last_update {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}	|| '';

	return {'time' => time(), 'wait' => 1800, errors => 0};
}

=head2 add_full_hashes()

Add full hashes to the local database

	$storage->add_full_hashes(timestamp => time(), full_hashes => [{chunknum => 2154, hash => HEX, list => 'goog-malware-shavar'}]);


Arguments

=over 4

=item timestamp

Required. Time when the full hash was retrieved.

=item full_hashes

Required. Array of full hashes. Each element is an hash reference in the following format:

	{
		chunknum	=> INTEGER,
		hash		=> HEX,
		list		=> 'goog-malware-shavar'
	}

=back


No return value


=cut

sub add_full_hashes {
	my ($self, %args) 	= @_;
	my $timestamp		= $args{timestamp}		|| time();
	my $full_hashes		= $args{full_hashes}	|| [];

	foreach my $hash (@$full_hashes) {
		# INSERT INTO [...] (num, hash, list, timestamp) VALUES ($hash->{chunknum}, $hash->{hash}, $hash->{list}, $timestamp);
	}
}

=head2 delete_full_hashes()

Delete full hashes from the local database

	$storage->delete_full_hashes(chunknums => [qw/2154 2156 2158/], list => 'goog-malware-shavar');


Arguments

=over 4

=item chunknums

Required. Array of chunk numbers.

=item list

Required. Google Safe Browsing list name.

=back


No return value


=cut

sub delete_full_hashes {
	my ($self, %args) 	= @_;
	my $chunknums		= $args{chunknums}	|| [];
	my $list			= $args{list}		|| croak "Missing list name\n";

	foreach my $num (@$chunknums) {
		# "DELETE FROM [...] WHERE num = $num AND list = $list
	}
}

=head2 full_hash_error()

Save information about failed attempt to retrieve a full hash

	$storage->full_hash_error(timestamp => time(), prefix => HEX);


Arguments

=over 4

=item timestamp

Required. Time when the Google returned an error.

=item prefix

Required. Host prefix.

=back


No return value


=cut

sub full_hash_error {
	my ($self, %args) 	= @_;
	my $timestamp		= $args{timestamp}	|| time();
	my $prefix			= $args{prefix}		|| '';

	# Add 1 to existing error count
}

=head2 full_hash_ok()

Save information about a successful attempt to retrieve a full hash

	$storage->full_hash_ok(timestamp => time(), prefix => HEX);


Arguments

=over 4

=item timestamp

Required. Time when the Google returned an error.

=item prefix

Required. Host prefix.

=back


No return value


=cut

sub full_hash_ok {
	my ($self, %args) 	= @_;
	my $timestamp		= $args{timestamp}	|| time();
	my $prefix			= $args{prefix}		|| '';

	# UPDATE full_hashes_errors SET errors = 0, timestamp = $timestamp WHERE prefix = $prefix
}

=head2 get_full_hash_error()

Save information about a successful attempt to retrieve a full hash

	my $info = $storage->get_full_hash_error(prefix => HEX);


Arguments

=over 4

=item prefix

Required. Host prefix.

=back


Return value

=over 4

undef if there was no error

Hash reference in the following format if there was an error:

	{
		timestamp 	=> time(),
		errors		=> 3
	}

=back


=cut

sub get_full_hash_error {
	my ($self, %args) 	= @_;
	my $prefix			= $args{prefix}		|| '';


	# no error
	return undef;

	# some error
	# return { timestamp => time(), errors => 3 }
}

=head2 get_mac_keys()

Retrieve the Message Authentication Code (MAC) keys.

	my $keys = $storage->get_mac_keys();


No arguments


Return value

=over 4


Hash reference in the following format:

	{
		client_key 	=> '',
		wrapped_key	=> ''
	}

=back

=cut

sub get_mac_keys {
	my ($self, %args) 	= @_;


	return { client_key => '', wrapped_key => '' }
}

=head2 delete_add_keys()

Add the Message Authentication Code (MAC) keys.

	$storage->delete_mac_keys(client_key => 'KEY', wrapped_key => 'KEY');


Arguments

=over 4

=item client_key

Required. Client key.

=item wrapped_key

Required. Wrapped key.

=back

No return value

=cut

sub add_mac_keys {
	my ($self, %args) 	= @_;
	my $client_key		= $args{client_key}		|| '';
	my $wrapped_key		= $args{wrapped_key}	|| '';

	# INSERT INTO ...

}

=head2 delete_mac_keys()

Delete the Message Authentication Code (MAC) keys.

	$storage->delete_mac_keys();


No arguments

No return value

=cut

sub delete_mac_keys {
	my ($self, %args) 	= @_;

# 	# DELETE FROM mac_keys WHERE 1
}


=head2 reset()

Remove all local data

	$storage->delete_mac_keys();


Arguments

=over 4

=item list

Required. Google Safe Browsing list name.

=back

No return value

=cut

sub reset {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}		|| '';

	# DELETE FROM s_chunks WHERE list = $list
	# DELETE FROM a_chunks WHERE list = $list
	# DELETE FROM full_hashes WHERE list = $list
	# DELETE FROM full_hashes_errors WHERE list = $list
	# DELETE FROM updates WHERE list = $list
}


=head1 PRIVATE FUNCTIONS

These functions are not intended for debugging purpose.

=over 4

=back

=head2 hex_to_ascii()

Transform hexadecimal strings to printable ASCII strings. Used mainly for debugging.

  print $storage->hex_to_ascii('hex value');

=cut

sub hex_to_ascii {
	my ($self, $hex) = @_;


	my $ascii = '';

	while (length $hex > 0) {
		$ascii .= sprintf("%02x",  ord( substr($hex, 0, 1, '') ) );
	}

	return $ascii;
}

=head2 ascii_to_hex()

Transform ASCII strings to hexadecimal strings.

	  print $storage->ascii_to_hex('ascii value');

=cut

sub ascii_to_hex {
	my ($self, $ascii) = @_;

	my $hex = '';
	for (my $i = 0; $i < int(length($ascii) / 2); $i++) {
		$hex .= chr hex( substr($ascii, $i * 2, 2) );
	}

	return $hex;
}

=head1 CHANGELOG

=over 4

=item 0.4

Add reset mehtod to empty local database.

=item 0.3

Return the hostkey as part of the add chunks (get_add_chunks).

=item 0.2

Add functions to store and retrieve Message Authentication Code (MAC) keys.

=back

=head1 SEE ALSO

See L<Net::Google::SafeBrowsing2> for handling Google Safe Browsing v2.

See L<Net::Google::SafeBrowsing2::Sqlite> or L<Net::Google::SafeBrowsing2::MySQL> for an example of storing and managing the Google Safe Browsing database.

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

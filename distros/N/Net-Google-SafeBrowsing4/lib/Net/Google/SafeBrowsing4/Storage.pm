package Net::Google::SafeBrowsing4::Storage;

# ABSTRACT: Base class for storing the Google Safe Browsing v4 database

use strict;
use warnings;

our $VERSION = '0.2';

=head1 NAME

Net::Google::SafeBrowsing4::Storage - Base class for storing the Google Safe Browsing v4 database

=head1 SYNOPSIS

	package Net::Google::SafeBrowsing4::Storage::File;

	use base qw(Net::Google::SafeBrowsing4::Storage);

=head1 DESCRIPTION

This is the base class for implementing a storage mechanism for the Google Safe Browsing v4 database. See L<Net::Google::SafeBrowsing4::Storage::File> for an example of implementation.

This module cannot be used on its own as it does not actually store anything. All public methods should redefined.

=cut


=head1 CONSTRUCTOR

=head2 new()

	Create a Net::Google::SafeBrowsing4::Storage object

	my $storage => Net::Google::SafeBrowsing4::Storage->new(
		# Constructor parameters vary based on the implementation
		...
	);

=cut

sub new {
	...
}

=head1 PUBLIC FUNCTIONS

=over 4

=back

=head2 save()

Add chunk information to the local database

  $storage->save(add => [...], remove => [...], state => '...', list => { threatType => ..., threatEntryType => ..., platformType => ... });

Return the new list of local hashes.


Arguments

=over 4

=item override

Optional. override the local list of hashes. 0 by default (do not override)

=item add

Optional. List of hashes to add.

=item remove

Optional. List of hash indexes to remove.

=item state

Optional. New list state.

=item list

Required. Google Safe Browsing list.

=back

=cut

sub save {
	...
}


=head2 reset()

Remove all local data.

	$storage->reset(list => { threatType => ..., threatEntryType => ..., platformType => ... });


Arguments

=over 4

=item list

Required. Google Safe Browsing list.

=back

No return value

=cut

sub reset {
	...
}


=head2 next_update()

Ge the timestamp when the local database update is allowed.

	my $next = $storage->next_update();


No arguments

=cut

sub next_update {
	...
}


=head2 get_state()

Return the current state of the list.

	my $state = $storage->get_state(list => { threatType => ..., threatEntryType => ..., platformType => ... });


Arguments

=over 4

=item list

Required. Google Safe Browsing list.

=back


=cut

sub get_state {
	...
}



=head2 get_prefixes()

Return the list of prefxies that match a full hash for a given list.

	my @prefixes = $storage->get_prefixes(hashes => [...], list => { threatType => ..., threatEntryType => ..., platformType => ... });


Arguments

=over 4

=item list

Required. Google Safe Browsing list.

=back

=item hashes

Required. List of full hashes.

=back


=cut

sub get_prefixes {
	...
}

=head2 updated()

Save information about a successful database update

	$storage->updated('time' => time(), next => time() + 1800);


Arguments

=over 4

=item time

Required. Time of the update.

=item next

Required. Time of the next update allowed.

=back


No return value

=cut

sub updated {
	...
}


=head2 get_full_hashes()

Return a list of full hashes

	$storage->get_full_hashes(hash => AAAAAAAA..., lists => [{ threatType => '...', threatEntryType => '...', platformType => '...' }]);


Arguments

=over 4

=item hash

Required. 32-bit hash


=item lists

Required. Google Safe Browsing lists

=back

Return value

=over 4

Array of full hashes:

    ({ hash => HEX, type => 0 }, { hash => HEX, type => 1 }, { hash => HEX, type => 0 })

=back


=cut

sub get_full_hashes {
	...
}


=head2 update_error()

Save information about a failed database update

	$storage->update_error('time' => time(), wait => 60, errors => 1);


Arguments

=over 4

=item time

Required. Time of the update.

=item wait

Required. Number of seconds to wait before doing the next update.

=item errors

Required. Number of errors.

=back


No return value

=cut

sub update_error {
	...
}

=head2 last_update()

Return information about the last database update

	my $info = $storage->last_update();


No arguments


Return value

=over 4

Hash reference

	{
		time	=> time(),
		errors	=> 0
	}

=back

=cut

sub last_update {
	...
}

=head2 add_full_hashes()

Add full hashes to the local database

	$storage->add_full_hashes(timestamp => time(), full_hashes => [{hash => HEX, list => { }, cache => "300s"}]);


Arguments

=over 4

=item timestamp

Required. Time when the full hash was retrieved.

=item full_hashes

Required. Array of full hashes. Each element is an hash reference in the following format:

	{
		hash		=> HEX,
		list		=> { }',
		cache => "300s"
	}

=back


No return value


=cut

sub add_full_hashes {
	...
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
	...
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
	...
}

=head2 get_full_hash_error()

Save information about an unsuccessful attempt to retrieve a full hash

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
	...
}

=head1 SEE ALSO

See L<Net::Google::SafeBrowsing4> for handling Google Safe Browsing v4.

See L<Net::Google::SafeBrowsing4::Storage::File> for an example of storing and managing the Google Safe Browsing database.

Google Safe Browsing v4 API: L<https://developers.google.com/safe-browsing/v4/>

=head1 AUTHOR

Julien Sobrier, E<lt>julien@sobrier.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Julien Sobrier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;

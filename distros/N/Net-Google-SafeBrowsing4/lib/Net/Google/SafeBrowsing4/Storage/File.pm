package Net::Google::SafeBrowsing4::Storage::File;

use strict;
use warnings;

use base qw(Net::Google::SafeBrowsing4::Storage);

use Carp;
use List::Util qw(first);
use Path::Tiny;
use Storable qw(nstore retrieve);
use List::BinarySearch qw(binsearch);


our $VERSION = '0.4';

=head1 NAME

Net::Google::SafeBrowsing4::Storage::File - File storage for the Google Safe Browsing v4 database

=head1 SYNOPSIS

	use Net::Google::SafeBrowsing4::Storage::File;

	my $storage = Net::Google::SafeBrowsing4::Storage::File->new(path => '.');
	$storage->save(...);

=head1 DESCRIPTION

This is the a file-based implementation of L<Net::Google::SafeBrowsing4::Storage> to manage the Google Safe Browsing v4 local database.

=cut


=head1 CONSTRUCTOR

=over 4

=back

=head2 new()

  Create a Net::Google::SafeBrowsing4::Storage::File object

  my $storage	=> Net::Google::SafeBrowsing4::Storage::File->new(path => '.');

Arguments

=over 4

=item path

Optional. Path to store the database files Use current directory by default.

=item keep_all

Optional. Set to 1 to keep old information (such as expiring full hashes) in the database. 0 (delete) by default.

=item sticky

Optional. Set to 1 to if you are going to do multiple lookup. More memory will be used but lookup will be sped up. 0 by default.

=item files

Optional. Hash reference to map file types to file names. Default:

	{
		updates => "updates.gdb4",
		full_hashes => "full_hashes.gsb4"
	}

=item logger

Optional. Log4Perl compatible object reference. By default this option is unset, making Net::Google::SafeBrowsing4::Storage::File silent.

=back

=cut

sub new {
	my ($class, %args) = @_;

	my $self = { # default arguments
		keep_all	=> 0,
		path 		=> '.',
		sticky		=> 0,
		files => {
			updates => "updates.gdb4",
			full_hashes => "full_hashes.gsb4",
			lists => "lists.gsb4"
		},
		data => { },
		%args,
	};

	bless($self, $class) or croak("Can't bless $class: $!");

	$self->init();

	return $self;
}

=head1 PUBLIC FUNCTIONS

=over 4

See L<Net::Google::SafeBrowsing4::Storage> for a complete list of public functions.

=back

=head2 close()

Cleanup old full hashes, and close the connection to the database.

  $storage->close();

=cut


sub init {
	my ($self, %args) = @_;

	# make sure path exists
	if (! -d $self->{path}) {
		mkdir($self->{path}) or croak("Cannot create directory " . $self->{path} . ": $!\n");
	}

	# file to hold all updates
	my $file = path(join("/", $self->{path}, $self->{files}->{updates}));
	if (! -e $file) {
		my %update = (last_update => 0, next_update => 0, errors => 0);
		if ($self->{sticky}) {
			$self->{data}->{ $self->{files}->{updates} } = { %update };
		}

		nstore(\%update, $file) or croak("Cannot store information into $file: $!\n");
	}
}

sub save {
	my ($self, %args) = @_;
	my $list 		= $args{list} 		|| croak("Missing list information");
	my $override	= $args{override}	|| 0;
	my @hashes		= @{ $args{add} 	|| [] };
	my @remove		= @{ $args{remove} 	|| [] };
	my $state		= $args{'state'}	|| '';

	# save the information somewhere
	my $file = path(join("/", $self->{path}, $self->list_to_file($list)));
	$self->{logger} && $self->{logger}->debug("Save hashes to $file");

	my %data = ('state' => $state, hashes => [@hashes]); # hashes are already stored
	if (-e $file && !$override) {
		my $db = retrieve($file);
		$self->{logger} && $self->{logger}->debug("Load $file (save)");

		$self->{logger} && $self->{logger}->debug("hashes to remove: ", scalar(@remove));
		$self->{logger} && $self->{logger}->debug("hashes to add: ", scalar(@hashes));

		$self->{logger} && $self->{logger}->debug("Number of hashes before removal: ", scalar(@{ $db->{hashes} }));
		foreach my $index (@remove) {
			$self->{logger} && $self->{logger}->debug("Remove index $index");
			$db->{hashes}->[$index] = '';
		}
		$db->{hashes} = [ grep { $_ ne '' } @{ $db->{hashes} } ];
		$self->{logger} && $self->{logger}->debug("Number of hashes after removal: ", scalar(@{ $db->{hashes} }));

		$data{hashes} = [sort { $a cmp $b } (@hashes, @{ $db->{hashes} })];
	}

	nstore(\%data, $file) or croak("Cannot save data to $file: $!\n");
	if ($self->{sticky}) {
		$self->{data}->{ $self->list_to_file($list) } = { %data };
	}

	# return the list of hashes, sorted, from the new storage
	$self->{logger} && $self->{logger}->debug("Number of hashes at end: ", scalar(@{ $data{hashes} }));
	return @{ $data{hashes} };
}



sub reset {
	my ($self, %args) = @_;
	my $list = $args{list} || croak("Missing list information");

	my $file = path(join("/", $self->{path}, $self->list_to_file($list)));
	unlink($file);

	if ($self->{sticky}) {
		$self->{data}->{ $self->list_to_file($list) } = { };
	}
}


sub next_update {
	my ($self, %args) = @_;

	# make sure the file exists
	$self->init();

	my $update = { };
	if ($self->{sticky} && exists($self->{data}->{ $self->{files}->{updates} })) {
		$update = $self->{data}->{ $self->{files}->{updates} };
	}
	else {
		# retrieve information from storage
		my $file = path(join("/", $self->{path}, $self->{files}->{updates}));
		$update = retrieve($file);
		$self->{logger} && $self->{logger}->debug("Load $file (reset)");

		if ($self->{sticky}) {
			$self->{data}->{ $self->{files}->{updates} } = $update;;
		}
	}

	return $update->{next_update} || 0;
}

sub last_update {
	my ($self, %args) = @_;

	# make sure the file exists
	$self->init();

	my $update = { };
	if ($self->{sticky} && exists($self->{data}->{ $self->{files}->{updates} })) {
		$update = $self->{data}->{ $self->{files}->{updates} };
	}
	else {
		# retrieve information from storage
		my $file = path(join("/", $self->{path}, $self->{files}->{updates}));
		$update = retrieve($file);
		$self->{logger} && $self->{logger}->debug("Load $file (last_update)");

		if ($self->{sticky}) {
			$self->{data}->{ $self->{files}->{updates} } = $update;
		}
	}

	return { last_update => $update->{last_update} || 0, errors => $update->{errors} || 0 };
}


sub get_state {
	my ($self, %args) = @_;
	my $list = $args{list} || croak("Missing list information\n");

	my $update = { };
	if ($self->{sticky} && exists($self->{data}->{ $self->list_to_file($list) })) {
		$update = $self->{data}->{ $self->list_to_file($list) };
	}
	else {
		my $file = path(join("/", $self->{path}, $self->list_to_file($list)));
		if (! -e $file) {
			return "";
		}
		else {
			$self->{logger} && $self->{logger}->debug("Load $file (get_state)");
			$update = retrieve($file);

			if ($self->{sticky}) {
				$self->{data}->{ $self->list_to_file($list) } = $update;
			}
		}
	}

	return $update->{'state'} || '';
}

sub updated {
	my ($self, %args) = @_;
	my $time = $args{'time'} || time();
	my $next = $args{'next'} || time() + 1800;

	# next update applies to all lists, save it
	# make sure the file exists
	$self->init();

	my $file = path(join("/", $self->{path}, $self->{files}->{updates}));
	my $update = { };
	if ($self->{sticky} && exists($self->{data}->{ $self->{files}->{updates} })) {
		$update = $self->{data}->{ $self->{files}->{updates} };
	}
	else {
		# retrieve information from storage
		$self->{logger} && $self->{logger}->debug("Load $file (updated)");
		$update = retrieve($file);
	}

	$update->{next_update} = $next;
	$update->{last_update} = $time;
	$update->{errors} = 0;

	nstore($update, $file) or croak("Cannot save data to $file: $!\n");

	if ($self->{sticky}) {
		$self->{data}->{ $self->{files}->{updates} } = $update;
	}
}


sub update_error {
	my ($self, %args) = @_;
	my $time = $args{'time'} || time();
	my $wait = $args{'wait'} || 1800;
	my $errors = $args{errors} || 0;

	# make sure the file exists
	$self->init();

	my $file = path(join("/", $self->{path}, $self->{files}->{updates}));
	my $update = { };
	if ($self->{sticky} && exists($self->{data}->{ $self->{files}->{updates} })) {
		$update = $self->{data}->{ $self->{files}->{updates} };
	}
	else {
		# retrieve information from storage
		$self->{logger} && $self->{logger}->debug("Load $file (update_error)");
		$update = retrieve($file);
	}

	$update->{next_update} = $time + $wait;
	$update->{last_update} = $time;
	$update->{errors}	= $errors;

	nstore($update, $file) or croak("Cannot save data to $file: $!\n");
	if ($self->{sticky}) {
		$self->{data}->{ $self->{files}->{updates} } = $update;
	}
}


sub get_prefixes {
	my ($self, %args) = @_;
	my @lists = @{ $args{lists} || [] };
	my @hashes = @{ $args{hashes} || [] };
	my @data = ();

	$self->{logger} && $self->{logger}->debug("Number of lists: ", scalar(@lists));
	foreach my $list (@lists) {
		my $db = { };
		if ($self->{sticky} && exists($self->{data}->{ $self->list_to_file($list) })) {
			$db = $self->{data}->{ $self->list_to_file($list) };
		}
		else {
			my $file = path(join("/", $self->{path}, $self->list_to_file($list)));
			if (! -e $file) {
				$self->{logger} && $self->{logger}->debug("File $file does not exist");
				next;
			}

			$self->{logger} && $self->{logger}->debug("Load $file (get_prefixes)");
			$db = retrieve($file);

			if ($self->{sticky}) {
				$self->{data}->{ $self->list_to_file($list) } = $db;
			}
		}

		foreach my $hash (@hashes) {
			my $prefix = undef;
			my $index = binsearch {substr($a, 0, length($b)) cmp $b} $hash, @{$db->{hashes}};
			if (defined($index)) {
				$prefix = $db->{hashes}->[$index];
				push(@data, { prefix => $prefix, list => $list, hash => $hash });
			}
		}
	}

	return @data;
}


sub add_full_hashes {
	my ($self, %args) = @_;
	my @hashes = @{ $args{hashes} || [] };
	my $timestamp = $args{timestamp} || time();


	my $file = path(join("/", $self->{path}, $self->{files}->{full_hashes}));
	my $db = { hashes => [] };
	if ($self->{sticky} && exists($self->{data}->{ $self->{files}->{full_hashes} })) {
		$db = $self->{data}->{ $self->{files}->{full_hashes} };
	}
	elsif (-e $file) {
		$db = retrieve($file);
	}

	foreach my $hash (@hashes) {
		my $cache = $hash->{cache};
		$cache =~ s/s//;
		$self->{logger} && $self->{logger}->debug("cache: $cache");

		$hash->{expire} = $cache + $timestamp;
		push(@{ $db->{hashes} }, $hash);
	}

	$self->{logger} && $self->{logger}->debug("Save ", scalar(@{ $db->{hashes} }), " full hashes to $file");
	nstore($db, $file) or croak("Cannot save data to $file: $!\n");

	if ($self->{sticky}) {
		$self->{data}->{ $self->{files}->{full_hashes} } = $db;
	}

	return (@{ $db->{hashes} });
}


sub get_full_hashes {
	my ($self, %args) = @_;
	my @lists = @{ $args{lists} || [] };
	my $hash = $args{hash} || return ();

	my $db = { };
	if ($self->{sticky} && exists($self->{data}->{ $self->{files}->{full_hashes} })) {
		$db = $self->{data}->{ $self->{files}->{full_hashes} };
	}
	else {
		my $file = path(join("/", $self->{path}, $self->{files}->{full_hashes}));
		if (! -e $file) {
			return ();
		}

		$self->{logger} && $self->{logger}->debug("Load $file");
		$db = retrieve($file);
	}

	my @hashes = ();
	$self->{logger} && $self->{logger}->debug("Number of full hashes on file: ", scalar(@{ $db->{hashes} }));
	foreach my $list (@lists) {
		my $result = first {
			$_->{hash} eq $hash &&
			$_->{list}->{threatEntryType} eq $list->{threatEntryType} &&
			$_->{list}->{threatType} eq $list->{threatType} &&
			$_->{list}->{platformType} eq $list->{platformType} &&
			$_->{expire} > time()
		} @{ $db->{hashes} };

		push(@hashes, $result) if (defined($result));
	}

	return @hashes;
}


sub list_to_file {
	my ($self, $list) = @_;

	return join("_", $list->{threatType}, $list->{platformType}, $list->{threatEntryType}) . ".gsb4";
}


sub close {
	my ($self, %args) = @_;

	if ($self->{keep_all} == 0) {
		return;
	}

	my $file = path(join("/", $self->{path}, $self->{files}->{full_hashes}));
	if (! -e $file) {
		return;
	}

	my $db = retrieve($file);

	my @results = grep { $_->{expire} > time() } @{ $db->{hashes} };
	if (scalar(@results) < scalar(@{ $db->{hashes} })) {
		$db->{hashes} = [@results];
		nstore($db, $file) or croak("Cannot save data to $file: $!\n");
	}

	$self->{data} = { };
}


sub get_lists {
	my ($self, %args) = @_;

	my $file = path(join("/", $self->{path}, $self->{files}->{lists}));
	
	if (! -e $file) {
		return [];
	}
	
	my $db = retrieve($file);
	return $db;
}

sub save_lists {
	my ($self, $lists) = @_;
	
	my $file = path(join("/", $self->{path}, $self->{files}->{lists}));
	nstore($lists, $file) or croak("Cannot save data to $file: $!\n");
}


=head1 CHANGELOG

=over 4

=item 0.1

Initial release

=item 0.3

Add C<get_lists> and C<save_lists> methods.

=item 0.4

Fix typo last_udpate/last_update

=back


=head1 SEE ALSO

See L<Net::Google::SafeBrowsing4> for handling Google Safe Browsing v4.

See L<Net::Google::SafeBrowsing4::Storage> for the list of public functions.

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
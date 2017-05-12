#!/usr/bin/perl

package Net::SNMP::Vendor;

use strict;
use warnings;

use LWP::Simple qw(get);
use DBM::Deep qw(exists);

our $VERSION = sprintf "%d.%02d", q$Revision: 0.01 $ =~ m/ (\d+) \. (\d+) /xg;


use constant IANA_SYSOID_ADDR => 'http://www.iana.org/assignments/enterprise-numbers'; 

use constant DEEP_REPOSITORY => './';
use constant DEEP_IANA_SYSOID_DB => 'sysoid.db';

use constant CACHE => 'CACHE';
use constant DB    => 'DB';

use constant ERROR_SUCCESS                         => 'ERROR_SUCCESS';
use constant ERROR_NO_UPDATE_INFORMATION_AVAILABLE => 'ERROR_NO_UPDATE_INFORMATION_AVAILABLE';
use constant ERROR_COULD_NOT_CREATE_DB             => 'ERROR_COULD_NOT_CREATE_DB';
use constant ERROR_COULD_NOT_LOAD_IANA_LIST        => 'ERROR_COULD_NOT_LOAD_IANA_LIST';
use constant ERROR_SYSOID_STRING_INVALID           => 'ERROR_SYSOID_STRING_INVALID';
use constant ERROR_SYSOID_STRING_UNKNOWN           => 'ERROR_SYSOID_STRING_UNKNOWN';
use constant ERROR_INVALID_CACHE_METHOD            => 'ERROR_INVALID_CACHE_METHOD';

my (
    $_sysoid_cache, # To store the results extracted from the IANA list
);

sub new {
	my ($class) = shift;
	my %args = @_;
	my $self = {};
	
	bless $self, $class;
	
	$self->set_error;
	
	$self->{'type'}        = exists $args{'type'}        ? ($args{'type'} eq CACHE || $args{'type'} eq DB ? $args{'type'} : $self->set_error(ERROR_INVALID_CACHE_METHOD)) : CACHE;
	$self->{'db_dir'}      = exists $args{'db_dir'}      ? $args{'db_dir'}      : DEEP_REPOSITORY;
	$self->{'db_file'}     = exists $args{'db_file'}     ? $args{'db_file'}     : DEEP_IANA_SYSOID_DB;
	$self->{'db_optimize'} = exists $args{'db_optimize'} && $args{'db_optimize'} == 1 ? 1 : 0;
	
	if($self->{'type'} eq DB) {
		#$self->set_error(ERROR_COULD_NOT_CREATE_DB)
		#	unless $_sysoid_cache = DBM::Deep->new(file => $self->{'db_dir'} . $self->{'db_file'}, type => DBM::Deep->TYPE_HASH);
		eval { $_sysoid_cache = DBM::Deep->new(file => $self->{'db_dir'} . $self->{'db_file'}, type => DBM::Deep->TYPE_HASH); };
		$self->set_error(ERROR_COULD_NOT_CREATE_DB) if $@;
		$self->{'type'} = CACHE;
	}
	
	return $self;
}

sub get_lastupdated {
	my $self = shift;
	return $self->set_error(ERROR_NO_UPDATE_INFORMATION_AVAILABLE)
		unless (my $iana_last_update = $_sysoid_cache->{-1}->{'timestamp'});
	return $iana_last_update;
}

sub load_cache {
	my $self = shift;
	my ($iana_ref,
	    $iana_last_updated,
	    $iana_data,
	    @iana_entries,
    	);
	
	return $self->set_error(ERROR_COULD_NOT_LOAD_IANA_LIST)
		unless $iana_data = get(IANA_SYSOID_ADDR);
	
	$iana_data =~ /\(last updated ([\d-]+)\)/;
	$iana_last_updated = $1;
	
	if($self->{'type'} eq DB && $_sysoid_cache->{-1}->{'timestamp'} && $_sysoid_cache->{-1}->{'timestamp'} eq $iana_last_updated) {
		return ERROR_SUCCESS;
	}
	
	# Cut off begin and end of the document and 
	# add an extra delimeter between all entries
	$iana_data =~ /\| \| \| \|/;
	$iana_data = $';
	$iana_data =~ s/\n+[ |\x0d]*/\n/g;
	$iana_data =~ s/\n*End of Document$//g;
	$iana_data =~ s/\n(\d+)\n/\n::=$1\n/g;
	@iana_entries = split /::=/, $iana_data;
	# delete data referenced by $_sysoid_cache
	ref $_sysoid_cache eq 'DBM::Deep::Hash' ? $_sysoid_cache->clear : $_sysoid_cache = undef;
	$_sysoid_cache->{-1}->{'timestamp'} = $iana_last_updated;
	foreach (@iana_entries) {
		if(/^(\d+)\n([^\n]*)\n([^\n]*)\n([^\n]*)/) {
			$_sysoid_cache->{$1}->{'sysObjectID'}    = '1.3.6.1.4.1.' . $1;
			$_sysoid_cache->{$1}->{'id'}             = $1;
			$_sysoid_cache->{$1}->{'vendor'}         = $2;
			$_sysoid_cache->{$1}->{'contact_person'} = $3;
			($_sysoid_cache->{$1}->{'contact_email'} = $4) =~ s/\&/@/g;
		}
	}
	if($self->{'type'} eq DB && $self->{'db_optimize'}) {
		$_sysoid_cache->optimize;
	}
	return ERROR_SUCCESS;
}

sub lookup {
	my $self = shift;
	my %args = @_;
	return $self->set_error(ERROR_SYSOID_STRING_INVALID)
		unless exists $args{'sysoid'} && $args{'sysoid'} =~ /^(\.1\.3\.6\.1\.4\.1\.)?(\d+)/;
	return $self->set_error(ERROR_SYSOID_STRING_UNKNOWN)
		unless my $result_ref = $_sysoid_cache->{$2};
	return $result_ref;
}

sub set_error {
	my ($self, $error, $error_expl) = @_;
	$self->{'error'} = defined $error ? ($error = defined $@ ? $error . ' Reason: ' . $@ : $error) : ERROR_SUCCESS ;
	undef;
}

sub get_error {
	my $self = shift;
	return $self->{'error'};
}

1;
__END__

=head1 NAME

Net::SNMP::Vendor - lookup the Vendor for a sysObjectID based on the
IANA list

=head1 SYNPOSIS
	
	use Net::SNMP::Vendor;
	
	my $sysObjectID = '.1.3.6.1.4.1.0';
	
	my $v = Net::SNMP::Vendor->new;
	$v->load_cache;
	my $vendor = $v->lookup(sysid => $sysObjectID);

=head1 DESCRIPTION

The Internet Assigned Numbers Association (www.iana.org) maintains 
a list of all assgined sysObjectID which can be used to determine
the vendor of a SNMP agent. Futhermore this ID points usually to
an entry in the vendors SMI within the enterprise subtree under
'C<.1.3.6.1.4.1>'.

To obtain the sysObjectID perform a SNMP get_request operation on
the SNMP agent for the following OID 'C<.1.3.6.1.2.1.1.2.0>'. The result
will be as described above a dotted decimal string with the prefix
'C<.1.3.6.1.4>' followed by the vendors identification ID and the vendor
assigned device ID.

You might then either pass the whole string or the extracted vendor
ID to the module as described above. If the ID is assigned and in 
the cache the	module will return a hash reference to a vendor 
object giving all information stored by the IANA for that certain
vendor ID. If the ID is unkown the module will return undef. To
get the cause for the error you might call the C<get_error()>
function.

This module tries to persistently cache with C<DBM::Deep> the vendor
information to avoid obsesive network use. If you prefer not to
store the result persistently you might use C<Net::SNMP::Vendor::CACHE>
in combination with the C<type> option in the constructor. That will
cause the module to store the loaded list within a normal hash reference

NOTE: The result will be lost as soon as the process finishes that created
the hash.

=head1 CONSTRUCTOR

=over 4

=item new ( [type => DB|CACHE, db_dir => DIR, db_file => FILE, db_optimize => Bool] )

Creates and returns a blessed reference to a Vendor object. The
module can be run in two different modes. The recommended mode
is the database mode (set C<type> to C<Net::SNMP::Vendor::DB>) which 
is enabled by default. The other mode is called cache mode 
(set C<type> to C<Net::SNMP::Vendor::CACHE>).

If run in the C<DB> mode the constructor will try to create a 
C<DBM::Deep> database either under 'C<./sysoid.db>' or under the 
location specified through the 'C<db_dir>' and 'C<db_file>' option.
If the creation of the database fails the cause for the error can
be determined calling the C<get_error()> function. In this case the
type option will be set to C<CACHE> automatically.

The C<db_optimize> option can be used to enforce the release of unused
disk space used by the C<DBM::Deep> object. NOTE: Under rare conditions this 
sometimes leads to the loss of data. The feature is disabled by default.

Running in C<CACHE> mode means that the list of loaded sysObjectID
list will be stored temporarily in a hash reference and the list will be lost
when the process finishes.

=back

=head1 METHODS

=over 4

=item load_cache

Loads the list of assigned sysObjectIDs from 
'C<http://www.iana.org/assignments/enterprise-numbers>'.
Depending on the C<type> the result is either stored in a 
C<DBM::Deep> database or in a hash reference. If not initially
loaded the functions first checks if the stored list comply with
the current list loaded before updating the database or cache. If
an error occurred the function will return C<undef>. Else 
C<ERROR_SUCCESS> is returned.

=item lookup(sysoid => sysObjectID)

Tries to lookup the passed sysObjectID. The sysObjectID might be
either passed as the whole dotted decimal string or as an unsigned
integer to the function. If the function succeeds it will return a
hash reference with the sysObjectID corresponding vendor. If not it
will return C<undef>. To determine the error cause call the
C<get_error()> function.

=item get_error

Returns the cause for the last error that occured. If no error
occured it will return C<ERROR_SUCCESS>. If the error was
caused by another module that was called by the Vendor object
there will be additional error information available calling this
function.

=item get_lastupdated

Returns the date in the style YYYY-MM-DD when the loaded and
probably saved list last has been updated by the IANA.

=back

=head1 AUTHOR

Florian Endler C<endler@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Florian Endler.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

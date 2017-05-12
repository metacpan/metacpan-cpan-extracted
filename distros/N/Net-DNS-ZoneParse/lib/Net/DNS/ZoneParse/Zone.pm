package Net::DNS::ZoneParse::Zone;

use strict;
use warnings;
use vars qw($VERSION);
use Net::DNS::ZoneParse;
use base qw(Class::Accessor);

$VERSION = 0.102;

__PACKAGE__->mk_accessors(qw/rr ttl/);

=pod

=head1 NAME

Net::DNS::ZoneParse::Zone - A representation of a given zone.

=head1 SYNOPSIS

  use Net::DNS::ZoneParse::Zone;
  use Net::DNS::RR;

  my $zone = Net::DNS::ZoneParse::Zone->new({ filename => "db.example.com" });
  
  my $newrr = Net::DNS::RR::new({ ... });
  $zone->add($newrr);
  $zone->rr->[-1]->name eq $newrr->name;
  $zone->save;

=head1 DESCRIPTION

Net::DNS::ZoneParse::Zone is the representation of one zonefile, used by
N::D::ZoneParse. It can be used to access and modify all information of
this zone and write them back transperantly.

=head2 METHODS

=head3 new

	$zone = Net::DNS::ZoneParse::Zone->new("example.com" [, $param]);

returns a new Zone-object. The first parameter is the domain-name or origin
of that zone, the optional second is a hash-reference of one or more
of the followin:

=over

=item path

The directory to use as working dir for the file. The current directory, if not
given.

=item filename 

The name of the file to read. If not given, "db." will prepended to the name
of the zone; thus "db.example.com" would be used for "example.com".

=item ttl

The default time to live for the resource records.

=item parent

if given, is the Net::DNS::ZoneParse object, this Zone is derived from

=item dontload

by default, the corresponding zonefile will be loaded on creating the new
zone. If this dontload is true, the zone will start empty.

=back

=cut

sub new {
	my ($self, $zone, $config) = @_;
	$config = {} unless(defined $config);
	my %config = (
		filename =>	($config->{path} || ".")."/".
				($config->{filename} || "db.$zone"),
		zone => $zone,
		ttl => $config->{ttl} || 0,
		parent => $config->{parent},
		rr => [],
	);
	my $zpz = bless(\%config);
	$zpz->load() unless($config->{dontload});
	return $zpz;
}

=pod

=head3 load

	$zone->load()

Will open the corresspondig file and parse it, intializing the array
of resource records

=cut

sub load {
	my ($self) = @_;
	return unless( -f $self->{filename} );
	if($self->{parent}) {
		my %param = (
		       	origin => $self->{zone},
		       	ttl => $self->ttl,
			nocache => 1,
	       	);
		$self->{rr} = $self->{parent}->parse($self->{filename}, \%param);
		$self->{ttl} = $param{ttl} if($param{ttl});
	} else {
		$self->{rr} = Net::DNS::ZoneParse::parse({
			file => $self->{filename}
		});
	}
}

=pod

=head3 save

	$zone->save();

will write back the contents of the zone to the corresponding filename

=cut

sub save {
	my ($self) = @_;
	my $file;
	open($file, ">", $self->{filename});
	print $file $self->string;
	close $file;
}

=pod

=head3 string

	$zonetext = $zone->string();

string will return the contents of a zonefile representing the current state of
the zone.

=cut

sub string {
	my ($self) = @_;
	if($self->{parent}) {
		return $self->{parent}->writezone($self->{zone});
	} else {
		return Net::DNS::ZoneParse::writezone($self->rr, {
					origin => $self->{zone},
					ttl => $self->ttl,
				});
	}
}

=pod

=head3 add

	$zone->add($rr)

add can be used to add further resource records to the zone

=cut

sub add {
	my $self = shift;
	my $lnr = 0;
	my $rr = ${$self->rr}[-1];
	$lnr = $rr->{Line} if $rr->{Line};

	$rr = $_[0];
	$rr = [ @_ ] if(ref($rr) ne "ARRAY");
	map {
		if($_->{Line}) {
			$lnr = $_{Line};
		} else {
			$lnr+=1;
			$_->{Line} = $lnr
		} 
	} @{$rr};
	push(@{$self->rr}, @{$rr});
}

# returns a generic search routine depending on the given argumenttype
sub _findffunc {
	my ($rr) = @_;

	return sub { $_[0]->string ne $_[1]->string } if(ref($rr) eq "Net::DNS::RR");
	return sub {
		my $item = $_[0];
		for(keys(%{$_[1]})) {
			return 1 if($_[1]->{$_} ne $_[0]->{$_});
		}
		return undef;
	} if(ref($rr) eq "HASH");
	return 1;
}

=pod

=head3 delete

	$zone->delete($rr)

deletes the given RR from the zone. If no RR is given, the zone will be purged.
The RR can either be given as a Net::DNS::RR-object, in this case, the 
string representation of the record is compared to find the correct one.
As an alternative a HASH-reference can be used, to filter for a set of RRs. In
this case all keys of the hash must be found and equal in the RR.

=cut

sub delete {
	my ($self, $rr) = @_;
	unless($rr) {
		$self->{rr} = [];
		return;
	}
	my $ffunc = _findffunc($rr);

	$self->{rr} = [ grep &$ffunc($_,$rr), @{$self->{rr}} ];
}

=pod

=head3 replace

	$zone->replace($old, $new)

Replaces all RRs of the zone matching $old by the Net::DNS::RR-object given in
$new. $old is handled in the same way as $rr in the delete-method. If $new
is not given, replace behaves exactly like delete.

=cut

sub replace {
	my ($self, $rr, $new) = @_;
	return unless($rr);
	return $self->delete($rr) unless($new);
	my $ffunc = _findffunc($rr);
	$self->{rr} = [ map { &$ffunc($_,$rr)? $_ :$new } @{$self->{rr}}];
}

=head3 delall

	$zone->delall();

Deletes all parsed resource records and deletes the corresponding zonefile from
disk.

=cut

sub delall {
	my ($self) = @_;

	unlink($self->{filename})
       		if($self->{filename} and -f $self->{filename});
	$self->{rr} = [];
	$self->{parent}->uncache($self->{zone}) if($self->{parent});
}

=head1 SEE ALSO

Net::DNS::ZoneParse

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;


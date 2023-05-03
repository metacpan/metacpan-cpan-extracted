package NOLookup::RDAP::RDAPLookup::Whois;

use warnings;
use strict;
use POSIX qw(locale_h);
use base qw(NOLookup::RDAP::RDAPLookup); 
use NOLookup::RDAP::RDAPLookup qw / $RDAP_LOOKUP_ERR_NO_MATCH /;
use NOLookup::Whois::WhoisLookup;

use Data::Dumper;
$Data::Dumper::Indent=1;

our $VERSION = $NOLookup::VERSION;

=head2 result_as_norid_whois_string

Format result as old style Norid whois output.

Uses internal helper formatting functions.

=cut

sub result_as_norid_whois_string {
    my ($self, $check, $nameservers, $entity, $expand, $lookup_reg_ent) = @_;

    my (@errors, $errs);

    my $rs = "";

    # A check has no data, let the caller handle it.
    return if ($check);
    
    my $response = $self->result;

    if ($response->isa('Net::RDAP::Error')) {
	push(@errors, sprintf("%03u (%s)", $response->errorCode, $response->title));
	return $rs, \@errors;
    }

    ($rs, $errs) = $self->rdap_notice_as_norid_whois_string($response);

    if ($response->isa('Net::RDAP::SearchResult')) {

	my $ix = 0;
	foreach my $nso ($response->nameservers) {
	    my ($rst, $errs) = $self->rdap_ns_obj_as_norid_whois_string($nso, $ix, $check, $nameservers, $entity);
	    $rs .= $rst if ($rst);
	    push @errors, @$errs if ($errs && @$errs);
	    ++$ix;
	}

	$ix = 0;
	foreach my $do ( $response->domains) {
	    my ($rst, $errs) =
		$self->rdap_domain_obj_as_norid_whois_string($do, $ix, $check, $nameservers, $entity, 1, $expand);
	    $rs .= $rst if ($rst);
	    push @errors, @$errs if ($errs && @$errs);
	    ++$ix;
	}

	$ix = 0;
	foreach my $o ($response->entities) {
	    my ($rst, $errs) =
		$self->rdap_entity_obj_as_norid_whois_string($o, $ix, $check, $nameservers, $entity, 1, $expand);
	    $rs .= $rst if ($rst);
	    push @errors, @$errs if ($errs && @$errs);
	    ++$ix;
	}

    } elsif ($response->class eq 'nameserver') {

	my ($rst, $errs) = $self->rdap_ns_obj_as_norid_whois_string($response, 0, $check, $nameservers, $entity);
	$rs .= $rst if ($rst);
	push @errors, @$errs if ($errs && @$errs);

    } elsif ($response->class eq 'entity') {

	#print STDERR "** AN ENTITY OBJ: ix: 0, ",
	#    ", ns    : ", $nameservers || 0,
	#    ", entity: ", $entity || 0,
	#    ", search: ", 0,
	#    ", expand: ", $expand || 0,
	#    "\n";

	my ($rst, $errs) = $self->rdap_entity_obj_as_norid_whois_string($response, 0, $check, $nameservers, $entity, 0, $expand);
	$rs .= $rst if ($rst);
	push @errors, @$errs if ($errs && @$errs);

    } elsif ($response->class eq 'domain') {
	my ($rst, $errs) = $self->rdap_domain_obj_as_norid_whois_string($response, 0, $check, $nameservers, $entity, 0, $expand);
	$rs .= $rst if ($rst);
	push @errors, @$errs if ($errs && @$errs);

    } else {
	die "Unexpected response class, please report it as a bug!";
    }
    
    return $rs, \@errors;

}

=head2 rdap_ns_obj_as_norid_whois_string

Return whois formatted string.

=cut

sub rdap_ns_obj_as_norid_whois_string {
    my ($self, $nso, $ix, $check, $nameservers, $entity) = @_;

    my (@errors, @wa);

    unless ('nameserver' eq $nso->class) {
	push @errors, "No nameserver object";
	return undef, \@errors;
    }

    if ($ix == 0) {
	# add whois object header
	push @wa, "";
	push @wa, "";
	if ($nameservers) {
	    # Multiple nameserver objects
	    push @wa, "Hosts matching the search parameter";
	    rdap_page_info_as_norid_whois_string($self, \@wa);
	} else {
	    # single NS
	    push @wa, "Host information";
	}
    }
    push @wa, "";

    if ($self->is_a_search) {
	my $cnt = $ix+1;
	push @wa, "[$cnt]";
    }
    push @wa, "NORID Handle...............: " . $nso->handle;

    ##
    # $nso is a single nameserver, present the name
    #print "RDL: NSO single: ", Dumper $nso;
	
    my ($name, $xname) = $self->rdap_get_obj_name($nso);

    push @wa, "Name Server Hostname.......: " . $name;

    if ($xname ne $name) {
	# Not likely to have this for an ns under .no,
	# since ace coded ns is not allowd.
	push @errors, "Unexpected nameserver ACE name";
	push @wa, "ACE Name Server Hostname...: " . $xname;
    }
    
    my @addrs = $nso->addresses;
    if (scalar(@addrs) > 0) {
	foreach my $ip (@addrs) {
	    push @wa, "Name Server IP-address.....: " . $ip->ip;
	}
    }
    
    my @ent = $nso->entities;
    if (scalar(@ent) > 0) {
	foreach my $en (@ent) {
	    my @roles = $en->roles;
	    if (scalar(@roles)) {
		my $role = $roles[0];
		if ($role eq 'registrar') {
		    push @wa, "Registrar Handle...........: " . uc($en->handle);
		} elsif ($role eq 'technical') {
		    push @wa, "Tech-c Handle..............: " . $en->handle;
		}
	    }
	}
    }

    push @wa, "";

    # Add Additional dates only if single ns
    unless ($nameservers) {
	my @events = $nso->events;
	if (scalar(@events)) {
	    push @wa, "Additional information:";
	    my ($create_date, $update_date);
	    foreach my $event (@events) {
		# DateTime object is UTC, convert to localtime
		my $to = $event->date;
		$to->set_time_zone('Europe/Oslo');
		
		if ($event->action eq 'registration') {
		    $create_date = substr(scalar($to->date), 0, 10);
		    push @wa, "Created:         " . $create_date;
		} else {
		    push @wa, "Last updated:    " . substr(scalar($to->date), 0, 10);
		    $update_date = 1;
		}
	    }
	    unless ($update_date) {
		# Dispay update as same as create when not yet updated
		push @wa, "Last updated:    " . $create_date;
	    }
	}
	
	push @wa, "";
    }
    
    return join("\n", @wa), \@errors;;

}

=head2 rdap_notice_as_norid_whois_string

Return whois formatted string.

=cut

sub rdap_notice_as_norid_whois_string {
    my ($self, $response) = @_;

    my (@errors, @wa);
    
    my @notices = $response->notices;

    if (scalar(@notices) > 0) {
	foreach my $notice (@notices) {

	    push @wa, $notice->title . ":";

	    foreach my $link ($notice->links) {
		push @wa, $link->href->as_string;
	    }
	    push @wa, "";
	    push @wa, $notice->description;
	}
    }
    return '% ' . join("\n% ", @wa), \@errors;
}

=head2 rdap_entity_obj_as_norid_whois_string

Return whois formatted string.

$search indicates if a search is done, in which case the entity is a
set of at least one.

The header if built differently dependent of $nameservers and $search.

$lookup_reg_ent triggers lookup of registrar entity, if missing.

=cut

sub rdap_entity_obj_as_norid_whois_string {
    my ($self, $eo, $ix, $check, $nameservers, $entity, $search, $expand, $lookup_reg_ent) = @_;

    my (@errors, @wa, @doms);

    #print STDERR "ENTITY OBJ map2whois: ix: $ix, ns: ", $nameservers || 0,
    #	", entity        : ", $entity || 0,
    #	", search        : ", $search || 0,
    #	", expand        : ", $expand || 0,
    #	", lookup_reg_ent: ", $lookup_reg_ent || 0,
    #	"\n";
    
    unless ($eo->isa('Net::RDAP::Object::Entity')) {
	push @errors, "Not an entity isa object";
	return undef, \@errors;
    }

    unless ('entity' eq $eo->class) {
	push @errors, "No entity object";
	return undef, \@errors;
    }

    # TODO: Type of entity needs to be checked dependene of type/identity
    push @wa, "";
    push @wa, "";

    #print STDERR "rdap_entity_obj_as_norid_whois_string(), eo: ", Dumper $eo, "\n";

    # If there are entities inside an entity, it carries the registrar info,
    # if not, it is a registrar entity directly
    my @ent = $eo->entities;
    my $handle = $eo->handle;
    my $htype = $self->norid_handle_type($handle);

    if ($ix == 0) {
	if ($search) {
	    push @wa, "Contacts matching the search parameter";
	    rdap_page_info_as_norid_whois_string($self, \@wa);
	} else {
	    push @wa, ucfirst($htype) . " Information";
	}
	push @wa, "";
    }
    if ($search) {
	my $cnt = $ix+1;
	push @wa, "[$cnt]";
    }

    #print STDERR "ENTITY REG map2whois\n";
    #print STDERR "  number ent found: ", scalar(@ent), "\n";

    if ($htype eq 'registrar') {
	push @wa, "Registrar Handle...........: " . uc($handle);

    } else {
	push @wa, "NORID Handle...............: " . uc($handle);

	if (($lookup_reg_ent || $search) && !@ent && ($expand || $entity)) {

	    $self->rdap_get_entities_by_entity_handle($handle, $check,
					       $nameservers, \@ent, \@errors);
	}

        if (scalar(@ent) > 0 && ($expand || $entity) &&
	    ($htype eq 'organization' || $htype eq 'person')) {

	    $self->rdap_get_domains_by_entity_handle($handle, $check,
					      $nameservers, \@doms, \@errors);
	}
    }

    foreach my $en (@ent) {
	#print STDERR "en: ", Dumper $en, "\n";
		
	my $ehandle = $en->handle;
	my $ehtype  = $self->norid_handle_type($ehandle);
	die "Unexpected ehandle type here: '$ehtype' for $ehandle" if ($ehtype ne 'registrar');
		
	my @roles = $en->roles;

	#print STDERR "en role: ", Dumper \@roles, "\n";

	if (scalar(@roles)) {
	    my $role = $roles[0];
	    if ($role eq 'registrar') {
		push @wa, "Registrar Handle...........: " . uc($ehandle);
	    } elsif ($role eq 'technical') {
		push @wa, "Tech-c Handle..............: " . $ehandle;
		die "Unexpected combination for role $role - only registrar expected here";
	    } else {
		die "Unexpected combination for role $role - only registrar expected here";
	    }
	}
    }

    #print STDERR "eo: ", Dumper $eo, "\n";

    my @ids = $eo->ids;
    if (scalar(@ids)) {
	foreach my $id (@ids) {
	    if ($id->type) {
		if ($id->type eq 'Norwegian organization number') {
		    push @wa, "Id Type....................: organization_number";
		} elsif ($id->type eq 'Norid local identifier') {
		    push @wa, "Id Type....................: local_id_number";
		} elsif ($id->type eq 'Norid person identifier') {
		    push @wa, "Id Type....................: anonymous_person_identifier";
		} elsif ($id->type eq 'Norid registrar ID') {
		    push @wa, "Id Type....................: local_registrar_identifier";
		}
	    }
	    if ($id->identifier) { 
		push @wa, "Id Number..................: " . $id->identifier;
	    }
	}
    }
    #print "ENTITY OBJ \n";

    my @cards = $eo->vcard;

    if (scalar(@cards)) {
	foreach my $card (@cards) {
	    # @cards may contain a single undef entry if no cards were found 
	    next unless $card;
	    my ($vcs, $errs) = $self->rdap_vcard_as_norid_whois_string($card, $htype, $eo);
	    push @wa, $vcs if $vcs;

	    push @errors, @$errs if ($errs && @$errs);
	}
    }

    #push @wa, "" unless ($search);

    # Dates not presented in whois for a reg handle.
    unless ($htype eq 'registrar') {
	if ($eo->events) {
	    my ($evs, $errs) = $self->rdap_events_as_norid_whois_string($eo);
	    if ($evs) {
		push @wa, "";
		push @wa, $evs; 
	    }
	    push @errors, @$errs if ($errs && @$errs);
	}
    }

    # List the domains when relevant
    if (scalar(@doms)) {
	my $ds = "";
	my @dns;

	foreach my $dom (@doms) {

	    my ($name, $xname) = $self->rdap_get_obj_name($dom);

	    if ($xname) {
		push @dns, $xname;
	    } else {
		push @dns, $name; 
	    }
	}

	# extend domain list with both total number and domain list
	if (@dns) {
	    push @wa, "";
	    push @wa, "Total Number of Domains....: " . scalar(@doms);
	    push @wa, "Domains....................: " . join(" ", sort(@dns));
	    push @wa, "";
	}
    }

    #print "ENTITY OBJ DONE\n";
    
    return join("\n", @wa), \@errors;

}


=head2 rdap_domain_obj_as_norid_whois_string

Return whois formatted string.

  $search indicates if a search is done, in which case the domain obj is a
  set of at least one. 

  $expand indicates if extra lookup for registrar info should be made,
  since registrar info may not be included.

  The header if built differently dependent of $nameservers and $search.

=cut

sub rdap_domain_obj_as_norid_whois_string {
    my ($self, $do, $ix, $check, $nameservers, $entity, $search, $expand, $lookup_reg_ent) = @_;

    #print STDERR "ix: $ix, rdap_domain_obj_as_norid_whois_string()\n";

    my (@errors, @wa);

    unless ($do->isa('Net::RDAP::Object::Domain')) {
	push @errors, "Not a domain isa object";
	return undef, \@errors;
    }
    
    unless ('domain' eq $do->class) {
	push @errors, "No domain class object";
	return undef, \@errors;
    }
    
    push @wa, "";
    push @wa, "";

    # If there are entities inside a domain object, they carry
    # the registrar info, holder, tech info.
    # If not, it is a registrar entity directly

    my $handle = $do->handle;
    my $htype = $self->norid_handle_type($handle);

    if ($ix == 0) {
	if ($search) {
	    # This search did not exist in the old whois
	    push @wa, "Domains matching the search parameter";
	    rdap_page_info_as_norid_whois_string($self, \@wa);
	} else {
	    push @wa, ucfirst($htype) . " Information";
	}
	push @wa, "";
    }
    if ($search) {
	my $cnt = $ix+1;
	push @wa, "[$cnt]";
    }

    push @wa, "NORID Handle...............: " . uc($do->handle);

    my ($name, $xname) = $self->rdap_get_obj_name($do);

    #print STDERR "Doman name is '$name'\n";

    push @wa, "Domain Name................: " . $xname;
	
    if ($xname ne $name) {
	# Not likely to have this for an ns under .no,
	# since ace coded ns is not allowd.
	    push @wa, "ACE Domain Name............: " . $name;
    }

    my $hoe;
    
    my @ent = $do->entities;

    if ($search && !@ent && ($expand || $entity)) {
	#print STDERR "DOMAIN obj, but no embedded entities, lookup entity on domain name: '$name'\n";

	$self->rdap_get_entities_by_domain_name($name, $check,
					 $nameservers, \@ent, \@errors);
    }

    if (scalar(@ent) > 0) {

	#print STDERR "DOMAIN obj, embedded entities found\n";
	#print STDERR "  ent's: ", Dumper \@ent, "n";
	
	my (@ha, @ta, @ra);
	foreach my $en (@ent) {
	    my @roles = $en->roles;
	    if (scalar(@roles)) {
		my $role = $roles[0];
		if ($role eq 'registrar') {
		    push @ra, "Registrar Handle...........: " . uc($en->handle);
		} elsif ($role eq 'technical') {
		    push @ta, "Tech-c Handle..............: " . $en->handle;
		} elsif ($role eq 'registrant') {
		    push @ha, "Domain Holder Handle.......: " . $en->handle;
		    $hoe = $en;

		} else {
		    die "unexpected role: $role";
		}
	    }
	}
	push @wa, @ha if (@ha);
	push @wa, @ra if (@ra);
	push @wa, @ta if (@ta);
    }

    my @ns = $do->nameservers;
    if (scalar(@ns) > 0) {
	foreach my $ns (sort { lc($a->name->name) cmp lc($b->name->name) } @ns) {
	    push @wa, "Name Server Handle.........: " . $ns->handle;
	    #push @wa, "Name Server Handle.........: " . $ns->handle . " (" . $ns->name->name . ")";    
	}
    }

    my @ds = $do->ds;
    if (scalar(@ds) > 0) {
	push @wa, "DNSSEC.....................: Signed";    

	my $ix = 1;
	foreach my $ds (@ds) {
	    push @wa, "DS Key Tag     $ix...........: " . $ds->keytag;
	    push @wa, "Algorithm      $ix...........: " . $ds->algorithm;
	    push @wa, "Digest Type    $ix...........: " . $ds->digtype;
	    push @wa, "Digest         $ix...........: " . $ds->digest;
	    ++$ix;
	}
    }

    # Keys are not expected for .no, but hey, present them
    my @keys = $do->keys;
    if (scalar(@keys) > 0) {
	push @wa, "DNSSEC Keys";    
	foreach my $key (@keys) {
	    push @wa, "Key Name      $ix..........: " . $key->name;
	    push @wa, "Key Flags     $ix..........: " . $key->flags;
	    push @wa, "Key Protocol  $ix..........: " . $key->protocol;
	    push @wa, "Key Algorithm $ix..........: " . $key->algorithm;
	    push @wa, "Key Key       $ix..........: " . $key->key;
	}
    }

    unless ($search) {
	push @wa, "";
    
	my @events = $do->events;
	if (scalar(@events)) {
	    push @wa, "Additional information:";
	    my ($create_date, $update_date);
	    foreach my $event (@events) {
		# DateTime object is UTC, convert to localtime
		my $to = $event->date;
		$to->set_time_zone('Europe/Oslo');

		if ($event->action eq 'registration') {	
		    $create_date = substr(scalar($to->date), 0, 10);
		    push @wa, "Created:         " . $create_date;
		} else {
		    push @wa, "Last updated:    " . substr(scalar($to->date), 0, 10);
		    $update_date = 1;
		}
	    }
	    unless ($update_date) {
		# Dispay update as same as create when not yet updated
		push @wa, "Last updated:    " . $create_date;
	    }
	}
    }

    if ($hoe && !$search) {
	# We have the domain info above, attach registrant/holder info
	# to simulate the output from Norid whois on a domain lookup.

	#print STDERR "hoe entity as norid string\n";
	#print STDERR "hoe entity, self: ", Dumper $self;

	my ($rst, $errs) = $self->rdap_entity_obj_as_norid_whois_string($hoe, 0, $check, $nameservers, 1, 0, $expand, 0);

	push @wa, $rst if ($rst);
	push @errors, @$errs if ($errs && @$errs);
    }

    return join("\n", @wa), \@errors;

}

=head2 rdap_events_as_norid_whois_string

Format events as norid whois string.

=cut

sub rdap_events_as_norid_whois_string {
    my ($self, $eo) = @_;

    my (@errors, @wa);

    my @events = $eo->events;
    
    if (scalar(@events)) {
	push @wa, "Additional information:";
	my ($create_date, $update_date);
	foreach my $event (@events) {
	    # DateTime object is UTC, convert to localtime
	    my $to = $event->date;
	    $to->set_time_zone('Europe/Oslo');

	    if ($event->action eq 'registration') {
		$create_date = substr(scalar($to->date), 0, 10);
		push @wa, "Created:         " . $create_date;
	    } else {
		push @wa, "Last updated:    " . substr(scalar($to->date), 0, 10);
		$update_date = 1;
	    }
	}
	unless ($update_date) {
	    # Dispay update as same as create when not yet updated
	    push @wa, "Last updated:    " . $create_date;
	}
    }
    return join("\n", @wa), \@errors;
}

=head2 rdap_vcard_as_norid_whois_string

Format vcard object(s) as whois string.

Ref. https://tools.ietf.org/html/rfc6350#section-6.3.1 to see order of
things.

=cut

sub rdap_vcard_as_norid_whois_string {
    my ($self, $card, $type, $eo) = @_;

    unless ($eo) {
	die "VCARD eo is missing as argument";
    }
    unless ($eo->isa('Net::RDAP::Object::Entity')) {
	die "VCARD eo is not an entity object";
    }

    my (@errors, @wa);

    if ($type eq 'registrar') {
	push @wa, "Registrar Name.............: " . $card->full_name if ($card->full_name);

    } else {
	push @wa, "Type.......................: " . $type;

	if ($type eq 'organization') {
	    # When full layer access is configured, two names should be present in the card:
	    #   - the legal name should be found in fn
	    #   - the org. name should be in the 'organization' field.
	    push @wa, "Organization Name..........: " . $card->organization if ($card->organization);
	}
	push @wa, "Name.......................: " . $card->full_name if ($card->full_name);
    }

    my @addresses = @{$card->addresses};
    if (scalar(@addresses) > 0) {

	foreach my $address (@addresses) {
	    my @lines;
	    my $ix = 0;
	    foreach my $element (@{$address->{'address'}}) {
		my @val = ('ARRAY' eq ref($element) ? @{$element} : $element);

		foreach my $al (@val) {
		    next unless $al;

		    if ($ix < 3) {
			if ($type eq 'registrar') {
			    # 0: PoBox, 1: extended address, 2: street address 
			    push @wa, "Address....................: " . $al;
			} else {
			    push @wa, "Post Address...............: " . $al;
			}
			
		    } elsif ($ix == 3) {
			# city: GDPR layer only
			push @wa, "Postal Area................: " . $al;

		    } elsif ($ix == 4) {
			# region, not used by us?
			push @wa, "Postal Region..............: " . $al;

		    } elsif ($ix == 5) {
			# pcode / zip : GDPR layer only
			push @wa, "Postal Code................: " . $al;
		    } elsif ($ix == 6) {
			# pcode / zip
			push @wa, "Country....................: " . $al;
			
		    } else {
			die "Should not end at this index $ix";
		    }
		}
		++$ix;
	    }
	   
	}
    }

    foreach my $number (@{$card->phones}) {

	my @types = ('ARRAY' eq ref($number->{'type'}) ? @{$number->{'type'}} : ($number->{'type'}));

	# Separate between fax, voice and cell phone
	my $type = 'voice';
	foreach my $t (@types) {
	    $t = lc($t);
	    if ($t eq 'fax' || $t eq 'cell') {
		$type = $t;
		last;
	    }	    
	}

	# strip the 'tel:' prefix
	my $no = $number->{'number'};
	$no =~ s/^tel://;

	if ($type eq 'fax') {
	    push @wa, "Fax Number.................: $no";
	} elsif ($type eq 'voice') {
	    push @wa, "Phone Number...............: $no";
	} elsif ($type eq 'cell') {
	    push @wa, "Mobile Phone Number........: $no";
	}
    }

    my $ix = 0;
    foreach my $email (@{$card->email_addresses}) {
	if ($email->{'type'}) {
	    # Do not know when I get here, so die till we know
	    die "what is this email type? " . Dumper $email->{'type'};
	}
	if ($ix == 0) {
	    push @wa, "Email Address..............: " . $email->{'address'};
	} else {
	    push @wa, "Additional Email...........: " . $email->{'address'};
	}
	++$ix;
    }

    # Hack: Web address (url) for an entity is not supported via the card
    # object, ref. code for vcard() in
    # https://metacpan.org/source/GBROWN/Net-RDAP-0.14/lib/Net/RDAP/Object/Entity.pm
    # which does not process the url info.
    #
    # Therefore just fetch the url from inside the $eo instead.
    #
    # TODO: This should be fixed in Net::RDAP::Object::Entity, a bug
    #       report has been filed with a request for support.
    #       (Could also be fixed by local subclassing here, but we
    #        prefer a central fix)
    #
    my $vca = $eo->{vcardArray};

    if ($vca && $vca->[0] && $vca->[0] eq 'vcard' && $vca->[1]) {
	foreach my $vc (@{$vca->[1]}) {
	    if ($vc->[0] && $vc->[0] eq 'url') {
		if ($vc->[0] && $vc->[0] eq 'url' &&
		    $vc->[2] && $vc->[2] eq 'uri' && 
		    $vc->[3]) {
		    push @wa, "Web Address................: " . $vc->[3];
		}
	    }
	}
    }
   
    return join("\n", @wa), \@errors;
}

=head2 rdap_page_info_as_norid_whois_string

Format and insert page info, if requested.

=cut

sub rdap_page_info_as_norid_whois_string {
    my ($self, $wa) = @_;

    #print STDERR "rdap_page_info_as_norid_whois_string() called\n";

    return unless ($self->{insert_page_info});

    my $nopages_int = $self->total_no_pages || 1;

    #print STDERR "rdap_page_info_as_norid_whois_string() inserting\n";
    #print STDERR "page_size  : ", $self->page_size, "\n";
    #print STDERR "total_size : ", $self->total_size, "\n";
    #print STDERR "page_number: ", $self->page_number, "\n";
    #print STDERR "nopages_int: $nopages_int\n";

    push @$wa, "";
    push @$wa, "Page Number................: " . ($self->page_number || 1) . "/$nopages_int";
    push @$wa, "Number Of Hits Shown.......: " . $self->size;
    push @$wa, "Number Of Total Hits.......: " . $self->total_size;

    return if ($self->size == $self->total_size);

    # cur_page not interesting as I see it?
    if ($self->first_page) {
	#print STDERR " first_page: ", $self->first_page, "\n";
    	push @$wa, "First Page.................: " . $self->first_page;
    }
    if ($self->cur_page) {
	#print STDERR " cur_page: ", $self->cur_page, "\n";
    	push @$wa, "Current Page...............: " . $self->cur_page;
    }
    if ($self->prev_page) {
	#print STDERR " prev_page: ", $self->prev_page, "\n";
	push @$wa, "Previous Page..............: " . $self->prev_page;    
    }
    
    if ($self->size < $self->total_size && $self->next_page) {
	#print STDERR " next_page: ", $self->next_page, "\n";
	push @$wa, "Next Page..................: " . $self->next_page;
    }
}


=head2 norid_whois_parse

Convert a whois formatted result string to a whois object the same way
as NOLookup::Whois::WhoisLookup does.

Returns ($wh, $do, $ho), all NOLookup::Whois::WhoisLookup objects.

=cut

sub norid_whois_parse {
    my ($self, $text) = @_;

    my ($wh, $do, $ho);
    
    # Parse whois and map values into objects.
    $wh = NOLookup::Whois::WhoisLookup->new;
    $wh->_parse($text);

    # Also include do and ho if present 
    if ($text =~ m/\nDomain Information\n/) {
	
	# If a domain name, or a domain handle, is looked up, the
	# whois server may also return the holder info as a second
	# block. The below code parses the domain and holder info and
	# returns the data in separate objects.
	#
	
	# Domain info is first block. Holder contact info is second
	# block, but only if the full (but limited) registrarwhois
	# service is used. Split the text and make two objects.
	
	my ($dmy, $dtxt, $htxt) = split ('NORID Handle', $text);

	$do = NOLookup::Whois::WhoisLookup->new;

	#print STDERR "\n------\nparse domain text: '$dtxt'\n";
	$do->_parse("\nNORID Handle" . $dtxt);

	if ($htxt) {
	    $ho = NOLookup::Whois::WhoisLookup->new;
	    #print STDERR "\n------\nparse holder text: '$htxt'\n";
	    $ho->_parse("\nNORID Handle" . $htxt);
	}
	#print STDERR "wh: ", Dumper $wh if ($wh);
	#print STDERR "do: ", Dumper $do if ($do);
	#print STDERR "ho: ", Dumper $ho if ($ho);

	return $wh, $do, $ho;

    } 

    if ($text =~ m/\nHosts matching the search parameter\n/) {
	# Set a method telling that a name_server_list is found,
	# which is only the case when a host name is looked up.
	$wh->{name_server_list} = 1;
    }

    #print STDERR "\n\n====\nwh after $query: ", Dumper $wh;
    return $wh;

}

=head2 rdap_get_domain_object_as_whois

Scan domain object and do the rdap2whois on it.

$result must point to a domain result.

=cut

sub rdap_get_domain_object_as_whois {
    my ($self, $result) = @_;

    #print STDERR "rdap_get_domain_object_as_whois()\n";

    my @errors;
    
    # We expect only a domain name result
    unless ($result->isa('Net::RDAP::Object::Domain')) {
	push @errors, "Not an Net::RDAP::Object::Domain object";
	return undef, \@errors;
    }
    unless ($result->class eq 'domain') {
	push @errors, "Not a 'domain' class";
	return undef, \@errors;
    }

    my ($rst, $errs) = $self->rdap_domain_obj_as_norid_whois_string($result, 0);

    unless ($rst) {
	push @errors, "No whois string, not able to build domain_object_as_whois";
	push @errors, @$errs if ($errs && @$errs);
	return undef, \@errors;
    }

    my ($wh, $do) = $self->norid_whois_parse($rst);

    return $do, \@errors;

}

=head2 rdap_get_entity_objects_as_whois

Scan registrant, registrar and tech entity objects and do the rdap2whois on them.

=cut

sub rdap_get_entity_objects_as_whois {
    my ($self, $result) = @_;
    
    my ($ho, $regobj, @tcs, @errors);

    # Collect domain contact entities, registrant, registrar and tech-c's.
    my @ent = $result->entities;
    
    my $ix = 0;
    if (scalar(@ent) > 0) {
	$ix = 0;
	foreach my $en (@ent) {
	    my ($rst, $errs) = $self->rdap_entity_obj_as_norid_whois_string($en, $ix);
	    unless ($rst) {
		push @errors, "No whois string, not able to build entity_objects_as_whois";
		push @errors, @$errs if ($errs && @$errs);
		next;
	    }

	    ++$ix;
	    my $eo = $self->norid_whois_parse($rst);
	    
	    my @roles = $en->roles;
	    if (scalar(@roles)) {
		my $role = $roles[0];

		#print STDERR "ROLE: $role\n";

		if ($role eq 'registrar') {
		    $regobj = $eo;
		} elsif ($role eq 'technical') {
		    push @tcs, $eo;
		} elsif ($role eq 'registrant') {
		    $ho = $eo;
		} else {
		    # unexpected role
		    push @errors, "Unexpected role: $role, technical, registrar or registrant expected!";
		}
	    }
	}
    }
    return $ho, $regobj, \@tcs, \@errors;
}

=head2 rdap_get_nameserver_objects_as_whois

Scan NS objects and do the rdap2whois on them.

=cut

sub rdap_get_nameserver_objects_as_whois {
    my ($self, $result) = @_;

    my (@nss, @zcs, %zeen, @errors);

    my $ix = 0;
    
    foreach my $nso ($result->nameservers) {

	#print STDERR "convert nameserver: ", Dumper $nso;
	
    	my ($rst, $errs) = $self->rdap_ns_obj_as_norid_whois_string($nso, $ix);
	next unless $rst;
	unless ($rst) {
	    push @errors, "No whois string, not able to build nameserver_objects_as_whois";
	    push @errors, @$errs if ($errs && @$errs);
	    next;
	}

	++$ix;
	my $wnso = $self->norid_whois_parse($rst);

	# ns tech contact is contained as an entity inside the NS object,
	# there should be only one contact in the current NO data model.
	my @ent = $nso->entities;

	#print "ns ent array: ", Dumper \@ent;
	if (scalar(@ent) > 0) {
	    $ix = 0;
	    foreach my $en (@ent) {
		next unless $en;

		#print STDERR "ns entity obj: ", Dumper $en;
		my $nsh = $en->handle;

		if ($ix > 1) {
		    push @errors, "Unexpected number of tech-contacts ($ix) for name server: $nsh!";
		}

		my ($rst, $errs) = $self->rdap_entity_obj_as_norid_whois_string($en, $ix);
		unless ($rst) {
		    push @errors, "No whois string, not able to build nameserver tech entity objects_as_whois";
		    push @errors, @$errs if ($errs && @$errs);
		    next;
		}

		++$ix;
		my $eo = $self->norid_whois_parse($rst);
		 
		my @roles = $en->roles;
	
		if (scalar(@roles)) {
		    my $role = $roles[0];
		    if ($role eq 'technical') {
			$wnso->{tech_c_name} = $eo->name;
			$wnso->{tech_c_type} = $eo->type;
			push @zcs, $eo if ($eo && !$zeen{$nsh});
			$zeen{$nsh} = 1;
		    } else {
			# unexpected role for an ns contact
			push @errors, "Unexpected ns object tech role: $role, technical expected!";
		    }
		}
	    }
	}
	push @nss, $wnso if ($wnso);
    }

    return (\@nss, \@zcs, \@errors);
    
}


=pod

=encoding ISO-8859-1

=head1 NAME

NOLookup::RDAP::RDAPLookup::Whois

Offer a number of utility whois methods to simulate an
rdap2whois world, building output and objects as the old whois
formatted service.

=head1 SYNOPSIS

    use Encode;
    use NOLookup::RDAP::RDAPLookup::Whois;
 
    # Default API service URL
    my $SERVICE_URL = "https://rdap.norid.no";

    # Example 1: Domain name lookup
    # Decode the query when needed, like for IDNs
    # or names with national characters.

    my $q = 'norid.no';
    #$q = decode('ISO8859-1', 'øl.no');

    my $bo = NOLookup::RDAP::RDAPLookup->new(
     {
	service_url         => 'https://rdap.norid.no',
	debug               => 0,
	use_cache  	    => 0,
	norid_header_secret => 'secret1234',
	norid_header_proxy  => 1,
     });

    # test HEAD operation for existence
    $bo->lookup($q, 1, 0, 0);
    if ($bo->error) {
       print "HEAD: Error, error / status: ",
          $bo->error . "/" . $bo->status) . "\n";
    }

    # test GET operations
    $bo->lookup($q, 0, 0, 0);
    if ($bo->error) {
       print "GET: Error, error / status: ",
          $bo->error . "/" . $bo->status) . "\n";
    }
	
    # result of lookup is in $bo->result
    # This result contains response objects built by Net::RDAP

    my $res = $bo->result;
    print "handle: ", $bo->handle, "\n";

 * See bin/no_rdap.pl for more information on usage.

 * See various formatting/helper functions in this file for how to
   access the various objects returned by Net::RDAP.

=head1 DESCRIPTION

This module provides an object oriented API for use with the
Norid RDAP service. It uses the Net::RDAP module from Cpan
internally to fetch information from the Norid RDAP.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>(nospam)info(at)norid.noE<gt>

=head1 SEE ALSO

L<https://www.norid.no/en>
L<https://teknisk.norid.no/en/integrere-mot-norid/rdap-tjenesten>
L<https://teknisk.norid.no/en/integrere-mot-norid/whois>

=head1 CAVEATS

=head1 AUTHOR

Trond Haugen, E<lt>(nospam)info(at)norid.noE<gt>

=head1 COPYRIGHT

Copyright (c) 2020- Trond Haugen <(nospam)info(at)norid.no>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

1;

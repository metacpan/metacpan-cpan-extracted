package TM::Serializable::JTM;
# $Id: JTM.pm,v 1.1 2010/04/09 09:57:08 az Exp $ 

use strict;
use Class::Trait 'base';
use Class::Trait 'TM::Serializable';
use JSON::Syck;
use YAML::Syck;
use TM::Literal;

use vars qw($VERSION);
$VERSION = qw(('$Revision: 1.2 $'))[1];

=pod

=head1 NAME

TM::Serializable::JTM - Topic Maps, trait for reading/writing JSON Topic Map instances.

=head1 SYNOPSIS

  # NOTE: this is not an end-user package,
  # see TM::Materialized::JTM for common application patterns

  # reading JSON/YAML:
  my $tm=TM->new(...);
  Class::Trait->apply($tm,"TM::Serializable::JTM");
  $tm->deserialize($jsondata);

  # writing JSON/YAML:
  # ...a map $tm is instantiated somehow

  Class::Trait->apply($tm,"TM::Serializable::JTM");
  my $yamltext=$tm->serialize(format=>"yaml");


=head1 DESCRIPTION

This trait provides functionality for reading and writing Topic Maps in
JTM (JSON Topic Map) format, as defined here: L<http://www.cerny-online.com/jtm/1.0/>.

Limitations: 

=over

=item * Variants are not supported by TM.

=item * Reification of basenames, occurrences and roles is not supported by TM.

=item * Multiple scopes are not supported by TM.

=back

=head1 INTERFACE

=head2 Methods

=over

=item B<deserialize>

This method take a string and parses JTM content from it. It will 
raise an exception on any parsing error. On success, it will return the map object.

The method understands one key/value parameter pair:

=over

=item * B<format> (choices: C<"json">, C<"yaml">)

This option controls whether the JTM is expected to be in JSON format
or in YAML (which is a superset of JSON). 

If no format parameter is given but the L<TM::Materialized::JTM> trait is used, then the format
is inherited from there; otherwise the default is C<"json">.

=back

=cut

sub deserialize 
{
    my ($self,$content,%opts)=@_;
    
    my $base=$self->baseuri;
    $opts{format}||=$self->{format}||"json";

    my $js;
    $js=($opts{format} eq "json"? JSON::Syck::Load($content): YAML::Syck::Load($content));

    
    die  "not a JTM topicmap object!\n"
	if (!_asserttype($js,"HASH") || lc($js->{item_type}) ne "topicmap"
	    || $js->{version} ne "1.0");
    die "variants are not supported.\n" if ($js->{variants});

    # topic nodes in jtm versus tids in tm.
    my %jtm2tid;

    # walk through topics, instantiate them
    # leave occurrences and basenames for later, as these have scopes and types
    # and we want to keep the tids consistent where possible.
    for my $t (@{$js->{topics}})
    {
	# sanitize the data structure
	for my $i (qw(item_identifiers subject_identifiers subject_locators names occurrences))
	{
	    $t->{$i}||=[];
	    die "Malformed data structure (bad $i)\n"
		if (!_asserttype($t->{$i},"ARRAY"));
	}
		
	# multiple item identifiers: not supported in TM.
	die("TM does not support multiple topic identifiers (IDs: "
	    .join(" ",@{$t->{item_identifiers}}).").\n")  if (@{$t->{item_identifiers}}>1);

	# multiple subject locators make no sense
	die("TM does not support multiple subject locators ("
	    .join(" ",@{$t->{subject_locators}}).").\n")  if (@{$t->{subject_locators}}>1);
	
	# do we have an item id? then suggest that as tid to TM
	# ...but check first if this is already present as an infrastructure topic. bah!
	my $newtid=$t->{item_identifiers}->[0];
	$newtid=$base.$newtid if (!$self->toplet($newtid));

	my $sloc; 
	if ($t->{subject_locators}->[0])
	{
	    $sloc=$t->{subject_locators}->[0];
	    # base must be added to plain strings (=local topic), but not on uris.
	    $sloc=$base.$sloc if ($sloc!~/^[a-zA-Z][a-zA-Z0-9+\.-]*:/); 
	}

	# internalize may well return a different tid!
	my $actual=$self->internalize($newtid=>$sloc); # $sloc is actual string
	$jtm2tid{$t}=$actual;

	# add all subject identifiers
	for my $sin (@{$t->{subject_identifiers}})
	{
	    my $nochange=$self->internalize($actual=>\$sin); # must be ref
	    die("confusion: adding subject indicator ($$sin) to $actual created new topic $nochange?!?\n")
		if ($nochange ne $actual);
	}
    }

    # now all explicitely named topics are known: tackle basenames and occurrences 
    for my $t (@{$js->{topics}})
    {
	for my $what ('names','occurrences')
	{
	    for my $item (@{$t->{$what}})
	    {
		die "variants are not supported.\n" if ($item->{variants});
		die "reification of $what is not supported.\n" if ($item->{reifier});
		$item->{scope}||=[];
		die "multiple scopes are not supported.\n" if (@{$item->{scope}}>1);

		# figure out scope
		my $scope="us";
		my $sr=$item->{scope}->[0];
		$scope=$self->_asserttref($sr) if ($sr);
		die "couldn't find/create scope topic from topic ref $sr\n" if (!$scope);

		# and type
		my $type=$what; $type=~s/.$//; my $short=$type;
		my $tr=$item->{type};
		$type=$self->_asserttref($tr) if ($tr);
		die "couldn't find/create type topic from topic ref $tr\n" if (!$type);

		my $vo=TM::Literal->new($item->{value},$item->{datatype}||TM::Literal->STRING);
		my (@success)=$self->assert(Assertion->new(kind=>($what eq 'names'? TM->NAME: TM->OCC),
							   type=>$type,
							   scope=>$scope,
							   roles=>['thing','value'],
							   players=>[ $jtm2tid{$t}, $vo]));
		die "couldn't create $short assertion for $jtm2tid{$t}\n"
		    if (@success!=1);
	    }
	}
    }
    
    # walk through assocs, and instantiate them too.
    for my $a (@{$js->{associations}})
    {
	die "multiple scopes are not supported.\n" if (@{$a->{scope}}>1);

	# figure out scope
	my $scope="us";
	my $sr=$a->{scope}->[0];
	$scope=$self->_asserttref($sr) if ($sr);
	die "couldn't find/create scope topic from topic ref $sr\n" if (!$scope);

	# and type
	die "can't have association without a type!\n" if (!$a->{type});
	my $type=$self->_asserttref($a->{type});
	die "couldn't find/create type topic from topic ref $a->{type}\n" if (!$type);

	my (@roles,@players);
	
	die "can't have association without roles!\n" if (!_asserttype($a->{roles},"ARRAY"));
	for my $r (@{$a->{roles}})
	{
	    die "role reification is not supported.\n" if ($r->{reifier});

	    my $roletype=$self->_asserttref($r->{type});
	    die "couldn't find/create role topic from topic ref $r->{type}\n" if (!$roletype);
	    my $player=$self->_asserttref($r->{player});
	    die "couldn't find/create player topic from topic ref $r->{player}\n" if (!$player);

	    push @roles,$roletype;
	    push @players,$player;
	}
	my (@success)=$self->assert(Assertion->new(kind=>TM->ASSOC,
						   type=>$type,
						   scope=>$scope,
						   roles=>\@roles,
						   players=>\@players));
	die "couldn't create association of type $type!\n" if (@success!=1);
	

	# assoc reifier present? then add that info to the relevant topic
	if  ($a->{reifier})
	{
	    my $aid=$success[0]->[TM->LID];

	    my $rtopic=$self->_asserttref($a->{reifier});
	    die "couldn't find/create reifier topic from topic ref $a->{reifier}\n" if (!$rtopic);
	    # and now add the subject locator
	    my $nochange=$self->internalize($rtopic=>$aid);
	    die "added subject locator $aid to topic $rtopic, which created new topic $nochange?!?\n"
		if ($nochange ne $rtopic);
	}
    }
    return $self;
}

sub _asserttype
{
    my ($objref,$expected)=@_;
    return ($objref && ref($objref) eq $expected);
}

# find topic from jtm topic ref
# this creates a new topic if required - and reuses existing base-less topics
# wherever possible. this could cause a mess (can't have different topics with the 
# same name as infrastructure topics) but that's unavoidable - internalize doesn't
# help with finding baseless stuff.
sub _asserttref
{
    my ($self,$tr)=@_;
    return undef if ($tr !~ /^(ii|si|sl):(.+)$/);

    my ($type,$id)=($1,$2);
    my $res=$id; 
    # only find/make stuff if the baseless version doesn't exist.
    $res=$self->internalize($type eq 'ii'?
			      (($self->baseuri.$id)=>undef):
			      ($type eq 'sl'?(undef=>$id):(undef=>\ $id))) if (!$self->toplet($res));
    return $res;
}

=pod

=item B<serialize>

This method serializes the map object in JTM notation and returns 
the result as a string.

The method understands one key/value parameter pair:

=over

=item * B<format> (choices: C<"json">, C<"yaml">)

This option controls whether the JTM result should be created in the JSON format
or in YAML (which is a superset of JSON).

If no format parameter is given but the L<TM::Materialized::JTM> trait is used, then the format
is inherited from there; otherwise the default is C<"json">.

=back

=cut

sub serialize  
{
    my ($self, %opts) = @_;
    $opts{format}||=$self->{format}||"json";
    my $baseuri = $self->baseuri;


    # force item-identifier on topic ids (both infrastructure as well as explicit ones)
    my $rebase=sub {
	my ($x)=@_;
	$x =~ s/^$baseuri//;
	return "ii:".$x;
    };
    
    my (%topics,%js);
    
    $js{version}="1.0";
    $js{item_type}="topicmap";
    $js{topics}=[];
    $js{associations}=[];
    
    # attach bn,oc,in to the relevant topic; prime normal assocs directly
    for my $m ($self->asserts (\ '+all')) 
    {
	my $kind  = $m->[TM->KIND];
	my $type  = &$rebase($m->[TM->TYPE]);
	my $scope = &$rebase($m->[TM->SCOPE]);
	my $lid   = $m->[TM->LID];

	if ($kind == TM->ASSOC) 
	{
	    my %thisa=(type=>$type,scope=>[$scope],roles=>[]);

	    my ($reifier)=$self->is_reified($m);
	    $thisa{reifier}=&$rebase($reifier) if $reifier;

	    # get_role_s returns a role list that is NOT necessarily duplicate-free,
	    # which stuffs up get_x_players, so we do it by hand. *sigh*.
	    for my $i (0..$#{$m->[TM->ROLES]})
	    {
		my $role=$m->[TM->ROLES]->[$i];
		my $player=$m->[TM->PLAYERS]->[$i];

		my $rolename = &$rebase($role);
		push @{$thisa{roles}},{player=>&$rebase($player),
				       type=>$rolename};
	    }
	    push @{$js{associations}},\%thisa;
	}
	elsif ($kind == TM->NAME) 
	{
	    my $thing = &$rebase(($self->get_x_players($m,"thing"))[0]);
	    my $reifier=$self->is_reified ($m);
	    $reifier=&$rebase($reifier) if $reifier;
	    
	    for my $p ($self->get_x_players($m,"value")) 
	    {
		my %x=(value=>$p->[0], scope=>[$scope], type=>$type);
		$x{reifier}=$reifier if $reifier;
		push @{$topics{$thing}->{names}},\%x;
	    }
	} 
	elsif ($kind == TM->OCC) 
	{
	    my $thing = &$rebase(($self->get_x_players($m,"thing"))[0]);
	    my $reifier=$self->is_reified ($m);
	    $reifier=&$rebase($reifier) if $reifier;
	    
	    for my $p ($self->get_x_players($m,"value")) 
	    { 
		my %x=(value=>$p->[0], datatype=>$p->[1], scope=>[$scope], type=>$type);
		$x{reifier}=$reifier if $reifier;

		push @{$topics{$thing}->{occurrences}},\%x;
	    }
	}
    }
    
    # finally add in reification info
    foreach my $tt ($self->toplets (\ '+all')) 
    {
	my $t = $tt->[TM->LID];
	my $base=$self->baseuri;

	my $tn=$t; 
	$tn=~s/^$base//;
	my $unbased=$tn;
	$tn='ii:'.$tn;

        $topics{$tn}->{subject_identifiers} = $tt->[TM->INDICATORS] 
	    if (@{$tt->[TM->INDICATORS]} > 0);

	# only reified topics and external uris are listed here,
	# assoc reification is listed with the assoc.
	# don't de-base external uri's! damn base-less infrastructure topics make this messy.
	my $other=$tt->[TM->ADDRESS];
	$other=~s/^$base// if ($other && $self->toplet($other));

	$topics{$tn}->{subject_locators}=[$other] 
	    if ($tt->[TM->ADDRESS] && !$self->retrieve($tt->[TM->ADDRESS]));
	$topics{$tn}->{item_identifiers}=[$unbased];
	push @{$js{topics}},$topics{$tn};
    }

    return ($opts{format} eq "json"?JSON::Syck::Dump(\%js) : YAML::Syck::Dump(\%js));
}

=pod

=back

=head1 SEE ALSO

L<TM>, L<TM::Serializable>

=head1 AUTHOR INFORMATION

Copyright 2010, Alexander Zangerl, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

1;



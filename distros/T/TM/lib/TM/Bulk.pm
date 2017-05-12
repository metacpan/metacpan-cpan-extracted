package TM::Bulk;

use TM;
use Class::Trait 'base';

use Data::Dumper;

=pod

=head1 NAME

TM::Bulk - Topic Maps, Bulk Retrieval Trait

=head1 SYNOPSIS

  my $tm = .....                          # get a map from anywhere

  use TM::Bulk;
  use Class::Trait;
  Class::Trait->apply ($tm, 'TM::Bulk');  # give the map the trait

  # find out environment of topic
  my $vortex = $tm->vortex ('some-lid',
                           {
	  	 	    'types'       => [ 'types' ],
		 	    'instances'   => [ 'instances*', 0, 20 ],
			    'topic'       => [ 'topic' ],
			    'roles'       => [ 'roles',     0, 10 ],
			    'members'     => [ 'players' ],
			   },
			   );
  # find names of topics (optionally using a scope preference list)
  my $names = $tm->names ([ 'ccc', 'bbb', 'aaa' ], [ 's1', 's3', '*' ]);

=head1 DESCRIPTION

Especially when you build user interfaces, you might need access to a lot of topic-related
information. Instead of collecting this 'by foot' the following methods help you achieve this more
effectively.

=over

=item B<names>

I<$name_hash_ref> = I<$tm>->names (I<$lid_list_ref>, [ I<$scope_list_ref> ] )

This method takes a list (reference) of topic ids and an optional list of scoping topic ids.  For
the former it will try to find the I<name>s (I<topic names> for TMDM acolytes).

If the list of scopes is empty then the preference is on the unconstrained scope. If no name for a
topic is in that scope, some other will be used.

If the list of scopes is non-empty, it directs to look first for a name in the first scoping topic,
then second, and so on. If you want to have one name in any case, append C<*> to the scoping list.

If no name exist for a particular I<lid>, then an C<undef> is returned in the result hash. References
to non-existing topics are ignored.

The overall result is a hash (reference). The keys are of the form C<topic-id @ scope-id> (without
the blanks) and the name strings are the values.

=cut

sub names {
    my $self   = shift;
    my $topics = shift || [];
    my $scopes = shift || [ '*' ];

#warn "looking for ".Dumper ($topics). "with scopes ".Dumper $scopes;
    my $dontcare = 0;                                                  # one of the rare occasions I need a boolean
    if ($scopes->[-1] eq '*') {
	pop @$scopes;                                                  # get rid of this '*' to have a clean topic list
	$dontcare = 1;                                                 # remember this incident for below
    }
    my @scopes = grep { $_ } $self->tids (@$scopes);                   # make them absolute, so that we can compare later (only keep existing ones)
#warn "scopes".Dumper \@scopes;

    my ($US) = ('us');

    my %dict;                                                          # this is what we are building
TOPICS:
    foreach my $lid (grep { $_ } $self->tids (@$topics)) {             # for all in my working list, make them absolute, and test
#	next if $dict{$lid};                                           # do not things twice
#	$dict{$lid} = undef;                                           # but make sure we have an entry there, whatever comes next

	my @as = grep { $_->[TM->KIND] == TM->NAME }                   # filter all characteristics for basenames
	            $self->match_forall (char => 1, topic => $lid);
	unless (@as) {                                                 # no names? => done 
	    $dict{$lid} = undef;
	    next;
	}
                                                                       # assertion: @as contains at least one entry!
	unless (@scopes) {                                             # empty list? => preference is unconstrained scope
	    if (my @aas = grep ($_->[TM->SCOPE] eq $US, @as)) {
		$dict{$lid.'@'.$US} = $aas[0]->[TM->PLAYERS]->[1]->[0];
		next TOPICS;
	    }
	}
	foreach my $sco ($self->tids (@scopes)) {                      # check out all scope preferences (note, there is at least one in @as!)
	    if (my @aas = grep ($_->[TM->SCOPE] eq $sco, @as)) {
		$dict{$lid.'@'.$sco} = $aas[0]->[TM->PLAYERS]->[1]->[0];
		next TOPICS;
	    }
	}
	if ($dontcare) {                                               # get some name item and derereference it
	    $dict{$lid.'@'.$as[0]->[TM->SCOPE]} = $as[0]->[TM->PLAYERS]->[1]->[0]; # scope it with what we have
	} else {                                                       # otherwise send back nothing
	    $dict{$lid} = undef;
	}
    }
#warn "returning dict ".Dumper \%dict;
    return \%dict;
}

=pod

=item B<vortex>

I<$info> = I<$tm>->vortex (,
               I<$vortex_lid>,
               I<$what_hashref>,
               I<$scope_list_ref> )

This method returns B<a lot> of information about a particular toplet (vortex). The function expects
the following parameters:

=over

=item I<lid>:

the lid of the toplet in question

=item I<what>:

a hash reference describing the extent of the information (see below)

=item I<scopes>:

a list (reference) to scopes (currently B<NOT> honored)

=back

To control B<what> exactly should be returned, the C<what> hash reference can contain following
components. All of them being tagged with <n,m> accept an additional pair of integer specify the
range which should be returned.  To ask for the first twenty, use C<0,19>, for the next
C<20,39>. The order in which the identifiers is returned is undefined but stable over subsequent
read-only calls.

=over

=item I<topic>:

fetches the toplet (which is only the subject locator, subject indicators information).

=item I<names> (<n,m>):

fetches all names (as array reference triple [ I<type>, I<scope>, string value ])

=item I<occurrences> (<n,m>):

fetches all occurrences (as array reference triple [ I<type>, I<scope>, I<value> ])

=item I<instances> (<n,m>):

fetches all toplets which are direct instances of the vortex (that is regarded as
class here);

=item I<instances*> (<n,m>):

same as C<instances>, but including all instances of subclasses of the vortex

=item I<types> (<n,m>):

fetches all (direct) types of the vortex (that is regarded as instance here)

=item I<types*> (<n,m>):

fetches all (direct and indirect) types of the vortex (that is regarded as instance here)

=item I<subclasses>  (<n,m>):

fetches all direct subclasses

=item I<subclasses*> (<n,m>):

same as C<subclasses>, but creates reflexive, transitive closure

=item I<superclasses> (<n,m>):

fetches all direct superclasses

=item I<superclasses*> (<n,m>):

same as C<superclasses>, but creates reflexive, transitive closure

=item I<roles> (<n,m>):

fetches all assertion ids where the vortex plays a role

=item I<peers> (<n,m>):

fetches all topics which are also a direct instance of any of the (direct) types of this topic

=item I<peers*> (<n,m>):

fetches all topics which are also a (direct or indirect) instances of any of the (direct) types of
this topic

=item I<peers**> (<n,m>):

fetches all topics which are also a (direct or indirect) instances of any of the (direct or
indirect) types of this topic

=back

The function will determine all of the requested information and will prepare a hash reference
storing each information into a hash component. Under which name this information is stored, the
caller can determine with the hash above as the example shows:

Example:

  $vortex = $tm->vortex ('some-lid',
                         {
			  'types'       => [ 'types' ],
			  'instances'   => [ 'instances*', 0, 20 ],
			  'topic'       => [ 'topic' ],
			  'roles'       => [ 'roles',     0, 10 ],
			 },
			);

The method dies if C<lid> does not identify a proper toplet.

=cut

sub vortex {
  my $self   = shift;
  my $lid    = shift;
  my $what   = shift;
  my $scopes = shift             and $TM::log->logdie ("scopes not supported yet");

  my $alid   = $self->tids ($lid) or $TM::log->logdie ("no topic '$lid'");

  my ($ISSC, $ISA) = ('is-subclass-of', 'isa');
  
  my @as = $self->match_forall (iplayer => $alid);            # find out everything we know about the player

  my $_t;                                                     # here all the goodies go
  foreach my $where (keys %{$what}) {                         # collect here what the user wants
      my $w = shift @{$what->{$where}};

      if ($w eq 'topic') {
	  $_t->{$where} = $self->toplet ($alid);
	  
      } else {
	  my @is;
	  if (grep ($w =~ /^$_\*?$/, qw(instances types subclasses superclasses))) {
	      $w =~ s/\*/T/;

	      @is  = $self->$w ($alid); # whoa, Perl late binding rocks !
	  
	  } elsif ($w eq 'names') {
	      @is = map { [ $_->[TM->TYPE], $_->[TM->SCOPE], $_->[TM->PLAYERS]->[1]->[0] ] }
	            grep { $_->[TM->KIND] == TM->NAME }
                    @as;
	  
	  } elsif ($w eq 'occurrences') {
	      @is = map { [ $_->[TM->TYPE], $_->[TM->SCOPE], $_->[TM->PLAYERS]->[1] ] }
	            grep { $_->[TM->KIND] == TM->OCC }
	            @as;
	  
	  } elsif ($w eq 'roles') {
	      @is = map { $_->[ TM->LID ] }
                    grep { $_->[TM->TYPE] ne $ISSC && $_->[TM->TYPE] ne $ISA }
	            grep { $_->[TM->KIND] == TM->ASSOC }
                    @as;

          } elsif ($w eq 'peers') {
              @is = grep { $_ ne $alid } $self->instances ($self->types ($alid));

          } elsif ($w eq 'peers*') {
              @is = grep { $_ ne $alid }  $self->instancesT ($self->types ($alid)) ;

          } elsif ($w eq 'peers**') {
              @is = grep { $_ ne $alid } $self->instancesT ($self->typesT ($alid)) ;

	  } elsif ($w eq 'associations') { # TODO! test case
sub _morph {
    my $lid = shift;
    my $a   = shift;

    my ($ps, $rs) = ($a->[TM->PLAYERS], $a->[TM->ROLES]);
    my $r;                                                                    # my own role
    my %rs;                                                                   # the other roles
    for (my $i = 0; $i < @$ps; $i++) {
        if ($lid eq $ps->[$i]) {                                              # we talk about ourselves
            $r = $rs->[$i];
        } else {                                                              # this is about something else
            push @{ $rs{ $rs->[$i] } }, $ps->[$i];
        }
    }
    return ($r, \%rs);
}
              @is = map { [  $_->[TM->TYPE], $_->[TM->SCOPE], _morph ($alid, $_) ] }
                    grep { $_->[TM->TYPE] ne $ISSC && $_->[TM->TYPE] ne $ISA }
                    grep { $_->[TM->KIND] == TM->ASSOC }
                    @as;

	  }
	  my ($from, $to) = _calc_limits (scalar @is, shift @{$what->{$where}}, shift @{$what->{$where}});
	  $_t->{$where} = [ @is[ $from .. $to ] ];
      }
  }
  return $_t;                                                                   # and ship it all back

  sub _calc_limits {
      my $last  = (shift) - 1; # last available
      my $from  = shift || 0;
      my $want  = shift || 10;
      my $to = $from + $want - 1;
      $to = $last if $to > $last;
      return ($from, $to);
  }
}

=pod

=back

=head1 SEE ALSO

L<TM::Overview>

=head1 COPYRIGHT AND LICENSE

Copyright 200[3-57] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

our $VERSION  = 0.5;
our $REVISION = '$Id: Bulk.pm,v 1.2 2007/07/17 16:23:05 rho Exp $';

1;

__END__

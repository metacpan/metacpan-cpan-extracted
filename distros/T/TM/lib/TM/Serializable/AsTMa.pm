package TM::Serializable::AsTMa;

use strict;
use warnings;

use Class::Trait 'base';
use Class::Trait 'TM::Serializable';

use Data::Dumper;

=pod

=head1 NAME

TM::Serializable::AsTMa - Topic Maps, trait for parsing AsTMa instances.

=head1 SYNOPSIS

  # this is not an end-user package
  # see the source in TM::Materialized::AsTMa how this can be used

=head1 DESCRIPTION

This trait provides parsing functionality for AsTMa= instances. AsTMa= is a textual shorthand
notation for Topic Map authoring. Currently, AsTMa= 1.3 and the (experimental) AsTMa= 2.0 is
supported.

=over

=item B<AsTMa= 1.3>

This follows the specification: L<http://astma.it.bond.edu.au/authoring.xsp> with the following
constraints/additions:

=over

=item following directives are supported:

=over

=item %cancel

Cancels the parse process on this very line and ignores the rest of the AsTMa instance. Useful for
debugging faulty maps. There is an appropriate line written to STDERR.

=item %log [ message ]

Writes a line to STDERR reporting the line number and an optional message. Useful for debugging.

=item %encoding [ encoding ]

Specifies which encoding to use to interpret the B<following> text. This implies that this
directive may appear several times to change the encoding. Whether this is a good idea
in terms of information management, is a different question.

B<NOTE>: If no encoding is provided, utf8 is assumed.

=item %trace integer

For debugging purposes you can turn on I<tracing> by specifying an integer level. Level C<0> means
I<no tracing>, level C<1> shows a bit more, and so forth.

B<NOTE>: This is not overly developed at the moment, but can be easily extended.


=back

A directive can be inserted anywhere in the document but must be at the start of a line.

=back


=item B<AsTMa= 2.0>

It follows the specification on http://astma.it.bond.edu.au/astma=-spec-2.0r1.0.dbk with
the following changes:

=over

=item this is work in progress

=back

=back

=head1 INTERFACE

=head2 Methods

=over

=item B<deserialize>

This method take a string and tries to parse AsTMa= content from it. It will raise an exception on
parse error. On success, it will return the map object.

=cut

sub deserialize {
    my $self    = shift;
    my $content = shift;

    if ($content =~ /^\s*%version\s+2/s) {                                     # this is version 2.x
	use TM::AsTMa::Fact2;
	my $ap = new TM::AsTMa::Fact2 (store => $self);
	$ap->parse ($content);

    } else {                                                                   # assume it is 1.x
	use TM::AsTMa::Fact;
	my $ap = new TM::AsTMa::Fact (store => $self);
	$ap->parse ($content);                                                 # we parse content into the ap object component 'store'
    }
    return $self;
}

=pod

=item B<serialize>

This method serialized the map object into AsTMa notation and returns the resulting string.  It will
raise an exception if the object contains constructs that AsTMa cannot represent. The result is a
standard Perl string, so you may need to force it into a particular encoding.

The method understands a number of key/value pair parameters:

=over

=item C<version> (default: C<1>)

Which AsTMa version the result should conform to. Currently only version C<1> is supported.

=item C<omit_trivia> (default: C<0>)

This option suppresses the output of completely I<naked> toplets (toplets without any characteristics).

=item C<omit_infrastructure> (default: C<1>)

This option suppresses the output of infrastructure toplets.

=item C<omit_provenance> (default: C<0>)

If set, no mentioning of where the content came from is added.

=item C<trace> (default: C<undef>)

[v1.54] Switches on I<tracing> in the generated AsTMa code. The trace level can be controlled via the value of
this option.

=back

=cut

sub serialize  {
    my ($self, %opts) = @_;
    $opts{version}     ||=1;
#   $opts{omit_trivia} ||=1;
    $opts{omit_infrastructure} ||=1;
    
    return _serializeAsTMa1 ($self, %opts) if $opts{version} eq 1;

    $TM::log->logdie(scalar __PACKAGE__ .": serialization not implemented for AsTMa version ".$opts{version} );

#sub _fat_mama {
#    use Proc::ProcessTable;
#    my $t = new Proc::ProcessTable;
##warn Dumper [ $t->fields ]; exit;                                                                                                                                               
#    my ($me) = grep {$_->pid == $$ }  @{ $t->table };
##warn "size: ".  $me->size;                                                                                                                                                      
#    return $me->size / 1024;
#}

sub _serializeAsTMa1 {
    my $self = shift;
    my %opts = @_;

    my ($THING, $US, $CLASS, $INSTANCE, $VALUE, $ISA, $NAME, $OCCURRENCE) =
	('thing', 'us', 'class', 'instance', 'value', 'isa', 'name', 'occurrence');

#    my ($PLAYERS, $ROLES, $URI, $LID, $ADDRESS, $NAME, $OCC, $ASSOC, $SCOPE, $TYPE, $KIND, $INDICATORS) =  # sadly, this makes a difference in speed
#	(TM->PLAYERS, TM->ROLES, TM::Literal->URI, TM->LID, TM->ADDRESS, TM->NAME, TM->OCC, TM->ASSOC, TM->SCOPE, TM->TYPE, TM->KIND, TM->INDICATORS);

    my $baseuri = $self->{baseuri};

    my $debase = sub {
	$_[0] =~ s/^$baseuri//;
	return $_[0];
    };

    my %assocs;
    my %topics;                                  # the work stats: collect info from the assertions.

#    warn scalar $self->asserts (\ '+all -infrastructure');

ASSOCS:
    for my $m ($self->asserts (\ '+all -infrastructure')) {
	my $kind  = $m->[TM->KIND];
	my $type  = $m->[TM->TYPE];
	my $scope = $m->[TM->SCOPE];
	my $lid   = $m->[TM->LID];

	$scope = $US eq $scope ? undef : &$debase ($scope);

	if ($kind == TM->ASSOC) {
	    if ( $type eq $ISA ) {
		my ($p, $c) = map { &$debase ( $_) } @{ $m->[TM->PLAYERS] };
		push @{$topics{$p}->{children}}, $c;
		push @{$topics{$c}->{parents}},  $p;

	    } else {
		my %thisa;

		$thisa{type}      = &$debase ($type);
		$thisa{scope}     = $scope;

		if (my ($reifier)     = $self->is_reified ($m)) {
		    $thisa{reifiedby} = &$debase ($reifier);
		}

		{
		    my ($ps, $rs) = ($m->[TM->PLAYERS], $m->[TM->ROLES]);
		    for (my $i = 0; $i < @$ps; $i++) {
			push @{  $thisa{roles}->{ &$debase ($rs->[$i]) }  }, &$debase ($ps->[$i]);
		    }
		}

		$assocs{$lid} = \%thisa;
	    }

	} elsif ($kind == TM->NAME) {
	    my ($thing, $value) = @{ $m->[TM->PLAYERS] };
	    $thing = &$debase ($thing);
	    
	    $TM::log->logdie (scalar __PACKAGE__ .": astma 1.x does not offer reification of basenames (topic $thing)\n")
		if $self->is_reified ($m);

	    push @{$topics{$thing}->{bn}}, [ $value->[0], $type eq $NAME ? undef : &$debase($type), $scope ];
	    
	} elsif ($kind == TM->OCC) {
	    my ($thing, $value) = @{ $m->[TM->PLAYERS] };
	    $thing = &$debase ($thing);
	    
	    $TM::log->logdie (scalar __PACKAGE__ .": astma 1.x does not offer reification of occurrences (topic $thing)\n")
		if $self->is_reified ($m);

	    my $key= $value->[1] eq TM::Literal->URI ? "oc" : "in";
	    push @{$topics{$thing}->{ $key }}, [ $value->[0], $type eq $OCCURRENCE ? undef : &$debase($type), $scope ];
	}
    }
##warn Dumper \%topics;
    foreach my $tt ($self->toplets (\ '+all -infrastructure') ) {                     # then from the topics
	my $t = $tt->[TM->LID];
	my $tn = &$debase ($t);

	$topics{$tn} ||= {}; 
	
	$TM::log->logdie (scalar __PACKAGE__ .": astma 1.x does not offer variants (topic $tn)\n")
	    if ($self->variants ($t));
	
        $topics{$tn}->{sins} = $tt->[TM->INDICATORS] if @{ $tt->[TM->INDICATORS] } > 0;
	if ($tt->[TM->ADDRESS] and !$self->retrieve($tt->[TM->ADDRESS])) {
	    # external target? attach as active 'reifies' to local topic
	    # target is an internal topic? attach as passive 'is-reified-by' to the target,
	    # to avoid the ugly/base-specific 'x reifies tm://y'
	    my $target = $tt->[TM->ADDRESS];
	    if ($self->toplet($target))
	    {
		$topics{&$debase($target)}->{raddr}=$tn;
	    }
	    else
	    {
		$topics{$tn}->{addr}=$target;
	    }
	}
    } 
#--- finally the actual dumping of the actual information ---------------------------------------------------
    my @result; # will collect lines here
    push @result, "# originally from ".($self->{url} =~ /^inline:/ ? "inline" : $self->{url}) unless $opts{omit_provenance};
    push @result, "# base $baseuri";
    push @result, "";

    push @result, "%trace ".$opts{trace} if $opts{trace};

TOPICS:
    for my $t (sort keys %topics) {
	my $tn = $topics{$t};

	if ($opts{omit_infrastructure}) {
	    next TOPICS if $TM::infrastructure->{mid2iid}->{ $t };
	}
	if ($opts{omit_trivia}) {
	    next TOPICS unless keys %$tn;
	}

	push @result,
        $t                                                                                   # the id
	.($tn->{parents} ? " (".join(" ",@{$tn->{parents}}).")" : "")                        # optionally the types (....)
        .($tn->{addr}     ? " reifies ". $tn->{addr}              : "")                      # optionally the subject address
	.($tn->{raddr}?(" is-reified-by ".$tn->{raddr}):""); # subject address, passive.
	
	foreach my $k (qw(bn in oc)) {
	    push @result, 
		map {  $k.($_->[2]?(" @ ".$_->[2]):"")
			 .($_->[1]?(" (".$_->[1].")"):"")
                         .": ". _multiline ($_->[0]) } 
		(@{$tn->{$k}});
	}
sub _multiline {
    if ($_[0] =~ /\n/s) {
	return "<<<\n$_[0]\n<<<";
    } else {
	return $_[0];
    }
}

	if ($tn->{sins}) {
	    map { push @result, "sin: ".$_; } (@{$tn->{sins}});
	}
	push @result,"";                                                                     # will end up as empty line
    }
    map {
	my $a = $_;
	push @result,"(".$a->{type}.")"
                     .($a->{scope}     ? " @".$a->{scope}                  : "")
                     .($a->{reifiedby} ? " is-reified-by ".$a->{reifiedby} : "");
	map 
	{ 
	    push @result, 
	    "$_: ".join(" ",@{$a->{roles}->{$_}});  
	} (sort keys %{$a->{roles}});
	push @result,"";
    }
    map       { $assocs{ $_ } }
         sort { $assocs{$b}->{type} cmp $assocs{$a}->{type} } 
         keys %assocs;
    return join("\n",@result)."\n\n";
}
}

=pod

=back

=head1 SEE ALSO

L<TM>, L<TM::Serializable>

=head1 AUTHOR INFORMATION

Copyright 200[1-68], Robert Barta <drrho@cpan.org>, Alexander Zangerl <he@does.not.want.his.email.anywhere>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.6';
our $REVISION = '$Id: rho';

1;

__END__

# not sure what it does, will check later
#	    if ($tn->{reifies}) {
#		next TOPICS if grep { $_ && $tn->{reifies} eq $_ } @iaddr;
#	    }
	}


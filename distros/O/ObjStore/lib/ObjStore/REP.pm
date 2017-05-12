use strict;
package ObjStore::REP;
use Carp;
use ObjStore;
use vars qw(%Default);

sub be_compatible {
    # These are needed for databases created before DLL schemas
    # were available.
    require ObjStore::REP::Splash;
    require ObjStore::REP::FatTree;
    require ObjStore::REP::ODI;
}

sub load_default {
    my $ty = caller;
    my $sub;
    if ($ty eq 'ObjStore::AV') {
	require ObjStore::REP::Splash;
	install(AV1 => \&ObjStore::REP::Splash::AV::new);
	$sub = \&AV;
    } elsif ($ty eq 'ObjStore::HV') {
	require ObjStore::REP::Splash;
	require ObjStore::REP::ODI;
	install(HV1 => \&ObjStore::REP::Splash::HV::new,
		HV2 => \&ObjStore::REP::ODI::HV::new);
	$sub = \&HV;
    } elsif ($ty eq 'ObjStore::Index') {
	# representations are self-serve
	$sub = \&Index;
    } else {
	croak "load_default $ty?";
    }
    $Default{$ty} = 1;  #??
    {
	no strict 'refs';
	local $^W = 0;
	*{$ty.'::new'} = $sub;
    }
    goto &$sub;
}

use vars qw($AV1 $AV2 $HV1 $HV2 $XV1 $XV2);
sub install {
    while (@_) {
	my ($k,$v) = splice @_, 0, 2;
	if    ($k eq 'AV1') { $AV1 = $v }
	elsif ($k eq 'AV2') { $AV2 = $v }
	elsif ($k eq 'HV1') { $HV1 = $v }
	elsif ($k eq 'HV2') { $HV2 = $v }
	elsif ($k eq 'XV1') { $XV1 = $v }
	elsif ($k eq 'XV2') { $XV2 = $v }
	else { Carp::cluck "unknown '$k'" }
    }
    $AV1 ||= $AV2;
    $AV2 ||= $AV1;
    $HV1 ||= $HV2;
    $HV2 ||= $HV1;
    $XV1 ||= $XV2;
    $XV2 ||= $XV1;
}

sub AV {
    my ($this, $loc, $how) = @_;
    $loc = $loc->segment_of if ref $loc;
    my $class = ref($this) || $this;
    my ($av, $sz, $init);
    if (ref $how) {
	$sz = @$how || 7;
	$init = $how;
    } else {
	$sz = $how || 7;
    }
    $av = ($sz < 45? $AV1 : $AV2)->($class, $loc, $sz);
    if ($init) {
	for (my $x=0; $x < @$init; $x++) { $av->STORE($x, $init->[$x]); }
    }
    $av;
}

sub HV {
    my ($this, $loc, $how) = @_;
    $loc = $loc->segment_of if ref $loc;
    my $class = ref($this) || $this;
    my ($hv, $sz, $init);
    if (ref $how) {
	$sz = (split(m'/', scalar %$how))[0] || 7;
	$init = $how;
    } else {
	$sz = $how || 7;
    }
    $hv = ($sz < 25? $HV1 : $HV2)->($class, $loc, $sz);
    if ($init) {
	while (my($hk,$v) = each %$init) { $hv->STORE($hk, $v); }
    }
    $hv;
}

my $noise = 3;
sub Index {
    my ($this, $loc, @C) = @_;
    $loc = $loc->segment_of if ref $loc;
    my $class = ref($this) || $this;
    if (@C and ref $C[0]) {
	carp "please pass configuration without hashref"
	    if $noise-- >= 0;
	@C = %{ $C[0] };
    }
    my %c = @C;
    my $sz = $c{size} ||= 100;
    my $x = ($sz < 7000? $XV1 : $XV2)->($class, $loc);
    my @args = %c; #shouldn't need to unroll here XXX
    $x->configure(@args);
    $x;
}

1;

=head1 NAME

    ObjStore::REP - Default Representations Constructors

=head1 SYNOPSIS

    ObjStore::REP::install(type => \&constructor);

=head1 DESCRIPTION

The most suitable representation for data-types is determined when
they are allocated.  The code that does the determination is set up by
this file.

To override the defaults, simply re-implement the 'new' method for the
classes of your choice before you allocate anything.

=cut


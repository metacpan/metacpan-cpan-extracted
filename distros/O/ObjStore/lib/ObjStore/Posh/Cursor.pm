use strict;
package ObjStore::Posh::Cursor;
use ObjStore ':ADV';
use base 'ObjStore::HV';
use vars qw($VERSION);
$VERSION = '0.72';

sub new {
    my ($o) = shift->SUPER::new(@_);
    my $top = $o->database_of->hash;
    die "expecting a ServerDB" 
	if !$top->isa('ObjStore::ServerDB::Top');
    $$o{mtime} = time;
    $$o{history} = [];
    $o->do_init();
    $o;
}

use ObjStore::notify qw(init);
sub do_init {
    my ($o) = @_;
    $$o{where} = [[$o->database_of->hash->new_ref($o,'hard')]];   #array of paths
    $$o{at} = 0;
}

use ObjStore::notify qw(configure execute);
sub do_configure {
    my $o = shift;
    # local or remote?
}

sub myeval {
    my ($o, $perl) = @_;

    # observe care!
    my $w = $o->{where}[ $$o{at} ]->HOLD;
    my @c;
    for my $tmp (@$w) {
	my $got = $tmp->focus;
	push @c, $got;
    }
    local($input::db, $input::at, $input::cursor) = 
	($o->database_of, @c? $c[$#c] : $o->database_of, \@c);

    my @r;
    my $to_eval = "no strict; package input;\n#line 1 \"input\"\n".$perl;
    if (wantarray) {               @r = eval $to_eval; }
    elsif (defined wantarray) { $r[0] = eval $to_eval; }
    else {                              eval $to_eval; }
    if ($@) {
	ObjStore::Transaction::get_current()->abort();
	()
    } else {
	if (!defined wantarray) { () } else { wantarray ? @r : $r[0]; }
    }
}

sub resolve {
    my ($o,$to,$update) = @_;
    # $to already stripped of leading & trailing spaces
    my $w = $$o{where};
    my @at = map { $_->focus } @{ $$w[ $$o{at} ] };
    if (!length $to) {
	@at = ();
	if ($update) {
	    $w->UNSHIFT([$o->database_of->hash->new_ref($o,'hard')]);
	    pop @$w if @$w > 5;
	    $$o{at} = 0;
	}
    } elsif ($to =~ m/^([+-])$/) {
	my $at = $1 eq '-' ? $$o{at}+1 : $$o{at}-1;
	if ($at >= 0 and $at < @$w) {
	    @at = map { $_->focus } @{ $$w[$at] };
	    if ($update) {
		$$o{at} = $at;
	    }
	}
    } elsif ($to =~ m,^[\w\/\.\:\-]+$,) {
	my @to = split m'/+', $to;
	for my $t (@to) {
	    next if $t eq '.';
	    if ($t eq '..') {
		pop @at if @at;
	    } else {
		my $at = $at[$#at];
		if ($at->can('POSH_CD')) {
		    $at = $at->POSH_CD($t);
		    $at = $at->POSH_ENTER()
			if blessed $at && $at->can('POSH_ENTER');
		    if (!blessed $at or !$at->isa('ObjStore::UNIVERSAL')) {
			$at = 'undef' if !defined $at;
			$$o{why} = "resolve($to): failed at $t (got '$at'!)";
			last;
		    }
		}
		push @at, $at;
	    }
	}
	if (!$$o{why} and $update) {
	    $w->UNSHIFT([map { $_->new_ref($w,'hard') } @at]);
	    pop @$w if @$w > 5;
	    $$o{at} = 0;
	}
    } else {
	my $err;
	my $warn='';
        {
	    local $SIG{__WARN__} = sub { $warn.=$_[0] };
	    begin sub {
		local $Carp::Verbose = 1;
		my $at = $o->myeval($to);
		if ($@) {
		    $err .= $warn.$@;
		} else {
		    $$o{out} = $warn;
		    push @at, $at;
		    if ($update) {
			$w->UNSHIFT([map { $_->new_ref($w,'hard') } @at]);
			pop @$w if @$w > 5;
			$$o{at} = 0;
		    }
		}
	    };
	}
	warn if $@;
	$$o{why} = $err if $err;
    }
    @at? $at[$#$a] : undef;
}

sub do_execute {
    require ObjStore::Peeker;
    my ($o, $in) = @_;

    $$o{mtime} = time;  #make sure the GUI knows!
    $in ||= '';
    $in =~ s/\s+$//;
    $in =~ s/^\s+//;
    my $hist = $$o{history} ||= [];
    push @$hist, $in;
    shift @$hist if @$hist > 10;  #configurable?

    # use a fresh transaction: speed doesn't matter compared to safety
    begin sub {
	local $Carp::Verbose = 1;
	$$o{why} = '';
	$$o{out} = '';
	
	if ($in =~ m/^reset$/) {
	    $o->do_init();
	} elsif ($in =~ m/^cd \b \s* (.*?) \s* $/sx) {
	    $o->resolve($1, 1);
	    if (!$$o{why}) {
		my $at = $o->{where}[ $$o{at} ];
		my $p = ObjStore::Peeker->new(depth => 0);
		$$o{out} .= $p->Peek($$at[$#$at]->focus);
	    }
	} elsif ($in =~ m/^(ls|peek|raw) \b \s* (.*?) \s* $/sx) {
	    my ($cmd,$to) = ($1,$2);
	    my @at;
	    if (length $to) {
		@at = $o->resolve($to, 0);
	    } else {
		my $at = $o->{where}[ $$o{at} ] ||= [];
		push @$at, $o->database_of->hash->new_ref($at,'hard')
		    if !@$at;
		$at[0] = $$at[ $#$at ]->focus;
	    }
	    if (!$$o{why}) {
		my $depth = $cmd eq 'raw' || $cmd eq 'peek'? 10 : 0;
		my $p = ObjStore::Peeker->new(pretty => $cmd eq 'raw',
					      depth => $depth);
		$$o{out} = $p->Peek($at[0]);
	    }
	} elsif ($in eq 'pwd') {
	    $$o{out} = $o->pwd();
	} else {
	    my $err = '';
	    my $warn = '';
	    {
		local $SIG{__WARN__} = sub { $warn.=$_[0] };
		begin sub {
		    local $Carp::Verbose = 1;
		    my @r = $o->myeval($in);
		    if ($@) {
			$err .= $warn.$@;
		    } else {
			my $p = ObjStore::Peeker->new(depth => 10, vareq => 1);
			my $out = $$o{out} = [$warn];
			for (@r) { push @$out, $p->Peek($_) }
		    }
		};
	    }
	    warn if $@;
	    $$o{why} = $err if $err;
	}
    };
    if ($@) {
	$$o{why} .= $@;
    }
}

sub prompt {
    my ($o) = @_;
    my $w = $o->{where}[ $$o{at} ];
    return "?" if !$w || !@$w;
    "\$at = ".$$w[$#$w]->focus;
}

sub pwd {
    my ($o) = @_;
    my $out = '';
    my $p = ObjStore::Peeker->new(depth => 0);
    my $w = $o->{where}[ $$o{at} ];
    my @c = map { $_->focus } @$w;
    for (my $z=0; $z < @c; $z++) {
	$out .= '$cursor->['."$z] = ".$p->Peek($c[$z]);
    }
    $out;
}

package input;
use Carp qw(carp cluck croak confess);
use ObjStore ':ADV';
use vars qw($at $db $cursor);

1;
__END__

# TODO:
#
# 'use Safe' once it is worthwhile


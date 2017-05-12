use strict;
package Rc::Sh;  #bourne shell backend
use Carp;
use Rc qw($OutputFH);
use vars qw($level %Local $Backq);
$level = 0;
%Local = (IFS => 1);

sub HELP { die "Will an 'sh' expert please step forward?" }

sub indent(&) { local $level = $level + 1; shift->() }
sub nl() { "\n" . ' 'x($level*4) }

sub Rc::Node::sh {
    print $OutputFH shift->shp(). "\n";
}

sub Rc::Node::shp {
    my $n=shift;
    die ref($n)." not implemented yet for 'sh'";
}

sub Rc::Word::shp { shift->string }

sub Rc::Qword::shp {
    my $s = shift->string;
    # quotemeta XXX
    "'$s'"
}

sub no_brace {
    my $n=shift;
    $n->isa('Rc::Brace')? $n->kid(0) : $n
}

sub Rc::If::shp {
    my $n=shift;
    my $k = $n->kid(1);
    'if '.$n->kid(0)->shp.' ; then'.
	($k->isa('Rc::Else')? $k->shp :
	 indent { nl.no_brace($k)->shp }.nl.'fi' )
}

sub Rc::Orelse::shp {
    my $n=shift;
    join(' || ', map { $_->shp } $n->kids);
}

sub Rc::Concat::shp {
    my $n = shift;
    # maybe some sanity check? XXX
    join('', map { $_->shp } $n->kids);
}

sub Rc::Else::shp {
    my $n =shift;
    my $k = $n->kid(1);
    indent { nl.no_brace($n->kid(0))->shp }.nl.do {
	if ($k->isa('Rc::If')) {
	    'el'.$k->shp
	} else {
	    'else '.$k->shp;
	}
    };
}

sub Rc::Args::shp {
    my $n = shift;
    join(' ', map { $_->shp } $n->kids)
}

sub _words {
    my $n=shift;
    my @w;
    while ($n->isa('Rc::Lappend')) {
	push @w, $n->kid(1);
	$n = $n->kid(0);
    }
    @w, $n;
}

sub _match {
    my ($x,$y) = @_;
    if (ref $y eq 'Rc::Undef') {
	'test "x'.$x->shp.'" = x'
    } else {
	die "don't know how to match against $y";
    }
}

sub Rc::Match::shp {
    my $n=shift;
    join(' || ', map { _match($n->kid(0), $_) } _words($n->kid(1)))
}

sub as_var {
    my ($k) = @_;
    my $varname;
    if ($k->isa('Rc::WordX')) {
	$varname = $k->shp;
	if ($varname =~ /[:=-?+%\#]/) {
	    die "metacharacters found in var '$varname'";
	} elsif ($varname eq 'pid') {
	    return "\$";
	}
    } else {
	die "don't know how use $k as a variable"
    }
    "{$varname}"
}

sub Rc::Backq::shp {
    my $n=shift;
    die "nested Backq unimplemented" if $Backq;
    local $Backq=1;
    my @s;
    my $k = $n->kid(0);
    if ($k->isa('Rc::Var')) {
	my $v = $k->kid(0);
	if ($v->isa('Rc::Word') and $v->string eq 'ifs') {}
	else {
	    push @s, 'IFS='.$v->shp;
	}
    } else {
	die "backq with strange ifs"
    }
    # quotemeta XXX
    '`'.$n->kid(1)->shp.'`'
}

*Rc::Flat::shp = \&HELP;
*Rc::Count::shp = \&HELP;
sub Rc::Var::shp { "\$". as_var(shift->kid(0)) }

sub _body {
    my $n=shift;
    my @s;
    my @k = $n->kids;
    push @s, $k[0]->shp; # $k[0] always set? XXX
    if (!$k[1]->isa('Rc::Undef')) {
	if (!$k[0]->isa('Rc::Nowait')) {
	    push @s, nl;
	}
	push @s, $k[1]->shp;
    }
    join '', @s;
}

*Rc::Body::shp = \&_body;
*Rc::Cbody::shp = \&_body;

sub Rc::Brace::shp {
    my $n=shift;
    my $k1=$n->kid(1);
    '{'.indent { nl.$n->kid(0)->shp }.nl.'}'.
	(!$k1->isa("Rc::Undef")? $k1->shp:'')
}

sub Rc::Assign::shp {
    my ($n) = @_;
    my $name = $n->kid(0)->shp;
    $name.'='.$n->kid(1)->shp.($Local{$name}? '':'; export '.$name)
}

sub Rc::Pre::shp {
    my $n=shift;
    my @l;
    my @s = ("# LOCALISATION BLOCK");
    while (1) {
	my $mod = $n->kid(0);
	if ($mod->isa('Rc::Assign')) {
	    my $name = $mod->kid(0)->shp;
	    die "sh doesn't do nested localization ($name)"
		if $Local{$name};
	    $Local{$name}=1;
	    push @l, $name;
	    push @s, "$name=".$mod->kid(1)->shp;
	} elsif ($mod->isa('Rc::Redir')) {
	    die "Pre($mod) - not yet"; #move down? XXX
	} else {
	    die "Pre($mod)?";
	}
	if ($n->kid(1)->isa('Rc::Pre')) {
	    $n = $n->kid(1);
	    next;
	}
	last;
    }
    @s = join(nl,@s);
    indent {
	push @s, nl.no_brace($n->kid(1))->shp;
    };
    push @s,nl;
    for (@l) {
	delete $Local{$_};
	push @s, "unset $_".nl;
    }
    join('',@s);
}

sub Rc::Newfn::shp {
    my $n = shift;
    $n->kid(0)->shp.'() {'.indent { nl.$n->kid(1)->shp }.nl.'}'
}

1;

use strict;
package Rc::Csh;  #sea shell backend
use Carp;
use Rc qw($OutputFH);
use vars qw($level %Local $Backq);
$level = 0;

sub HELP { die "Will a 'csh' expert please step forward?" }

sub indent(&) { local $level = $level + 1; shift->() }
sub nl() { "\n" . ' 'x($level*4) }

sub Rc::Node::csh {
    print $OutputFH shift->chp(). "\n";
}

sub Rc::Node::chp {
    my $n=shift;
    die ref($n)." not implemented yet for 'csh'";
}

sub Rc::Word::chp { shift->string }

sub Rc::Qword::chp {
    my $s = shift->string;
    # quotemeta XXX
    "'$s'"
}

sub no_brace {
    my $n=shift;
    $n->isa('Rc::Brace')? $n->kid(0) : $n
}

sub Rc::If::chp {
    my $n=shift;
    my $k = $n->kid(1);
    'if ('.$n->kid(0)->chp.') then'.
	($k->isa('Rc::Else')? $k->chp :
	 indent { nl.no_brace($k)->chp }.nl.'endif' )
}

sub Rc::Orelse::chp {
    my $n=shift;
    die "csh doesn't know || {}" if $n->kid(1)->isa('Rc::Brace');
    join(' || ', map { $_->chp } $n->kids);
}

sub Rc::Concat::chp {
    my $n = shift;
    # maybe some sanity check? XXX
    join('', map { $_->chp } $n->kids);
}

sub Rc::Else::chp {
    my $n =shift;
    my $k = $n->kid(1);
    indent { nl.$n->kid(0)->chp }.nl.do {
	if ($k->isa('Rc::If')) {
	    'else '.$k->chp
	} else {
	    'else '.nl.$k->chp;
	}
    };
}

sub Rc::Args::chp {
    my $n = shift;
    join(' ', map { $_->chp } $n->kids)
}

sub as_var {
    my ($k) = @_;
    my $varname;
    if ($k->isa('Rc::WordX')) {
	$varname = $k->chp;
	if ($varname =~ /[:=-?+%\#]/) {
	    die "metacharacters found in var '$varname'";
	}
    } else {
	die "don't know how use $k as a variable"
    }
    "{$varname}"
}

sub Rc::Backq::chp {
    my $n=shift;
    die "nested Backq unimplemented" if $Backq;
    local $Backq=1;
    my @s;
    my $k = $n->kid(0);
    if ($k->isa('Rc::Var')) {
	my $v = $k->kid(0);
	if ($v->isa('Rc::Word') and $v->string eq 'ifs') {}
	else {
	    die "csh only has space separated ifs?";
	}
    } else {
	die "backq with strange ifs"
    }
    # quotemeta XXX
    '`'.$n->kid(1)->chp.'`'
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
	if ($x->isa('Rc::Var')) {
	    "! \${?".$x->kid(0)->chp."}";
	} else {
	    die $x;
	}
    } else {
	die "don't know how to match against $y";
    }
}

sub Rc::Match::chp {
    my $n=shift;
    join(' || ', map { _match($n->kid(0), $_) } _words($n->kid(1)))
}

sub Rc::Var::chp { "\$". as_var(shift->kid(0)) }

sub _body {
    my $n=shift;
    my @s;
    my @k = $n->kids;
    push @s, $k[0]->chp; # $k[0] always set? XXX
    if (!$k[1]->isa('Rc::Undef')) {
	if (!$k[0]->isa('Rc::Nowait')) {
	    push @s, nl;
	}
	push @s, $k[1]->chp;
    }
    join '', @s;
}

*Rc::Body::chp = \&_body;
*Rc::Cbody::chp = \&_body;

sub Rc::Brace::chp {
    my $n=shift;
    my $k1=$n->kid(1);
    '{'.indent { nl.$n->kid(0)->chp }.nl.'}'.
	(!$k1->isa('Rc::Undef')? $k1->chp:'')
}

sub Rc::Assign::chp {
    my ($n) = @_;
    my $name = $n->kid(0)->chp;
    if ($Local{$name}) {
	'set '.$name.' = '.$n->kid(1)->chp.nl
    } else {
	'setenv '.$name.' '.$n->kid(1)->chp.nl
    }
}

sub Rc::Pre::chp {
    my $n=shift;
    my @l;
    my @s = ("# LOCALISATION BLOCK");
    while (1) {
	my $mod = $n->kid(0);
	if ($mod->isa('Rc::Assign')) {
	    my $name = $mod->kid(0)->chp;
	    die "sh doesn't do nested localization ($name)"
		if $Local{$name};
	    $Local{$name}=1;
	    push @l, $name;
	    push @s, "set $name = ".$mod->kid(1)->chp;
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
	push @s, nl.no_brace($n->kid(1))->chp;
    };
    push @s,nl;
    for (@l) {
	delete $Local{$_};
	push @s, "unset $_".nl;
    }
    join('',@s);
}

sub Rc::Newfn::chp {
    die "csh doesn't have functions...";
}

1;

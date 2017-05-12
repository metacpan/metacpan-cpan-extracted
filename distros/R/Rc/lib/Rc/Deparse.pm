use strict;
package Rc::Deparse;
use Rc qw($OutputFH);
use vars qw($level);
$level = 0;

# This is a perl implementation of footobar.c!

sub indent(&) { local $level = $level + 1; shift->() }

sub nl() { "\n" . ' 'x($level*4) }

sub Rc::Node::deparse {
    print $OutputFH shift->dp()."\n";
}

sub Rc::Undef::dp { '()' }

sub Rc::Word::dp { shift->string }

sub Rc::Qword::dp {
    my $s = shift->string;
    $s =~ s/\'/\'\'/g;
    "'$s'"
}

sub Rc::Bang::dp { '!' . shift->kid(0)->dp() }

sub Rc::Case::dp { 'case '. shift->kid(0)->dp() }

sub Rc::Nowait::dp { shift->kid(0)->dp() . '&' }

sub Rc::Rmfn::dp { 'fn '.shift->kid(0)->dp() }

sub Rc::Subshell::dp { ' @'.shift->kid(0)->dp() }

sub Rc::Andalso::dp {
    my $n = shift;
    join(' && ', map { $_->dp } $n->kids);
}

sub Rc::Assign::dp {
    my $n = shift;
    join('=', map { $_->dp } $n->kids);
}

sub Rc::Concat::dp {
    my $n = shift;
    join('^', map { $_->dp } $n->kids);
}

sub Rc::Else::dp {
    my $n = shift;
    '{'.indent { nl.$n->kid(0)->dp }.nl.'} else '.$n->kid(1)->dp
}

sub Rc::Newfn::dp {
    my $n = shift;
    'fn '.$n->kid(0)->dp.' {'.indent { nl.$n->kid(1)->dp }.nl.'}'
}

sub Rc::If::dp {
    my $n=shift;
    my $k = $n->kid(1);
    'if ('.$n->kid(0)->dp.')'.
	($k->isa('Rc::Else')? ' '.$k->dp : indent { nl.$k->dp });
}

sub Rc::Orelse::dp {
    my $n=shift;
    join(' || ', map { $_->dp } $n->kids);
}

sub Rc::Args::dp {
    my $n = shift;
    join(' ', map { $_->dp } $n->kids)
}

sub Rc::Switch::dp {
    my $n =shift;
    'switch ('.$n->kid(0)->dp.') {'.$n->kid(1)->dp.'}'
}

sub Rc::Match::dp {
    my $n=shift;
    '~ '.$n->kid(0)->dp.' '.$n->kid(1)->dp
}

sub Rc::While::dp {
    my $n=shift;
    'while ('.$n->kid(0)->dp.') '.$n->kid(1)->dp
}

sub Rc::Lappend::dp {
    my $n=shift;
    '('.join(' ', map { $_->dp } $n->kids).')'
}

sub Rc::Forin::dp {
    my $n=shift;
    'for ('.$n->kid(0)->dp.' in '.$n->kid(1)->dp.') '.$n->kid(2)->dp
}

sub Rc::Varsub::dp {
    my $n=shift;
    "\$".$n->kid(0)->dp.'('.$n->kid(1)->dp.')'
}

sub _varop {
    my ($op,$k) = @_;
    if ($k->isa('Rc::WordX')) {
	# maybe wrong for Qword? XXX
	$op.$k->dp;
    } else {
	$op.'('.$k->dp.')'
    }
}

sub Rc::Count::dp { _varop("\$#", shift->kid(0)) }
sub Rc::Flat::dp { _varop("\$^", shift->kid(0)) }
sub Rc::Var::dp { _varop("\$", shift->kid(0)) }

sub Rc::Dup::dp {
    my $n=shift;
    if ($n->right != -1) {
	$n->redir.'['.$n->left.'='.$n->right.']'
    } else {
	$n->redir.'['.$n->left.'=]'
    }
}

sub Rc::Backq::dp {
    my $n=shift;
    my $k = $n->kid(0);
    my $ifs;
    if ($k->isa('Rc::Var')) {
	my $v = $k->kid(0);
	$ifs=1 if ($v->isa('Rc::Word') and $v->string eq 'ifs');
    }
    ($ifs? '`' : '`` '.$k->dp.' ').'{'.$n->kid(1)->dp.'}'
}

sub _body {
    my $n=shift;
    my @s;
    my @k = $n->kids;
    push @s, $k[0]->dp; # $k[0] always set? XXX
    if (!$k[1]->isa('Rc::Undef')) {
	if (!$k[0]->isa('Rc::Nowait')) {
	    push @s, nl;
	}
	push @s, $k[1]->dp;
    }
    join '', @s;
}

*Rc::Body::dp = \&_body;
*Rc::Cbody::dp = \&_body;

sub Rc::Brace::dp {
    my $n=shift;
    my $k1=$n->kid(1);
    '{'.indent { nl.$n->kid(0)->dp }.nl.'}'.(!$k1->isa("Rc::Undef")? $k1->dp:'')
}

sub _mod {
    my $n=shift;
    join ' ', map { $_->dp } $n->kids;
}

*Rc::Pre::dp = \&_mod;
*Rc::Epilog::dp = \&_mod;

sub Rc::Pipe::dp {
    my $n=shift;
    my @k = $n->kids;
    my @fd = $n->fds;
    ($k[0]->dp.
     ' |'.
     ($fd[1] != 0? "[$fd[0]=$fd[1]]":
      $fd[0] != 1? "[$fd[1]]":
      '').
     ' '.
     $k[1]->dp);
}

sub _redir {
    my $n=shift;
    my $dir = $n->redir;
    ($dir.
     ($n->fd != ($dir =~ m/^\</? 0:1)? '['.$n->fd.']' : '').
     ($n->isa('Nmpipe')? '{'.$n->targ->dp.'}' : $n->targ->dp))
}

*Rc::Redir::dp = \&_redir;
*Rc::Nmpipe::dp = \&_redir;

1;

use strict;
package Rc::Terse;
use Rc qw($OutputFH);
use Carp;
use vars qw($level);

$level = 0;

sub Rc::Node::terse {
    my $n = shift;
    print $OutputFH $n->terse_str()."\n";
}

sub indent(&) {
    local $level = $level + 1;
    shift->();
}

sub nl() { "\n" . ' 'x$level }

sub Rc::Undef::terse_str { '()' }

sub Rc::WordX::terse_str {
    my $n = shift;
    $n->type.'['.$n->string.']'
}

sub Rc::UnaryCmd::terse_str {
    my $n = shift;
    join('',
	 $n->type().'(',
	 indent { $n->kid(0)->terse_str() },
	 ')')
}

sub Rc::BinCmd::terse_str {
    my $n = shift;
    join('',
	 $n->type().'(',
	 indent {nl.$n->kid(0)->terse_str().','.nl .$n->kid(1)->terse_str() },
	 nl.')');
}

sub Rc::Forin::terse_str {
    my $n = shift;
    join('','For(',
	 indent { nl.join(nl, map { $n->kid($_)->terse_str } 0..2) },
	 nl.')');
}

sub Rc::Dup::terse_str {
    my $n = shift;
    'Dup('.$n->redir.','.$n->left.'='.$n->right.')'
}

sub Rc::Redir::terse_str {
    my $n = shift;
    join('',$n->type.'('.$n->redir.','.$n->fd.',',
	 indent { nl.$n->targ->terse_str },
	 nl.')');
}

*Rc::Nmpipe::terse_str = \&Rc::Redir::terse_str;

sub Rc::Pipe::terse_str {
    my $n = shift;
    my @fd = $n->fds;
    my @k = $n->kids;
    join('',$k[0]->terse_str, nl, $fd[0].'|'.$fd[1], nl, $k[1]->terse_str);
}

1;

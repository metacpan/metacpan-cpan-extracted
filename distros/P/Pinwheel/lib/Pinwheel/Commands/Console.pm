package Pinwheel::Commands::Console;

use strict;
use warnings;

use Data::Dumper;
use Term::ReadLine;
use PPI;

sub p
{
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    print Dumper(shift) . "\n";
}

sub is_silent
{
    my ($coderef, $d) = @_;

    $d = PPI::Document->new($coderef);
    return $d->find_any(sub {
        $_[1]->isa('PPI::Token::Operator') and $_[1]->content eq '='
    });
}

my ($_r_, $_n_);
my $_term_ = Term::ReadLine->new('console');
$_term_->ornaments('0,0,0,0');
while (defined($_ = $_term_->readline('>>> '))) {
    s/ +$//;
    $_n_++;
    $_r_ = eval qq{
        package main;
        no strict qw(vars subs refs);
#line $_n_ "console"
        $_;
    };
    warn $@ if $@;
    p($_r_) unless ($@ || !$_ || is_silent(\$_));
}

END { print "\n" }

1;

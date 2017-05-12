package Net::SPOCP::SExpr;

use 5.006;
use strict;
use warnings;

@Net::SPOCP::SExpr::ISA = qw(Net::SPOCP);

# [ [ 'resource' , 'etc' 'group' ] [ 'subject' 'uid' 'leifj' ] [ 'foo' '*' '1' '2' ] ]

package Net::SPOCP::SExpr::Atom;
@Net::SPOCP::SExpr::Atom::ISA = qw(Net::SPOCP::SExpr);

sub new
  {
    my $self = shift;
    my $class = ref $self || $self;

    bless { data => $_[0], length => length($_[0]) },$class;
  }

sub toString
  {
    sprintf("%d:%s",$_[0]->{length},$_[0]->{data});
  }

package Net::SPOCP::SExpr;

sub create
  {
    my ($class,$x) = @_;

    if (ref $x eq 'ARRAY')
      {
	my @out;
	foreach my $item (@{$x})
	  {
	    push(@out,$class->create($item));
	  }
	return bless \@out,$class;
      }
    elsif (ref $x eq 'HASH')
      {
	my @out;
	foreach my $key (keys %{$x})
	  {
	    my $v = $class->create($x->{$key});
	    if (ref $x->{$key})
	      {
		unshift(@{$v},$class->create($key));
		push(@out,$v);
	      }
	    else
	      {
		push(@out,bless [$class->create($key),$v],$class);
	      }
	  }
	return bless \@out,$class;
      }
    else
      {
	return Net::SPOCP::SExpr::Atom->new($x);
      }
  }

sub new
  {
    my $self = shift;
    my $class = ref $self || $self;
    my @expr = @_;
    $expr[0] = "" unless defined $expr[0];

    if (ref $expr[0] eq 'ARRAY')
      {
	return $class->create($expr[0]);
      }
    elsif ($expr[0] =~ m/^\(.*\)$/)
      {
  return $class->create($class->toList($expr[0]));
      }
    else
      {
	return $class->create(\@expr);
      }
  }

sub parse
  {
    my $self = shift;
    my $io = shift;

    my @stack;

    while ($_)
      {
	
      }
  }

sub items
  {
    @{$_[0]};
  }

sub toString
  {
    my $out = "(";
    foreach my $item ($_[0]->items)
      {
	$out .= $item->toString();
      }
    $out .= ")";

    $out;
  }

sub toList
  {
    use Net::SPOCP::SExpr::Parser;
    my $self = shift;
    my $sexpr = shift;

    my $parser = new Net::SPOCP::SExpr::Parser();
    $parser->YYData->{INPUT} = $sexpr;
    $parser->YYParse(yylex => \&Net::SPOCP::SExpr::Parser::yylex);
  }

1;

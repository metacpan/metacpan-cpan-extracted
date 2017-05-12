# Implements the unification algorithm for type inference described
# in the Dragon's book by Aho, Sethi and Ullman, chapter 6. Section 6.7. page 376
package Parse::Eyapp::Unify;
use Data::Dumper;
use Parse::Eyapp::Node;
use base qw (Exporter);
our @EXPORT = qw(unify representative strunifiedtree hnewunifiedtree newunifiedtree);

my $count = 0;
my $set = 'representative';
my $isvar = sub { }; 
my $samebasic = sub { };

# Not OOP
sub set {
   my $class = shift if @_ %2;
	 $class = __PACKAGE__ unless defined($class);

   my %handler = @_;
 
   $set = 'representative';
   $set = $handler{key} if exists($handler{key});
   $isvar = $handler{isvar} if exists($handler{isvar});
   $samebasic = $handler{samebasic} if exists($handler{samebasic});
   $count = 0;

	 bless { key => $set, isvar => $isvar, samebasic => $samebasic, count => $count }, $class;
}

sub mergevar {
  my ($s, $t) = @_;

  if ($isvar->($s))  {
    $s->{$set} = representative($t);
    # print "Merged ".representative($s)->str." and ".representative($t)->str."\n";
    return 1;
  }
  if ($isvar->($t)) {
    $t->{$set} = representative($s);
    # print "Merged ".representative($s)->str." and ".representative($t)->str."\n";
    return 1;
  }
  return 0;
}

sub representative {
  my $t = shift;

  if (@_) {
    $t->{$set} = shift;
    return $t;
  }
	$t = $t->{$set} while defined($t->{set}) && ($t != $t->{$set});
	die "Representative ($set) not defined!".Dumper($t) unless defined($t->{set});
  return $t;
}

sub unify {
  my ($m, $n) = @_;

  my $s = representative($m);
  my $t = representative($n);

  return 1 if ($s == $t);
  
  return 1 if $samebasic->($s, $t);

  # print "Unifying ".representative($s)->str." and ".representative($t)->str."\n";
  return 1 if (mergevar($s, $t));

  if (ref($s) eq ref($t)) {
     $s->{$set} = representative($t);
     my $i = 0;
     for ($s->children) {
       my $tc = $t->child($i++);
       return 0 unless unify($_, $tc);
     }
     return 1;
  }

  return 0;
}

sub strunifiedtree {
	local $Parse::Eyapp::Node::CLASS_HANDLER = sub { ref(representative($_[0])) };
	$_[0]->str;
}

sub hnewunifiedtree {
	local $Parse::Eyapp::Node::INDENT = 0; 
	local $Parse::Eyapp::Node::STRSEP = ","; 
  my $td = strunifiedtree($_[0]);
	Parse::Eyapp::Node->hnew($td);
}

sub newunifiedtree {
	local $Parse::Eyapp::Node::INDENT = 0; 
	local $Parse::Eyapp::Node::STRSEP = ","; 
  my $td = strunifiedtree($_[0]);
	Parse::Eyapp::Node->new($td);
}

1;

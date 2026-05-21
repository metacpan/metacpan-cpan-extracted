package Tie::ArrayNoNull;
use Nobody::Util;
use Tie::Array;
our($AUTOLOAD);
sub AUTOLOAD {
  my($s)="$AUTOLOAD";
  for($s) {
    s{.*::}{};
  };
  if($s eq "TIEARRAY") {
    return bless(Tie::StdArray->TIEARRAY(@_),shift);
  } else {
    if(wantarray){
      local(@_)=eval "Tie::StdArray::$s(\@_)";
      die "NULL!" if grep { !defined } @{$_[0]};
      return @_;
    } elsif(defined(wantarray)){
      local($_)=eval "Tie::StdArray::$s(\@_)";
      die "NULL!" if grep { !defined } @{$_[0]};
      return $_;
    } else {
      eval "Tie::StdArray::$s(\@_)";
      die "NULL!" if grep { !defined } @{$_[0]};
    };
  };
};
1;

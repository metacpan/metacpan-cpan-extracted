package Nobody::Exes;
require Exporter;
our(@EXPORT);
BEGIN {
  push(@EXPORT,qw( path_find editor ));
};
*import=\&Exporter::import;
use Env qw(@PATH @PERL5LIB @LD_LIBRARY_PATH @MANPATH);
use Nobody::Util;

sub path_find {
  my($cb)=shift;
  local($_,@_)=@_;
  $_=[$_] unless 'ARRAY'eq ref;
  if(m{^/}){
    @_="";
  } else {
    my($tgt)=$_;
    @_=map { s{/*$}{}; my $dir=$_; map { "$dir/$_" } @$tgt } @_;
  };
  @_=grep { -e } @_;
  @_ = grep { $cb->($_) } @_;
};
sub exe {
  sub { -x };
};
sub editor {
  my(%res);
  local(@_)=($ENV{EDITOR}, $ENV{VISUAL}, "vim", "vi");
  my($found)=0;
  $res{$_}=++$found for path_find(exe(),\@_,@PATH);
  sort {$res{$a}<=>$res{$b}} keys %res;
};
unless(caller){
  eex path_find(exe(), "sh",@PATH);
};

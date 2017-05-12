use strictures 1;

package Object::Remote::GlobProxy;
require Tie::Handle;
our @ISA = qw( Tie::Handle );

sub TIEHANDLE {
  my ($class, $glob_container) = @_;
  return bless { container => $glob_container }, $class;
}

my @_delegate = (
  [READLINE => sub { wantarray ? $_[0]->getlines : $_[0]->getline }],
  (map { [uc($_), lc($_)] } qw(
    write
    print
    printf
    read
    getc
    close
    open
    binmode
    eof
    tell
    seek
  )),
);

for my $delegation (@_delegate) {
  my ($from, $to) = @$delegation;
  no strict 'refs';
  *{join '::', __PACKAGE__, $from} = sub {
    $_[0]->{container}->$to(@_[1 .. $#_]);
  };
}

1;

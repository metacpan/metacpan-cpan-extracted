package Term::ReadLine::TTYtter;
use Carp;
@ISA = qw(Term::ReadLine::Stub Term::ReadLine::TTYtter::Compa Term::ReadLine::TTYtter::AU);

$VERSION = $VERSION = 1.4;

sub readline {
  shift; 
  &readline_ttytter::readline(@_);
}

*addhistory = \&AddHistory;
*settophistory = \&SetTopHistory;

$readline_ttytter::minlength = 1;	# To pacify -w
$readline_ttytter::rl_readline_name = undef; # To pacify -w
$readline_ttytter::rl_basic_word_break_characters = undef; # To pacify -w

sub new {
  if (defined $term) {
    warn "Cannot create second readline interface, falling back to dumb.\n";
    return Term::ReadLine::Stub::new(@_);
  }
  shift;			# Package
  if (@_) {
    if ($term) {
      warn "Ignoring name of second readline interface.\n" if defined $term;
      shift;
    } else {
      $readline_ttytter::rl_readline_name = shift; # Name
    }
  }
  if (!@_) {
    if (!defined $term) {
      ($IN,$OUT) = Term::ReadLine->findConsole();
      # Old Term::ReadLine did not have a workaround for a bug in Win devdriver
      $IN = 'CONIN$' if $^O eq 'MSWin32' and "\U$IN" eq 'CON';
      open IN,
	# A workaround for another bug in Win device driver
	(($IN eq 'CONIN$' and $^O eq 'MSWin32') ? "+< $IN" : "< $IN")
	  or croak "Cannot open $IN for read";
      open(OUT,">$OUT") || croak "Cannot open $OUT for write";
      $readline_ttytter::term_IN = \*IN;
      $readline_ttytter::term_OUT = \*OUT;
    }
  } else {
    if (defined $term and ($term->IN ne $_[0] or $term->OUT ne $_[1]) ) {
      croak "Request for a second readline interface with different terminal";
    }
    $readline_ttytter::term_IN = shift;
    $readline_ttytter::term_OUT = shift;    
  }
  eval {require Term::ReadLine::readline_ttytter}; die $@ if $@;
  # The following is here since it is mostly used for perl input:
  # $readline_ttytter::rl_basic_word_break_characters .= '-:+/*,[])}';
  $term = bless [$readline_ttytter::term_IN,$readline_ttytter::term_OUT];
  unless ($ENV{PERL_RL} and $ENV{PERL_RL} =~ /\bo\w*=0/) {
    local $Term::ReadLine::termcap_nowarn = 1; # With newer Perls
    local $SIG{__WARN__} = sub {}; # With older Perls
    $term->ornaments(1);
  }
  return $term;
}
sub newTTY {
  my ($self, $in, $out) = @_;
  $readline_ttytter::term_IN   = $self->[0] = $in;
  $readline_ttytter::term_OUT  = $self->[1] = $out;
  my $sel = select($out);
  $| = 1;				# for DB::OUT
  select($sel);
}
sub ReadLine {'Term::ReadLine::TTYtter'}
sub Version { $Term::ReadLine::TTYtter::VERSION }
sub MinLine {
  my $old = $readline_ttytter::minlength;
  $readline_ttytter::minlength = $_[1] if @_ == 2;
  return $old;
}
sub SetHistory {
  shift;
  @readline_ttytter::rl_History = @_;
  $readline_ttytter::rl_HistoryIndex = @readline_ttytter::rl_History;
}
sub GetHistory {
  @readline_ttytter::rl_History;
}
sub AddHistory {
  shift;
  push @readline_ttytter::rl_History, @_;
  $readline_ttytter::rl_HistoryIndex = @readline_ttytter::rl_History + @_;
}
sub SetTopHistory {
  shift;
  pop @readline_ttytter::rl_History;
  push @readline_ttytter::rl_History, @_;
  $readline_ttytter::rl_HistoryIndex = @readline_ttytter::rl_History;
}
%features =  (appname => 1, minline => 1, autohistory => 1, getHistory => 1,
	      setHistory => 1, addHistory => 1, preput => 1, 
	      attribs => 1, 'newTTY' => 1, canRemoveReadline => 1,
              canRepaint => 1, canSetTopHistory => 1, canBackgroundSignal => 1,
              canHookUseAnsi => 1, canHookNoCounter => 1,
	      tkRunning => Term::ReadLine::Stub->Features->{'tkRunning'},
	      ornaments => Term::ReadLine::Stub->Features->{'ornaments'},
	     );
sub Features { \%features; }
# my %attribs;
tie %attribs, 'Term::ReadLine::TTYtter::Tie' or die ;
sub Attribs {
  \%attribs;
}
sub DESTROY {}

package Term::ReadLine::TTYtter::AU;

sub AUTOLOAD {
  { $AUTOLOAD =~ s/.*:://; }		# preserve match data
  my $name = "readline_ttytter::rl_$AUTOLOAD";
  die "Cannot do `$AUTOLOAD' in Term::ReadLine::TTYtter" 
    unless exists $readline_ttytter::{"rl_$AUTOLOAD"};
  *$AUTOLOAD = sub { shift; &$name };
  goto &$AUTOLOAD;
}

package Term::ReadLine::TTYtter::Tie;

sub TIEHASH { bless {} }
sub DESTROY {}

sub STORE {
  my ($self, $name) = (shift, shift);
  $ {'readline_ttytter::rl_' . $name} = shift;
}
sub FETCH {
  my ($self, $name) = (shift, shift);
  $ {'readline_ttytter::rl_' . $name};
}

package Term::ReadLine::TTYtter::Compa;

sub get_c {
  my $self = shift;
  getc($self->[0]);
}

sub get_line {
  my $self = shift;
  my $fh = $self->[0];
  scalar <$fh>;
}

1;

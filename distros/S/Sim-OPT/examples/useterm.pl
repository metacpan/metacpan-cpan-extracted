use strict;
use warnings;
use Term::ReadKey;

my $cfg   = {};        # your config structure
my $dirty = 0;
my $state = 'MAIN';

sub clear_screen { print "\e[2J\e[H"; }   # optional

sub read_key {
  ReadMode('cbreak');
  my $k = ReadKey(0);
  ReadMode('restore');
  return $k;
}

sub read_line {
  ReadMode('restore');                 # ensure normal line mode
  my $line = <STDIN>;
  defined $line or return undef;
  $line =~ s/\R\z//;
  return $line;
}

sub render_main {
  my ($cfg, $dirty) = @_;
  clear_screen();
  print "Sim::OPT config editor", ($dirty ? "  [modified]" : ""), "\n";
  print "----------------------\n";
  print "a) Morphing\n";
  print "b) Simulation\n";
  print "c) Objectives\n";
  print "d) Constraints\n";
  print "s) Save\n";
  print "l) Load\n";
  print "v) Validate\n";
  print "x) Exit\n";
  print "\nSelect option: ";
}

sub validate_cfg {
  my ($cfg) = @_;
  my @err;
  push @err, "missing simulator" unless defined $cfg->{simulator};
  return @err;
}

sub save_cfg {
  my ($cfg) = @_;
  print "\nSave to file: ";
  my $f = read_line();
  return if !defined $f || $f eq '';
  open my $fh, ">", $f or do { print "Cannot write: $!\nPress any key..."; read_key(); return; };
  # TODO: write in your preferred format
  print $fh "# generated config\n";
  print $fh "simulator=$cfg->{simulator}\n" if defined $cfg->{simulator};
  close $fh;
  print "Saved.\nPress any key...";
  read_key();
}

sub load_cfg {
  my ($cfg) = @_;
  print "\nLoad from file: ";
  my $f = read_line();
  return if !defined $f || $f eq '';
  open my $fh, "<", $f or do { print "Cannot read: $!\nPress any key..."; read_key(); return; };
  while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
    if ($line =~ /^simulator=(.*)$/) { $cfg->{simulator} = $1; }
  }
  close $fh;
  print "Loaded.\nPress any key...";
  read_key();
}

while (1) {
  if ($state eq 'MAIN') {
    render_main($cfg, $dirty);
    my $k = read_key();
    $k = lc($k // '');

    if    ($k eq 'a') { $state = 'MORPH'; }
    elsif ($k eq 'b') { $state = 'SIM'; }
    elsif ($k eq 'c') { $state = 'OBJ'; }
    elsif ($k eq 'd') { $state = 'CONS'; }
    elsif ($k eq 'v') {
      my @err = validate_cfg($cfg);
      print "\n", (@err ? join("\n", @err) : "ok"), "\nPress any key...";
      read_key();
    }
    elsif ($k eq 's') { save_cfg($cfg); $dirty = 0; }
    elsif ($k eq 'l') { load_cfg($cfg); $dirty = 1; }
    elsif ($k eq 'x') {
      if ($dirty) {
        print "\nUnsaved changes. Exit anyway? (y/n): ";
        my $yn = lc(read_key() // '');
        next unless $yn eq 'y';
      }
      last;
    }
    else {
      print "\nInvalid option. Press any key...";
      read_key();
    }
  }

  # You will add MORPH/SIM/OBJ/CONS states similarly, each with q) back.
  if ($state ne 'MAIN') {
    clear_screen();
    print "$state menu (stub)\nq) back\nSelect option: ";
    my $k = lc(read_key() // '');
    $state = 'MAIN' if $k eq 'q';
  }
}
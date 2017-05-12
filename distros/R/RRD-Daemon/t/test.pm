package test;

use base  qw( Exporter );
our @EXPORT_OK = qw( BIN_DIR DATA_DIR 
                     test_capture test_compare );

use Carp                   qw( croak );
use Env                    qw( @PERL5LIB );
use File::Compare          qw( cmp );
use File::Spec::Functions  qw( catdir catfile updir );
use FindBin                qw( $Bin );
use Test::More             ( import => [qw( diag is ok ) ]);

use constant TOP_DIR    => catdir  $Bin, updir;
use constant BIN_DIR    => catdir  TOP_DIR, 'bin';
use constant LIB_DIR    => catdir  TOP_DIR, 'lib';
use constant DATA_DIR   => catdir  TOP_DIR, 'data';

unshift @PERL5LIB, LIB_DIR;

BEGIN { # this has to be in a begin block so that the rest of the code can
        # see $EXITVAL, etc.
  eval {
    require IPC::System::Simple;
    IPC::System::Simple->import(qw( capturex systemx $EXITVAL EXIT_ANY ));
  }; if ( $@ ) {
    diag $@;
    push @require_not_ok, 'IPC::System::Simple';
  }

  Test::More->import(skip_all => join(',', @require_not_ok) . ' not found')
    if @require_not_ok;
}

sub import { 
  my ($class, @a) = @_;
  croak 'must specify test count'
    unless $a[0] eq 'tests';
  my $test_count = $a[1];
  Test::More::plan tests => $test_count;
  $class->export_to_level(1, $class, @a[2..$#a]);
}

sub test_capture {
  my ($cmd, $expect, $cmdname) = @_;

  $cmdname //= join ' ', @$cmd;

  my $text = capturex EXIT_ANY, @$cmd;
  my $exit = $EXITVAL;
  is 0, $exit, "exit val $cmdname";
  is $text, $expect, "output of $cmdname";
}

sub test_compare {
  my ($cmd, $out_fn, $ref_fn, $cmdname) = @_;

  $cmdname //= join ' ', @$cmd;

  my $text = systemx EXIT_ANY, @$cmd; # we EXIT_ANY because we test the code later
  my $exit = $EXITVAL;
  is 0, $exit, "exit val $cmdname";
  ok !cmp($out_fn, $ref_fn), "compare of $out_fn with $ref_fn";
}

1; # keep require happy

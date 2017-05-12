#!/sig/local/bin/perl5 -w

use ExtUtils::MakeMaker;
BEGIN {
  eval {
    require ExtUtils::MM_PRCS;
    import ExtUtils::MM_PRCS;
  };
  if ($@ and $@ =~ /Can\'t locate/) {
    print STDERR "Ignore \"Not a known parameter name\" warnings.\n";
  } elsif ($@) {
    die;
  }
}

WriteMakefile(
  VERSION => '0.1',
  LIBS => [q[-lfam]],
  NAME => q(Sys::Gamin),
  EXE_FILES => [qw(monitor)]
);

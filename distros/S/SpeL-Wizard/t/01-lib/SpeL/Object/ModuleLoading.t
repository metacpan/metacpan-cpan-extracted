# -*- cperl -*-
use Test::More;

my @modules = map { $_ =~ s/lib\/(.+)\.pm$/$1/;
		    $_ =~ s/\//::/g;
		    $_
		  } glob( "lib/SpeL/Object/*.pm" );

plan tests => scalar @modules;

foreach my $module ( @modules ) {
  { 
    use_ok( "$module" );
  }
}


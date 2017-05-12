use strict;
use warnings;

use ExtUtils::MakeMaker;
use Data::Dumper;

my $ok;
my @errors;

{
	eval "require Text::Aspell";
	if ($@){
		push(@errors, "No Text::Aspell installed");
		last;
	}
	
	my $aspell = Text::Aspell->new;
	if (not $aspell){
		push @errors, 'Could not make Aspell object';
		last;
	}

	$aspell->check('house');
	if ($aspell->errstr){
		push @errors, 'Aspell: ' . $aspell->errstr;
		last;
	}
	
	$ok = 1;
}

if (not $ok){
	eval "require Lingua::Ispell";
	if ($@){
		push @errors, 'No Ispell';
	} 
	
	elsif (Lingua::Ispell->VERSION < 0.07){
		push @errors, 'Sorry, only Linuga::Ispell version >= 0.07 is supported ';
	}
	
	else {
		
		FIND: 
		foreach my $p (
			'', # Already on the PATH?
			qw( 
				/usr/local/bin/
				/usr/local/sbin/
				/usr/bin/
				/opt/usr/bin/
				/opt/local/bin/
			)
		){
			my $path = $p . ($^O eq 'MSWin32'? 'ispell.exe' : 'ispell');
			if (`$path -v`){
				no warnings;
				$Lingua::Ispell::path = $path;
				$ok = 1;
				last FIND;
			}
			push @errors, "Could not find ispell as $path";
		}
		
		if ($ok){
			$ok = undef;
			my $r;
			eval { $r = Lingua::Ispell::spellcheck( 'house' ) };
			if ($@){
				push @errors, "Ispell died: $@";
			}
			elsif (ref $r) { # API changed, no rv for correect spelling: $r->{type} =~ /^(miss|guess|none)$/){
				push @errors, "Ispell could not spell 'house'";
			} 
			else {
				$ok = 1;
			}
		}
	}
}

if (not $ok){
	print <<_STOP_;

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

This module  requires you  have  installed  on your system
one of either Lingua::Ispell or  Text::Aspell Perl modules,
along with their binaries, and that they are configured to 
function correctly: it appears this is not the case.

If you feel this  message to be  in  error, please contact
the author via LGoddard-at-CPAN-dot-org.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

_STOP_

	warn join "\n", @errors;
	warn "Writing Makefile anyway\n";
} 

# else 
{
	
	
	WriteMakefile(
	  # ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
	  license( 'perl' ),
	  NAME          => 'Pod::Spelling',
	  AUTHOR        => 'Lee Goddard <lgoddard@cpan.org>',
	  VERSION		=> '0.23',
	  ABSTRACT_FROM => 'lib/Pod/Spelling.pm',
	  PL_FILES      => {},
	  PREREQ_PM     => {
		'Pod::POM'	=> 0.04,
		'Test::Pod' => 0,
		'Test::Builder' => 0,
		'Test::Pod'	=> 0,
	  },
	  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	  clean => { FILES    => 'Pod-Spelling-*' },
	);

}

sub license {
  my $lic = shift;
  local $^W = 0;    # Silence warning about non-numeric version
  return
   unless $ExtUtils::MakeMaker::VERSION >= '6.31';
  return ( LICENSE => $lic );
}




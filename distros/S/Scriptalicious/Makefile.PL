#!/usr/bin/perl
#
use ExtUtils::MakeMaker;
# See perldoc Module::Build for details of how this works

my @recommends = qw(Text::Wrap Time::HiRes YAML);

for my $module ( @recommends ) {
    eval "use $module";
    if ( $@ ) {
	warn "Failed to load optional dependency $module ($@)";
    }
}

WriteMakefile
    ( NAME     => 'Scriptalicious',
      VERSION_FROM => "lib/Scriptalicious.pm",
      ( ( $] >= 5.005 ) ?
	( ABSTRACT => "Make scripts more delicious to SysAdmins",
	  AUTHOR     => "Sam Vilain <samv\@cpan.org>",
	) : () ),
      PREREQ_PM => {
		    'Test::More' => 0,
		    'Term::ReadKey' => 0,
		   },
      NO_META => 0,
    );

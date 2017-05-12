use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Simple::Types',
    VERSION_FROM      => 'lib/Simple/Types.eyp', # finds $VERSION
    PREREQ_PM         => {Parse::Eyapp => "0"}, # e.g., Module::Name => 1.1
);

sub MY::postamble {
return <<'EOT';
release: 
	eyapp -m Simple::Types -o lib/Simple/Types.pm lib/Simple/Types.eyp
	treereg -m Simple::Types lib/Simple/Trans.trg
	perl -Ilib -c lib/Simple/Types.pm; 

pdf:
	atopdf lib/Simple/Types.eyp lib/Simple/Trans.trg script/usetypes.pl -o /tmp/SimpleTypes.pdf
EOT
}


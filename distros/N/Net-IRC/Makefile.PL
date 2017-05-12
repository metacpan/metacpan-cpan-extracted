# Net::IRC sucks
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

exit 0 if $ENV{AUTOMATED_TESTING};
my $ok = 'I acknowledge that Net::IRC is unsupported and I wish to proceed.';
my $warning = <<WILLROBINSON;
--------------------------------------------------------------------------------
********************************************************************************
DANGER, WILL ROBINSON! DANGER!

This module has been deprecated, abandoned, and is no longer supported. It has
not seen active development in five years, and its original author has moved on.
We *STRONGLY* recommend you port your code to either Bot::BasicBot or
POE::Component::IRC. Please feel free to stop by irc.freenode.net/#perl for help
making this transition. Or, if you insist on proceeding, please type the
following line exactly as is and then press Enter:

$ok
********************************************************************************
--------------------------------------------------------------------------------
WILLROBINSON

-t STDIN or die $warning;
warn $warning;
chomp(my $acceptance = <STDIN>);
die "Refusing to install due to lack of confirmation" unless $acceptance eq $ok;


WriteMakefile(
	      'NAME'  => 'Net::IRC',
	      'PM'    =>  {
		  'IRC.pm'        => '$(INST_LIBDIR)/IRC.pm',
		  'Connection.pm' => '$(INST_LIBDIR)/IRC/Connection.pm',
		  'Event.pm'      => '$(INST_LIBDIR)/IRC/Event.pm',
		  'DCC.pm'        => '$(INST_LIBDIR)/IRC/DCC.pm',
                  'EventQueue.pm' => '$(INST_LIBDIR)/IRC/EventQueue.pm',
		  'Entry.pm'      => '$(INST_LIBDIR)/IRC/EventQueue/Entry.pm',
	      },
              'PREREQ_PM' => {
                  'IO::Select'    => 0,
                  'Carp'          => 0,
                  'Socket'        => 0,
                  'IO::File'      => 0,
                  'IO::Socket'    => 0,
                  'Sys::Hostname' => 0,
              },
	      'VERSION_FROM' => 'IRC.pm', # finds $VERSION
              'dist' => { 'COMPRESS' => 'gzip --best' },
);

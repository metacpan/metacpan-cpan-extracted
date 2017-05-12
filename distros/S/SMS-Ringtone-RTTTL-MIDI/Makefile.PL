use ExtUtils::MakeMaker;
require 5.6.0;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'SMS::Ringtone::RTTTL::MIDI',
    'VERSION_FROM' => 'lib/SMS/Ringtone/RTTTL/MIDI.pm',
    'AUTHOR' => 'Craig Manley (c.manley@skybound.nl)',
    'ABSTRACT' => 'Module for converting RTTTL songs into MIDI format.',
    'PREREQ_PM'	=> {
    		'SMS::Ringtone::RTTTL::Parser' => '0.02',
    		'MIDI::Simple' => '0.77',
    		'IO::String' => '1.01',
    			},
    'dist' => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'}
);

print "\nWARNING: The latest version of IO::String that was around when this\n";
print "module was created was 1.01. This version has a small bug. Fix it by\n";
print "adding the line \"sub BINMODE {}\" to the IO::String module above the\n";
print "line containing \"1;\". If you don't fix it, then you won't be able\n";
print "to use SMS::Ringtone::RTTTL::MIDI.\n";
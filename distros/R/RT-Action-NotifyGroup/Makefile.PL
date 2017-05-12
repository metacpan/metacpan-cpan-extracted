use lib qw(.);
use inc::Module::Install;

$ENV{'WITH_SUBDIRS'} = 'sbin,lib';
RTx                     ('RT-Action-NotifyGroup');
author                  ('Ruslan U. Zakirov <cubic@wildgate.miee.ru>');
license                 ('perl');

requires                ('Getopt::Long');
requires                ('Storable');
recommends		('Pod::PlainText');

my ($lp) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $lib_path = join( ' ', "$RT::LocalPath/lib", $lp );
Configure( { RT_LIB_PATH => $lib_path }, 'sbin/rt-notify-group-admin');

skip( qr/\.in$/ );

&WriteAll;

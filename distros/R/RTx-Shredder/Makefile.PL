use inc::Module::Install;

$ENV{'WITH_SUBDIRS'} = 'sbin,lib,html';
RTx			('RTx-Shredder');
author			('Ruslan U. Zakirov <Ruslan.Zakirov@gmail.com>');
license			('perl');
readme_from ('lib/RTx/Shredder.pm');

rt_too_new('3.8.0');

requires		('DBIx::SearchBuilder', 1.31);
requires		('Getopt::Long');
requires		('Exception::Class', 1.23);

build_requires		('DBD::SQLite');
build_requires		('Test::More');
build_requires		('Test::Deep');
build_requires		('File::Spec');
build_requires		('File::Path');
build_requires		('File::Copy');
build_requires		('Cwd');

my ($lp) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $lib_path = join( ' ', "$RT::LocalPath/lib", $lp );
my $sbin_path = $RT::SbinPath || "$RT::BasePath/sbin" || "/opt/rt3/sbin";

substitute( { RT_LIB_PATH => $lib_path,
	      RT_SBIN_PATH => $sbin_path,
	    },
	    qw(sbin/rtx-shredder
	       sbin/rtx-validator
	       lib/RTx/Shredder.pm
	       t/utils.pl)
	  );

no_index( package =>
'RT::ACE',
'RT::CachedGroupMember',
'RT::Attachment',
'RT::CustomFieldValue',
'RT::CustomField',
'RT::Group',
'RT::GroupMember',
'RT::ObjectCustomFieldValue',
'RT::Link',
'RT::Principal',
'RT::Queue',
'RT::Record',
'RT::Scrip',
'RT::ScripAction',
'RT::ScripCondition',
'RT::Template',
'RT::Ticket',
'RT::Transaction',
'RT::User',
);

WriteAll();

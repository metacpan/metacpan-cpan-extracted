use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use Config;

print "\n\nNet::LDAPapi Perl5 Module - by Quanah Gibson-Mount <mishikal\@yahoo.com>\n\n";
print "OpenLDAP support by Symas Corporation -- http://www.symas.com\n";
print "Updated by Quanah Gibson-Mount to match modern products and vendors.\n";
print "Updated by Dmitri Priimak to use the v3 OpenLDAP API.\n";
print "\nOriginally by Clayton Donley <donley\@cig.mcel.mot.com>\n\n";

$pl_path = $Config{'perlpath'};

unless (@ARGV) {
warn <<END;
NOTICE: This module requires the OpenLDAP C API or Mozilla C SDK.
        It will NOT work with ISODE or the UMich LDAP api.

        Type perl Makefile.PL -h for command-line option summary.
END
}

#############################################################################################
# Build options passed in to script to support reproducible builds via Makefiles
#############################################################################################
use Getopt::Long;
my $result = GetOptions("sdk=s"       => \$sdk,
                        "lib_path=s"  => \$lib_ldap,
                        "include_path=s" => \$include_ldap,
                        "sasl_include_path=s" => \$include_sasl,
               );
unless ($result) {
  print STDERR <<END;
Usage: perl Makefile.PL [options]

Configure Net::LDAPapi module.

 Options:
     -sdk               SDK   which SDK to use(openldap or mozilla)
     -lib_path          path  path to the LDAP libraries
     -include_path      path  path to the LDAP includes
     -sasl_include_path path  path to the SASL includes (optional)


If no options are passed on the command line will prompt for these
values interactively.
END
}

if ($sdk eq "mozilla" || $sdk eq "MOZILLA") {
    $sdk = 2;
}
 
unless ($sdk)
{
   print "\nSelect your Development Kit:\n";
   print "  1.  OpenLDAP (default)\n";
   print "  2.  Mozilla\n";
   $sdk=prompt("Choose:",1);
}

$version = ($sdk == 2 ? 'MOZILLA' :
	    'OPENLDAP');

if ($include_ldap eq "")
{
   $include_ldap=prompt("Location of LDAP include files:","/usr/include");
   chomp($include_ldap);
   $include_ldap = "/usr/include" unless $include_ldap =~ /\S/;
}

if ($lib_ldap eq "")
{
   $df_lib = ($include_ldap =~ m%^(\S+)/include% ? "$1/lib" : "/usr/lib");
   $lib_ldap=prompt("Location of LDAP library files:",$df_lib);
   chomp($lib_ldap);
   $lib_ldap = $df_lib unless $lib_ldap =~ /\S/;
}

if ( $sdk == 1 && $include_sasl eq "") {
   $include_sasl=prompt("Location of SASL include files if needed:");
   chomp($include_sasl);
}

if ($version eq "MOZILLA")
{
      if ($Config::Config{'osname'} eq 'MSWin32')
      {
         $ldap_lib = 'nsldapssl32v30';
      } else {
         $ldap_lib = 'ldapssl30';
      }
}

if ($version eq "OPENLDAP")
{
    if ($^O eq "MSWin32")
    {
	$ldap_lib = 'ldap.lib lber.lib';
    }
    else
    {
	$ldap_lib = '-lldap -llber';
    }
}

sub MY::postamble
{
    "
constant.h:     constant.gen
	$pl_path constant.gen >constant.h 
";
}

WriteMakefile(
	'NAME'          =>      'Net::LDAPapi',
	'VERSION_FROM'  =>      'LDAPapi.pm',
	'PREREQ_PM'	=>	{ 'Convert::ASN1' => '0.19'},
        ($include_sasl ne "" ? (
	'INC'           =>      "-I$include_ldap -I$include_sasl -I/usr/include",
        ) : ( 
	'INC'           =>      "-I$include_ldap -I/usr/include",
        )),
	($version eq "MOZILLA" ? (
	'LIBS'          =>      ["-L$lib_ldap -l$ldap_lib"],
	'DEFINE'        =>      '-DMOZILLA_LDAP',
	) : (
	'LIBS'          =>      ["-L$lib_ldap $ldap_lib"],
	'DEFINE'        =>      '-DOPENLDAP',
	)),
	'depend'        =>      { 'LDAPapi.c' => 'constant.h' },
	'clean'         =>      { 'FILES'     => 'constant.h' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/quanah/net-ldapapi.git',
				web  => 'https://github.com/quanah/net-ldapapi',
			},
		},
	},
);

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

@exe_files = ( 'bin/sqldef.pl' );

WriteMakefile(
    'NAME'	     => 'Msql::RDBMS',
    'DISTNAME'       => 'RDBMS.pm',
    'VERSION_FROM'   => 'RDBMS.pm', # finds $VERSION
    'INSTALLBIN'     => '/usr/local/bin',
    'INSTALLSCRIPT'  => '/usr/local/bin',
    'INSTALLMAN1DIR' => '/usr/local/man/man1',
    'INSTALLMAN3DIR' => '/usr/local/man/man3',
    'EXE_FILES'      => \@exe_files,
    'linkext'        => { LINKTYPE=>'' },	# no link needed
    'dist'           => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz'}
);

# Check versions of installed modules. This was borrowed from the libnet
# Makefile.PL.
#
sub chk_version
{
 my($pkg,$wanted,$msg) = @_;

 local($|) = 1;
 print "Checking for $pkg...";

 eval { my $p; ($p = $pkg . ".pm") =~ s#::#/#g; require $p; };

 my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
                                 : "not found";
 my $vnum = ${"${pkg}::VERSION"} || 0;

 print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

 $vnum >= $wanted;
}

chk_version(Msql => '1.1819') or
    warn  "\nMsql::RDBMS requires version 1.1819 or later of Msql.pm\n" .
          "You may install it with the command:\n\n".
          "  perl -MCPAN -e 'install Msql'\n\n";

chk_version(Date::Format => '2.07') or
    warn  "\nMsql::RDBMS requires version 2.07 or later of Date::Format\n" .
          "You may install it with the command:\n\n".
          "  perl -MCPAN -e 'install Date::Format'\n\n";

chk_version(Date::Parse => '2.06') or
    warn  "\nMsql::RDBMS requires version 2.06 or later of Date::Parse\n" .
          "You may install it with the command:\n\n".
          "  perl -MCPAN -e 'install Date::Parse'\n\n";

chk_version(CGI::Carp => '1.06') or
    warn  "\nMsql::RDBMS requires version 1.06 or later of CGI::Carp\n" .
          "You may install it with the command:\n\n".
          "  perl -MCPAN -e 'install CGI::Carp'\n\n";


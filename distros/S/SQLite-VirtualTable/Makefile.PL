use ExtUtils::MakeMaker;

use Config;

my $sqlite_source;

@ARGV = grep {
    if (/^SQLITE_SOURCE\s*=\s*(.*)$/) {
        $sqlite_source = $1;
        undef;
    }
    else {
        1
    }
} @ARGV;

my $INC = '';
if (defined $sqlite_source) {
    -f $sqlite_source . "/src/sqlite3ext.h"
	or die "SQLite source not found on the path given '$sqlite_source'\n";
    $INC =  "-I$sqlite_source -I$sqlite_source/src";
}
else {
    warn "Assuming SQLite development files are installed in the standard places...\n";
}


WriteMakefile( NAME => 'SQLite::VirtualTable',
               VERSION_FROM => 'lib/SQLite/VirtualTable.pm',
               PREREQ_PM => {},
               ABSTRACT_FROM => 'lib/SQLite/VirtualTable.pm',
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
               INC => $INC,
               OBJECT => 'perlvtab.o',
               OPTIMIZE => '-g3 -O0',
               dynamic_lib => { OTHERLDFLAGS => '`$(PERL) -MExtUtils::Embed -e ldopts`' }
             );


package MY;
our @ISA = qw(ExtUtils::MakeMaker);
sub constants {
    my $txt = shift->SUPER::constants(@_);
    $txt =~ s/^DLBASE\s*=.*$/DLBASE = perlvtab/m;
    $txt;
}

sub install {
    my $txt = shift->SUPER::install(@_);
    $txt =~ s/^install\b(.*)$/install$1 my_message/m;
    $txt
}

sub postamble {
    my $txt = shift->SUPER::installbin(@_);
    $txt .= <<EOM;
my_message:
\t\$(NOECHO) \$(ECHO)
\t\$(NOECHO) \$(ECHO) "*** IMPORTANT:"
\t\$(NOECHO) \$(ECHO) "*** Now, you have to copy" \$(INST_DYNAMIC)
\t\$(NOECHO) \$(ECHO) "*** to the directory where dynamic libraries are stored in"
\t\$(NOECHO) \$(ECHO) "*** your system in order to make the Perl Virtual Table"
\t\$(NOECHO) \$(ECHO) "*** extension available to any SQLite application."
EOM
    $txt;
}

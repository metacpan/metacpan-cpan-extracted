use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..24\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}

use vars qw(@test);

BEGIN {
    @test = (

    '001_void.pl' => [<<'END', 'notdie'],
END

    '002_1.pl' => [<<'END', 'notdie'],
1;
END

    '003_exit.pl' => [<<'END', 'notdie'],
exit;
END

    '004_die.pl' => [<<'END', 'mustdie'],
die;
END

    '005_strict.pl' => [<<'END', 'notdie'],
use strict;
END

    '006_strictperl_exit.pl' => [<<'END', 'notdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
exit;
END

    '007_strictperl_die.pl' => [<<'END', 'mustdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
die;
END

    '008_must_moduleversion.pl' => [<<'END', 'mustdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl;
use vars qw($VERSION);
$VERSION = 1;
exit;
END

    '009_must_moduleversion_match.pl' => [<<'END', 'mustdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl 9999.99;
use vars qw($VERSION);
$VERSION = 1;
exit;
END

    '010_strict.pl' => [<<'END', 'mustdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
$VERSION = 1;
$VAR = 1;
exit;
END

    '011_warnings.pl' => [<<'END', 'mustdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
print "VERSION=$VERSION";
exit;
END

    '012_autodie.pl' => [<<'END', 'mustdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
open(FILE,'not_exists.txt');
close(FILE);
exit;
END

    '013_goodvariable.pl' => [<<'END', 'notdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
print "\$^W=($^W)\n";
exit;
END

    '014_bareword.pl' => [<<'END', 'notdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
open(FILE,$0);
close(FILE);
exit;
END

    '015_fileno_0.pl' => [<<'END', 'notdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
print "fileno(STDIN)=(",fileno(STDIN),")\n";
exit;
END

    '016_fileno_undef.pl' => [<<'END', 'mustdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
print "fileno(FILE)=(",fileno(FILE),")\n";
exit;
END

    '017_unlink.pl' => [<<'END', 'notdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
unlink('not_exists.txt');
exit;
END

    '018_use_Thread.pl' => [<<'END', 'mustdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
use Thread;
exit;
END

    '019_use_threads.pl' => [<<'END', 'mustdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
use threads;
exit;
END

    '020_use_encoding.pl' => [<<'END', 'mustdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
use encoding;
exit;
END

    '021_use_Switch.pl' => [<<'END', 'mustdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
use Switch;
exit;
END

    '022_sigiled_keyword.pl' => [<<'END', 'notdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
my $goto = 1;
END

    '023_line.pl' => [<<'END', 'notdie'],
@rem = '
goto HERE
:HERE
@rem ';
#line 6
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
END

    '024___END__.pl' => [<<'END', 'notdie'],
use FindBin;
use lib "$FindBin::Bin/lib";
use Strict::Perl <%MODULEVERSION%>;
use vars qw($VERSION);
$VERSION = 1;
__END__
goto
END

    );
}

# get $Strict::Perl::VERSION
BEGIN {
    require Strict::Perl;
}

while (@test > 0) {
    my $scriptname    = shift @test;
    my($script,$want) = @{shift @test};

    open(SCRIPT,"> $scriptname") || die "Can't open file: $scriptname\n";
    $script =~ s/<%MODULEVERSION%>/$Strict::Perl::VERSION/;
    print SCRIPT $script;
    close(SCRIPT);

    my $rc;
    if ($^O eq 'MSWin32') {
        $rc = system(qq{$^X $scriptname >NUL 2>NUL});
    }
    else {
        $rc = system(qq{$^X $scriptname >/dev/null 2>/dev/null});
    }
    unlink($scriptname);

    if ($want eq 'mustdie') {
        ok(($rc>>8) != 0, "rc=($rc) perl/$] $scriptname $want");
    }
    else{
        ok(($rc>>8) == 0, "rc=($rc) perl/$] $scriptname $want");
    }
}

__END__

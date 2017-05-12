# Makefile.PL

use ExtUtils::MakeMaker;

# Check for the ALLOW_UU=0 option
my $allow;
@ARGV = grep {
	if ($ARGV[$_] =~ /^(ALLOW_UU(=(.*))?)$/) {
	    # Allowed forms: ALLOW_UU
	    #		 ALLOW_UU=...
	    if (!$2) {
		$allow = 1;
	    } elsif (lc($3) =~ /^(true|on|1|yes|ok(ay)?)$/) {
		$allow = 1;
	    } elsif (lc($3) =~ /^(no|false|0|off)$/) {
		$allow = 0;
	    } elsif ($3) {
		die "Can't tell what '$3' means (try 1 or 0)";
	    }
	    0;		# Remove from @ARGV
	} else {
	    1;		# Retain in @ARGV
	}
    } @ARGV;

if (defined $allow) {
    my $filename = 'Taint.pm';
    print $allow ? "Allowing" : "Disallowing",
	" use of unconditional_untaint() function...\n";
    local($^I) = '.bak';
    local(@ARGV) = $filename;
    my $mode = (stat $filename)[2];
    die "Can't stat Taint.pm: $!" unless defined $mode;
    unless (-w _) {
	chmod $mode | 0200, $filename
	    or die "Can't change mode: $!";
    }
    die "Backup file already exists - please remove or rename it"
	if -e "$filename.bak";
    my $subbed = 0;
    while (<>) {
	$subbed++ if s
	  <^\s*sub\s+allowing_insanity\s*\(\)\s*\{\s*\d+\s*\}.*>
	  {sub allowing_insanity () { $allow }\t\t# Default is 1.};
	print;
    }
    close ARGV;				# just in case
    local($SIG{'__DIE__'}) =
    local($SIG{'__WARN__'}) = sub {
	if (rename "$filename.bak", $filename) {
	    print "\n@_\n(Original file restored.)\n";
	} else {
	    print "\n@_\n(Use the backup file.)\n";
	}
	exit;
    };
    if ($subbed != 1) {
	die "Wrong number ($subbed) of substitutions";
    }
    chmod $mode, $filename
	or die "Can't change mode: $!";
    unlink "$filename.bak"
	or die "Can't unlink backup file: $!";
    print "Looks good.\n\n";
}

WriteMakefile(
    'NAME'	=> 'Taint',
    'VERSION_FROM' => 'Taint.pm', # finds $VERSION
    'dist'      => { COMPRESS=>'gzip -9', SUFFIX=>'gz',
   	(($^O eq 'machten') ? (DIST_CP => 'cp') : ()) },
);

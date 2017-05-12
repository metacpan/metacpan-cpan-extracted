use warnings;
use strict;

use Pod::Usage;
use Getopt::Long;

use ExtUtils::MakeMaker qw(WriteMakefile prompt);
use 5.006;                      # for "no warnings" -- sorry!
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %prereq = (
    'Data::Dumper'    => 0,
    'Scalar::Util'    => 0,
);

## Poor man's optional deps.
sub test_for
{
    my $mod = shift;
    eval "require $mod";
    if ($@) {
        my $resp = prompt("@_.  Install $mod (y/n)? ", 'n');
        $prereq{$mod} = 0 if $resp =~ /^y/i;
    }
}

my $ELISP_FIND_SITELISP = <<'END_ELISP';
(dolist (x load-path) (princ x) (terpri))
END_ELISP

my $ELISP_FIND_INFODIR = <<'END_ELISP';
(progn
 (require (quote info))
 (princ (car Info-default-directory-list)))
END_ELISP

my ($EMACS, $SITE_LISP, $INSTALL_INFO, $INFO_DIR, $HELP);

sub escape_path
{
    my ($path) = @_;
    $path =~ s/([$?* ])/\\$1/g; # escape special characters
    $path =~ s{/+$}{};          # remove trailing forward-slashes
    return $path;
}

sub prompt_for_emacs
{
    # try to compile and install Elisp files, but don't die if we can't.
    my ($sysemacs) = grep { defined && -x }
        $ENV{EMACS}, glob '/usr/bin{/local,}/emacs';
    $sysemacs ||= q{emacs};

    my $emacs = prompt("Where is your emacs? ", $sysemacs);

    # Make sure emacs is a valid string/program path...
    return undef unless $emacs;

    # Make sure -x is passed an absolute path...
    unless ( $emacs =~ m{^/} && -x $emacs ) { 
        warn "$emacs is not executable! Undefined.\n";
        return undef;
    }

    return escape_path( $emacs );
}

# Runs some elisp code with emacs via the command line.
# We must set $EMACS before running this... if it is an untrue value
# then we return an empty list or string, depending on what caller wants.
sub run_elisp
{
    my ($elisp) = @_;

    return wantarray ? qw// : q{} unless $EMACS;
    return `$EMACS --batch --eval '$elisp' 2>/dev/null`;
}

sub prompt_for_sitelisp
{
    my @lp = run_elisp( $ELISP_FIND_SITELISP );
    chomp @lp;

    my $site_lisp;
    if ( scalar @lp ) {
        ($site_lisp) = grep { /site-lisp$/ && -d $_ } @lp;
    }

    $site_lisp = prompt("Elisp install directory?", $site_lisp);

    # We don't check if the directory exists, because we can create it...
    return escape_path( $site_lisp );
}

sub prompt_for_infodir
{
    chomp(my @info_dir = grep { m!/info/?$! } run_elisp( $ELISP_FIND_INFODIR ));

    # pass prompt undef so it will not display brackets if $info_dir is ""
    my $info_dir = prompt("Info directory?", $info_dir[0] || undef);
    return escape_path( $info_dir );
}

# Append info page and elisp installation to the end of the install
# section in the Makefile...

sub MY::postamble
{
    # Make an entry for Sepia.html as a target to make things easier...
    my $maketxt = <<'END_MAKETXT';
all :: Sepia.html sepia.info

Sepia.html : sepia.texi
	makeinfo --no-split --no-headers --html sepia.texi -o Sepia.html

sepia.info : sepia.texi
	makeinfo --no-split -o sepia.info sepia.texi

END_MAKETXT

    $maketxt .= <<"END_MAKETXT";
install ::
END_MAKETXT

    if ( $INFO_DIR ) { $maketxt .= <<"END_MAKETXT" }
	install -d -m755 \$(DESTDIR)$INFO_DIR
	install -m644 sepia.info \$(DESTDIR)$INFO_DIR
	$INSTALL_INFO \$(DESTDIR)$INFO_DIR/sepia.info \$(DESTDIR)$INFO_DIR/dir
	
END_MAKETXT

    if ( $SITE_LISP ) {
        $maketxt .= <<"END_MAKETXT";
	install -d -m755 \$(DESTDIR)$SITE_LISP
	install -m644 *.el \$(DESTDIR)$SITE_LISP
END_MAKETXT
          if ( $EMACS ) {
              $maketxt .= <<"END_MAKETXT";
	install -m644 *.elc \$(DESTDIR)$SITE_LISP
END_MAKETXT
          }
    } else {
        print <<'END_MSG'

======================================================================
To actually use this package, you need to move the Emacs Lisp files
somewhere Emacs will find them.

You may also want to install the HTML documentation somewhere
appropriate to your system.
======================================================================

END_MSG
    }

    # Create a new target for compiled elisp (.elc) files...
    # Allow the compilation to fail (it is prefixed with "-")...
    if ( $EMACS ) {
        $maketxt .= <<"EOS";

\%.elc : \%.el
	- $EMACS -L '$ENV{PWD}' --batch -f batch-byte-compile \$? 2>/dev/null

all :: sepia-snippet.elc sepia.elc sepia-cpan.elc sepia-tree.elc \\
	   sepia-w3m.elc sepia-ido.elc
EOS
    }

    return $maketxt;
}

GetOptions( 'emacs=s' => \$EMACS,
            'lisp=s'  => \$SITE_LISP,
            'info=s'  => \$INFO_DIR,
            'help'    => \$HELP,
           );

exit pod2usage( '-verbose' => 1 ) if $HELP;

test_for 'Devel::Peek', 'Printing internals requires Devel::Peek';
test_for 'Devel::Size', 'Printing variable sizes requires Devel::Size';
test_for 'IO::Scalar', 'Printing internals requires IO::Scalar because Devel::Peek sucks';
test_for 'PadWalker', 'Strict mode requires PadWalker';
test_for 'Devel::LexAlias', 'Strict mode requires Devel::LexAlias';
test_for 'LWP::Simple', 'CPAN documentation browsing requires LWP::Simple';
test_for 'Module::CoreList', 'sepia-core-version requires Module::CoreList';
test_for 'Module::Info', 'Required for some Emacs functions';
test_for 'BSD::Resource', 'Detailed command timing';
test_for 'Time::HiRes', 'Basic command timing';
# test_for 'Pod::Webserver', 'Pod::Webserver creates nice documentation.';
# test_for 'Scope::Upper', 'Required for return-from-context';

$INSTALL_INFO = 'install-info';

if ( !defined $EMACS ) {
    $EMACS = prompt_for_emacs()
      or warn "Disabling elisp compilation and dir detection.\n";
}
$SITE_LISP    ||= prompt_for_sitelisp();
$INFO_DIR     ||= prompt_for_infodir();
$INSTALL_INFO ||= prompt("install-info program?", 'install-info')
    if $INFO_DIR;

WriteMakefile(
    NAME		=> 'Sepia',
    VERSION_FROM	=> 'lib/Sepia.pm', # finds $VERSION
    PREREQ_PM		=> \%prereq,
    EXE_FILES		=> ['sepl'],
    AUTHOR		=> "Sean O'Rourke <seano\@cpan.org>",
    ABSTRACT		=> 'Simple Emacs-Perl InterAction',
    clean           => { FILES => '*.elc' },
);

__END__

=head1 SYNOPSIS

  # prompts for paths
  perl Makefile.PL 
  
  # doesn't prompt for paths
  perl Makefile.PL --emacs /usr/bin/emacs \
      --lisp /usr/share/emacs/site-lisp/sepia \
      --info /usr/share/info

=head1 OPTIONS

=over 4

=item B<--emacs>

Specifies the path to emacs.

=item B<--lisp>

Specifies the directory to install the elisp files to.

=item B<--info>

Specifies the directory to install the texinfo files to.

=item B<--help>

Display this help information.

=back

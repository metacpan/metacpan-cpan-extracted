#!/usr/bin/perl -w

require 5.008000;
use strict;
use ExtUtils::MakeMaker;
use Getopt::Long;

eval q{
    use ExtUtils::MakeMaker::Coverage;
    # I keep many modules outside of /usr/lib/perl5
    my $config = ExtUtils::MakeMaker::Coverage->config;
    $config->ignore( ['site_perl'] );
};


#############################################################
my $NAME               = 'POE::XUL';
my $JS_DIR             = 'javascript';
my $SERVER_SCRIPT_NAME = 'poe-xul-server';
my $SERVER_ROOT_DIR    = 'poe-xul';
my $SERVER_XUL_DIR     = "$SERVER_ROOT_DIR/xul";
my $SERVER_JS_DIR      = "$SERVER_XUL_DIR/javascript";
my $SERVER_JSLIB       = "$SERVER_XUL_DIR/NS6lib.js";
my $BLIB_SERVER_ROOT   = "blib/$SERVER_ROOT_DIR";
my $BLIB_SERVER_XUL    = "blib/$SERVER_XUL_DIR";
my $BLIB_SERVER_JS     = "blib/$SERVER_JS_DIR";
my $BLIB_SERVER_JSLIB  = "blib/$SERVER_JSLIB";
my $MODULE             = 'lib/POE/XUL.pm';
my $MODULE_VARS        = 'lib/POE/Component/XUL.pm';
my $SERVER_SCRIPT      = "bin/$SERVER_SCRIPT_NAME";
my $JS_BUILD_SCRIPT    = 'bin/js-build';
my $BLIB_TESTS_XUL     = "$BLIB_SERVER_XUL/tests.xul";

#############################################################
my $PORT = 8077;
my $INSTALL_DIR;

my $res = GetOptions( "port=i" => \$PORT, 
                      "root=s" => \$INSTALL_DIR 
                    );
die "Usage: $0 [--port=8077] [--root=/usr/local/$SERVER_ROOT_DIR]" unless $res;


my $root;
if( $^O eq 'MSWin32' ) {
    $root = "C:/perl/$SERVER_ROOT_DIR";
}
else {
    my $prefix = "/usr/local";
    foreach my $a ( @ARGV ) {
        next unless $a =~ /^PREFIX=(.+)/;
        $prefix = $1;
        last;
    }
    $root = "$prefix/$SERVER_ROOT_DIR";
}

$PORT ||= 8077;
$INSTALL_DIR ||= $root;

#############################################################
print "Fixing $MODULE_VARS\n";
{
    local $^I = '.bk';
    local @ARGV = ( $MODULE_VARS );
    while( <> ) {
        s/(args->\{port\}.+?)\d+(;\s+# PORT)/$1$PORT$2/;
        s/(args->\{root\}.+')[^']+(';\s+# ROOT)/$1$INSTALL_DIR\/xul$2/;
        print;
    }
}

#############################################################
print <<MESSAGE;

Default port is $PORT (set with --port)
Server root is $INSTALL_DIR (set with --root)

MESSAGE


#############################################################
WriteMakefile(
        NAME          => $NAME,
        VERSION_FROM  => $MODULE,
        ABSTRACT      => 'Server-side XUL for POE',
        AUTHOR        => 'Philip Gwyn <gwyn at cpan.org>',
        dist          => {COMPRESS => 'gzip --force --best'},
#        PL_FILES      => {"$SERVER_SCRIPT.PL" => $SERVER_SCRIPT},
#        EXE_FILES     => [$SERVER_SCRIPT],
        clean         => {FILES => "$SERVER_SCRIPT"},
        LICENSE       => 'perl',

        PREREQ_PM     => {
            'Carp'                              => 0,
            'Digest::MD5'                       => '2.3',
            'HTTP::Date'                        => '1.4',
            'HTML::Entities'                    => '1.35',
            'HTTP::Status'                      => '1',
            'I18N::AcceptLanguage'              => '1.04',
            'JSON::XS'                          => '0.8',
            'MIME::Types'                       => '1.13',
            'POE'                               => '0.9500',
            'POE::Component::Server::HTTP'      => '0.09',
            'Scalar::Util'                      => '1.13',
            'Test::More'                        => '0.60',
            'Time::HiRes'                       => 1,
            'Unicode::String'                   => 2
        },
);

#############################################################
package MY;

# add targets for building server, and installing it
sub Xpostamble {qq[
build_server :: pm_to_blib
        \@\$(ECHO) "building server root directory in blib..."
        \@\$(PERL) $JS_BUILD_SCRIPT
        \@\$(MOD_INSTALL) $SERVER_ROOT_DIR $BLIB_SERVER_XUL
        \@\$(RM_RF) $BLIB_SERVER_JS
        \@\$(RM_F) $SERVER_JSLIB
        \@\$(RM_F) $BLIB_TESTS_XUL

install_server :: build_server
        \@\$(ECHO) "installing server root directory from blib to $INSTALL_DIR..."
        \@\$(MOD_INSTALL) $BLIB_SERVER_ROOT $INSTALL_DIR
        \@\$(RM_F) $SERVER_SCRIPT
]}

# add install_server target to install as dependency
sub Xinstall {
        my $class = shift;
        my $basic = $class->SUPER::install(@_);
        my $add   = 'install_server';
        $basic    =~ s/^(install\s+::\s+.*)$/$1 $add/m;
        $basic;
}

# add port and install_dir to script generator command line args
sub XprocessPL {
        my $inherited = shift->SUPER::processPL(@_);
        $inherited =~ s|($SERVER_SCRIPT\.PL $SERVER_SCRIPT)|$1 $PORT $INSTALL_DIR|;
        $inherited;
}

sub static
{
    my $inherited = shift->SUPER::static(@_);
    return <<MAKE;

all :: poexul_to_blib

POEXUL=\$(shell find $SERVER_XUL_DIR -name \\*~ -o -name .svn -prune -o -type f -print)

realclean :: js_cleanup

poexul_to_blib: js_to_poexul Makefile \$(POEXUL)
	\$(NOECHO) \$(MKPATH) $BLIB_SERVER_XUL/
	\$(NOECHO) \$(MKPATH) $BLIB_SERVER_XUL/javascript
	\$(NOECHO) \$(MKPATH) $BLIB_SERVER_XUL/images
	\$(NOECHO) for file in \$(POEXUL) ; do cp -v \$\$file $BLIB_SERVER_XUL/`echo \$\$file | sed -e 's/\Q$SERVER_JS_DIR\E/javascript/; s/\Q$SERVER_XUL_DIR\E//;'` ; done
	\$(NOECHO) \$(TOUCH) poexul_to_blib

JSLIB=\$(shell find $JS_DIR/lib -name \\*.js | grep -v .\\#)
JSSRC=\$(shell find $JS_DIR/src -name \\*.js | grep -v .\\#)

js_to_poexul: Makefile \$(JSLIB) \$(JSSRC)
	\$(NOECHO) \$(MKPATH) $SERVER_JS_DIR/
	\$(NOECHO) \$(ABSPERLRUN) bin/js-build $SERVER_JS_DIR $JS_DIR/lib $JS_DIR/src
	\$(NOECHO) \$(TOUCH) js_to_poexul

js_cleanup:
	rm -fR $SERVER_JS_DIR/*.js js_to_poexul poexul_to_blib
	( find . -name diff | xargs rm 2>/dev/null ; true )

MAKE
}

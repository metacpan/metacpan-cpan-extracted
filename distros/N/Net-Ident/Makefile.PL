#!/usr/bin/perl
# Makefile for Net::Ident
#
# $Id: Makefile.PL,v 1.57 1999/08/27 00:00:09 john Exp $

use strict;
use ExtUtils::MakeMaker qw(:DEFAULT prompt);
use Getopt::Long;
use Pod::Text;
use Socket;
use FileHandle;
use FindBin qw($Bin);

$| = 1;

my $intro = <<HELP;
This is the installer of the Net::Ident module.

You can specify the following options:

HELP

use vars qw($opt_help $opt_force_compat $opt_test_apache);
my %options = (
    'help|h'         => "Produce this helptext",
    'force-compat|c' => q{
	Force installation of Net::Ident compatible with version 1.11.
	By default, the installer checks if version 1.11 is installed, and
	if so, offers the option to install the compatible version.

	Here ``compatible'' means that C<use "Net::Ident";> will install
	the C<lookup_ident> method in package C<FileHandle>.},
    'test-apache|a' => q{
	Makes the installer go into the dialogue to configure the apache
	mod_perl test. This is normally only done when a few basic almost
	fail-safe tests confirm that you can run this test.},
);

# files that need adapting when we install compatibility mode
my @compat_files = qw(Ident.pm);

# option processing
GetOptions( keys %options ) or $opt_help++;

# provide help if necessary
if ($opt_help) {
    open( POD, "|-" ) or pod2text( "<&STDIN", *STDOUT ), exit 0;
    print POD "=head1 Net::Ident installation\n\n";
    print POD $intro;
    print POD "=over 4\n\n";
    for my $opt ( sort keys %options ) {
        my $txtopt = join(
            " ",
            map { "-" x ( length > 1 ? 2 : 1 ) . $_ } split /\|/, $opt
        );
        print POD "=item $txtopt\n\n";
        $options{$opt} =~ s/^\s+//mg;
        print POD $options{$opt}, "\n\n";
    }
    print POD "=back\n\n";
    exit 0;
}

# check and ask if we possibly need compatibility-install
sub check_compat () {
    my $forcetxt = <<FORCE;
You could force installing the backwards-compatible Net::Ident, for
example because you want to use scripts that rely on the backwards
compatible calling syntax [not that that's very likely; I'm not aware
of any existing scripts that use it -- JohnPC].

To enable this, re-run this Makefile.PL using:

	perl Makefile.PL --force-compat

FORCE

    print "Checking for previous Net::Ident... ";
    eval { require Net::Ident };
    if ($@) {
        print "Not found.\n\n$forcetxt";
        return;
    }
    if ( !defined($Net::Ident::VERSION) ) {
        print "no VERSION? assuming Net::Ident not present\n\n$forcetxt";
        return;
    }
    print "found $Net::Ident::VERSION\n";
    if ( $Net::Ident::VERSION lt '1.10' ) {
        print "That version is too old, and is not supposed to exist.\n";
        return;
    }
    elsif ( $Net::Ident::VERSION eq '1.10' || $Net::Ident::VERSION eq '1.11' ) {
        print <<COMPAT;

You have a previous version of Net::Ident installed. This previous version
automatically added a method `ident_lookup' in package FileHandle. The
version you're about to install by default only does so when you request
it by explicitly importing the `:fh' tag.

If you have any current code that relies on this FileHandle method, you
can either change your old code, or, optionally, install this module
such that the old behaviour is continued. That is, this module will then
also automatically import the `ident_lookup' method in package FileHandle,
at least when using `use Net::Ident' without specific qualifiers.
COMPAT
        print <<COMPAT if $Net::Ident::VERSION eq '1.10';

NOTE! Your installed version 1.10 of Net::Ident had a constructor named
`initconnect' instead of the more appropriate `new'. There is no backwards
compatibility mode available for this depreciated and little used syntax.
COMPAT
    }
    elsif ( $Net::Ident::VERSION gt '1.11' ) {
        if ( @Net::Ident::EXPORT
            && grep { $_ eq "_export_hook_fh" } @Net::Ident::EXPORT ) {
            print <<COMPAT;

You already have a fairly recent version of Net::Ident installed. During
installation, you enabled compatibility mode, so the method `ident_lookup'
is automatically imported in package FileHandle, to provide backward
compatibility to old code.
COMPAT
        }
        else {
            print "No compatibility mode necessary.\n$forcetxt";
            return;
        }
    }
    else {
        die "Why did I get here? VERSION is $Net::Ident::VERSION\n";
    }

    # if we get here, then we might want to enable compatibility mode
    my $answ = prompt( "\nDo you want to enable compatibility mode for this install?", "n" );
    return $answ =~ /^y/;
}

# modify files in @compat_files for compatiblity mode
# search for lines containing @@NUMLINES PERLEXP @@, which modifies
# the next NUMLINES lines with PERLEXP (NUMLINES can be left out, in
# which case it defaults to 1)
sub install_compat () {
    print "Rewriting for compatibility mode: @compat_files\n";
    system( $^X, '-pli', '-e',
        q{eval $p if $p; --$c>0 or ($c,$p)=/@@(\d*) (.*) @@/},
        @compat_files
    );
}

# initial checks to see if apache is possible at all
sub check_initial_apache ($) {
    my $apinfo = shift;
    print "\nChecking for Apache.pm... ";
    eval { require Apache };
    if ($@) {
        print "not found\n";
        return;
    }
    print "found version $Apache::VERSION\n";
    $apinfo->{Apache_pm_version} = $Apache::VERSION;

    print "Checking for mod_perl.pm... ";
    eval { require mod_perl };
    if ($@) {
        print "not found\n";
        return;
    }
    print "found version $mod_perl::VERSION\n";
    $apinfo->{mod_perl_pm_version} = $mod_perl::VERSION;

    print "Checking for identd... ";
    my $tcpproto = getprotobyname('tcp') || 6;
    my $identport = ( getservbyname( 'ident', 'tcp' ) )[2] || 113;
    socket( S, PF_INET, SOCK_STREAM, $tcpproto ) or die "socket: $!\n";
    if ( !connect( S, sockaddr_in( $identport, inet_aton("127.1") ) ) ) {
        print "cannot connect: $!\n";
        return;
    }
    print "OK\n";
    close S;

    my $forcetxt = <<FORCE;
If you want to force testing Net::Ident in it's own Apache, because you
know you installed a mod_perl enabled Apache, which just happens not
to be running right now, re-run this Makefile.PL using:

	perl Makefile.PL --test-apache

FORCE

    print "Checking for apache with mod_perl... ";
    my $httpport = ( getservbyname( 'http', 'tcp' ) )[2] || 80;
    socket( S, PF_INET, SOCK_STREAM, $tcpproto ) or die "socket: $!\n";
    S->autoflush(1);
    if ( !connect( S, sockaddr_in( $httpport, inet_aton("127.1") ) ) ) {
        print "You don't have a webserver running: $!\n\n$forcetxt";
        return;
    }
    print S "HEAD / HTTP/1.0\r\n\r\n";
    my $reply;
    {
        # slurp in reply in one go
        local $/ = undef;
        $reply = <S>;
    }
    close S;
    if ( $reply !~ m{^Server:.*mod_perl/([\d.]+)\b}mi ) {
        print "Your webserver isn't mod_perl enabled\n\n$forcetxt";
        return;
    }
    print "you have mod_perl/$1\n";
    $apinfo->{mod_perl_parsed_version} = $1;

    # verify versions... but don't do anything with it, just warn
    # (can this be the cause of trouble???)
    if ( $apinfo->{mod_perl_parsed_version} != $apinfo->{mod_perl_pm_version} ) {
        print <<ODD;
Strange... your running mod_perl version differs from the installed mod_perl.pm
module version.
ODD
    }

    if ( $reply !~ m{^Server:.*Apache/([\d.]+)\b}mi ) {
        print "... hmm... odd... you're not running Apache?\n";
    }
    else {
        print "... and you're running Apache/$1\n";
        $apinfo->{apache_parsed_version} = $1;
    }

    print <<EXPLAIN;

Purely as a testing gimmick, the "make test" phase of Net::Ident can
start an httpd process for you, and try out the Net::Ident that you're
about to install from within Apache and mod_perl.

You might like to perform this test if you want to use Net::Ident from
within Apache... it also serves as a simple example. To enable this,
you'll have to answer some questions about your apache install. You
don't have to run the tests as root.

EXPLAIN

    # if we get here, then we might want to enable the apache test
    my $answ = prompt( "Do you want to test Net::Ident via Apache mod_perl ?", "y" );
    return $answ =~ /^y/;
}

sub safe_exec_httpd (@) {
    my $errfile = "/tmp/apache.$$.errout";
    my $pid = open( APOUT, "-|" );
    my $apout;
    defined $pid or die "cannot fork: $!\n";
    if ( !$pid ) {

        # child. Divert STDERR and exec the binary
        open( STDERR, ">$errfile" );
        exec(@_)
          or die "Couldn't execute @_: $!\n";
    }
    else {
        # parent. slurp in output.
        local $/ = undef;
        $apout = <APOUT>;
    }

    # wait for child to terminate.
    close APOUT;

    # check return status
    my $error = '';
    if ($?) {
        $error = "`@_' returned with a non-zero exit status: " . ( $? >> 8 ) . "\n";
    }

    # check stderr output
    if ( -s $errfile ) {
        $error .= "`@_' returned the following on STDERR:\n";
        open( ERR, $errfile ) or die "odd... opening $errfile: $!\n";
        {
            local $/ = undef;
            $error .= <ERR>;
        }
        close ERR;
    }
    unlink $errfile;
    return ( $error, $apout );
}

# parse httpd output and return info
sub parse_httpd_version ($$) {
    my ( $binary, $arg ) = @_;

    my ( $error, $apout ) = safe_exec_httpd( $binary, $arg );
    return $error if $error;

    my ($version)    = $apout =~ m{version.*Apache/([\d.]+)};
    my ($httpd_root) = $apout =~ m{HTTPD_ROOT="([^"]+)"};
    my ($httpd_conf) = $apout =~ m{SERVER_CONFIG_FILE="([^"]+)"};
    return ( "", $version, $httpd_root, $httpd_conf );
}

# parse the httpd.conf to extract User and Group statements
sub extract_usergroup ($) {
    my $apinfo = shift;

    my $conf = my $usergroup = "";
    $usergroup .= "User $1\n"
      if $apinfo->{httpd_conf_contents} =~ /^\s*user\s+(\w+)/mi;
    $usergroup .= "Group $1\n"
      if $apinfo->{httpd_conf_contents} =~ /^\s*group\s+(\w+)/mi;
    $usergroup;
}

# parse the httpd.conf and extract LoadModule and AddModule statements
# to make sure mod_perl.c gets loaded
sub extract_module_statements ($) {
    my $apinfo = shift;

    my $httpdconf = $apinfo->{orig_httpd_conf};
    my $conf      = $apinfo->{httpd_conf_contents};

    # first make sure mod_perl.c is added
    unless ( $conf =~ /^\s*AddModule\s+mod_perl\.c\s*$/mi ) {
        print "Cannot find mod_perl.c module in $httpdconf\n";
        return;
    }

    # remove all comments
    $conf =~ s/^\s*#.*//gm;

    # remove runs of empty lines
    $conf =~ s/^\s*$//gm;

    # remove all <IfDefine>..</IfDefine> and <IfModule>..</IfModule> parts
    1 while ( $conf =~ s{(<IfDefine\s+\w+>(?:(?!</IfDefine>).)*</IfDefine>)}{}is
        or $conf =~ s{(<IfModule\s+\w+>(?:(?!</IfModule>).)*</IfModule>)}{}is );

    # check that we didn't lose mod_perl.c in the process
    unless ( $conf =~ /^\s*AddModule\s+mod_perl\.c\s*$/mi ) {
        print <<IMSTUPID;
Whoa! mod_perl is in some IfDefine section, and I'm not intelligent enough
to get it out. Sorry. Ask my maker to fix me.
IMSTUPID
        return;
    }

    # now get all LoadModule, ClearModuleList and AddModule statements
    my $extract = '';
    while ( $conf =~ m{^(\s*(?:LoadModule|ClearModuleList|AddModule).*)$}img ) {
        $extract .= "$1\n";
    }
    return $extract;
}

# find real apache settings
sub apache_dialogue ($) {
    my $apinfo = shift;

    # find new apache root
    my $apache_root = "$Bin/t/apache";
    $apinfo->{apache_root} = $apache_root;

    # find current apache root
    my ($orig_apache_root) = grep { -d } qw(
      /usr/local/apache
      /opt/apache
      /usr/local/etc/httpd
      /etc/httpd
      /Local/Library/WebServer
      /boot/home/apache
      /usr/local
      /usr
    );
    print <<TXT;
Please answer the following questions about your apache installation. If
defaults are given, they are likely to be correct, so just accept them
if you're unsure.

TXT
    my $answ = prompt( "Where is your apache SERVERROOT?", $orig_apache_root );

    if ( !defined $answ ) {
        print "cannot find SERVERROOT, no apache test performed.\n";
        return;
    }
    if ( !-d $answ ) {
        print "$answ is not a directory, no apache test performed.\n";
        return;
    }
    $apinfo->{orig_apache_root} = $orig_apache_root = $answ;

    # find httpd binary
    my ($apache_bin) = grep { -x }
      map { m-^/- ? $_ : "$orig_apache_root/$_" }
      qw(
      httpd
      sbin/httpd
      bin/httpd
      libexec/httpd
      /sbin/httpd
      /usr/sbin/httpd
      /usr/libexec/httpd
    );
    $answ = prompt( "Where is your httpd executable?", $apache_bin );

    if ( !defined $answ ) {
        print "cannot find httpd executable, no apache test performed.\n";
        return;
    }
    if ( !-x $answ ) {
        print "$answ is not executable, no apache test performed.\n";
        return;
    }
    $apinfo->{apache_bin} = $apache_bin = $answ;
    my ( $error, $version, $orig_apache_root2, $orig_httpd_conf ) = parse_httpd_version( $apache_bin, "-V" );
    if ( !defined $version ) {

        # try httpd -v
        ( $error, $version, $orig_apache_root2, $orig_httpd_conf ) = parse_httpd_version( $apache_bin, "-v" );
        if ( !defined $version ) {

            # now give up
            print "I cannot use $apache_bin:\n$error\n";
            return;
        }
    }
    print "$apache_bin is version Apache/$version\n";
    $apinfo->{orig_httpd_conf} = $orig_httpd_conf;

    # verify this version against running version, if possible
    if (   $apinfo->{apache_parsed_version}
        && $version ne $apinfo->{apache_parsed_version} ) {
        print <<ODD;
Hey! $apache_bin is not the same version as you're currently running!
ODD
    }

    # verify apache root, if possible
    if (   $orig_apache_root2
        && $orig_apache_root ne $orig_apache_root2 ) {
        print <<ROOTMISMATCH;
You said the apache root was $orig_apache_root , but
$apache_bin says it is $orig_apache_root2 .
I'll assume the program knows that better than you do.
ROOTMISMATCH
        $apinfo->{orig_apache_root} = $orig_apache_root = $orig_apache_root2;
    }

    my $httpdconf = $apinfo->{orig_httpd_conf};

    # find proper httpd.conf
    if ( !$httpdconf || !-r $httpdconf ) {

        # oh dear. we need the original httpd.conf, but we don't know
        # where it is exactly, or can't read it. Provide guesses.
        ($httpdconf) = grep { -r }
          map { m-^/- ? $_ : "$orig_apache_root/$_" }
          qw(
          etc/httpd.conf
          conf/httpd.conf
          etc/httpd/httpd.conf
          Configuration/httpd.conf
          /usr/local/apache/conf/httpd.conf
          /usr/local/apache/etc/httpd.conf
          /opt/apache/conf/httpd.conf
          /opt/apache/etc/httpd.conf
          /etc/opt/apache/httpd.conf
          /etc/httpd/conf/httpd.conf
        );
    }
    $httpdconf = "$orig_apache_root/$httpdconf"
      unless $httpdconf =~ m-^/-;
    $answ = prompt( "Where is your httpd.conf?", $httpdconf );
    if ( !defined $answ ) {
        print "I cannot perform the apache test without httpd.conf\n";
        return;
    }
    if ( !-r $answ ) {
        print "Cannot read $answ, cannot proceed without it\n";
        return;
    }
    $httpdconf = $answ;
    $apinfo->{orig_httpd_conf} = $httpdconf;

    # read httpd.conf
    if ( !open( CONF, $httpdconf ) ) {
        print "Cannot read $httpdconf: $!\nCannot proceed without it\n";
        return;
    }
    my $conf;
    {
        # slurp in config
        local $/ = undef;
        $conf = <CONF>;
    }
    close CONF;
    $apinfo->{httpd_conf_contents} = $conf;

    # extract User/Group info
    $apinfo->{usergroup} = extract_usergroup($apinfo);

    # verify mod_perl module is present, if not, find LoadModule statement.
    my $modlist;
    ( $error, $modlist ) = safe_exec_httpd( $apache_bin, "-l" );
    if ($error) {
        print "Odd... `$apache_bin -l' returned an error:\n$error\n";
        print "I give up!\n";
        return;
    }

    # check for mod_perl.c
    my $LoadModule = "";
    if ( $modlist !~ /^\s*mod_perl\.c\s*$/m ) {

        # not present! we need to find the proper Module statements!
        print "Oops... mod_perl.c isn't in your standard module list...\n";
        $LoadModule = extract_module_statements($apinfo)
          or return;
        print <<MODULEOK;
There, I copied your existing Module statements, that should do it...
MODULEOK
    }
    else {
        print "mod_perl.c is linked in the executable, good.\n";
    }

    $apinfo->{LoadModule} = $LoadModule;

    # find a usable port
    my $port = 2706;
    my $tcpproto = getprotobyname('tcp') || 6;
    socket( S, PF_INET, SOCK_STREAM, $tcpproto ) or die "socket: $!\n";
    $port++ while $port < 2801 && !bind( S, pack_sockaddr_in( $port, INADDR_ANY ) );
    close S;
    if ( $port >= 2801 ) {
        print "Couldn't find a usable port, strange enough...\n";
        return;
    }
    $apinfo->{port} = $port;

    # return success
    return 1;
}

# substitute the lot into the config files.
sub install_apache ($) {
    my $apinfo = shift;

    print <<BLURB;

Writing the configuration files for the apache/mod_perl test...
BLURB

    my @configfiles = qw(
      conf/httpd.conf
      conf/access.conf
      conf/srm.conf
      conf/apache_config.pl
    );

    my $serverroot = $apinfo->{apache_root};
    my $version    = $apinfo->{apache_parsed_version};

    for my $file (@configfiles) {

        # read .in file
        open( IN, "$serverroot/$file.in" )
          or die "cannot open $serverroot/$file.in: $!\n";
        my $conf;
        {
            local $/ = undef;
            $conf = <IN>;
        }
        close IN;

        # handle $ifversion{}{}. allow 1-level nesting of {}
        # note: this is a nominee for the "most scary regexp '99" award.
        # no user serviceable parts inside. flammable. explosive. do not touch.
        $conf =~ s<\$ifversion([\d.]+)\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}>
		  < $version ge $1 ? $2 : $3 >gems;

        # handle $var
        $conf =~ s{\\(.)|\$(\w+)}
	          { $1 || $apinfo->{$2} }ge;

        # write config file
        print "Writing $serverroot/$file ...\n";
        open( OUT, ">$serverroot/$file" )
          or die "cannot write $serverroot/$file: $!\n";
        print OUT $conf;
        close OUT;
    }
    print <<BLURB;

Note that if you still get "skipping test on this platform" for the
t/apache test, something is wrong with your config. In that case,
study the logfiles, the generated config files, or run with TEST_VERBOSE=1
to find the reason apache is failing to initialise.

BLURB
}

sub MY::post_initialize {
    print "Do not worry if any of the following items are not found\n";

    if ( $opt_force_compat || check_compat ) {
        install_compat;
    }

    my %apinfo;
    if ( ( $opt_test_apache || check_initial_apache( \%apinfo ) )
        && apache_dialogue( \%apinfo ) ) {
        install_apache( \%apinfo );
    }

    '';
}

# back to your regular scheduled MakeMaker
WriteMakefile(
    NAME         => 'Net::Ident',
    ABSTRACT     => 'Lookup the username on the remote end of a TCP/IP connection',
    AUTHOR       => 'Jan-Pieter Cornet <johnpc@xs4all.nl>',
    VERSION_FROM => 'Ident.pm',                                                       # finds $VERSION
    PREREQ_PM    => {
        Socket     => '0',
        Fcntl      => '0',
        FileHandle => '0',
        Carp       => '0',
        Config     => '0',
        Exporter   => '0',
        vars       => '0',
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => "Net-Ident-* t/apache/conf/access.conf t/apache/conf/apache_config.pl t/apache/conf/httpd.conf t/apache/conf/srm.conf t/apache/logs/access_log t/apache/logs/error_log t/apache/perl/inc" },
    META_MERGE => {
        build_requires => {

            #            'Apache' => 0,  # mod_perl is crazy hard to install. It's not a fair thing to require
            #            'Apache::Constants' => 0,  # mod_perl is crazy hard to install. It's not a fair thing to require
            'Test::More',    # For Testing.
            'IO::Socket',    # For Testing
        },
        resources => {
            license  => 'http://dev.perl.org/licenses/',
            homepage => 'http://wiki.github.com/toddr/Net-Ident/',

            #            bugtracker => 'https://rt.cpan.org/Dist/Display.html?Queue=Net-Ident',
            repository => 'http://github.com/toddr/Net-Ident',
        },
    },
);

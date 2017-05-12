#!/usr/local/bin/perl

eval 'exec /usr/local/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
use warnings;

# $Id$

=head1 NAME

release-csjewell - give your Perl distros to the world

=head1 SYNOPSIS

	release-csjewell [OPTIONS] [ LOCAL_FILE [ REMOTE_FILE ] ]

	# try a dry run without uploading anything
	release-csjewell -t

	# print a help message and exit
	release-csjewell -h

	# skip kwalitee testing (e.g. a script distro)
	release-csjewell -k

	# print debugging information
	release-csjewell -d

	# print release number and exit
	release-csjewell -v

	# set $ENV{AUTOMATED_TESTING} to a true value
	release-csjewell -a

=head1 DESCRIPTION

This is the prototype program for using C<Module::Release>. You should
modify it to fit your needs. If it doesn't do what you want, you can
change it however you like. This is how I like to release my modules,
and I'm happy to add features that do not get in my way. Beyond that,
you should write your own script to match your process.

This program automates Perl module releases. It makes the
distribution, tests it, checks that source control is up to date, tags
source control, uploads it to the PAUSE anonymous FTP directory and
claims it on PAUSE.

By default this script assumes that you use CVS, but recognizes SVN
and git and switches when appropriate.

=head2 Process

The release script checks many things before it actually releases the
file.  Some of these are annoying, but they are also the last line of
defense against releasing bad distributions.

=over 4

=item Read the configuration data

Look in the current working directory for C<.releaserc>.  See the
Configuration section.  If release cannot find the configuration file,
it dies.

=item Test and make the distribution

Run make realclean, perl Makefile.PL, make test, make dist, make
disttest.  If testing fails, release dies.  make dist provides the
name of the distribution if LOCAL_FILE is not provided on the command
line. Too test the distribution against several perl binaries, see
the C<perls> configuration setting.

=item Check that source control is up-to-date

If there are modified files, added files, or extra files so that
source control complains, fail.

=item Upload to PAUSE

Simply drop the distribution in the incoming/ directory of PAUSE

=item Claim the file on PAUSE

Connect to the PAUSE web thingy and claim the uploaded file for your
CPAN account.

=item Tag the repository

Use the version number (in the distribution name) to tag the
repository.  You should be able to checkout the code from any release.

=back

=head2 Command-line switches

=over 4

=item --automate

Set $ENV{AUTOMATED_TESTING} to true. You can also set automated_testing
in the configuration file.

=item --verbose | --debug

Show debugging information

=item --help

Print a help message then exit

=item --nokwalitee

Skip the kwalitee checks. You can also set the skip_kwalitee directive
to a true value in the configuration file.

Have you considered just fixing the kwalitee though? :)

=item --noprereqs

Skip the prereq checks. You can also set the skip_prereqs directive
to a true value in the configuration file.

Have you considered just fixing the prereqs though? :)

=item --test

Run all checks then stop. Do not change any files or upload the distribution.

=item --usage

Print the program name and version then exit

=back

=head2 Configuration

The release script uses a configuration file in the current working
directory.  The file name is F<.releaserc>.

release's own F<.releaserc> looks like this:

    cpan_user BDFOY

If you would like to test with multiple perl binaries (version 1.21
and later), list them as a colon-separated list in the C<perls>
setting:

	perls /usr/local/bin/perl5.6.2:/usr/local/bin/perl5.10.0

release does not test the perls in any particular order.

=over 4

=item cpan_user

The PAUSE user

=item passive_ftp

Set C<passive_ftp> to "y" or "yes" for passive FTP transfers.  Usually
this is to get around a firewall issue.

=item skip_kwalitee

Set to a false value to skip kwalitee checks (such as for a script
distribution with no modules in it).

=item skip_prereqs

Set C<skip_prereqs> to 1 if you don't want to run the Test::Prereq
checks. By default this is 0 and C<release> will try to check
prerequisites.

=item automated_testing

Set C<automated_testing> to the value you want for the 
$ENV{AUTOMATED_TESTING} setting. By default this is 0, so
testing is started in interactive mode.

=item release_subclass

DEPRECATED AND REMOVED. You should really just write your own
release script. Fork this one even!

=back

=head2 Environment

=over 4

=item * AUTOMATED_TESTING

Module::Release doesn't do anything with this other than set it for
Test::Harness.

=item * CPAN_PASS

release reads the C<CPAN_PASS> environment variable to set the
password for PAUSE.  Of course, you don't need to set the password for
a system you're not uploading to.

=item * RELEASE_DEBUG

The C<RELEASE_DEBUG> environment variable sets the debugging value,
which is 0 by default.  Set C<RELEASE_DEBUG> to a true value to get
debugging output.

=item * PERL

The C<PERL> environment variable sets the path to perl for use in the
make; otherwise, the perl used to run release will be used.

=back

=head1 TO DO

=over 4

=item * break out functional groups into modules.

=item * more plugins!

=back

=head1 SOURCE AVAILABILITY

This source is in Github as part of the Module::Release project:

        git://github.com/briandfoy/module-release.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2008, brian d foy, All rights reserved.

You may use this software under the same terms as Perl itself.

=head1 CREDITS

Ken Williams turned the original release(1) script into a module.

Andy Lester contributed to the module and script.

H. Merijn Brand submitted patches to work with 5.005 and to create
the automated_testing feature.

=cut

use Getopt::Long;
use Module::Release '2.00_04';

my $class = "Module::Release";


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my %opts;
my( $script_version ) = '2.00_05';

my $tag_vcs = 1;
$opts{k} = 1;
$opts{p} = 1;

GetOptions(
	'usage'      => sub { print "$0 version $script_version\n"; exit; },
	'help'       => \$opts{h},
	'verbose'    => \$opts{d},
	'debug'      => \$opts{d},
	'kwalitee!'  => \$opts{k},
	'test'       => \$opts{t},
	'automate!'  => \$opts{a},
	'prereqs!'   => \$opts{p},
	'tag-vcs!'   => \$tag_vcs,
	) or $opts{h} = 1;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
if( $opts{h} )
	{
	print <<"USE";

Use: $0 --options [ LOCAL_FILE [ REMOTE_FILE ] ]

Will upload current release LOCAL_FILE, naming it REMOTE_FILE.  Will
get LOCAL_FILE and REMOTE_FILE automatically (using same name for
both) if not supplied.

	--help        This help
	--verbose     Print extra debugging information
	--nokwalitee  Skip kwalitee check
	--test        Just make and test distribution, don't tag/upload
	--usage       Print the script version number and exit

The program works in the current directory, and looks for a .releaserc
or releaserc file and the environment for its preferences.  See
`perldoc $0`, for more information.

USE

	exit;
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# get the release object
my %params;
$params{local}  = shift @ARGV if @ARGV;

if( @ARGV )
	{
    $params{remote} = shift @ARGV;
	}
elsif( $params{local} )
	{
    $params{remote} = $params{local};
	}

$params{debug} = 1 if $opts{d};

my $release = $class->new( %params );

$release->_debug( "release $script_version, using $class "
	.  $class->VERSION . "\n" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# load whatever will handle source control
{
my @vcs = (
	[ '.git'       => "Module::Release::Git" ],
	[ '.gitignore' => "Module::Release::Git" ],
	[ '.svn'       => "Module::Release::SVN" ],
	[ 'CVS'        => "Module::Release::CVS" ],
	);

foreach my $vcs ( @vcs )
	{
	next unless -e $vcs->[0];

	my $module = $vcs->[1];

	if ($tag_vcs) {
		$release->_debug( "I see an $vcs->[0] directory, so I'm loading $module\n" );

		$release->load_mixin( $module );

		die "Could not load $module: $@\n" if $@;
	}
	
	last;
	}

}

if( $release->config->interactive ) # not a dry run
	{
	local $ENV{'PERL_MM_USE_DEFAULT'} = 1;
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Will we upload to PAUSE?
if( $release->config->cpan_user ) # not a dry run
	{
	$release->load_mixin( 'Module::Release::PAUSE' );
	}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Will we upload to PAUSE?
$release->load_mixin( 'Module::Release::Prereq' );

my $skip_prereqs = (not $opts{p}) || $release->config->skip_prereqs;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set automated testing from command line, config, environment, or default 
{
no warnings 'uninitialized';

$ENV{AUTOMATED_TESTING} = ( 
	grep { defined } ( 
		($opts{a} == 1), $release->config->automated_testing, 
		$ENV{AUTOMATED_TESTING}, 0 ) 
	)[0];
$release->_debug( "Automated testing is $ENV{AUTOMATED_TESTING}; -a was $opts{a};" .
	" automated_testing was " . $release->config->automated_testing . ";\n" );
}	
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# test with a bunch of perls
{
my $old_perl = $release->get_perl;

foreach my $perl ( $release->perls )
	{
	$release->_print("============Testing with $perl\n");
	$release->set_perl( $perl ) or next;

	$release->clean;
	$release->build_makefile;
	$release->make;
	$release->test;

	unless( $skip_prereqs )
		{
		$release->check_prereqs;
		}
	else
		{
		$release->_print( "Skipping prereq checks. Shame on you!\n" );
		}
		
	$release->dist;
	$release->disttest;
	}

$release->set_perl( $old_perl );
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# check kwalitee
unless( (not $opts{k}) || $release->config->skip_kwalitee  )
	{
	$release->load_mixin( 'Module::Release::Kwalitee' );
	$release->_print("============Testing for kwalitee\n");
	$release->clean;
	$release->build_makefile;
	$release->make;
	$release->dist;
	$release->check_kwalitee;
	}
else
	{
	$release->_print( "Skipping kwalitee checks. Shame on you!\n" );
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# check source repository (but do not commit)

$release->_print("============Checking source repository\n");

$release->check_vcs;

my $Version = $release->dist_version;

$release->_debug( "dist version is  $Version\n" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# exit if this is a dry run. Everything following this changes
# things or uploads. Don't leave anything behind.

if( $opts{t} )
	{
	$release->distclean;
	unlink glob( "*.tar*" );
	exit;
	}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#unless( $release->debug )
#	{ 
#	my $changes = "Changes";
#	my $bak     = $changes . ".bak";

#	die "Changes file does not exist!\n" unless -e $changes;

#	$release->_print( "\n", "-" x 73, "\n", "Enter Changes section\n\n> " );

#	my $str = $Version . " - " . localtime() . "\n";

#	while( <STDIN> )
#		{
#		$_ =~ s/^(\S)/\t$1/; # always indent

#		$str .= $_;
#		$release->_print( "> " );
#		}

#	$str .= "\n";
#
#	rename $changes, $bak or die "Could not backup $changes. $!\n";
#
#	open my $in, $bak or die "Could not read old $changes file! $!\n";
#	open my $out, ">", $changes;

#	while( <$in> )
#		{
#		print $out $_;
#		last unless m/\S/;
#		}

#	print $out $str;

#	print $out $_ while( <$in> );

#	close $in;
#	close $out;

#	my $command = do {
#		if(    -d 'CVS' )  { 'cvs commit -m' }
#		elsif( -d '.svn' ) { 'svn commit -m' }
#		elsif( -d '.git' ) { 'git commit -a -m' }
#		};

#	my $cvs_commit = `$command "* for version $Version" 2>&1`;

#	$release->_print( $cvs_commit );
#	}
#else
#	{
#	$release->_print( "Skipping Changes file since you're debugging" );
#	}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Build the release in preparation for uploading
$release->clean;
$release->touch_all_in_manifest;
$release->build_makefile;
$release->make;
$release->dist;
$release->load_mixin( 'Module::Release::PermissionFix' );
$release->fix_permission();


$release->check_for_passwords;

$release->_debug( "This is where I should release stuff\n" );
while( $release->should_upload_to_pause )
	{
	$release->load_mixin( 'Module::Release::FTP' );
	$release->load_mixin( 'Module::Release::Twitter' );
	$release->twit_password;
	$release->load_mixin( 'Module::Release::UploadOwnSite' );
	$release->ownsite_password;
	$release->load_mixin( 'Module::Release::OpenRepository' );
	$release->_print("Now uploading to PAUSE\n" );
	$release->_print("============Uploading to PAUSE\n");
	last if $release->debug;
	
	$release->ownsite_upload;
	$release->open_upload;
	$release->twit_upload;
	$release->ftp_upload( hostname => $release->pause_ftp_site );
	$release->pause_claim;
	last;
	}

# $release->vcs_tag unless $release->debug;


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
$release->clean;

$release->_print( "Done.\n" );

__END__

#!perl
#----------------------------------------------------------------------
=pod

=head1	NAME

    Build.PL	-- Module::Build Build script for REST::Resource

=head1	SYNOPSIS

    perl Build.PL
    ./Build		## or perl Build
    ./Build test
    ./Build install

=head1	DESCRIPTION

    This script is the build script for REST::Resource.  This build
    script is intended to be run under two semantic environments:

    [1] The master CruiseControl server that allocates builds by
    the module author.

    [2] CPAN users, who will use the last built build-label.

=head1	FILES

    ./Build.PL			- This script.
    ./etc/build_number.txt	- The module-persistent build number.

=head1	AUTHOR

    frotz@acm.org	John "Frotz" Fa'atuai	ffaatuai@cisco.com

=head1	METHODS

=cut

use strict;
use warnings;
use Module::Build;

&main( @ARGV );
exit( 0 );





#----------------------------------------------------------------------
=pod

=head2	main()

USAGE:

    &main( $build_label, $build_time );
    exit( 0 );

DESCRIPTION:

    This method allocates a Module::Build instance, which verifies the
    environment requirements and generates the resulting ./Build
    script.  Additionally, if run on Windows, a batch file wrapper is
    generated.

    The parameters below are ONLY used by the master CruiseControl
    instance.  They are not used by CPAN module users.

PARAMETERS:

    $build_label	-- CruiseControl build-label value.
    $build_time		-- CruiseControl build-time value.

=cut

sub	main
{
    my( $label )	= shift()	|| "";
    my( $time )		= shift()	|| "";
    if  ($label =~ /^(\d+\.\d+\.\d+\.\d+)$/ &&
	 $time  =~ /$time/ )
    {
	mkdir( "./etc", 0755 )		unless( -d "./etc" );
	&write( "./etc/build_number.txt", $label );
	@ARGV = ();					## BAD: Have to hide this from Module::Build.
    }
    my( @lines )	= &read( "./etc/build_number.txt" );
    my( $build_number )	= $lines[0];
    chomp( $build_number );
    &update( "./lib/REST/Resource.pm",		"MODULE-VERSION-NUMBER", $build_number );
    &update( "./lib/REST/Request.pm",		"MODULE-VERSION-NUMBER", $build_number );
    &update( "./lib/REST/RequestFast.pm",	"MODULE-VERSION-NUMBER", $build_number );
    &update( "./eg/cgi_server/parts.cgi",	"MODULE-VERSION-NUMBER", $build_number );
    &update( "./eg/fcgi_server/parts.fcgi",	"MODULE-VERSION-NUMBER", $build_number );
    my( $build ) = Module::Build->new( dist_author	=> "frotz\@acm.org",
				       dist_name	=> "REST-Resource",
				       dist_version	=> $build_number,
				       dist_abstract	=> "Abstract base class for RESTful CGIs.",
				       license		=> "apache",
				       recommends	=>
				       {
					   "FCGI"		=> ">= 0.67",
					   "CGI"		=> ">= 3.27",
					   "CGI::Fast"		=> ">= 1.07",
					   "HTTP::Status"	=> ">= 1.28",
					   "JSON"		=> ">= 1.07",
					   "XML::Dumper"	=> ">= 0.81",
					   "Data::Dumper"	=> ">= 2.121",
					   "IO::String"	=> ">= 0",
				       },
				       requires		=>
				       {
					   perl			=> "5.6.1",
					   "CGI"		=> "> 0",
					   "HTTP::Status"	=> "> 0",
					   "Data::Dumper"	=> "> 0",
					   "Module::Build"	=> "> 0",
				       },
				       build_requires	=>
				       {
				       },
				       build_recommends	=>
				       {
					   "Devel::Cover" 	=> ">= 0.55",
					   "Test::Class"	=> ">= 0.22",
					   "Test::More"		=> ">= 0.66",
					   "Test::Pod"		=> "> 0",
					   "Pod::Simple"	=> "> 0",
				       },
				       );
    $build->create_build_script;
    `pl2bat Build`		if  ($ =~ /win/i);
    if  ($label =~ /^(\d+\.\d+\.\d+\.\d+)$/ &&
	 $time  =~ /$time/ )
    {
	&repository_commit( $label );
    }
}





#use Module::Build;
#         my $class = Module::Build->subclass( class => ’My::Builder’, code => q{ sub ACTION_foo {} }, );





#----------------------------------------------------------------------
=pod

=head2	read()

USAGE:

    my( $contents )	= &read( $file );

DESCRIPTION:

    This method will read the specified file and return its contents
    to the caller as a scalar.

=cut

sub	read
{
    my( $file )	= shift;
    my( @lines );
    if  (open( FILE, $file ))
    {
	@lines	= <FILE>;
	close( FILE );
    }
    else
    {
	die( "Unable to read file [$file]: $!" );
    }
    return( @lines );
}





#----------------------------------------------------------------------
=pod

=head2	write()

USAGE:

    &write( $file, $contents );

DESCRIPTION:

    This method will [re-]write the specified file with $contents.

=cut

sub	write
{
    my( $file )		= shift;
    my( @lines )	= @_;
    chmod( 0755, $file )			if	($file =~ /cgi$/);
    chmod( 0644, $file )			unless	($file =~ /cgi$/);
    if  (open( FILE, ">$file" ))
    {
	print FILE @lines;
	close( FILE );
    }
    else
    {
	die( "Unable to write file [$file]: $!" );
    }
}




#----------------------------------------------------------------------
=pod

=head2	update()

USAGE:

    &update( $filename, $signature, $build_number );

DESCRIPTION:

    This method will update $filename by replacing any line matching
    the $signature pattern with:

        our( $VERSION ) = '$build_number';

=cut

sub	update
{
    my( $filename )	= shift;	## File to touch.
    my( $signature )	= shift;	## Line to replace.
    my( $build_number )	= shift;

    if  (open( FILE, $filename ))
    {
	my( @lines )	= <FILE>;
	close( FILE );
	if  (open( FILE, ">$filename" ))
	{
	    foreach my $line (@lines)
	    {
		chomp( $line );
		if  ($line =~ /$signature/)
		{
		    print "$filename:	\$VERSION	=> '$build_number'\n";
		    $line	= "our( \$VERSION )	= '$build_number';	## $signature";
		}
		print FILE "$line\n";
	    }
	    close( FILE );
	}
	else
	{
	    die( "Unable to re-write [$filename]: $!" );
	}
    }
    else
    {
	die( "Unable to read [$filename]: $!" );
    }
}


#----------------------------------------------------------------------
=pod

=head2	repository_commit()

USAGE:

    &repository_commit();

DESCRIPTION:

    This code should ONLY be invoked on a machine that has access to
    the Subversion (either the master or a mirror).  This method
    handles the final check-in and commit of changes within the build
    tree.

    In a perfect world, there is nothing to commit.

=cut

sub	repository_commit
{
    my( $label )	= shift;

    die "SVN_SSH=[$ENV{SVN_SSH}] - undefined"	unless( defined( $ENV{SVN_SSH} ) );

    print "Build: Cleaning build hierarchy...\n";
    `rm -rf blib _build coverage cover_db`;

    print "Subversion: Generating Change History...\n";
    `svn log -v > build_repository_report.txt`;

    print "Subversion: Committing...\n";
    `svn commit -m "Finalizing Build $label."`;

    print "Subversion: Branching: [build-$label]\n";
    `svn copy -m "Build $label" $ENV{SVN_SSH}/REST-Resource/trunk $ENV{SVN_SSH}/REST-Resource/builds/build-$label`;

    print "Regenerating ./Build\n";
    `perl Build.PL`;
}

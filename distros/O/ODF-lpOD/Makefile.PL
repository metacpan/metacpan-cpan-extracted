#=============================================================================
#
#       Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#       Copyright (c) 2014 Jean-Marie Gouarné.
#       Author: Jean-Marie Gouarné <jean.marie.gouarne@online.fr>
#
#=============================================================================
use     5.010_001;
use     strict;
#=============================================================================
#       Packaging & installation for ODF::lpOD - 2014-05-21T10:32:13
#=============================================================================
use ExtUtils::MakeMaker;
use Getopt::Long;
#-----------------------------------------------------------------------------

sub	default_version
	{
	'0.000'
	}

sub	default_author
	{
	'Jean-Marie Gouarne <jean-marie.gouarne@online.fr>'
	}

sub	default_date
	{
	my @lt = localtime();
	return sprintf(
		"%04d-%02d-%02dT%02d:%02d:%02d",
		$lt[5] + 1900, $lt[4] + 1, $lt[3], $lt[2], $lt[1], $lt[0]
		);
	}

GetOptions
	(
	'version=s'	=> \(my $version	= default_version),
	'date=s'	=> \(my $dist_date	= default_date),
	'author=s'	=> \(my $author		= default_author),
	'build'		=> \(my $build		= undef),
	'prompt!'	=> \(my $prompt		= 1)
	);

#-----------------------------------------------------------------------------

if ($build)
        {
        require File::Copy;

        if ($prompt)
                {
                my $ok = "N";
                do  {
                        $version	= prompt("Version number ?", $version);
                        $dist_date	= prompt("Build date ?", $dist_date);
                        $author		= prompt("Packager ?", $author);
                        $ok		= prompt("OK ? (Y/N)", "Y");
                        }
                        until (uc($ok) eq "Y")
                }
        else
                {
                say for (
                        "Version number : $version",
                        "Build date : $dist_date",
                        "Packager : $author"
                        );
                }

        File::Copy::copy("lib/ODF/lpOD.pm", "lib/ODF/lpOD.bak");
        open    LPOD, 	"<", "lib/ODF/lpOD.pm";
        open	TMP,	">", "lib/ODF/lpod.tmp";
        my @lpod = ();
        while (my $line = <LPOD>)
                {
                if	($line =~ /VERSION/) {
                        $line =~ s/".*"/"$version"/;
                        }
                elsif	($line =~ /PACKAGE_DATE/) {
                        $line =~ s/".*"/"$dist_date"/;
                        }

                print TMP $line;
                }
        close   LPOD;
        close	TMP;
        unlink("lib/ODF/lpOD.pm"); rename("lib/ODF/lpod.tmp", "lib/ODF/lpOD.pm");
        }

#-----------------------------------------------------------------------------

WriteMakefile
        (
        'NAME'              => 'ODF::lpOD',
        'VERSION'           => $version,
        'ABSTRACT_FROM'     => 'lib/ODF/lpOD.pod',
    	'AUTHOR'            => $author,
		'LICENSE'   => 'GPL',
        'MIN_PERL_VERSION'  => '5.016000', # Needed for feature current_sub
        META_MERGE => {
            resources => {
                repository => 'https://github.com/ctrlo/ODF-lpOD/',
                bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=ODF-lpOD',
                homepage   => 'https://github.com/ctrlo/ODF-lpOD/',
            },
        },
    	'PREREQ_PM'         =>
                {
                'XML::Twig'         => '3.34',
                'Archive::Zip'      => '1.30',
                'File::Temp'        => '0.12',
                'File::Find'        => '1.01',
                'Time::Local'       => '1.07',
                'IO::File'          => '1.14',
                'File::Basename'    => '2.76',
                'File::Slurp'       => '0',
                'File::Type'        => '0',
                'Image::Size'       => '0',
                'LWP::Simple'       => '0',
                'experimental'      => '0'
                },
        'EXE_FILES'         =>
                [
                'bin/lpod_test'
                ]
        );

#-----------------------------------------------------------------------------

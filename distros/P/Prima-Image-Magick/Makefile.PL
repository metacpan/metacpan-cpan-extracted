# $Id: Makefile.PL,v 1.6 2012/01/03 16:48:41 dk Exp $
use 5.008008;
use ExtUtils::MakeMaker;

my ( $i, $d, $l) = ('','','');
eval { 
	require Prima::Config;
	$d = join(' ', map { "-D$_" } @{$Prima::Config::Config{cdefs}});
	$i = join(' ', map { "-I$_" } @{$Prima::Config::Config{incpaths}});

	if ( `pkg-config --cflags MagickCore` =~ /^(.+)$/ ) {
		$i .= " $1";
	} else {
        	for ( '/usr/include', @{$Prima::Config::Config{incpaths}}) {
        	        $i .= " -I$_/ImageMagick" if -d "$_/ImageMagick";
        	}
		if ( $^O =~ /win32/i ) {
			for my $p ( split ";", $ENV{PATH}) {
				$i .= " -I\"$p/include\"" if -d "$p/include/magick";
			}
		}
	}
	$l = $Prima::Config::Config{libname} if $^O =~ /win32/i;
	$i .= ' -Iinclude';
};

my $magicklib = '-lMagickCore';
if ( 
	`convert -version` =~ /Version: ImageMagick (\d+\.\d+\.\d+)/ 
) {
	my $v = $1;
	$v =~ s/\.//g;
	if ($v < 641) {
		$magicklib = '-lMagick';
	} elsif ( `pkg-config --libs MagickCore` =~ /^(.+)$/ ) {
		$magicklib = $1;
	}
}

WriteMakefile(
	NAME              => 'Prima::Image::Magick',
	VERSION_FROM      => 'lib/Prima/Image/Magick.pm',
	PREREQ_PM         => {
		'Prima'		=> 0,
		'Image::Magick' => 0,
	},
	ABSTRACT_FROM     => 'lib/Prima/Image/Magick.pm',
	AUTHOR            => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	LIBS              => [ "$l $magicklib" ],
	DEFINE            => $d,
	INC               => $i,
	OBJECT            => "prima\$(OBJ_EXT) mag\$(OBJ_EXT) Magick\$(OBJ_EXT)",
);

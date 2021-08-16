use strict;
use warnings;
use ExtUtils::MakeMaker 6.48;

# make sure we can run gnuplot before continuing
{
    unless(`gnuplot -V`)
    {
        print STDERR <<EOM;

Error: "$!"

I tried to execute 'gnuplot' and it didn't work. Since this module is an is an
interface to Gnuplot, it must be installed for the module to be useful. Install
Gnuplot to continue. Use your package manager, or download the source from
http://www.gnuplot.info
EOM

        exit 0;
    }
}


sub MY::libscan {
    package MY;

    my ($self, $file) = @_;

    # Don't install the README.pod or any .pl file
    return undef if $file =~ /\.pl$|^README.pod/;

    return $self->SUPER::libscan ($file);
}


sub MY::postamble {
    my $text = <<'FOO';
install ::
	@echo "Updating PDL documentation database...";
	@$(PERL) -e "exit if $$ENV{DESTDIR}; use PDL::Doc; eval { PDL::Doc::add_module(q{PDL::Graphics::Gnuplot}); }; ";

FOO
    return $text;
}


WriteMakefile(
    NAME                      => 'PDL::Graphics::Gnuplot',
    AUTHOR                    => 'Craig DeForest <craig@deforest.org>, Dima Kogan <dima@secretsauce.net>',
    VERSION_FROM              => 'lib/PDL/Graphics/Gnuplot.pm',
    ABSTRACT_FROM             => 'lib/PDL/Graphics/Gnuplot.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE'          => 'perl')
        : ()
    ),
    MIN_PERL_VERSION          => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64', # TEST_REQUIRES
    },
    PREREQ_PM => { 
            'Alien::Gnuplot'      => 0,
	    'PDL'                 => 0,
	    'PDL::Transform::Color' => 0,
	    'IPC::Run'            => 0,
	    'List::Util'          => 0,
	    'Storable'            => 0,
	    'IPC::Open3'          => 0,
	    'IO::Select'          => 0,
	    'Time::HiRes'         => 0,
	    'Safe::Isa'           => 0
    },
    TEST_REQUIRES => {
        'Test::More'          => '0.88',
    },
    META_ADD => {
        resources => {
            homepage          => 'http://github.com/PDLPorters/PDL-Graphics-Gnuplot',
            repository        => 'git://github.com/PDLPorters/PDL-Graphics-Gnuplot.git',
            bugtracker        => 'http://github.com/PDLPorters/PDL-Graphics-Gnuplot/issues'
        }
    },  

    dist                      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean                     => { FILES => 'PDL-Graphics-Gnuplot-* pdl_graphics_gnuplot_test_* *~' },
  );

# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
my $POD_header = <<EOF;
    =head1 OVERVIEW

This is a Gnuplot-based plotter for PDL. This repository stores the history for
the PDL::Graphics::Gnuplot module on CPAN. Install the module via CPAN. CPAN
page at L<http://metacpan.org/pod/PDL::Graphics::Gnuplot>.

    =cut

EOF
$POD_header =~ s{^    }{}gm;

if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
    open MOD, 'lib/PDL/Graphics/Gnuplot.pm' or die "Couldn't open main module";
    open README, '>README.pod'              or die "Couldn't open README.pod";

    print README $POD_header;

    while (<MOD>)
    {
        if (/^=/../^=cut/) { print README; }
    }
}

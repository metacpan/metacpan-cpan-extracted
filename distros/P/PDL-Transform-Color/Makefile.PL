use strict;
use warnings;
use ExtUtils::MakeMaker;

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
	@$(PERL) -e "exit if $$ENV{DESTDIR}; use PDL::Doc; eval { PDL::Doc::add_module(q{PDL::Trasform::Color}); }; ";

FOO
    return $text;
}


WriteMakefile(
    NAME                      => 'PDL::Transform::Color',
    AUTHOR                    => 'Craig DeForest <craig@deforest.org>',
    VERSION_FROM              => 'lib/PDL/Transform/Color.pm',
    ABSTRACT_FROM             => 'lib/PDL/Transform/Color.pm',
    LICENSE                   => 'perl',
    MIN_PERL_VERSION          => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.48,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => { 
        'PDL'                 => 0,
        'PDL::MatrixOps'      => 0,
	'PDL::Transform'      => 0,
    },
    META_ADD => {
        resources => {
            homepage          => 'http://github.com/PDLPorters/PDL-Transform-Color',
            repository        => 'git://github.com/PDLPorters/PDL-Transform-Color.git',
            bugtracker        => 'http://github.com/PDLPorters/PDL-Transform-Color/issues'
        }
    },  

    dist                      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean                     => { FILES => 'PDL-Transform-Color-* pdl_transform_color_test_* *~' },
  );

# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
my $POD_header = <<EOF;
=head1 OVERVIEW

This module provides transformations for manipulating color.  This repository 
stores the history for the PDL::Transform::Color module on CPAN. 

=cut

EOF


if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
    open MOD, 'lib/PDL/Transform/Color.pm ' or die "Couldn't open main module";
    open README, '>README.pod'              or die "Couldn't open README.pod";

    print README $POD_header;

    while (<MOD>)
    {
        if (/^=/../^=cut/) { print README; }
    }
}

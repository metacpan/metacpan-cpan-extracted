use ExtUtils::MakeMaker;
# Add in the Ex::MM::Coverage stuff.  But silently ignore failure.
eval q{
    use ExtUtils::MakeMaker::Coverage;
    # I keep some modules outside of /usr/lib/perl5
    my $config = ExtUtils::MakeMaker::Coverage->config;
    $config->ignore( ['site_perl'] );
};

package MY;

use strict;
use warnings;

sub init_PM
{
    my( $self, @args ) = @_;

    $self->SUPER::init_PM( @args );

    foreach my $file ( keys %{ $self->{PM} || {} } ) {
        next if $file =~ /^lib.+\.pm$/;
        delete $self->{PM}{$file};
    }
    # warn join ', ', keys %{ $self->{PM} };
}

package main;
WriteMakefile(
    NAME              => 'POE::Session::Multiplex',
    VERSION_FROM      => 'lib/POE/Session/Multiplex.pm',
    PREREQ_PM         => {
            'POE'           => 1,
            'Scalar::Util'  => 0,
#            'Devel::Size'   => 0
        }, 
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'lib/POE/Session/Multiplex.pm',
       AUTHOR         => 'Philip Gwyn <gwyn-at-cpan.org>') : ()),
    LICENSE           => 'perl'
);

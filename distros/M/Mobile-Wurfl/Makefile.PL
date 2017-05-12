use ExtUtils::MakeMaker;
use File::Find;

my $name = 'Mobile::Wurfl';
my %prereq_pm;
find(
    sub {
        return unless -f;
        return unless -T;
        return unless /\.(pm|t|pl|cgi)$/i;
        open( FH, $_ );
        for ( <FH> )
        {
            $prereq_pm{$1} = 0
                if /(?:use|require)\s+([A-Z][A-Za-z0-9:]+)/
                && $1 ne $name
            ;
        }
    }, "." 
);
warn "the following modules are required:\n", map "\t$_\n", sort keys %prereq_pm;
WriteMakefile(
    'NAME'		=> $name,
    'VERSION_FROM'	=> 'lib/Mobile/Wurfl.pm',
    'PREREQ_PM'		=> \%prereq_pm
);

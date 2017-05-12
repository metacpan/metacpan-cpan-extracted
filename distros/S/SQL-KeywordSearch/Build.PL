shift(@ARGV) if $ARGV[0] eq 'Build'; # accomodate with CPAN autoinstall
use Module::Build;

my $class = Module::Build->subclass(
	 class => 'SQL::KeywordSearch::Builder',
	 code => q{
	 	sub ACTION_dist {
			my $self = shift;
			`perldoc -t lib/SQL/KeywordSearch.pm>README`;
			$self->SUPER::ACTION_dist;
	 	}

        sub ACTION_cover {
            my $self = shift;
            $self->depends_on('build');

            system qw( cover -delete );

            # sometimes we get failing tests, which makes Test::Harness
            # die.  catch that
            eval {
                local $ENV{PERL5OPT} = "-MDevel::Cover=-summary,0";
                $self->ACTION_test(@_);
            };
            system qw( cover -report html );
        }
 	},
);


$class->new(
    dist_author         => 'Mark Stosberg <mark@summersault.com>',
	module_name         => 'SQL::KeywordSearch',
	license => 'perl',
	requires => {
		'Test::More'  	 	=> 0,
		'Params::Validate' 	=> 0,
	},
    recommends => {
        'SQL::Interp' => 0,
    },
)->create_build_script;


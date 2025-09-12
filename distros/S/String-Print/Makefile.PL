use ExtUtils::MakeMaker;

use 5.016;


# Use command 'oodist' to produce your whole software release.
my $version  = '0.95';
my $git      = "https://github.com/markov2/perl5-String-Print";
my $publish  = "../public_html/string-print";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.04,
	first_year => 2016,
	email    => "markov\@cpan.org",

	include  => [
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [ ],
		pmhead         => undef,
	},

	tests    => {
	},

	release  => {
		publish        => "$publish/source",
	},

	raw      => {
		publish        => "$publish/raw",
	},

	generate => [
	  {	# Add real pod to the releases
		format         => 'pod3',
		podtail        => undef,
	  },
	  # You may add HTML formatters here.
	  # You may add exporter configurations here.
	],
);

WriteMakefile
	NAME      => 'String::Print',
	VERSION   => $version,
	PREREQ_PM => +{
		'Test::More'        => 0.86,
		'Unicode::GCString' => 0,
		'Encode'            => 0,
		'HTML::Entities'    => 0,
		'Date::Parse'       => 2.30,
	},

	AUTHOR     => 'Mark Overmeer <markov@cpan.org>',
	ABSTRACT   => 'printf extensions',
	LICENSE    => 'perl_5',
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => "$git.git",
				web  => $git,
			},
			homepage => $homepage,
			license  => [ 'http//dev.perl.org/licenses/' ],
		},
		prereqs => {
			develop => {
				requires => {
					'OODoc' => 3.04,
				}
			},
			test => {
				requires => {
					'Test::More' => 1.00,
					'Test::Pod'  => 1.00,
				}
			},
		},

		# You may use multiple set-ups, see "oodist --make"
		x_oodist => \%oodist,
	};

use ExtUtils::MakeMaker;

require 5.016;

# Use command 'oodist' to produce your whole software release.
my $version  = 0.22;
my $git      = "https://github.com/markov2/perl5-Object-Realize-Later";
my $publish  = "../public_html/object-realize-later";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.05,
	first_year    => 2001,
	email         => "markov\@cpan.org",

	include  => [
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [
		],
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

	generate => [ {
		# Add real pod to the releases
		format         => 'pod3',
		podtail        => undef,
	  },
 	  # You may add HTML formatters here.
 		  # You may add exporter configurations here.
	],
);

WriteMakefile
	NAME      => 'Object::Realize::Later',
	VERSION   => $version,
	PREREQ_PM => {
		Scalar::Util => 0.0,
	},
	AUTHOR    => 'Mark Overmeer <markov@cpan.org>',
	ABSTRACT  => 'Delayed realization of objects',
	LICENSE   => 'perl_5',

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
					'OODoc' => '3.00',
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

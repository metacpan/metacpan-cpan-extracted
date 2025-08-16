use ExtUtils::MakeMaker;

require 5.016;

# Use command 'oodist' to produce the documentation before the software release.
my $git      = "https://github.com/markov2/perl5-OODoc-Template";
my $publish  = "../public_html/oodoc-template";
my $homepage = "http://perl.overmeer.net/oodoc-template/";

my %oodist   = (
	oodoc_version => 3.00,
	first_year => 2003,
	email    => "perl\@overmeer.net",

	include  => [
		'../OODoc',
	],

	use      => [
		'../Log-Report',
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
	],
);

WriteMakefile
	NAME       => 'OODoc::Template',
	VERSION    => 0.19,
	AUTHOR     => 'Mark Overmeer',
	ABSTRACT   => 'Simple template system',
	PREREQ_PM  => {
		'File::Spec::Functions' => 0,
		'Log::Report'  => 1.40,
		'Scalar::Util' => 0,
	},
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
			license  => [ 'https://dev.perl.org/licenses/' ],
		},
		prereqs => {
			develop => {
				requires => {
					'OODoc' => '3.00',
				}
			},
			test => {
				requires => {
					'Test::More' => 0.47,
					'Test::Pod'  => 1.00,
				}
			},
		},

		# You may use multiple set-ups, see "oodist --make"
		x_oodist => \%oodist,
	};

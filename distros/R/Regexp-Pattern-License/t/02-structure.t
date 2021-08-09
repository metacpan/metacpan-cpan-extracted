use Test2::V0;

use Regexp::Pattern::License;

#plan 11;

my %RE = %Regexp::Pattern::License::RE;

my $property  = '_?[a-z][a-z0-9_]*';
my $attribute = '[a-z][a-z0-9_]*';
my $lang      = '[a-z]{2,3}(?:_[A-Z]{2,3})?';

my $localspec_re = qr/^(?:
	# metadata and Regexp::Pattern structs without attributes
	description|examples|licenseversion|tags|gen|gen_args
|
	(?:
		# metadata with optional properties
		(?:name|caption|summary|iri)
		(?:\.alt(?:\.(?:
			# TODO: add tests to check each org
			# TODO: maybe drop less popular orgs (instead using misc)
			org\.(?:cc|debian|fedora|fsf|gentoo|linfo|osi|perl|scancode|software_license|spdx|steward|tldr|trove|wikipedia|wikidata)
		|
			(?:since|until)\.(?:date_\d{8})
		|
			archive\.(?:time_\d{14})
		|
			synth\.nogrant
		|
			version\.$property(?:_[a-z0-9]+)+
		|
			(?:lang\.$lang)?
		|
			(?:old|path|legal|iri|format|misc)\.$attribute
		))+)?
	|
		# patterns
		_?pat
		(?:\.alt(?:\.(?:
			subject\.(?:name|grant|license|iri|trait)
		|
			# TODO: drop overlapping terms
			# TODO: add line_or_sentence, and require unigueness
			scope\.(?:line|sentence|paragraph|multiparagraph|section|multisection|all)
		|
			(?:lang\.$lang)?
		|
			# TODO: drop
			version\.none
		|
			(?:target|part|type|synth|misc)\.$attribute
		))+)?
	)
)$/x;

like \%RE, hash {
	all_keys match qr/^$property(?:\.$attribute)*$/
}, 'object names match Regexp::Pattern spec';

like \%RE, hash {
	all_vals hash {

		all_keys match $localspec_re;
	}
},
	'properties match Regexp::Pattern spec and attributes are alt + key/value pairs';

done_testing;

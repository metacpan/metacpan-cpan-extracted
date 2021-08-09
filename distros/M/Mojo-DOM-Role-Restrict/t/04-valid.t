use Test::More;
use Mojo::DOM;

my $dom = Mojo::DOM->with_roles('+Restrict')->new;

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		'*' => { # apply to all tags
			'*' => 1, # allow all attributes by default
		}
	},
	expected => 1
);

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		html => 1,
		head => 1,
		script => 1,
		body => 1,
		p => 1,
		span => 1
	},
	expected => 1
);

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		'*' => {
			'*' => '^not',
		},
	},
	expected => 0
);

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		script => 0, # remove all script tags
		'*' => { # apply to all tags
			'*' => 1, # allow all attributes by default
			'onclick' => 0 # disable onclick attributes
		},
		span => {
			class => 0 # disable class attributes on span's
		}
	},
	expected => 0
);

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		html => 1,
		head => 1,
		body => 1,
		p => {
			class => 1,
			id => 1
		},
		span => {}
	},
	expected => 0
);

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		html => 1,
		body => 1,
	},
	expected => 0
);

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		html => 1,
		body => 0,
	},
	expected => 0
);

sub basic_test {
	my (%args) = @_;
	my $html = $dom->parse($args{html}, $args{spec});
	is($html->valid, $args{expected}, $args{expected} ? 'valid html' : 'invalid html');
}

done_testing();

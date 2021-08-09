use Test::More;
use Mojo::DOM;

my $dom = Mojo::DOM->with_roles('+Restrict')->new;

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		script => 0,
		'*' => {
			class => '^okay$',
			id => 'allow'
		},
	},
	expected => q|<html><head></head><body><p class="okay" id="allow">Restrict <span>HTML</span></p></body></html>|
);


basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		head => 0,
		'*' => {
			'*' => '^not',
		},
	},
	expected => q|<html><body><p onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|
);

sub basic_test {
	my (%args) = @_;
	my $html = $dom->parse($args{html}, $args{spec});
	is("$html", $args{expected}, $args{expected});
}

done_testing();

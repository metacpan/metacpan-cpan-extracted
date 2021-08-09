use Test::More;
use Mojo::DOM;

my $dom = Mojo::DOM->with_roles('+Restrict')->new;

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		script => 0,
		span => {
			validate_tag => sub {
				delete $_[1]->{class};
				return @_;
			}
		},
		'*' => {
			class => sub {
				my ($attr, $val) = @_;
				my $match = $val =~ m/^okay$/;
				return $match ? ($attr, $val) : 0;
			},
			id => sub {
				return @_;
			}
		},
	},
	expected => q|<html><head></head><body><p class="okay" id="allow">Restrict <span>HTML</span></p></body></html>|
);

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		script => 0,
		span => {
			validate_tag => sub {
				delete $_[1]->{class};
				return @_;
			}
		},
		'*' => {
			class => 1,
			id => sub {
				return @_;
			}
		},
	},
	expected => q|<html><head></head><body><p class="okay" id="allow">Restrict <span>HTML</span></p></body></html>|
);

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		script => 0,
		'*' => {
			class => sub {
				my ($attr, $val) = @_;
				my $match = $val =~ m/^okay$/;
				return $match ? ($attr, $val) : 0;
			},
			id => sub {
				return @_;
			}
		},
	},
	expected => q|<html><head></head><body><p class="okay" id="allow">Restrict <span>HTML</span></p></body></html>|
);

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		script => 0,
		span => {
			validate_tag => sub {
				return ('b', $_[1]);
			}
		},
		p => {
			validate_tag => sub {
				$_[1]->{id} = "prefixed-" . $_[1]->{id};
				$_[1]->{'data-unknown'} = 'abc'; 
				return ('div', $_[1]);
			}
		},
		'*' => {
			'*' => 1,
			onclick => sub { 0 },
			class => sub {
				my ($attr, $val) = @_;
				my $match = $val =~ m/^okay$/;
				return $match ? ($attr, $val) : 0;
			},
			id => sub {
				return @_;
			}
		},
	},
	expected => q|<html><head></head><body><div class="okay" data-unknown="abc" id="prefixed-allow">Restrict <b>HTML</b></div><div class="okay" data-unknown="abc" id="prefixed-allow">Restrict <b>HTML</b></div><div class="okay" data-unknown="abc" id="prefixed-allow">Restrict <b>HTML</b></div><div class="okay" data-unknown="abc" id="prefixed-allow">Restrict <b>HTML</b></div><div class="okay" data-unknown="abc" id="prefixed-allow">Restrict <b>HTML</b></div><div class="okay" data-unknown="abc" id="prefixed-allow">Restrict <b>HTML</b></div></body></html>|
);



sub basic_test {
	my (%args) = @_;
	my $html = $dom->parse($args{html}, $args{spec});
	$html->restrict;
	is($html->to_string(1), $args{expected}, $args{expected});
}

done_testing();

use Test::More;
use Mojo::DOM;

my $html = q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|;

my $spec = {
	script => 0, # remove all script tags
	'*' => { # apply to all tags
		'*' => 1, # allow all attributes by default
		'onclick' => 0 # disable onclick attributes
	},
	span => {
		class => 0 # disable class attributes on span's
	}
};

my $dom = Mojo::DOM->with_roles('+Restrict')->new($html, $spec);
is ("$dom", q|<html><head></head><body><p class="okay" id="allow">Restrict <span>HTML</span></p></body></html>|);

$dom = Mojo::DOM->with_roles('+Restrict')->new;

$spec = {
	script => 0,
	'*' => {
		'*' => 1,
		onclick => sub { 0 },
		id => sub { return @_ },
		class => sub {
			my ($attr, $val) = @_;
			my $match = $val =~ m/^okay$/;
			return $match ? ($attr, $val) : 0;
		}
	},
	span => {
		validate_tag => sub {
			return ('b', $_[1]);
		}
	},
	p => {
		validate_tag => sub {
			$_[1]->{id} = "prefixed-" . $_[1]->{id};
			$_[1]->{'data-unknown'} = 'abc'; 
			return @_;
		}
	},
};

$dom->parse($html, $spec);
	
is($dom->to_string, q|<html><head></head><body><p class="okay" data-unknown="abc" id="prefixed-allow">Restrict <b>HTML</b></p></body></html>|);

# you can change the spec and then re-render
$spec = {
	'*' => {
		'*' => '^not',
	},
};

$dom->restrict_spec($spec);
	
is($dom->to_string, q|<html><head><script>...</script></head><body><p onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|);


# check whether the spec is valid
is($dom->valid, 0);

# apply spec changess to the Mojo::DOM object
ok($dom->restrict);

# re-check whether the spec is valid
is($dom->valid, 1); # 1

$dom->parse(q|<p class="okay" data-unknown="abc" id="prefixed-allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p>|);

is($dom->to_string, q|<p onclick="not-allow">Restrict <span class="not-okay">HTML</span></p>|);



done_testing();

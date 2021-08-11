use Test::More;
use Mojo::DOM;

BEGIN {
        eval {
                require Text::Diff;
                1;
        } or do {
                print $@;
                plan skip_all => "Text::Diff is not available";
                done_testing();
        };
}

my $dom = Mojo::DOM->with_roles('+Restrict')->new;

basic_test(
	html => q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|,
	spec => {
		'*' => { # apply to all tags
			'*' => 1, # allow all attributes by default
		}
	},
	expected => q||
);

basic_test(
	html => q|<html>
	<head>
		<script>...</script>
	</head>
	<body>
		<p class="okay" id="allow" onclick="not-allow">
			Restrict
			<span class="not-okay">HTML</span>
		</p>
	</body>
</html>|,
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
	like => quotemeta(q|@@ -1,11 +1,11 @@
 <html>
 	<head>
-		<script>...</script>
+		
 	</head>
 	<body>
-		<p class="okay" id="allow" onclick="not-allow">
+		<p class="okay" id="allow">
 			Restrict
-			<span class="not-okay">HTML</span>
+			<span>HTML</span>
 		</p>
 	</body>
 </html>
\\ No newline at end of file
|));

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
	like => quotemeta(q|@@ -1 +1 @@
-<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>
\\ No newline at end of file
+<html><head></head><body><p class="okay" id="allow">Restrict <span>HTML</span></p></body></html>
\\ No newline at end of file
|));

sub basic_test {
	my (%args) = @_;
	my $html = $dom->parse($args{html}, $args{spec});
	my $diff = $html->diff;
	$args{like} ? like($diff, qr/$args{like}/, $diff) : is($diff, $args{expected}, $args{expected});
}

done_testing();

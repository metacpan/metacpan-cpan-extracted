use strict;
use warnings;
use utf8;
use Future::AsyncAwait;
use Encode qw(decode_utf8 encode_utf8);

# =============================================================================
# PAGI UTF-8 Round-Trip Test Demo
# =============================================================================
#
# Tests UTF-8 handling across all PAGI input vectors:
#
# 1. PATH TEST: /echo/{utf8_string}
#    - $scope->{path}: decoded Unicode characters (per PAGI spec)
#    - $scope->{raw_path}: percent-encoded bytes from wire
#
# 2. QUERY STRING TEST: ?text={utf8_string}
#    - $scope->{query_string}: percent-encoded bytes (app decodes)
#
# 3. POST BODY TEST: form submit with textarea
#    - Request body: percent-encoded bytes (application/x-www-form-urlencoded)
#    - App must: percent-decode → decode_utf8 → characters
#
# 4. RESPONSE TEST: UTF-8 literals in source
#    - App must: encode_utf8 → bytes for wire
#    - Content-Length must be byte count, not character count
#
# =============================================================================

my $app = async sub  {
        my ($scope, $receive, $send) = @_;
  
    die "Unsupported scope type: $scope->{type}" if $scope->{type} ne 'http';
    
    # Collect request body
    my $body = '';
    while (1) {
        my $message = await $receive->();
        $body .= $message->{body} // '';
        last unless $message->{more};
    }
    
    my $echo = '';
    my $source = '';
    
    # 1. PATH: Check for /echo/{value}
    if ($scope->{path} =~ m{^/echo/(.+)$}) {
        $echo = $1;  # Already decoded per PAGI spec
        $source = 'path';
    }
    # 2. QUERY STRING: ?text={value}
    elsif (length($scope->{query_string} // '') && $scope->{query_string} =~ /text=([^&]*)/) {
        $echo = _uri_decode($1);
        $source = 'query string';
    }
    # 3. POST BODY: text={value}
    elsif (length $body && $body =~ /text=(.*)/) {
        $echo = _uri_decode($1);
        $source = 'POST body';
    }
    
    # Build echo section
    my $echo_section = '';
    if (length $echo) {
        my $chars = length($echo);
        my $bytes = length(encode_utf8($echo));
        my $codepoints = join ' ', map { sprintf 'U+%04X', ord($_) } split //, $echo;
        $echo_section = <<"ECHO";
<div style="background: #e8f5e9; padding: 1em; margin: 1em 0; border-radius: 4px;">
  <h2>Echo (from $source):</h2>
  <pre style="font-size: 1.5em;">$echo</pre>
  <p>Characters: $chars | UTF-8 bytes: $bytes</p>
  <p>Codepoints: $codepoints</p>
</div>
ECHO
    }
    
    # Build path test links
    my @path_samples = ('λ', '🔥', '中文', '♥', 'café');
    my $path_links = join ' | ', map {
        my $encoded = _uri_encode($_);
        qq{<a href="/echo/$encoded">$_</a>}
    } @path_samples;
    
    my $html = <<"HTML";
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>PAGI UTF-8</title></head>
<body>
<h1>PAGI UTF-8 Round-Trip Test</h1>
<p>Samples: λ (Greek) | 🔥 (Emoji) | 中文 (CJK) | ♥ (Symbol) | café (Accented)</p>

$echo_section

<h2>1. Path Test</h2>
<p>Click: $path_links</p>
<p><small>Tests \$scope-&gt;{path} (decoded) vs \$scope-&gt;{raw_path} (bytes)</small></p>

<h2>2. Query String Test</h2>
<form method="GET" action="/">
  <input name="text" value="λ 🔥 中文" style="font-size: 1.2em;" />
  <button type="submit">GET</button>
</form>
<p><small>Tests \$scope-&gt;{query_string} (percent-encoded bytes)</small></p>

<h2>3. POST Body Test</h2>
<form method="POST" action="/">
  <textarea name="text" rows="3" cols="40" style="font-size: 1.2em;">λ 🔥 中文 ♥ café</textarea><br>
  <button type="submit" style="margin-top: 0.5em;">POST</button>
</form>
<p><small>Tests request body (application/x-www-form-urlencoded)</small></p>

</body></html>
HTML

    my $bytes = encode_utf8($html);
    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [
            ['content-type',   'text/html; charset=utf-8'],
            ['content-length', length($bytes)],
        ],
    });
    await $send->({
        type => 'http.response.body',
        body => $bytes,
        more => 0,
    });
};

sub _uri_decode {
    my ($str) = @_;

    $str =~ s/\+/ /g;
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return decode_utf8($str);
}

sub _uri_encode {
    my ($str) = @_;

    my $bytes = encode_utf8($str);
    $bytes =~ s/([^A-Za-z0-9\-._~])/sprintf("%%%02X", ord($1))/eg;
    return $bytes;
}

$app;

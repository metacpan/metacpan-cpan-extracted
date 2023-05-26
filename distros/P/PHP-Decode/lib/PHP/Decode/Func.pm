#
# execute PHP built-in functions
#
package PHP::Decode::Func;

use strict;
use warnings;
use List::Util qw(min max shuffle);
use MIME::Base64;
use Compress::Zlib;
use Digest::MD5 qw(md5 md5_hex);
eval "use Digest::SHA1 qw(sha1 sha1_hex); 1" or eval "use Digest::SHA qw(sha1 sha1_hex); 1" or die "Digest::SHA/SHA1 required";
use HTML::Entities;
use URI::Escape;
use File::Basename;
use PHP::Decode::Array qw(is_int_index);
use PHP::Decode::Op;
use PHP::Decode::Parser qw(:all);
use PHP::Decode::Transformer;

my $VERSION = '0.129';

# if block contains just a sequence of strings, then return joined string
#
sub _joinable_str {
	my ($parser, $s, $val) = @_;

	if (is_block($s)) {
		my ($type, $a) = @{$parser->{strmap}{$s}};
		foreach my $stmt (@$a) {
			$val = &_joinable_str($parser, $stmt, $val);
			last if (!defined $val);
		}
		return $val;
	}
	if (is_strval($s)) {
		return $val . $parser->{strmap}{$s};
	}
	if (is_null($s)) {
		return '';
	}
	return;
}

sub parsing_func {
	my ($ctx) = @_;

	if ($ctx->{infunction}) {
		if (!$ctx->{incall}) {
			return 0;
		}
		return 1;
	}
	return 0;
}

# see: https://gist.github.com/BaiGang/1321793
#
sub levenshtein {
	my ($str1, $str2) = @_;
	my ($len1, $len2) = (length $str1, length $str2);
	my %mat;
 
	if ($len1 == 0) {
		return $len2;
	}
	if ($len2 == 0) {
		return $len1;
	}
	for (my $i = 0; $i <= $len1; ++$i) {
		$mat{0}{$i} = $i;
		$mat{1}{$i} = 0;
	}
	my @ar1 = split //, $str1;
	my @ar2 = split //, $str2;
 
	for (my $j = 1; $j <= $len2; ++$j) {
		my $p = $j % 2;
		my $q = ($j + 1) % 2;
		$mat{$p}{0} = $j;
		for (my $i = 1; $i <= $len1; ++$i) {
			my $cost = 0;
			if ($ar1[$i-1] ne $ar2[$j-1]) {
				$cost = 1;
			}
			$mat{$p}{$i} = min($cost + $mat{$q}{$i-1},
			$mat{$p}{$i-1} + 1, $mat{$q}{$i} + 1);
		}
	}
	return $mat{$len2%2}{$len1};
} 

# see: Perl-only CRC32 function
# http://billauer.co.il/blog/2011/05/perl-crc32-crc-xs-module/
#
my $crc32a_table;
my $crc32b_table;

sub mycrc32a {
	my ($input, $init_value, $polynomial) = @_;

	# hash('crc32', $str);
	# == perl -I./Digest-CRC-0.22/lib -e 'use Digest::CRC;
	#    $ctx = Digest::CRC->new(width=>32, init=>0xffffffff, xorout=>0xffffffff, refout=>0, poly=>0x4C11DB7, refin=>0, cont=>0);
	#    $ctx->add("test");
	#    print $digest = $ctx->hexdigest . "\n";' --> (need to read bytes backwards)
	#
	$init_value = 0 unless (defined $init_value);
	$polynomial = 0x04c11db7 unless (defined $polynomial);

	unless (defined $crc32a_table) {
		$crc32a_table = [];

		for (my $i=0; $i<256; $i++) {
			my $x = $i << 24;
			for (my $j=0; $j<8; $j++) {
				if ($x & (1 << 31)) {
					$x = ($x << 1) ^ $polynomial;
				} else {
					$x = $x << 1;
				}
			}
			$x = $x & 0xffffffff;
			push @$crc32a_table, $x;
		}
	}
	my $crc = $init_value ^ 0xffffffff;

	foreach my $x (unpack ('C*', $input)) {
		$crc = (($crc << 8) & 0xffffff00) ^ $crc32a_table->[(($crc >> 24) & 0xff) ^ ($x & 0xff)];
	}
	$crc = $crc ^ 0xffffffff;

	# reverse byteorder
	$crc = ($crc << 24) & 0xff000000 | ($crc << 8) & 0xff0000 | ($crc >> 8) & 0xff00 | ($crc >> 24) & 0xff;
	return $crc;
}

sub mycrc32b {
	my ($input, $init_value, $polynomial) = @_;

	# hash('crc32b', $str);
	# == perl -I./Digest-CRC-0.22/lib -e 'use Digest::CRC;
	#    $ctx = Digest::CRC->new(width=>32, init=>0xffffffff, xorout=>0xffffffff, refout=>1, poly=>0x4C11DB7, refin=>1, cont=>0); 
	#    $ctx->add("test");
	#    print $digest = $ctx->hexdigest;'
	#
	$init_value = 0 unless (defined $init_value);
	#$polynomial = _reflect(0x04c11db7,32) unless (defined $polynomial);
	$polynomial = 0xedb88320 unless (defined $polynomial);

	unless (defined $crc32b_table) {
		$crc32b_table = [];
		for (my $i=0; $i<256; $i++) {
			my $x = $i;
			for (my $j=0; $j<8; $j++) {
				if ($x & 1) {
					$x = ($x >> 1) ^ $polynomial;
				} else {
					$x = $x >> 1;
				}
			}
			push @$crc32b_table, $x;
		}
	}
	my $crc = $init_value ^ 0xffffffff;

	foreach my $x (unpack ('C*', $input)) {
		$crc = (($crc >> 8) & 0xffffff) ^ $crc32b_table->[($crc ^ $x) & 0xff];
	}
	$crc = $crc ^ 0xffffffff;
	return $crc;
}

# see: https://metacpan.org/dist/PHP-Strings/source/Strings.pm
# todo: might use more functions from PHP::Strings module
#
sub stripcslashes {
    my ($str) = @_;

    $str =~ s{
            \\([abfnrtv\\?'"])
            |
            \\(\d\d\d)
            |
            \\(x[[:xdigit:]]{2})
            |
            \\(x[[:xdigit:]])
    }{
        if ( $+ eq 'v' ) {
            "\013";
        } elsif (length $+ == 1) {
            eval qq{qq/\\$+/};
        } else {
            chr oct "0$+";
        }
    }exg ;
    return $str;
}

sub dyn_replace {
	my ($replace) = @_;
	my @groups;
	{
		no strict 'refs';
		$groups[$_] = $$_ for 1 .. $#-;      # the size of @- tells us the number of capturing groups
	}
	# For the e modifier preg_replace escapes [' " \ NULL] in the replacement string.
	# see: https://www.php.net/manual/en/function.preg-replace.php
	#
	for (my $i=1; $i < scalar @groups; $i++) {
		#print ">> dyn_replace $i: $groups[$i]\n";
		$groups[$i] =~ s/(["'\\\0])/\\$1/g;
	}
	$replace =~ s/\$(\d+)/$groups[$1]/g;
	return $replace;
}

sub dyn_replace_eval {
	my ($ctx, $replace) = @_;
	my $parser = $ctx->{parser};
	my $res = dyn_replace($replace);

	my $code = $parser->setstr($res);
	my $parser2 = $parser->subparser();
	my $ctx2 = $ctx->subctx(parser => $parser2);
	my $block = $ctx2->parse_eval($code);
	my $k = $ctx2->exec_eval($block);
	my $str = _joinable_str($parser, $k, '');
	unless (defined $str) {
		# mark non resolvable code with {{{#stmtX}}} pattern
		#
		$str = '{{{' . $k . '}}}';
	}
	$ctx->{log}->($ctx, 'replace', $replace, "$res -> eval($code) -> $str ($k)") if $ctx->{log};
	return $str;
}

sub dyn_result {
	my ($str, $parser) = @_;
	my @out;
	my $k;
	my $res;

	# when the result contains non resolved statements,
	# then create a chain of concatted expresions.
	#
	while ($str =~ /^(.*?)\{\{\{(#\w+\d+)\}\}\}(.*)$/) {
		if ($1 ne '') {
			$k = $parser->setstr($1);
			push(@out, $k);
		}
		push(@out, $2);
		$str = $3;
	}
	if (($str eq '') && (scalar @out > 0)) {
		$res = pop(@out);
	} else {
		$res = $parser->setstr($str);
	}
	while (scalar @out > 0) {
		my $op1 = pop(@out);
		$res = $parser->setexpr('.', $op1, $res);
	}
	return $res;
}

sub preg_replace {
	my ($ctx, $_pattern, $_replacement, $str, $mode, $limit) = @_;
	my $parser = $ctx->{parser};
	my $pattern = $parser->get_strval($_pattern);
	my $replacement = $parser->get_strval($_replacement);
	my $cnt = 0;
	my $res;
	my $k;

	if ($str eq '#null') {
		$res = '';
	} else {
		$res = $parser->get_strval($str);
	}
	unless (defined $pattern && defined $res) {
		return;
	}
	my $m = '';
	my $modifier;
	if ($mode eq 'preg') {
		my ($delim) = $pattern =~ /^(.)/;
		my $delim2;

		# allow bracket delimiters
		# https://php.net/regexp.reference.delimiters
		#
		if ($delim eq '[') {
			$delim2 = ']';
		} elsif ($delim eq '(') {
			$delim2 = ')';
		} elsif ($delim eq '{') {
			$delim2 = '}';
		} elsif ($delim eq '<') {
			$delim2 = '>';
		} else {
			$delim2 = $delim;;
		}
		# TODO: need to handle escapes in pattern?
		#       https://php.net/manual/en/function.preg-quote.php
		#
		if ($pattern =~ m|^\Q$delim\E([^$delim2]*)\Q$delim2\E(\w*)$|) {
			$pattern = $1;
			$modifier = $2;
			$m .= 'i' if ($modifier =~ /i/);
			$m .= 'm' if ($modifier =~ /m/);
			$m .= 's' if ($modifier =~ /s/);
			$m .= 'x' if ($modifier =~ /x/);
		}
	}

	# don't escape pattern here - it might contain regexp rules
	# don't escape replacement here - special-chars should not get excaped
	#
	if ($limit == 0) {
		# delete pattern
		if ($mode eq 'preg') {
			$res =~ s/$pattern//g;
		} else {
			$res =~ s/\Q$pattern\E//g;
		}
		$k = $parser->setstr($res);
	} else {
		unless (defined $replacement) {
			return;
		}

		# the replacement might contain backreferences in the
		# form '\1'. Convert them to '$1' for perl call.
		#
		if ($mode eq 'preg') {
			$replacement =~ s/(\\([0-9]))/\$$2/g;
		}

		# When the replacement contains backreferences and
		# it comes from data, it needs to get evaled first.
		# (eval as string by /ee does not help in this case).
		#
		# http://stackoverflow.com/questions/1908159/perl-can-i-store-backreferences-not-their-values-in-variables
		#
		if (defined $modifier && $modifier =~ /e/) {
			# eval-modifier deprecated since php-5.5
			# https://php.net/manual/en/reference.pcre.pattern.modifiers.php#reference.pcre.pattern.modifiers.eval
			#
			eval { $res =~ s/$pattern/dyn_replace_eval($ctx, $replacement)/eg; };
			if ($@) {
				$ctx->{warn}->($ctx, 'replace', $str, "bad preg/e $pattern");
				return;
			}
			if (scalar @- > 0) {
				$cnt++;
			}
			$k = dyn_result($res, $parser);
		} else {
			if ($limit != -1) {
				while ($cnt < $limit) {
					if ($mode eq 'preg') {
						eval { $res =~ s/$pattern/dyn_replace($replacement)/e; };
					} else {
						eval { $res =~ s/\Q$pattern\E/$replacement/; };
					}
					if ($@) {
						$ctx->{warn}->($ctx, 'replace', $str, "bad preg $pattern");
						return;
					}
					if (scalar @- == 0) {
						# no match found in substitution
						last;
					}
					$cnt++;
				}
			} else {
				if ($mode eq 'preg') {
					eval { $res =~ s/$pattern/dyn_replace($replacement)/eg; };
				} else {
					# TODO: use quotemeta($replacement) here?
					#
					eval { $res =~ s/\Q$pattern\E/$replacement/g; };
				}
				if ($@) {
					$ctx->{warn}->($ctx, 'replace', $str, "bad preg $pattern");
					return;
				}
				if (scalar @- > 0) {
					$cnt++;
				}
			}
			$k = $parser->setstr($res);
		}
	}
	$ctx->{log}->($ctx, 'replace', $str, "[%s]->[%s] %s -> %s", $parser->shortstr($pattern,40), $parser->shortstr($replacement,40), $parser->shortstr($str,40), $parser->shortstr($res,40)) if $ctx->{log};
	return ($k, $cnt);
}

sub preg_replace_subject {
	my ($ctx, $pattern, $replacement, $str, $mode, $limit) = @_;
	my $parser = $ctx->{parser};

	if (is_array($pattern)) {
		my $arr = $parser->{strmap}{$pattern};
		my $keys = $arr->get_keys();
		my $rep = $replacement;
		my $r_arr;
		my $r_keys;
		my $cnt = 0;

		if (is_array($replacement)) {
			$r_arr = $parser->{strmap}{$replacement};
			$r_keys = $r_arr->get_keys();
		}
		foreach my $k (@$keys) {
			my $val = $arr->val($k);
			if (is_array($replacement)) {
				my $rk = shift(@$r_keys);
				$rep = $r_arr->val($rk);
			}
			#$ctx->{log}->($ctx, 'replace', $str, "preg $val -> $rep [$str]") if $ctx->{log};
			my ($r, $n) = preg_replace($ctx, $val, $rep, $str, $mode, $limit);
			if ($limit != -1) {
				$limit -= $cnt;
			}
			$cnt += $n;
			$str = $r;
		}
		return ($str, $cnt);
	} elsif (is_strval($pattern)) {
		my ($r, $cnt) = preg_replace($ctx, $pattern, $replacement, $str, $mode, $limit);
		return ($r, $cnt);
	}
	return;
}

use constant R_VOID   => 0x0001;
use constant R_INT    => 0x0002;
use constant R_FLOAT  => 0x0004;
use constant R_BOOL   => 0x0008;
use constant R_STR    => 0x0010;
use constant R_ARRAY  => 0x0020;
use constant R_OBJECT => 0x0040;
use constant R_CALL   => 0x0080;
use constant R_MIXED  => 0x0100;
use constant R_FIX    => 0x0200; # string not usable by eval
use constant R_FIXSTR => (R_FIX|R_STR);

# https://php.net/manual/en/function.get-defined-functions.php
# list all:           php -r '$x = get_defined_functions(); print_r($x);'  | less
# list standard:      php -r '$f=get_extension_funcs("standard"); print_r($f);'  | less
# list per extension: php -r '$x = get_loaded_extensions(); foreach ($x as $e) { print ("$e: \n"); $f=get_extension_funcs($e); print_r($f); }'  | less
#
my %php_funcs_core = (
	zend_version => { ret => R_FIXSTR },
	func_num_args => { ret => R_INT },
	func_get_arg => { ret => R_MIXED },
	func_get_args => { ret => R_ARRAY },
	strlen => { ret => R_INT },
	strcmp => { ret => R_INT },
	strncmp => { ret => R_INT },
	strcasecmp => { ret => R_INT },
	strncasecmp => { ret => R_INT },
	each => { param => ['#ref0'], ret => R_ARRAY },
	error_reporting => { ret => R_INT },
	define => { ret => R_BOOL },
	defined => { ret => R_BOOL },
	get_class => { ret => R_STR },
	get_called_class => { ret => R_STR },
	get_parent_class => { ret => R_STR },
	method_exists => { ret => R_BOOL },
	property_exists => { ret => R_BOOL },
	class_exists => { ret => R_BOOL },
	interface_exists => { ret => R_BOOL },
	function_exists => { ret => R_BOOL },
	class_alias => { ret => R_BOOL },
	get_included_files => { ret => R_ARRAY },
	get_required_files => { ret => R_ARRAY },
	is_subclass_of => { ret => R_BOOL },
	is_a => { ret => R_BOOL },
	get_class_vars => { ret => R_ARRAY },
	get_object_vars => { ret => R_ARRAY },
	get_class_methods => { ret => R_ARRAY },
	trigger_error => { ret => R_BOOL },
	user_error => { ret => R_BOOL },
	set_error_handler => { ret => R_CALL },
	restore_error_handler => { ret => R_BOOL },
	set_exception_handler => { ret => R_CALL },
	restore_exception_handler => { ret => R_BOOL },
	get_declared_classes => { ret => R_ARRAY },
	get_declared_interfaces => { ret => R_ARRAY },
	get_defined_functions => { ret => R_ARRAY },
	get_defined_vars => { ret => R_ARRAY },
	create_function => { ret => R_STR, callable => 1 },
	get_resource_type => { ret => R_FIXSTR },
	get_loaded_extensions => { ret => R_ARRAY },
	extension_loaded => { ret => R_BOOL },
	get_extension_funcs => { ret => R_ARRAY },
	get_defined_constants => { ret => R_ARRAY },
	debug_backtrace => { ret => R_ARRAY },
	debug_print_backtrace => { ret => R_VOID },
	gc_collect_cycles => { ret => R_INT },
	gc_enabled => { ret => R_BOOL },
	gc_enable => { ret => R_VOID },
	gc_disable => { ret => R_VOID },
	gc_status => { ret => R_ARRAY },
);

my %php_funcs_standard = (
	exit => { ret => R_VOID }, # is language construct
	die => { ret => R_VOID }, # is language construct
	unset => { ret => R_VOID }, # is language construct
	constant => { ret => R_MIXED },
	bin2hex => { ret => R_FIXSTR },
	sleep => { ret => R_INT },
	usleep => { ret => R_VOID },
	time_nanosleep => { ret => R_ARRAY|R_BOOL },
	time_sleep_until => { ret => R_BOOL },
	strptime => { ret => R_STR },
	flush => { ret => R_VOID },
	wordwrap => { ret => R_STR },
	htmlspecialchars => { ret => R_STR },
	htmlentities => { ret => R_STR },
	html_entity_decode => { ret => R_STR },
	htmlspecialchars_decode => { ret => R_STR },
	get_html_translation_table => { ret => R_ARRAY },
	sha1 => { ret => R_FIXSTR },
	sha1_file => { ret => R_FIXSTR|R_BOOL },
	md5 => { ret => R_FIXSTR },
	md5_file => { ret => R_FIXSTR|R_BOOL },
	crc32 => { ret => R_INT },
	iptcparse => {},
	iptcembed => {},
	getimagesize => {},
	image_type_to_mime_type => {},
	image_type_to_extension => {},
	phpinfo => {},
	phpversion => {},
	phpcredits => {},
	php_logo_guid => {},
	php_real_logo_guid => {},
	php_egg_logo_guid => {},
	zend_logo_guid => {},
	php_sapi_name => {},
	php_uname => { ret => R_STR },
	php_ini_scanned_files => {},
	php_ini_loaded_file => {},
	strnatcmp => {},
	strnatcasecmp => {},
	substr_count => { ret => R_INT },
	strspn => {},
	strcspn => {},
	strtok => {},
	strtoupper => {},
	strtolower => {},
	strpos => {},
	stripos => {},
	strrpos => {},
	strripos => {},
	strrev => { ret => R_STR },
	hebrev => {},
	hebrevc => {},
	nl2br => {},
	basename => {},
	dirname => {},
	pathinfo => {},
	stripslashes => {},
	stripcslashes => {},
	strstr => {},
	stristr => {},
	strrchr => {},
	str_shuffle => {},
	str_word_count => {},
	str_split => { ret => R_ARRAY },
	strpbrk => {},
	substr_compare => {},
	strcoll => {},
	money_format => {},
	substr => {},
	substr_replace => {},
	quotemeta => {},
	ucfirst => {},
	lcfirst => {},
	ucwords => {},
	strtr => {},
	addslashes => {},
	addcslashes => {},
	rtrim => { ret => R_STR },
	str_replace => {},
	str_ireplace => {},
	str_repeat => {},
	count_chars => {},
	chunk_split => {},
	trim => { ret => R_STR },
	ltrim => { ret => R_STR },
	strip_tags => {},
	similar_text => {},
	explode => {},
	implode => {},
	join => {},
	setlocale => {},
	localeconv => {},
	nl_langinfo => {},
	soundex => {},
	levenshtein => {},
	chr => {},
	ord => {},
	parse_str => {},
	str_getcsv => {},
	str_pad => {},
	chop => {},
	strchr => {},
	sprintf => {},
	printf => {},
	vprintf => {},
	vsprintf => {},
	fprintf => {},
	vfprintf => {},
	sscanf => {},
	fscanf => {},
	parse_url => {},
	urlencode => { ret => R_STR },
	urldecode => { ret => R_STR },
	rawurlencode => { ret => R_STR },
	rawurldecode => { ret => R_STR },
	http_build_query => {},
	readlink => {},
	linkinfo => {},
	symlink => {},
	link => {},
	unlink => {},
	exec => { param => ['#str0', '#ref0', '#ref0'], ret => R_STR|R_BOOL },
	system => {},
	escapeshellcmd => {},
	escapeshellarg => {},
	passthru => {},
	shell_exec => {},
	proc_open => {},
	proc_close => {},
	proc_terminate => {},
	proc_get_status => {},
	proc_nice => {},
	rand => {},
	srand => {},
	getrandmax => {},
	mt_rand => {},
	mt_srand => {},
	mt_getrandmax => {},
	getservbyname => {},
	getservbyport => {},
	getprotobyname => {},
	getprotobynumber => {},
	getmyuid => {},
	getmygid => {},
	getmypid => {},
	getmyinode => {},
	getlastmod => {},
	base64_decode => { cmd => \&cmd_base64_decode, ret => R_STR },
	base64_encode => { cmd => \&cmd_base64_encode, ret => R_STR },
	convert_uuencode => {},
	convert_uudecode => {},
	abs => {},
	ceil => {},
	floor => {},
	round => {},
	sin => {},
	cos => {},
	tan => {},
	asin => {},
	acos => {},
	atan => {},
	atanh => {},
	atan2 => {},
	sinh => {},
	cosh => {},
	tanh => {},
	asinh => {},
	acosh => {},
	expm1 => {},
	log1p => {},
	pi => {},
	is_finite => {},
	is_nan => {},
	is_infinite => {},
	pow => { ret => R_INT|R_FLOAT },
	exp => {},
	log => {},
	log10 => {},
	sqrt => {},
	hypot => {},
	deg2rad => {},
	rad2deg => {},
	bindec => {},
	hexdec => {},
	octdec => {},
	decbin => {},
	decoct => {},
	dechex => {},
	base_convert => {},
	number_format => {},
	fmod => {},
	inet_ntop => {},
	inet_pton => {},
	ip2long => {},
	long2ip => {},
	getenv => { cmd => \&PHP::Decode::Transformer::cmd_getenv, ret => R_STR },
	putenv => {},
	getopt => {},
	sys_getloadavg => {},
	microtime => {},
	gettimeofday => {},
	getrusage => {},
	uniqid => {},
	quoted_printable_decode => {},
	quoted_printable_encode => {},
	convert_cyr_string => {},
	get_current_user => {},
	set_time_limit => {},
	get_cfg_var => {},
	magic_quotes_runtime => {},
	set_magic_quotes_runtime => {},
	get_magic_quotes_gpc => {},
	get_magic_quotes_runtime => {},
	import_request_variables => {},
	error_log => {},
	error_get_last => {},
	call_user_func => { callable => 1 },
	call_user_func_array => { callable => 1 },
	call_user_method => { callable => 1 },
	call_user_method_array => { callable => 1 },
	forward_static_call => { callable => 1 },
	forward_static_call_array => { callable => 1 },
	serialize => {},
	unserialize => {},
	var_dump => {},
	var_export => {},
	debug_zval_dump => {},
	print_r => {},
	memory_get_usage => {},
	memory_get_peak_usage => {},
	register_shutdown_function => { callable => 1 },
	register_tick_function => { callable => 1 },
	unregister_tick_function => {},
	highlight_file => {},
	show_source => {},
	highlight_string => {},
	php_strip_whitespace => {},
	ini_get => {},
	ini_get_all => {},
	ini_set => {},
	ini_alter => {},
	ini_restore => {},
	get_include_path => {},
	set_include_path => {},
	restore_include_path => {},
	setcookie => {},
	setrawcookie => {},
	header => {},
	header_remove => {},
	headers_sent => {},
	headers_list => {},
	connection_aborted => {},
	connection_status => {},
	ignore_user_abort => {},
	parse_ini_file => {},
	parse_ini_string => {},
	is_uploaded_file => {},
	move_uploaded_file => {},
	gethostbyaddr => {},
	gethostbyname => {},
	gethostbynamel => {},
	gethostname => {},
	dns_check_record => {},
	checkdnsrr => {},
	dns_get_mx => {},
	getmxrr => {},
	dns_get_record => {},
	intval => { ret => R_INT },
	floatval => { ret => R_FLOAT },
	doubleval => { ret => R_FLOAT },
	strval => { ret => R_STR },
	gettype => {},
	settype => {},
	empty => { ret => R_BOOL },
	isset => { ret => R_BOOL },
	is_null => { ret => R_BOOL },
	is_resource => { ret => R_BOOL },
	is_bool => { ret => R_BOOL },
	is_long => { ret => R_BOOL },
	is_float => { ret => R_BOOL },
	is_int => { ret => R_BOOL },
	is_integer => { ret => R_BOOL },
	is_double => { ret => R_BOOL },
	is_real => { ret => R_BOOL },
	is_numeric => { ret => R_BOOL },
	is_string => { ret => R_BOOL },
	is_array => { ret => R_BOOL },
	is_object => { ret => R_BOOL },
	is_scalar => { ret => R_BOOL },
	is_callable => { ret => R_BOOL },
	pclose => {},
	popen => {},
	readfile => {},
	rewind => {},
	rmdir => {},
	umask => {},
	fclose => {},
	feof => {},
	fgetc => {},
	fgets => {},
	fgetss => {},
	fread => {},
	fopen => {},
	fpassthru => {},
	ftruncate => {},
	fstat => {},
	fseek => {},
	ftell => {},
	fflush => {},
	fwrite => {},
	fputs => {},
	mkdir => {},
	rename => {},
	copy => {},
	tempnam => {},
	tmpfile => {},
	file => {},
	file_get_contents => {},
	file_put_contents => {},
	stream_select => {},
	stream_context_create => {},
	stream_context_set_params => {},
	stream_context_get_params => {},
	stream_context_set_option => {},
	stream_context_get_options => {},
	stream_context_get_default => {},
	stream_context_set_default => {},
	stream_filter_prepend => {},
	stream_filter_append => {},
	stream_filter_remove => {},
	stream_socket_client => {},
	stream_socket_server => {},
	stream_socket_accept => {},
	stream_socket_get_name => {},
	stream_socket_recvfrom => {},
	stream_socket_sendto => {},
	stream_socket_enable_crypto => {},
	stream_socket_shutdown => {},
	stream_socket_pair => {},
	stream_copy_to_stream => {},
	stream_get_contents => {},
	stream_supports_lock => {},
	fgetcsv => {},
	fputcsv => {},
	flock => {},
	get_meta_tags => {},
	stream_set_read_buffer => {},
	stream_set_write_buffer => {},
	set_file_buffer => {},
	set_socket_blocking => {},
	stream_set_blocking => {},
	socket_set_blocking => {},
	stream_get_meta_data => {},
	stream_get_line => {},
	stream_wrapper_register => {},
	stream_register_wrapper => {},
	stream_wrapper_unregister => {},
	stream_wrapper_restore => {},
	stream_get_wrappers => {},
	stream_get_transports => {},
	stream_resolve_include_path => {},
	stream_is_local => {},
	get_headers => {},
	stream_set_timeout => {},
	socket_set_timeout => {},
	socket_get_status => {},
	realpath => {},
	fnmatch => {},
	fsockopen => {},
	pfsockopen => {},
	pack => {},
	unpack => {},
	get_browser => {},
	crypt => {},
	opendir => {},
	closedir => {},
	chdir => {},
	chroot => {},
	getcwd => {},
	rewinddir => {},
	readdir => {},
	dir => {},
	scandir => {},
	glob => {},
	fileatime => {},
	filectime => {},
	filegroup => {},
	fileinode => {},
	filemtime => {},
	fileowner => {},
	fileperms => {},
	filesize => {},
	filetype => {},
	file_exists => {},
	is_writable => {},
	is_writeable => {},
	is_readable => {},
	is_executable => {},
	is_file => {},
	is_dir => {},
	is_link => {},
	stat => {},
	lstat => {},
	chown => {},
	chgrp => {},
	lchown => {},
	lchgrp => {},
	chmod => {},
	touch => {},
	clearstatcache => {},
	disk_total_space => {},
	disk_free_space => {},
	diskfreespace => {},
	realpath_cache_size => {},
	realpath_cache_get => {},
	mail => {},
	ezmlm_hash => {},
	openlog => {},
	syslog => {},
	closelog => {},
	define_syslog_variables => {},
	lcg_value => {},
	metaphone => {},
	ob_start => { cmd => \&PHP::Decode::Transformer::cmd_ob_start, ret => R_BOOL, callable => 1 },
	ob_flush => {},
	ob_clean => {},
	ob_end_flush => { cmd => \&PHP::Decode::Transformer::cmd_ob_end_flush, ret => R_BOOL, callable => 1 },
	ob_end_clean => { cmd => \&PHP::Decode::Transformer::cmd_ob_end_clean, ret => R_BOOL },
	ob_get_flush => {},
	ob_get_clean => {},
	ob_get_length => {},
	ob_get_level => {},
	ob_get_status => {},
	ob_get_contents => {},
	ob_implicit_flush => {},
	ob_list_handlers => {},
	ksort => { param => ['#ref0'], ret => R_BOOL },
	krsort => { param => ['#ref0'], ret => R_BOOL },
	natsort => { param => ['#ref0'], ret => R_BOOL },
	natcasesort => { param => ['#ref0'], ret => R_BOOL },
	asort => { param => ['#ref0'], ret => R_BOOL },
	arsort => { param => ['#ref0'], ret => R_BOOL },
	sort => { param => ['#ref0'], ret => R_BOOL },
	rsort => { param => ['#ref0'], ret => R_BOOL },
	usort => { param => ['#ref0'], ret => R_BOOL, callable => 1 },
	uasort => { param => ['#ref0'], ret => R_BOOL, callable => 1 },
	uksort => { param => ['#ref0'], ret => R_BOOL, callable => 1 },
	shuffle => { param => ['#ref0'], ret => R_BOOL },
	array_walk => { param => ['#ref0'], ret => R_BOOL, callable => 1 },
	array_walk_recursive => { param => ['#ref0'], ret => R_BOOL, callable => 1 },
	count => {},
	end => { param => ['#ref0'], ret => R_MIXED },
	prev => { param => ['#ref0'], ret => R_MIXED },
	next => { param => ['#ref0'], ret => R_MIXED },
	reset => { param => ['#ref0'], ret => R_MIXED },
	current => {},
	key => {},
	min => {},
	max => {},
	in_array => {},
	array_search => {},
	extract => { param => ['#ref0'], ret => R_INT },
	compact => {},
	array_fill => {},
	array_fill_keys => {},
	range => { ret => R_ARRAY },
	array_multisort => { param => ['#ref0'], ret => R_BOOL },
	array_push => { param => ['#ref0'], ret => R_INT },
	array_pop => { param => ['#ref0'], ret => R_MIXED },
	array_shift => { param => ['#ref0'], ret => R_MIXED },
	array_unshift => { param => ['#ref0'], ret => R_INT },
	array_splice => { param => ['#ref0'], ret => R_ARRAY },
	array_slice => {},
	array_merge => {},
	array_merge_recursive => {},
	array_replace => {},
	array_replace_recursive => {},
	array_keys => {},
	array_values => {},
	array_count_values => {},
	array_reverse => {},
	array_reduce => {},
	array_pad => {},
	array_flip => {},
	array_change_key_case => {},
	array_rand => {},
	array_unique => {},
	array_intersect => {},
	array_intersect_key => {},
	array_intersect_ukey => { callable => 1 },
	array_uintersect => { callable => 1 },
	array_intersect_assoc => {},
	array_uintersect_assoc => { callable => 1 },
	array_intersect_uassoc => { callable => 1 },
	array_uintersect_uassoc => { callable => 1 },
	array_diff => {},
	array_diff_key => {},
	array_diff_ukey => { callable => 1 },
	array_udiff => { callable => 1 },
	array_diff_assoc => {},
	array_udiff_assoc => { callable => 1 },
	array_diff_uassoc => { callable => 1 },
	array_udiff_uassoc => { callable => 1 },
	array_sum => {},
	array_product => {},
	array_filter => { callable => 1 },
	array_map => { callable => 1, ret => R_ARRAY },
	array_chunk => {},
	array_combine => {},
	array_key_exists => {},
	pos => {},
	sizeof => {},
	key_exists => {},
	assert => {},
	assert_options => {},
	version_compare => {},
	ftok => {},
	str_rot13 => {},
	stream_get_filters => {},
	stream_filter_register => {},
	stream_bucket_make_writeable => {},
	stream_bucket_prepend => {},
	stream_bucket_append => {},
	stream_bucket_new => {},
	output_add_rewrite_var => {},
	output_reset_rewrite_vars => {},
	sys_get_temp_dir => {},
);

my %php_funcs_date = (
        strtotime => {},
        date => {},
        idate => {},
        gmdate => {},
        mktime => {},
        gmmktime => {},
        checkdate => {},
        strftime => {},
        gmstrftime => {},
        time => {},
        localtime => {},
        getdate => {},
        date_create => {},
        date_create_from_format => {},
        date_parse => {},
        date_parse_from_format => {},
        date_get_last_errors => {},
        date_format => {},
        date_modify => {},
        date_add => {},
        date_sub => {},
        date_timezone_get => {},
        date_timezone_set => {},
        date_offset_get => {},
        date_diff => {},
        date_time_set => {},
        date_date_set => {},
        date_isodate_set => {},
        date_timestamp_set => {},
        date_timestamp_get => {},
        timezone_open => {},
        timezone_name_get => {},
        timezone_name_from_abbr => {},
        timezone_offset_get => {},
        timezone_transitions_get => {},
        timezone_location_get => {},
        timezone_identifiers_list => {},
        timezone_abbreviations_list => {},
        timezone_version_get => {},
        date_interval_create_from_date_string => {},
        date_interval_format => {},
        date_default_timezone_set => {},
        date_default_timezone_get => {},
        date_sunrise => {},
        date_sunset => {},
        date_sun_info => {},
);

my %php_funcs_pcre = (
        preg_match => {},
        preg_match_all => {},
        preg_replace => { ret => R_STR|R_ARRAY },
        preg_replace_callback => { callable => 1, ret => R_STR|R_ARRAY },
        preg_replace_callback_array => { callable => 1, ret => R_STR|R_ARRAY },
        preg_filter => {},
        preg_split => { ret => R_ARRAY },
        preg_quote => {},
        preg_grep => {},
        preg_last_error => {},
);

my %php_funcs_posix = (
        posix_kill => {},
        posix_getpid => {},
        posix_getppid => {},
        posix_getuid => {},
        posix_setuid => {},
        posix_geteuid => {},
        posix_seteuid => {},
        posix_getgid => {},
        posix_setgid => {},
        posix_getegid => {},
        posix_setegid => {},
        posix_getgroups => {},
        posix_getlogin => {},
        posix_getpgrp => {},
        posix_setsid => {},
        posix_setpgid => {},
        posix_getpgid => {},
        posix_getsid => {},
        posix_uname => {},
        posix_times => {},
        posix_ctermid => {},
        posix_ttyname => {},
        posix_isatty => {},
        posix_getcwd => {},
        posix_mkfifo => {},
        posix_mknod => {},
        posix_access => {},
        posix_getgrnam => {},
        posix_getgrgid => {},
        posix_getpwnam => {},
        posix_getpwuid => {},
        posix_getrlimit => {},
        posix_get_last_error => {},
        posix_errno => {},
        posix_strerror => {},
        posix_initgroups => {},
);

my %php_funcs_curl = (
        curl_init => {},
        curl_copy_handle => {},
        curl_version => {},
        curl_setopt => {},
        curl_setopt_array => {},
        curl_exec => {},
        curl_getinfo => {},
        curl_error => {},
        curl_errno => {},
        curl_close => {},
        curl_multi_init => {},
        curl_multi_add_handle => {},
        curl_multi_remove_handle => {},
        curl_multi_select => {},
        curl_multi_exec => {},
        curl_multi_getcontent => {},
        curl_multi_info_read => {},
        curl_multi_close => {},
);

my %php_funcs_zlib = (
        readgzfile => {},
        gzrewind => {},
        gzclose => {},
        gzeof => {},
        gzgetc => {},
        gzgets => {},
        gzgetss => {},
        gzread => {},
        gzopen => {},
        gzpassthru => {},
        gzseek => {},
        gztell => {},
        gzwrite => {},
        gzputs => {},
        gzfile => {},
        gzcompress => {},
        gzuncompress => {},
        gzdeflate => {},
        gzinflate => {},
        gzdecode => {},
        gzencode => {},
        ob_gzhandler => {},
        zlib_get_coding_type => {},
);

my %php_funcs_mysql = (
        mysql_connect => {},
        mysql_pconnect => {},
        mysql_close => {},
        mysql_select_db => {},
        mysql_query => {},
        mysql_unbuffered_query => {},
        mysql_db_query => {},
        mysql_list_dbs => {},
        mysql_list_tables => {},
        mysql_list_fields => {},
        mysql_list_processes => {},
        mysql_error => {},
        mysql_errno => {},
        mysql_affected_rows => {},
        mysql_insert_id => {},
        mysql_result => {},
        mysql_num_rows => {},
        mysql_num_fields => {},
        mysql_fetch_row => {},
        mysql_fetch_array => {},
        mysql_fetch_assoc => {},
        mysql_fetch_object => {},
        mysql_data_seek => {},
        mysql_fetch_lengths => {},
        mysql_fetch_field => {},
        mysql_field_seek => {},
        mysql_free_result => {},
        mysql_field_name => {},
        mysql_field_table => {},
        mysql_field_len => {},
        mysql_field_type => {},
        mysql_field_flags => {},
        mysql_escape_string => {},
        mysql_real_escape_string => {},
        mysql_stat => {},
        mysql_thread_id => {},
        mysql_client_encoding => {},
        mysql_ping => {},
        mysql_get_client_info => {},
        mysql_get_host_info => {},
        mysql_get_proto_info => {},
        mysql_get_server_info => {},
        mysql_info => {},
        mysql_set_charset => {},
        mysql => {},
        mysql_fieldname => {},
        mysql_fieldtable => {},
        mysql_fieldlen => {},
        mysql_fieldtype => {},
        mysql_fieldflags => {},
        mysql_selectdb => {},
        mysql_freeresult => {},
        mysql_numfields => {},
        mysql_numrows => {},
        mysql_listdbs => {},
        mysql_listtables => {},
        mysql_listfields => {},
        mysql_db_name => {},
        mysql_dbname => {},
        mysql_tablename => {},
        mysql_table_name => {},
);

my %php_funcs_hash = (
        hash => { ret => R_STR },
	hash_file => {},
	hash_hmac => {},
	hash_hmac_file => {},
	hash_init => {},
	hash_update => {},
	hash_update_stream => {},
	hash_update_file => {},
	hash_final => {},
	hash_copy => {},
	hash_algos => {},
	hash_hmac_algos => {},
	hash_pbkdf2 => {},
	hash_equals => {},
	hash_hkdf => {},
	mhash_get_block_size => {},
	mhash_get_hash_name => {},
	mhash_keygen_s2k => {},
	mhash_count => {},
	mhash => {},
);

my %php_funcs_libxml = (
	libxml_set_streams_context => {},
	libxml_use_internal_errors => {},
	libxml_get_last_error => {},
	libxml_get_errors => {},
	libxml_clear_errors => {},
	libxml_disable_entity_loader => {},
	libxml_set_external_entity_loader => {},
);

my %php_funcs_filter = (
	filter_has_var => { ret => R_BOOL },
	filter_input => { ret => R_MIXED },
	filter_var => { ret => R_MIXED },
	filter_input_array => { ret => R_MIXED },
	filter_var_array => { ret => R_ARRAY|R_BOOL },
	filter_list => { ret => R_ARRAY },
	filter_id => { ret => R_INT|R_BOOL },
);

my %php_funcs_json = (
	json_encode => { ret => R_STR },
	json_decode => { ret => R_MIXED },
	json_last_error => { ret => R_INT },
	json_last_error_msg => { ret => R_STR },
);

my %php_funcs_spl = (
	class_implements => {},
	class_parents => {},
	class_uses => {},
	spl_autoload => {},
	spl_autoload_call => {},
	spl_autoload_extensions => {},
	spl_autoload_functions => {},
	spl_autoload_register => {},
	spl_autoload_unregister => {},
	spl_classes => {},
	spl_object_hash => {},
	spl_object_id => {},
	iterator_apply => {},
	iterator_count => {},
	iterator_to_array => {},
);

my %php_funcs_session = (
	session_name => { ret => R_STR },
	session_module_name => { ret => R_STR },
	session_save_path => { ret => R_STR },
	session_id => { ret => R_STR },
	session_create_id => { ret => R_STR },
	session_regenerate_id => { ret => R_BOOL },
	session_decode => { ret => R_BOOL },
	session_encode => { ret => R_STR },
	session_destroy => { ret => R_BOOL },
	session_unset => { ret => R_BOOL },
	session_gc => { ret => R_INT },
	session_get_cookie_params => { ret => R_BOOL },
	session_write_close => { ret => R_BOOL },
	session_abort => { ret => R_BOOL },
	session_reset => { ret => R_BOOL },
	session_status => { ret => R_INT },
	session_register_shutdown => { ret => R_VOID },
	session_commit => { ret => R_BOOL },
	session_set_save_handler => { ret => R_BOOL },
	session_cache_limiter => { ret => R_STR },
	session_cache_expire => { ret => R_INT },
	session_set_cookie_params => { ret => R_ARRAY },
	session_start => { ret => R_BOOL },
);

my %php_funcs_pdo = (
	pdo_drivers => {},
);

my %php_funcs_xml = (
	xml_parser_create => {},
	xml_parser_create_ns => {},
	xml_set_object => {},
	xml_set_element_handler => {},
	xml_set_character_data_handler => {},
	xml_set_processing_instruction_handler => {},
	xml_set_default_handler => {},
	xml_set_unparsed_entity_decl_handler => {},
	xml_set_notation_decl_handler => {},
	xml_set_external_entity_ref_handler => {},
	xml_set_start_namespace_decl_handler => {},
	xml_set_end_namespace_decl_handler => {},
	xml_parse => {},
	xml_parse_into_struct => {},
	xml_get_error_code => {},
	xml_error_string => {},
	xml_get_current_line_number => {},
	xml_get_current_column_number => {},
	xml_get_current_byte_index => {},
	xml_parser_free => {},
	xml_parser_set_option => {},
	xml_parser_get_option => {},
);

my %php_funcs_calendar = (
	cal_days_in_month => {},
	cal_from_jd => {},
	cal_info => {},
	cal_to_jd => {},
	easter_date => {},
	easter_days => {},
	frenchtojd => {},
	gregoriantojd => {},
	jddayofweek => {},
	jdmonthname => {},
	jdtofrench => {},
	jdtogregorian => {},
	jdtojewish => {},
	jdtojulian => {},
	jdtounix => {},
	jewishtojd => {},
	juliantojd => {},
	unixtojd => {},
);

my %php_funcs_ctype = (
	ctype_alnum => { ret => R_BOOL },
	ctype_alpha => { ret => R_BOOL },
	ctype_cntrl => { ret => R_BOOL },
	ctype_digit => { ret => R_BOOL },
	ctype_lower => { ret => R_BOOL },
	ctype_graph => { ret => R_BOOL },
	ctype_print => { ret => R_BOOL },
	ctype_punct => { ret => R_BOOL },
	ctype_space => { ret => R_BOOL },
	ctype_upper => { ret => R_BOOL },
	ctype_xdigit => { ret => R_BOOL },
);

my %php_funcs_gettext = (
	textdomain => { ret => R_STR },
	gettext => { ret => R_STR },
	'_' => { ret => R_STR },
	dgettext => { ret => R_STR },
	dcgettext => { ret => R_STR },
	bindtextdomain => { ret => R_STR },
	ngettext => { ret => R_STR},
	dngettext => { ret => R_STR },
	dcngettext => { ret => R_STR },
	bind_textdomain_codeset => { ret => R_STR },
);

my %php_funcs_iconv = (
	iconv_strlen => { ret => R_INT },
	iconv_substr => { ret => R_STR },
	iconv_strpos => { ret => R_INT },
	iconv_strrpos => { ret => R_INT },
	iconv_mime_encode => { ret => R_STR },
	iconv_mime_decode => { ret => R_STR },
	iconv_mime_decode_headers => { ret => R_STR|R_ARRAY },
	iconv => { ret => R_STR },
	iconv_set_encoding => { ret => R_BOOL },
	iconv_get_encoding => { ret => R_STR|R_ARRAY },
	ob_iconv_handler => { callable => 1, ret => R_STR },
);

my %php_funcs_socket = (
	socket_select => {},
	socket_create_listen => {},
	socket_accept => {},
	socket_set_nonblock => {},
	socket_set_block => {},
	socket_listen => {},
	socket_close => {},
	socket_write => {},
	socket_read => { ret => R_STR },
	socket_getsockname => {},
	socket_getpeername => {},
	socket_create => {},
	socket_connect => {},
	socket_strerror => {},
	socket_bind => {},
	socket_recv => {},
	socket_send => {},
	socket_recvfrom => {},
	socket_sendto => {},
	socket_get_option => {},
	socket_getopt => {},
	socket_set_option => {},
	socket_setopt => {},
	socket_create_pair => {},
	socket_shutdown => {},
	socket_last_error => {},
	socket_clear_error => {},
	socket_import_stream => {},
	socket_export_stream => {},
	socket_sendmsg => {},
	socket_recvmsg => {},
	socket_cmsg_space => {},
	socket_addrinfo_lookup => {},
	socket_addrinfo_connect => {},
	socket_addrinfo_bind => {},
	socket_addrinfo_explain => {},
);

my %php_funcs_tokenizer = (
	token_get_all => {},
	token_name => {},
);

# https://developer.wordpress.org/reference/functions/
#
my %php_funcs_wordpress = (
	get_option => { ret => R_MIXED },
	update_option => { ret => R_BOOL },
	add_post_meta => { ret => R_INT },
	get_categories => { ret => R_ARRAY },
	wp_add_post_tags => { ret => R_ARRAY },
	wp_create_category => { ret => R_INT },
	get_posts => { ret => R_MIXED },
	get_post => { ret => R_MIXED },
	wp_insert_post => { ret => R_INT },
	wp_update_post => { ret => R_INT },
	wp_delete_post => { ret => R_MIXED },
	wp_set_post_tags => { ret => R_ARRAY },
	get_post_meta => { ret => R_MIXED },
	add_post_meta => { ret => R_INT },
	update_post_meta => { ret => R_INT },
	delete_post_meta => { ret => R_BOOL },
	get_users => { ret => R_ARRAY },
	get_user_by => { ret => R_MIXED },
	get_userdata => { ret => R_MIXED },
	wp_insert_user => { ret => R_INT },
	wp_update_user => { ret => R_INT },
	wp_delete_user => { ret => R_BOOL },
	get_user_meta => { ret => R_MIXED },
	add_user_meta => { ret => R_INT },
	update_user_meta => { ret => R_INT },
	delete_user_meta => { ret => R_BOOL },
	get_user_setting => { ret => R_MIXED },
	delete_user_setting => { ret => R_BOOL },
	wp_schedule_single_event => { ret => R_BOOL },
	wp_clear_scheduled_hook => { ret => R_INT },
	wp_unschedule_event => { ret => R_BOOL },
	wp_upload_dir => { ret => R_ARRAY },
);

my %php_funcs = (
	Core     => \%php_funcs_core,
	standard => \%php_funcs_standard,
	date     => \%php_funcs_date,
	pcre     => \%php_funcs_pcre,
	posix    => \%php_funcs_posix,
	curl     => \%php_funcs_curl,
	zlib     => \%php_funcs_zlib,
	mysql    => \%php_funcs_mysql,
	hash     => \%php_funcs_hash,
	libxml   => \%php_funcs_libxml,
	filter   => \%php_funcs_filter,
	json     => \%php_funcs_json,
	spl      => \%php_funcs_spl,
	session  => \%php_funcs_session,
	pdo      => \%php_funcs_pdo,
	xml      => \%php_funcs_xml,
	calendar => \%php_funcs_calendar,
	ctype    => \%php_funcs_ctype,
	gettext  => \%php_funcs_gettext,
	iconv    => \%php_funcs_iconv,
	socket   => \%php_funcs_socket,
	tokenizer=> \%php_funcs_tokenizer,
	#wordpress=> \%php_funcs_wordpress,
);

sub get_php_func {
	my ($cmd) = @_;

	$cmd = lc($cmd);

	foreach my $e (keys %php_funcs) {
		if (exists $php_funcs{$e}{$cmd}) {
			my $f = $php_funcs{$e}{$cmd};
			return $f;
		}
	}
	return
}

sub func_may_call_callbacks {
	my ($cmd) = @_;

	$cmd = lc($cmd);

	if ($cmd =~ /^(eval|include|include_once|require|require_once)$/) {
		return 1;
	}
	my $f = get_php_func($cmd);
	if (defined $f) {
		if (exists $f->{callable}) {
			return 1;
		}
		return 0;
	}
	return 1;
}

sub func_may_return_string {
	my ($cmd) = @_;

	$cmd = lc($cmd);

	if ($cmd =~ /^(include|include_once|require|require_once)$/) {
		return 0;
	}
	my $f = get_php_func($cmd);
	if (defined $f) {
		if (exists $f->{ret}) {
			unless ($f->{ret} & (R_STR|R_MIXED)) {
				return 0;
			}
			if ($f->{ret} & R_FIX) {
				return 0;
			}
		}
		return 1;
	}
	return 1;
}

sub cmd_base64_decode {
	my ($ctx, $cmd, $args) = @_;
	my $parser = $ctx->{parser};

	if (scalar @$args >= 1) {
		my $s = $parser->get_strval($$args[0]);
		my $php50_compat;
		my $strict = 0;
		if (scalar @$args > 1) {
			$strict = $parser->get_strval($$args[1]);
		}
		if (defined $s) {
			# older php-versions (< php5.1) treated blanks in base64 string as '+':
			# https://php.net/manual/en/function.base64-decode.php
			#
			# perl ignores any character not part of the 65-character base64 subset.
			# https://perldoc.perl.org/MIME::Base64
			#
			if ($php50_compat) {
				$s =~ s/ /+/g; # incompatible with ignore-rule
			}
			if ($strict && !($s =~ /^[A-Za-z0-9\/+]*=*$/)) {
				$ctx->{warn}->($ctx, 'cmd', $cmd, "$$args[0] contains non-strict chars");
			}
			my $decoded;
			{
				# suppress decode_base64() warnings (premature end of data, etc.)
				local $^W = 0;
				$decoded = decode_base64($s);
			}
			if (defined $decoded) {
				#$decoded = decode_input($decoded); # might convert wide strings back to internal perl utf-8 encoding
				#$ctx->{log}->($ctx, 'cmd', $cmd, "%d:[%s]->%d:[%s]", length($s), $parser->shortstr($s,40), length($decoded), $parser->shortstr($decoded,40)) if $ctx->{log};
				return $parser->setstr($decoded);
			}
		}
	}
	return;
}

sub cmd_base64_encode {
	my ($ctx, $cmd, $args) = @_;
	my $parser = $ctx->{parser};

	if (scalar @$args == 1) {
		my $s = $parser->get_strval($$args[0]);
		if (defined $s) {
			# might convert from internal perl wide string representation to utf-8 stream
			# see: https://perldoc.perl.org/MIME::Base64
			#
			#my $bytestr = encode('utf-8', $s);
			#my $encoded = encode_base64($bytestr,'');
			my $encoded = encode_base64($s,'');
			if (defined $encoded) {
				$ctx->{log}->($ctx, 'cmd', $cmd, "%d:[%s]->%d:[%s]", length($s), $parser->shortstr($s,40), length($encoded), $parser->shortstr($encoded,40)) if $ctx->{log};
				return $parser->setstr($encoded);
			}
		}
	}
	return;
}

sub get_refvar_val {
	my ($ctx, $var) = @_;
	my $parser = $ctx->{parser};

	unless ($ctx->{infunction} && !$ctx->{incall}) {
		if (is_variable($var)) {
			my $val = $ctx->getvar($var, 1);
			return (1, $val); # valid
		} elsif ($var =~ /^(\#elem\d+)$/) {
			my ($v, $i) = @{$parser->{strmap}{$var}};
			my ($basevar, $has_index, $idxstr) = $ctx->resolve_variable($var, 0);
			if ($has_index) {
				my $basestr = $ctx->exec_statement($basevar, 0);
				if (defined $basestr && is_array($basestr) && defined $idxstr) {
					$idxstr = $parser->setstr('') if is_null($idxstr); # null maps to '' array index
					my $arr = $parser->{strmap}{$basestr};
					my $val = $arr->get($idxstr);
					return (1, $val); # valid
				}
			}
		}
	}
	return;
}

sub set_refvar_val {
	my ($ctx, $var, $val) = @_;
	my $parser = $ctx->{parser};

	if (is_variable($var)) {
		$ctx->setvar($var, $val, 1);
	} elsif ($var =~ /^(\#elem\d+)$/) {
		my $sub = $parser->setexpr('=', $var, $val);
		my $had_assigns = $ctx->have_assignments();
		my $k = $ctx->exec_statement($sub);
		if (!$had_assigns) {
			# remove any pending assignments, to avoid variable
			# insertion for the 'sub'-assignmenmt.
			# The full array assignment is inserted after the loop
			#
			$ctx->discard_pending_assignments();
		}
	}
	return;
}

sub exec_cmd {
	my ($ctx, $cmd, $args) = @_;
	my $parser = $ctx->{parser};
	my $res;
	my $to_num = 0;

	# some dynamic function names are created from mixed-style strings
	# see: https://www.php.net/manual/en/functions.user-defined.php
	#      function names are case-insensitive for the ASCII characters A to Z.
	#
	$cmd = lc($cmd);

	$ctx->{log}->($ctx, 'cmd', $cmd, "args (%s)", join(', ', @$args)) if $ctx->{log};

	my $f = get_php_func($cmd);

	if (defined $f && exists $f->{cmd}) {
		my $k = &{$f->{cmd}}(@_);
		return $k;
	}

	if ($cmd eq 'unescape') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = $s;
				$res =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/ge;
			}
		}
	} elsif ($cmd eq 'str_rot13') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = $s;
				$res =~ tr/A-Za-z/N-ZA-Mn-za-m/;
			}
		}
	} elsif ($cmd eq 'strrev') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = reverse $s;
			}
		}
	} elsif ($cmd eq 'strtoupper') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = uc($s);
			}
		}
	} elsif ($cmd eq 'strtolower') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = lc($s);
			}
		}
	} elsif ($cmd eq 'ucfirst') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = ucfirst($s);
			}
		}
	} elsif ($cmd eq 'lcfirst') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = lcfirst($s);
			}
		}
	} elsif ($cmd eq 'dirname') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = dirname($s);
			}
		}
	} elsif ($cmd eq 'basename') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = basename($s);
			}
		}
	} elsif ($cmd eq 'strlen') {
		if (scalar @$args == 1) {
			my $val = $$args[0];
			if (is_array($val)) {
				$ctx->{warn}->($ctx, 'cmd', $cmd, "len of array $val taken -> 0");
				$res = 0;
				$to_num = 1;
			} elsif (is_null($val)) {
				$res = 0;
				$to_num = 1;
			} elsif (is_strval($val)) {
				my $s = $parser->get_strval($val);
				if (defined $s) {
					$res = length($s);
					$to_num = 1;
				}
			}
		}
	} elsif ($cmd eq 'chr') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = chr(int($s) & 0xff);
			}
		}
	} elsif ($cmd eq 'ord') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = ord($s);
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'hexdec') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = hex($s);
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'octdec') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = oct($s);
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'bindec') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = unpack('N', pack('B32', substr('0' x 32 . $s, -32)));
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'dechex') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = sprintf("%x", $s);
			}
		}
	} elsif ($cmd eq 'octhex') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = sprintf("%o", $s);
			}
		}
	} elsif ($cmd eq 'binhex') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = sprintf("%b", $s);
			}
		}
	} elsif ($cmd eq 'bin2hex') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = unpack('H*', $s);
			}
		}
	} elsif ($cmd eq 'hex2bin') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = pack('H*', $s);
			}
		}
	} elsif ($cmd eq 'floor') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$s = 0 if ($s eq '');
				$res = int($s);
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'ceil') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$s = 0 if ($s eq '');
				$res = int($s + 0.99);
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'intval') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$s = 0 if ($s eq '');
				$res = int(PHP::Decode::Op::to_num($s));
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'strval') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = "$s";
			}
		}
	} elsif ($cmd eq 'boolval') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$s = 0 if ($s eq '');
				if ($s eq '0') {
					$res = 0;
				} else {
					$res = 1;
				}
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'floatval') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$s = 0 if ($s eq '');
				$res = $s + 0;
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'pow') {
		if (scalar @$args == 2) {
			my $s = $parser->get_strval($$args[0]);
			my $e = $parser->get_strval($$args[1]);
			if (defined $s && defined $e) {
				$s = 0 if ($s eq '');
				$e = 0 if ($e eq '');
				$res = $s ** $e;
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'gzinflate') {
		if (scalar @$args >= 1) {
			my $s = $parser->get_strval($$args[0]);
			my $maxlen = '0';
			if (scalar @$args > 1) {
				$maxlen = $parser->get_strval($$args[1]);
				$maxlen = 0 if ($maxlen eq '');
			}
			if (defined $s && (defined $maxlen && ($maxlen eq '0'))) {
				my ($i, $istatus) = Compress::Zlib::inflateInit(-WindowBits => -(MAX_WBITS));
				my ($output, $ostatus) = $i->inflate($s);
				if (defined $output) {
					$res = $output;
				}
			}
		}
	} elsif ($cmd eq 'gzdecode') {
		if (scalar @$args >= 1) {
			my $s = $parser->get_strval($$args[0]);
			my $maxlen = '0';
			if (scalar @$args > 1) {
				$maxlen = $parser->get_strval($$args[1]);
				$maxlen = 0 if ($maxlen eq '');
			}
			if (defined $s && (defined $maxlen && ($maxlen eq '0'))) {
				# http://www.faqs.org/rfcs/rfc1952.html
				#
				if (substr($s, 0, 3) eq "\x1f\x8b\x08") {
					my $off = 10;
					my $flag = ord(substr($s, 3, 1));
					if ($flag > 0 ) {
						if ($flag & 4) {
							my ($xlen) = unpack('v', substr($s, $off, 2));
							$off = $off + 2 + $xlen;
						}
						if ($flag & 8) {
							$off = index($s, "\0", $off) + 1;
						}
						if ($flag & 16) {
							$off = index($s, "\0", $off) + 1;
						}
						if ($flag & 2) {
							$off = $off + 2;
						}
					}
					my $b = substr($s, $off, -8);

					my ($i, $istatus) = Compress::Zlib::inflateInit(-WindowBits => -(MAX_WBITS));
					my ($output, $ostatus) = $i->inflate($b);
					if (defined $output) {
						$res = $output;
					}
				}
			}
		}
	} elsif ($cmd eq 'gzuncompress') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = Compress::Zlib::uncompress($s);
			}
		}
	} elsif ($cmd eq 'crc32') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = mycrc32b($s);
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'hash') {
		if (scalar @$args >= 2) {
			my $a = $parser->get_strval($$args[0]);
			my $s = $parser->get_strval($$args[1]);
			my $raw = '0';
			if (scalar @$args > 2) {
				$raw = $parser->get_strval($$args[2]);
			}
			if (defined $a && defined $s && defined $raw) {
				my $output;
				if ($a eq 'crc32') {
					$output = pack('N', mycrc32a($s));
				} elsif ($a eq 'crc32b') {
					$output = pack('N', mycrc32b($s));
				} elsif ($a eq 'sha1') {
					$output = sha1($s);
				} elsif ($a eq 'md5') {
					$output = md5($s);
				}
				if (defined $output) {
					if ($raw eq '0') {
						#$res = sprintf("%x", $output);
						$res = unpack('H*', ''.$output);
					} else {
						$res = $output;
					}
				}
			}
		}
	} elsif ($cmd eq 'rawurldecode') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				# no '+'->' ' conversion here
				$res = URI::Escape::uri_unescape($s);
			}
		}
	} elsif ($cmd eq 'rawurlencode') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				# no ' '->'+' conversion here
				# default safe RFC3986 characters are: "A-Za-z0-9\-\._~"
				$res = URI::Escape::uri_escape($s);
			}
		}
	} elsif ($cmd eq 'urldecode') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$s =~ s/\+/ /g;
				$res = URI::Escape::uri_unescape($s);
			}
		}
	} elsif ($cmd eq 'urlencode') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				# default safe characters are here: "A-Za-z0-9\-\._"
				# see: php/ext/standard/url.c
				$res = URI::Escape::uri_escape($s, "^A-Za-z0-9\-\._ ");
				$res =~ s/ /\+/g;
			}
		}
	} elsif ($cmd eq 'trim') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = $s;
				$res =~ s/^\s+|\s+$//g;
			}
		}
	} elsif ($cmd eq 'ltrim') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = $s;
				$res =~ s/^\s+//;
			}
		}
	} elsif (($cmd eq 'rtrim') || ($cmd eq 'chop')) {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = $s;
				$res =~ s/\s+$//;
			}
		}
	} elsif ($cmd eq 'stripslashes') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = $s;
				$res =~ s/\\(\'|\"|\\)/$1/g;
			}
		}
	} elsif ($cmd eq 'stripcslashes') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = stripcslashes($s);
			}
		}
	} elsif ($cmd eq 'strpos') {
		if (scalar @$args >= 2) {
			my $s = $parser->get_strval($$args[0]);
			my $p = $parser->get_strval($$args[1]);
			my $off = 0;
			if (scalar @$args == 3) {
				$off = $parser->get_strval($$args[2]);
				$off = 0 if ($off eq '');
			}
			if (defined $s && defined $p) {
				$res = index($s, $p, $off);
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'substr') {
		if (scalar @$args >= 2) {
			my $s = $parser->get_strval($$args[0]);
			my $off = $parser->get_strval($$args[1]);
			if (defined $s && defined $off) {
				$off = 0 if ($off eq '');
				if (scalar @$args == 3) {
					my $len = $parser->get_strval($$args[2]);
					if (defined $len) {
						$len = 0 if ($len eq '');
						$res = substr($s, $off, $len);
					}
				} else {
					$res = substr($s, $off);
				}
			}
		}
	} elsif ($cmd eq 'substr_count') {
		if (scalar @$args >= 2) {
			my $s = $parser->get_strval($$args[0]);
			my $p = $parser->get_strval($$args[1]);
			if (defined $s) {
				my $sub = $s;
				if (scalar @$args > 2) {
					my $off = $parser->get_strval($$args[2]);
					if (scalar @$args > 3) {
						my $len = $parser->get_strval($$args[3]);
						$sub = substr($s, $off, $len);
					} else {
						$sub = substr($s, $off);
					}
				}
				$res = () = $sub =~ /\Q$p\E/g;
				$to_num=1;
			}
		}
	} elsif ($cmd eq 'strstr') {
		if (scalar @$args >= 2) {
			my $s = $parser->get_strval($$args[0]);
			my $p = $parser->get_strval($$args[1]);
			if (defined $s && defined $p) {
				my $off = index($s, $p);
				if (defined $off) {
					my $before = 0;
					if (scalar @$args > 2) {
						$before = $parser->get_strval($$args[2]);
					}
					if ($before) {
						$res = substr($s, 0, $off);
					} else {
						$res = substr($s, $off);
					}
				}
			}
		}
	} elsif ($cmd eq 'strtr') {
		# https://www.php.net/manual/en/function.strtr.php
		#
		# if from and to have different lengths, the extra characters in
		# the longer of the two are ignored. The length of string will be
		# the same as the return value's.
		#
		if (scalar @$args == 3) {
			my $str = $parser->get_strval($$args[0]);
			my $from = $parser->get_strval($$args[1]);
			my $to = $parser->get_strval($$args[2]);
			my $org = $str;

			if (defined $str && defined $from && defined $to) {
				# for from > to perl would skip characters missing in 'to',
				# for to > from perl would substitue the last char with the full suffix.
				#
				if (length($from) > length($to)) {
					$to .= substr($from, length($from)-1);
				} elsif (length($to) > length($from)) {
					$from .= substr($to, length($to)-1);
				}
				# tr needs eval to use variables
				#
				eval "\$str =~ tr/\Q$from\E/\Q$to\E/;";
				unless ($@) {
					$ctx->{log}->($ctx, 'cmd', $cmd, "[%s]->[%s] [%s]->[%s]", $parser->shortstr($from,40), $parser->shortstr($to,40), $parser->shortstr($org,40), $parser->shortstr($str,40)) if $ctx->{log};
 					$res = $str;
				}
			}
		}
	} elsif ($cmd eq 'strcmp') {
		# https://php.net/manual/en/function.strcmp.php
		# TODO: perl cmp does just return -1,0,1
		#
		if (scalar @$args == 2) {
			my $s = $parser->get_strval($$args[0]);
			my $d = $parser->get_strval($$args[1]);
			if (defined $s && defined $d) {
				$res = $s cmp $d;
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'strncmp') {
		# https://php.net/manual/en/function.strncmp.php
		# TODO: perl cmp does just return -1,0,1
		#
		if (scalar @$args == 3) {
			my $s = $parser->get_strval($$args[0]);
			my $d = $parser->get_strval($$args[1]);
			my $len = $parser->get_strval($$args[2]);
			if (defined $s && defined $d && defined $len) {
				$len = 0 if ($len eq '');
				$res = substr($s,0,$len) cmp substr($d,0,$len);
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'strcasecmp') {
		# https://php.net/manual/en/function.strcasecmp.php
		# TODO: perl cmp does just return -1,0,1
		#
		if (scalar @$args == 2) {
			my $s = $parser->get_strval($$args[0]);
			my $d = $parser->get_strval($$args[1]);
			if (defined $s && defined $d) {
				$res = lc($s) cmp lc($d);
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'strncasecmp') {
		# https://php.net/manual/en/function.strncasecmp.php
		# TODO: perl cmp does just return -1,0,1
		#
		if (scalar @$args == 3) {
			my $s = $parser->get_strval($$args[0]);
			my $d = $parser->get_strval($$args[1]);
			my $len = $parser->get_strval($$args[2]);
			if (defined $s && defined $d && defined $len) {
				$len = 0 if ($len eq '');
				$res = lc(substr($s,0,$len)) cmp lc(substr($d,0,$len));
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'str_repeat') {
		# https://php.net/manual/en/function.str-repeat.php
		#
		if (scalar @$args == 2) {
			my $s = $parser->get_strval($$args[0]);
			my $m = $parser->get_strval($$args[1]);

			if (defined $s && defined $m) {
				$m = 0 if ($m eq '');
				if ($m > $ctx->{max_repeat}) { # limit maxsize
					$ctx->{warn}->($ctx, 'cmd', $cmd, "$s x $m memory exhaution");
				} else {
					$res = $s x $m;
				}
			}
		}
	} elsif ($cmd eq 'str_replace') {
		if (scalar @$args >= 3) {
			my $pattern = $$args[0];
			my $replacement = $$args[1];
			my $subject = $$args[2];
			my $limit = -1;
			if (scalar @$args == 4) {
				$limit = $parser->get_strval($$args[3]);
				$limit = 0 if ($limit eq '');
			}
			if (defined $pattern && defined $replacement && defined $subject) {
				if (is_array($subject)) {
					my $arr = $parser->{strmap}{$subject};
					my $keys = $arr->get_keys();
					my $newarr = $parser->newarr();
	
					foreach my $k (@$keys) {
						my $val = $arr->val($k);
						my ($r, $cnt) = preg_replace_subject($ctx, $pattern, $replacement, $val, 'str', $limit);
						$newarr->set(undef, $r);
						if ($limit != -1) {
							$limit -= $cnt;
						}
					}
					return $newarr->{name};
				} elsif (is_strval($subject)) {
					my ($r, $cnt) = preg_replace_subject($ctx, $pattern, $replacement, $subject, 'str', $limit);
					return $r;
				} elsif ($subject eq '#null') {
					my ($r, $cnt) = preg_replace_subject($ctx, $pattern, $replacement, $subject, 'str', $limit);
					return $r;
				}
			}
		}
	} elsif ($cmd eq 'ereg_replace') {
		if (scalar @$args == 3) {
			my $pattern = $parser->get_strval($$args[0]);
			my $replacement = $parser->get_strval($$args[1]);
			my $str = $parser->get_strval($$args[2]);

			# todo: use posix regex here
			#
			if (defined $pattern && defined $replacement && defined $str) {
				$res = $str;
				$res =~ s/\Q$pattern\E/$replacement/g;
				$ctx->{log}->($ctx, 'cmd', $cmd, "[%s]->[%s] %s -> %s", $parser->shortstr($pattern,40), $parser->shortstr($replacement,40), $parser->shortstr($str,40), $parser->shortstr($res,40)) if $ctx->{log};
			}
		}
	} elsif ($cmd eq 'preg_replace') {
		if (scalar @$args >= 3) {
			my $pattern = $$args[0];
			my $replacement = $$args[1];
			my $subject = $$args[2];
			my $limit = -1;
			if (scalar @$args == 4) {
				$limit = $parser->get_strval($$args[3]);
				$limit = 0 if ($limit eq '');
			}

			# preg_replace uses pattern '/xxx/' instead of 'xxx'
			#
			if (defined $pattern && defined $replacement && defined $subject) {
				if (is_array($subject)) {
					my $arr = $parser->{strmap}{$subject};
					my $keys = $arr->get_keys();
					my $newarr = $parser->newarr();
	
					foreach my $k (@$keys) {
						my $val = $arr->val($k);
						my ($r, $cnt) = preg_replace_subject($ctx, $pattern, $replacement, $val, 'preg', $limit);
						$newarr->set(undef, $r);
						if ($limit != -1) {
							$limit -= $cnt;
						}
					}
					return $newarr->{name};
				} elsif (is_strval($subject)) {
					my ($r, $cnt) = preg_replace_subject($ctx, $pattern, $replacement, $subject, 'preg', $limit);
					return $r;
				} elsif ($subject eq '#null') {
					my ($r, $cnt) = preg_replace_subject($ctx, $pattern, $replacement, $subject, 'preg', $limit);
					return $r;
				}
			}
		}
	} elsif ($cmd eq 'preg_quote') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				# escape: . \ + * ? [ ^ ] $ ( ) { } = ! < > | : -
				$s =~ s/%([\.\\\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:\-])/\\$1/ge;
				$res = $s;
			}
		}
	} elsif ($cmd eq 'md5') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = md5_hex($s);
			}
		}
	} elsif ($cmd eq 'sha1') {
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = sha1_hex($s);
			}
		}
	} elsif ($cmd eq 'levenshtein') {
		if (scalar @$args == 2) {
			my $s1 = $parser->get_strval($$args[0]);
			my $s2 = $parser->get_strval($$args[1]);
			if (defined $s1 && defined $s2) {
				$res = levenshtein($s1, $2);
			}
		}
	} elsif ($cmd eq 'str_split') {
		if (scalar @$args >= 1) {
			my $s1 = $parser->get_strval($$args[0]);
			my $s2 = '1';
			if (scalar @$args == 2) {
				$s2 = $parser->get_strval($$args[1]);
			}
			if (defined $s1 && defined $s2) {
				my $arr = $parser->newarr();
				# don't include delimter in split result
				my @parts = $s1 =~ /.{1,$s2}/g;

				foreach my $p (@parts) {
					$ctx->{log}->($ctx, 'cmd', $cmd, "[$s2] part: $p") if $ctx->{log};
					my $k = $parser->setstr($p);
					$arr->set(undef, $k);
				}
				return $arr->{name};
			}
		}
	} elsif ($cmd eq 'preg_split') {
		if (scalar @$args >= 2) {
			my $s1 = $parser->get_strval($$args[0]);
			my $s2 = $parser->get_strval($$args[1]);
			my $limit = '-1';
			my $flags = 0;
			if (scalar @$args > 2) {
				$limit = $parser->get_strval($$args[2]);
				$limit = 0 if ($limit eq '');
			}
			if (scalar @$args > 3) {
				$flags = $parser->get_strval($$args[3]);
			}
			if (defined $s1 && defined $s2 && ($flags == 0)) {
				my $arr = $parser->newarr();
				my ($pattern) = $s1 =~ /^\/(.*)\/$/;
				my @parts = split /$pattern/, $s2, $limit;

				foreach my $p (@parts) {
					$ctx->{log}->($ctx, 'cmd', $cmd, "[$s2] '$s1' part: $p") if $ctx->{log};
					my $k = $parser->setstr($p);
					$arr->set(undef, $k);
				}
				return $arr->{name};
			}
		}
	} elsif ($cmd eq 'explode') {
		if (scalar @$args >= 2) {
			my $s1 = $parser->get_strval($$args[0]);
			my $s2 = $parser->get_strval($$args[1]);
			my $limit = '-1';
			if (scalar @$args == 3) {
				$limit = $parser->get_strval($$args[2]);
			}
			if (defined $s1 && defined $s2) {
				my $arr = $parser->newarr();
				my @parts = split /\Q$s1\E/, $s2, $limit;

				foreach my $p (@parts) {
					$ctx->{log}->($ctx, 'cmd', $cmd, "[$s2] '$s1': part: $p") if $ctx->{log};
					my $k = $parser->setstr($p);
					$arr->set(undef, $k);
				}
				return $arr->{name};
			}
		}
	} elsif (($cmd eq 'implode') || ($cmd eq 'join')) {
		# https://php.net/manual/en/function.implode.php
		# 'join' is an alias for implode()
		#
		if (scalar @$args >= 1) {
			my $basestr = $$args[0];
			my $glue = '';

			if (scalar @$args == 2) {
				if (is_array($$args[0])) {
					$ctx->{warn}->($ctx, 'cmd', $cmd, "reversed arguments $$args[0] $$args[1]");
					$basestr = $$args[0];
					$glue = $parser->get_strval($$args[1]);
				} else {
					$glue = $parser->get_strval($$args[0]);
					$basestr = $$args[1];
				}
			}
			if (defined $glue && defined $basestr) {
				if (is_array($basestr)) {
					my $arr = $parser->{strmap}{$basestr};
					my $keys = $arr->get_keys();

					my @vals = ();
					my $failed = 0;
					foreach my $k (@$keys) {
						my $val = $arr->val($k);
						if (is_strval($val)) {
							push (@vals, $parser->{strmap}->{$val});
						} else {
							my $v = $ctx->exec_statement($val);
							if (is_strval($v)) {
								push (@vals, $parser->{strmap}->{$v});
							} else {
								$ctx->{warn}->($ctx, 'cmd', $cmd, "$basestr: key $k not str ($val -> $v)");
								$failed = 1;
								last;
							}
						}
					}
					$res = join($glue, @vals) unless ($failed);
				}
			}
		}
	} elsif ($cmd eq 'range') {
		# https://www.php.net/manual/en/function.range.php
		#
		if (scalar @$args >= 2) {
			my $s1 = $parser->get_strval($$args[0]);
			my $s2 = $parser->get_strval($$args[1]);
			my $step = '1';
			if (scalar @$args == 3) {
				$step = $parser->get_strval($$args[2]);
				$step = 0 if ($step eq '');
			}
			if (defined $s1 && defined $s2) {
				my $arr = $parser->newarr();
				my @parts;

				# https://perldoc.perl.org/perlop#Range-Operators
				# If the initial value specified isn't part of a magical increment sequence
				# (that is, a non-empty string matching /^[a-zA-Z]*[0-9]*\z/), only the
				# initial value will be returned.
				if (($s1 =~ /^[a-zA-Z0-9]*$/) && ($s2 =~ /^[a-zA-Z0-9]*$/)) {
					@parts = ($s1 .. $s2);
				} else {
					@parts = map { chr } (ord($s1) .. ord($s2));
				}

				foreach my $p (@parts) {
					$ctx->{log}->($ctx, 'cmd', $cmd, "['$s1', '$s2']: part: $p") if $ctx->{log};
					my $k = $parser->setstr($p);
					$arr->set(undef, $k);
				}
				return $arr->{name};
			}
		}
	} elsif (($cmd eq 'count') || ($cmd eq 'sizeof')) {
		# https://php.net/manual/en/function.count.php
		# todo: support arg2: COUNT_NORMAL/COUNT_RECURSIVE
		#
		if (scalar @$args == 1) {
			my $basestr = $$args[0];
			if (defined $basestr) {
				if (is_array($basestr)) {
					my $arr = $parser->{strmap}{$basestr};
					my $keys = $arr->get_keys();
					$res = scalar @$keys;
					$to_num = 1;
				}
			}
		}
	} elsif (($cmd eq 'htmlspecialchars') || ($cmd eq 'htmlentities')) {
		if (scalar @$args >= 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = HTML::Entities::encode_entities($s);
			}
		}
	} elsif (($cmd eq 'htmlspecialchars_decode') || ($cmd eq 'html_entity_decode')) {
		# just support 1 argument version without flags & charset for now
		# 
		if (scalar @$args == 1) {
			my $s = $parser->get_strval($$args[0]);
			if (defined $s) {
				$res = HTML::Entities::decode_entities($s);
			}
		}
	} elsif ($cmd eq 'pack') {
		if (scalar @$args >= 1) {
			my $s = $parser->get_strval($$args[0]);
			my @param = ();
			my $i;

			if (defined $s) {
				for ($i=1; $i < scalar @$args; $i++) {
					my $p = $parser->get_strval($args->[$i]);
					last unless (defined $p);
					push(@param, $p);
				}
				if ($i == scalar @$args) {
					eval { $res = pack($s, @param); };
					if ($@) {
						$ctx->{warn}->($ctx, 'cmd', $cmd, "bad param $s");
					}
				}
			}
		}
	} elsif ($cmd eq 'unpack') {
		if (scalar @$args == 2) {
			my $s = $parser->get_strval($$args[0]);
			my $d = $parser->get_strval($$args[1]);

			if (defined $s && defined $d) {
				my @values;
				eval { @values = unpack($s, $d); };
				if ($@) {
					$ctx->{warn}->($ctx, 'cmd', $cmd, "bad param $s");
				}

				my $arr = $parser->newarr();

				foreach my $p (@values) {
					$ctx->{log}->($ctx, 'cmd', $cmd, "[$s]: $p") if $ctx->{log};
					my $k = $parser->setstr($p);
					$arr->set(undef, $k);
				}
				return $arr->{name};
			}
		}
	} elsif ($cmd eq 'sprintf') {
		if (scalar @$args >= 1) {
			my $s = $parser->get_strval($$args[0]);
			my @param = ();
			my $i;

			if (defined $s) {
				for ($i=1; $i < scalar @$args; $i++) {
					my $p = $parser->get_strval($args->[$i]);
					last unless (defined $p);
					push(@param, $p);
				}
				if ($i == scalar @$args) {
					eval { $res = sprintf($s, @param); };
					if ($@) {
						$ctx->{warn}->($ctx, 'cmd', $cmd, "bad param $s");
					}
				}
			}
		}
	} elsif ($cmd eq 'array_push') {
		# https://php.net/manual/en/function.array-push.php
		#
		if (scalar @$args >= 1) {
			my $var = $$args[0]; # ref var
			my ($is_valid, $val) = get_refvar_val($ctx, $var);

			if ($is_valid) {
				if (!defined $val || is_null($val) || is_array($val)) {
					my $arr;
					if (defined $val && is_array($val)) {
						$arr = $parser->{strmap}{$val};
						$arr = $arr->copy(); # recursive copy
					} else {
						$arr = $parser->newarr();
					}
					for (my $i=1; $i < scalar @$args; $i++) {
						$arr->set(undef, $$args[$i]);
					}
					set_refvar_val($ctx, $var, $arr->{name});
					my $keys = $arr->get_keys();

					$res = scalar keys @$keys; # returns elem count
					$to_num = 1;
				}
			}
		}
	} elsif ($cmd eq 'array_pop') {
		# https://php.net/manual/en/function.array-pop.php
		#
		if (scalar @$args == 1) {
			my $var = $$args[0]; # ref var
			my ($is_valid, $val) = get_refvar_val($ctx, $var);

			if ($is_valid) {
				if (!defined $val || is_array($val)) {
					if (defined $val && is_array($val)) {
						my $arr = $parser->{strmap}{$val};
						my $keys = $arr->get_keys();
						if (scalar @$keys == 0) {
							$res = '#null';
						} else {
							my $k = pop @$keys;
							$res = $arr->val($k);
							$arr = $arr->copy($keys);
							set_refvar_val($ctx, $var, $arr->{name});
						}
					} else {
						$res = '#null';
					}
					return $res;
				}
			}
		}
	} elsif ($cmd eq 'array_unshift') {
		# https://php.net/manual/en/function.array-unshift.php
		#
		if (scalar @$args >= 1) {
			my $var = $$args[0]; # ref var
			my ($is_valid, $val) = get_refvar_val($ctx, $var);

			if ($is_valid) {
				if (!defined $val || is_null($val) || is_array($val)) {
					my $newarr = $parser->newarr();

					for (my $i=1; $i < scalar @$args; $i++) {
						$newarr->set(undef, $$args[$i]); # prepend new elems
					}
					if (defined $val && is_array($val)) {
						my $arr = $parser->{strmap}{$val};
						my $keys = $arr->get_keys();

						foreach my $k (@$keys) {
							my $oldval = $arr->val($k);
							if (is_int_index($k)) {
								$newarr->set(undef, $oldval); # renumber int key
							} else {
								$newarr->set($k, $oldval);
							}
						}
					}
					set_refvar_val($ctx, $var, $newarr->{name});

					my $keys = $newarr->get_keys();
					$res = scalar keys @$keys; # returns elem count
					$to_num = 1;
				}
			}
		}
	} elsif ($cmd eq 'array_shift') {
		# https://php.net/manual/en/function.array-shift.php
		#
		if (scalar @$args == 1) {
			my $var = $$args[0]; # ref var
			my ($is_valid, $val) = get_refvar_val($ctx, $var);

			if ($is_valid) {
				if (!defined $val || is_array($val)) {
					if (defined $val && is_array($val)) {
						my $arr = $parser->{strmap}{$val};
						my $keys = $arr->get_keys();
						if (scalar @$keys == 0) {
							$res = '#null';
						} else {
							my $k = shift @$keys;
							$res = $arr->val($k);

							my $newarr = $parser->newarr();
							foreach my $k (@$keys) {
								my $oldval = $arr->val($k);
								if (is_int_index($k)) {
									$newarr->set(undef, $oldval); # renumber int key
								} else {
									$newarr->set($k, $oldval);
								}
							}
							set_refvar_val($ctx, $var, $newarr->{name});
						}
					} else {
					}
				} else {
					$res = '#null';
				}
				return $res;
			}
		}
	} elsif ($cmd eq 'each') {
		# https://php.net/manual/en/function.each.php
		#
		if (scalar @$args == 1) {
			my $var = $$args[0]; # ref var
			my ($is_valid, $val) = get_refvar_val($ctx, $var);

			if ($is_valid) {
				if (defined $val && is_array($val)) {
					my $arr = $parser->{strmap}{$val};
					my $pos = $arr->get_pos();
					my $keys = $arr->get_keys();
					if ($pos >= scalar @$keys) {
						$res = 0;
						$to_num = 1;
					} else {
						my $k = $keys->[$pos];
						my $v = $arr->val($k);
						my $newarr = $parser->newarr();
						if (is_int_index($k)) {
							$k = $parser->setnum($k);
						}
						$newarr->set(undef, $k);
						$newarr->set(undef, $v);
						$arr->set_pos($pos+1);
						return $newarr->{name};
					}
				} else {
					$res = 0;
					$to_num = 1;
				}
			}
		}
	} elsif ($cmd eq 'reset') {
		# https://php.net/manual/en/function.reset.php
		#
		if (scalar @$args == 1) {
			my $var = $$args[0]; # ref var
			my ($is_valid, $val) = get_refvar_val($ctx, $var);

			if ($is_valid) {
				if (defined $val && is_array($val)) {
					my $arr = $parser->{strmap}{$val};
					my $keys = $arr->get_keys();
					$arr->set_pos(0);
					if (scalar @$keys == 0) {
						$res = 0;
						$to_num = 1;
					} else {
						my $k = shift @$keys;
						$res = $arr->val($k);
						return $res;
					}
				} else {
					$res = 0;
					$to_num = 1;
				}
			}
		}
	} elsif ($cmd eq 'next') {
		# https://php.net/manual/en/function.next.php
		#
		if (scalar @$args == 1) {
			my $var = $$args[0]; # ref var
			my ($is_valid, $val) = get_refvar_val($ctx, $var);

			if ($is_valid) {
				if (defined $val && is_array($val)) {
					my $arr = $parser->{strmap}{$val};
					my $pos = $arr->get_pos();
					my $keys = $arr->get_keys();
					if (($pos+1) >= scalar @$keys) {
						$res = 0;
						$to_num = 1;
					} else {
						my $k = $keys->[$pos+1];
						$res = $arr->val($k);
						$arr->set_pos($pos+1);
						return $res;
					}
				} else {
					$res = 0;
					$to_num = 1;
				}
			}
		}
	} elsif ($cmd eq 'prev') {
		# https://php.net/manual/en/function.prev.php
		#
		if (scalar @$args == 1) {
			my $var = $$args[0]; # ref var
			my ($is_valid, $val) = get_refvar_val($ctx, $var);

			if ($is_valid) {
				if (defined $val && is_array($val)) {
					my $arr = $parser->{strmap}{$val};
					my $pos = $arr->get_pos();
					my $keys = $arr->get_keys();
					if (($pos == 0) || (scalar @$keys == 0)) {
						$res = 0;
						$to_num = 1;
					} else {
						my $k = $keys->[$pos-1];
						$res = $arr->val($k);
						$arr->set_pos($pos-1);
						return $res;
					}
				} else {
					$res = 0;
					$to_num = 1;
				}
			}
		}
	} elsif ($cmd eq 'end') {
		# https://php.net/manual/en/function.end.php
		#
		if (scalar @$args == 1) {
			my $var = $$args[0]; # ref var
			my ($is_valid, $val) = get_refvar_val($ctx, $var);

			if ($is_valid) {
				if (defined $val && is_array($val)) {
					my $arr = $parser->{strmap}{$val};
					my $keys = $arr->get_keys();
					if (scalar @$keys == 0) {
						$res = 0;
						$to_num = 1;
					} else {
						my $pos = scalar @$keys - 1;
						my $k = $keys->[$pos];
						$res = $arr->val($k);
						$arr->set_pos($pos);
						return $res;
					}
				} else {
					$res = 0;
					$to_num = 1;
				}
			}
		}
	} elsif (($cmd eq 'current') || ($cmd eq 'pos')) {
		# https://php.net/manual/en/function.current.php
		#
		if (scalar @$args == 1) {
			my $var = $$args[0];

			unless ($ctx->{infunction} && !$ctx->{incall}) {
				if (is_array($var)) {
					my $arr = $parser->{strmap}{$var};
					my $pos = $arr->get_pos();
					my $keys = $arr->get_keys();
					if ($pos >= scalar @$keys) {
						$res = 0;
						$to_num = 1;
					} else {
						my $k = $keys->[$pos];
						$res = $arr->val($k);
						return $res;
					}
				} else {
					$res = 0;
					$to_num = 1;
				}
			}
		}
	} elsif ($cmd eq 'key') {
		# https://php.net/manual/en/function.key.php
		#
		if (scalar @$args == 1) {
			my $var = $$args[0];

			unless ($ctx->{infunction} && !$ctx->{incall}) {
				if (is_array($var)) {
					my $arr = $parser->{strmap}{$var};
					my $pos = $arr->get_pos();
					my $keys = $arr->get_keys();
					if ($pos >= scalar @$keys) {
						$res = '#null';
						return $res;
					} else {
						my $k = $keys->[$pos];
						if (is_int_index($k)) {
							$k = $parser->setnum($k);
						}
						return $k;
					}
				} else {
					$res = '#null';
					return $res;
				}
			}
		}
	} elsif ($cmd eq 'array_map') {
		# https://php.net/manual/en/function.array-map.php
		#
		if (scalar @$args == 2) {
			my $name = $$args[0];
			my $param = $$args[1];
			if ((is_strval($name) || is_variable($name)) && is_array($param)) {
				my $arr = $parser->{strmap}{$param};
				my $keys = $arr->get_keys();

				if (is_strval($name)) {
					$name = $parser->{strmap}{$name};
				}
				if (defined $keys) {
					my $newarr = $parser->newarr();
					foreach my $k (@$keys) {
						my $val = $arr->val($k);
						my $c = $parser->setcall($name, [$val]);
						my $v = $ctx->exec_statement($c);
						$newarr->set($k, $v);
					}
					return $newarr->{name};
				}
			}
		}
	} elsif ($cmd eq 'array_walk') {
		# https://php.net/manual/en/function.array-walk.php
		#
		if (scalar @$args >= 2) {
			my $var = $$args[0]; # ref var
			my $name = $$args[1]; # callable
			my $arg;
			if (is_strval($name)) {
				$name = $parser->{strmap}->{$name};
			}
			if (scalar @$args > 2) {
				$arg = $$args[2];
			}
			my ($is_valid, $val) = get_refvar_val($ctx, $var);

			if ($is_valid) {
				if (defined $val && is_array($val)) {
					# todo: need only to create new array if handler has ref-param
					#
					my $arr = $parser->{strmap}{$val};
					my $keys = $arr->get_keys();
					my $newarr = $parser->newarr();
					foreach my $k (@$keys) {
						my $oldval = $arr->val($k);
						my $k2 = $k;
						if (is_int_index($k)) {
							$k2 = $parser->setnum($k);
						}
						my $v = $var.'__walktmp';
						$ctx->setvar($v, $oldval, 1);
						my $c = $parser->setcall($name, defined $arg ? [$v, $k2, $arg] : [$v, $k2]);
						my $r = $ctx->exec_statement($c, 1);
						my $n = $ctx->getvar($v, 1);
						$newarr->set($k, $n);
					}
					set_refvar_val($ctx, $var, $newarr->{name});
				}
				$res = 1;
				$to_num = 1;
			}
		}
       } elsif ($cmd eq 'array_rand') {
		# https://php.net/manual/en/function.array-rand.php
		#
		if (scalar @$args >= 1) {
			my $param = $$args[0];
			my $num = 1;
			if (scalar @$args == 2) {
				$num = $parser->get_strval($$args[1]);
			}
			unless ($ctx->{infunction} && !$ctx->{incall}) {
			    # don't precalc rand() in function body
			    #
			    if (is_array($param)) {
				my $arr = $parser->{strmap}{$param};
				my $keys = $arr->get_keys();
				if (!defined $keys || ($num > scalar @$keys)) {
					$res = 0;
					$to_num = 1;
				} elsif ($num == 1) {
					my $i = int(rand(scalar @$keys));
					my $k = $keys->[$i]; # return key
					if (is_int_index($k)) {
						$res = $k;
						$to_num = 1;
					} else {
						$res = $parser->get_strval($k);
					}
				} else {
					# keep random keys uniq & in order
					my @randidx = shuffle(0 .. $#$keys);
					@randidx = sort { $a <=> $b } @randidx[0..$num-1];

					my $newarr = $parser->newarr();
					foreach (my $i=0; $i < $num; $i++) {
						my $k = $keys->[$randidx[$i]];
						if (is_int_index($k)) {
							$k = $parser->setnum($k);
						}
						$newarr->set(undef, $k); # append key
					}
					return $newarr->{name};
				}
			    }
			}
		}
	} elsif ($cmd eq 'round') {
		if (scalar @$args >= 1) {
			my $s = $parser->get_strval($$args[0]);
			my $precision = 0;
			if (scalar @$args == 2) {
				$precision = $parser->get_strval($$args[1]);
			}
			if (defined $s && defined $precision) {
				if ($precision == 0) {
					$res = int($s + 0.5);
				} else {
					$res = sprintf "%0.*f", $precision, $s;
				}
				$to_num = 1;
			}
		}
	} elsif (($cmd eq 'rand') || ($cmd eq 'mt_rand')) {
		my $min = 0;
		my $max = 32767;
		if (scalar @$args == 2) {
			$min = $parser->get_strval($$args[0]);
			$max = $parser->get_strval($$args[1]);
		}
		if (defined $min && defined $max) {
		    # don't precalc rand() in function body
		    #
		    unless ($ctx->{infunction} && !$ctx->{incall}) {
			my $range = int($max) - int($min);
			$res = int(rand($range)) + int($min);
			$to_num = 1;
		    }
		}
	} elsif ($cmd eq 'empty') {
		# https://php.net/manual/en/function.empty.php
		# (https://php.net/manual/en/types.comparisons.php)
		#
		if (scalar @$args >= 1) {
			my $val = $$args[0];
			if (is_array($val)) {
				my $arr = $parser->{strmap}{$val};
				$res = $arr->empty() ? 1 : 0;
				$to_num = 1;
			} elsif (is_null($val)) {
				$res = 1;
				$to_num = 1;
			} elsif (is_strval($val)) {
				my $s = $parser->get_strval($val);
				if (!defined $s) {
					$res = 1;
				} elsif ($s eq '0') {
					$res = 1;
				} elsif (($val =~ /^(\#str\d+)$/) && ($s eq '')) {
					$res = 1;
				} else {
					$res = 0;
				}
				$to_num = 1;
			} elsif (is_variable($val)) {
				my $v = $ctx->getvar($val);
				#$ctx->{log}->($ctx, 'cmd', $cmd, "$val -> $v: (tainted: %s)", $ctx->{tainted}) if $ctx->{log};
				if (!defined $v) {
		                    unless (&parsing_func($ctx) || $ctx->{tainted}) {
					unless ($ctx->{skipundef}) {
						$res = 1;
						$to_num = 1;
					}
				    }
				} elsif ($v eq '#unresolved') {
					$ctx->{warn}->($ctx, 'cmd', $cmd, "$val is #unresolved");
				}
			} elsif ($val =~ /^(\#elem\d+)$/) {
				my ($v, $i) = @{$parser->{strmap}->{$val}};
				my ($basevar, $has_index, $idxstr) = $ctx->resolve_variable($val, 0);
				if (defined $basevar) {
				     if ($has_index) {
					my $basestr = $ctx->exec_statement($basevar, 0);
					if (defined $basestr && is_array($basestr) && defined $idxstr) {
						$idxstr = $parser->setstr('') if is_null($idxstr); # null maps to '' array index
						my $arr = $parser->{strmap}{$basestr};
						my $arrval = $arr->get($idxstr);
						if (defined $arrval) {
							my $s = $parser->get_strval($arrval);
							if (!defined $s) {
								$res = 1;
							} elsif ($s eq '0') {
								$res = 1;
							} elsif (($arrval =~ /^(\#str\d+)$/) && ($s eq '')) {
								$res = 1;
							} else {
								$res = 0;
							}
						} elsif (!$ctx->is_superglobal($basevar)) {
							$res = 1;
						}
						$to_num = 1;
					} elsif (!defined $basestr && (!$ctx->is_superglobal($basevar) || ($basevar =~ /^\$GLOBALS$/))) {
						unless ($ctx->{tainted}) {
							$ctx->{warn}->($ctx, 'cmd', $cmd, "$val %s[%s] is #unresolved", $basevar, defined $i ? $i : '');
						}
					}
				    } else {
					my $v = $ctx->getvar($basevar);
					if (!defined $v) {
				             unless (&parsing_func($ctx) || $ctx->{tainted}) {
						unless ($ctx->{skipundef}) {
							$res = 1;
							$to_num = 1;
						}
					    }
					} elsif ($v eq '#unresolved') {
						$ctx->{warn}->($ctx, 'cmd', $cmd, "$val is #unresolved");
					}
				    }
				}
			}
		}
	} elsif ($cmd eq 'is_array') {
		# https://www.php.net/manual/en/function.is-array.php
		#
		if (scalar @$args == 1) {
			my $val = $$args[0];
			if (is_array($val)) {
				$res = 1;
				$to_num = 1;
			} elsif ($ctx->is_superglobal($val)) {
				$res = 1;
				$to_num = 1;
			} elsif (is_null($val)) {
				$res = 0;
				$to_num = 1;
			} elsif (is_strval($val)) {
				$res = 0;
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'is_null') {
		# https://php.net/manual/en/function.is-null.php (similar to $a === null)
		# (https://php.net/manual/en/types.comparisons.php)
		#
		if (scalar @$args >= 1) {
			my $val = $$args[0];
			if (is_array($val)) {
				$res = 0;
				$to_num = 1;
			} elsif (is_null($val)) {
				$res = 1;
				$to_num = 1;
			} elsif (is_strval($val)) {
				my $s = $parser->get_strval($val);
				if (!defined $s) {
					$res = 1;
				} else {
					$res = 0;
				}
				$to_num = 1;
			} elsif (is_variable($val)) {
				my $v = $ctx->getvar($val);
				if (!defined $v) {
		                    unless (&parsing_func($ctx) || $ctx->{tainted}) {
					unless ($ctx->{skipundef}) {
						if ($ctx->is_superglobal($val)) {
							# superglobals always exist as empty array,
							# Since it is unknown which fields exist in a real environment,
							# don't create superglobal array on the fly here.
							#
							$res = 0;
						} else {
							$res = 1;
						}
						$to_num = 1;
					}
				    }
				} elsif ($v eq '#unresolved') {
					$ctx->{warn}->($ctx, 'cmd', $cmd, "$val is #unresolved");
				}
			} elsif ($val =~ /^(\#elem\d+)$/) {
				my ($v, $i) = @{$parser->{strmap}->{$val}};
				my ($basevar, $has_index, $idxstr) = $ctx->resolve_variable($val, 0);
				if (defined $basevar) {
					my $basestr = $ctx->exec_statement($basevar, 0);
					if (defined $basestr && is_array($basestr) && defined $idxstr) {
						$idxstr = $parser->setstr('') if is_null($idxstr); # null maps to '' array index
						my $arr = $parser->{strmap}{$basestr};
						my $arrval = $arr->get($idxstr);
						if (defined $arrval) {
							$res = 0;
						} elsif (!$ctx->is_superglobal($basevar)) {
							$res = 1;
						}
						$to_num = 1;
					} elsif (!defined $basestr && (!$ctx->is_superglobal($basevar) || ($basevar =~ /^\$GLOBALS$/))) {
						unless ($ctx->{tainted}) {
							$ctx->{warn}->($ctx, 'cmd', $cmd, "$val %s[%s] is #unresolved", $basevar, defined $i ? $i : '');
						}
					}
				}
			}
		}
	} elsif ($cmd eq 'is_null_weak') {
		# https://php.net/manual/en/types.comparisons.php (similar to $a == null)
		#
		if (scalar @$args >= 1) {
			my $val = $$args[0];
			if (is_array($val)) {
				$res = 1;
				$to_num = 1;
			} elsif (is_null($val)) {
				$res = 1;
				$to_num = 1;
			} elsif (is_strval($val)) {
				my $s = $parser->get_strval($val);
				if (!defined $s) {
					$res = 1;
				} elsif (($val =~ /^(\#num\d+)$/) && ($s == 0)) {
					$res = 1;
				} elsif ($s eq '0') {
					$res = 0;
				} elsif (($val =~ /^(\#str\d+)$/) && ($s eq '')) {
					$res = 1;
				} elsif ($val =~ /^(\#null)$/) {
					$res = 1;
				} else {
					$res = 0;
				}
				$to_num = 1;
			} elsif (is_variable($val)) {
				my $v = $ctx->getvar($val);
				if (!defined $v) {
		            	    unless (&parsing_func($ctx) || $ctx->{tainted}) {
					unless ($ctx->{skipundef}) {
						if ($ctx->is_superglobal($val)) {
							# superglobals always exist as empty array,
							# Since it is unknown which fields exist in a real environment,
							# don't create superglobal array on the fly here.
							#
							$res = 0;
						} else {
							$res = 1;
						}
						$to_num = 1;
					}
				    }
				} elsif ($v eq '#unresolved') {
					$ctx->{warn}->($ctx, 'cmd', $cmd, "$val is #unresolved");
				}
			} elsif ($val =~ /^(\#elem\d+)$/) {
				my ($v, $i) = @{$parser->{strmap}->{$val}};
				my ($basevar, $has_index, $idxstr) = $ctx->resolve_variable($val, 0);
				if (defined $basevar) {
					my $basestr = $ctx->exec_statement($basevar, 0);
					if (defined $basestr && is_array($basestr) && defined $idxstr) {
						$idxstr = $parser->setstr('') if is_null($idxstr); # null maps to '' array index
						my $arr = $parser->{strmap}{$basestr};
						my $arrval = $arr->get($idxstr);
						if (defined $arrval) {
							my $s = $parser->get_strval($arrval);
							if (!defined $s) {
								$res = 1;
							} elsif (($arrval =~ /^(\#num\d+)$/) && ($s == 0)) {
								$res = 1;
							} elsif ($arrval eq '0') {
								$res = 1;
							} elsif (($arrval =~ /^(\#str\d+)$/) && ($s eq '')) {
								$res = 1;
							} elsif ($arrval =~ /^(\#null)$/) {
								$res = 1;
							} else {
								$res = 0;
							}
						} elsif (!$ctx->is_superglobal($basevar)) {
							$res = 1;
						}
						$to_num = 1;
					} elsif (!defined $basestr && (!$ctx->is_superglobal($basevar) || ($basevar =~ /^\$GLOBALS$/))) {
						unless ($ctx->{tainted}) {
							$ctx->{warn}->($ctx, 'cmd', $cmd, "$val %s[%s] is #unresolved", $basevar, defined $i ? $i : '');
						}
					}
				}
			}
		}
	} elsif ($cmd eq 'isset') {
		my $inv = &exec_cmd($ctx, 'is_null', $args);
		if (defined $inv && is_strval($inv)) {
			if ($parser->{strmap}{$inv} eq '0') {
				$res = 1;
			} else {
				$res = 0;
			}
			$to_num = 1;
		}
	} elsif ($cmd eq 'define') {
		if (scalar @$args == 2) {
			my $key = $parser->get_strval($$args[0]);
			my $val = $parser->get_strval($$args[1]);
			if (defined $key && defined $val) {
				if (defined $ctx->{defines}) {
					$ctx->{defines}{$key} = $$args[1];
					$ctx->{log}->($ctx, 'cmd', $cmd, "$key = $val") if $ctx->{log};
					# no result here
					return '#noreturn';
				}
			}
		}
	} elsif ($cmd eq 'function_exists') {
		# https://php.net/manual/en/function.function-exists.php
		#
		if (scalar @$args == 1) {
			my $fn = $parser->get_strval($$args[0]);
			if (defined $fn) {
				my $lfn = lc($fn);

				# php functions are always global
				# - so a user defined func is valid also in tainted mode
				#
				unless ($ctx->{skipundef}) {
					if ($ctx->getfun($fn)) {
						$res = 1;
					}
				}
				unless (defined $res) {
					if (get_php_func($lfn)) {
						$res = 1;
					}
				}
				unless (defined $res) {
					if ($ctx->{tainted}) {
						$ctx->{warn}->($ctx, 'cmd', $cmd, "$fn not found but ctx tainted -> skip execution");
						return;
					} else {
						$res = 0;
					}
				}
				$to_num = 1;
			}
		}
	} elsif ($cmd eq 'create_function') {
		# https://php.net/manual/en/function.create-function.php
		# (see also: anonymous functions)
		#
		# This is basically what PHP does internally:
		# function create_function($args, $code) {
		#     // create a random $functionName
		#     eval('function ' . $functionName . '($args){$code}');
		#     return $functionName;
		# }
		#
		# It's why you can do something like this (which works on the same principle as SQL injection):
		# $code = 'print "I print repeatedly.\n"; } print "I print once.\n"; if (false) {';
		# $function = create_function('', $code);
		# call_user_func($function);
		# call_user_func($function);
		# 
		# // I print once.
		# // I print repeatedly.
		# // I print repeatedly.
		#
		if (scalar @$args == 2) {
			my $params = $parser->get_strval($$args[0]);
			my $code   = $parser->get_strval($$args[1]);
			if (defined $args && defined $code) {
				my @arglist;
				foreach my $p (split(/,/, $params)) {
					my $stmt = $parser->read_statement([$p], undef);
					push(@arglist, $stmt);
				}
				# eval with new parser and without global & local varmap
				#
				my $codestr = $parser->setstr('function ('.$params.') {'.$code.'}');
				my $parser2 = $parser->subparser();
				my $ctx2 = $ctx->subctx(globals => {}, varmap => {}, parser => $parser2, tainted => 1, varhist => {});
				my $block = $ctx2->parse_eval($codestr);
				my $stmt = $ctx2->exec_eval($block);
				$stmt = $ctx->exec_statement($stmt);
				return $stmt;
			}
		}
	} elsif ($cmd eq 'call_user_func') {
		# https://php.net/manual/en/function.call-user-func.php
		#
		if (scalar @$args >= 1) {
			my $name = $$args[0];
			if (is_strval($name) || is_variable($name)) {
				if (is_strval($name)) {
					$name = $parser->{strmap}->{$name};
				}
				my @arglist = @$args[1..@$args-1];
				my $call = $parser->setcall($name, \@arglist);
				return $call;
			}
		}
	} elsif ($cmd eq 'call_user_func_array') {
		# https://php.net/manual/en/function.call-user-func-array.php
		#
		if (scalar @$args == 2) {
			my $name = $$args[0];
			my $param = $$args[1];
			if ((is_strval($name) || is_variable($name)) && is_array($param)) {
				my $arr = $parser->{strmap}{$param};
				my $keys = $arr->get_keys();
				if (is_strval($name)) {
					$name = $parser->{strmap}->{$name};
				}
				if (@$keys) {
					my @arglist = ();
					foreach my $k (@$keys) {
						my $val = $arr->val($k);
						my $v = $ctx->exec_statement($val);
						push(@arglist, $v);
					}
					my $call = $parser->setcall($name, \@arglist);
					return $call;
				}
			}
		}
	} elsif ($cmd eq 'file') {
		# https://php.net/manual/en/function.file.php
		# - TODO: also URL possible
		#
		if (scalar @$args >= 1) {
			my $filename = $parser->get_strval($$args[0]);
			my $flags = 0;

			if (scalar @$args > 1) {
				$flags = $parser->get_strval($$args[1]);
			}
			if (defined $filename) {
			    my ($fh) = $parser->newfh($filename, 'r');
			    if (defined $fh) {
				my $buf = $parser->{strmap}->{$fh}{buf};
				$parser->{strmap}->{$fh}{buf} = '';
				# split in lines and keep trailing newlines
				#
				my @lines;
				if ($flags =~ /FILE_IGNORE_NEW_LINES/) {
					@lines = split(/\n/, $buf);
				} else {
					@lines = split(/^/, $buf);
				}
				my $arr = $parser->newarr();

				foreach my $p (@lines) {
					$ctx->{log}->($ctx, 'cmd', $cmd, "[$filename] line: $p") if $ctx->{log};
					my $k = $parser->setstr($p);
					$arr->set(undef, $k);
				}
				return $arr->{name};
			    }
			}
		}
	} elsif ($cmd eq 'file_get_contents') {
		# https://php.net/manual/en/function.file-get-contents.php
		#
		if (scalar @$args == 1) {
			my $filename = $parser->get_strval($$args[0]);

			if (defined $filename) {
			    my ($fh) = $parser->newfh($filename, 'r');
			    if (defined $fh) {
				my $buf = $parser->{strmap}->{$fh}{buf};
				$parser->{strmap}->{$fh}{buf} = '';
				$res = $buf;
			    }
			}
		}
	} elsif ($cmd eq 'reset') {
		# https://php.net/manual/en/function.reset.php
		# reset next()-pointer & return first array element
		#
		if (scalar @$args == 1) {
			my $basestr = $$args[0];

			if (is_array($basestr)) {
				my $arr = $parser->{strmap}{$basestr};
				my $keys = $arr->get_keys();

				#my @vals = map { $arr->val($_) } @$keys;
				$res = $arr->val($keys->[0]);
			}
		}
	} elsif ($cmd eq 'fopen') {
		if (scalar @$args >= 2) {
			my $filename = $parser->get_strval($$args[0]);
			my $mode = $parser->get_strval($$args[1]);
			if (defined $filename && defined $mode) {
				my ($fh) = $parser->newfh($filename, $mode);
				return $fh;
			}
		}
	} elsif ($cmd eq 'fclose') {
		if (scalar @$args == 1) {
			my $fh = $$args[0];
			if ($fh =~ /^(\#fh\d+)$/) {
				$parser->{strmap}->{$fh}{pos} = 0;
				$parser->{strmap}->{$fh}{buf} = '';
			}
		}
	} elsif ($cmd eq 'fread') {
		if (scalar @$args == 2) {
			my $fh = $$args[0];
			my $cnt = $parser->get_strval($$args[1]);
			if (($fh =~ /^(\#fh\d+)$/) && defined $cnt) {
				my $pos = $parser->{strmap}->{$fh}{pos};
				my $buf = $parser->{strmap}->{$fh}{buf};
				if ($cnt > length($buf) - $pos) {
					$cnt = length($buf) - $pos;
				}
				$res = substr($buf, $pos, $cnt);
				$pos += $cnt;
				$parser->{strmap}->{$fh}{pos} = $pos;
			}
		}
	} elsif ($cmd eq 'fgets') {
		if (scalar @$args >= 1) {
			my $fh = $$args[0];
			my $cnt;
			if (scalar @$args == 2) {
				$cnt = $parser->get_strval($$args[1]);
			}
			if ($fh =~ /^(\#fh\d+)$/) {
				my $pos = $parser->{strmap}->{$fh}{pos};
				my $buf = $parser->{strmap}->{$fh}{buf};
				$res = '';

				while ($pos < length($buf)) {
					my $ch = substr($buf, $pos, 1);
					if ($ch eq "\n") {
						$pos++;
						last;
					}
					last if (defined $cnt && (length($res) >= $cnt));
					$res .= $ch;
					$pos++;
				}
				$parser->{strmap}->{$fh}{pos} = $pos;
			}
		}
	}

        if (defined $res) {
		my $k;
		if ($to_num) {
			$k = $parser->setnum($res);
		} else {
			$k = $parser->setstr($res);
		}
		return $k;
	}
	return;
}

1;

__END__

=head1 NAME

PHP::Decode::Func

=head1 SYNOPSIS

  # Creating an instance

  my %strmap;
  my $parser = PHP::Decode::Parser->new(strmap => \%strmap);
  my $ctx = PHP::Decode::Transformer->new(parser => $parser);

  # Exec func

  my $str = $parser->setstr('test');
  my $res = PHP::Decode::Func::exec_cmd($ctx, 'strlen', [$str]);

  if (defined $res) {
      my $code = $parser->format_stmt($res);
      print $code;
  }

=head1 DESCRIPTION

The PHP::Decode::Func Module contains implementations of php builtin-functions
without external side-effects.

=head1 METHODS

=head2 exec_cmd

Execute a php built-in function.

    $res = PHP::Decode::Func::exec_cmd($ctx, $cmd, $args);

=head2 Dependencies

Requires the PHP::Decode::Parser, PHP::Decode::Transformer and PHP::Decode::Array Modules.

Some other Modules are required to implement the php functions:
List::Util, Compress::Zlib, Digest::MD5, Digest::SHA1, HTML::Entities, URI::Escape, File::Basename.

=head1 AUTHORS

Barnim Dzwillo @ Strato AG

=cut

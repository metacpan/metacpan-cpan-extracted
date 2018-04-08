package Test::PLP;

use strict;
use warnings;

use PLP::Functions qw( DecodeURI );
require PLP::Backend::CGI;
require PerlIO::scalar;

our $VERSION = '1.00';

use Test::Builder::Module;
use base 'Test::Builder::Module';
our @EXPORT = qw( plp_is plp_ok );

$PLP::use_cache = 0 if $PLP::use_cache;
#TODO: caching on (change file names)

open ORGOUT, '>&', *STDOUT;

sub is_string ($$;$) {
	my $tb = __PACKAGE__->builder;
	$tb->is_eq(@_);
}

eval {
	# optionally replace unformatted is_string by LongString prettification
	require Test::LongString;
	Test::LongString->import(max => 128);

	# override output method to not escape newlines
	no warnings 'redefine';
	my $formatter = *Test::LongString::_display;
	my $parent = \&{$formatter};
	*{$formatter} = sub {
		my $s = &{$parent};
		$s =~ s/\Q\x{0a}/\n              /g;
		# align lines to: "____expected: "
		return $s;
	};
} or 1;

sub _plp_run {
	my ($src, $env, $input) = @_;

	%ENV = (
		REQUEST_METHOD => 'GET',
		REQUEST_URI => "/$src/test/123",
		QUERY_STRING => 'test=1&test=2',
		GATEWAY_INTERFACE => 'CGI/1.1',
		
		SCRIPT_NAME => '/plp.cgi',
		SCRIPT_FILENAME => "./plp.cgi",
		PATH_INFO => "/$src/test/123",
		PATH_TRANSLATED => "./$src/test/123",
		DOCUMENT_ROOT => ".",
		
		$env ? %{$env} : (),
	); # Apache/2.2.4 CGI environment

	if (defined $input) {
		$ENV{CONTENT_LENGTH} //= length $input;
		$ENV{CONTENT_TYPE} //= 'application/x-www-form-urlencoded';
		close STDIN;
		open STDIN, '<', $input;
	}

	close STDOUT;
	open STDOUT, '>', \my $output;  # STDOUT buffered to scalar
	select STDOUT;  # output before start() (which selects PLPOUT)
	eval {
		local $SIG{__WARN__} = sub {
			# include warnings in stdout (but modified to distinguish)
			my $msg = shift;
			my $eol = $msg =~ s/(\s*\z)// && $1;
			print "<warning>$msg</warning>$eol"
		};
		PLP::everything();
	};
	my $failure = $@;
	select ORGOUT;  # return to original STDOUT
	die $failure if $failure;

	return $output;
}

sub plp_is {
	my ($src, $env, $input, $expect, $name) = @_;
	my $tb = __PACKAGE__->builder;
	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my $output = eval { _plp_run($src, $env, $input) };
	if (my $failure = $@) {
		$tb->ok(0, $name);
		$tb->diag("    Error: $failure");
		return;
	}

	if (defined $expect) {
		$output =~ s{((?:.+\n)*)}{ join "", sort split /(?<=\n)/, $1 }e; # order headers
		return is_string($output, $expect, $name);
	}

	$tb->ok(defined $output, $name);
	return $output;
}

sub _getwarning {
	# captures the first warning produced by the given code string
	my ($code, $line, $file) = @_;

	local $SIG{__WARN__} = sub { die @_ };
	# warnings module runs at BEGIN, so we need to use icky expression evals
	eval qq(# line $line "$file"\n$code; return);
	my $res = $@;
	chomp $res;
	return $res;
}

sub _getplp {
	my ($file, %replace) = @_;

	(my $name = $file) =~ s/[.][^.]+$//;
	$file = "$name.html";
	my $src = delete $replace{-input} // "$name.plp";
	my $input = -e "$name.txt" && "$name.txt";
	$name =~ s/^(\d*)-// and $name .= " ($1)";
	DecodeURI($name);

	my $env = delete $replace{-env};

	my $output;
	if (open my $fh, '<', $file) {
		local $/ = undef;  # slurp
		$output = readline $fh;
		close $fh;
	}

	if ($output) {
		$replace{HEAD} //= "Content-Type: text/html\nX-PLP-Version: $PLP::VERSION\n";
		$replace{VERSION        } //= $PLP::VERSION;
		$replace{SCRIPT_NAME    } //= $src;
		$replace{SCRIPT_FILENAME} //= "./$src";

		chomp $output;
		$output =~ s/\$$_/$replace{$_}/g for keys %replace;
		$output =~ s{
			<eval \s+ line="([^"]*)"> (.*?) </eval>
		}{ _getwarning($2, $1, $src) }msxge;
	}

	return ($src, $env, $input, $output, $name);
}

sub plp_ok {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	plp_is(_getplp(@_));
}


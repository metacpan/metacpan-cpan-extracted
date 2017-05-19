#line 1
#line 43

package Module::Runtime;

{ use 5.006; }
use warnings;
use strict;

use Params::Classify 0.000 qw(is_string);

our $VERSION = "0.011";

use parent "Exporter";
our @EXPORT_OK = qw(
	$module_name_rx is_module_name is_valid_module_name check_module_name
	module_notional_filename require_module
	use_module use_package_optimistically
	$top_module_spec_rx $sub_module_spec_rx
	is_module_spec is_valid_module_spec check_module_spec
	compose_module_name
);

#line 86

our $module_name_rx = qr/[A-Z_a-z][0-9A-Z_a-z]*(?:::[0-9A-Z_a-z]+)*/;

#line 95

my $qual_module_spec_rx =
	qr#(?:/|::)[A-Z_a-z][0-9A-Z_a-z]*(?:(?:/|::)[0-9A-Z_a-z]+)*#;

my $unqual_top_module_spec_rx =
	qr#[A-Z_a-z][0-9A-Z_a-z]*(?:(?:/|::)[0-9A-Z_a-z]+)*#;

our $top_module_spec_rx = qr/$qual_module_spec_rx|$unqual_top_module_spec_rx/o;

#line 110

my $unqual_sub_module_spec_rx = qr#[0-9A-Z_a-z]+(?:(?:/|::)[0-9A-Z_a-z]+)*#;

our $sub_module_spec_rx = qr/$qual_module_spec_rx|$unqual_sub_module_spec_rx/o;

#line 129

sub is_module_name($) { is_string($_[0]) && $_[0] =~ /\A$module_name_rx\z/o }

#line 137

*is_valid_module_name = \&is_module_name;

#line 147

sub check_module_name($) {
	unless(&is_module_name) {
		die +(is_string($_[0]) ? "`$_[0]'" : "argument").
			" is not a module name\n";
	}
}

#line 170

sub module_notional_filename($) {
	&check_module_name;
	my($name) = @_;
	$name =~ s!::!/!g;
	return $name.".pm";
}

#line 195

sub require_module($) {
	# Explicit scalar() here works around a Perl core bug, present
	# in Perl 5.8 and 5.10, which allowed a require() in return
	# position to pass a non-scalar context through to file scope
	# of the required file.  This breaks some modules.  require()
	# in any other position, where its op flags determine context
	# statically, doesn't have this problem, because the op flags
	# are forced to scalar.
	return scalar(require(&module_notional_filename));
}

#line 231

sub use_module($;$) {
	my($name, $version) = @_;
	require_module($name);
	if(defined $version) {
		$name->VERSION($version);
	}
	return $name;
}

#line 265

sub use_package_optimistically($;$) {
	my($name, $version) = @_;
	check_module_name($name);
	eval { local $SIG{__DIE__}; require(module_notional_filename($name)); };
	die $@ if $@ ne "" && $@ !~ /\A
		Can't\ locate\ .+\ at
		\ \Q@{[__FILE__]}\E\ line\ \Q@{[__LINE__-1]}\E
	/xs;
	$name->VERSION($version) if defined $version;
	return $name;
}

#line 293

sub is_module_spec($$) {
	my($prefix, $spec) = @_;
	return is_string($spec) &&
		$spec =~ ($prefix ? qr/\A$sub_module_spec_rx\z/o :
				    qr/\A$top_module_spec_rx\z/o);
}

#line 306

*is_valid_module_spec = \&is_module_spec;

#line 315

sub check_module_spec($$) {
	unless(&is_module_spec) {
		die +(is_string($_[1]) ? "`$_[1]'" : "argument").
			" is not a module specification\n";
	}
}

#line 343

sub compose_module_name($$) {
	my($prefix, $spec) = @_;
	check_module_name($prefix) if defined $prefix;
	&check_module_spec;
	if($spec =~ s#\A(?:/|::)##) {
		# OK
	} else {
		$spec = $prefix."::".$spec if defined $prefix;
	}
	$spec =~ s#/#::#g;
	return $spec;
}

#line 380

1;

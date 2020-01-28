use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Plain;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.011';

use Sub::HandlesVia::Toolkit;
our @ISA = 'Sub::HandlesVia::Toolkit';

sub make_callbacks {
	my ($me, $target, $attr) = (shift, @_);
	
	my ($get_slot, $set_slot) = @$attr;
	$set_slot = $get_slot if @$attr < 2;
	
	my $captures = {};
	my ($get, $set, $get_is_lvalue) = (undef, undef, 0);
	
	require B;
	
	if (ref $get_slot) {
		$get = sub { '$_[0]->$shv_reader' };
		$captures->{'$shv_reader'} = \$get_slot;
	}
	elsif ($get_slot =~ /\A \[ ([0-9]+) \] \z/sx) {
		my $index = $1;
		$get = sub { "\$_[0][$index]" };
		++$get_is_lvalue;
	}
	elsif ($get_slot =~ /\A \{ (.+) \} \z/sx) {
		my $key = B::perlstring($1);
		$get = sub { "\$_[0]{$key}" };
		++$get_is_lvalue;
	}
	else {
		my $method = B::perlstring($get_slot);
		$get = sub { "\$_[0]->\${\\ $method}" };
	}
	
	if (ref $set_slot) {
		$set = sub { my $val = shift or die; "\$_[0]->\$shv_writer($val)" };
		$captures->{'$shv_writer'} = \$set_slot;
	}
	elsif ($set_slot =~ /\A \[ ([0-9]+) \] \z/sx) {
		my $index = $1;
		$set = sub { my $val = shift or die; "(\$_[0][$index] = $val)" };
	}
	elsif ($set_slot =~ /\A \{ (.+) \} \z/sx) {
		my $key = B::perlstring($1);
		$set = sub { my $val = shift or die; "(\$_[0]{$key} = $val)" };
	}
	else {
		my $method = B::perlstring($set_slot);
		$set = sub { my $val = shift or die; "\$_[0]->\${\\ $method}($val)" };
	}

	my %callbacks = (
		args => sub {
			'@_[1..$#_]';
		},
		arg => sub {
			@_==1 or die;
			my $n = shift;
			"\$_[$n]";
		},
		argc => sub {
			'(@_-1)';
		},
		curry => sub {
			@_==1 or die;
			my $arr = shift;
			"splice(\@_,1,0,$arr);";
		},
		usage_string => sub {
			@_==2 or die;
			my $method_name = shift;
			my $guts = shift;
			"\$instance->$method_name($guts)";
		},
		self => sub {
			'$_[0]';
		},
		is_method      => !!1,
		get            => $get,
		get_is_lvalue  => $get_is_lvalue,
		set            => $set,
		set_checks_isa => !!1,
		coerce         => !!0,
		env            => $captures,
		be_strict      => !!1,
	);
	
	\%callbacks;
}

1;


package Parse::Plain;

require 5.005;
use strict;


BEGIN
{
	use Exporter;
	use Carp;
	use vars  qw( $VERSION $lcnt_max $ssec );

	$VERSION = "3.03";
}


# constructor
# [I] $template (mandatory): template filename
#     $lcnt_max (optional) : number of attempts to open file
#     $s_sec    (optional) : number of seconds to sleep between
#                            attemts if file can't be opened
sub new
{
	my $type = shift;
	my ($template, $lcnt, @lines, $line, $block, $block_open,
	    $s_block, @bl_stack, @bl_name_stack);
	my $self = {};

	($template, $lcnt_max, $ssec) = @_;

	$self->{'text'}   = '';    # input
	$self->{'hparse'} = {};    # hash of tags - values
	$self->{'gparse'} = {};    # hash of global tags - values
	$self->{'hblock'} = {};    # hash of blocks
	$self->{'oblock'} = {};    # original values of blocks
	$self->{'cback'}  = {};    # callback references
	$self->{'parsed'} = undef; # output
	
	if ((defined $lcnt_max) && ($lcnt_max !~ /^\d+$/)) {
		&_my_error('$lcnt_max must be number');
	}
	$lcnt_max = 5 unless ($lcnt_max);

	if ((defined $lcnt_max) && ($lcnt_max !~ /^\d+$/)) {
		&_my_error('$ssec must be number');
	}
	$ssec = 1 unless ($ssec);
	
	@lines = @{&_load_file($template)};

	$block = \$self->{'text'};
	$block_open = '';
	foreach $line(@lines) {
		if ($line =~ m/^\s*{{\s*([\!\w\d\.-_]+)$/) {
			push @bl_name_stack, $block_open
				if ($block_open);

			if (substr($1, 0, 1) eq '!') {
				$s_block = 1;
				$block_open = substr($1, 1);
			} else {
				$s_block = 0;
				$block_open = $1;
			}

			chomp $$block if ($$block);
			$$block .= ('%%!' . $block_open . '%%')
			    unless ($s_block);
			push @bl_stack, $block;
			$block = \$self->{'hblock'}->{$block_open};
			next;
		}
		if (($line =~ m/^\s*}}(.*)$/) && $block_open) {
			chomp $$block if ((!$1) && ($$block));
			$block = pop @bl_stack;
			$block_open = pop @bl_name_stack;
 			$line = ($1 ? $1 . "\n" : '');
 			redo;
		}
		$$block .= $line;
	}
	
	if ($block_open) {
		&_my_error("in $template: block not closed");
	}
	
	foreach (keys(%{$self->{'hblock'}})) {
		$self->{'oblock'}->{$_} = $self->{'hblock'}->{$_};
	}
	
	$self->{'cback'}->{'INCLUDE'} = \&_include_file;
	
	return bless $self, $type;
}


# set tags in %hparse
# [I] either ($tag, $val) pair or $hash_ref containing { $tag => $val } pairs
# [O] hash_ref containing { $tagname => $new_value, ... }
sub set_tag
{
 	my $self = shift;
	my ($tag, $val, $res);
	
	unless ($_[0]) {
		&_my_error('required parameter missed');
	}
	
	$res = {};

	if (ref($_[0]) eq 'HASH') {
		foreach $tag(keys(%{$_[0]})) {
			$val = $_[0]->{$tag};
			
			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'hparse'}->{$tag} = $val->parse;
			} else {
				$self->{'hparse'}->{$tag} = $val;
			}
			$res->{$tag} = $self->{'hparse'}->{$tag};
		}
	} elsif (!ref($_[0])) {
		($tag, $val) = @_;
		
		if (UNIVERSAL::isa($val, 'Parse::Plain')) {
			$self->{'hparse'}->{$tag} = $val->parse;
		} else {
			$self->{'hparse'}->{$tag} = $val;
		}
		$res->{$tag} = $self->{'hparse'}->{$tag};
	} else {
		&_my_error('unsupported argument type: ' . ref($_[0]));
	}
	
	return $res;
}


# retrieve tags from %hparse
# [I] @tags or [$tag1, $tag2, ...]
# [O] [$val1, $val2, ...]
sub get_tag
{
	my $self = shift;
	my ($res, $key);

	unless ($_[0]) {
		&_my_error('required parameter missed');
	}
	
	$res = [];
	
	# to avoid mess I support either arrayref or list not both mixed!
	if (ref($_[0]) eq 'ARRAY') {
		foreach $key(@{$_[0]}) {
			push @$res, $self->{'hparse'}->{$key};
		}
	} elsif (!ref($_[0])) {
		while (@_) {
			$key = shift;
			push @$res, $self->{'hparse'}->{$key};
		}
	} else {
		&_my_error('unsupported argument type: ' . ref($_[0]));
	}

	return $res;
}


# append values to tags
# [I] either ($tag, $val) pair or $hash_ref containing { $tag => $val } pairs
# [O] hash_ref with { $tagname => $new_val, ... }
sub push_tag
{
	my $self = shift;
	my ($tag, $val, $res);

	unless ($_[0]) {
		&_my_error('required parameter missed');
	}
	
	$res = {};

	if (ref($_[0]) eq 'HASH') {
		foreach $tag(keys(%{$_[0]})) {
			$val = $_[0]->{$tag};

			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'hparse'}->{$tag} .= $val->parse;
			} else {
				$self->{'hparse'}->{$tag} .= $val;
			}
			
			$res->{$tag} = $self->{'hparse'}->{$tag};
		}
	} elsif (!ref($_[0])) {
		($tag, $val) = @_;
		
		if (UNIVERSAL::isa($val, 'Parse::Plain')) {
			$self->{'hparse'}->{$tag} .= $val->parse;
		} else {
			$self->{'hparse'}->{$tag} .= $val;
		}
		
		$res->{$tag} = $self->{'hparse'}->{$tag};
	} else {
		&_my_error('unsupported argument type: ' . ref($_[0]));
	}
	
	return $res;
}


# append tags to passed values and store result in tags
# [I] either ($tag, $val) pair or $hash_ref containing { $tag => $val } pairs
# [O] hash_ref of new values
sub unshift_tag
{
	my $self = shift;
	my ($tag, $val, $res);

	unless ($_[0]) {
		&_my_error('required parameter missed');
	}

	$res = {};	
	
	if (ref($_[0]) eq 'HASH') {
		foreach $tag(keys(%{$_[0]})) {
			$val = $_[0]->{$tag};

			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'hparse'}->{$tag} =
				    $val->parse . $self->{'hparse'}->{$tag};
			} else {
				$self->{'hparse'}->{$tag} =
				    $val . $self->{'hparse'}->{$tag};
			}
			
			$res->{$tag} = $self->{'hparse'}->{$tag};
		}
	} elsif (!ref($_[0])) {
		($tag, $val) = @_;

		if (UNIVERSAL::isa($val, 'Parse::Plain')) {
			$self->{'hparse'}->{$tag} =
			    $val->parse . $self->{'hparse'}->{$tag};
		} else {
			$self->{'hparse'}->{$tag} =
			    $val . $self->{'hparse'}->{$tag};
		}
		
		$res->{$tag} = $self->{'hparse'}->{$tag};
	} else {
		&_my_error('unsupported argument type: ' . ref($_[0]));
	}
	
	return $res;
}


# block src/res accessor, required for backwards compatibility with 2.x
# if block hasn't been parse()'d yet or has been unparse()'d then
# block_src() used else block_res()
# [I] scalar blockname to get or list (blockname, val) to set value
# [O] same as block_src() / block_res()
sub block
{
	my $self = shift;
	my ($bl);

	$bl = $_[0];
	unless ($bl) {
		&_my_error('required parameter missed');
	}
	
	if (defined $self->{'hparse'}->{'!' . $bl}) {
		return $self->block_res(@_);
	} else {
		return $self->block_src(@_);
	}
	
	&_my_error('control flow must never reach here');
}


# block source accessor
# [I] either block name (to get block value)
#     or array_ref of block names to get their values
#     or ($block, $val) to set $val to $block
#     or hash_ref of { $block => $val, ... } pairs
# [O] hash_ref with (new) values of blocks
sub block_src
{
	my $self = shift;
	my ($bl, $val, $res, @arr);
	
	@arr = @_;
	unless ($arr[0]) {
		&_my_error('required parameter missed');
	}

	$res = {};
	if (ref($arr[0]) eq 'ARRAY') { # get block vals from arr_ref
		foreach $bl(@{$arr[0]}) {
			$res->{$bl} = $self->{'hblock'}->{$bl};
		}
	} elsif (ref($arr[0]) eq 'HASH') { # set block val from hash_ref
		foreach $bl(keys(%{$arr[0]})) {
			$val = $arr[0]->{$bl};
			
			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'hblock'}->{$bl} = $val->parse;
			} else {
				$self->{'hblock'}->{$bl} = $val;
			}
			
			$res->{$bl} = $self->{'hblock'}->{$bl};
		}
	} elsif (!ref($arr[0])) { # no refs, for backwards-compatibility
		($bl, $val) = @arr;
		
		if ($val) {
			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'hblock'}->{$bl} = $val->parse;
			} else {
				$self->{'hblock'}->{$bl} = $val;
			}
		}
		
		$res->{$bl} = $self->{'hblock'}->{$bl};
	} else {
		&_my_error('unsupported argument type: ' . ref($arr[0]));
	}
	
	return $res;
}


# block result accessor
# [I] either block name (to get block value)
#     or array_ref of block names to get their values
#     or ($block, $val) to set $val to $block
#     or hash_ref of { $block => $val, ... } pairs
# [O] hash_ref with (new) values of blocks
sub block_res
{
	my $self = shift;
	my ($bl, $blf, $val, $res, @arr);
	
	@arr = @_;
	unless ($arr[0]) {
		&_my_error('required parameter missed');
	}

	$res = {};
	
	if (ref($arr[0]) eq 'ARRAY') { # get block vals from arr_ref
		foreach $bl(@{$arr[0]}) {
			$blf = '!' . $bl;
			
			if (defined $self->{'hparse'}->{$blf}) {
				$res->{$bl} = $self->{'hparse'}->{$blf};
			} else {
				$res->{$bl} = undef;
			}
		}
	} elsif (ref($arr[0]) eq 'HASH') { # set block val from hash_ref
		foreach $bl(keys(%{$arr[0]})) {
			$val = $arr[0]->{$bl};
			$blf = '!' . $bl;
			
			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'hparse'}->{$blf} = $val->parse;
			} else {
				$self->{'hparse'}->{$blf} = $val;
			}
			
			$res->{$bl} = $self->{'hparse'}->{$blf};
		}
	} elsif (!ref($arr[0])) { # no refs, for backwards-compatibility
		($bl, $val) = @arr;		
		$blf = '!' . $bl;
		
		if ($val) {
			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'hparse'}->{$blf} = $val->parse;
			} else {
				$self->{'hparse'}->{$blf} = $val;
			}
		}
		
		if (defined $self->{'hparse'}->{$blf}) {
			$res->{$bl} = $self->{'hparse'}->{$blf};
		} else {
			$res->{$bl} = undef;
		}
	} else {
		&_my_error('unsupported argument type: ' . ref($arr[0]));
	}
	
	return $res;
}


# append values to src / res blocks
# required for backwards compatibility with 2.x
# if block hasn't been parse()'d yet or has been unparse()'d then
# push_block_src() used else push_block_res()
# [I] list (blockname, val)
# [O] same as push_block_src() / push_block_res()
sub push_block
{
	my $self = shift;
	my ($bl);

	$bl = $_[0];
	unless ($bl) {
		&_my_error('required parameter missed');
	}
	
	if (defined $self->{'hparse'}->{'!' . $bl}) {
		return $self->push_block_res(@_);
	} else {
		return $self->push_block_src(@_);
	}
	
	&_my_error('control flow must never reach here');
}


# append values to blocks sources
# [I] either ($block, $val) or $hash_ref with { $block => $val, ... } pairs
# [O] hash_ref of new values
sub push_block_src
{
	my $self = shift;
	my ($block, $val, $res);

	unless ($_[0]) {
		&_my_error('required parameter missed');
	}
	
	$res = {};

	if (ref($_[0]) eq 'HASH') {
		foreach $block(keys(%{$_[0]})) {
			$val = $_[0]->{$block};
			
			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'hblock'}->{$block} .= $val->parse;
			} else {
				$self->{'hblock'}->{$block} .= $val;
			}
			
			$res->{$block} = $self->{'hblock'}->{$block};
		}
	} elsif (!ref($_[0])) {
		($block, $val) = @_;
		
		if (UNIVERSAL::isa($val, 'Parse::Plain')) {
			$self->{'hblock'}->{$block} .= $val->parse;
		} else {
			$self->{'hblock'}->{$block} .= $val;
		}
		
		$res->{$block} = $self->{'hblock'}->{$block};
	} else {
		&_my_error('unsupported argument type: ' . ref($_[0]));
	}
	
	return $res;
}


# append values to blocks results
# [I] either ($block, $val) or $hash_ref with { $block => $val, ... } pairs
# [O] hash_ref of new values
sub push_block_res
{
	my $self = shift;
	my ($block, $blockf, $val, $res);

	unless ($_[0]) {
		&_my_error('required parameter missed');
	}
	
	$res = {};

	if (ref($_[0]) eq 'HASH') {
		foreach $block(keys(%{$_[0]})) {
			$val = $_[0]->{$block};
			$blockf = '!' . $block;
			
			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'hparse'}->{$blockf} .= $val->parse;
			} else {
				$self->{'hparse'}->{$blockf} .= $val;
			}
			
			$res->{$block} = $self->{'hparse'}->{$blockf};
		}
	} elsif (!ref($_[0])) {
		($block, $val) = @_;
		$blockf = '!' . $block;
		
		if (UNIVERSAL::isa($val, 'Parse::Plain')) {
			$self->{'hparse'}->{$blockf} .= $val->parse;
		} else {
			$self->{'hparse'}->{$blockf} .= $val;
		}
		
		$res->{$block} = $self->{'hparse'}->{$blockf};
	} else {
		&_my_error('unsupported argument type: ' . ref($_[0]));
	}
	
	return $res;
}


# push values to src / res blocks
# required for backwards compatibility with 2.x
# if block hasn't been parse()'d yet or has been unparse()'d then
# unshift_block_src() used else unshift_block_res()
# [I] list (blockname, val)
# [O] same as unshift_block_src() / unshift_block_res()
sub unshift_block
{
	my $self = shift;
	my ($bl);

	$bl = $_[0];
	unless ($bl) {
		&_my_error('required parameter missed');
	}
	
	if (defined $self->{'hparse'}->{'!' . $bl}) {
		return $self->unshift_block_res(@_);
	} else {
		return $self->unshift_block_src(@_);
	}
	
	&_my_error('control flow must never reach here');
}


# append block(s) sources to passed values and store 
# result back into blocks sources
# [I] either ($block, $val) or $hash_ref with { $block => $val, ... } pairs
# [O] if hash_ref was passed then hash_ref of new values else just new value
sub unshift_block_src
{
	my $self = shift;
	my ($block, $val, $res);

	unless ($_[0]) {
		&_my_error('required parameter missed');
	}
	
	$res = {};
	
	if (ref($_[0]) eq 'HASH') {
		foreach $block(keys(%{$_[0]})) {
			$val = $_[0]->{$block};
			
			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'hblock'}->{$block} =
				    $val->parse . $self->{'hblock'}->{$block};
			} else {
				$self->{'hblock'}->{$block} =
				    $val . $self->{'hblock'}->{$block};
			}
			
			$res->{$block} = $self->{'hblock'}->{$block};
		}
	} elsif (!ref($_[0])) {
		($block, $val) = @_;
		
		if (UNIVERSAL::isa($val, 'Parse::Plain')) {
			$self->{'hblock'}->{$block} =
			    $val->parse . $self->{'hblock'}->{$block};
		} else {
			$self->{'hblock'}->{$block} =
			    $val . $self->{'hblock'}->{$block};
		}
		
		$res->{$block} = $self->{'hblock'}->{$block};
	} else {
		&_my_error('unsupported argument type: ' . ref($_[0]));
	}
	
	return $res;
}


# append blocks results to passed values and 
# store block results back into blocks
# [I] either ($block, $val) or $hash_ref with { $block => $val, ... } pairs
# [O] if hash_ref was passed then hash_ref of new values else just new value
sub unshift_block_res
{
	my $self = shift;
	my ($block, $blockf, $val, $res);

	unless ($_[0]) {
		&_my_error('required parameter missed');
	}
	
	$res = {};
	
	if (ref($_[0]) eq 'HASH') {
		foreach $block(keys(%{$_[0]})) {
			$val = $_[0]->{$block};
			$blockf = '!' . $block;
			
			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'hparse'}->{$blockf} =
				    $val->parse . $self->{'hparse'}->{$blockf};
			} else {
				$self->{'hparse'}->{$blockf} =
				    $val . $self->{'hparse'}->{$blockf};
			}
			
			$res->{$block} = $self->{'hparse'}->{$blockf};
		}
	} elsif (!ref($_[0])) {
		($block, $val) = @_;
		$blockf = '!' . $block;
		
		if (UNIVERSAL::isa($val, 'Parse::Plain')) {
			$self->{'hparse'}->{$blockf} =
			    $val->parse . $self->{'hparse'}->{$blockf};
		} else {
			$self->{'hparse'}->{$blockf} =
			    $val . $self->{'hparse'}->{$blockf};
		}
		
		$res->{$block} = $self->{'hparse'}->{$blockf};
	} else {
		&_my_error('unsupported argument type: ' . ref($_[0]));
	}
	
	return $res;
}


# resets blocks sources to it's original values (as in template)
# [I] array_ref or list with block names
# [O] hash_ref of original block values
sub reset_block_src
{
	my $self = shift;
	my ($res, $block, @arr);

	@arr = @_;
	$block = shift @arr;
	unless ($block) {
		&_my_error('required parameter missed');
	}
	
	$res = {};
	
	if (ref($block) eq 'ARRAY') {
		foreach (@$block) {
			$self->{'hblock'}->{$_} = $self->{'oblock'}->{$_};
			$res->{$_} = $self->{'hblock'}->{$_};
		}
	} elsif (!ref($block)) {
		while ($block) {
			$self->{'hblock'}->{$block} =
			    $self->{'oblock'}->{$block};
			$res->{$block} = $self->{'hblock'}->{$block};
			$block = shift @arr;
		}
	} else {
		&_my_error('unsupported argument type: ' . ref($arr[0]));
	}

	return $res;
}


# reset source values for all blocks
# [I] none
# [O] hash_ref of original block values
sub reset_block_src_all
{
	my $self = shift;
	
	return $self->reset_block_src($self->enum_blocks());
}


# get original block values (as in the source template)
# [I] either list or array_ref of block names
# [O] hash_ref of original block values
sub get_oblock
{
	my $self = shift;
	my (@arr) = @_;
	my ($res);
	
	$res = {};

	unless ($arr[0]) {
		&_my_error('required parameter missed');
	}
	
	if (ref($arr[0]) eq 'ARRAY') {
		foreach (@{$arr[0]}) {
			$res->{$_} = $self->{'oblock'}->{$_};
		}
	} elsif (!ref($arr[0])) {
		foreach (@arr) {
			$res->{$_} = $self->{'oblock'}->{$_};
		}
	} else {
		&_my_error('unsupported argument type: ' . ref($arr[0]));
	}

	return $res;
}


# enumarate all blocks in template
# [I] none
# [O] array_ref with block names
sub enum_blocks
{
	my $self = shift;
	my ($res);
	
	$res = [];
	
	foreach (keys %{$self->{'oblock'}}) {
		push @$res, $_;
	}
	
	return $res;
}


# set self->{'text'}, don't use unless absolutely sure
# about what you are doing
# [I] new value to set
# [O] new value
sub set_text
{
	my ($self, $val) = @_;

	if (UNIVERSAL::isa($val, 'Parse::Plain')) {
		$self->{'text'} = $val->parse;
	} else {
		$self->{'text'} = $val;
	}
	
	return $self->{'text'};
}


# return self->{'text'}
# [I] none
# [O] $self->{'text'}
sub get_text
{
	my $self = shift;

	return $self->{'text'};
}


# set parsing result to specified value; DON'T use unless you are
# absolutely sure about what you're doing
# [I] new value for result
# [O] new value for result
sub set_parsed
{
	my ($self, $val) = @_;
	
	if (UNIVERSAL::isa($val, 'Parse::Plain')) {
		$self->{'parsed'} = $val->parse;
	} else {
		$self->{'parsed'} = $val;
	}
	
	return $self->{'parsed'};
}


# global tags accessor, sets or gets tags that are global for any block
# [I] either ($gtag, $val) pair or 
#     $hash_ref containing { $gtag => $val } pairs or
#     scalar $gtag to get it's value or
#     arrayref [ $gtag1, $gtag2, ... ] to get their values
# [O] hash_ref containing { $gtag => $new_value, ... }
sub gtag
{
	my $self = shift;
	my ($gtag, $val, $res, @arr);
	
	@arr = @_;
	unless ($arr[0]) {
		&_my_error('required parameter missed');
	}

	$res = {};
	
	if (ref($arr[0]) eq 'ARRAY') { # get gtag values
		foreach $gtag(@{$arr[0]}) {
			$res->{$gtag} = $self->{'gparse'}->{$gtag};
		}
	} elsif (ref($arr[0]) eq 'HASH') { # set gtags from hash_ref
		foreach $gtag(keys(%{$arr[0]})) {
			$val = $arr[0]->{$gtag};
			
			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'gparse'}->{$gtag} = $val->parse;
			} else {
				$self->{'gparse'}->{$gtag} = $val;
			}
			
			$res->{$gtag} = $self->{'gparse'}->{$gtag};
		}
	} elsif (!ref($arr[0])) { # no refs, for backwards-compatibility
		($gtag, $val) = @arr;
		
		if ($val) {
			if (UNIVERSAL::isa($val, 'Parse::Plain')) {
				$self->{'gparse'}->{$gtag} = $val->parse;
			} else {
				$self->{'gparse'}->{$gtag} = $val;
			}
		}
		
		$res->{$gtag} = $self->{'gparse'}->{$gtag};
	} else {
		&_my_error('unsupported argument type: ' . ref($arr[0]));
	}
	
	return $res;
}


# set callbacks
# [I] either hashref of { 'name' => {coderef}, ... }
#     or pair name, coderef to callback
# [O] none
sub callback
{
	my $self = shift;
	my (@arr, $tmp);

	@arr = @_;
	
	if (ref($arr[0]) eq 'HASH') { # hashref
		foreach $tmp(keys(%{$arr[0]})) {
			&_my_error('colons not allowed in callback tagnames: '
			    . $tmp) if ($tmp =~ /:/);
			    
			$self->{'cback'}->{$tmp} = $arr[0]->{$tmp};
		}
	} elsif (!ref($arr[0])) { # no refs
			&_my_error('colons not allowed in callback tagname: '
			    . $arr[0]) if ($arr[0] =~ /:/);

			$self->{'cback'}->{$arr[0]} = $arr[1];
	} else {
		&_my_error('unsupported argument type: ' . ref($arr[0]));
	}
	
	return;
}


# parse template or block
# [I] if none parses outermost block, if $block param is specified then
#     block is parsed and $hparse{$block} is appended with result; if also 
#     $href hash reference is specified the block is parsed using $href; if 
#     also $usehparse is TRUE, then block will be parsed using
#     'hparse' hash as well.
# [O] parsing results
sub parse
{
	my ($self, $block, $href, $usehparse) = @_;
	my ($res, $lref, $cback, $W);
	
	$lref = {};
	
	if ($href) {
		foreach (keys %$href) {
			if (UNIVERSAL::isa($href->{$_}, 'Parse::Plain')) {
				$lref->{$_} = $href->{$_}->parse;
			} else {			
				$lref->{$_} = $href->{$_};
			}
		}
	}
	
	if (!$href) {
		foreach (keys %{$self->{'hparse'}}) {
			$lref->{$_} = $self->{'hparse'}->{$_};
		}		
	} elsif ($usehparse) {
		foreach (keys %{$self->{'hparse'}}) {
			$lref->{$_} = $self->{'hparse'}->{$_}
				unless (defined $lref->{$_});
		}
	}

	foreach (keys %{$self->{'gparse'}}) {
		$lref->{$_} = $self->{'gparse'}->{$_}
			unless (defined $lref->{$_});
		# gparse has least priority
	}		

	$W = $^W;
	$^W = 0;
	if ($block) {
		$res = $self->{'hblock'}->{$block};
		foreach $cback(keys %{$self->{'cback'}}) {
			$res =~ s/%{2}($cback)\:([\w\d\.\(\)\*\&\^\$\\\/:;,_-]*)%{2}/&{$self->{'cback'}->{$1}}($2)/ge
				if (ref($self->{'cback'}->{$cback}) eq 'CODE');		}
		$res =~ s/%{2}([\w\d\.\(\)\*\&\^\$\\\/:;,_-]+)%{2}/$lref->{$1}/g;
		$res =~ s/%{2}(\![\w\d\.\(\)\*\&\^\$\\\/:;,_-]+)%{2}/$self->{'hparse'}->{$1}/g;
		$self->{'hparse'}->{'!' . $block} .= $res;
	} else {
		if (defined $self->{'parsed'}) {
			$^W = $W;
			return $self->{'parsed'};
		}
		$self->{'parsed'} = $self->{'text'};
		foreach $cback(keys %{$self->{'cback'}}) {
			$self->{'parsed'} =~ s/%{2}($cback)\:([\w\d\.\(\)\*\&\^\$\\\/:;,_-]*)%{2}/&{$self->{'cback'}->{$1}}($2)/ge
				if (ref($self->{'cback'}->{$cback}) eq 'CODE');
		}
		$self->{'parsed'} =~ s/%{2}([\w\d\.\(\)\*\&\^\$\\\/:;,_-]+)%{2}/$lref->{$1}/g;
		$self->{'parsed'} =~ s/%{2}(\![\w\d\.\(\)\*\&\^\$\\\/:;,_-]+)%{2}/$self->{'hparse'}->{$1}/g;
		$res = $self->{'parsed'};
	}
	$^W = $W;
		    
	return $res;
}


# reset parsed blocks
# [I] none to reset outermost block
#     array or arrayref of block names to reset blocks 
#     to current values of block sources
# [O] previous value of text or hash_ref with previous
#     values of blocks
sub unparse
{
	my $self = shift;
	my ($tmp, $key, $keyf);

	if ($#_ == -1) {
		$tmp = $self->{'parsed'};
		$self->{'parsed'} = undef;
	} else {
		$tmp = {};
		
		if (ref($_[0]) eq 'ARRAY') {
			foreach $key(@{$_[0]}) {
				$keyf = '!' . $key;
				
				if (defined $self->{'hparse'}->{$keyf}) {
					$tmp->{$key} =
					    $self->{'hparse'}->{$keyf};
					$self->{'hparse'}->{$keyf} = undef;
				}
			}
		} elsif (!ref($_[0])) {
			while (@_) {
				$key = shift;
				$keyf = '!' . $key;
				
				if (defined $self->{'hparse'}->{$keyf}) {
					$tmp->{$key} =
					    $self->{'hparse'}->{$keyf};
					$self->{'hparse'}->{$keyf} = undef;
				}
			}
		} else {
			&_my_error('unsupported argument type: ' . ref($_[0]));
		}
	}
	
	return $tmp;
}


# unparse() all blocks including outermost
# [I] none
# [O] hash_ref with previous values of blocks except outermost (text)
sub unparse_all
{
	my $self = shift;
	
	$self->unparse();
	return $self->unparse($self->enum_blocks());
}


# print parsing results, if template already parsed prints it
# otherwise parse template first
# [I] none
# [O] parsing results
sub output
{
	my $self = shift;

	print $self->parse;

	return $self->{'parsed'};
}


# callback for including templates recursively via %%include:filename.tmpl%%
# not method, not exported
# [I] filename
# [O] file contents as scalar
sub _include_file
{
	my $arg = shift;
	my ($cnt);
	
	return '' unless ($arg);
	
	$cnt = join('', @{&_load_file($arg)});
	$cnt =~ s/%{2}INCLUDE:([\w\d\.\(\)\&\^\$\\\/;,_-]+)%{2}/&_include_file($1)/ge;
	
	return $cnt;
}


# read file from disk, not method, not exported
# [I] filename
# [O] reference to array of lines
sub _load_file
{
	my $filename = shift;
	my ($lcnt, @lines);

	unless (-f $filename) {
		&_my_error("template not found: $filename");
	}

	unless (-r $filename) {
		&_my_error("template not readable: $filename");
	}
	
	$lcnt = 0;
	while (1) {
		if (open(TMPL, '<' . $filename)) {
			@lines = <TMPL>;
			close(TMPL);
			last;
		} elsif ($lcnt >= $lcnt_max) {
			&_my_error("loop counter ($lcnt_max) exceeded " .
			           "while opening file $filename");
		} else {
			$lcnt++;
			sleep $ssec if ($ssec);
		}
	}
	
	return \@lines;
}


# die with specified message.
# [I] error_message
# [O] none
sub _my_error
{
	my $msg = shift;
	my @caller;

	@caller = caller(0);

	croak "Parse::Plain $caller[1]:$caller[2] in $caller[3]: $msg";

	return;
}


1;


__END__


=head1 NAME

 Parse::Plain - template parsing engine (version 3.03)


=head1 SYNOPSIS

 # in user's code
 use Parse::Plain;
 
 my $t = new Parse::Plain('/path/to/filename.tmpl');
 my $t = new Parse::Plain('/path/to/filename.tmpl', 1, 2);
 
 $t->set_tag('mytag', 'value');          # %%mytag%% set to value
 $t->push_tag('mytag', '-pushed');       # %%mytag%% set to value-pushed
 $t->set_tag({'mytag' => 'value'});      # %%mytag%% set to value
 $t->unshift_tag('mytag', 'unshifted-'); # %%mytag%% set to unshifted-value
 
 # set a callback for tags like %%url:http://host.com/doc.html%%
 $t->callback('url', sub { return SomePackage::GetUrl($_[0]); });
 
 $t->push_block_src('myblock', 'some text to append to the block source');
 $t->unshift_block_res('myblock', 'some text to prepend to the block result');
 
 $t->parse('myblock', {'blocktag' => 'block value'});  # parse block
 $t->parse('myblock', {'blocktag' => 'another block value'});
 
 $t->parse;   # parse whole document
 $t->output;  # output parsed results to STDOUT
 
 $t->unparse; # reset parsed result to original template
 

=head1 DESCRIPTION

Parse::Plain is a Perl module for parsing text-based templates. It was
designed to use with HTML, XHTML, XML and other markup languages
but usually can be used with arbitrary text files as well.

Basic constructions in the templates are tags and blocks. Both must
have names. Valid symbols for using in tag and block names are digits,
latin letters, underscores, dashes, dots, semicolons, colons, commas,
parentheses, asterisks, ampersands, slashes and caret symbols. An exclamation
mark ('B<!>') has special meaning and will be discussed later. All names
are case sensitive.

Tag is a string in form B<%%tagname%%>. There may be any number of tags
with the same name and any number of different tags in the template.

Block is a construction that begins with line

  {{ blockname

and ends with symbols B<}}>

Block-start element must be on separate line. There may be no other
symbols from the beginning of line to the block-end element. However
you may have other text (except block-start) after block-end on the
same line (same as having those symbols on next line).
Symbols between block-start and block-end form block body.
Blocks are especially useful for iterative elements like table rows.
Blocks can be nested and tags are allowed within block body.

There is also a special form of tag names. Let's say you have a block
named I<myblock>. Then in the template you can use tags named B<%%!myblock%%>
and they will be substituted to current value of I<myblock>.

You can also hide block from place in template where it is defined
by prepending B<!> to it's name. You'll still be able to use this
block with appropriate tag names (with 'B<!>'). See L</EXAMPLES> section.

There is a difference between source block and result block (as used
in some method names). The source block is a chunk of text that is
exactly as it appears in source template unless you have changed it
using methods L</block_src>, L</unshift_block_src>, L</push_block_src>.
The result block is a chunk of text that appears in the output and
affected by calls to L</parse> function on this block or may be
modified with L</block_res>, L</unshift_block_res>, L</push_block_res>
methods as well. See description of these methods elsewhere in
this document. To illustrate the difference:

  
  # source block named 'b' in template:
  # {{ b
  # -%%Y%%-
  # }}
  $val = $t->block_src('b');       # $val eq '-%%Y%%-'
  $val = $t->block_res('b');       # $val == undef
  
  # now let's modify source block
  $t->push_block_src('b', 'Z|');   # -%%Y%%-Z|
  $t->unshift_block_src('b', 'X'); # X-%%Y%%-Z|
  
  $val = $t->block_src('b');       # $val eq 'X-%%Y%%-Z|'
  $val = $t->block_res('b');       # $val == undef
  
  # now let's modify result block
  $t->parse('b', '1');             # result block: X-1-Z|
  $t->parse('b', '2');             # result block: X-1-Z|X-2-Z|
  $t->unshift_block_res('b', '|'); # result block: |X-1-Z|X-2-Z|
  
  $val = $t->block_src('b');       # $val eq 'X-%%Y%%-Z|'
  $val = $t->block_res('b');       # $val eq '|X-1-Z|X-2-Z|'
  


=head1 METHODS

=head2 new

The constructor. The first parameter (mandatory) is a path to template
file. Template file must exist and be readable. If file cannot be read
several attempts will be made (by default 5 attemts with 1 second interval
between attemts). You can optionally change these values by passing
additional paramteres to constructor ($lcnt_max and $ssec are respectively
number of maximum retries and number of seconds to sleep between retries).
If template cannot be read script dies.


=head2 set_tag

This method allows you to set tag values. There are two prototypes for
this method. You may either pass a hash reference containing any number
of tagname =E<gt> value pairs or just pass two scalars (tagname and value).

Examples:

 $t->set_tag('mytag', 'value'); # set %%mytag%% to 'value'
 $t->set_tag({'mytag' => 'value', 'othertag' => 'otherval');

Values may be another instances of Parse::Plain. In this case L</parse>
method will be called on value object. Returned value is a hash
reference containing tag_name =E<gt> new_value pairs.


=head2 get_tag

Get current values of tags at. Parameter may be either
array reference containing tag names or a list with tag names but not
both intermixed. Returned value is a hash reference containing
tag_name =E<gt> value pairs. Using array reference as parameter
is recommended.


=head2 push_tag

Append supplied values to current values of tags. There are two
prototypes for this method. You may either pass a hash reference containing
any number of tagname =E<gt> value pairs or just pass two scalars (tagname
and value). Values may be another instances of Parse::Plain. In this case
L</parse> method will be called on value object. Returned value is a hash
reference containing tag_name =E<gt> new_value pairs.


=head2 unshift_tag

Prepend supplied values to current values of tags. There are two
prototypes for this method. You may either pass a hash reference containing
any number of tagname =E<gt> value pairs or just pass two scalars (tagname
and value). Values may be another instances of Parse::Plain. In this case
L</parse> method will be called on value object. Returned value is a hash
reference containing tag_name =E<gt> new_value pairs.


=head2 block

Block accessor, allows to set or get values of specific blocks.
This method exists for backwards-compatibility and accepts as
input parameter only list (blockname, value) to set blockname to value
or just scalar blockname to get it's value. You should call
L</block_src> or L</block_res> methods instead. This method acts
exactly like L</block_src> if the block being accessed hasn't been parsed
yet (this means that you haven't called yet L</parse> method for this
block from the object creation moment or after L</unparse> call for
this block). Elsewise this method acts like L</block_res>.


=head2 block_src

Block source accessor, allows to set or get values of sources of
specific blocks. Arguments can be either scalar block name
(to get it's value) or a pair of scalars ($block, $val) to set
$block to $val or an array reference with block names to get their
values or hash reference with { $block =E<gt> $val, ... } pairs
to set new values. Values may be another instances of Parse::Plain.
In this case L</parse> method will be called on value object.
Returned value is a hash reference containing
block_name =E<gt> value pairs.


=head2 block_res

Block result accessor, allows to set or get values of results of
specific blocks. Arguments can be either scalar block name
(to get it's value) or a pair of scalars ($block, $val) to set 
$block to $val or an array reference with block names to get their
values or hash reference with { $block =E<gt> $val, ... } pairs
to set new values. Values may be another instances of Parse::Plain.
In this case L</parse> method will be called on value object.
Returned value is a hash reference containing 
block_name =E<gt> value pairs.


=head2 push_block

Append supplied values to blocks. This method exists for 
backwards-compatibility and accepts only list with blockname, value
as input parameter. You should call L</push_block_src> or
L</push_block_res> methods instead. This method acts exactly
like L</push_block_src> if the block being accessed isn't parsed yet
(this means that you haven't called yet L</parse> method for
this block from the object creation moment or after L</unparse>
call for this block). Elsewise this method acts like L</push_block_res>.


=head2 push_block_src

Append supplied values to block sources. There are two prototypes for this
method. You may either pass a hash reference containing any number of
block =E<gt> value pairs or just pass two scalars (blockname and value).
Values may be another instances of Parse::Plain. In this case L</parse> method
will be called on value object. Returned value is a hash reference containing
block_name =E<gt> new_value pairs.


=head2 push_block_res

Append supplied values to block results. There are two prototypes for this
method. You may either pass a hash reference containing any number of
block =E<gt> value pairs or just pass two scalars (blockname and value).
Values may be another instances of Parse::Plain. In this case L</parse> method
will be called on value object. Returned value is a hash reference containing
block_name =E<gt> new_value pairs.


=head2 unshift_block

Prepend supplied values to blocks. TThis method exists for
backwards-compatibility and accepts only list with blockname, value
as input parameter. You should call L</unshift_block_src> or
L</unshift_block_res> methods instead. This method acts exactly
like L</unshift_block_src> if the block being accessed isn't parsed yet
(this means that you haven't called yet L</parse> method for 
this block from the object creation moment or after L</unparse>
call for this block). Elsewise this method acts like L</unshift_block_res>.


=head2 unshift_block_src

Prepend supplied values to block sources. There are two prototypes for this
method. You may either pass a hash reference containing any number of
block =E<gt> value pairs or just pass two scalars (blockname and value).
Values may be another instances of Parse::Plain. In this case L</parse> method
will be called on value object. Returned value is a hash reference containing
block_name =E<gt> new_value pairs.


=head2 unshift_block_res

Prepend supplied values to block results. There are two prototypes for this
method. You may either pass a hash reference containing any number of
block =E<gt> value pairs or just pass two scalars (blockname and value).
Values may be another instances of Parse::Plain. In this case L</parse> method
will be called on value object. Returned value is a hash reference containing
block_name =E<gt> new_value pairs.


=head2 reset_block_src

Resets block source values. The block source value may be changed
invoking L</block>, L</block_src>, L</push_block>, L</push_block_src>,
L</unshift_block>, L</unshift_block_src>, methods.
This method allows you to restore block sources to it's original
values from the source template. Parameter is either array reference or list
containing block names to be restored. Returned value is a hash reference
containing block_name =E<gt> original_value pairs. Unlike L</unparse>
method this one changes block sources, not results.


=head2 reset_block_src_all

Calls L</reset_block_src> for each block within template excpet outermost
one (I<text>).


=head2 get_oblock

Get original block source values. The block source value may be changed
invoking L</block>, L</block_src>, L</push_block>, L</push_block_src>,
L</unshift_block>, L</unshift_block_src>, methods.
This method returns original values of block sources from the template.
Unlike L</reset_block> this method doesn't change current value of blocks.
Parameter is either array reference or list containing block names to be
restored. Returned value is a hash reference containing
block_name =E<gt> original_value pairs.


=head2 enum_blocks

Enumerate all blocks found in template. Takes no input. Return value is
an array reference containing block names. Block names order is undefined.


=head2 set_text

Set I<text> to argument. I<text> is a special member containing outermost
block source. Argument can be another instance of Parse::Plain. In this
case L</parse> method will be called on value object. Returns new value of
I<text>.

B<WARNING:> Use with care and only when you are absolutely sure about
what you are doing!


=head2 get_text

Returns current value of text. I<text> is a special member containing
outermost block source.


=head2 set_parsed

Set I<parsed> to argument. I<parsed> is a special member containing undef
if outermost block has not been parsed yet or parsing result elsewise.
Argument can be another instance of Parse::Plain. In this case L</parse>
method will be called on value object. Returns new value of I<parsed>.

B<WARNING:> Use with care and only when you are absolutely sure about
what you are doing!


=head2 gtag

Global tag hash accessor. You may optionally set global tags that will
be used in all blocks including outermost. These global tags have lesser
priority then those set by L</set_tag> method or L</parse> arguments.
Arguments can be either scalar tagname (to get it's value) or a
pair of scalars (gtagname, val) to set gtagname to val or an array
reference with tag names to get their values or hash reference with
{ $tag =E<gt> $val, ... } pairs to set new values. Values may be another
instances of Parse::Plain. In this case L</parse> method will be called
on value object. Returned value is a hash reference containing 
gtag_name =E<gt> value pairs. Pass undef as value to remove global tag.


=head2 callback

Set callbacks. A callback allows you to have special tags in the form:

  %%tagname:param%%

For each such tag specified callback function will be called with
I<param>. Arguments to this method may be either pair of tagname,
code reference or a hash reference containing pairs:
{ tagname => coderef, ... }. There is no return values. Pass undef
as a coderef to remove given callback. You may not use colon in I<tagname>.
There is one predefined callback that allows you to include another
templates within current.  to do that just use tag %%INCLUDE:/path/to/file%%.
In the file included all %%INCLUDE:%% tags will be processed recursively.


=head2 parse

Parse chunk of text using defined tags and blocks. If called without
parameters the outermost block is parsed using tags and blocks defined so far.
There are three optional parameters: I<$blockname>, I<$hashref>,
I<$useglobalhash>. First specifies block name to be parsed. You must call
L</parse> function on each block in your template at least once or the
block will be ignored. You must also call L</parse> function for each
iteration of the block. See L</EXAMPLES> section elsewhere in this document.
You can also provide a referense to hash of tags used for parsing
current block. For example:

  $t->parse('blockname', {'tag1' => 'val1', 'tag2' => 'val2'});

If you don't specify this hash reference hash filled by
L</set_tag> functions wiil be used instead. You can also use both
hashes for parsing your block by setting third parameter to true.
Returns parsing results (either text or block).


=head2 unparse

Reset block result values. This method allows you to reset some block
results or the whole I<text> (outermost block) so that you could
L</parse> it again from the scratch. Unlike L</reset_block_src> this
method only resets block result not source. If no input argument passed
resets I<text> (outermost block). To reset specific blocks pass an
array reference or list with blocknames. Returns hash reference with
pairs: { 'blockname' => 'old_block_result_value', ... }.


=head2 unparse_all

Calls L</unparse> method for each block including outermost (I<text>).
Takes no input. Returns hash reference with pairs:
{ 'blockname' => 'old_block_result_value', ... } for each
block except outermost one.


=head2 output

Print parsing results to STDOUT. If text hasn't been parsed yet calls
L</parse> method before. Returns parsed results.


=head1 TIPS AND CAVEATS

=over 4

=item *
Names are case sensitive.

=item *
Non-defined tags and blocks are moved off from the result.

=item *
Block start and end elements may be padded with whitespaces or tabs
for better readability.

=item *
Always parse innermost block before outer blocks or you may get mess.

=item *
Block start and end elements don't insert newline. Consider
template fragment:

       He
  {{ myblock
ll
  }}
o

One will be parsed to

       Hello

line. However since version 3.00 you could also use such template:

       He
  {{ myblock
ll
  }}o

to get the same results as in the previous example.

=item *
You may not use colons in callback tagnames.

=item *
Obviously, it's not a very good idea to use this module for 
binary templates. ;-)

=back


=head1 EXAMPLES

=head2 Using blocks

B<Template (template.tmpl):>

 <table>
 <th>%%name%%</th>

 {{ block1
         <tr><td>%%tag1%%</td><td>%%tag2%%</td></tr>

 }}
 </table>

B<Code:>

 use Parse::Plain;
 $t = new Parse::Plain 'template.tmpl';
 $t->set_tag('name', "My table");
 $t->parse('block1', {'tag1' => '01', 'tag2' => '02'});
 $t->parse('block1', {'tag1' => '03', 'tag2' => '04'}); 
 $t->output;

B<Output:>

 <table>
 <th>My table</th>
         <tr><td>01</td><td>02</td></tr>
         <tr><td>03</td><td>04</td></tr>
 </table>


=head2 Using hidden blocks

B<Template (template.tmpl):>

 <table %%border%%>
 
 {{ myblock
         <tr><td %%!hidden%%>%%value%%</td></tr>
 }} </table>
 
 {{ !hidden
 class="%%class%%" align="%%align%%"
 }}

B<Code:>

 use Parse::Plain;
 $t = new Parse::Plain 'template.tmpl';
 $t->parse('hidden', {'class' => 'red', 'align' => 'right'});
 $t->parse('myblock', {'value' => '01'});
 $t->parse('myblock', {'value' => '02'});
 # we didn't define %%border%% tag
 $t->output;

B<Output:>

 <table >
         <tr><td  class="red" align="right">01</td></tr>
         <tr><td  class="red" align="right">02</td></tr>
 </table>


=head2 Including files

B<Template 1 (template1.tmpl):>

 Some text %%INCLUDE:template2.tmpl%%!

B<Template 2 (template2.tmpl):>

 >>>%%INCLUDE:template3.tmpl%%<<<

B<Template 3 (template3.tmpl):>

 0%%tag%%0

B<Code:>

 use Parse::Plain;
 $t = new Parse::Plain 'template1.tmpl';
 $t->set_tag('tag', '!!!');
 $t->output;

B<Output:>

 Some text >>>0!!!0<<<


=head1 BUGS

If you define a hidden block (with 'B<!>') and a nested block inside it
and use then tag to show the hidden (outer) block behavior is undefined.

You have no way to change tag / block delimiters. See FAQ document
provided with distribution for more details.

If you have found any other bugs or have any comments / wishes don't
hesitate to contact me.


=head1 AUTHOR

  Andrew Alexandre Novikov.
  mailto: perl@an.kiev.ua
  www: http://www.an.kiev.ua/
  icq: 7593332


=head1 COPYRIGHTS

(C) Copyright 2003-2004 by Andrew A Novikov http://www.an.kiev.ua/

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut


package Parse::JCONF;

use strict;
use Carp;
use Parse::JCONF::Boolean qw(TRUE FALSE);
use Parse::JCONF::Error;

our $VERSION = '0.05';
our $HashClass = 'Tie::IxHash';

sub new {
	my ($class, %opts) = @_;
	
	my $self = {
		autodie    => delete $opts{autodie},
		keep_order => delete $opts{keep_order}
	};
	
	%opts and croak 'unrecognized options: ', join(', ', keys %opts);
	
	if ($self->{keep_order}) {
		eval "require $HashClass"
			or croak "you need to install $HashClass for `keep_order' option";
	}
	
	bless $self, $class;
}

sub parse {
	my ($self, $data) = @_;
	
	$self->_err(undef);
	
	my %rv;
	if ($self->{keep_order}) {
		tie %rv, $HashClass;
	}
	
	my $offset = 0;
	my $line = 1;
	my $len = length $data;
	
	while ($offset < $len && $self->_parse_space_and_comments(\$data, \$offset, \$line)) {
		$self->_parse_bareword(\$data, \$offset, \$line, \my $key)
			or return;
		$self->_parse_eq_sign(\$data, \$offset, \$line)
			or return;
		$self->_parse_value(\$data, \$offset, \$line, \my $val)
			or return;
		$self->_parse_delim(undef, \$data, \$offset, \$line)
			or return;
		
		$rv{$key} = $val;
	}
	
	return \%rv;
}

sub _parse_space_and_comments {
	my ($self, $data_ref, $offset_ref, $line_ref) = @_;
	
	pos($$data_ref) = $$offset_ref;
	
	while ($$data_ref =~ /\G(?:(\n+)|\s|#[^\n]*)/gc) {
		if (defined $1) {
			$$line_ref += length $1;
		}
	}
	
	$$offset_ref = pos($$data_ref);
	return $$offset_ref < length $$data_ref;
}

sub _parse_bareword {
	my ($self, $data_ref, $offset_ref, $line_ref, $rv_ref) = @_;
	
	$self->_parse_space_and_comments($data_ref, $offset_ref, $line_ref)
		or return $self->_err(
			Parser => "Unexpected end of data, expected bareword at line $$line_ref"
		);
	
	pos($$data_ref) = $$offset_ref;
	
	$$data_ref =~ /\G(\w+)/g
		or return $self->_err(
			Parser => "Expected bareword at line $$line_ref:\n" . _parser_msg($data_ref, $$offset_ref)
		);
	
	$$rv_ref = $1;
	$$offset_ref = pos($$data_ref);
	
	1;
}

sub _parse_bareword_or_string {
	my ($self, $data_ref, $offset_ref, $line_ref, $rv_ref) = @_;
	
	$self->_parse_space_and_comments($data_ref, $offset_ref, $line_ref)
		or return $self->_err(
			Parser => "Unexpected end of data, expected bareword or string at line $$line_ref"
		);
	
	pos($$data_ref) = $$offset_ref;
	
	if (substr($$data_ref, $$offset_ref, 1) eq '"') {
		$self->_parse_string($data_ref, $offset_ref, $line_ref, $rv_ref);
	}
	else {
		$self->_parse_bareword($data_ref, $offset_ref, $line_ref, $rv_ref);
	}
}

sub _parse_delim {
	my ($self, $ok_if, $data_ref, $offset_ref, $line_ref) = @_;
	
	my $line_was = $$line_ref;
	my $has_data = $self->_parse_space_and_comments($data_ref, $offset_ref, $line_ref);
	
	if ($has_data && substr($$data_ref, $$offset_ref, 1) eq ',') {
		# comma delimiter
		$$offset_ref++;
		return 1;
	}
	
	if ($line_was != $$line_ref) {
		# newline delimiter
		return 1;
	}
	
	if (!defined $ok_if && !$has_data) {
		# we may not have delimiter at the end of data
		return 1;
	}
	
	if ($has_data && substr($$data_ref, $$offset_ref, 1) eq $ok_if) {
		# we may not have delimiter at the end of object, array
		return 1;
	}
	
	$self->_err(
		Parser => "Expected delimiter `,' at line $$line_ref:\n" . _parser_msg($data_ref, $$offset_ref)
	);
}

sub _parse_eq_sign {
	my ($self, $data_ref, $offset_ref, $line_ref) = @_;
	
	$self->_parse_space_and_comments($data_ref, $offset_ref, $line_ref)
		or return $self->_err(
			Parser => "Unexpected end of data, expected equals sign `=' at line $$line_ref"
		);
	
	unless (substr($$data_ref, $$offset_ref, 1) eq '=') {
		return $self->_err(
			Parser => "Expected equals sign `=' at line $$line_ref:\n" . _parser_msg($data_ref, $$offset_ref)
		);
	}
	
	$$offset_ref++;
	1;
}

sub _parse_value {
	my ($self, $data_ref, $offset_ref, $line_ref, $rv_ref) = @_;
	
	$self->_parse_space_and_comments($data_ref, $offset_ref, $line_ref)
		or return $self->_err(
			Parser => "Unexpected end of data, expected value at line $$line_ref"
		);
	
	my $c = substr($$data_ref, $$offset_ref, 1);
	if ($c eq '{') {
		$self->_parse_object($data_ref, $offset_ref, $line_ref, $rv_ref);
	}
	elsif ($c eq '[') {
		$self->_parse_array($data_ref, $offset_ref, $line_ref, $rv_ref);
	}
	elsif ($c eq 't') {
		$self->_parse_constant('true', TRUE, $data_ref, $offset_ref, $line_ref, $rv_ref);
	}
	elsif ($c eq 'f') {
		$self->_parse_constant('false', FALSE, $data_ref, $offset_ref, $line_ref, $rv_ref);
	}
	elsif ($c eq 'n') {
		$self->_parse_constant('null', undef, $data_ref, $offset_ref, $line_ref, $rv_ref);
	}
	elsif ($c eq '"') {
		$self->_parse_string($data_ref, $offset_ref, $line_ref, $rv_ref);
	}
	elsif ($c =~ /-|\d/) {
		$self->_parse_number($data_ref, $offset_ref, $line_ref, $rv_ref);
	}
	else {
		$self->_err(
			Parser => "Unexpected value, expected array/object/string/number/true/false/null at line $$line_ref:\n" . 
						_parser_msg($data_ref, $$offset_ref)
		);
	}
}

sub _parse_constant {
	my ($self, $constant, $constant_val, $data_ref, $offset_ref, $line_ref, $rv_ref) = @_;
	
	my $len = length $constant;
	substr($$data_ref, $$offset_ref, $len) eq $constant && 
	($len + $$offset_ref == length $$data_ref || substr($$data_ref, $$offset_ref+$len, 1) =~ /[\s,\]}]/)
		or return $self->_err(
			Parser => "Unexpected value, expected `$constant' at line $$line_ref:\n" .
						_parser_msg($data_ref, $$offset_ref)
		);
	
	$$offset_ref += $len;
	$$rv_ref = $constant_val;
	
	1;
}

sub _parse_number {
	my ($self, $data_ref, $offset_ref, $line_ref, $rv_ref) = @_;
	
	$$data_ref =~ /\G(-?(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+-]?\d+)?)/gc
		or return $self->_err(
			Parser => "Unexpected value, expected number at line $$line_ref:\n" .
						_parser_msg($data_ref, $$offset_ref)
		);
	
	my $num = $1;
	$$rv_ref = $num + 0; # WTF: $1 + 0 is string if we can believe Data::Dumper, so use temp var
	$$offset_ref = pos($$data_ref);
	
	1;
}

sub _parse_array {
	my ($self, $data_ref, $offset_ref, $line_ref, $rv_ref) = @_;
	
	$$offset_ref++;
	my @rv;
	
	while (1) {
		$self->_parse_space_and_comments($data_ref, $offset_ref, $line_ref)
			or return $self->_err(
				Parser => "Unexpected end of data, expected end of array `]' at line $$line_ref"
			);
			
		substr($$data_ref, $$offset_ref, 1) eq ']'
			and last;
		$self->_parse_value($data_ref, $offset_ref, $line_ref, \my $val)
			or return;
		$self->_parse_delim(']', $data_ref, $offset_ref, $line_ref)
			or return;
		
		push @rv, $val;
	}
	
	$$rv_ref = \@rv;
	$$offset_ref++;
	
	1;
}

sub _parse_object {
	my ($self, $data_ref, $offset_ref, $line_ref, $rv_ref) = @_;
	
	$$offset_ref++;
	my %rv;
	if ($self->{keep_order}) {
		tie %rv, $HashClass;
	}
	
	while (1) {
		$self->_parse_space_and_comments($data_ref, $offset_ref, $line_ref)
			or return $self->_err(
				Parser => "Unexpected end of data, expected end of object `}' at line $$line_ref"
			);
		
		substr($$data_ref, $$offset_ref, 1) eq '}'
			and last;
		$self->_parse_bareword_or_string($data_ref, $offset_ref, $line_ref, \my $key)
			or return;
		$self->_parse_colon_sign($data_ref, $offset_ref, $line_ref)
			or return;
		$self->_parse_value($data_ref, $offset_ref, $line_ref, \my $val)
			or return;
		$self->_parse_delim('}', $data_ref, $offset_ref, $line_ref)
			or return;
		
		$rv{$key} = $val;
	}
	
	$$rv_ref = \%rv;
	$$offset_ref++;
	
	1;
}

sub _parse_colon_sign {
	my ($self, $data_ref, $offset_ref, $line_ref) = @_;
	
	$self->_parse_space_and_comments($data_ref, $offset_ref, $line_ref)
		or return $self->_err(
			Parser => "Unexpected end of data, expected colon sign `:' at line $$line_ref"
		);
	
	unless (substr($$data_ref, $$offset_ref, 1) eq ':') {
		return $self->_err(
			Parser => "Expected colon sign `:' at line $$line_ref:\n" . _parser_msg($data_ref, $$offset_ref)
		);
	}
	
	$$offset_ref++;
	1;
}

my %ESCAPES = (
	'b'  => "\b",
	'f'  => "\f",
	'n'  => "\n",
	'r'  => "\r",
	't'  => "\t",
	'"'  => '"',
	'\\' => '\\'
);

sub _parse_string {
	my ($self, $data_ref, $offset_ref, $line_ref, $rv_ref) = @_;
	
	pos($$data_ref) = ++$$offset_ref;
	my $str = '';
	
	while ($$data_ref =~ /\G(?:(\n+)|\\((?:[bfnrt"\\]))|\\u([0-9a-fA-F]{4})|([^\\"\x{0}-\x{8}\x{A}-\x{C}\x{E}-\x{1F}]+))/gc) {
		if (defined $1) {
			$$line_ref += length $1;
			$str .= $1;
		}
		elsif (defined $2) {
			$str .= $ESCAPES{$2};
		}
		elsif (defined $3) {
			$str .= pack 'U', hex $3;
		}
		else {
			$str .= $4;
		}
	}
	
	$$offset_ref = pos($$data_ref);
	if ($$offset_ref == length $$data_ref) {
		return $self->_err(
			Parser => "Unexpected end of data, expected string terminator `\"' at line $$line_ref"
		);
	}
	
	if ((my $c = substr($$data_ref, $$offset_ref, 1)) ne '"') {
		if ($c eq '\\') {
			return $self->_err(
				Parser => "Unrecognized escape sequence in string at line $$line_ref:\n" .
							_parser_msg($data_ref, $$offset_ref)
			);
		}
		else {
			my $hex = sprintf('"\x%02x"', ord $c);
			return $self->_err(
				Parser => "Bad character $hex in string at line $$line_ref:\n" .
							_parser_msg($data_ref, $$offset_ref)
			);
		}
	}
	
	$$offset_ref++;
	$$rv_ref = $str;
	
	1;
}

sub parse_file {
	my ($self, $path) = @_;
	
	$self->_err(undef);
	
	open my $fh, '<:utf8', $path
		or return $self->_err(IO => "open `$path': $!");
	
	my $data = do {
		local $/;
		<$fh>;
	};
	
	close $fh;
	
	$self->parse($data);
}

sub last_error {
	return $_[0]->{last_error};
}

sub _err {
	my ($self, $err_type, $msg) = @_;
	
	unless (defined $err_type) {
		$self->{last_error} = undef;
		return;
	}
	
	$self->{last_error} = "Parse::JCONF::Error::$err_type"->new($msg);
	if ($self->{autodie}) {
		$self->{last_error}->throw();
	}
	
	return;
}

sub _parser_msg {
	my ($data_ref, $offset) = @_;
	
	my $msg = '';
	my $non_space_chars = 0;
	my $c;
	my $i;
	
	for ($i=$offset; $i>=0; $i--) {
		$c = substr($$data_ref, $i, 1);
		if ($c eq "\n") {
			last;
		}
		elsif ($c eq "\t") {
			$c = '  ';
		}
		elsif (ord $c < 32) {
			$c = ' ';
		}
		
		substr($msg, 0, 0) = $c;
		
		if ($c =~ /\S/) {
			if (++$non_space_chars > 5) {
				last;
			}
		}
	}
	
	substr($msg, 0, 0) = ' ';
	my $bad_char = length $msg;
	
	my $len = length $$data_ref;
	$non_space_chars = 0;
	
	for ($i=$offset+1; $i<$len; $i++) {
		$c = substr($$data_ref, $i, 1);
		if ($c eq "\n") {
			last;
		}
		elsif ($c eq "\t") {
			$c = '  ';
		}
		elsif (ord $c < 32) {
			$c = ' ';
		}
		
		substr($msg, length $msg) = $c;
		
		if ($c =~ /\S/) {
			if (++$non_space_chars > 3) {
				last;
			}
		}
	}
	
	substr($msg, length $msg) = "\n" . ' 'x($bad_char-1).'^';
	return $msg;
}

1;

__END__

=pod

=head1 NAME

Parse::JCONF - Parse JCONF (JSON optimized for configs)

=head1 SYNOPSIS

    use strict;
    use Parse::JCONF;
    
    my $raw_cfg = do { local $/; <DATA> };
    my $parser = Parse::JCONF->new(autodie => 1);
    
    $cfg = $parser->parse($raw_cfg);
    
    $cfg->{modules}{Mo}[1]; # 0.08
    $cfg->{enabled}; # Parse::JCONF::Boolean::TRUE or "1" in string context
    $cfg->{enabled} == Parse::JCONF::Boolean::TRUE; # yes
    $cfg->{enabled} == 1; # no
    if ($cfg->{enabled}) { 1 }; # yes
    $cfg->{data}[0]; # Test data
    $cfg->{query}; # SELECT * from pkg
                   # LEFT JOIN ver ON pkg.id=ver.pkg_id
                   # WHERE pkg.name IN ("Moose", "Mouse", "Moo", "Mo")
    __DATA__
    modules = {
        Moose: 1,
        Mouse: 0.91,
        Moo: 0.05, # some comment here about version
        Mo: [0.01, 0.08],
    }
    
    enabled = true
    data = ["Test data", "Production data"] # some comment about data
    
    query = "SELECT * from pkg
             LEFT JOIN ver ON pkg.id=ver.pkg_id
             WHERE pkg.name IN (\"Moose\", \"Mouse\", \"Moo\", \"Mo\")"

=head1 DESCRIPTION

JSON is good, but not very handy for configuration files. JCONF intended to fix this.

It has several differences with JSON format:

=over

=item bareword - the word which matches /^\w+$/

    some_word   # valid
    some word   # invalid
    "some_word" # invalid

=item bareword may be used only as object key or root key

=item object key may be bareword or string

    {test: 1}   # valid
    {"test": 1} # valid

=item JCONF root always consists of 0 or more trines: root key (bareword), equals sign (=), any valid JCONF value (number/string/true/false/null/object/array)

    value1 = [1,2] # root trine: root key (bareword), equals sign (=), any valid JCONF value

=item values in the object/array or root trines may be devided with comma "," (like in JSON) or with new line (or even several)

    val = [1,2,3,4] # with comma
    
    val = [         # with new line
        1
        2
        3
        4
    ]
    
    val = {         # several newlines are ok
        a: 1
        
        b: 2
    }
    
    val = {        # comma and newlines are ok
        a: 1,
        b: 2
    }
    
    val = {       # invalid, several commas is not ok
        a: 1,,b:2
    }

=item comma separator allowed after last element

    [1,2,3,4,] # ok
    {a:1,b:2,} # ok

=item new lines, carriage return, tabs are valid symbols in the string

    str = "This is valid multiline
    JCONF string"

=item # - is start of the comment, all from this symbol to the end of line will be interpreted as comment

    obj = {
        bool: false # this is comment
    }

=back

=head1 METHODS

=head2 new

This is parser object constructor. Available parameters are:

=over

=item autodie

Throw exception on any error if true, default is false (in this case parser methods will return undef on error
and error may be found with L</last_error> method)

=item keep_order

Store key/value pairs in the hash which keeps order if true, default is false. This is useful when you need to
store your configuration back to the file (for example with C<JCONF::Writer>) and want to save same order as it
was before. You must have $Parse::JCONF::HashClass installed which default value is Tie::IxHash.

=back

=head2 parse

Parses string provided as parameter. Expected string encoding is utf8. On success returns reference to hash.
On fail returns undef/throws exception (according to C<autodie> option in the constructor).
Exception will be of type C<Parse::JCONF::Error::Parser>.

=head2 parse_file

Parses content of the file which path provided as parameter. Expected file content encoding is utf8. On success
returns reference to hash. On fail returns undef/throws exception (according to C<autodie> option in the constructor).
Exception will be of type C<Parse::JCONF::Error::IO> or C<Parse::JCONF::Error::Parser>.

=head2 last_error

Returns error occured for last parse() or parse_file() call. Error will be one of C<Parse::JCONF::Error> subclass or undef
(if there was no error).

=head1 SEE ALSO

L<Parse::JCONF::Error>, L<Parse::JCONF::Boolean>, L<JCONF::Writer>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

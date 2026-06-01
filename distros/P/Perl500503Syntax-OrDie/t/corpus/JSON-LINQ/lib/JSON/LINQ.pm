package JSON::LINQ;
######################################################################
#
# JSON::LINQ - LINQ-style query interface for JSON, JSONL, and LTSV files
#
# https://metacpan.org/dist/JSON-LINQ
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com>
######################################################################
#
# Compatible : Perl 5.005_03 and later
# Platform   : Windows and UNIX/Linux
#
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
                # Perl 5.005_03 compatibility for historical toolchains
# use 5.008001; # Lancaster Consensus 2013 for toolchains

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use Carp qw(croak);

use vars qw($VERSION $_fh_seq);
$VERSION = '1.02';
$VERSION = $VERSION;
# $VERSION self-assignment suppresses "used only once" warning under strict.
$_fh_seq = 0;
$_fh_seq = $_fh_seq;
# $_fh_seq self-assignment suppresses "used only once" warning under strict.

###############################################################################
# JSON Boolean type objects (merged from mb::JSON)
###############################################################################

package JSON::LINQ::Boolean;
use vars qw($VERSION);
$VERSION = '1.02';
$VERSION = $VERSION;

use overload
    '0+'     => sub { ${ $_[0] } },
    q{""}    => sub { ${ $_[0] } ? 'true' : 'false' },
    'bool'   => sub { ${ $_[0] } },
    fallback => 1;

package JSON::LINQ;

use vars qw($true $false);
{
    my $_t = 1; $true  = bless \$_t, 'JSON::LINQ::Boolean';
    my $_f = 0; $false = bless \$_f, 'JSON::LINQ::Boolean';
}

sub true  { $true  }
sub false { $false }

###############################################################################
# Internal JSON encoder/decoder (merged from mb::JSON 0.06)
###############################################################################

# UTF-8 multibyte pattern
my $utf8_pat = join '|', (
    '[\x00-\x7F\x80-\xBF\xC0-\xC1\xF5-\xFF]',
    '[\xC2-\xDF][\x80-\xBF]',
    '[\xE0][\xA0-\xBF][\x80-\xBF]',
    '[\xE1-\xEC][\x80-\xBF][\x80-\xBF]',
    '[\xED][\x80-\x9F][\x80-\xBF]',
    '[\xEE-\xEF][\x80-\xBF][\x80-\xBF]',
    '[\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF]',
    '[\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF]',
    '[\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF]',
    '[\x00-\xFF]',
);

sub _json_decode {
    my $json = defined $_[0] ? $_[0] : $_;
    my $r    = \$json;
    my $val  = _parse_value($r);
    $$r =~ s/\A\s+//s;
    croak "JSON::LINQ::_json_decode: trailing garbage: " . substr($$r, 0, 20)
        if length $$r;
    return $val;
}

sub _parse_value {
    my ($r) = @_;
    $$r =~ s/\A\s+//s;
    croak "JSON::LINQ::_json_decode: unexpected end of input" unless length $$r;

    my $c = substr($$r, 0, 1);

    if    ($c eq '{') { return _parse_object($r) }
    elsif ($c eq '[') { return _parse_array($r)  }
    elsif ($c eq '"') { return _parse_string($r) }
    elsif ($$r =~ s/\Anull(?=[^a-zA-Z0-9_]|$)//s)  { return undef   }
    elsif ($$r =~ s/\Atrue(?=[^a-zA-Z0-9_]|$)//s)  { return $true   }
    elsif ($$r =~ s/\Afalse(?=[^a-zA-Z0-9_]|$)//s) { return $false  }
    elsif ($$r =~ s/\A(-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?)//s) {
        return $1 + 0;
    }
    else {
        croak "JSON::LINQ::_json_decode: unexpected token: " . substr($$r, 0, 20);
    }
}

sub _parse_object {
    my ($r) = @_;
    $$r =~ s/\A\{//s;
    my %obj;
    $$r =~ s/\A\s+//s;
    if ($$r =~ s/\A\}//s) { return { %obj } }
    while (1) {
        $$r =~ s/\A\s+//s;
        croak "JSON::LINQ::_json_decode: expected string key in object"
            unless $$r =~ /\A"/;
        my $key = _parse_string($r);
        $$r =~ s/\A\s+//s;
        $$r =~ s/\A://s
            or croak "JSON::LINQ::_json_decode: expected ':' after key '$key'";
        my $val = _parse_value($r);
        $obj{$key} = $val;
        $$r =~ s/\A\s+//s;
        if    ($$r =~ s/\A,//s)  { next }
        elsif ($$r =~ s/\A\}//s) { last }
        else { croak "JSON::LINQ::_json_decode: expected ',' or '}' in object" }
    }
    return { %obj };
}

sub _parse_array {
    my ($r) = @_;
    $$r =~ s/\A\[//s;
    my @arr;
    $$r =~ s/\A\s+//s;
    if ($$r =~ s/\A\]//s) { return [ @arr ] }
    while (1) {
        push @arr, _parse_value($r);
        $$r =~ s/\A\s+//s;
        if    ($$r =~ s/\A,//s)  { next }
        elsif ($$r =~ s/\A\]//s) { last }
        else { croak "JSON::LINQ::_json_decode: expected ',' or ']' in array" }
    }
    return [ @arr ];
}

my %UNESC = (
    '"' => '"', '\\' => '\\', '/' => '/',
    'b'  => "\x08", 'f' => "\x0C",
    'n'  => "\n",   'r' => "\r",   't' => "\t",
);

sub _parse_string {
    my ($r) = @_;
    $$r =~ s/\A"//s;
    my $s = '';
    while (1) {
        if    ($$r =~ s/\A"//s)             { last }
        elsif ($$r =~ s/\A\\(["\\\/bfnrt])//s) { $s .= $UNESC{$1} }
        elsif ($$r =~ s/\A\\u([0-9a-fA-F]{4})//s) {
            $s .= _cp_to_utf8(hex($1));
        }
        elsif ($$r =~ s/\A($utf8_pat)//s)  { $s .= $1 }
        else  { croak "JSON::LINQ::_json_decode: unterminated string" }
    }
    return $s;
}

sub _cp_to_utf8 {
    my ($cp) = @_;
    return chr($cp) if $cp <= 0x7F;
    if ($cp <= 0x7FF) {
        return chr(0xC0|($cp>>6)) . chr(0x80|($cp&0x3F));
    }
    return chr(0xE0|($cp>>12))
         . chr(0x80|(($cp>>6)&0x3F))
         . chr(0x80|($cp&0x3F));
}

sub _json_encode {
    my ($data) = @_;
    return _enc_value($data);
}

sub _enc_value {
    my ($v) = @_;
    return 'null'  unless defined $v;
    if (ref $v eq 'JSON::LINQ::Boolean') { return $$v ? 'true' : 'false' }
    if (ref $v eq 'ARRAY')  { return '[' . join(',', map { _enc_value($_) } @$v) . ']' }
    if (ref $v eq 'HASH') {
        my @pairs = map { _enc_string($_) . ':' . _enc_value($v->{$_}) }
                    sort keys %$v;
        return '{' . join(',', @pairs) . '}';
    }
    # number: matches JSON number pattern exactly
    if (!ref $v && $v =~ /\A-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?\z/s) {
        return $v;
    }
    return _enc_string($v);
}

sub _enc_string {
    my ($s) = @_;
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    $s =~ s/\x08/\\b/g;
    $s =~ s/\x0C/\\f/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\r/\\r/g;
    $s =~ s/\t/\\t/g;
    $s =~ s/([\x00-\x1F])/sprintf('\\u%04X', ord($1))/ge;
    return '"' . $s . '"';
}

###############################################################################
# Constructor and Iterator Infrastructure
###############################################################################

sub new {
    my($class, $iterator) = @_;
    return bless { iterator => $iterator }, $class;
}

sub iterator {
    my $self = $_[0];
    # If this object was created by _from_snapshot, _factory provides
    # a fresh iterator closure each time iterator() is called.
    if (exists $self->{_factory}) {
        return $self->{_factory}->();
    }
    return $self->{iterator};
}

###############################################################################
# Data Source Methods
###############################################################################

# From - create query from array
sub From {
    my($class, $source) = @_;

    if (ref($source) eq 'ARRAY') {
        my $i = 0;
        return $class->new(sub {
            return undef if $i >= scalar(@$source);
            return $source->[$i++];
        });
    }

    die "From() requires ARRAY reference";
}

# _open_fh - open a file for reading ('<') or writing ('>') and return a
# filehandle reference that works on all supported Perl versions.
#
# A unique numbered package glob is used on all Perl versions to guarantee
# that concurrent From* iterators (e.g. inside Join/GroupJoin) each get their
# own IO slot.  (\do{local *_} always resolves to *main::_ and causes
# IO-slot collision; lexical filehandles via eval-string are avoided because
# they are unreliable with a variable $mode on some Windows Perls.)
#
# $raw: if true, binmode is called after open so that raw bytes are
# read/written on all platforms, preventing \r\n <-> \n translation on
# Windows.  Pass 0 for text-mode files such as CSV, where the OS-level
# \r\n -> \n conversion is desired.
sub _open_fh {
    my($mode, $file, $raw) = @_;
    $_fh_seq++;
    my $seq = $_fh_seq;
    my $fhn = "JSON::LINQ::FH::H${seq}";
    my $arg = ($mode eq '>') ? ">$file" : "< $file";
    { no strict 'refs'; open($fhn, $arg) or die "Cannot open '$file': $!" }
    if ($raw) { no strict 'refs'; binmode(*{$fhn}) }
    return $fhn;
}

# FromJSON - read a JSON file containing a top-level array of objects
# Each element of the array becomes one item in the sequence.
# The file must contain a single JSON array: [ {...}, {...}, ... ]
# or a single JSON object (treated as a one-element sequence).
sub FromJSON {
    my($class, $file) = @_;

    my $fhn = _open_fh('<', $file, 1);

    my $content;
    { no strict 'refs'; local $/; $content = readline(*{$fhn}) }
    { no strict 'refs'; close($fhn) }

    my $data = eval { _json_decode($content) };
    die "JSON::LINQ::FromJSON: cannot parse '$file': $@" if $@;

    my $records;
    if (ref($data) eq 'ARRAY') {
        $records = $data;
    }
    elsif (ref($data) eq 'HASH') {
        $records = [ $data ];
    }
    else {
        die "JSON::LINQ::FromJSON: '$file' must contain a JSON array or object";
    }

    my $i = 0;
    return $class->new(sub {
        return undef if $i >= scalar(@$records);
        return $records->[$i++];
    });
}

# FromJSONL - read a JSONL (JSON Lines) file
# Each line is a separate JSON value (typically an object).
# Empty lines and lines beginning with '#' are skipped.
# This is memory-efficient for large files: one line at a time.
sub FromJSONL {
    my($class, $file) = @_;

    my $fhn = _open_fh('<', $file, 1);

    return $class->new(sub {
        no strict 'refs';
        while (my $line = readline(*{$fhn})) {
            chomp $line;
            $line =~ s/\r\z//;          # Strip CR for CRLF files
            next unless length $line;
            next if $line =~ /\A\s*\z/; # Skip blank lines
            next if $line =~ /\A\s*#/;  # Skip comment lines

            my $val = eval { _json_decode($line) };
            if ($@) {
                warn "JSON::LINQ::FromJSONL: skipping invalid JSON line: $@";
                next;
            }
            return $val;
        }
        close($fhn);
        return undef;
    });
}

# FromJSONString - create query from a JSON string (array or object)
sub FromJSONString {
    my($class, $json) = @_;

    my $data = eval { _json_decode($json) };
    die "JSON::LINQ::FromJSONString: cannot parse JSON: $@" if $@;

    my $records;
    if (ref($data) eq 'ARRAY') {
        $records = $data;
    }
    elsif (ref($data) eq 'HASH') {
        $records = [ $data ];
    }
    else {
        $records = [ $data ];
    }

    my $i = 0;
    return $class->new(sub {
        return undef if $i >= scalar(@$records);
        return $records->[$i++];
    });
}

###############################################################################
# CSV parsing helpers (RFC 4180 compliant)
###############################################################################

# _parse_csv_line - split one CSV line into a list of fields
# Handles: quoted fields, embedded commas, escaped double-quotes (""),
# configurable separator (default: comma).
# Does NOT handle embedded newlines (multi-line quoted fields).
sub _parse_csv_line {
    my($line, $sep) = @_;
    $sep = ',' unless defined $sep;
    my @fields = ();
    $line =~ s{\r\n\z|\r\z|\n\z}{};
    my $pos = 0;
    my $len = length($line);
    while ($pos <= $len) {
        if ($pos < $len && substr($line, $pos, 1) eq '"') {
            $pos++;
            my $field = '';
            while ($pos < $len) {
                my $c = substr($line, $pos, 1);
                if ($c eq '"') {
                    $pos++;
                    if ($pos < $len && substr($line, $pos, 1) eq '"') {
                        $field .= '"';
                        $pos++;
                    }
                    else {
                        last;
                    }
                }
                else {
                    $field .= $c;
                    $pos++;
                }
            }
            push @fields, $field;
            $pos++ if $pos < $len && substr($line, $pos, 1) eq $sep;
        }
        else {
            my $start = $pos;
            while ($pos < $len && substr($line, $pos, 1) ne $sep) {
                $pos++;
            }
            push @fields, substr($line, $start, $pos - $start);
            $pos++;
        }
    }
    return @fields;
}

# _format_csv_field - quote a single value for CSV output if necessary
sub _format_csv_field {
    my($value, $sep) = @_;
    $sep = ',' unless defined $sep;
    $value = '' unless defined $value;
    if ($value =~ /["\n\r]/ || index($value, $sep) >= 0) {
        $value =~ s/"/""/g;
        return '"' . $value . '"';
    }
    return $value;
}

# FromCSV - read a CSV (Comma-Separated Values) file
# The first line is used as the header row (column names) unless the
# C<headers> option is supplied.
# Options:
#   sep         => $char     field separator (default: ',')
#   headers     => \@cols    explicit column names (skip auto-detect from file)
#   skip_header => 1         skip the first line even when headers is given
sub FromCSV {
    my($class, $file, %opts) = @_;
    my $sep     = defined $opts{sep}     ? $opts{sep}     : ',';
    my $headers = $opts{headers};
    my $skip    = $opts{skip_header};

    my $fhn = _open_fh('<', $file, 0);

    my @cols = ();
    if (!defined $headers) {
        my $hdr;
        { no strict 'refs'; $hdr = readline(*{$fhn}) }
        if (defined $hdr) {
            @cols = _parse_csv_line($hdr, $sep);
        }
    }
    else {
        @cols = @{$headers};
        if ($skip) {
            no strict 'refs'; readline(*{$fhn});
        }
    }

    my $iter = sub {
        no strict 'refs';
        my $line = readline(*{$fhn});
        if (!defined $line) {
            close($fhn);
            return undef;
        }
        $line =~ s{\r\n\z|\r\z|\n\z}{};
        return undef if $line eq '';
        my @vals = _parse_csv_line($line, $sep);
        my %rec  = ();
        for my $i (0 .. $#cols) {
            $rec{ $cols[$i] } = $vals[$i];
        }
        return { %rec };
    };
    return $class->new($iter);
}

# FromLTSV - read an LTSV (Labeled Tab-Separated Values) file
# Each line is a record of "label:value" fields separated by tabs.
# Empty lines are skipped.  Memory-efficient: one line at a time.
# This method is provided so JSON::LINQ can JOIN with LTSV data sources
# without requiring LTSV::LINQ to be installed.
sub FromLTSV {
    my($class, $file) = @_;

    my $fhn = _open_fh('<', $file, 1);

    return $class->new(sub {
        no strict 'refs';
        while (my $line = readline(*{$fhn})) {
            chomp $line;
            $line =~ s/\r\z//;  # Remove CR for CRLF files on any platform
            next unless length $line;

            my %record = map {
                /\A(.+?):(.*)\z/ ? ($1, $2) : ()
            } split /\t/, $line;

            return { %record } if %record;
        }
        close($fhn);
        return undef;
    });
}

# Range - generate sequence of integers
sub Range {
    my($class, $start, $count) = @_;

    my $current = $start;
    my $remaining = $count;

    return $class->new(sub {
        return undef if $remaining <= 0;
        $remaining--;
        return $current++;
    });
}

# Empty - return empty sequence
sub Empty {
    my($class) = @_;

    return $class->new(sub {
        return undef;
    });
}

# Repeat - repeat element specified number of times
sub Repeat {
    my($class, $element, $count) = @_;

    my $remaining = $count;

    return $class->new(sub {
        return undef if $remaining <= 0;
        $remaining--;
        return $element;
    });
}

###############################################################################
# Filtering Methods
###############################################################################

# Where - filter elements
sub Where {
    my($self, @args) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);

    # Support both code reference and DSL form
    my $cond;
    if (@args == 1 && ref($args[0]) eq 'CODE') {
        $cond = $args[0];
    }
    else {
        # DSL form: Where(key => value, ...)
        my %match = @args;
        $cond = sub {
            my $row = shift;
            for my $k (keys %match) {
                return 0 unless defined $row->{$k};
                return 0 unless $row->{$k} eq $match{$k};
            }
            return 1;
        };
    }

    return $class->new(sub {
        while (1) {
            my $item = $iter->();
            return undef unless defined $item;
            return $item if $cond->($item);
        }
    });
}

###############################################################################
# Projection Methods
###############################################################################

# Select - transform elements
sub Select {
    my($self, $selector) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);

    return $class->new(sub {
        my $item = $iter->();
        return undef unless defined $item;
        return $selector->($item);
    });
}

# SelectMany - flatten sequences
sub SelectMany {
    my($self, $selector) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);

    my @buffer;

    return $class->new(sub {
        while (1) {
            if (@buffer) {
                return shift @buffer;
            }

            my $item = $iter->();
            return undef unless defined $item;

            my $result = $selector->($item);
            unless (ref($result) eq 'ARRAY') {
                die "SelectMany: selector must return an ARRAY reference";
            }
            @buffer = @$result;
        }
    });
}

# Concat - concatenate two sequences
sub Concat {
    my($self, $second) = @_;
    my $class = ref($self);

    my $first_iter = $self->iterator;
    my $second_iter;
    my $first_done = 0;

    return $class->new(sub {
        if (!$first_done) {
            my $item = $first_iter->();
            if (defined $item) {
                return $item;
            }
            $first_done = 1;
            $second_iter = $second->iterator;
        }

        return $second_iter ? $second_iter->() : undef;
    });
}

# Zip - combine two sequences element-wise
sub Zip {
    my($self, $second, $result_selector) = @_;

    my $iter1 = $self->iterator;
    my $iter2 = $second->iterator;
    my $class = ref($self);

    return $class->new(sub {
        my $item1 = $iter1->();
        my $item2 = $iter2->();

        # Return undef if either sequence ends
        return undef unless defined($item1) && defined($item2);

        return $result_selector->($item1, $item2);
    });
}

###############################################################################
# Partitioning Methods
###############################################################################

# Take - take first N elements
sub Take {
    my($self, $count) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);
    my $taken = 0;

    return $class->new(sub {
        return undef if $taken >= $count;
        my $item = $iter->();
        return undef unless defined $item;
        $taken++;
        return $item;
    });
}

# Skip - skip first N elements
sub Skip {
    my($self, $count) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);
    my $skipped = 0;

    return $class->new(sub {
        while ($skipped < $count) {
            my $item = $iter->();
            return undef unless defined $item;
            $skipped++;
        }
        return $iter->();
    });
}

# TakeWhile - take while condition is true
sub TakeWhile {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);
    my $done = 0;

    return $class->new(sub {
        return undef if $done;
        my $item = $iter->();
        return undef unless defined $item;

        if ($predicate->($item)) {
            return $item;
        }
        else {
            $done = 1;
            return undef;
        }
    });
}

# SkipWhile - skip elements while predicate is true
sub SkipWhile {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);
    my $skipping = 1;

    return $class->new(sub {
        while (1) {
            my $item = $iter->();
            return undef unless defined $item;

            if ($skipping) {
                if (!$predicate->($item)) {
                    $skipping = 0;
                    return $item;
                }
            }
            else {
                return $item;
            }
        }
    });
}

###############################################################################
# Ordering Methods
###############################################################################

# OrderBy - sort ascending (smart: numeric when both keys look numeric)
sub OrderBy {
    my($self, $key_selector) = @_;
    my @items = $self->ToArray();
    return JSON::LINQ::Ordered->_new_ordered(
        [ @items ],
        [{ sel => $key_selector, dir => 1, type => 'smart' }]
    );
}

# OrderByDescending - sort descending (smart comparison)
sub OrderByDescending {
    my($self, $key_selector) = @_;
    my @items = $self->ToArray();
    return JSON::LINQ::Ordered->_new_ordered(
        [ @items ],
        [{ sel => $key_selector, dir => -1, type => 'smart' }]
    );
}

# OrderByStr - sort ascending by string comparison
sub OrderByStr {
    my($self, $key_selector) = @_;
    my @items = $self->ToArray();
    return JSON::LINQ::Ordered->_new_ordered(
        [ @items ],
        [{ sel => $key_selector, dir => 1, type => 'str' }]
    );
}

# OrderByStrDescending - sort descending by string comparison
sub OrderByStrDescending {
    my($self, $key_selector) = @_;
    my @items = $self->ToArray();
    return JSON::LINQ::Ordered->_new_ordered(
        [ @items ],
        [{ sel => $key_selector, dir => -1, type => 'str' }]
    );
}

# OrderByNum - sort ascending by numeric comparison
sub OrderByNum {
    my($self, $key_selector) = @_;
    my @items = $self->ToArray();
    return JSON::LINQ::Ordered->_new_ordered(
        [ @items ],
        [{ sel => $key_selector, dir => 1, type => 'num' }]
    );
}

# OrderByNumDescending - sort descending by numeric comparison
sub OrderByNumDescending {
    my($self, $key_selector) = @_;
    my @items = $self->ToArray();
    return JSON::LINQ::Ordered->_new_ordered(
        [ @items ],
        [{ sel => $key_selector, dir => -1, type => 'num' }]
    );
}

# Reverse - reverse order
sub Reverse {
    my($self) = @_;
    my @items = reverse $self->ToArray();
    my $class = ref($self);
    return $class->From([ @items ]);
}

###############################################################################
# Grouping Methods
###############################################################################

# GroupBy - group elements by key
sub GroupBy {
    my($self, $key_selector, $element_selector) = @_;
    $element_selector ||= sub { $_[0] };

    my %groups;
    my @key_order;

    $self->ForEach(sub {
        my $item = shift;
        my $key = $key_selector->($item);
        $key = '' unless defined $key;
        unless (exists $groups{$key}) {
            push @key_order, $key;
        }
        push @{$groups{$key}}, $element_selector->($item);
    });

    my @result;
    for my $key (@key_order) {
        push @result, {
            Key => $key,
            Elements => $groups{$key},
        };
    }

    my $class = ref($self);
    return $class->From([ @result ]);
}

###############################################################################
# Set Operations
###############################################################################

# Distinct - remove duplicates
sub Distinct {
    my($self, $key_selector) = @_;
    my $iter = $self->iterator;
    my $class = ref($self);
    my %seen;

    return $class->new(sub {
        while (1) {
            my $item = $iter->();
            return undef unless defined $item;

            my $key = $key_selector ? $key_selector->($item) : _make_key($item);
            $key = '' unless defined $key;

            unless ($seen{$key}++) {
                return $item;
            }
        }
    });
}

# Internal helper for set operations - make key from item
sub _make_key {
    my($item) = @_;

    return '' unless defined $item;

    if (ref($item) eq 'HASH') {
        my @pairs = ();
        for my $k (sort keys %$item) {
            my $v = defined($item->{$k}) ? $item->{$k} : '';
            push @pairs, "$k\x1F$v";  # \x1F = Unit Separator
        }
        return join("\x1E", @pairs);  # \x1E = Record Separator
    }
    elsif (ref($item) eq 'ARRAY') {
        return join("\x1E", map { defined($_) ? $_ : '' } @$item);
    }
    else {
        return $item;
    }
}

# _from_snapshot - internal helper for GroupJoin.
sub _from_snapshot {
    my($class_or_self, $aref) = @_;

    my $class = ref($class_or_self) || $class_or_self;

    my $iter_factory = sub {
        my $i = 0;
        return sub {
            return undef if $i >= scalar(@$aref);
            return $aref->[$i++];
        };
    };

    my $obj = bless {
        iterator => $iter_factory->(),
        _factory => $iter_factory,
    }, $class;

    return $obj;
}

# Union - set union with distinct
sub Union {
    my($self, $second, $key_selector) = @_;

    return $self->Concat($second)->Distinct($key_selector);
}

# Intersect - set intersection
sub Intersect {
    my($self, $second, $key_selector) = @_;

    my %second_set = ();
    $second->ForEach(sub {
        my $item = shift;
        my $key = $key_selector ? $key_selector->($item) : _make_key($item);
        $second_set{$key} = $item;
    });

    my $class = ref($self);
    my $iter = $self->iterator;
    my %seen = ();

    return $class->new(sub {
        while (defined(my $item = $iter->())) {
            my $key = $key_selector ? $key_selector->($item) : _make_key($item);

            next if $seen{$key}++;
            return $item if exists $second_set{$key};
        }
        return undef;
    });
}

# Except - set difference
sub Except {
    my($self, $second, $key_selector) = @_;

    my %second_set = ();
    $second->ForEach(sub {
        my $item = shift;
        my $key = $key_selector ? $key_selector->($item) : _make_key($item);
        $second_set{$key} = 1;
    });

    my $class = ref($self);
    my $iter = $self->iterator;
    my %seen = ();

    return $class->new(sub {
        while (defined(my $item = $iter->())) {
            my $key = $key_selector ? $key_selector->($item) : _make_key($item);

            next if $seen{$key}++;
            return $item unless exists $second_set{$key};
        }
        return undef;
    });
}

# Join - correlates elements of two sequences
sub Join {
    my($self, $inner, $outer_key_selector, $inner_key_selector, $result_selector) = @_;

    my %inner_hash = ();
    $inner->ForEach(sub {
        my $item = shift;
        my $key = $inner_key_selector->($item);
        $key = _make_key($key) if ref($key);
        push @{$inner_hash{$key}}, $item;
    });

    my $class = ref($self);
    my $iter = $self->iterator;
    my @buffer = ();

    return $class->new(sub {
        while (1) {
            return shift @buffer if @buffer;

            my $outer_item = $iter->();
            return undef unless defined $outer_item;

            my $key = $outer_key_selector->($outer_item);
            $key = _make_key($key) if ref($key);

            if (exists $inner_hash{$key}) {
                for my $inner_item (@{$inner_hash{$key}}) {
                    push @buffer, $result_selector->($outer_item, $inner_item);
                }
            }
        }
    });
}

# GroupJoin - group join (LEFT OUTER JOIN-like operation)
sub GroupJoin {
    my($self, $inner, $outer_key_selector, $inner_key_selector, $result_selector) = @_;
    my $class = ref($self);
    my $outer_iter = $self->iterator;

    my %inner_lookup = ();
    $inner->ForEach(sub {
        my $item = shift;
        my $key = $inner_key_selector->($item);
        $key = _make_key($key) if ref($key);
        $key = '' unless defined $key;
        push @{$inner_lookup{$key}}, $item;
    });

    return $class->new(sub {
        my $outer_item = $outer_iter->();
        return undef unless defined $outer_item;

        my $key = $outer_key_selector->($outer_item);
        $key = _make_key($key) if ref($key);
        $key = '' unless defined $key;

        my $matched_inners = exists $inner_lookup{$key} ? $inner_lookup{$key} : [];

        my @snapshot = @$matched_inners;
        my $inner_group = $class->_from_snapshot([ @snapshot ]);

        return $result_selector->($outer_item, $inner_group);
    });
}

###############################################################################
# Quantifier Methods
###############################################################################

# All - test if all elements satisfy condition
sub All {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;

    while (defined(my $item = $iter->())) {
        return 0 unless $predicate->($item);
    }
    return 1;
}

# Any - test if any element satisfies condition
sub Any {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;

    if ($predicate) {
        while (defined(my $item = $iter->())) {
            return 1 if $predicate->($item);
        }
        return 0;
    }
    else {
        my $item = $iter->();
        return defined($item) ? 1 : 0;
    }
}

# Contains - check if sequence contains element
sub Contains {
    my($self, $value, $comparer) = @_;

    if ($comparer) {
        return $self->Any(sub { $comparer->($_[0], $value) });
    }
    else {
        return $self->Any(sub {
            my $item = $_[0];
            return (!defined($item) && !defined($value)) ||
                   (defined($item) && defined($value) && $item eq $value);
        });
    }
}

# SequenceEqual - compare two sequences for equality
sub SequenceEqual {
    my($self, $second, $comparer) = @_;
    $comparer ||= sub {
        my($a, $b) = @_;
        return (!defined($a) && !defined($b)) ||
               (defined($a) && defined($b) && $a eq $b);
    };

    my $iter1 = $self->iterator;
    my $iter2 = $second->iterator;

    while (1) {
        my $item1 = $iter1->();
        my $item2 = $iter2->();

        return 1 if !defined($item1) && !defined($item2);
        return 0 if !defined($item1) || !defined($item2);
        return 0 unless $comparer->($item1, $item2);
    }
}

###############################################################################
# Element Access Methods
###############################################################################

# First - get first element
sub First {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;

    if ($predicate) {
        while (defined(my $item = $iter->())) {
            return $item if $predicate->($item);
        }
        die "No element satisfies the condition";
    }
    else {
        my $item = $iter->();
        return $item if defined $item;
        die "Sequence contains no elements";
    }
}

# FirstOrDefault - get first element or default
sub FirstOrDefault {
    my $self = shift;
    my($predicate, $default);

    if (@_ >= 2) {
        ($predicate, $default) = @_;
    }
    elsif (@_ == 1) {
        if (ref($_[0]) eq 'CODE') {
            $predicate = $_[0];
        }
        else {
            $default = $_[0];
        }
    }

    my $result = eval { $self->First($predicate) };
    return $@ ? $default : $result;
}

# Last - get last element
sub Last {
    my($self, $predicate) = @_;
    my @items = $self->ToArray();

    if ($predicate) {
        for (my $i = $#items; $i >= 0; $i--) {
            return $items[$i] if $predicate->($items[$i]);
        }
        die "No element satisfies the condition";
    }
    else {
        die "Sequence contains no elements" unless @items;
        return $items[-1];
    }
}

# LastOrDefault - return last element or default
sub LastOrDefault {
    my $self = shift;
    my($predicate, $default);

    if (@_ >= 2) {
        ($predicate, $default) = @_;
    }
    elsif (@_ == 1) {
        if (ref($_[0]) eq 'CODE') {
            $predicate = $_[0];
        }
        else {
            $default = $_[0];
        }
    }

    my @items = $self->ToArray();

    if ($predicate) {
        for (my $i = $#items; $i >= 0; $i--) {
            return $items[$i] if $predicate->($items[$i]);
        }
        return $default;
    }
    else {
        return @items ? $items[-1] : $default;
    }
}

# Single - return the only element
sub Single {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;
    my $found;
    my $count = 0;

    while (defined(my $item = $iter->())) {
        next if $predicate && !$predicate->($item);

        $count++;
        if ($count > 1) {
            die "Sequence contains more than one element";
        }
        $found = $item;
    }

    die "Sequence contains no elements" if $count == 0;
    return $found;
}

# SingleOrDefault - return the only element or undef
sub SingleOrDefault {
    my($self, $predicate) = @_;
    my $iter = $self->iterator;
    my $found;
    my $count = 0;

    while (defined(my $item = $iter->())) {
        next if $predicate && !$predicate->($item);

        $count++;
        if ($count > 1) {
            return undef;
        }
        $found = $item;
    }

    return $count == 1 ? $found : undef;
}

# ElementAt - return element at specified index
sub ElementAt {
    my($self, $index) = @_;
    die "Index must be non-negative" if $index < 0;

    my $iter = $self->iterator;
    my $current = 0;

    while (defined(my $item = $iter->())) {
        return $item if $current == $index;
        $current++;
    }

    die "Index out of range";
}

# ElementAtOrDefault - return element at index or undef
sub ElementAtOrDefault {
    my($self, $index) = @_;
    return undef if $index < 0;

    my $iter = $self->iterator;
    my $current = 0;

    while (defined(my $item = $iter->())) {
        return $item if $current == $index;
        $current++;
    }

    return undef;
}

###############################################################################
# Aggregation Methods
###############################################################################

# Count - count elements
sub Count {
    my($self, $predicate) = @_;

    if ($predicate) {
        return $self->Where($predicate)->Count();
    }

    my $count = 0;
    my $iter = $self->iterator;
    $count++ while defined $iter->();
    return $count;
}

# Sum - calculate sum
sub Sum {
    my($self, $selector) = @_;
    $selector ||= sub { $_[0] };

    my $sum = 0;
    $self->ForEach(sub {
        $sum += $selector->(shift);
    });
    return $sum;
}

# Min - find minimum
sub Min {
    my($self, $selector) = @_;
    $selector ||= sub { $_[0] };

    my $min;
    $self->ForEach(sub {
        my $val = $selector->(shift);
        $min = $val if !defined($min) || $val < $min;
    });
    return $min;
}

# Max - find maximum
sub Max {
    my($self, $selector) = @_;
    $selector ||= sub { $_[0] };

    my $max;
    $self->ForEach(sub {
        my $val = $selector->(shift);
        $max = $val if !defined($max) || $val > $max;
    });
    return $max;
}

# Average - calculate average
sub Average {
    my($self, $selector) = @_;
    $selector ||= sub { $_[0] };

    my $sum = 0;
    my $count = 0;
    $self->ForEach(sub {
        $sum += $selector->(shift);
        $count++;
    });

    die "Sequence contains no elements" if $count == 0;
    return $sum / $count;
}

# AverageOrDefault - calculate average or return undef if empty
sub AverageOrDefault {
    my($self, $selector) = @_;
    $selector ||= sub { $_[0] };

    my $sum = 0;
    my $count = 0;
    $self->ForEach(sub {
        $sum += $selector->(shift);
        $count++;
    });

    return undef if $count == 0;
    return $sum / $count;
}

# Aggregate - apply accumulator function over sequence
sub Aggregate {
    my($self, @args) = @_;

    my($seed, $func, $result_selector);

    if (@args == 1) {
        $func = $args[0];
        my $iter = $self->iterator;
        $seed = $iter->();
        die "Sequence contains no elements" unless defined $seed;

        while (defined(my $item = $iter->())) {
            $seed = $func->($seed, $item);
        }
    }
    elsif (@args == 2) {
        ($seed, $func) = @args;
        $self->ForEach(sub {
            $seed = $func->($seed, shift);
        });
    }
    elsif (@args == 3) {
        ($seed, $func, $result_selector) = @args;
        $self->ForEach(sub {
            $seed = $func->($seed, shift);
        });
    }
    else {
        die "Invalid number of arguments for Aggregate";
    }

    return $result_selector ? $result_selector->($seed) : $seed;
}

###############################################################################
# Conversion Methods
###############################################################################

# ToArray - convert to array
sub ToArray {
    my($self) = @_;
    my @result;
    my $iter = $self->iterator;

    while (defined(my $item = $iter->())) {
        push @result, $item;
    }
    return @result;
}

# ToList - convert to array reference
sub ToList {
    my($self) = @_;
    return [$self->ToArray()];
}

# ToDictionary - convert sequence to hash reference
sub ToDictionary {
    my($self, $key_selector, $value_selector) = @_;

    $value_selector ||= sub { $_[0] };

    my %dictionary = ();

    $self->ForEach(sub {
        my $item = shift;
        my $key = $key_selector->($item);
        my $value = $value_selector->($item);

        $key = '' unless defined $key;
        $dictionary{$key} = $value;
    });

    return { %dictionary };
}

# ToLookup - convert sequence to hash of arrays
sub ToLookup {
    my($self, $key_selector, $value_selector) = @_;

    $value_selector ||= sub { $_[0] };

    my %lookup = ();

    $self->ForEach(sub {
        my $item = shift;
        my $key = $key_selector->($item);
        my $value = $value_selector->($item);

        $key = '' unless defined $key;
        push @{$lookup{$key}}, $value;
    });

    return { %lookup };
}

# DefaultIfEmpty - return default value if empty
sub DefaultIfEmpty {
    my($self, $default_value) = @_;
    my $has_default_arg = @_ > 1;
    if (!$has_default_arg) {
        $default_value = undef;
    }

    my $class = ref($self);
    my $iter = $self->iterator;
    my $has_elements = 0;
    my $returned_default = 0;

    return $class->new(sub {
        my $item = $iter->();
        if (defined $item) {
            $has_elements = 1;
            return $item;
        }

        if (!$has_elements && !$returned_default) {
            $returned_default = 1;
            return $default_value;
        }

        return undef;
    });
}

# ToJSON - write sequence as a JSON array file
# Each element is encoded as JSON; the result is a JSON array.
sub ToJSON {
    my($self, $file) = @_;

    my $fhn = _open_fh('>', $file, 1);

    { no strict 'refs'; print {*{$fhn}} "[\n" }
    my $first = 1;
    $self->ForEach(sub {
        my $record = shift;
        no strict 'refs';
        print {*{$fhn}} ",\n" unless $first;
        $first = 0;
        print {*{$fhn}} _json_encode($record);
    });
    { no strict 'refs'; print {*{$fhn}} "\n]\n" }

    { no strict 'refs'; close($fhn) }
    return 1;
}

# ToJSONL - write sequence as a JSONL (JSON Lines) file
# Each element is encoded as one line of JSON.
# This is streaming-friendly and memory-efficient.
sub ToJSONL {
    my($self, $file) = @_;

    my $fhn = _open_fh('>', $file, 1);

    $self->ForEach(sub {
        my $record = shift;
        no strict 'refs';
        print {*{$fhn}} _json_encode($record), "\n";
    });

    { no strict 'refs'; close($fhn) }
    return 1;
}

# ToLTSV - write sequence as an LTSV (Labeled Tab-Separated Values) file.
# Each element must be a HASH reference.
# Tab/CR/LF in values are sanitized to a single space to keep the file
# structurally valid.  This method is provided so a JSON::LINQ pipeline
# can emit LTSV output without requiring LTSV::LINQ.
#
# Options (key => value pairs after $filename):
#   label_order => \@labels   emit only these labels in this order;
#                             labels not present in the record are skipped.
#   headers     => \@labels   alias for label_order.
#
# Without label_order/headers, all keys are emitted alphabetically.
sub ToLTSV {
    my($self, $file, %opt) = @_;

    # Resolve label_order / headers alias
    my $label_order = $opt{label_order} || $opt{headers} || undef;

    my $fhn = _open_fh('>', $file, 1);

    $self->ForEach(sub {
        my $record = shift;
        # LTSV spec: tab is the field separator; newline terminates the record.
        # Sanitize values to prevent structural corruption of the output file.
        my @keys = $label_order
            ? grep { exists $record->{$_} } @$label_order
            : sort keys %$record;
        my $line = join("\t", map {
            my $v = defined($record->{$_}) ? $record->{$_} : '';
            $v =~ s/[\t\n\r]/ /g;
            "$_:$v"
        } @keys);
        no strict 'refs';
        print {*{$fhn}} $line, "\n";
    });

    { no strict 'refs'; close($fhn) }
    return 1;
}

###############################################################################
# CSV Output
###############################################################################

# ToCSV - write the sequence as a CSV file.
# Elements that are HASH references are written as named-column rows;
# scalar elements are written one-per-line without a header.
#
# Options (key => value pairs after $filename):
#   sep          => $char       field separator (default: ',')
#   headers      => \@cols      emit only these columns in this order
#   label_order  => \@cols      alias for headers
#   no_header    => 1           suppress the header row entirely
sub ToCSV {
    my($self, $file, %opts) = @_;
    my $sep       = defined $opts{sep}         ? $opts{sep}         : ',';
    my $headers   = defined $opts{headers}     ? $opts{headers}
                  : defined $opts{label_order} ? $opts{label_order}
                  : undef;
    my $no_header = $opts{no_header};

    # Materialise the sequence so we can inspect the first element before
    # writing the header.
    my @items = ();
    my $iter  = $self->iterator;
    while (defined(my $e = $iter->())) {
        push @items, $e;
    }

    my $fhn = _open_fh('>', $file, 0);

    unless ($no_header) {
        my @cols = ();
        if (defined $headers) {
            @cols = @{$headers};
        }
        elsif (@items && ref($items[0]) eq 'HASH') {
            @cols = sort keys %{ $items[0] };
        }

        if (@cols) {
            { no strict 'refs'; print {*{$fhn}} join($sep, map { _format_csv_field($_, $sep) } @cols) . "\n" }
            for my $item (@items) {
                if (ref($item) eq 'HASH') {
                    no strict 'refs';
                    print {*{$fhn}} join($sep, map {
                        _format_csv_field($item->{$_}, $sep)
                    } @cols) . "\n";
                }
                else {
                    no strict 'refs'; print {*{$fhn}} _format_csv_field($item, $sep) . "\n";
                }
            }
            { no strict 'refs'; close($fhn) }
            return 1;
        }
        # else: scalar sequence with no header -- fall through to no_header path
    }

    # no_header path (or scalar sequence)
    for my $item (@items) {
        if (ref($item) eq 'HASH') {
            my @cols = sort keys %{$item};
            { no strict 'refs'; print {*{$fhn}} join($sep, map {
                _format_csv_field($item->{$_}, $sep)
            } @cols) . "\n" }
        }
        else {
            { no strict 'refs'; print {*{$fhn}} _format_csv_field($item, $sep) . "\n" }
        }
    }
    { no strict 'refs'; close($fhn) }
    return 1;
}

###############################################################################
# Utility Methods
###############################################################################

# ForEach - execute action for each element
sub ForEach {
    my($self, $action) = @_;
    my $iter = $self->iterator;

    while (defined(my $item = $iter->())) {
        $action->($item);
    }
    return;
}

1;

######################################################################
#
# JSON::LINQ::Ordered - Ordered query supporting ThenBy/ThenByDescending
#
# Returned by OrderBy* methods.  Inherits all JSON::LINQ methods via @ISA.
# Stability guarantee: Schwartzian-Transform stable sort, all Perl versions.
#
######################################################################

package JSON::LINQ::Ordered;

@JSON::LINQ::Ordered::ISA = ('JSON::LINQ');

sub _new_ordered {
    my($class, $items, $specs) = @_;
    return bless {
        _items   => $items,
        _specs   => $specs,
        _factory => sub {
            my @sorted = _perform_sort($items, $specs);
            my $i = 0;
            return sub { $i < scalar(@sorted) ? $sorted[$i++] : undef };
        },
    }, $class;
}

sub _perform_sort {
    my($items, $specs) = @_;

    my @decorated = map {
        my $idx  = $_;
        my $item = $items->[$idx];
        my @keys = map { _extract_key($_->{sel}->($item), $_->{type}) } @{$specs};
        [$idx, [ @keys ], $item]
    } 0 .. $#{$items};

    my @sorted_dec = sort {
        my $r = 0;
        for my $i (0 .. $#{$specs}) {
            my $cmp = _compare_keys($a->[1][$i], $b->[1][$i], $specs->[$i]{type});
            if ($specs->[$i]{dir} < 0) { $cmp = -$cmp }
            if ($cmp != 0) { $r = $cmp; last }
        }
        $r != 0 ? $r : ($a->[0] <=> $b->[0]);
    } @decorated;

    return map { $_->[2] } @sorted_dec;
}

sub _extract_key {
    my($val, $type) = @_;
    $val = '' unless defined $val;
    if ($type eq 'num') {
        return defined($val) && length($val) ? $val + 0 : 0;
    }
    elsif ($type eq 'str') {
        return "$val";
    }
    else {
        my $t = $val;
        $t =~ s/^\s+|\s+$//g;
        if ($t =~ /^[+-]?(?:\d+\.?\d*|\d*\.\d+)(?:[eE][+-]?\d+)?$/) {
            return [0, $t + 0];
        }
        else {
            return [1, "$val"];
        }
    }
}

sub _compare_keys {
    my($ka, $kb, $type) = @_;
    if ($type eq 'num') {
        return $ka <=> $kb;
    }
    elsif ($type eq 'str') {
        return $ka cmp $kb;
    }
    else {
        my $fa = $ka->[0];  my $va = $ka->[1];
        my $fb = $kb->[0];  my $vb = $kb->[1];
        if    ($fa == 0 && $fb == 0) { return $va <=> $vb }
        elsif ($fa == 1 && $fb == 1) { return $va cmp $vb }
        else                         { return $fa <=> $fb  }
    }
}

sub _thenby {
    my($self, $key_selector, $dir, $type) = @_;
    my @new_specs = (@{$self->{_specs}}, { sel => $key_selector, dir => $dir, type => $type });
    return JSON::LINQ::Ordered->_new_ordered($self->{_items}, [ @new_specs ]);
}

sub ThenBy            { my($s, $k)=@_; $s->_thenby($k, 1, 'smart') }
sub ThenByDescending  { my($s, $k)=@_; $s->_thenby($k, -1, 'smart') }
sub ThenByStr         { my($s, $k)=@_; $s->_thenby($k, 1, 'str')   }
sub ThenByStrDescending { my($s, $k)=@_; $s->_thenby($k, -1, 'str') }
sub ThenByNum         { my($s, $k)=@_; $s->_thenby($k, 1, 'num')   }
sub ThenByNumDescending { my($s, $k)=@_; $s->_thenby($k, -1, 'num') }

1;

=encoding utf-8

=head1 NAME

JSON::LINQ - LINQ-style query interface for JSON, JSONL, LTSV, and CSV files

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

  use JSON::LINQ;

  # Read JSON file (array of objects) and query
  my @results = JSON::LINQ->FromJSON("users.json")
      ->Where(sub { $_[0]{age} >= 18 })
      ->Select(sub { $_[0]{name} })
      ->Distinct()
      ->ToArray();

  # Read JSONL (JSON Lines) file - one JSON object per line
  my @errors = JSON::LINQ->FromJSONL("events.jsonl")
      ->Where(sub { $_[0]{level} eq 'ERROR' })
      ->ToArray();

  # DSL syntax for simple filtering
  my @active = JSON::LINQ->FromJSON("users.json")
      ->Where(status => 'active')
      ->ToArray();

  # Grouping and aggregation
  my @stats = JSON::LINQ->FromJSON("orders.json")
      ->GroupBy(sub { $_[0]{category} })
      ->Select(sub {
          my $g = shift;
          return {
              Category => $g->{Key},
              Count    => scalar(@{$g->{Elements}}),
              Total    => JSON::LINQ->From($g->{Elements})
                              ->Sum(sub { $_[0]{amount} }),
          };
      })
      ->OrderByDescending(sub { $_[0]{Total} })
      ->ToArray();

  # Write results back as JSON or JSONL
  JSON::LINQ->From(\@results)->ToJSON("output.json");
  JSON::LINQ->From(\@results)->ToJSONL("output.jsonl");

  # Read/write CSV files (Comma-Separated Values)
  my @rows = JSON::LINQ->FromCSV("access.csv")
      ->Where(sub { $_[0]{status} eq '200' })
      ->ToArray();
  JSON::LINQ->From(\@rows)->ToCSV("filtered.csv");

  # JOIN a JSON file (main) with a CSV lookup table
  my $depts = JSON::LINQ->FromCSV("departments.csv");
  my @joined = JSON::LINQ->FromJSON("employees.json")
      ->Join($depts,
          sub { $_[0]{dept_id} },
          sub { $_[0]{id}      },
          sub { { name => $_[0]{name}, dept => $_[1]{name} } })
      ->ToArray();

  # CSV to JSON conversion
  JSON::LINQ->FromCSV("data.csv")
      ->Where(sub { $_[0]{active} eq '1' })
      ->ToJSON("active.json");

  # Read/write LTSV files (Labeled Tab-Separated Values)
  my @rows = JSON::LINQ->FromLTSV("access.ltsv")
      ->Where(sub { $_[0]{status} eq '200' })
      ->ToArray();
  JSON::LINQ->From(\@rows)->ToLTSV("filtered.ltsv");

  # JOIN a JSON file (main) with an LTSV file (sub-table)
  my $depts = JSON::LINQ->FromLTSV("departments.ltsv");
  my @joined = JSON::LINQ->FromJSON("employees.json")
      ->Join($depts,
          sub { $_[0]{dept_id} },
          sub { $_[0]{id}      },
          sub { { name => $_[0]{name}, dept => $_[1]{name} } })
      ->ToArray();

  # JOIN an LTSV file (main) with a JSON file (sub-table)
  my $prices = JSON::LINQ->FromJSON("prices.json");
  my @priced = JSON::LINQ->FromLTSV("orders.ltsv")
      ->Join($prices,
          sub { $_[0]{sku} },
          sub { $_[0]{sku} },
          sub { { order_id => $_[0]{id},
                  amount   => $_[0]{qty} * $_[1]{price} } })
      ->ToArray();

  # Boolean values
  my $rec = { active => JSON::LINQ::true, count => 0 };
  JSON::LINQ->From([$rec])->ToJSON("output.json");
  # ToJSON encodes as: {"active":true,"count":0}

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</INCLUDED DOCUMENTATION> -- eg/ samples and doc/ cheat sheets

=item * L</METHODS> -- Complete method reference (67 methods)

=item * L</EXAMPLES> -- Practical examples

=item * L</FEATURES> -- Lazy evaluation, method chaining, DSL

=item * L</ARCHITECTURE> -- Iterator design, execution flow

=item * L</COMPATIBILITY> -- Perl 5.005+ support, pure Perl

=item * L</DIAGNOSTICS> -- Error messages

=item * L</LIMITATIONS AND KNOWN ISSUES>

=item * L</BUGS>

=item * L</SEE ALSO>

=back

=head1 DESCRIPTION

JSON::LINQ provides a LINQ-style query interface for JSON, JSONL
(JSON Lines), and LTSV (Labeled Tab-Separated Values) files. It is
the JSON counterpart of L<LTSV::LINQ>, sharing the same LINQ API and
adding JSON-specific I/O methods.

Key features:

=over 4

=item * B<Lazy evaluation> - O(1) memory for JSONL and LTSV streaming;
JSON arrays are loaded once then iterated lazily

=item * B<Method chaining> - Fluent, readable query composition

=item * B<DSL syntax> - Simple key-value filtering

=item * B<67 LINQ methods> - including JSON I/O (FromJSON, FromJSONL,
FromJSONString, ToJSON, ToJSONL), LTSV I/O (FromLTSV, ToLTSV),
CSV I/O (FromCSV, ToCSV), and all 60 methods from L<LTSV::LINQ>

=item * B<Pure Perl> - No XS dependencies

=item * B<Perl 5.005_03+> - Works on ancient and modern Perl

=item * B<Built-in JSON parser> - No CPAN JSON module required

=back

=head2 Supported Data Sources

=over 4

=item * B<FromJSON($file)> - JSON file containing a top-level array or object

=item * B<FromJSONL($file)> - JSONL file (one JSON value per line)

=item * B<FromJSONString($json)> - JSON string (array or object)

=item * B<FromLTSV($file)> - LTSV file (Labeled Tab-Separated Values)

=item * B<FromCSV($file)> - CSV file (Comma-Separated Values; also TSV via sep option)

=item * B<From(\@array)> - In-memory Perl array

=item * B<Range($start, $count)> - Integer sequence

=item * B<Empty()> - Empty sequence

=item * B<Repeat($element, $count)> - Repeated element

=back

=head2 What is JSONL?

JSONL (JSON Lines, also known as ndjson - newline-delimited JSON) is a
text format where each line is a valid JSON value (typically an object).
It is particularly suited for log files and streaming data because:

=over 4

=item * One record per line enables streaming with O(1) memory usage

=item * Compatible with standard Unix tools (grep, sed, awk)

=item * Easily appendable without rewriting the whole file

=item * Each line is independently parseable

=back

B<Format example:>

  {"time":"2026-04-20T10:00:00","host":"192.0.2.1","status":200,"url":"/"}
  {"time":"2026-04-20T10:00:01","host":"192.0.2.2","status":404,"url":"/missing"}

C<FromJSONL> reads these files lazily (one line at a time), matching the
memory efficiency of C<LTSV::LINQ>'s C<FromLTSV>.

=head2 What is LINQ?

LINQ (Language Integrated Query) is the Microsoft .NET query API.
This module brings the same LINQ interface to JSON data in Perl.
See L<LTSV::LINQ> for a detailed description of the LINQ design philosophy.

=head1 INCLUDED DOCUMENTATION

The C<eg/> directory contains sample programs:

  eg/01_json_query.pl       FromJSON/Where/Select/OrderByDescending/Distinct/ToLookup
  eg/02_jsonl_query.pl      FromJSONL streaming, GroupBy, aggregation, ToJSONL
  eg/03_grouping.pl         GroupBy, ToLookup, GroupJoin, SelectMany, Join
  eg/04_sorting.pl          OrderBy/ThenBy multi-key sort, OrderByNum vs OrderByStr
  eg/05_json_ltsv_join.pl   JOIN main JSON x sub-table LTSV
  eg/06_ltsv_json_join.pl   JOIN main LTSV x sub-table JSON
  eg/07_csv_query.pl        FromCSV/Where/Select/GroupBy/OrderByNum/ToCSV
  eg/08_csv_json_join.pl    JOIN main CSV x sub-table JSON, CSV to JSON conversion

The C<doc/> directory contains JSON::LINQ cheat sheets in 21 languages:

  doc/json_linq_cheatsheet.EN.txt   English
  doc/json_linq_cheatsheet.JA.txt   Japanese
  doc/json_linq_cheatsheet.ZH.txt   Chinese (Simplified)
  doc/json_linq_cheatsheet.TW.txt   Chinese (Traditional)
  doc/json_linq_cheatsheet.KO.txt   Korean
  doc/json_linq_cheatsheet.FR.txt   French
  doc/json_linq_cheatsheet.ID.txt   Indonesian
  doc/json_linq_cheatsheet.VI.txt   Vietnamese
  doc/json_linq_cheatsheet.TH.txt   Thai
  doc/json_linq_cheatsheet.HI.txt   Hindi
  doc/json_linq_cheatsheet.BN.txt   Bengali
  doc/json_linq_cheatsheet.TR.txt   Turkish
  doc/json_linq_cheatsheet.MY.txt   Burmese
  doc/json_linq_cheatsheet.TL.txt   Filipino
  doc/json_linq_cheatsheet.KM.txt   Khmer
  doc/json_linq_cheatsheet.MN.txt   Mongolian
  doc/json_linq_cheatsheet.NE.txt   Nepali
  doc/json_linq_cheatsheet.SI.txt   Sinhala
  doc/json_linq_cheatsheet.UR.txt   Urdu
  doc/json_linq_cheatsheet.UZ.txt   Uzbek
  doc/json_linq_cheatsheet.BM.txt   Malay

=head1 METHODS

=head2 Complete Method Reference

This module implements 67 LINQ methods organized into 15 categories.
In addition, C<true> and C<false> boolean accessor functions are provided.

=over 4

=item * B<Data Sources (9)>: From, FromJSON, FromJSONL, FromJSONString, FromLTSV, FromCSV, Range, Empty, Repeat

=item * B<Filtering (1)>: Where (with DSL)

=item * B<Projection (2)>: Select, SelectMany

=item * B<Concatenation (2)>: Concat, Zip

=item * B<Partitioning (4)>: Take, Skip, TakeWhile, SkipWhile

=item * B<Ordering (13)>: OrderBy, OrderByDescending, OrderByStr, OrderByStrDescending, OrderByNum, OrderByNumDescending, Reverse, ThenBy, ThenByDescending, ThenByStr, ThenByStrDescending, ThenByNum, ThenByNumDescending

=item * B<Grouping (1)>: GroupBy

=item * B<Set Operations (4)>: Distinct, Union, Intersect, Except

=item * B<Join (2)>: Join, GroupJoin

=item * B<Quantifiers (3)>: All, Any, Contains

=item * B<Comparison (1)>: SequenceEqual

=item * B<Element Access (8)>: First, FirstOrDefault, Last, LastOrDefault, Single, SingleOrDefault, ElementAt, ElementAtOrDefault

=item * B<Aggregation (7)>: Count, Sum, Min, Max, Average, AverageOrDefault, Aggregate

=item * B<Conversion (9)>: ToArray, ToList, ToDictionary, ToLookup, ToJSON, ToJSONL, ToLTSV, ToCSV, DefaultIfEmpty

=item * B<Utility (1)>: ForEach

=back

=head2 JSON-Specific Data Source Methods

=over 4

=item B<FromJSON($filename)>

Read a JSON file containing a top-level array of values. Each element of
the array becomes one item in the sequence.

  my $q = JSON::LINQ->FromJSON("users.json");

If the file contains a single JSON object (not an array), it is treated
as a one-element sequence.

B<File format:>

  [
    {"name": "Alice", "age": 30},
    {"name": "Bob",   "age": 25}
  ]

The entire file is read into memory and parsed once. For large files,
consider JSONL format with C<FromJSONL> for streaming access.

B<Concurrent use (e.g. Join/GroupJoin):> On Perl 5.006 and later,
each call to C<FromJSON> uses a distinct numbered filehandle slot, so
multiple iterators may be open simultaneously without interference.
On Perl 5.005_03, a unique numbered package glob is used per call
(JSON::LINQ::FH::H1, JSON::LINQ::FH::H2, ...) to achieve the same safety.

=item B<FromJSONL($filename)>

Read a JSONL (JSON Lines) file. Each non-empty line is parsed as a
separate JSON value. Empty lines and lines starting with C<#> are skipped.

  my $q = JSON::LINQ->FromJSONL("events.jsonl");

B<File format:>

  {"event":"login","user":"alice","ts":1713600000}
  {"event":"purchase","user":"alice","ts":1713600060,"amount":29.99}
  {"event":"logout","user":"alice","ts":1713600120}

C<FromJSONL> reads lazily (one line at a time), providing O(1) memory
usage for arbitrarily large files.

Invalid JSON lines produce a warning and are skipped rather than
aborting the entire sequence.

B<Concurrent use (e.g. Join/GroupJoin):> On Perl 5.006 and later,
each call to C<FromJSONL> uses a distinct numbered filehandle slot, so
multiple iterators may be open simultaneously without interference.
On Perl 5.005_03, a unique numbered package glob is used per call
(JSON::LINQ::FH::H1, JSON::LINQ::FH::H2, ...) to achieve the same safety.

=item B<FromJSONString($json)>

Create a query from a JSON string. Accepts a JSON array (each element
becomes one sequence item) or a JSON object (single-element sequence).

  my $q = JSON::LINQ->FromJSONString('[{"id":1},{"id":2}]');
  my $q = JSON::LINQ->FromJSONString('{"id":1,"name":"Alice"}');

=back

=head2 LTSV Interoperability

To make it easy to JOIN JSON data with LTSV master/lookup tables (or vice
versa) without requiring L<LTSV::LINQ> to be installed, JSON::LINQ ships
with built-in LTSV I/O methods. The LTSV format is described at
L<https://ltsv.org/>.

=over 4

=item B<FromLTSV($filename)>

Read an LTSV (Labeled Tab-Separated Values) file. Each line is split on
TAB, and each field is split on the first colon to produce a label/value
pair. The result is a sequence of hash references.

  my $q = JSON::LINQ->FromLTSV("departments.ltsv");

B<File format:>

  id:1<TAB>name:Engineering<TAB>head:Alice
  id:2<TAB>name:Sales<TAB>head:Bob

C<FromLTSV> reads lazily (one line at a time), so memory usage is O(1)
even for very large files. Empty lines are skipped. CR is stripped to
handle CRLF files on any platform.

B<Concurrent use (e.g. Join/GroupJoin):> On Perl 5.006 and later,
each call to C<FromLTSV> uses a distinct numbered filehandle slot, so
multiple iterators may be open simultaneously without interference.
On Perl 5.005_03, a unique numbered package glob is used per call
(JSON::LINQ::FH::H1, JSON::LINQ::FH::H2, ...) to achieve the same safety.

=item B<ToLTSV($filename)>

=item B<ToLTSV($filename, label_order =E<gt> \@labels)>

=item B<ToLTSV($filename, headers =E<gt> \@labels)>

Write the sequence as an LTSV file. Each element must be a HASH reference.
TAB, CR, and LF in values are sanitized to a single space to keep the file
structurally valid.

  $query->ToLTSV("output.ltsv");

B<Output format (default - all keys, alphabetical):>

  age:30<TAB>name:Alice
  age:25<TAB>name:Bob

B<label_order> (or its alias B<headers>) specifies which labels to emit and
in what order. Labels not present in a record are silently skipped.

  $query->ToLTSV("output.ltsv", label_order => [qw(name age)]);
  $query->ToLTSV("output.ltsv", headers     => [qw(name age)]);

B<Output format (with label_order):>

  name:Alice<TAB>age:30
  name:Bob<TAB>age:25

=back

=head2 CSV Interoperability

CSV (Comma-Separated Values) is the most widely used format for tabular
data exchange. C<FromCSV> and C<ToCSV> let a JSON::LINQ pipeline read
from and write to CSV files without requiring any extra CPAN module.

The separator character defaults to C<','> but can be set to C<"\t"> to
handle TSV (Tab-Separated Values) files, or any other single character.

=over 4

=item B<FromCSV($filename)>

=item B<FromCSV($filename, sep =E<gt> $char)>

=item B<FromCSV($filename, headers =E<gt> \@cols)>

=item B<FromCSV($filename, headers =E<gt> \@cols, skip_header =E<gt> 1)>

Read a CSV file. The first line is used as the header row (column names),
and each subsequent data row is returned as a hash reference with those
column names as keys.

B<Options:>

=over 4

=item C<sep> - Field separator character (default: C<','>). Use C<"\t"> for TSV.

=item C<headers> - Array reference of column names. When given, the first
data line is treated as data rather than a header. Combine with
C<skip_header =E<gt> 1> to skip an existing header row in the file.

=item C<skip_header> - If true, skip the first line of the file even when
C<headers> is given.

=back

  # Standard CSV with header row
  my $q = JSON::LINQ->FromCSV("data.csv");

  # Tab-separated (TSV)
  my $q = JSON::LINQ->FromCSV("data.tsv", sep => "\t");

  # Headerless CSV with explicit column names
  my $q = JSON::LINQ->FromCSV("noheader.csv",
      headers => [qw(name age city)]);

C<FromCSV> reads the file lazily (one line at a time), providing O(1)
memory usage for arbitrarily large files.

B<RFC 4180 compliance:> Quoted fields (including fields containing
the separator, double-quotes escaped as C<"">, or newline characters)
are handled correctly. See L</LIMITATIONS AND KNOWN ISSUES> for the
one known exception (multi-line quoted fields).

B<Concurrent use (e.g. Join/GroupJoin):> Each call to C<FromCSV> uses a
unique numbered package glob (JSON::LINQ::FH::H1, H2, ...) on all Perl
versions, so multiple CSV iterators may be open simultaneously without
interference.

=item B<ToCSV($filename)>

=item B<ToCSV($filename, sep =E<gt> $char)>

=item B<ToCSV($filename, headers =E<gt> \@cols)>

=item B<ToCSV($filename, label_order =E<gt> \@cols)>

=item B<ToCSV($filename, no_header =E<gt> 1)>

Write the sequence as a CSV file.

B<Options:>

=over 4

=item C<sep> - Field separator character (default: C<','>).

=item C<headers> - Array reference of column names that controls which keys
are written and in what order. Also serves as the header row.

=item C<label_order> - Alias for C<headers>.

=item C<no_header> - If true, suppress the header row entirely.

=back

  $query->ToCSV("output.csv");
  $query->ToCSV("output.tsv", sep => "\t");
  $query->ToCSV("output.csv", headers => [qw(name age city)]);

When C<headers>/C<label_order> is not supplied and elements are HASH
references, column names are taken from the first record's keys in
alphabetical order.

=back

=head2 JSON-Specific Conversion Methods

=over 4

=item B<ToJSON($filename)>

Write the sequence as a JSON file containing a JSON array. Each element
is encoded as JSON. The output is a valid JSON array.

  $query->ToJSON("output.json");

B<Output format:>

  [
  {"age":30,"name":"Alice"},
  {"age":25,"name":"Bob"}
  ]

Hash keys are sorted alphabetically for deterministic output.

=item B<ToJSONL($filename)>

Write the sequence as a JSONL file. Each element is written as one line
of JSON. This is the streaming counterpart of C<ToJSON>.

  $query->ToJSONL("output.jsonl");

B<Output format:>

  {"age":30,"name":"Alice"}
  {"age":25,"name":"Bob"}

=back

=head2 Boolean Values

JSON::LINQ provides boolean singleton objects compatible with JSON encoding:

  JSON::LINQ::true   # stringifies as "true",  numifies as 1
  JSON::LINQ::false  # stringifies as "false", numifies as 0

Use these when creating data structures that will be serialised to JSON:

  my $rec = { active => JSON::LINQ::true, count => 0 };
  # ToJSON encodes as: {"active":true,"count":0}

When C<FromJSON> or C<FromJSONL> decode a JSON C<true> or C<false>,
the result is a C<JSON::LINQ::Boolean> object that behaves as 1 or 0
in numeric and boolean context.

=head2 All Other Methods

All other LINQ methods are inherited from L<LTSV::LINQ> and behave
identically. Please refer to L<LTSV::LINQ> for complete documentation of:

Where, Select, SelectMany, Concat, Zip, Take, Skip, TakeWhile,
SkipWhile, OrderBy, OrderByDescending, OrderByStr, OrderByStrDescending,
OrderByNum, OrderByNumDescending, Reverse, ThenBy, ThenByDescending,
ThenByStr, ThenByStrDescending, ThenByNum, ThenByNumDescending, GroupBy,
Distinct, Union, Intersect, Except, Join, GroupJoin, All, Any, Contains,
SequenceEqual, First, FirstOrDefault, Last, LastOrDefault, Single,
SingleOrDefault, ElementAt, ElementAtOrDefault, Count, Sum, Min, Max,
Average, AverageOrDefault, Aggregate, ToArray, ToList, ToDictionary,
ToLookup, DefaultIfEmpty, ForEach.

=head1 EXAMPLES

=head2 Basic JSON File Query

  use JSON::LINQ;

  # users.json: [{"name":"Alice","age":30}, {"name":"Bob","age":25}, ...]
  my @adults = JSON::LINQ->FromJSON("users.json")
      ->Where(sub { $_[0]{age} >= 18 })
      ->OrderBy(sub { $_[0]{name} })
      ->ToArray();

=head2 JSONL Streaming

  # events.jsonl: one JSON object per line
  my $error_count = JSON::LINQ->FromJSONL("events.jsonl")
      ->Count(sub { $_[0]{level} eq 'ERROR' });

  JSON::LINQ->FromJSONL("events.jsonl")
      ->Where(sub { $_[0]{level} eq 'ERROR' })
      ->ForEach(sub { print $_[0]{message}, "\n" });

=head2 Aggregation

  my $avg = JSON::LINQ->FromJSON("orders.json")
      ->Where(sub { $_[0]{status} eq 'completed' })
      ->Average(sub { $_[0]{amount} });

  printf "Average order: %.2f\n", $avg;

=head2 Grouping

  my @by_category = JSON::LINQ->FromJSON("products.json")
      ->GroupBy(sub { $_[0]{category} })
      ->Select(sub {
          my $g = shift;
          {
              Category => $g->{Key},
              Count    => scalar(@{$g->{Elements}}),
              MaxPrice => JSON::LINQ->From($g->{Elements})
                              ->Max(sub { $_[0]{price} }),
          }
      })
      ->OrderByDescending(sub { $_[0]{Count} })
      ->ToArray();

=head2 Transform and Write

  # Read JSON, transform, write back as JSONL
  JSON::LINQ->FromJSON("input.json")
      ->Select(sub {
          my $r = shift;
          return { %$r, processed => JSON::LINQ::true };
      })
      ->ToJSONL("output.jsonl");

=head2 JOIN: JSON (main) with LTSV (sub-table)

A common pattern: the primary records live in a JSON file, and a small
lookup table is maintained in LTSV format. The example below reads
employees from a JSON file and joins them against a department lookup
table in LTSV format.

  # employees.json
  # [
  #   {"id":1,"name":"Alice","dept_id":10},
  #   {"id":2,"name":"Bob",  "dept_id":20},
  #   {"id":3,"name":"Carol","dept_id":10}
  # ]
  #
  # departments.ltsv
  # id:10<TAB>name:Engineering
  # id:20<TAB>name:Sales

  my $depts = JSON::LINQ->FromLTSV("departments.ltsv");

  my @joined = JSON::LINQ->FromJSON("employees.json")
      ->Join($depts,
          sub { $_[0]{dept_id} },     # outer key (JSON side)
          sub { $_[0]{id}      },     # inner key (LTSV side)
          sub { { name => $_[0]{name},
                  dept => $_[1]{name} } })
      ->OrderBy(sub { $_[0]{name} })
      ->ToArray();

  # @joined == ({name=>"Alice", dept=>"Engineering"},
  #             {name=>"Bob",   dept=>"Sales"},
  #             {name=>"Carol", dept=>"Engineering"})

=head2 JOIN: LTSV (main) with JSON (sub-table)

The opposite pattern: the primary records are in an LTSV log file (often
high-volume, append-only), and the lookup table is in JSON.

  # orders.ltsv
  # id:1001<TAB>sku:A100<TAB>qty:2
  # id:1002<TAB>sku:B200<TAB>qty:1
  # id:1003<TAB>sku:A100<TAB>qty:5
  #
  # prices.json
  # [
  #   {"sku":"A100","price":300},
  #   {"sku":"B200","price":1200}
  # ]

  my $prices = JSON::LINQ->FromJSON("prices.json");

  my @priced = JSON::LINQ->FromLTSV("orders.ltsv")
      ->Join($prices,
          sub { $_[0]{sku} },                       # outer key (LTSV)
          sub { $_[0]{sku} },                       # inner key (JSON)
          sub { { order_id => $_[0]{id},
                  amount   => $_[0]{qty} * $_[1]{price} } })
      ->ToArray();

  # @priced == ({order_id=>1001, amount=>600},
  #             {order_id=>1002, amount=>1200},
  #             {order_id=>1003, amount=>1500})

C<Join> builds a hash from the inner (sub-table) sequence, so it is
efficient even when the outer sequence is large and read lazily.

C<Join> builds a hash from the inner (sub-table) sequence, so it is
efficient even when the outer sequence is large and read lazily.

=head2 Basic CSV Query

  use JSON::LINQ;

  # sales.csv:
  #   name,amount,category
  #   Alice,1500,A
  #   Bob,800,B
  #   Carol,2000,A

  my @high_sales = JSON::LINQ->FromCSV("sales.csv")
      ->Where(sub { $_[0]{amount} > 1000 })
      ->OrderByNumDescending(sub { $_[0]{amount} })
      ->ToArray();

=head2 DSL Filtering on CSV

  my @tokyo = JSON::LINQ->FromCSV("users.csv")
      ->Where(city => 'Tokyo')
      ->ToArray();

=head2 Grouping and Aggregation on CSV

  my @by_category = JSON::LINQ->FromCSV("sales.csv")
      ->GroupBy(sub { $_[0]{category} })
      ->Select(sub {
          my $g = shift;
          {
              Category => $g->{Key},
              Count    => scalar(@{$g->{Elements}}),
              Total    => JSON::LINQ->From($g->{Elements})
                              ->Sum(sub { $_[0]{amount} }),
          }
      })
      ->OrderByStrDescending(sub { $_[0]{Total} })
      ->ToArray();

=head2 JOIN Two CSV Files

  # orders.csv: id,customer_id,amount
  # customers.csv: id,name,city

  my $orders    = JSON::LINQ->FromCSV("orders.csv");
  my $customers = JSON::LINQ->FromCSV("customers.csv");

  my @joined = $orders->Join(
      $customers,
      sub { $_[0]{customer_id} },
      sub { $_[0]{id} },
      sub { { Name => $_[1]{name}, Amount => $_[0]{amount} } }
  )->ToArray();

=head2 TSV Support

  my @data = JSON::LINQ->FromCSV("data.tsv", sep => "\t")
      ->Where(status => 'active')
      ->ToArray();

=head2 CSV Round-Trip (Filter and Write)

  JSON::LINQ->FromCSV("input.csv")
      ->Where(sub { $_[0]{active} eq '1' })
      ->ToCSV("active.csv");

=head2 CSV to JSON Conversion

  JSON::LINQ->FromCSV("data.csv")
      ->Select(sub {
          my $r = shift;
          return { %$r, processed => JSON::LINQ::true };
      })
      ->ToJSON("data.json");

=head2 In-Memory Array Query

  my @data = (
      {name => 'Alice', score => 95},
      {name => 'Bob',   score => 72},
      {name => 'Carol', score => 88},
  );

  my @top = JSON::LINQ->From(\@data)
      ->Where(sub { $_[0]{score} >= 80 })
      ->OrderByDescending(sub { $_[0]{score} })
      ->ToArray();

=head1 FEATURES

=head2 Lazy Evaluation

C<FromJSONL> reads one line at a time. Combined with C<Where> and C<Take>,
only the needed records are ever in memory simultaneously.

C<FromJSON> reads the whole file once but then iterates the array lazily.

=head2 Built-in JSON Parser

JSON::LINQ contains its own JSON encoder/decoder (derived from mb::JSON 0.06).
No CPAN JSON module is required. The parser handles:

=over 4

=item * UTF-8 multibyte strings (output as-is, not \uXXXX-escaped)

=item * C<\uXXXX> escape sequences on input (converted to UTF-8)

=item * All JSON types: object, array, string, number, true, false, null

=item * Nested structures of arbitrary depth

=back

=head1 ARCHITECTURE

=head2 Relationship to LTSV::LINQ

JSON::LINQ and LTSV::LINQ are parallel modules sharing the same LINQ API.

  LTSV::LINQ  - LINQ for LTSV (Labeled Tab-Separated Values) files
  JSON::LINQ  - LINQ for JSON and JSONL files

Both share the same LINQ API. JSON::LINQ adds the following I/O methods
on top of LTSV::LINQ's interface:

  FromJSON($file)         - read JSON array file
  FromJSONL($file)        - read JSONL file (streaming)
  FromJSONString($json)   - read JSON string
  FromLTSV($file)         - read LTSV file (streaming)
  FromCSV($file)          - read CSV file (streaming, RFC 4180)
  ToJSON($file)           - write JSON array file
  ToJSONL($file)          - write JSONL file
  ToLTSV($file)           - write LTSV file (streaming)
  ToCSV($file)            - write CSV file

C<FromLTSV>, C<ToLTSV>, C<FromCSV>, and C<ToCSV> are provided so a
JSON::LINQ pipeline can JOIN against (or emit into) LTSV and CSV files
without requiring LTSV::LINQ or CSV::LINQ to be installed.

The internal iterator architecture is identical: each operator returns a
new query object wrapping a closure.

=head2 Memory Characteristics

  FromJSONL  - O(1) per record: one line at a time
  FromJSON   - O(n): entire file loaded once, then lazy iteration
  FromLTSV   - O(1) per record: one line at a time
  FromCSV    - O(1) per record: one line at a time
  ToJSON     - O(n): entire sequence collected for array output
  ToJSONL    - O(1) per record: streaming write
  ToLTSV     - O(1) per record: streaming write
  ToCSV      - O(n): entire sequence collected before writing header

=head1 COMPATIBILITY

=head2 Perl Version Support

Compatible with B<Perl 5.00503 and later>. See L<LTSV::LINQ> for the
full compatibility rationale (Universal Consensus 1998 / Perl 5.005_03).

=head2 Pure Perl Implementation

No XS dependencies. No CPAN module dependencies. Works on any Perl
installation with only the standard core.

=head2 JSON Limitations

The built-in parser has the same limitations as mb::JSON 0.06:

=over 4

=item * Surrogate pairs (C<\uD800>-C<\uDFFF>) are not supported

=item * Circular references in encoding cause infinite recursion

=item * Non-ARRAY/HASH references are stringified

=back

=head2 Iterator Protocol and JSON null

The internal iterator protocol uses C<undef> to signal end-of-sequence.
As a consequence, an C<undef> value (i.e. a decoded JSON C<null>) cannot
appear as a I<top-level element> of a sequence: it would be
indistinguishable from EOF and the sequence would be silently truncated
at that point.

This affects C<Select> in particular: a selector that returns C<undef>
for some elements will terminate the sequence early.

  # JSON: [{"v":1},{"v":null},{"v":3}]
  JSON::LINQ->FromJSON("data.json")
            ->Select(sub { $_[0]{v} })
            ->ToArray;
  # returns (1) - sequence stops at the undef from the second record

C<Where> is unaffected when filtering hash records (the hashref itself
is the element, not its C<v> field), but a C<Select> that projects a
nullable field will be truncated at the first C<null>. Workarounds:

=over 4

=item * Project to a sentinel value: C<< Select(sub { defined $_[0]{v} ? $_[0]{v} : '' }) >>

=item * Wrap each element in a hashref so the element itself is never undef.

=back

C<DefaultIfEmpty(undef)> is similarly affected: a default of C<undef>
is silently lost. Use a non-undef sentinel (C<0>, C<''>, C<{}>) instead.

=head1 DIAGNOSTICS

=over 4

=item C<JSON::LINQ::FromJSON: cannot parse '$file': $@>

The file exists but does not contain valid JSON.

=item C<JSON::LINQ::FromJSON: '$file' must contain a JSON array or object>

The file contains valid JSON but the top-level value is a string, number,
or boolean, not an array or object.

=item C<JSON::LINQ::FromJSONL: skipping invalid JSON line: $@>

A line in a JSONL file could not be parsed. The line is skipped with a
warning; processing continues.

=item C<JSON::LINQ::FromJSONString: cannot parse JSON: $@>

The supplied JSON string is not valid JSON.

=item C<JSON::LINQ::_json_decode: ...>

Internal JSON parsing error.  The message includes the specific unexpected
token or an indication of where parsing stopped.

=item C<JSON::LINQ::_json_decode: expected ',' or ']' in array>

The JSON array was not properly terminated or separated.

=item C<JSON::LINQ::_json_decode: expected ',' or '}' in object>

A JSON object was not properly terminated or separated.

=item C<JSON::LINQ::_json_decode: expected ':' after key '$key'>

The colon separator was missing after a JSON object key.

=item C<JSON::LINQ::_json_decode: expected string key in object>

A JSON object key was not a quoted string.

=item C<JSON::LINQ::_json_decode: trailing garbage: >

Extra text was found after a successfully parsed top-level JSON value.
The message is followed by the first 20 characters of the unexpected text.

=item C<JSON::LINQ::_json_decode: unexpected end of input>

The JSON text ended before a complete value was parsed.

=item C<JSON::LINQ::_json_decode: unexpected token: >

An unrecognised token was encountered while parsing JSON.
The message is followed by the first 20 characters of the unexpected text.

=item C<JSON::LINQ::_json_decode: unterminated string>

A JSON string was not closed with a double-quote.

=item C<Cannot open '$file': $!>

Thrown by C<FromJSON>, C<FromJSONL>, C<FromLTSV>, or C<FromCSV> when the input file
cannot be opened.

=item C<Cannot open '$filename': $!>

Thrown by C<ToJSON>, C<ToJSONL>, C<ToLTSV>, or C<ToCSV> when the output file
cannot be opened.

=item C<From() requires ARRAY reference>

Thrown by C<From()> when the argument is not an array reference.

=item C<Index must be non-negative>

Thrown by C<ElementAt()> when the supplied index is less than zero.

=item C<Index out of range>

Thrown by C<ElementAt()> when the index is beyond the end of the sequence.
Use C<ElementAtOrDefault()> to avoid this error.

=item C<Invalid number of arguments for Aggregate>

Thrown by C<Aggregate()> when called with an argument count other than 1, 2, or 3.

=item C<Sequence contains no elements>

Thrown by C<First()>, C<Last()>, C<Average()>, C<Aggregate()> (no-seed form), and
C<Single()> when the sequence is empty or no element satisfies the predicate.

=item C<Sequence contains more than one element>

Thrown by C<Single()> when more than one element (or matching element) is found.

=item C<No element satisfies the condition>

Thrown by C<First()> or C<Last()> with a predicate when no element matches.

=item C<SelectMany: selector must return an ARRAY reference>

Thrown by C<SelectMany()> when the selector function returns a non-array value.

=back

All other error messages are identical to L<LTSV::LINQ>.

=head1 LIMITATIONS AND KNOWN ISSUES

=over 4

=item * B<Iterator Consumption>

Query objects can only be consumed once. The iterator is exhausted after
terminal operations (C<ToArray>, C<Count>, C<Sum>, C<ToCSV>, etc.).
Create a new query or save the C<ToArray()> result to reuse data.

=item * B<Undef Values>

Due to the iterator-based design, C<undef> signals end-of-sequence.
A C<Select> selector that returns C<undef> will terminate the sequence
early. See L</Iterator Protocol and JSON null> for details and workarounds.

=item * B<Multi-line CSV Fields>

C<FromCSV> reads the file one line at a time. RFC 4180 quoted fields
that contain embedded newlines (multi-line fields) are not yet
supported. Single-line quoted fields containing commas and escaped
double-quotes (C<"">) are handled correctly.

=item * B<No Parallel Execution>

All operations execute sequentially in a single thread.

=back

=head1 BUGS

Please report bugs to C<ina.cpan@gmail.com>.

=head1 SEE ALSO

=over 4

=item * L<LTSV::LINQ> - The LTSV counterpart of this module

=item * L<CSV::LINQ> - LINQ-style query interface for CSV files

=item * L<mb::JSON> - The JSON encoder/decoder this module's parser is derived from

=item * JSONL specification: L<https://jsonlines.org/>

=item * RFC 4180 (CSV): L<https://www.ietf.org/rfc/rfc4180.txt>

=item * Microsoft LINQ documentation: L<https://learn.microsoft.com/en-us/dotnet/csharp/linq/>

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 INABA Hitoshi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS
WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

=cut

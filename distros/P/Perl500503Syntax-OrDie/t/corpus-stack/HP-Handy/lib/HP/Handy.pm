package HP::Handy;
######################################################################
#
# HP::Handy - A tiny Jinja2-compatible template engine for Perl 5.5.3+
#
# https://metacpan.org/dist/HP-Handy
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
use File::Spec;
use vars qw($VERSION);
$VERSION = '0.01';
$VERSION = $VERSION;
# $VERSION self-assignment suppresses "used only once" warning under strict.

###############################################################################
# Built-in filters
###############################################################################
my %FILTERS = (
    'upper'       => sub { my $s = defined $_[0] ? $_[0] : ''; $s =~ tr/a-z/A-Z/; $s },
    'lower'       => sub { my $s = defined $_[0] ? $_[0] : ''; $s =~ tr/A-Z/a-z/; $s },
    'trim'        => sub { my $s = defined $_[0] ? $_[0] : ''; $s =~ s/^\s+|\s+$//g; $s },
    'length'      => sub {
        return 0 unless defined $_[0];
        ref($_[0]) eq 'ARRAY' ? scalar @{$_[0]}
      : ref($_[0]) eq 'HASH'  ? scalar keys %{$_[0]}
      : length($_[0])
    },
    'reverse'     => sub {
        return '' unless defined $_[0];
        ref($_[0]) eq 'ARRAY' ? [ reverse @{$_[0]} ]
      : scalar reverse("$_[0]")
    },
    'escape'      => \&_html_escape,
    'e'           => \&_html_escape,
    'safe'        => sub { bless \(my $s = defined $_[0] ? $_[0] : ''), 'HP::Handy::SafeString' },
    'default'     => sub { (defined $_[0] && $_[0] ne '') ? $_[0] : $_[1] },
    'd'           => sub { (defined $_[0] && $_[0] ne '') ? $_[0] : $_[1] },
    'replace'     => sub {
        my ($s, $from, $to) = @_;
        $s = defined $s ? $s : '';
        $from = defined $from ? $from : '';
        $to   = defined $to   ? $to   : '';
        $s =~ s/\Q$from\E/$to/g;
        $s
    },
    'truncate'    => sub {
        my ($s, $len, $end) = @_;
        $s   = defined $s   ? $s   : '';
        $len = defined $len ? int($len) : 255;
        $end = defined $end ? $end : '...';
        (length($s) > $len) ? substr($s, 0, $len) . $end : $s
    },
    'join'        => sub {
        my ($list, $sep) = @_;
        $sep = defined $sep ? $sep : '';
        ref($list) eq 'ARRAY' ? join($sep, @$list) : (defined $list ? $list : '')
    },
    'first'       => sub { ref($_[0]) eq 'ARRAY' && @{$_[0]} ? $_[0][0]  : undef },
    'last'        => sub { ref($_[0]) eq 'ARRAY' && @{$_[0]} ? $_[0][-1] : undef },
    'list'        => sub { ref($_[0]) eq 'ARRAY' ? $_[0] : [defined $_[0] ? $_[0] : ()] },
    'abs'         => sub { abs(defined $_[0] ? $_[0] : 0) },
    'int'         => sub { int(defined $_[0] ? $_[0] : 0) },
    'float'       => sub { defined $_[0] ? ($_[0] + 0.0) : 0.0 },
    'string'      => sub { defined $_[0] ? "$_[0]" : '' },
    'title'       => sub {
        my $s = defined $_[0] ? $_[0] : '';
        $s =~ s/\b([a-z])/uc($1)/ge;
        $s
    },
    'capitalize'  => sub {
        my $s = defined $_[0] ? lc($_[0]) : '';
        $s =~ s/^([a-z])/uc($1)/e;
        $s
    },
    'urlencode'   => sub {
        my $s = defined $_[0] ? $_[0] : '';
        $s =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
        $s
    },
    'wordcount'   => sub {
        my $s = defined $_[0] ? $_[0] : '';
        my @w = split /\s+/, $s;
        @w = grep { $_ ne '' } @w;
        scalar @w
    },
    'batch'       => sub {
        my ($list, $size, $fill) = @_;
        return [] unless ref($list) eq 'ARRAY';
        $size = int($size || 1);
        $size = 1 if $size < 1;
        my @result;
        my @flat = @$list;
        while (@flat) {
            my @chunk = splice(@flat, 0, $size);
            if (defined $fill) {
                push @chunk, $fill while @chunk < $size;
            }
            push @result, \@chunk;
        }
        \@result
    },
    'slice'       => sub {
        my ($list, $slices) = @_;
        return [] unless ref($list) eq 'ARRAY';
        $slices = int($slices || 1);
        $slices = 1 if $slices < 1;
        my $total = scalar @$list;
        my $per   = int($total / $slices);
        my $extra = $total % $slices;
        my @result;
        my $idx = 0;
        for my $i (0 .. $slices - 1) {
            my $n = $per + ($i < $extra ? 1 : 0);
            push @result, [ @{$list}[$idx .. $idx + $n - 1] ];
            $idx += $n;
        }
        \@result
    },
    'sort'        => sub {
        my ($list, $attr) = @_;
        return [] unless ref($list) eq 'ARRAY';
        if (defined $attr) {
            return [ sort { _get_attr($a, $attr) cmp _get_attr($b, $attr) } @$list ];
        }
        [ sort @$list ]
    },
    'unique'      => sub {
        return [] unless ref($_[0]) eq 'ARRAY';
        my %seen;
        [ grep { !$seen{$_}++ } @{$_[0]} ]
    },
    'min'         => sub {
        return undef unless ref($_[0]) eq 'ARRAY' && @{$_[0]};
        my $m = $_[0][0];
        for (@{$_[0]}) { $m = $_ if $_ < $m }
        $m
    },
    'max'         => sub {
        return undef unless ref($_[0]) eq 'ARRAY' && @{$_[0]};
        my $m = $_[0][0];
        for (@{$_[0]}) { $m = $_ if $_ > $m }
        $m
    },
    'sum'         => sub {
        return 0 unless ref($_[0]) eq 'ARRAY';
        my $s = 0; $s += $_ for @{$_[0]}; $s
    },
    'map'         => sub {
        my ($list, $attr) = @_;
        return [] unless ref($list) eq 'ARRAY';
        [ map { _get_attr($_, $attr) } @$list ]
    },
    'select'      => sub {
        my ($list, $attr) = @_;
        return [] unless ref($list) eq 'ARRAY';
        [ grep { _get_attr($_, $attr) } @$list ]
    },
    'reject'      => sub {
        my ($list, $attr) = @_;
        return [] unless ref($list) eq 'ARRAY';
        [ grep { !_get_attr($_, $attr) } @$list ]
    },
    'count'       => sub { ref($_[0]) eq 'ARRAY' ? scalar @{$_[0]} : 0 },
    'pprint'      => sub { _to_json($_[0]) },
    'nl2br'       => sub {
        my $s = defined $_[0] ? $_[0] : '';
        $s =~ s/\n/<br>\n/g;
        $s
    },
    'striptags'   => sub {
        my $s = defined $_[0] ? $_[0] : '';
        $s =~ s/<[^>]*>//g;
        $s
    },
    'format'      => sub {
        my ($s, $fmt) = @_;
        defined $s ? sprintf($fmt, $s) : ''
    },
    'center'      => sub {
        my ($s, $width) = @_;
        $s = defined $s ? $s : '';
        $width = defined $width ? int($width) : 80;
        my $pad = $width - length($s);
        return $s if $pad <= 0;
        my $left  = int($pad / 2);
        my $right = $pad - $left;
        (' ' x $left) . $s . (' ' x $right)
    },
    'indent'      => sub {
        my ($s, $width, $first) = @_;
        $s     = defined $s     ? $s     : '';
        $width = defined $width ? int($width) : 4;
        $first = defined $first ? $first : 0;
        my $pad = ' ' x $width;
        my @lines = split /\n/, $s, -1;
        for my $i (0 .. $#lines) {
            $lines[$i] = $pad . $lines[$i] if $i > 0 || $first;
        }
        join("\n", @lines)
    },
    'xmlattr'     => sub {
        my $h = $_[0];
        return '' unless ref($h) eq 'HASH';
        join(' ', map {
            my $v = defined $h->{$_} ? $h->{$_} : '';
            $v =~ s/&/&amp;/g; $v =~ s/"/&quot;/g;
            "$_=\"$v\""
        } sort keys %$h)
    },
    'tojson'      => sub {
        my $v = $_[0];
        _to_json($v)
    },
    'forceescape' => \&_html_escape,
);

###############################################################################
# Built-in tests (is_xxx)
###############################################################################
my %TESTS = (
    'defined'   => sub { defined $_[0] },
    'none'      => sub { !defined $_[0] },
    'string'    => sub { defined $_[0] && !ref($_[0]) },
    'number'    => sub { defined $_[0] && !ref($_[0]) && $_[0] =~ /^-?(?:\d+\.?\d*|\.\d+)$/ },
    'sequence'  => sub { ref($_[0]) eq 'ARRAY' },
    'mapping'   => sub { ref($_[0]) eq 'HASH' },
    'iterable'  => sub { ref($_[0]) eq 'ARRAY' || ref($_[0]) eq 'HASH' },
    'callable'  => sub { ref($_[0]) eq 'CODE' },
    'odd'       => sub { defined $_[0] && int($_[0]) % 2 != 0 },
    'even'      => sub { defined $_[0] && int($_[0]) % 2 == 0 },
    'divisibleby' => sub { defined $_[0] && defined $_[1] && $_[1] != 0 && int($_[0]) % int($_[1]) == 0 },
    'upper'     => sub { defined $_[0] && $_[0] eq uc($_[0]) && $_[0] =~ /[A-Z]/ },
    'lower'     => sub { defined $_[0] && $_[0] eq lc($_[0]) && $_[0] =~ /[a-z]/ },
    'equalto'   => sub { defined $_[0] && defined $_[1] && $_[0] eq $_[1] },
    'ne'        => sub { !(defined $_[0] && defined $_[1] && $_[0] eq $_[1]) },
    'lt'        => sub { defined $_[0] && defined $_[1] && $_[0] <  $_[1] },
    'le'        => sub { defined $_[0] && defined $_[1] && $_[0] <= $_[1] },
    'gt'        => sub { defined $_[0] && defined $_[1] && $_[0] >  $_[1] },
    'ge'        => sub { defined $_[0] && defined $_[1] && $_[0] >= $_[1] },
    'in'        => sub {
        my ($val, $container) = @_;
        return 0 unless defined $val && defined $container;
        if (ref($container) eq 'ARRAY') { return (grep { defined $_ && $_ eq $val } @$container) ? 1 : 0 }
        if (ref($container) eq 'HASH')  { return exists $container->{$val} ? 1 : 0 }
        return index($container, $val) >= 0 ? 1 : 0
    },
);

###############################################################################
# Constructor
###############################################################################
sub new {
    my ($class, %args) = @_;
    my $self = {
        template_dir    => defined $args{template_dir}    ? $args{template_dir}    : '.',
        auto_escape     => defined $args{auto_escape}     ? $args{auto_escape}     : 1,
        trim_blocks     => defined $args{trim_blocks}     ? $args{trim_blocks}     : 0,
        lstrip_blocks   => defined $args{lstrip_blocks}   ? $args{lstrip_blocks}   : 0,
        block_start     => defined $args{block_start}     ? $args{block_start}     : '{%',
        block_end       => defined $args{block_end}       ? $args{block_end}       : '%}',
        var_start       => defined $args{var_start}       ? $args{var_start}       : '{{',
        var_end         => defined $args{var_end}         ? $args{var_end}         : '}}',
        comment_start   => defined $args{comment_start}   ? $args{comment_start}   : '{#',
        comment_end     => defined $args{comment_end}     ? $args{comment_end}     : '#}',
        _filters        => { %FILTERS },
        _tests          => { %TESTS  },
        _blocks         => {},   # block name => template string (for inheritance)
        _macros         => {},   # macro name => { args=>[], defaults=>[], body=>'' }
        _extends        => '',   # parent template name
    };
    bless $self, $class;
    return $self;
}

###############################################################################
# add_filter - Register a custom filter
###############################################################################
sub add_filter {
    my ($self, $name, $code) = @_;
    croak "add_filter: name required"        unless defined $name;
    croak "add_filter: code must be coderef" unless ref($code) eq 'CODE';
    $self->{_filters}{$name} = $code;
    return $self;
}

###############################################################################
# add_test - Register a custom test
###############################################################################
sub add_test {
    my ($self, $name, $code) = @_;
    croak "add_test: name required"        unless defined $name;
    croak "add_test: code must be coderef" unless ref($code) eq 'CODE';
    $self->{_tests}{$name} = $code;
    return $self;
}

###############################################################################
# render_file - Render a template file with variables
###############################################################################
sub render_file {
    my ($self, $filename, $vars) = @_;
    $vars = {} unless defined $vars;
    my $source = $self->_load_file($filename);
    return $self->_render($source, $vars, $filename);
}

###############################################################################
# render_string - Render a template string with variables
###############################################################################
sub render_string {
    my ($self, $source, $vars) = @_;
    $vars = {} unless defined $vars;
    return $self->_render($source, $vars, '<string>');
}

###############################################################################
# _load_file - Read template from disk
###############################################################################
sub _load_file {
    my ($self, $filename) = @_;

    # Prevent path traversal
    if ($filename =~ /\.\./) {
        croak "HP::Handy: path traversal not allowed in '$filename'";
    }

    my $path;
    if (File::Spec->file_name_is_absolute($filename)) {
        $path = $filename;
    }
    else {
        $path = File::Spec->catfile($self->{template_dir}, $filename);
    }

    local *HPHANDY_FH;
    open(HPHANDY_FH, "< $path") or croak "HP::Handy: cannot open '$path': $!";
    local $/;
    my $source = <HPHANDY_FH>;
    close(HPHANDY_FH);
    return defined $source ? $source : '';
}

###############################################################################
# _render - Core rendering engine
###############################################################################
sub _render {
    my ($self, $source, $vars, $filename) = @_;
    $filename = defined $filename ? $filename : '<string>';

    # Reset per-render state
    $self->{_blocks}  = {};
    $self->{_macros}  = {};
    $self->{_extends} = '';

    # First pass: collect blocks and macros, detect extends
    $source = $self->_preprocess($source, $vars);

    # If extends was found, do inheritance (iteratively for multi-level)
    while ($self->{_extends} ne '') {
        my $parent_src = $self->_load_file($self->{_extends});
        $self->{_extends} = '';
        # Collect parent blocks/macros without overwriting child definitions
        $parent_src = $self->_preprocess_parent($parent_src, $vars);
        # Apply child blocks to parent template
        $source = $self->_apply_inheritance($parent_src, $vars);
        # Now resolve all known blocks so deeper levels see merged content.
        # For each block in _blocks, expand any other known blocks inside it.
        my $merged = 1;
        my $passes = 10;
        while ($merged && $passes-- > 0) {
            $merged = 0;
            for my $bname (keys %{$self->{_blocks}}) {
                my $prev = $self->{_blocks}{$bname};
                my $val  = $prev;
                my $lim2 = 10;
                while ($lim2-- > 0) {
                    my $prev2 = $val;
                    $val =~ s/\{%-?\s*block\s+(\w+)\s*-?%\}((?:(?!\{%-?\s*block\b)[\s\S])*?)\{%-?\s*endblock(?:\s+\1)?\s*-?%\}/
                        exists $self->{_blocks}{$1} ? $self->{_blocks}{$1} : "\x00BLK\x01$1\x01$2\x00EBLK\x00"
                    /gse;
                    last if $val eq $prev2;
                }
                $val =~ s/\x00BLK\x01(\w+)\x01(.*?)\x00EBLK\x00/$2/gs;
                $val =~ s/\{%-?\s*endblock(?:\s+\w+)?\s*-?%\}//g;
                if ($val ne $prev) {
                    $self->{_blocks}{$bname} = $val;
                    $merged = 1;
                }
            }
        }
    }

    return $self->_eval_template($source, $vars, $filename);
}

###############################################################################
# _preprocess - Scan for extends/block/macro; strip them for non-inherited use
###############################################################################
sub _preprocess {
    my ($self, $source, $vars) = @_;

    # Detect {% extends "..." %}
    if ($source =~ s/\{%-?\s*extends\s+["']([^"']+)["']\s*-?%\}[ \t]*\n?//) {
        $self->{_extends} = $1;
    }

    # Collect {% macro name(args) %}...{% endmacro %}
    while ($source =~ s/\{%-?\s*macro\s+(\w+)\s*\(([^)]*)\)\s*-?%\}(.*?)\{%-?\s*endmacro\s*-?%\}//s) {
        my ($mname, $argstr, $body) = ($1, $2, $3);
        my (@args, @defaults);
        for my $a (split /\s*,\s*/, $argstr) {
            $a =~ s/^\s+|\s+$//g;
            next if $a eq '';
            if ($a =~ /^(\w+)\s*=\s*(.+)$/) {
                push @args,     $1;
                push @defaults, $2;
            }
            else {
                push @args,     $a;
                push @defaults, undef;
            }
        }
        $self->{_macros}{$mname} = { args => \@args, defaults => \@defaults, body => $body };
    }

    # Collect {% block name %}...{% endblock %} from child
    while ($source =~ s/\{%-?\s*block\s+(\w+)\s*-?%\}(.*?)\{%-?\s*endblock(?:\s+\1)?\s*-?%\}/$self->_store_block($1, $2)/se) {}

    return $source;
}

sub _store_block {
    my ($self, $name, $content) = @_;
    $self->{_blocks}{$name} = $content unless exists $self->{_blocks}{$name};
    return '';
}


# _preprocess_parent - Scan parent for extends/macro; collect NEW blocks only
# (does NOT strip block tags -- those must survive for _apply_inheritance)
sub _preprocess_parent {
    my ($self, $source, $vars) = @_;

    # Detect {% extends "..." %} in parent (for multi-level)
    if ($source =~ s/\{%-?\s*extends\s+["']([^"']+)["']\s*-?%\}[ \t]*\n?//) {
        $self->{_extends} = $1;
    }

    # Collect macros from parent (without overwriting child macros)
    while ($source =~ s/\{%-?\s*macro\s+(\w+)\s*\(([^)]*)\)\s*-?%\}(.*?)\{%-?\s*endmacro\s*-?%\}//s) {
        my ($mname, $argstr, $body) = ($1, $2, $3);
        next if exists $self->{_macros}{$mname};
        my (@args, @defaults);
        for my $a (split /\s*,\s*/, $argstr) {
            $a =~ s/^\s+|\s+$//g;
            next if $a eq "";
            if ($a =~ /^(\w+)\s*=\s*(.+)$/) {
                push @args,     $1;
                push @defaults, $2;
            }
            else {
                push @args,     $a;
                push @defaults, undef;
            }
        }
        $self->{_macros}{$mname} = { args => \@args, defaults => \@defaults, body => $body };
    }

    # Collect NEW blocks (without overwriting child blocks).
    # Expand already-known child blocks within the body before storing.
    my $tmp = $source;
    while ($tmp =~ s/\{%-?\s*block\s+(\w+)\s*-?%\}(.*)\{%-?\s*endblock(?:\s+\1)?\s*-?%\}/
        $self->_store_block_expanded($1, $2)
    /se) {}

    return $source;  # keep block tags intact for _apply_inheritance
}

sub _store_block_expanded {
    my ($self, $name, $body) = @_;
    unless (exists $self->{_blocks}{$name}) {
        # Expand already-resolved child blocks inside this body.
        # Use _apply_inheritance logic on the snippet.
        my $expanded = $body;
        my $lim = 10;
        while ($lim-- > 0) {
            my $prev = $expanded;
            # Replace innermost (non-nested) blocks that are known
            $expanded =~ s/\{%-?\s*block\s+(\w+)\s*-?%\}((?:(?!\{%-?\s*block\b)[\s\S])*?)\{%-?\s*endblock(?:\s+\1)?\s*-?%\}/
                exists $self->{_blocks}{$1} ? $self->{_blocks}{$1} : "__BLK__" . $1 . "__SEP__" . $2 . "__EBLK__"
            /gse;
            last if $expanded eq $prev;
        }
        # Clean up any un-expanded block tags
        $expanded =~ s/__BLK__(\w+)__SEP__(.*?)__EBLK__/$2/gs;
        $expanded =~ s/\{%-?\s*endblock(?:\s+\w+)?\s*-?%\}//g;
        $self->{_blocks}{$name} = $expanded;
    }
    return '';
}


###############################################################################
# _apply_inheritance - Render parent with child blocks
###############################################################################
sub _apply_inheritance {
    my ($self, $parent_src, $vars) = @_;

    # Iteratively substitute innermost (non-nested) blocks first.
    # A block body that contains no other {% block %} tags is "innermost".
    my $limit = 20;
    while ($limit-- > 0) {
        my $changed = 0;
        $parent_src =~ s/\{%-?\s*block\s+(\w+)\s*-?%\}((?:(?!\{%-?\s*block\b)[\s\S])*?)\{%-?\s*endblock(?:\s+\1)?\s*-?%\}/
            do { $changed = 1; exists $self->{_blocks}{$1} ? $self->{_blocks}{$1} : $2 }
        /gse;
        last unless $changed;
    }

    # Remove any orphaned {% endblock %} left from outer block substitutions
    $parent_src =~ s/\{%-?\s*endblock(?:\s+\w+)?\s*-?%\}//g;

    return $parent_src;
}

###############################################################################
# _eval_template - Evaluate template directives recursively
###############################################################################
sub _eval_template {
    my ($self, $source, $vars, $filename) = @_;
    $filename = defined $filename ? $filename : '<string>';

    # Apply trim_blocks / lstrip_blocks
    if ($self->{trim_blocks}) {
        $source =~ s/(%\}|#\})[ \t]*\n/$1\n/g;  # already minimal; remove newline after tag
        $source =~ s/(%\}|#\})\n/$1/g;
    }
    if ($self->{lstrip_blocks}) {
        $source =~ s/^[ \t]*(\{[%#])/$1/mg;
    }

    my $bs = quotemeta($self->{block_start});
    my $be = quotemeta($self->{block_end});
    my $vs = quotemeta($self->{var_start});
    my $ve = quotemeta($self->{var_end});
    my $cs = quotemeta($self->{comment_start});
    my $ce = quotemeta($self->{comment_end});

    # Protect {% raw %}...{% endraw %} blocks BEFORE comment stripping,
    # so that {# ... #} inside raw blocks is preserved as-is.
    my @raw_chunks;
    my $raw_ph = "\x00RAW\x00";
    my $bs_re = quotemeta($self->{block_start});
    my $be_re = quotemeta($self->{block_end});
    $source =~ s/${bs_re}-?\s*raw\s*-?${be_re}(.*?)${bs_re}-?\s*endraw\s*-?${be_re}/
        my $idx = scalar @raw_chunks;
        push @raw_chunks, $1;
        "${raw_ph}${idx}\x00"
    /gse;

    # Remove comments (after raw protection so {# #} inside raw is safe)
    $source =~ s/$cs.*?$ce//gs;

    # Tokenise into chunks
    # Tokens: [ 'text', $str ] or [ 'var', $expr ] or [ 'tag', $stmt ]
    my @tokens = $self->_tokenize($source);

    # Restore raw chunks in text tokens
    for my $tok (@tokens) {
        if ($tok->[0] eq 'text' && $tok->[1] =~ /\Q$raw_ph\E/) {
            $tok->[1] =~ s/\Q${raw_ph}\E(\d+)\x00/$raw_chunks[$1]/g;
        }
    }

    return $self->_eval_tokens(\@tokens, $vars, 0, $filename);
}

###############################################################################
# _tokenize - Split source into text/var/tag tokens
###############################################################################
sub _tokenize {
    my ($self, $source) = @_;

    my $bs = $self->{block_start};  # {%
    my $be = $self->{block_end};    # %}
    my $vs = $self->{var_start};    # {{
    my $ve = $self->{var_end};      # }}

    # Build split pattern
    my $qbs = quotemeta($bs); my $qbe = quotemeta($be);
    my $qvs = quotemeta($vs); my $qve = quotemeta($ve);

    my @tokens;
    my $pos = 0;
    my $len = length($source);

    while ($pos < $len) {
        # Find next tag start
        my $var_pos   = index($source, $vs, $pos);
        my $block_pos = index($source, $bs, $pos);

        # No more tags
        if ($var_pos < 0 && $block_pos < 0) {
            push @tokens, [ 'text', substr($source, $pos) ];
            last;
        }

        # Determine which comes first
        my $next;
        if ($var_pos >= 0 && ($block_pos < 0 || $var_pos <= $block_pos)) {
            $next = $var_pos;
            my $end = index($source, $ve, $next + length($vs));
            if ($end < 0) {
                push @tokens, [ 'text', substr($source, $pos) ];
                last;
            }
            if ($next > $pos) {
                push @tokens, [ 'text', substr($source, $pos, $next - $pos) ];
            }
            my $raw_expr = substr($source, $next + length($vs), $end - $next - length($vs));
            # Whitespace control dash: "{{- expr -}}"
            # The dash must be the very first/last non-whitespace character AND
            # must be followed/preceded by whitespace (not part of the expression).
            # Rule: if raw_expr starts with "-" followed by space/end, it's WS control.
            # "-5" or "-x" is a negative expression, NOT whitespace control.
            my $strip_left  = ($raw_expr =~ /^-(?:\s|$)/);
            my $strip_right = ($raw_expr =~ /(?:^|\s)-\s*$/);
            my $expr = $raw_expr;
            $expr =~ s/^\s+|\s+$//g;
            $expr =~ s/^-\s+// if $strip_left;    # remove leading "- "
            $expr =~ s/\s+-$// if $strip_right;   # remove trailing " -"
            # Strip whitespace from preceding text token if {{- }}
            if ($strip_left && @tokens && $tokens[-1][0] eq 'text') {
                $tokens[-1][1] =~ s/\s+$//;
                splice @tokens, -1 if $tokens[-1][1] eq '';
            }
            push @tokens, [ 'var', $expr, $strip_right ];
            $pos = $end + length($ve);
            # Strip leading whitespace from next text if {{ -}}
            if ($strip_right && $pos < $len) {
                my $rest = substr($source, $pos);
                my $stripped = $rest;
                $stripped =~ s/^\s+//;
                $pos += length($rest) - length($stripped);
            }
        }
        else {
            $next = $block_pos;
            my $end = index($source, $be, $next + length($bs));
            if ($end < 0) {
                push @tokens, [ 'text', substr($source, $pos) ];
                last;
            }
            if ($next > $pos) {
                # Whitespace control: {% - strips preceding whitespace
                my $text_before = substr($source, $pos, $next - $pos);
                my $stmt_raw    = substr($source, $next + length($bs), $end - $next - length($bs));
                if ($stmt_raw =~ /^-/) {
                    $text_before =~ s/\s+$//;
                }
                push @tokens, [ 'text', $text_before ] if $text_before ne '';
            }
            my $stmt_full = substr($source, $next + length($bs), $end - $next - length($bs));
            my $rstrip_tag = ($stmt_full =~ /\s*-\s*$/);
            my $stmt = $stmt_full;
            $stmt =~ s/^\s+|\s+$//g;
            $stmt =~ s/^-\s*|\s*-$//g;
            push @tokens, [ 'tag', $stmt ];
            $pos = $end + length($be);
            # Whitespace control: -%} strips following whitespace
            if ($rstrip_tag && $pos < $len) {
                substr($source, $pos) =~ s/^\s+//;
                $pos = $len - length($source) + $pos if $source =~ s/^(\s+)//;
                # Simpler: just advance pos past leading whitespace
                my $rest = substr($source, $pos);
                my $stripped = $rest;
                $stripped =~ s/^\s+//;
                $pos += length($rest) - length($stripped);
            }
            # trim_blocks: eat newline after %}
            if (!$rstrip_tag && $self->{trim_blocks} && $pos < $len && substr($source, $pos, 1) eq "\n") {
                $pos++;
            }
        }
    }
    return @tokens;
}

###############################################################################
# _eval_tokens - Execute a token list and return rendered string
###############################################################################
sub _eval_tokens {
    my ($self, $tokens, $vars, $start, $filename) = @_;
    $start = 0 unless defined $start;

    my $out = '';
    my $i   = $start;

    while ($i <= $#$tokens) {
        my ($type, $content) = @{$tokens->[$i]};

        if ($type eq 'text') {
            $out .= $content;
            $i++;
        }
        elsif ($type eq 'var') {
            my $val = $self->_eval_expr($content, $vars);
            if (ref($val) eq 'HP::Handy::SafeString') {
                $val = $$val;
            }
            elsif ($self->{auto_escape} && defined $val && !ref($val)) {
                $val = _html_escape($val);
            }
            $out .= defined $val ? $val : '';
            $i++;
        }
        elsif ($type eq 'tag') {
            my $stmt = $content;

            # --- set ---
            if ($stmt =~ /^set\s+(\w+)\s*=\s*(.+)$/) {
                my ($vname, $expr) = ($1, $2);
                $vars->{$vname} = $self->_eval_expr($expr, $vars);
                $i++;
            }
            # --- set block (multi-line) ---
            elsif ($stmt =~ /^set\s+(\w+)\s*$/) {
                my $vname = $1;
                my ($body, $ni) = $self->_collect_until($tokens, $i + 1, 'endset');
                $vars->{$vname} = $self->_eval_tokens($tokens, $vars, $i + 1, $filename);
                # re-render just the body tokens
                my @body_tokens = @{$tokens}[$i+1 .. $ni-1];
                $vars->{$vname} = $self->_eval_tokens(\@body_tokens, $vars, 0, $filename);
                $i = $ni + 1;
            }
            # --- if / elif / else / endif ---
            elsif ($stmt =~ /^if\s+(.+)$/) {
                my $cond_expr = $1;
                my ($result, $ni) = $self->_eval_if($tokens, $i, $vars, $filename);
                $out .= $result;
                $i = $ni;
            }
            # --- for / endfor ---
            elsif ($stmt =~ /^for\s+(.+?)\s+in\s+(.+?)(?:\s+if\s+(.+))?$/) {
                my ($loop_var, $iter_expr, $cond_expr) = ($1, $2, $3);
                my ($result, $ni) = $self->_eval_for($tokens, $i, $vars, $loop_var, $iter_expr, $cond_expr, $filename);
                $out .= $result;
                $i = $ni;
            }
            # --- include ---
            elsif ($stmt =~ /^include\s+["']([^"']+)["'](?:\s+ignore\s+missing)?$/) {
                my $inc_file = $1;
                my $inc_src;
                eval { $inc_src = $self->_load_file($inc_file) };
                if ($@) {
                    $inc_src = '' if $stmt =~ /ignore\s+missing/;
                    croak $@ unless $stmt =~ /ignore\s+missing/;
                }
                $out .= $self->_eval_template($inc_src, { %$vars }, $inc_file) if defined $inc_src;
                $i++;
            }
            # --- call macro ---
            elsif ($stmt =~ /^(\w+)\s*\(([^)]*)\)$/ && exists $self->{_macros}{$1}) {
                my ($mname, $argstr) = ($1, $2);
                $out .= $self->_call_macro($mname, $argstr, $vars, $filename);
                $i++;
            }
            # --- raw / endraw ---
            elsif ($stmt eq 'raw') {
                my ($raw, $ni) = $self->_collect_raw($tokens, $i + 1);
                $out .= $raw;
                $i = $ni + 1;
            }
            # --- with / endwith ---
            elsif ($stmt =~ /^with(?:\s+(.+))?$/) {
                my $assigns = $1;
                my %local_vars = %$vars;
                if (defined $assigns) {
                    for my $pair (_split_args($assigns)) {
                        if ($pair =~ /^(\w+)\s*=\s*(.+)$/) {
                            $local_vars{$1} = $self->_eval_expr($2, { %local_vars });
                        }
                    }
                }
                my ($body_tokens_ref, $ni) = $self->_collect_until($tokens, $i + 1, 'endwith');
                $out .= $self->_eval_tokens($body_tokens_ref, { %local_vars }, 0, $filename);
                $i = $ni + 1;
            }
            # --- block (standalone, no inheritance) ---
            elsif ($stmt =~ /^block\s+(\w+)$/) {
                my $bname = $1;
                my ($body_tokens_ref, $ni) = $self->_collect_until($tokens, $i + 1, "endblock $bname", 'endblock');
                if (exists $self->{_blocks}{$bname}) {
                    $out .= $self->_eval_template($self->{_blocks}{$bname}, $vars, $filename);
                }
                else {
                    $out .= $self->_eval_tokens($body_tokens_ref, $vars, 0, $filename);
                }
                $i = $ni + 1;
            }
            # skip endxxx tags (consumed by their openers above)
            elsif ($stmt =~ /^end(if|for|block|macro|raw|with|set)/ || $stmt =~ /^(else|elif)/) {
                $i++;
            }
            else {
                # Unknown tag: pass through as-is for forward compatibility
                $out .= $self->{block_start} . ' ' . $stmt . ' ' . $self->{block_end};
                $i++;
            }
        }
        else {
            $i++;
        }
    }
    return $out;
}

###############################################################################
# _eval_if - Evaluate if/elif/else/endif block
###############################################################################
sub _eval_if {
    my ($self, $tokens, $start, $vars, $filename) = @_;

    # Collect all branches: [ [cond_expr, [tokens...]], ..., [undef, [tokens...]] ]
    my @branches;
    my $cur_cond = $tokens->[$start][1];
    $cur_cond =~ s/^if\s+//;
    my @cur_body;
    my $depth = 1;
    my $i = $start + 1;

    while ($i <= $#$tokens) {
        my ($type, $content) = @{$tokens->[$i]};
        if ($type eq 'tag') {
            if ($content =~ /^if\b/) {
                $depth++;
                push @cur_body, $tokens->[$i];
            }
            elsif ($content eq 'endif') {
                $depth--;
                if ($depth == 0) {
                    push @branches, [ $cur_cond, [@cur_body] ];
                    $i++;
                    last;
                }
                else {
                    push @cur_body, $tokens->[$i];
                }
            }
            elsif ($depth == 1 && $content =~ /^elif\s+(.+)$/) {
                push @branches, [ $cur_cond, [@cur_body] ];
                $cur_cond = $1;
                @cur_body = ();
            }
            elsif ($depth == 1 && $content eq 'else') {
                push @branches, [ $cur_cond, [@cur_body] ];
                $cur_cond = undef;
                @cur_body = ();
            }
            else {
                push @cur_body, $tokens->[$i];
            }
        }
        else {
            push @cur_body, $tokens->[$i];
        }
        $i++;
    }
    push @branches, [ $cur_cond, [@cur_body] ] if @cur_body || !defined $cur_cond;

    my $result = '';
    for my $branch (@branches) {
        my ($cond, $body) = @$branch;
        if (!defined $cond || $self->_eval_expr($cond, $vars)) {
            $result = $self->_eval_tokens($body, $vars, 0, $filename);
            last;
        }
    }
    return ($result, $i);
}

###############################################################################
# _eval_for - Evaluate for loop
###############################################################################
sub _eval_for {
    my ($self, $tokens, $start, $vars, $loop_var, $iter_expr, $cond_expr, $filename) = @_;

    # Collect loop body tokens (until endfor at depth 1)
    my (@body_tokens, @else_tokens);
    my $in_else = 0;
    my $depth   = 1;
    my $i       = $start + 1;

    while ($i <= $#$tokens) {
        my ($type, $content) = @{$tokens->[$i]};
        if ($type eq 'tag') {
            if ($content =~ /^(?:for|if|block|macro|with)\b/) { $depth++ }
            elsif ($content =~ /^end(?:for|if|block|macro|with)/) {
                $depth--;
                if ($depth == 0 && $content eq 'endfor') { $i++; last }
            }
            elsif ($depth == 1 && $content eq 'else') {
                $in_else = 1; $i++; next;
            }
        }
        if ($in_else) { push @else_tokens, $tokens->[$i] }
        else          { push @body_tokens,  $tokens->[$i] }
        $i++;
    }

    # Evaluate iterable
    my $iter = $self->_eval_expr($iter_expr, $vars);
    my @items;
    if (ref($iter) eq 'ARRAY') {
        @items = @$iter;
    }
    elsif (ref($iter) eq 'HASH') {
        @items = map { [ $_, $iter->{$_} ] } sort keys %$iter;
    }
    elsif (defined $iter) {
        @items = ($iter);
    }

    # Apply loop filter
    if (defined $cond_expr) {
        my @filtered;
        for my $item (@items) {
            my %loop_vars = %$vars;
            $self->_assign_loop_var(\%loop_vars, $loop_var, $item);
            push @filtered, $item if $self->_eval_expr($cond_expr, \%loop_vars);
        }
        @items = @filtered;
    }

    if (!@items) {
        return ($self->_eval_tokens(\@else_tokens, $vars, 0, $filename), $i);
    }

    my $total  = scalar @items;
    my $result = '';

    for my $idx (0 .. $#items) {
        my %loop_vars = %$vars;
        $self->_assign_loop_var(\%loop_vars, $loop_var, $items[$idx]);

        # loop special variable
        $loop_vars{loop} = {
            index      => $idx + 1,
            index0     => $idx,
            revindex   => $total - $idx,
            revindex0  => $total - $idx - 1,
            first      => ($idx == 0)        ? 1 : 0,
            last       => ($idx == $#items)  ? 1 : 0,
            length     => $total,
            depth      => 1,
            depth0     => 0,
            odd        => ($idx % 2 == 0)    ? 0 : 1,
            even       => ($idx % 2 == 0)    ? 1 : 0,
            changed    => sub { my $attr = shift; _loop_changed($attr, $items[$idx], $idx > 0 ? $items[$idx-1] : undef) },
        };

        $result .= $self->_eval_tokens(\@body_tokens, \%loop_vars, 0, $filename);
    }

    return ($result, $i);
}

sub _assign_loop_var {
    my ($self, $vars, $loop_var, $item) = @_;
    # Tuple unpacking: "k, v" in "for k, v in ..."
    if ($loop_var =~ /^(\w+)\s*,\s*(\w+)$/) {
        my ($k, $v) = ($1, $2);
        if (ref($item) eq 'ARRAY') {
            $vars->{$k} = $item->[0];
            $vars->{$v} = $item->[1];
        }
        else {
            $vars->{$k} = $item;
            $vars->{$v} = undef;
        }
    }
    else {
        $vars->{$loop_var} = $item;
    }
}

sub _loop_changed {
    my ($attr, $cur, $prev) = @_;
    return 1 unless defined $prev;
    my $cv = _get_attr($cur,  $attr);
    my $pv = _get_attr($prev, $attr);
    return (!defined $cv && !defined $pv) ? 0
         : (!defined $cv ||  !defined $pv) ? 1
         : $cv ne $pv ? 1 : 0;
}

###############################################################################
# _collect_until - Collect tokens until end tag (depth-aware)
###############################################################################
sub _collect_until {
    my ($self, $tokens, $start, @end_tags) = @_;
    my %ends = map { $_ => 1 } @end_tags;
    my @body;
    my $depth = 1;
    my $i = $start;

    # Map each opener tag to its closer.  We track depth only for
    # openers whose closer matches one of the @end_tags we are looking for,
    # plus any nested use of the SAME opener.
    my %opener_to_closer = (
        'if'    => 'endif',
        'for'   => 'endfor',
        'block' => 'endblock',
        'macro' => 'endmacro',
        'with'  => 'endwith',
        'raw'   => 'endraw',
        'set'   => 'endset',
    );
    my %closer_to_opener = reverse %opener_to_closer;

    while ($i <= $#$tokens) {
        my ($type, $content) = @{$tokens->[$i]};
        if ($type eq 'tag') {
            my $bare = $content; $bare =~ s/\s.*//;
            if (exists $ends{$content}) {
                $depth--;
                last if $depth == 0;
            }
            elsif (exists $opener_to_closer{$bare}) {
                # Push only when the closer of THIS opener is in @end_tags
                # (i.e. same kind of nesting as what we're looking for)
                my $closer = $opener_to_closer{$bare};
                if (exists $ends{$closer}) {
                    $depth++;
                }
            }
        }
        push @body, $tokens->[$i];
        $i++;
    }
    return (\@body, $i);
}

###############################################################################
# _collect_raw - Collect raw text tokens until endraw
###############################################################################
sub _collect_raw {
    my ($self, $tokens, $start) = @_;
    my $raw = '';
    my $i   = $start;
    while ($i <= $#$tokens) {
        my ($type, $content) = @{$tokens->[$i]};
        last if $type eq 'tag' && $content eq 'endraw';
        $raw .= $content;
        $i++;
    }
    return ($raw, $i);
}

###############################################################################
# _call_macro - Call a defined macro
###############################################################################
sub _call_macro {
    my ($self, $mname, $argstr, $vars, $filename) = @_;
    my $macro = $self->{_macros}{$mname};
    return '' unless defined $macro;

    # Parse positional args
    my @arg_vals = _split_args($argstr);
    my %macro_vars = %$vars;

    my @margs     = @{ $macro->{args}     };
    my @mdefaults = @{ $macro->{defaults} };

    for my $idx (0 .. $#margs) {
        if ($idx < @arg_vals) {
            $macro_vars{$margs[$idx]} = $self->_eval_expr($arg_vals[$idx], $vars);
        }
        elsif (defined $mdefaults[$idx]) {
            $macro_vars{$margs[$idx]} = $self->_eval_expr($mdefaults[$idx], $vars);
        }
        else {
            $macro_vars{$margs[$idx]} = undef;
        }
    }

    # varargs / kwargs accessible as special vars
    $macro_vars{varargs} = [];
    $macro_vars{kwargs}  = {};

    return $self->_eval_template($macro->{body}, { %macro_vars }, $filename);
}

###############################################################################
# _eval_expr - Evaluate a Jinja2 expression
###############################################################################
sub _eval_expr {
    my ($self, $expr, $vars) = @_;
    $expr =~ s/^\s+|\s+$//g;
    return undef unless defined $expr && $expr ne '';

    # Literal: None / True / False
    return undef if $expr eq 'none' || $expr eq 'None' || $expr eq 'undefined';
    return 1     if $expr eq 'true' || $expr eq 'True';
    return 0     if $expr eq 'false' || $expr eq 'False';

    # Literal: integer / float
    return $expr + 0 if $expr =~ /^-?\d+(\.\d+)?$/;

    # Unary minus: -expr (where expr is not a literal number)
    if ($expr =~ /^-(.+)$/ && $1 !~ /^\d/) {
        my $val = $self->_eval_expr($1, $vars);
        return defined $val ? -$val : undef;
    }

    # Literal: string
    if ($expr =~ /^"((?:[^"\\]|\\.)*)"$/ || $expr =~ /^'((?:[^'\\]|\\.)*)'$/) {
        my $s = $1;
        $s =~ s/\\n/\n/g; $s =~ s/\\t/\t/g; $s =~ s/\\r/\r/g;
        $s =~ s/\\(.)/$1/g;
        return $s;
    }

    # Literal: [] list
    if ($expr =~ /^\[(.+)\]$/) {
        my @elems = _split_args($1);
        return [ map { $self->_eval_expr($_, $vars) } @elems ];
    }

    # Literal: {} dict
    if ($expr =~ /^\{(.+)\}$/) {
        return $self->_eval_dict($1, $vars);
    }

    # Literal: range() -- only when no pipe follows (e.g. range(3) but not range(3)|join)
    if ($expr =~ /^range\(([^|]*)\)$/) {
        return $self->_eval_range($1, $vars);
    }

    # Conditional expression: a if cond else b
    if ($expr =~ /^(.+?)\s+if\s+(.+?)\s+else\s+(.+)$/) {
        my ($a, $cond, $b) = ($1, $2, $3);
        return $self->_eval_expr($cond, $vars) ? $self->_eval_expr($a, $vars) : $self->_eval_expr($b, $vars);
    }

    # 'not' operator
    if ($expr =~ /^not\s+(.+)$/) {
        return $self->_eval_expr($1, $vars) ? 0 : 1;
    }

    # 'in' / 'not in' operator
    if ($expr =~ /^(.+?)\s+not\s+in\s+(.+)$/) {
        return $TESTS{in}->($self->_eval_expr($1, $vars), $self->_eval_expr($2, $vars)) ? 0 : 1;
    }
    if ($expr =~ /^(.+?)\s+in\s+(.+)$/) {
        return $TESTS{in}->($self->_eval_expr($1, $vars), $self->_eval_expr($2, $vars));
    }

    # Boolean operators: and / or
    if ($expr =~ /^(.+?)\s+or\s+(.+)$/) {
        my $a = $self->_eval_expr($1, $vars);
        return $a if $a;
        return $self->_eval_expr($2, $vars);
    }
    if ($expr =~ /^(.+?)\s+and\s+(.+)$/) {
        my $a = $self->_eval_expr($1, $vars);
        return $a ? $self->_eval_expr($2, $vars) : $a;
    }

    # Filter pipeline: expr | filter1 | filter2(arg)
    # Must be checked before comparison operators so that ">" inside
    # filter arg strings (e.g. replace("-->","x")) is not misread.
    if ($expr =~ /^(.+?)\s*\|\s*(\w+)(.*)$/) {
        my ($lhs, $fname, $rest) = ($1, $2, $3);
        my $val = $self->_eval_expr($lhs, $vars);

        my $fargs_str = '';
        my $remaining = '';
        if ($rest =~ /^\s*\(/) {
            # Find matching closing paren, respecting quotes and nesting
            my $depth2 = 0; my $in_sq2 = 0; my $in_dq2 = 0;
            my $found2 = -1;
            my $rs = $rest; $rs =~ s/^\s*//;
            for my $ci (0 .. length($rs) - 1) {
                my $c = substr($rs, $ci, 1);
                if (!$in_sq2 && !$in_dq2 && $c eq "'")  { $in_sq2 = 1; next }
                if ($in_sq2 && $c eq "'")               { $in_sq2 = 0; next }
                if (!$in_sq2 && !$in_dq2 && $c eq '"')  { $in_dq2 = 1; next }
                if ($in_dq2 && $c eq '"')               { $in_dq2 = 0; next }
                if (!$in_sq2 && !$in_dq2) {
                    if ($c eq '(') { $depth2++ }
                    elsif ($c eq ')') { $depth2--; if ($depth2 == 0) { $found2 = $ci; last } }
                }
            }
            if ($found2 >= 0) {
                $fargs_str = substr($rs, 1, $found2 - 1);
                $remaining = substr($rs, $found2 + 1);
            }
        }
        elsif ($rest =~ /^\s*(\|.+)$/) {
            $remaining = $1;
        }

        my @fargs;
        if ($fargs_str ne '') {
            @fargs = map { $self->_eval_expr($_, $vars) } _split_args($fargs_str);
        }

        my $fn = $self->{_filters}{$fname};
        $val = $fn ? $fn->($val, @fargs) : $val;

        # Continue pipeline
        if ($remaining =~ s/^\s*\|\s*//) {
            return $self->_eval_expr("__PIPEVAL__ | $remaining", { %$vars, '__PIPEVAL__' => $val });
        }
        return $val;
    }

    # Comparison operators
    if ($expr =~ /^(.+?)\s*(==|!=|>=|<=|>|<)\s*(.+)$/) {
        my ($lhs, $op, $rhs) = ($1, $2, $3);
        my $l = $self->_eval_expr($lhs, $vars);
        my $r = $self->_eval_expr($rhs, $vars);
        return 0 unless defined $l && defined $r;
        my $numeric = ($l =~ /^-?(?:\d+\.?\d*|\.\d+)$/ && $r =~ /^-?(?:\d+\.?\d*|\.\d+)$/);
        if ($op eq '==') { return $numeric ? ($l == $r ? 1 : 0) : ($l eq $r ? 1 : 0) }
        if ($op eq '!=') { return $numeric ? ($l != $r ? 1 : 0) : ($l ne $r ? 1 : 0) }
        if ($op eq '>')  { return $l >  $r ? 1 : 0 }
        if ($op eq '<')  { return $l <  $r ? 1 : 0 }
        if ($op eq '>=') { return $l >= $r ? 1 : 0 }
        if ($op eq '<=') { return $l <= $r ? 1 : 0 }
    }

    # Arithmetic: match ** and // before single-char operators
    if ($expr =~ /^(.+?)\s*(\*\*|\/\/)\s*(.+)$/) {
        my ($lhs, $op, $rhs) = ($1, $2, $3);
        my $l = $self->_eval_expr($lhs, $vars);
        my $r = $self->_eval_expr($rhs, $vars);
        if (defined $l && defined $r) {
            if ($op eq '//')  { return $r != 0 ? int($l / $r) : undef }
            if ($op eq '**') { return $l ** $r }
        }
        return undef;
    }

    # Arithmetic: scan for operator at depth-0 (respects parentheses)
    {
        my $depth3 = 0; my $in_sq3 = 0; my $in_dq3 = 0;
        my $op_pos = -1; my $op_char = '';
        for my $ci (0 .. length($expr) - 1) {
            my $c = substr($expr, $ci, 1);
            if (!$in_sq3 && !$in_dq3 && $c eq "'")  { $in_sq3 = 1; next }
            if ($in_sq3 && $c eq "'")                { $in_sq3 = 0; next }
            if (!$in_sq3 && !$in_dq3 && $c eq '"')  { $in_dq3 = 1; next }
            if ($in_dq3 && $c eq '"')                { $in_dq3 = 0; next }
            next if $in_sq3 || $in_dq3;
            if ($c eq '(' || $c eq '[' || $c eq '{') { $depth3++; next }
            if ($c eq ')' || $c eq ']' || $c eq '}') { $depth3--; next }
            next if $depth3 != 0;
            if ($c =~ /^[+\-*\/%~]$/) {
                next if $ci == 0;
                my $prev = substr($expr, $ci - 1, 1);
                next if $prev =~ /^[+\-*\/%~(]$/ || $prev eq "";
                next if $c eq '*' && $ci + 1 < length($expr) && substr($expr, $ci + 1, 1) eq '*';
                next if $c eq '/' && $ci + 1 < length($expr) && substr($expr, $ci + 1, 1) eq '/';
                $op_pos = $ci; $op_char = $c;
                last;
            }
        }
        if ($op_pos > 0) {
            my $lhs = substr($expr, 0, $op_pos);
            my $rhs = substr($expr, $op_pos + 1);
            $lhs =~ s/\s+$//; $rhs =~ s/^\s+//;
            my $l = $self->_eval_expr($lhs, $vars);
            my $r = $self->_eval_expr($rhs, $vars);
            if (defined $l && defined $r) {
                if ($op_char eq '+') {
                    return ($l =~ /^-?\d/ && $r =~ /^-?\d/) ? $l + $r : $l . $r;
                }
                if ($op_char eq '~')  { return $l . $r }
                if ($op_char eq '-')  { return $l - $r }
                if ($op_char eq '*')  { return $l * $r }
                if ($op_char eq '/')  { return $r != 0 ? $l / $r : undef }
                if ($op_char eq '%')  { return $r != 0 ? $l % $r : undef }
            }
        }
    }

    # Parenthesised expression -- must be before is/is not so that
    # (expr is test) does not mis-parse the leading "(" as part of lhs.
    if ($expr =~ /^\((.+)\)$/) {
        return $self->_eval_expr($1, $vars);
    }

    # is / is not test
    if ($expr =~ /^(.+?)\s+is\s+not\b\s+(\w+)(?:\s+(.+))?$/) {
        my ($lhs, $test, $arg) = ($1, $2, $3);
        my $val = $self->_eval_expr($lhs, $vars);
        my $targ = defined $arg ? $self->_eval_expr($arg, $vars) : undef;
        my $fn = $self->{_tests}{$test};
        return $fn ? ($fn->($val, $targ) ? 0 : 1) : 1;
    }
    if ($expr =~ /^(.+?)\s+is\s+(\w+)(?:\s+(.+))?$/) {
        my ($lhs, $test, $arg) = ($1, $2, $3);
        my $val = $self->_eval_expr($lhs, $vars);
        my $targ = defined $arg ? $self->_eval_expr($arg, $vars) : undef;
        my $fn = $self->{_tests}{$test};
        return $fn ? ($fn->($val, $targ) ? 1 : 0) : 0;
    }

    # Attribute access: obj.attr or obj["key"] or obj['key']
    if ($expr =~ /^(.+?)\.(\w+)(?:\(([^)]*)\))?$/) {
        my ($obj_expr, $attr, $call_args) = ($1, $2, $3);
        my $obj = $self->_eval_expr($obj_expr, $vars);
        if (defined $call_args) {
            # Method call (filters on object)
            my $fn = $self->{_filters}{$attr};
            my @args = map { $self->_eval_expr($_, $vars) } _split_args($call_args);
            return $fn ? $fn->($obj, @args) : undef;
        }
        return _get_attr($obj, $attr);
    }

    if ($expr =~ /^(.+?)\[["'](\w+)["']\]$/) {
        my ($obj_expr, $key) = ($1, $2);
        my $obj = $self->_eval_expr($obj_expr, $vars);
        return _get_attr($obj, $key);
    }

    if ($expr =~ /^(.+?)\[(-?\d+)\]$/) {
        my ($obj_expr, $idx) = ($1, $2);
        my $obj = $self->_eval_expr($obj_expr, $vars);
        return ref($obj) eq 'ARRAY' ? $obj->[$idx] : undef;
    }

    # Slice: list[start:end]
    if ($expr =~ /^(.+?)\[(-?\d*):(-?\d*)\]$/) {
        my ($obj_expr, $s, $e) = ($1, $2, $3);
        my $obj = $self->_eval_expr($obj_expr, $vars);
        return undef unless ref($obj) eq 'ARRAY';
        my $len  = scalar @$obj;
        my $si   = ($s ne '') ? int($s) : 0;
        my $ei   = ($e ne '') ? int($e) : $len;
        $si += $len if $si < 0;
        $ei += $len if $ei < 0;
        $si = 0    if $si < 0;
        $ei = $len if $ei > $len;
        return [ @{$obj}[$si .. $ei - 1] ];
    }

    # Function/macro call: name(args)
    if ($expr =~ /^(\w+)\s*\(([^)]*)\)$/) {
        my ($fname, $argstr) = ($1, $2);
        # Macro call
        if (exists $self->{_macros}{$fname}) {
            return $self->_call_macro($fname, $argstr, $vars, '<expr>');
        }
        # Built-in functions
        if ($fname eq 'range') {
            return $self->_eval_range($argstr, $vars);
        }
    }

    # Variable lookup
    if ($expr =~ /^(\w+)$/) {
        return exists $vars->{$expr} ? $vars->{$expr} : undef;
    }

    return undef;
}

###############################################################################
# _eval_dict - Parse and evaluate a dict literal { key: val, ... }
###############################################################################
sub _eval_dict {
    my ($self, $inner, $vars) = @_;
    my %h;
    # Simple k:v split (no nested dicts)
    for my $pair (_split_args($inner)) {
        if ($pair =~ /^(.+?)\s*:\s*(.+)$/) {
            my $k = $self->_eval_expr($1, $vars);
            my $v = $self->_eval_expr($2, $vars);
            $h{$k} = $v if defined $k;
        }
    }
    return { %h };
}

###############################################################################
# _eval_range - Evaluate range(stop) / range(start, stop[, step])
###############################################################################
sub _eval_range {
    my ($self, $args_str, $vars) = @_;
    my @args = map { $self->_eval_expr($_, $vars) } _split_args($args_str);
    my ($start, $stop, $step);
    if (@args == 1) { ($start, $stop, $step) = (0, int($args[0]), 1) }
    elsif (@args == 2) { ($start, $stop, $step) = (int($args[0]), int($args[1]), 1) }
    else { ($start, $stop, $step) = (int($args[0]), int($args[1]), int($args[2] || 1)) }
    $step = 1 if $step == 0;
    my @result;
    if ($step > 0) { for (my $n = $start; $n < $stop; $n += $step) { push @result, $n } }
    else           { for (my $n = $start; $n > $stop; $n += $step) { push @result, $n } }
    return [ @result ];
}

###############################################################################
# _get_attr - Get attribute from hash or array
###############################################################################
sub _get_attr {
    my ($obj, $attr) = @_;
    return undef unless defined $obj;
    if (ref($obj) eq 'HASH') {
        return exists $obj->{$attr} ? $obj->{$attr} : undef;
    }
    if (ref($obj) eq 'ARRAY') {
        return $attr =~ /^-?\d+$/ ? $obj->[$attr] : scalar @$obj;
    }
    return undef;
}

###############################################################################
# _split_args - Split comma-separated arguments (respects nested parens/quotes)
###############################################################################
sub _split_args {
    my ($str) = @_;
    return () unless defined $str && $str =~ /\S/;
    my @args;
    my $cur   = '';
    my $depth = 0;
    my $in_sq = 0;
    my $in_dq = 0;

    for my $ch (split //, $str) {
        if (!$in_sq && !$in_dq && $ch eq "'")  { $in_sq = 1; $cur .= $ch; next }
        if ($in_sq && $ch eq "'")               { $in_sq = 0; $cur .= $ch; next }
        if (!$in_sq && !$in_dq && $ch eq '"')  { $in_dq = 1; $cur .= $ch; next }
        if ($in_dq && $ch eq '"')               { $in_dq = 0; $cur .= $ch; next }
        if (!$in_sq && !$in_dq) {
            if    ($ch eq '(' || $ch eq '[' || $ch eq '{') { $depth++ }
            elsif ($ch eq ')' || $ch eq ']' || $ch eq '}') { $depth-- }
            elsif ($ch eq ',' && $depth == 0) {
                $cur =~ s/^\s+|\s+$//g;
                push @args, $cur;
                $cur = '';
                next;
            }
        }
        $cur .= $ch;
    }
    $cur =~ s/^\s+|\s+$//g;
    push @args, $cur if $cur ne '';
    return @args;
}

###############################################################################
# _html_escape - Escape HTML special characters
###############################################################################
sub _html_escape {
    my ($s) = @_;
    return '' unless defined $s;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    $s =~ s/'/&#39;/g;
    return $s;
}

###############################################################################
# _to_json - Minimal JSON serializer (no external dependency)
###############################################################################
sub _to_json {
    my ($val) = @_;
    return 'null'  unless defined $val;
    return 'true'  if ref($val) eq 'SCALAR' && $$val == 1;
    return 'false' if ref($val) eq 'SCALAR' && $$val == 0;
    if (ref($val) eq 'ARRAY') {
        return '[' . join(',', map { _to_json($_) } @$val) . ']';
    }
    if (ref($val) eq 'HASH') {
        return '{' . join(',', map {
            _to_json($_) . ':' . _to_json($val->{$_})
        } sort keys %$val) . '}';
    }
    if ($val =~ /^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?$/) {
        return $val;
    }
    $val =~ s/\\/\\\\/g;
    $val =~ s/"/\\"/g;
    $val =~ s/\n/\\n/g;
    $val =~ s/\r/\\r/g;
    $val =~ s/\t/\\t/g;
    return "\"$val\"";
}

###############################################################################
# Back to main package -- demo when run directly
###############################################################################

# Run as script: perl lib/HP/Handy.pm
unless (caller) {
    my $tmpl = HP::Handy->new(auto_escape => 1);

    my $source = <<'TMPL';
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>HP::Handy Demo</title>
<style>body{font-family:sans-serif;max-width:600px;margin:40px auto;padding:0 20px}
h1{color:#336699}table{border-collapse:collapse;width:100%}
td { padding: 6px 10px; border: 1px solid #ccc }
th { padding: 6px 10px; border: 1px solid #ccc }
tr:nth-child(even) { background: #f8f8f8 }
</style>
</head>
<body>
<h1>HP::Handy Demo</h1>
<p>Version: {{ version }}</p>

<h2>Variable and Filter</h2>
<p>Hello, {{ name | upper }}!</p>
<p>Escaped: {{ snippet }}</p>

<h2>For Loop</h2>
<table>
<tr><th>#</th><th>Item</th><th>First?</th><th>Last?</th></tr>
{% for item in items %}
<tr>
  <td>{{ loop.index }}</td>
  <td>{{ item }}</td>
  <td>{{ "yes" if loop.first else "no" }}</td>
  <td>{{ "yes" if loop.last  else "no" }}</td>
</tr>
{% endfor %}
</table>

<h2>Conditional</h2>
{% if score >= 90 %}
<p>Grade: A</p>
{% elif score >= 70 %}
<p>Grade: B</p>
{% else %}
<p>Grade: C</p>
{% endif %}

<h2>Set and Default Filter</h2>
{% set greeting = "Konnichiwa" %}
<p>{{ greeting | default("Hello") }}</p>
<p>Missing: {{ missing | default("(none)") }}</p>
</body>
</html>
TMPL

    my $html = $tmpl->render_string($source, {
        version => $HP::Handy::VERSION,
        name    => 'World',
        snippet => '<script>alert("xss")</script>',
        items   => [ 'Perl', 'Python', 'Ruby', 'JavaScript' ],
        score   => 85,
    });

    print $html;
}


###############################################################################
# HP::Handy::SafeString - trusted HTML string (bypasses auto_escape)
###############################################################################
package HP::Handy::SafeString;
use overload
    q("") => sub { ${$_[0]} },
    fallback => 1;

package HP::Handy;

1;

__END__

=head1 NAME

HP::Handy - A tiny Jinja2-compatible template engine for Perl 5.5.3 and later

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use HP::Handy;

  my $tmpl = HP::Handy->new(template_dir => './templates');

  # Render from file
  my $html = $tmpl->render_file('index.html', { name => 'World', items => [1,2,3] });

  # Render from string
  my $out = $tmpl->render_string('Hello, {{ name }}!', { name => 'World' });

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</REQUIREMENTS>

=item * L</CONSTRUCTOR>

=item * L</METHODS> -- render_file, render_string, add_filter, add_test

=item * L</TEMPLATE SYNTAX> -- variables, filters, tests, tags

=item * L</BUILT-IN FILTERS>

=item * L</BUILT-IN TESTS>

=item * L</TEMPLATE INHERITANCE>

=item * L</MACROS>

=item * L</DIAGNOSTICS>

=item * L</LIMITATIONS>

=item * L</DESIGN PHILOSOPHY>

=item * L</SEE ALSO>

=back

=head1 DESCRIPTION

HP::Handy is a single-file, zero-dependency Jinja2-compatible template engine
for Perl. It is designed for generating HTML pages from HTTP::Handy applications.

The goals of the project are simplicity and portability. The entire
implementation fits in one file with no installation step.

HP stands for I<HomePage>. Together with HTTP::Handy (server) and DB::Handy
(database), HP::Handy completes the three-layer stack for building local web
applications in pure Perl.

=head1 REQUIREMENTS

  Perl     : 5.5.3 or later -- all versions, all platforms
  OS       : Any (Windows, Unix, macOS, and others)
  Modules  : Core only -- Carp
  Model    : Pure Perl, regex-based evaluator

No CPAN modules are required.

=head1 CONSTRUCTOR

=head2 C<new(%args)>

Creates a new template engine instance.

  my $tmpl = HP::Handy->new(
      template_dir  => './templates',  # default: '.'
      auto_escape   => 1,              # default: 1 (HTML-escape {{ }} output)
      trim_blocks   => 0,              # default: 0 (remove newline after {% %})
      lstrip_blocks => 0,              # default: 0 (strip leading whitespace before {% %})
  );

=over 4

=item C<template_dir>

Directory to search for template files used by C<render_file()> and
C<{% include %}> / C<{% extends %}> tags.

=item C<auto_escape>

When true (the default), all C<{{ expr }}> output is HTML-escaped.
Use the C<safe> filter to bypass: C<{{ html | safe }}>.

=item C<trim_blocks>

When true, the newline immediately following a C<{% ... %}> tag is removed.
Equivalent to Jinja2's C<trim_blocks=True>.

=item C<lstrip_blocks>

When true, leading whitespace (spaces and tabs) before a C<{% ... %}> tag
on a line is stripped.  Equivalent to Jinja2's C<lstrip_blocks=True>.

=item C<block_start> / C<block_end>

Opening and closing delimiters for control tags.  Defaults: C<{%> and C<%}>.

=item C<var_start> / C<var_end>

Opening and closing delimiters for variable output.  Defaults: C<{{> and C<}}>.

=item C<comment_start> / C<comment_end>

Opening and closing delimiters for comments.  Defaults: C<{#> and C<#}>.

=back

=head1 METHODS

=head2 C<render_file($filename, \%vars)>

Load and render a template file. C<$filename> is relative to C<template_dir>.

  my $html = $tmpl->render_file('index.html', { name => 'World' });

=head2 C<render_string($source, \%vars)>

Render a template given as a string.

  my $out = $tmpl->render_string('Hello, {{ name }}!', { name => 'World' });

=head2 C<add_filter($name, \&code)>

Register a custom filter function. The first argument to the function is
the value being filtered; subsequent arguments come from the template call.

  $tmpl->add_filter('rot13', sub {
      my $s = $_[0];
      $s =~ tr/A-Za-z/N-ZA-Mn-za-m/;
      $s
  });

  # In template: {{ text | rot13 }}

=head2 C<add_test($name, \&code)>

Register a custom test function. Returns a true/false value.

  $tmpl->add_test('palindrome', sub {
      my $s = $_[0];
      defined $s && $s eq scalar reverse $s
  });

  # In template: {% if word is palindrome %}...{% endif %}

=head1 TEMPLATE SYNTAX

=head2 Delimiters

  {{ expr }}          Variable / expression output
  {% tag %}           Control tag (if, for, set, include, ...)
  {# comment #}       Comment (removed from output)

Whitespace control: add a dash inside the delimiter to strip whitespace.

  {%- tag -%}         Strip whitespace before and after the tag

=head2 Variables

  {{ name }}
  {{ user.email }}
  {{ items[0] }}
  {{ config["debug"] }}

=head2 Filters

  {{ name | upper }}
  {{ text | truncate(80) }}
  {{ text | replace("old", "new") }}
  {{ value | default("n/a") }}
  {{ items | join(", ") }}

=head2 Tests

  {% if x is defined %}
  {% if n is odd %}
  {% if x is divisibleby 3 %}
  {% if x is not none %}

=head2 Conditional

  {% if condition %}
      ...
  {% elif other %}
      ...
  {% else %}
      ...
  {% endif %}

Inline conditional:

  {{ "yes" if flag else "no" }}

=head2 For Loop

  {% for item in list %}
      {{ loop.index }}: {{ item }}
  {% endfor %}

  {% for item in list if item != '' %}
      {{ item }}
  {% else %}
      (empty)
  {% endfor %}

Loop variable C<loop>:

  loop.index      1-based counter
  loop.index0     0-based counter
  loop.revindex   reverse counter (1-based)
  loop.revindex0  reverse counter (0-based)
  loop.first      true on first iteration
  loop.last       true on last iteration
  loop.length     total number of items
  loop.odd        true on odd iterations
  loop.even       true on even iterations

Dict iteration:

  {% for key, value in mapping %}
      {{ key }}: {{ value }}
  {% endfor %}

=head2 Set

  {% set x = 42 %}
  {% set greeting = "Hello, " ~ name %}

=head2 Include

  {% include "header.html" %}
  {% include "optional.html" ignore missing %}

=head2 Raw

  {% raw %}
      {{ this is not rendered }}
  {% endraw %}

=head2 With

  {% with x = 10, y = 20 %}
      {{ x + y }}
  {% endwith %}

=head1 BUILT-IN FILTERS

  upper           Convert to uppercase
  lower           Convert to lowercase
  trim            Strip leading/trailing whitespace
  length          String or list length
  reverse         Reverse string or list
  escape / e      HTML-escape (&, <, >, ", ')
  safe            Mark as safe (skip auto_escape)
  default / d     Return value or default if undefined/empty
  replace         Replace substring
  truncate        Truncate string
  join            Join list with separator
  first           First element of list
  last            Last element of list
  list            Wrap scalar in list
  abs             Absolute value
  int             Convert to integer
  float           Convert to float
  string          Convert to string
  title           Title-case each word
  capitalize      Capitalize first letter
  urlencode       Percent-encode URL
  wordcount       Count words
  batch           Split list into chunks of N
  slice           Split list into N slices
  sort            Sort list (optionally by attribute)
  unique          Remove duplicates
  min             Minimum value in list
  max             Maximum value in list
  sum             Sum of list
  map             Map attribute over list
  select          Filter list by truthy attribute
  reject          Filter list by falsy attribute
  count           Number of elements
  nl2br           Replace newlines with <br>
  striptags       Strip HTML tags
  format          sprintf formatting
  center          Center string in a field
  indent          Indent lines
  xmlattr         Render hash as XML attributes
  tojson          Serialize to JSON
  pprint          Pretty-print value as JSON (no external dependency)
  forceescape     Force HTML-escape (ignores safe)

=head1 BUILT-IN TESTS

  defined         Value is defined
  none            Value is undef
  string          Value is a string (not reference)
  number          Value is numeric
  sequence        Value is an array reference
  mapping         Value is a hash reference
  iterable        Value is array or hash reference
  callable        Value is a code reference
  odd             Integer is odd
  even            Integer is even
  divisibleby N   Integer is divisible by N
  upper           String is all uppercase
  lower           String is all lowercase
  equalto X       Value equals X
  ne X            Value does not equal X
  in container    Value is in list/hash/string
  lt / le / gt / ge   Numeric comparisons

=head1 TEMPLATE INHERITANCE

Child template:

  {% extends "base.html" %}

  {% block title %}My Page{% endblock %}

  {% block content %}
  <p>Hello from child.</p>
  {% endblock %}

Base template (base.html):

  <!DOCTYPE html>
  <html>
  <head><title>{% block title %}Default{% endblock %}</title></head>
  <body>{% block content %}{% endblock %}</body>
  </html>

=head1 MACROS

  {% macro input(name, value="", type="text") %}
      <input type="{{ type }}" name="{{ name }}" value="{{ value }}">
  {% endmacro %}

  {{ input("username") }}
  {{ input("password", type="password") }}

=head1 DIAGNOSTICS

=over 4

=item C<add_filter: name required>

C<add_filter()> was called without a filter name argument.

=item C<add_filter: code must be coderef>

The second argument to C<add_filter()> is not a code reference.

=item C<add_test: name required>

C<add_test()> was called without a test name argument.

=item C<add_test: code must be coderef>

The second argument to C<add_test()> is not a code reference.

=item C<HP::Handy: path traversal not allowed in '$filename'>

The template filename passed to C<render_file()> or C<{% include %}> contains
C<..> which would allow reading files outside the C<template_dir>.

=item C<HP::Handy: cannot open '$path': $!>

C<render_file()> could not open the template file.
Check that the file exists and is readable.

=back

=head1 LIMITATIONS

=over 4

=item *

B<No compiled template cache.>  Templates are parsed on every render call.
For high-throughput use, cache rendered strings at the application layer.

=item *

B<No recursive macros> (calling a macro from within itself).

=item *

B<No import> (C<{% from "macros.html" import input %}>).
Use C<{% include %}> and call macros defined there.

=item *

B<No C<super()>> for accessing parent block content in template inheritance.

=item *

B<No C<namespace()>> for loop variable write-back across loop boundaries.

=item *

B<Nested dict/list literals> in expressions have limited support.
Complex data structures should be passed as Perl variables.

=item *

B<Expression parser is regex-based>, not a full AST.
Pathological expressions with many nested operators may not parse correctly.
Prefer passing pre-computed values from Perl for complex logic.

=item *

B<No Unicode-aware string operations.>
The C<length>, C<upper>, C<lower> filters operate on bytes, not characters,
for Perl 5.5.3 compatibility.  Use C<mb::> functions in your Perl code
and pass pre-processed values to the template.

=back

=head1 DESIGN PHILOSOPHY

HP::Handy adheres to the B<Perl 5.005_03 specification> for the same reasons
as HTTP::Handy and DB::Handy: simplicity, portability, and zero dependencies.

=over 4

=item B<One file>

The entire engine fits in one C<.pm> file.  No build step, no installation
required beyond copying.

=item B<Zero dependencies>

Only the core module C<Carp> is used.

=item B<Jinja2 syntax>

Uses the same C<{{ }}>  C<{% %}> C<{# #}> delimiters as Jinja2 so that
HTML templates written for Jinja2 (Python), Twig (PHP), or Nunjucks
(JavaScript) work with minimal changes.

=item B<Designed for HTTP::Handy>

HP::Handy is the view layer.  DB::Handy is the model layer.
HTTP::Handy is the controller layer.  Together they form a self-contained
MVC web stack for Perl 5.5.3 and later.

=back

=head1 SEE ALSO

L<HTTP::Handy> -- the HTTP/1.0 server layer (same distribution family).

L<DB::Handy> -- the flat-file database layer (same distribution family).

Jinja2 documentation (Python reference implementation):
L<https://jinja.palletsprojects.com/>

L<Template> -- Template Toolkit, the full-featured Perl template engine.
Requires Perl 5.8+.  HP::Handy is the minimal alternative for Perl 5.5.3+.

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

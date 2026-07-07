# Copyright (C) 2025  Scott Baker <scott@perturb.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

package Template::Sluz;

use strict;
use warnings;
use 5.016;

use File::Basename qw(dirname basename);
use autouse 'Carp' => qw(croak);

use constant SLUZ_INLINE => 'INLINE_TEMPLATE';

our $VERSION = 'v0.9.6';

################################################################################
# Built-in Sluz functions that can be used in templates
################################################################################

sub count {
    my $v = shift;

	if (ref $v eq 'ARRAY') {
		return scalar @$v;
	}

	if (ref $v eq 'HASH') {
		return scalar(keys %$v);
	}

    if (defined $v) { return 1 }

    return 0;
}

sub join {
    my $arr  = shift();
    my $glue = shift() // ', ';

    return CORE::join($glue, @$arr);
}

################################################################################
################################################################################

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = {
        version             => $VERSION,
        tpl_file            => undef,
        inc_tpl_file        => undef,
        debug               => $args{debug}       // 0,
        auto_escape         => $args{auto_escape} // 0,
        tpl_vars            => {},
        parent_tpl          => undef,
        var_prefix          => 'sluz_pfx',
        perl_file           => undef,
        perl_file_dir       => undef,
        fetch_called        => 0,
        char_pos            => -1,
        open_delim          => '{',
        close_delim         => '}',
        _sub_cache          => {},
        __S                 => {}, # Cached prefixed var hash used by _peval
        _convert_cache      => {}, # Cached _convert_vars results (avoids re-running regex on repeated expressions)
        _blocks_cache       => {}, # Cached _get_blocks results (avoids re-tokenizing if payloads in loops)
        _if_rules_cache     => {}, # Cached parsed {if} rules (avoids re-parsing same if block in loops)
        _verified_sub_cache => {}, # Cached subs that succeeded once — skip eval/SIG overhead
        _mod_cache          => {}, # Cached resolved modifier coderefs keyed by func name
    };

    bless $self, $class;
    $self->_precompute_tags();
    return $self;
}

sub assign {
    my $self = shift;

    my $pfx = $self->{var_prefix};

    # Accept either a hashref: assign($hash_ref)
    if (@_ == 1 && ref $_[0] eq 'HASH') {
        my $h = shift;
        @{$self->{tpl_vars}}{keys %$h} = values %$h;
        for my $k (keys %$h) {
            $self->{__S}{"${pfx}_$k"} = $h->{$k};
        }

    # Or a key-value list: assign(name => 'Scott', age => 42)
    } elsif (@_ % 2 == 0) {
        my %h = @_;
        @{$self->{tpl_vars}}{keys %h} = values %h;
        for my $k (keys %h) {
            $self->{__S}{"${pfx}_$k"} = $h{$k};
        }
    } else {
        $self->_error_out("Invalid assign. Must be a key/value or hash", 18956);
	}
}

sub fetch {
    my $self     = shift;
    my $tpl_file = shift // SLUZ_INLINE;
    my $parent   = shift;

    if (!$self->{perl_file}) {
        $self->{perl_file}     = $self->_get_perl_file;
        $self->{perl_file_dir} = dirname($self->{perl_file});
    }

    my $parent_tpl;
    if (defined $parent) {
        $parent_tpl = $parent;
    } else {
        $parent_tpl = $self->{parent_tpl};
    }

    if ($parent_tpl) {
        $self->assign('__CHILD_TPL', $tpl_file);
        $tpl_file = $parent_tpl;
    }

    my $str    = $self->_get_tpl_content($tpl_file);
    my @blocks = $self->_get_blocks($str);
    my $html   = $self->_process_blocks(\@blocks);

    $self->{fetch_called} = 1;
    return $html;
}

sub parse {
    my $self = shift;
    return $self->fetch(@_);
}

sub display {
    my $self = shift;
    print $self->fetch(@_);
}

# Parse a string instead of a file
sub parse_string {
    my $self    = shift;
    my $tpl_str = shift // '';
    my @blocks  = $self->_get_blocks($tpl_str);

    return $self->_process_blocks(\@blocks);
}

# Getter/setter for parent TPL
sub parent_tpl {
    my $self = shift;

    if (@_) {
        $self->{parent_tpl} = shift;
    }

    return $self->{parent_tpl};
}

sub set_delimiters {
    my $self  = shift;
    my $open  = shift;
    my $close = shift;

    if (!defined $open || !defined $close) {
        $self->_error_out("set_delimiters requires both open and close delimiter arguments", 51234);
    }

    if (length($open) != 1 || length($close) != 1) {
        $self->_error_out("Delimiters must be single characters", 51235);
    }

    if ($open eq $close) {
        $self->_error_out("Open and close delimiters must be different characters", 51236);
    }

    $self->{open_delim}  = $open;
    $self->{close_delim} = $close;

    $self->_precompute_tags();

    # Clear all caches since results are delimiter-dependent
    $self->{_blocks_cache}       = {};
    $self->{_if_rules_cache}     = {};
    $self->{_convert_cache}      = {};
    $self->{_sub_cache}          = {};
    $self->{_verified_sub_cache} = {};
    $self->{_mod_cache}          = {};

    return;
}

# Dive down an array or hashref using our dotted syntax
sub array_dive {
    my $self     = shift;
    my $needle   = shift;
    my $haystack = shift;

    if (!defined $needle || !defined $haystack) { return undef }

    # Quick path: needle is a direct key in the hash
    if (exists $haystack->{$needle}) {
        return $haystack->{$needle};
    }

    # Walk dotted path (e.g. "user.address.city") through nested structures
    my @parts = split /\./, $needle;
    my $arr   = $haystack;

    for my $elem (@parts) {
        if (!defined $arr) { return undef }
        if (ref $arr eq 'ARRAY') {
            if (!($elem =~ /^\d+$/ && $elem < @$arr)) { return undef }
            $arr = $arr->[$elem];
        } elsif (ref $arr eq 'HASH') {
            if (!exists $arr->{$elem}) { return undef }
            $arr = $arr->{$elem};
        } else {
            return undef;
        }
    }
    return $arr;
}

# HTML-escape a string for safe output. Encodes & < > " ' to entities.
# Usable as a modifier: {$var|escape} or as a callable: {escape($var)}
sub escape {
    my $str = shift // '';

    if (ref $str eq 'ARRAY') { return 'ARRAY' }
    if (ref $str eq 'HASH')  { return 'HASH' }

    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/"/&quot;/g;
    $str =~ s/'/&#x27;/g;

    return $str;
}

# Bypass auto-escaping when auto_escape is on: {$var|noescape}
sub noescape {
    return shift;
}

# Apply auto-escaping if enabled, otherwise return value unchanged.
# Ref types (ARRAY/HASH) pass through unescaped.
sub _esc {
    my ($self, $val) = @_;

    if (!$self->{auto_escape}) { return $val }
    if (ref $val)              { return $val }

    return escape($val);
}

sub ltrim_one {
    my $self = shift;
    my $str  = shift // '';
    my $char = shift;

    if (length $str && substr($str, 0, 1) eq $char) {
        return substr($str, 1);
    }

    return $str;
}

sub find_ending_tag {
    my $self      = shift;
    my $haystack  = shift // '';
    my $open_tag  = shift;
    my $close_tag = shift;

    # Find the first close tag; if there's only one open tag before it, we're done
    my $pos = index($haystack, $close_tag);
    if ($pos < 0) { return undef }

    my $substr     = substr($haystack, 0, $pos);
    my $open_count = () = $substr =~ /\Q$open_tag\E/g;
    if ($open_count == 1) { return $pos }

    # Nested tags: scan forward through subsequent close tags until
    # open/close counts balance (max 5 nesting levels)
    my $close_len = length $close_tag;
    my $offset    = $pos + $close_len;

    for (0 .. 4) {
        $pos = index($haystack, $close_tag, $offset);
        if ($pos < 0) { return undef }

        $substr         = substr($haystack, 0, $pos + 2);
        $open_count     = () = $substr =~ /\Q$open_tag\E/g;
        my $close_count = () = $substr =~ /\Q$close_tag\E/g;
        if ($open_count == $close_count) { return $pos }

        $offset = $pos + $close_len;
    }

    return undef;
}

sub get_tokens {
    my $self = shift;
    my $str  = shift // '';
    my $o = quotemeta($self->{open_delim});
    my $c = quotemeta($self->{close_delim});
    my @tokens = split /($o[^$c]+$c)/, $str;
    @tokens = grep { defined && length } @tokens;
    return @tokens;
}

sub is_if_token {
    my $self = shift;
    my $str  = shift // '';
    if ($str eq $self->{_tag_else})   { return 1 }
    if ($str eq $self->{_tag_if_close}) { return 1 }
    if (index($str, $self->{_tag_if}) == 0 || index($str, $self->{_tag_elseif}) == 0) {
        my $inner = substr($str, length($self->{open_delim}));
        $inner =~ s/^\S+\s+//;  # strip 'if ' or 'elseif '
        $inner =~ s/\Q$self->{close_delim}\E$//;
        return $inner;
    }
    return '';
}

# -------------------------------------------------------------------
# Private methods
# -------------------------------------------------------------------

sub _precompute_tags {
    my $self = shift;
    my $o    = $self->{open_delim};
    my $c    = $self->{close_delim};

    # Tag strings
    $self->{_tag_if}              = "${o}if ";
    $self->{_tag_if_close}        = "${o}/if${c}";
    $self->{_tag_else}            = "${o}else${c}";
    $self->{_tag_elseif}          = "${o}elseif ";
    $self->{_tag_foreach}         = "${o}foreach ";
    $self->{_tag_foreach_close}   = "${o}/foreach${c}";
    $self->{_tag_include}         = "${o}include ";
    $self->{_tag_literal}         = "${o}literal${c}";
    $self->{_tag_literal_close}   = "${o}/literal${c}";
    $self->{_tag_comment_open}    = "${o}*";
    $self->{_tag_comment_close}   = "*${c}";

    # Precomputed tag lengths (avoids repeated length() calls in hot loops)
    $self->{_tag_if_len}            = length($self->{_tag_if});
    $self->{_tag_if_close_len}      = length($self->{_tag_if_close});
    $self->{_tag_foreach_len}       = length($self->{_tag_foreach});
    $self->{_tag_include_len}       = length($self->{_tag_include});
    $self->{_tag_literal_len}       = length($self->{_tag_literal});
    $self->{_tag_literal_close_len} = length($self->{_tag_literal_close});

    # Precomputed quotemeta values (avoids per-call quotemeta in _get_blocks)
    $self->{_od_qr} = quotemeta($o);
    $self->{_cd_qr} = quotemeta($c);

    # Precompiled space-guard regex (avoids per-open-delimiter regex compile)
    my $od_qr = $self->{_od_qr};
    my $cd_qr = $self->{_cd_qr};
    $self->{_space_guard_re} = qr/\s[$od_qr$cd_qr]\s/;

    # Precompiled variable regex: {$var} or {$var.dot.path}
    $self->{_re_var_simple} = qr/^\Q$o\E\$(\w[\w.]*)\Q$c\E$/;
    $self->{_re_var_full}   = qr/^\Q$o\E\$([\w|.'";\t :,!@#%^&*?_\/\\\-]+)\Q$c\E$/;

    # Precompiled foreach regex
    $self->{_re_foreach} = qr/^\Q$o\Eforeach (\$\w[\w.]*) as \$(\w+)(?: => \$(\w+))?\Q$c\E(.+)\Q$o\E\/foreach\Q$c\E$/s;

    # Precompiled literal regex
    $self->{_re_literal} = qr/^\Q$o\Eliteral\Q$c\E(.+)\Q$o\E\/literal\Q$c\E$/s;

    # Precompiled expression catch-all regex
    $self->{_re_expr} = qr/^\Q$o\E(.+)\Q$c\E$/s;

    # Precompiled simple if regex (no else/elseif)
    $self->{_re_if_simple} = qr/\Q$o\Eif (.+?)\Q$c\E(.+)\Q$o\E\/if\Q$c\E/s;

    # Precomputed ord values for fast single-character delimiter checks
    $self->{_od_ord}      = ord($o);
    $self->{_cd_ord}      = ord($c);
    $self->{_dollar_ord}  = ord('$');

    # Precompiled modifier-split regexes (avoids per-modifier-call recompile)
    $self->{_pipe_re}  = qr/\|(?![^"]*"(?:(?:[^"]*"){2})*[^"]*$)(?![^']*'(?:(?:[^']*'){2})*[^']*$)/;
    $self->{_comma_re} = qr/,(?=(?:[^"]*"[^"]*")*[^"]*$)(?=(?:[^']*'[^']*')*[^']*$)/;

    return;
}

sub _get_perl_file {
    my $self = shift;
    my $i    = 0;
    my $file;

    while (caller($i)) {
        $file = (caller($i))[1];
        $i++;
    }

    return $file || __FILE__;
}

sub _get_tpl_content {
    my $self     = shift;
    my $tpl_file = shift // '';
    $self->{tpl_file} = $tpl_file;
    my $tf = $tpl_file;

    if ($self->{perl_file_dir}) {
        $tf = $self->{perl_file_dir} . "/$tf";
    }

    if (!length($tpl_file)) {
        $self->_error_out("Template file name is empty", 86801);
    }

    if ($tpl_file eq SLUZ_INLINE) {
        my ($c, $line_offset) = $self->_get_inline_content($self->{perl_file});
        if (defined $c) {
            $self->{tpl_file_display} = $self->{perl_file};
            $self->{tpl_line_offset}  = $line_offset;
            return $c;
        }
        delete $self->{tpl_file_display};
        delete $self->{tpl_line_offset};
        return '';
    } else {
        delete $self->{tpl_file_display};
        delete $self->{tpl_line_offset};
    }

    if ($tf && !-r $tf) {
        $self->_error_out("Unable to load template file <code>$tf</code>", 42280);
    }

    if ($tf) {
        local $/;
        open my $fh, '<', $tf or $self->_error_out("Cannot open <code>$tf</code>: $!", 13983);
        my $str = <$fh>;
        close $fh;
        return $str // '';
    }

    return '';
}

sub _get_inline_content {
    my $self = shift;
    my $file = shift;
    local $/;
    open my $fh, '<', $file or return undef;
    my $str = <$fh>;
    close $fh;
    my $idx = index($str, '__DATA__');
    if ($idx < 0) { return undef }
    my $before = substr($str, 0, $idx + 9);
    my $line_offset = $before =~ tr/\n//;
    return (substr($str, $idx + 9), $line_offset);
}

# -------------------------------------------------------------------
# Tokenizer
# -------------------------------------------------------------------

sub _get_blocks {
    my $self = shift;
    my $str  = shift // '';

    # Check blocks cache — avoids re-tokenizing the same payload string
    # (e.g. an {if} payload re-parsed on every iteration of a {foreach} loop)
    if (exists $self->{_blocks_cache}{$str}) {
        return @{$self->{_blocks_cache}{$str}};
    }

    my $od          = $self->{open_delim};
    my $cd          = $self->{close_delim};
    my $tag_if      = $self->{_tag_if};
    my $tag_foreach = $self->{_tag_foreach};
    my $tag_literal = $self->{_tag_literal};
    my $slen        = length $str;
    my $start       = 0;
    my $i;
    my @blocks;

    my $z = index($str, $od);
    if ($z < 0) { $z = $slen }

    for ($i = $z; $i < $slen; $i++) {
        my $char      = substr($str, $i, 1);
        my $is_open   = $char eq $od;
        my $is_closed = $char eq $cd;

        if (!$is_open && !$is_closed) {
            my $next_open  = index($str, $od, $i);
            if ($next_open < 0) { $next_open = $slen }
            my $next_close = index($str, $cd, $i);
            if ($next_close < 0) { $next_close = $slen }
            if ($next_open < $next_close) {
                $i = $next_open - 1;
            } else {
                $i = $next_close - 1;
            }
            next;
        }

        my $has_len    = $start != $i;
        my $is_comment = 0;

        if ($is_open) {
            my $prev_c;
            if ($i > 0) {
                $prev_c = substr($str, $i - 1, 1);
            } else {
                $prev_c = ' ';
            }
            my $next_c;
            if ($i + 1 < $slen) {
                $next_c = substr($str, $i + 1, 1);
            } else {
                $next_c = ' ';
            }
            my $chk = $prev_c . $char . $next_c;
            if ($chk =~ $self->{_space_guard_re}) { $is_open = 0 }
            if ($next_c eq '*') { $is_comment = 1 }
        }

        if ($is_open && $has_len) {
            push @blocks, [substr($str, $start, $i - $start), $i];
            $start = $i;
        } elsif ($is_closed) {
            my $len   = $i - $start + 1;
            my $block = substr($str, $start, $len);

            my $matched_block;
            if    (index($block, $tag_if) == 0)        { $matched_block = 'if'      }
            elsif (index($block, $tag_foreach) == 0)   { $matched_block = 'foreach' }
            elsif (index($block, $tag_literal) == 0)   { $matched_block = 'literal' }

            if ($matched_block) {
                my $close_tag = "${od}/${matched_block}${cd}";
                for (my $j = $i + 1; $j < length $str; $j++) {
                    if (substr($str, $j, 1) eq $cd) {
                        my $tmp = substr($str, $start, $j - $start + 1);
                        my $oc  = () = $tmp =~ /\Q${od}${matched_block}\E/g;
                        my $cc  = () = $tmp =~ /\Q${close_tag}\E/g;
                        if ($oc == $cc) {
                            $block = $tmp;
                            last;
                        }
                    }
                }
            }

            if (length $block) { push @blocks, [$block, $i] }
            $start += length($block);
            $i = $start;
        }

        if ($is_comment) {
            my $end = $self->find_ending_tag(substr($str, $start), $self->{_tag_comment_open}, $self->{_tag_comment_close});
            if (!defined $end) {
                my ($line, $col, $file) = $self->_get_char_location($i, $self->{tpl_file});
                $self->_error_out("Missing closing <code>$self->{_tag_comment_close}</code> for comment in <code>$file</code> on line #$line", 48724);
            }
            my $after = $start + $end + length($self->{_tag_comment_close});

            my $pre_nl  = ($i == 0 || substr($str, $i - 1, 1) eq "\n");
            my $post_nl = ($after >= $slen || substr($str, $after, 1) eq "\n");
            if ($pre_nl && $post_nl && $after < $slen) {
                $after++;
            }

            $start = $after;
            $i = $start - 1;
        }
    }

    if ($start < $slen) {
        push @blocks, [substr($str, $start), $i];
    }

    # Strip leading newline from text blocks that follow {if} or
    # {foreach} blocks, to avoid double-newlines when the block
    # payload already ends with \n. For {foreach}, only strip when
    # the payload actually ends with \n — if the payload is inline
    # (no trailing \n), the newline is structural content, not
    # whitespace noise.
    my $prev_is_if = 0;
    my $tag_foreach_close = $self->{_tag_foreach_close};
    for my $i (0 .. $#blocks) {
        my $bstr     = $blocks[$i][0] // '';
        my $cur_is_if = (index($bstr, $tag_if) == 0 || index($bstr, $tag_foreach) == 0);
        if ($prev_is_if) {
            my $should_strip = 1;
            if ($blocks[$i-1][0] =~ /^\Q$tag_foreach\E.+?\}(.*)\Q$tag_foreach_close\E$/s) {
                $should_strip = (substr($1, -1) eq "\n") ? 1 : 0;
            }
            if ($should_strip) {
                $blocks[$i][0] = $self->ltrim_one($bstr, "\n");
            }
        }
        $prev_is_if = $cur_is_if;
    }

    $self->{_blocks_cache}{$str} = \@blocks;
    return @blocks;
}

sub _process_blocks {
    my $self   = shift;
    my $blocks = shift;
    my $out    = shift;  # Optional: ref to append output to (avoids temp string + concat)

    my $od_ord = $self->{_od_ord};
    my $od     = $self->{open_delim};
    my $var_tag = "${od}\$";
    my $var_re  = $self->{_re_var_simple};

    if ($out) {
        for my $x (@$blocks) {
            my $block = $x->[0];
            next unless length $block;
            if (ord($block) != $od_ord) {
                $$out .= $block;
                next;
            }
            # Fast path: {$var} or {$var.dot} with no modifier — inline
            # variable resolution, skip _process_block AND _variable_block
            if (substr($block, 0, 2) eq $var_tag && index($block, '|') < 0
                && $block =~ $var_re) {
                my $var = $1;
                my $val;
                if (index($var, '.') < 0) {
                    $val = $self->{tpl_vars}{$var};
                } else {
                    $val = $self->array_dive($var, $self->{tpl_vars});
                }
                if (ref $val eq 'ARRAY')  { $$out .= 'ARRAY' }
                elsif (ref $val eq 'HASH') { $$out .= 'HASH' }
                elsif (defined $val)       { $$out .= ($self->{auto_escape} ? escape($val) : $val) }
                next;
            }
            # If block fast path — skip _process_block dispatch (mirrors
            # the $html branch so the $out path is equally fast).
            if (substr($block, 0, $self->{_tag_if_len}) eq $self->{_tag_if}
                && substr($block, -$self->{_tag_if_close_len}) eq $self->{_tag_if_close}) {
                $self->{char_pos} = $x->[1];
                $$out .= $self->_if_block($block);
                next;
            }
            $$out .= $self->_process_block($block, $x->[1]);
        }
        return;
    }

    my $html = '';
    for my $x (@$blocks) {
        my $block = $x->[0];
        next unless length $block;
        if (ord($block) != $od_ord) {
            $html .= $block;
            next;
        }
        # Fast path: {$var} or {$var.dot} with no modifier
        if (substr($block, 0, 2) eq $var_tag && index($block, '|') < 0
            && $block =~ $var_re) {
            my $var = $1;
            my $val;
            if (index($var, '.') < 0) {
                $val = $self->{tpl_vars}{$var};
            } else {
                $val = $self->array_dive($var, $self->{tpl_vars});
            }
            if (ref $val eq 'ARRAY')  { $html .= 'ARRAY' }
            elsif (ref $val eq 'HASH') { $html .= 'HASH' }
            elsif (defined $val)       { $html .= ($self->{auto_escape} ? escape($val) : $val) }
            next;
        }
        # If block fast path — skip _process_block dispatch
        if (substr($block, 0, $self->{_tag_if_len}) eq $self->{_tag_if}
            && substr($block, -$self->{_tag_if_close_len}) eq $self->{_tag_if_close}) {
            $self->{char_pos} = $x->[1];
            $html .= $self->_if_block($block);
            next;
        }
        $html .= $self->_process_block($block, $x->[1]);
    }

    return $html;
}

sub _process_block {
    my $self     = shift;
    my $str      = shift // '';
    my $char_pos = shift // -1;

    $self->{char_pos} = $char_pos;

    my $od     = $self->{open_delim};
    my $cd_ord = $self->{_cd_ord};

    # 1. Variable block {$foo} or {$foo|modifier}
    if (substr($str, 0, 2) eq "${od}\$" && $str =~ $self->{_re_var_full}) {
        return $self->_variable_block($1);
    }

    # 2. If block {if ...}{/if}
    if (substr($str, 0, $self->{_tag_if_len}) eq $self->{_tag_if}
        && substr($str, -$self->{_tag_if_close_len}) eq $self->{_tag_if_close}) {
        return $self->_if_block($str);
    }

    # 3. Foreach block {foreach ...}{/foreach}
    if (substr($str, 0, $self->{_tag_foreach_len}) eq $self->{_tag_foreach} && $str =~ $self->{_re_foreach}) {
        return $self->_foreach_block($1, $2, $3, $4);
    }

    # 4. Include block {include ...}
    if (substr($str, 0, $self->{_tag_include_len}) eq $self->{_tag_include}) {
        return $self->_include_block($str);
    }

    # 5. Literal block {literal}...{/literal}
    if (substr($str, 0, $self->{_tag_literal_len}) eq $self->{_tag_literal} && $str =~ $self->{_re_literal}) {
        return $1;
    }

    # 6. Expression / function block
    if ($str =~ $self->{_re_expr}) {
        return $self->_expression_block($str, $1);
    }

    # 7. Unclosed tag
    if (ord(substr($str, -1)) != $cd_ord) {
        my $tag_start = $self->{char_pos} - length($str);
        my ($line, $col, $file) = $self->_get_char_location($tag_start, $self->{tpl_file});
        $self->_error_out("Unclosed tag <code>$str</code> in <code>$file</code> on line #$line", 45821);
    }

    # 8. Fallthrough
    return $str;
}

# -------------------------------------------------------------------
# Block handlers
# -------------------------------------------------------------------

sub _variable_block {
    my $self = shift;
    my $str  = shift;

    # Fast path: no pipe means no modifier, just resolve the variable.
    # Avoids running the pipe-split regex on every plain variable block.
    if (index($str, '|') < 0) {
        my $ret;
        # Inline simple key lookup (no dots) — skips array_dive method call
        if (index($str, '.') < 0) {
            $ret = $self->{tpl_vars}{$str};
        } else {
            $ret = $self->array_dive($str, $self->{tpl_vars});
        }
        if (ref $ret eq 'ARRAY') { return 'ARRAY' }
        if (ref $ret eq 'HASH')  { return 'HASH' }
        if (defined $ret) { return ($self->{auto_escape} ? escape($ret) : $ret) }
        return '';
    }

    if ($str =~ /(.+?)\|(.*)/) {
        my $key = $1;
        my $mod = $2;

        my $tmp        = $self->array_dive($key, $self->{tpl_vars});
        my $is_nothing = (!defined $tmp || (defined $tmp && ref $tmp eq '' && !length $tmp && $tmp ne '0'));
        my $is_default = index($mod, 'default:') >= 0;

        if ($is_nothing && $is_default) {
            my $dval = $mod;
            $dval =~ s/^.*?default://;
            my ($ret) = $self->_peval($dval);
            if (defined $ret) { return $ret }
            return '';
        } elsif (!$is_nothing && $is_default) {
            return $tmp // '';
        } else {
            if ($is_nothing) {
                return '';
            }
            my $pre = $tmp;

            my $seen_escape   = 0;
			my $seen_noescape = 0;

            # Split on | not inside double or single quotes (supports chained
            # modifiers like {$x|uc|substr:0,3}). Regex precompiled in
            # _precompute_tags to avoid per-call recompile cost.
            my $pipe_re = $self->{_pipe_re};
            for my $m_part (split $pipe_re, $mod) {
                my @x    = split /:/, $m_part, 2;
                my $func = $x[0] // '';
                if ($func eq 'escape')   { $seen_escape   = 1 }
                if ($func eq 'noescape') { $seen_noescape = 1 }
                my $param_str = $x[1] // '';
                my @params = ($pre);

                if (length $param_str) {
                    # Split on commas not inside double or single quotes
                    # (parameter separator in modifier calls like substr:2,2)
                    my @new = map {
                        my ($v) = $self->_peval($_);
                        $v;
                    } split $self->{_comma_re}, $param_str;
                    push @params, @new;
                }

                # Resolve the modifier coderef once per func name and cache it.
                # Priority: main::, current package (Template::Sluz built-ins),
                # then CORE:: built-in operators.
                my $cref = $self->{_mod_cache}{$func};
                if (!defined $cref) {
                    no strict 'refs';
                    if    (defined &{"main::$func"}) { $cref = \&{"main::$func"} }
                    elsif (defined &{$func})         { $cref = \&{$func} }
                    elsif (defined &{"CORE::$func"}) { $cref = \&{"CORE::$func"} }
                    else                            { $cref = 0 }
                    $self->{_mod_cache}{$func} = $cref;
                }

                if (!$cref) {
                    my ($line, $col, $file) = $self->_get_char_location($self->{char_pos}, $self->{tpl_file});
                    $self->_error_out("Unknown function call <code>$func</code> in <code>$file</code> on line #$line", 47204);
                }

                $pre = eval { $cref->(@params) };
                if ($@) {
                    $self->_error_out("Exception: $@", 79134);
                }
            }

            if ($self->{auto_escape} && !$seen_noescape && !$seen_escape) {
                return escape($pre);
            }
            return $pre;
        }
    }

    my $ret = $self->array_dive($str, $self->{tpl_vars});
    if (ref $ret eq 'ARRAY') { return 'ARRAY' }
    if (ref $ret eq 'HASH')  { return 'HASH' }
    if (defined $ret) { return ($self->{auto_escape} ? escape($ret) : $ret) }
    return '';
}

sub _if_block {
    my $self = shift;
    my $str  = shift;

    my @rules;
    if (exists $self->{_if_rules_cache}{$str}) {
        @rules = @{$self->{_if_rules_cache}{$str}};
    } else {
        my $od = $self->{open_delim};
        my $cd = $self->{close_delim};
        my $isimple_start = length($od) + 1;
        my $else_check = $od . 'else';
        my $is_simple = index($str, $else_check, $isimple_start) < 0;

        if ($is_simple) {
            $str =~ $self->{_re_if_simple};
            my $cond    = $1 // '';
            my $payload = $2 // '';
            $payload = $self->ltrim_one($payload, "\n");
            @rules = ([$cond, $payload]);
        } else {
            my @toks = $self->get_tokens($str);
            @rules   = $self->_if_rules_from_tokens(\@toks);
        }

        $self->{_if_rules_cache}{$str} = \@rules;
    }

    my $ret = '';
    for my $rule (@rules) {
        my $raw = $rule->[0];
        # Inline _convert_vars for cached expressions — saves method call per iteration
        my $test = (index($raw, '$') < 0) ? $raw :
                   ($self->{_convert_cache}{$raw} // $self->_convert_vars($raw));
        my $payload = $rule->[1];
        my ($res) = $self->_peval($test);
        if ($res) {
            # Inline _get_blocks for cached payloads. Pass \$ret to
            # _process_blocks so it appends directly — avoids a temp
            # string allocation + concat per if-payload render.
            my $cached = $self->{_blocks_cache}{$payload};
            my @in_blocks = $cached ? @$cached : $self->_get_blocks($payload);
            $self->_process_blocks(\@in_blocks, \$ret);
            last;
        }
    }

    return $ret;
}

sub _foreach_block {
    my $self     = shift;
    my $src_expr = shift;
    my $okey     = shift;
    my $oval     = shift;
    my $payload  = shift;

    my $conv_src = $self->_convert_vars($src_expr);
    $payload     = $self->ltrim_one($payload, "\n");
    my @blocks   = $self->_get_blocks($payload);

    # Pre-classify blocks for fast dispatch in the loop (cached in block arrays)
    # type: -1=empty, 0=text, 1=simple_var, 2=if_block, 99=other
    my $od     = $self->{open_delim};
    my $od_ord = $self->{_od_ord};
    for my $b (@blocks) {
        next if defined $b->[2];
        my $bs = $b->[0];
        if (!length $bs) {
            $b->[2] = -1;
        } elsif (ord($bs) != $od_ord) {
            $b->[2] = 0;
        } elsif (substr($bs, 0, 2) eq "${od}\$" && index($bs, '|') < 0
                 && $bs =~ $self->{_re_var_simple}) {
            $b->[2] = 1;
            $b->[3] = $1;
        } elsif (substr($bs, 0, $self->{_tag_if_len}) eq $self->{_tag_if}
                 && substr($bs, -$self->{_tag_if_close_len}) eq $self->{_tag_if_close}) {
            $b->[2] = 2;
        } else {
            $b->[2] = 99;
        }
    }

    my ($src) = $self->_peval($conv_src);

    if (!defined $src) {
        $src = [];
    } elsif (ref $src ne 'ARRAY' && ref $src ne 'HASH') {
        $src = [$src];
    }

    my $pfx      = $self->{var_prefix};

    # Precompute __S keys for the loop variables
    my $okey_ks   = "${pfx}_$okey";
    my $oval_ks   = defined $oval ? "${pfx}_$oval" : undef;
    my $first_ks  = "${pfx}__FOREACH_FIRST";
    my $last_ks   = "${pfx}__FOREACH_LAST";
    my $index_ks  = "${pfx}__FOREACH_INDEX";

    my $ret  = '';
    my $idx  = 0;

    my $need_first = index($payload, '__FOREACH_FIRST') >= 0;
    my $need_last  = index($payload, '__FOREACH_LAST')  >= 0;
    my $need_index = index($payload, '__FOREACH_INDEX') >= 0;

    # Save only the keys we'll modify — O(k) where k <= 5, vs O(n) for
    # copying the entire tpl_vars/__S hashes. Big win for nested foreach.
    my @tpl_keys = ($okey);
    my @ks_keys  = ($okey_ks);
    if (defined $oval) {
        push @tpl_keys, $oval;
        push @ks_keys,  $oval_ks;
    }
    push @tpl_keys, '__FOREACH_FIRST' if $need_first;
    push @ks_keys,  $first_ks         if $need_first;
    push @tpl_keys, '__FOREACH_LAST'  if $need_last;
    push @ks_keys,  $last_ks          if $need_last;
    push @tpl_keys, '__FOREACH_INDEX' if $need_index;
    push @ks_keys,  $index_ks         if $need_index;

    my @tpl_exists = map { exists $self->{tpl_vars}{$_} } @tpl_keys;
    my @tpl_vals   = map { $self->{tpl_vars}{$_} } @tpl_keys;
    my @ks_exists  = map { exists $self->{__S}{$_} } @ks_keys;
    my @ks_vals    = map { $self->{__S}{$_} } @ks_keys;

    if (ref $src eq 'ARRAY') {
        my $last = $#$src;
        for my $i (0 .. $last) {
            if ($need_first) {
                $self->{tpl_vars}{__FOREACH_FIRST} = ($idx == 0) ? 1 : 0;
                $self->{__S}{$first_ks} = ($idx == 0) ? 1 : 0;
            }
            if ($need_last) {
                $self->{tpl_vars}{__FOREACH_LAST} = ($idx == $last) ? 1 : 0;
                $self->{__S}{$last_ks} = ($idx == $last) ? 1 : 0;
            }
            if ($need_index) {
                $self->{tpl_vars}{__FOREACH_INDEX} = $idx;
                $self->{__S}{$index_ks} = $idx;
            }
            if (defined $oval) {
                $self->{tpl_vars}{$okey} = $i;
                $self->{tpl_vars}{$oval} = $src->[$i];
                $self->{__S}{$okey_ks} = $i;
                $self->{__S}{$oval_ks} = $src->[$i];
            } else {
                $self->{tpl_vars}{$okey} = $src->[$i];
                $self->{__S}{$okey_ks} = $src->[$i];
            }
            # Inline block processing with pre-classified types — no substr/regex per iteration
            for my $b (@blocks) {
                my $type = $b->[2];
                if ($type == 0) {
                    $ret .= $b->[0];
                } elsif ($type == 1) {
                    my $var = $b->[3];
                    my $val;
                    if (index($var, '.') < 0) {
                        $val = $self->{tpl_vars}{$var};
                    } else {
                        $val = $self->array_dive($var, $self->{tpl_vars});
                    }
                    if (ref $val eq 'ARRAY')  { $ret .= 'ARRAY' }
                    elsif (ref $val eq 'HASH') { $ret .= 'HASH' }
                    elsif (defined $val)       { $ret .= ($self->{auto_escape} ? escape($val) : $val) }
                } elsif ($type == 2) {
                    $self->{char_pos} = $b->[1];
                    $ret .= $self->_if_block($b->[0]);
                } elsif ($type == -1) {
                    next;
                } else {
                    $ret .= $self->_process_block($b->[0], $b->[1]);
                }
            }
            $idx++;
        }
    } elsif (ref $src eq 'HASH') {
        my @keys = sort keys %$src;
        my $last = $#keys;
        for my $i (0 .. $last) {
            my $k = $keys[$i];
            if ($need_first) {
                $self->{tpl_vars}{__FOREACH_FIRST} = ($idx == 0) ? 1 : 0;
                $self->{__S}{$first_ks} = ($idx == 0) ? 1 : 0;
            }
            if ($need_last) {
                $self->{tpl_vars}{__FOREACH_LAST} = ($idx == $last) ? 1 : 0;
                $self->{__S}{$last_ks} = ($idx == $last) ? 1 : 0;
            }
            if ($need_index) {
                $self->{tpl_vars}{__FOREACH_INDEX} = $idx;
                $self->{__S}{$index_ks} = $idx;
            }
            if (defined $oval) {
                $self->{tpl_vars}{$okey} = $k;
                $self->{tpl_vars}{$oval} = $src->{$k};
                $self->{__S}{$okey_ks} = $k;
                $self->{__S}{$oval_ks} = $src->{$k};
            } else {
                $self->{tpl_vars}{$okey} = $src->{$k};
                $self->{__S}{$okey_ks} = $src->{$k};
            }
            # Inline block processing with pre-classified types — no substr/regex per iteration
            for my $b (@blocks) {
                my $type = $b->[2];
                if ($type == 0) {
                    $ret .= $b->[0];
                } elsif ($type == 1) {
                    my $var = $b->[3];
                    my $val;
                    if (index($var, '.') < 0) {
                        $val = $self->{tpl_vars}{$var};
                    } else {
                        $val = $self->array_dive($var, $self->{tpl_vars});
                    }
                    if (ref $val eq 'ARRAY')  { $ret .= 'ARRAY' }
                    elsif (ref $val eq 'HASH') { $ret .= 'HASH' }
                    elsif (defined $val)       { $ret .= ($self->{auto_escape} ? escape($val) : $val) }
                } elsif ($type == 2) {
                    $self->{char_pos} = $b->[1];
                    $ret .= $self->_if_block($b->[0]);
                } elsif ($type == -1) {
                    next;
                } else {
                    $ret .= $self->_process_block($b->[0], $b->[1]);
                }
            }
            $idx++;
        }
    }

    # Restore only the keys we modified
    for my $i (0 .. $#tpl_keys) {
        if ($tpl_exists[$i]) {
            $self->{tpl_vars}{$tpl_keys[$i]} = $tpl_vals[$i];
        } else {
            delete $self->{tpl_vars}{$tpl_keys[$i]};
        }
        if ($ks_exists[$i]) {
            $self->{__S}{$ks_keys[$i]} = $ks_vals[$i];
        } else {
            delete $self->{__S}{$ks_keys[$i]};
        }
    }

    return $ret;
}

sub _include_block {
    my $self = shift;
    my $str  = shift;

    my $save    = $self->{tpl_vars};
    my $inc_tpl = $self->_extract_include_file($str);

    if ($self->{perl_file_dir}) {
        $inc_tpl = $self->{perl_file_dir} . "/$inc_tpl";
    }

    while ($str =~ m/(\w+)=(['"](.+?)['"])/g) {
        my $key = $1;
        my $val = $2;
        if ($key eq 'file') { next }
        $val = $self->_convert_vars($val);
        my ($res) = $self->_peval($val);
        if (defined $res) {
            $self->assign($key => $res);
        } else {
            $self->assign($key => $val);
        }
    }

    if (!-f $inc_tpl || !-r $inc_tpl) {
        $self->{inc_tpl_file} = undef;
        my ($line, $col, $file) = $self->_get_char_location($self->{char_pos}, $self->{tpl_file});
        $self->_error_out("Unable to load include template <code>$inc_tpl</code> in <code>$file</code> on line #$line", 18485);
    }

    local $/;
    open my $fh, '<', $inc_tpl or $self->_error_out("Cannot open <code>$inc_tpl</code>: $!", 63579);
    my $content = <$fh>;
    close $fh;

    my @blocks = $self->_get_blocks($content);
    my $r      = $self->_process_blocks(\@blocks);

    $self->{tpl_vars}      = $save;
    $self->{inc_tpl_file}  = undef;

    return $r;
}

sub _expression_block {
    my $self  = shift;
    my $str   = shift;
    my $inner = shift;

    if ($str !~ /["\d\$\(]/) {
        my ($line, $col, $file) = $self->_get_char_location($self->{char_pos}, $self->{tpl_file});
        $self->_error_out("Unknown block type <code>$str</code> in <code>$file</code> on line #$line", 73467);
    }

    my $after = $self->_convert_vars($inner);
    my ($ret, $err) = $self->_peval($after);

    my $valid;
    if (defined $ret && (!ref $ret || ref $ret eq '')) {
        $valid = 1;
    } else {
        $valid = 0;
    }

    if ($err || !$valid) {
        my ($line, $col, $file) = $self->_get_char_location($self->{char_pos}, $self->{tpl_file});
        $self->_error_out("Unknown tag <code>$str</code> in <code>$file</code> on line #$line", 18933);
    }

    return $ret;
}

# -------------------------------------------------------------------
# Variable / eval engine
# -------------------------------------------------------------------

sub _convert_vars {
    my $self = shift;
    my $str  = shift // '';
    if (index($str, '$') < 0) { return $str }

    # Check conversion cache — avoids re-running regex substitutions on
    # the same expression (e.g. an {if} condition inside a {foreach} loop)
    if (exists $self->{_convert_cache}{$str}) {
        return $self->{_convert_cache}{$str};
    }

    my $orig = $str;

    # Step 1: $var.key -> $__S->{sluz_pfx_var}->{key}
    $str =~ s/(\$\w[\w\.]*)/ $self->_dot_to_bracket_cb($1) /ge;

    # Step 2: $__S->{...}["key"] -> $__S->{...}->{key} (PHP bracket syntax)
    if (index($str, '[') >= 0) {
        $str =~ s/(\$__S(?:->\{[^}]+\})+)\[(["'])([^\]]+?)\2\]/$1 . '->{' . $3 . '}'/ge;
    }

    $self->{_convert_cache}{$orig} = $str;
    return $str;
}

sub _dot_to_bracket_cb {
    my $self  = shift;
    my $match = shift;
    my @parts = split /\./, $match;
    my $first = shift @parts;
    my $var   = substr($first, 1);
    my $res   = "\$__S->\{$self->{var_prefix}_$var\}";
    for my $p (@parts) {
        if ($p =~ /^\d+$/) {
            $res .= "->[$p]";
        } else {
            $res .= "->{$p}";
        }
    }
    return $res;
}

sub _micro_optimize {
    my $self = shift;
    my $str  = shift // '';
    if ($str =~ /^-?\d+(?:\.\d+)?$/) { return $str }

    if (!length $str) { return undef }
    my $first = ord($str);
    my $last  = ord(substr($str, -1));

    if ($first == 39 && $last == 39) {
        my $tmp = substr($str, 1, length($str) - 2);
        if (index($tmp, "'") < 0) { return $tmp }
    }

    if ($first == 34 && $last == 34) {
        my $tmp = substr($str, 1, length($str) - 2);
        if (index($tmp, '$') < 0 && index($tmp, '"') < 0) { return $tmp }
    }

    if ($str =~ /^(!?)\$__S->\{sluz_pfx_(\w+)\}$/ && exists $self->{tpl_vars}{$2}) {
        return $1 ? !$self->{tpl_vars}{$2} : $self->{tpl_vars}{$2};
    }

    if ($str =~ /^(!?)(\w+)$/ && exists $self->{tpl_vars}{$2}) {
        return $1 ? !$self->{tpl_vars}{$2} : $self->{tpl_vars}{$2};
    }

    return undef;
}

sub _peval {
    my $self = shift;
    my $str  = shift // '';

    if (index($str, '===') >= 0) {
        $str =~ s/===/==/g;
    }

    my $opt = $self->_micro_optimize($str);
    if (defined $opt) { return ($opt, 0) }

    # Use the persistent $__S hash (maintained by assign/foreach) instead
    # of rebuilding it from tpl_vars on every call
    my $__S = $self->{__S};

    # Check verified sub cache — subs that have succeeded at least once.
    # Skip eval/local $SIG overhead (the biggest per-call cost in loops).
    # no warnings in the compiled sub suppresses uninitialized-value warnings.
    my $vsub = $self->{_verified_sub_cache}{$str};
    if ($vsub) {
        return ($vsub->($__S), 0);
    }

    # Check compiled sub cache — avoids re-parsing the same expression
    my $sub = $self->{_sub_cache}{$str};
    if (!defined $sub) {
        # Compile in main:: first (where user functions live), then Template::Sluz
        $sub = eval "package main; no warnings; sub { my \$__S = \$_[0]; return ($str); }";
        if ($@) {
            $sub = eval "no warnings; sub { my \$__S = \$_[0]; return ($str); }";
        }
        # Cache the result (even undef) so we don't recompile failures
        $self->{_sub_cache}{$str} = $sub;
    }

    my $ret;
    if ($sub) {
        local $SIG{__WARN__} = sub {};
        $ret = eval { $sub->($__S) };
        unless ($@) {
            # Promote to verified cache — skip eval/SIG on future calls
            $self->{_verified_sub_cache}{$str} = $sub;
            delete $self->{_sub_cache}{$str};
            return ($ret, 0);
        }
        # Cached sub failed (e.g. function not in main::) — evict and fall through
        delete $self->{_sub_cache}{$str};
    }

    {
        local $SIG{__WARN__} = sub {};
        $ret = eval "no warnings; return ($str);";
        if ($@) {
            $ret = eval "package main; no warnings; return ($str);";
        }
    }

    if ($@) {
        return (undef, -1);
    }

    return ($ret, 0);
}

# -------------------------------------------------------------------
# Error handling
# -------------------------------------------------------------------

sub _error_out {
    my $self    = shift;
    my $msg     = shift;
    my $err_num = shift;
    croak "Template::Sluz error #$err_num: $msg";
}

sub _get_char_location {
    my $self     = shift;
    my $pos      = shift;
    my $tpl_file = shift // '';

    if ($self->{inc_tpl_file}) { $tpl_file = $self->{inc_tpl_file} }

    # Use display file name and line offset when available (e.g. inline DATA templates)
    my $display_file = exists $self->{tpl_file_display} ? $self->{tpl_file_display} : $tpl_file;
    my $line_offset  = exists $self->{tpl_line_offset}  ? $self->{tpl_line_offset}  : 0;

    # Guard: no file context (e.g. parse_string) — skip _get_tpl_content
    # to avoid trying to open the perl_file_dir directory as a template file
    if (!length $tpl_file) { return (-1, -1, $display_file) }

    my $str = $self->_get_tpl_content($tpl_file);
    if ($pos < 0 || !defined $str) { return (-1, -1, $display_file) }

    my $line = 1;
    my $col  = 0;
    for (my $i = 0; $i < length $str; $i++) {
        $col++;
        if (substr($str, $i, 1) eq "\n") {
            $line++;
            $col = 0;
        }
        if ($pos == $i) { return ($line + $line_offset, $col, $display_file) }
    }

    if ($pos == length $str) { return ($line + $line_offset, $col, $display_file) }
    return (-1, -1, $display_file);
}

sub _extract_include_file {
    my $self = shift;
    my $str  = shift;

    if ($str =~ /\s(file=)(['"].+?['"])/) {
        my $xstr = $self->_convert_vars($2);
        my ($ret) = $self->_peval($xstr);
        $self->{inc_tpl_file} = $ret;
        return $ret;
    }

    if ($str =~ /\s(['"].+?['"])/) {
        my $xstr = $self->_convert_vars($1);
        my ($ret) = $self->_peval($xstr);
        $self->{inc_tpl_file} = $ret;
        return $ret;
    }

    my ($line, $col, $file) = $self->_get_char_location($self->{char_pos}, $self->{tpl_file});
    $self->_error_out("Unable to find a file in include block <code>$str</code> in <code>$file</code> on line #$line", 68493);
}

sub _if_rules_from_tokens {
    my $self = shift;
    my $toks = shift;
    my $num  = scalar @$toks;
    my $nested = 0;
    my @tmp;

    my $tif_tag = $self->{_tag_if};
    my $tifc_tag = $self->{_tag_if_close};
    my $tif_prefix = $self->{open_delim} . 'if';

    for my $i (0 .. $num - 1) {
        my $item = $toks->[$i];
        if (index($item, $tif_prefix) == 0) { $nested++ }
        if ($item eq $tifc_tag) { $nested-- }

        my $yes = 0;
        if ($nested == 1) {
            $yes = $self->is_if_token($item) || 0;
            $yes = 0 if $item eq $tifc_tag;
        }
        $tmp[$i] = $yes;
    }

    $tmp[$num - 1] = 1;

    my @conds;
    for my $i (0 .. $num - 1) {
        if ($tmp[$i]) {
            my $test = $self->is_if_token($toks->[$i]);
            if ($i != $num - 1) { push @conds, $test }
        }
    }

    my $str    = '';
    my @payloads;
    my $first  = 1;
    for my $i (0 .. $num - 1) {
        if ($tmp[$i]) {
            if (!$first) { push @payloads, $str }
            $first = 0;
            $str   = '';
        } else {
            $str .= $toks->[$i];
        }
    }

    if (@conds != @payloads) {
        $self->_error_out("Error parsing if conditions in '$str'", 95320);
    }

    my @ret;
    push @ret, [$conds[$_], $payloads[$_]] for 0 .. $#conds;
    for my $rule (@ret) {
        $rule->[1] = $self->ltrim_one($rule->[1], "\n");
    }
    return @ret;
}

1;

__END__

=head1 NAME

Template::Sluz - A minimalistic Perl templating engine with Smarty-like syntax

=head1 SYNOPSIS

File: C<main.pl>

    use Template::Sluz;

    my $s = Template::Sluz->new();

    $s->assign('name', 'Scott');
    $s->assign('array' => ['one', 'two', 'three']);
    $s->assign('hash'  => { color => 'red', age => 39});

    print $s->fetch('template.stpl');

File: C<template.stpl>

    Hello {$name}
    Nums: {foreach $array as $x}{$x} {/foreach}
    Info: {$hash.color} / {$hash.age}

Output:

    Hello Scott
    Nums: one two three
    Info: red / 39

=head1 METHODS

=over 4

=item B<new>

Create a new Template::Sluz instance.

    my $sluz = Template::Sluz->new();

=item B<assign>

Assign template variables.

    $s->assign('name', 'Scott');
    $s->assign('array' => ['one', 'two', 'three']);
    $s->assign('hash'  => { color => 'red', age => 39});
    $s->assign('nums'  => $array_ref);
    $s->assign('data'  => $hash_ref);

=item B<fetch>

Process a template file and return the output.

    $s->fetch('tpls/page.stpl');

=item B<parse_string>

Process a template string directly without a file.

    $s->parse_string('Hello {$name}');

=item B<set_delimiters>

Change the template delimiters from the default C<{> and C<}> to a custom
open and close character.  Both arguments are required and must be exactly
one character each.  The two characters must be different.

    $s->set_delimiters('<', '>');
    print $s->parse_string('Hello <$name>');

This is useful when template content contains curly braces (e.g., inline
CSS, JavaScript, or JSON) that would otherwise conflict with the default
template syntax.  All subsequent calls to C<fetch>, C<parse_string>, etc.
will use the new delimiters.

=back

=head1 TEMPLATE SYNTAX

=head2 Variables

    {$name}
    {$user.first_name}
    {$items.0}

=head2 Modifiers

    {$name|uc}
    {$name|substr:0,3}
    {$name|lc|ucfirst}
    {$name|escape}

=head2 Default values

    {$name|default:'Unknown'}

=head2 Conditionals

    {if $age > 18}
        Adult
    {elseif $age > 12}
        Teen
    {else}
        Child
    {/if}

=head2 Loops

    {foreach $items as $item}
        {$item}
    {/foreach}

=head2 Includes

    {include file='header.stpl'}
    {include file='header.stpl' title='Home'}

=head2 Literal blocks

    {literal}function foo() { .. } {/literal}

=head2 Comments

    {* This is a comment *}

=head2 Alternate Delimiters

By default the template engine uses C<{> and C<}> as delimiters.  You can
change them to any single open and close character using C<set_delimiters>:

    $s->set_delimiters('<', '>');

    print $s->parse_string('Hello <$name>');

All template syntax works the same way with alternate delimiters:

    <if $age > 18>
        Adult
    <else>
        Not adult
    </if>

    <foreach $items as $item>
        <$item>
    </foreach>

This is useful when your template content contains curly braces that would
conflict with the default delimiters.

=head1 FUNCTIONS AS MODIFIERS

Any Perl built-in or user-defined function can be used as a template
modifier:

    {$name|ucfirst}
    {$items|join:' - '}
    {$text|substr:0,10}

When a function is called as a modifier the template variable is passed first
and then it is followed by the params.

Example: C<{$text|substr:0,10}> would map to the call C<substr($text, 0, 10)>

=head1 SECURITY

Template variables hold untrusted data (form input, database rows, URL
parameters) by default.  The C<{$var}> construct emits the value verbatim,
so a template that renders user data without escaping is vulnerable to
cross-site scripting (XSS).

=head2 Escape modifier

Use the C<|escape> modifier on any variable that may contain
user-supplied data:

    {$comment|escape}

The C<escape> modifier encodes C<&>, C<E<lt>>, C<E<gt>>, C<">, and C<'>
to their HTML entity equivalents.  It can be chained with other modifiers:

    {$comment|trim|escape}
    {$name|uc|escape}

=head2 Auto-escape mode

Enable automatic HTML escaping for all variable output by setting the
C<auto_escape> option on construction:

    my $sluz = Template::Sluz->new(auto_escape => 1);

When enabled, every C<{$var}> expression is automatically HTML-escaped.
Use C<|noescape> to emit raw HTML for a specific variable:

    {$trusted_html|noescape}

Explicit C<|escape> takes priority and prevents double-escaping.
Auto-escape is off by default for backward compatibility.

=head2 Built-in escape functions

=over 4

=item B<escape>

HTML-escape a string for safe output in an HTML context.  Encodes:

    &  => &amp;
    <  => &lt;
    >  => &gt;
    "  => &quot;
    '  => &#x27;

=item B<noescape>

Identity passthrough. Bypasses auto-escaping when C<auto_escape> is
enabled. Does nothing otherwise.

=back

=head1 AUTHOR

Scott Baker - https://www.perturb.org/

=head1 SEE ALSO

L<https://github.com/scottchiefbaker/sluz>

=head1 LICENSE

GPL-3.0-or-later

=cut

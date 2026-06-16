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

our $VERSION = 'v0.9.2';

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
    my $self  = {
        version       => $VERSION,
        tpl_file      => undef,
        inc_tpl_file  => undef,
        debug         => 0,
        tpl_vars      => {},
        parent_tpl    => undef,
        var_prefix    => 'sluz_pfx',
        perl_file     => undef,
        perl_file_dir => undef,
        fetch_called  => 0,
        char_pos      => -1,
        _sub_cache    => {},
    };

    bless $self, $class;
    return $self;
}

sub assign {
    my $self = shift;

    # Accept either a hashref: assign($hash_ref)
    if (@_ == 1 && ref $_[0] eq 'HASH') {
        my $h = shift;
        @{$self->{tpl_vars}}{keys %$h} = values %$h;

    # Or a key-value list: assign(name => 'Scott', age => 42)
    } elsif (@_ % 2 == 0) {
        my %h = @_;
        @{$self->{tpl_vars}}{keys %h} = values %h;
    } else {
        $self->_error_out("Invalid assign. Must be a key/value or hash", 18956);
	}
}

sub fetch {
    my $self     = shift;
    my $tpl_file = shift || '';
    my $parent   = shift;

    if (!$self->{perl_file}) {
        $self->{perl_file}     = $self->_get_perl_file;
        $self->{perl_file_dir} = dirname($self->{perl_file});
    }

    if (!$tpl_file) {
        $tpl_file = $self->_guess_tpl_file($self->{perl_file});
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
    my @tokens = split /({[^}]+})/, $str;
    @tokens = grep { defined && length } @tokens;
    return @tokens;
}

sub is_if_token {
    my $self = shift;
    my $str  = shift // '';
    if ($str eq '{else}') { return 1 }
    if ($str eq '{/if}') { return 1 }
    if ($str =~ /^\{(?:if|elseif)\s+(.+?)\}$/) {
        return $1;
    }
    return '';
}

# -------------------------------------------------------------------
# Private methods
# -------------------------------------------------------------------

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

sub _guess_tpl_file {
    my $self  = shift;
    my $pfile = shift;

    my $base = basename($pfile);
    $base    =~ s/\.(pl|pm)$/.stpl/;

    return "tpls/$base";
}

sub _get_tpl_content {
    my $self     = shift;
    my $tpl_file = shift // '';
    $self->{tpl_file} = $tpl_file;
    my $tf = $tpl_file;

    if ($self->{perl_file_dir}) {
        $tf = $self->{perl_file_dir} . "/$tf";
    }

    if ($tpl_file eq SLUZ_INLINE) {
        my $c = $self->_get_inline_content($self->{perl_file});
        if (defined $c) { return $c }
        return '';
    }

    if ($tf && !-r $tf) {
        $self->_error_out("Unable to load template file <code>$tf</code>", 42280);
    }

    if ($tf) {
        local $/;
        open my $fh, '<', $tf or $self->_error_out("Cannot open <code>$tf</code>: $!", 42280);
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
    return substr($str, $idx + 9);
}

# -------------------------------------------------------------------
# Tokenizer
# -------------------------------------------------------------------

sub _get_blocks {
    my $self = shift;
    my $str  = shift // '';
    my $slen = length $str;
    my $start = 0;
    my $i;
    my @blocks;

    my $z = index($str, '{');
    if ($z < 0) { $z = $slen }

    for ($i = $z; $i < $slen; $i++) {
        my $char      = substr($str, $i, 1);
        my $is_open   = $char eq '{';
        my $is_closed = $char eq '}';

        if (!$is_open && !$is_closed) {
            my $next_open  = index($str, '{', $i);
            if ($next_open < 0) { $next_open = $slen }
            my $next_close = index($str, '}', $i);
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
            if ($chk =~ /\s[\{\}]\s/) { $is_open = 0 }
            if ($next_c eq '*') { $is_comment = 1 }
        }

        if ($is_open && $has_len) {
            push @blocks, [substr($str, $start, $i - $start), $i];
            $start = $i;
        } elsif ($is_closed) {
            my $len   = $i - $start + 1;
            my $block = substr($str, $start, $len);

            if ($block =~ /^\{(if|foreach|literal)\b/) {
                my $open_tag  = $1;
                my $close_tag = "{/$open_tag}";
                for (my $j = $i + 1; $j < length $str; $j++) {
                    if (substr($str, $j, 1) eq '}') {
                        my $tmp = substr($str, $start, $j - $start + 1);
                        my $oc  = () = $tmp =~ /\{\Q$open_tag\E/g;
                        my $cc  = () = $tmp =~ m@\{\/\Q$open_tag\E\}@g;
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
            my $end = $self->find_ending_tag(substr($str, $start), '{*', '*}');
            if (!defined $end) {
                my ($line, $col, $file) = $self->_get_char_location($i, $self->{tpl_file});
                $self->_error_out("Missing closing <code>*}</code> for comment in <code>$file</code> on line #$line", 48724);
            }
            $start += $end + 2;
            $i = $start;
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
    for my $i (0 .. $#blocks) {
        my $bstr     = $blocks[$i][0] // '';
        my $cur_is_if = ($bstr =~ /^\{if\b/ || $bstr =~ /^\{for/);
        if ($prev_is_if) {
            my $should_strip = 1;
            if ($blocks[$i-1][0] =~ /^\{foreach .+?\}(.*)\{\/foreach\}$/s) {
                $should_strip = (substr($1, -1) eq "\n") ? 1 : 0;
            }
            if ($should_strip) {
                $blocks[$i][0] = $self->ltrim_one($bstr, "\n");
            }
        }
        $prev_is_if = $cur_is_if;
    }

    return @blocks;
}

sub _process_blocks {
    my $self   = shift;
    my $blocks = shift;
    my $html   = '';

    for my $x (@$blocks) {
        my $block = $x->[0];
        if (!length $block) { next }
        if (substr($block, 0, 1) eq '{') {
            my $char_pos = $x->[1];
            $html .= $self->_process_block($block, $char_pos);
        } else {
            $html .= $block;
        }
    }

    return $html;
}

sub _process_block {
    my $self     = shift;
    my $str      = shift // '';
    my $char_pos = shift // -1;

    $self->{char_pos} = $char_pos;

    # 1. Variable block {$foo} or {$foo|modifier}
    if (substr($str, 0, 2) eq '{$' && $str =~ /^\{\$([\w|.'";\t :,!@#%^&*?_\/\\\-]+)\}$/) {
        return $self->_variable_block($1);
    }

    # 2. If block {if ...}{/if}
    if (substr($str, 0, 4) eq '{if ' && substr($str, -5) eq '{/if}') {
        return $self->_if_block($str);
    }

    # 3. Foreach block {foreach ...}{/foreach}
    if (substr($str, 0, 9) eq '{foreach ' && $str =~ /^\{foreach (\$\w[\w.]*) as \$(\w+)(?: => \$(\w+))?\}(.+)\{\/foreach\}$/s) {
        return $self->_foreach_block($1, $2, $3, $4);
    }

    # 4. Include block {include ...}
    if (substr($str, 0, 9) eq '{include ') {
        return $self->_include_block($str);
    }

    # 5. Literal block {literal}...{/literal}
    if (substr($str, 0, 9) eq '{literal}' && $str =~ /^\{literal\}(.+)\{\/literal\}$/s) {
        return $1;
    }

    # 6. Expression / function block
    if ($str =~ /^\{(.+)}$/s) {
        return $self->_expression_block($str, $1);
    }

    # 7. Unclosed tag
    if (substr($str, -1) ne '}') {
        my ($line, $col, $file) = $self->_get_char_location($self->{char_pos}, $self->{tpl_file});
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
            return $self->array_dive($key, $self->{tpl_vars}) // '';
        } else {
            if ($is_nothing) {
                return '';
            }
            my $pre = $self->array_dive($key, $self->{tpl_vars}) // '';

            # Split on | not inside double or single quotes (supports chained
            # modifiers like {$x|uc|substr:0,3})
            my $pipe_re = qr/\|(?![^"]*"(?:(?:[^"]*"){2})*[^"]*$)(?![^']*'(?:(?:[^']*'){2})*[^']*$)/;
            for my $m_part (split $pipe_re, $mod) {
                my @x    = split /:/, $m_part, 2;
                my $func = $x[0] // '';
                my $param_str = $x[1] // '';
                my @params = ($pre);

                if (length $param_str) {
                    # Split on commas not inside double or single quotes
                    # (parameter separator in modifier calls like substr:2,2)
                    my $comma_re = qr/,(?=(?:[^"]*"[^"]*")*[^"]*$)(?=(?:[^']*'[^']*')*[^']*$)/;
                    my @new = map {
                        my ($v) = $self->_peval($_);
                        $v;
                    } split $comma_re, $param_str;
                    push @params, @new;
                }

                {
                    no strict 'refs';

					# Priority: main::, Template::Sluz built-ins, then CORE::
                    my $callable = defined &{"main::$func"} || defined &{$func} || defined &{"CORE::$func"};

                    if (!$callable) {
                        my ($line, $col, $file) = $self->_get_char_location($self->{char_pos}, $self->{tpl_file});
                        $self->_error_out("Unknown function call <code>$func</code> in <code>$file</code> on line #$line", 47204);
                    }

                    if (defined &{"main::$func"}) {
                        $pre = eval { &{"main::$func"}(@params) };
                    } elsif (defined &{$func}) {
                        $pre = eval { &{$func}(@params) };
                    } else {
                        $pre = eval { &{"CORE::$func"}(@params) };
                    }
                }

                if ($@) {
                    $self->_error_out("Exception: $@", 79134);
                }
            }

            return $pre;
        }
    }

    my $ret = $self->array_dive($str, $self->{tpl_vars});
    if (ref $ret eq 'ARRAY') { return 'ARRAY' }
    if (ref $ret eq 'HASH')  { return 'HASH' }
    if (defined $ret) { return $ret }
    return '';
}

sub _if_block {
    my $self = shift;
    my $str  = shift;

    my $is_simple = index($str, '{else', 7) < 0;
    my @rules;

    if ($is_simple) {
        $str =~ /\{if (.+?)}(.+)\{\/if\}/s;
        my $cond    = $1 // '';
        my $payload = $2 // '';
        $payload = $self->ltrim_one($payload, "\n");
        @rules = ([$cond, $payload]);
    } else {
        my @toks = $self->get_tokens($str);
        @rules   = $self->_if_rules_from_tokens(\@toks);
    }

    my $ret = '';
    for my $rule (@rules) {
        my $test    = $self->_convert_vars($rule->[0]);
        my $payload = $rule->[1];
        my ($res) = $self->_peval($test);
        if ($res) {
            my @in_blocks = $self->_get_blocks($payload);
            $ret .= $self->_process_blocks(\@in_blocks);
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
    $payload = $self->ltrim_one($payload, "\n");
    my @blocks = $self->_get_blocks($payload);

    my ($src) = $self->_peval($conv_src);

    if (!defined $src) {
        $src = [];
    } elsif (ref $src ne 'ARRAY' && ref $src ne 'HASH') {
        $src = [$src];
    }

    my %save = %{$self->{tpl_vars}};
    my $ret  = '';
    my $idx  = 0;

    my $need_first = index($payload, '__FOREACH_FIRST') >= 0;
    my $need_last  = index($payload, '__FOREACH_LAST')  >= 0;
    my $need_index = index($payload, '__FOREACH_INDEX') >= 0;

    if (ref $src eq 'ARRAY') {
        my $last = $#$src;
        for my $i (0 .. $last) {
            if ($need_first) {
                $self->{tpl_vars}{__FOREACH_FIRST} = ($idx == 0) ? 1 : 0;
            }
            if ($need_last) {
                $self->{tpl_vars}{__FOREACH_LAST} = ($idx == $last) ? 1 : 0;
            }
            if ($need_index) {
                $self->{tpl_vars}{__FOREACH_INDEX} = $idx;
            }
            if (defined $oval) {
                $self->{tpl_vars}{$okey} = $i;
                $self->{tpl_vars}{$oval} = $src->[$i];
            } else {
                $self->{tpl_vars}{$okey} = $src->[$i];
            }
            $ret .= $self->_process_blocks(\@blocks);
            $idx++;
        }
    } elsif (ref $src eq 'HASH') {
        my @keys = sort keys %$src;
        my $last = $#keys;
        for my $i (0 .. $last) {
            my $k = $keys[$i];
            if ($need_first) {
                $self->{tpl_vars}{__FOREACH_FIRST} = ($idx == 0) ? 1 : 0;
            }
            if ($need_last) {
                $self->{tpl_vars}{__FOREACH_LAST} = ($idx == $last) ? 1 : 0;
            }
            if ($need_index) {
                $self->{tpl_vars}{__FOREACH_INDEX} = $idx;
            }
            if (defined $oval) {
                $self->{tpl_vars}{$okey} = $k;
                $self->{tpl_vars}{$oval} = $src->{$k};
            } else {
                $self->{tpl_vars}{$okey} = $src->{$k};
            }
            $ret .= $self->_process_blocks(\@blocks);
            $idx++;
        }
    }

    $self->{tpl_vars} = \%save;
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
    open my $fh, '<', $inc_tpl or $self->_error_out("Cannot open <code>$inc_tpl</code>: $!", 18485);
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

    # Step 1: $var.key -> $__S->{sluz_pfx_var}->{key}
    $str =~ s/(\$\w[\w\.]*)/ $self->_dot_to_bracket_cb($1) /ge;

    # Step 2: $__S->{...}["key"] -> $__S->{...}->{key} (PHP bracket syntax)
    $str =~ s/(\$__S(?:->\{[^}]+\})+)\[(["'])([^\]]+?)\2\]/$1 . '->{' . $3 . '}'/ge;

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
    my $first = substr($str, 0, 1);
    my $last  = substr($str, -1);

    if ($first eq "'" && $last eq "'") {
        my $tmp = substr($str, 1, length($str) - 2);
        if (index($tmp, "'") < 0) { return $tmp }
    }

    if ($first eq '"' && $last eq '"') {
        my $tmp = substr($str, 1, length($str) - 2);
        if (index($tmp, '$') < 0 && index($tmp, '"') < 0) { return $tmp }
    }

    if ($str =~ /^\$__S->\{sluz_pfx_(\w+)\}$/) {
        if (exists $self->{tpl_vars}{$1}) { return $self->{tpl_vars}{$1} }
    }

    if ($str =~ /^!\$__S->\{sluz_pfx_(\w+)\}$/) {
        if (exists $self->{tpl_vars}{$1}) { return !$self->{tpl_vars}{$1} }
    }

    if ($str =~ /^(\w+)$/ && exists $self->{tpl_vars}{$1}) {
        return $self->{tpl_vars}{$1};
    }

    if ($str =~ /^!(\w+)$/ && exists $self->{tpl_vars}{$1}) {
        return !$self->{tpl_vars}{$1};
    }

    return undef;
}

sub _peval {
    my $self = shift;
    my $str  = shift // '';

    $str =~ s/===/==/g;

    my $opt = $self->_micro_optimize($str);
    if (defined $opt) { return ($opt, 0) }

    my $__S = {};
    while (my ($k, $v) = each %{$self->{tpl_vars}}) {
        $__S->{"$self->{var_prefix}_$k"} = $v;
    }

    # Check compiled sub cache — avoids re-parsing the same expression
    my $sub = $self->{_sub_cache}{$str};
    if (!defined $sub) {
        # Compile in main:: first (where user functions live), then Template::Sluz
        $sub = eval "package main; sub { my \$__S = \$_[0]; return ($str); }";
        if ($@) {
            $sub = eval "sub { my \$__S = \$_[0]; return ($str); }";
        }
        # Cache the result (even undef) so we don't recompile failures
        $self->{_sub_cache}{$str} = $sub;
    }

    my $ret;
    if ($sub) {
        local $SIG{__WARN__} = sub {};
        $ret = eval { $sub->($__S) };
        unless ($@) { return ($ret, 0) }
        # Cached sub failed (e.g. function not in main::) — evict and fall through
        delete $self->{_sub_cache}{$str};
    }

    {
        local $SIG{__WARN__} = sub {};
        $ret = eval "return ($str);";
        if ($@) {
            $ret = eval "package main; return ($str);";
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

    my $str = $self->_get_tpl_content($tpl_file);
    if ($pos < 0 || !defined $str) { return (-1, -1, $tpl_file) }

    my $line = 1;
    my $col  = 0;
    for (my $i = 0; $i < length $str; $i++) {
        $col++;
        if (substr($str, $i, 1) eq "\n") {
            $line++;
            $col = 0;
        }
        if ($pos == $i) { return ($line, $col, $tpl_file) }
    }

    if ($pos == length $str) { return ($line, $col, $tpl_file) }
    return (-1, -1, $tpl_file);
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

    for my $i (0 .. $num - 1) {
        my $item = $toks->[$i];
        if ($item =~ /^\{if/) { $nested++ }
        if ($item eq '{/if}') { $nested-- }

        my $yes = 0;
        if ($nested == 1) {
            $yes = $self->is_if_token($item) || 0;
            $yes = 0 if $item eq '{/if}';
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
        $self->_error_out("Error parsing {if} conditions in '$str'", 95320);
    }

    my @ret;
    push @ret, [$conds[$_], $payloads[$_]] for 0 .. $#conds;
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

=head1 FUNCTIONS AS MODIFIERS

Any Perl built-in or user-defined function can be used as a template
modifier:

    {$name|ucfirst}
    {$items|join:' - '}
    {$text|substr:0,10}

When a function is called as a modifier the template variable is passed first
and then it is followed by the params.

Example: C<{$text|substr:0,10}> would map to the call C<substr($text, 0, 10)>

=head1 AUTHOR

Scott Baker - https://www.perturb.org/

=head1 SEE ALSO

L<https://github.com/scottchiefbaker/sluz>

=head1 LICENSE

GPL-3.0-or-later

=cut

package Template::LiquidX::Tidy::impl;

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.01';

use Exporter 'import';
our @EXPORT_OK = qw(_tidy_list _tidy_make_string);
use vars '%defaults';
*defaults = \%Template::LiquidX::Tidy::defaults;

# parser regex
our $PI_START = qr/\{%-?/;
our $PI_END = qr/-?%\}/;
our $LV_START = qr/\{\{/;

# pseudo html indenter
# $html - fragment of html to chunk into lines
# $args - indenter configuration
# $level - current level
# $clevel - current level for debugging
# $stack - additional storage for
#           open_tags /
#           closed_tags /
#           level at return time
# returns a list of [ level, fragment ] pairs and modifies $stack
sub _tidy_html ($html, $args, $level, $clevel, $stack) {
    #print ((" " x $clevel ). "_tidy_html <<$html>> <<$level>>\n");
    my $nl = $html =~ /\n/;
    my @return;
    my $last_line_start = 0;
    my $start_level = $level;
    my $level_change = '';
    while ($html =~ m{(?: (?<cdata> <!\[CDATA\[(.*?)\]\]> )
		        | (?<nl> \n )
			| (?<close2> />)
		        | <(?<close> /)? (?<tag> \w+ )
			) }gsx) {
	#use Data::Dumper; warn Dumper \%+;
	if ($+{cdata}) {
	    # ignore
	}
	elsif (length $+{nl}) {
	    1 while $level_change =~ s/\(\)//;
	    push @return, [ $start_level - ($level_change =~ y/)//), (substr $html, $last_line_start, (pos $html) - $last_line_start),
			    +{ html => 1,
			       ($stack->{open_tags} ? (open => [$stack->{open_tags}->@*]) : ()),
			       ($stack->{closed_tags} ? (closed => [$stack->{closed_tags}->@*]) : ()), } ];
	    $last_line_start = pos($html);
	    $start_level = $level;
	    $level_change = '';
	}
	else {
	    my $tag = $+{tag} ? lc $+{tag} : '';
	    if ($tag =~ /^(?| img | br | link | meta )$/ix) {
		push $stack->{waiting}->@*, $tag;
	    }
	    elsif ($+{close2}) {
		if ($stack->{waiting} && $stack->{waiting}->@*) {
		    pop $stack->{waiting}->@*;
		} else {
		    pop $stack->{open_tags}->@*;
		    $level_change .= ')';
		    $level--;
		    #print ((" " x $clevel ). " close2 <<$level_change>> <<$start_level>>\n");
		}
	    }
	    elsif ($+{close}) {
		if ($stack->{waiting} && $stack->{waiting}->@* && $stack->{waiting}[-1] eq $tag) {
		    pop $stack->{waiting}->@*;
		}
		else {
		    if ($stack->{open_tags} && $stack->{open_tags}[-1] eq $tag) {
			pop $stack->{open_tags}->@*;
		    } else {
			push $stack->{closed_tags}->@*, $tag;
		    }
		    $level_change .= ')';
		    $level--;
		    $stack->{waiting}->@* = ();
		    #print ((" " x $clevel ). " close<<$tag>> <<$level_change>> <<$start_level>>\n");
		}
	    }
	    else {
		push $stack->{open_tags}->@*, $tag;
		$level_change .= '(';
		$level++;
		$stack->{waiting}->@* = ();
		#print ((" " x $clevel ). " open<<$tag>> <<$level_change>> <<$start_level>>\n");
	    }
	}
    }
    if ($last_line_start < length $html) {
	1 while $level_change =~ s/\(\)//;
	push @return, [ $start_level - ($level_change =~ y/)//), (substr $html, $last_line_start),
			+{ html => 1,
			   ($stack->{open_tags} ? (open => [$stack->{open_tags}->@*]) : ()),
			   ($stack->{closed_tags} ? (closed => [$stack->{closed_tags}->@*]) : ()), } ];
    }
    $stack->{level} = $level;
    @return
}

# liquid indenter part
# $obj - an object, subclass of Template::Liquid::Document
# $args - indenter configuration
# $level - current level
# $clevel - current level for debugging
# $stack - additional storage for the html indenter in particular
# returns a list of [ level, fragment ] pairs and modifies $stack
sub _tidy_list ($obj, $args, $level, $clevel, $stack = {}) {
    my @return;
    push @return, [ $level, $obj->{markup}, +{ markup => $obj } ]
	if defined $obj->{markup};

    my $nlevel = $level + 1;
    for my $node ($obj->{nodelist}->@*) {
	my @result;
	if (ref $node) {
	    @result = _tidy_list($node, $args, $nlevel, $clevel + 1, $stack)
	} else {
	    if ($args->{html} // $defaults{html}) {
		@result = _tidy_html($node, $args, $nlevel, $clevel + 1, $stack);
		if ($stack->{level}) {
		    $nlevel = delete $stack->{level};
		}
	    } else {
		@result = [ $nlevel, $node, +{ text => 1 } ]
	    }
	}
	push @return, @result;
    }

    for my $block ($obj->{blocks}->@*) {
	my @result;
	if (ref $block) {
	    @result = _tidy_list($block, $args, $level, $clevel + 1, $stack)
	} else {
	    if ($args->{html} // $defaults{html}) {
		@result = _tidy_html($block, $args, $level, $clevel + 1, $stack)
	    } else {
		@result = [ $level, $block, +{ text => 1 } ]
	    }
	}
	push @return, @result;
    }

    push @return, [ $level, $obj->{markup_2}, +{ markup_2 => $obj } ]
	if defined $obj->{markup_2};

    @return
}

# check if the tag should always be linebroken
# $args->{force_nl} - config option to enable linebreaks
# $args->{force_nl_tags} - whitespace separated string with tags that should be linebroken
sub _force_nl_tags ($args, $content) {
    my $force_nl = $args->{force_nl} // $defaults{force_nl};
    my $force_nl_tags = $args->{force_nl_tags} // $defaults{force_nl_tags};
    return unless $force_nl;
    my @tags = split ' ', $force_nl_tags;
    return 1 unless @tags;
    my $re = join '|', map { "\Q$_" } @tags;
    return $content =~ /$PI_START\s*($re)/;
}

# there is only whitespace before $list[$i] and a linebreak
sub _ws_only_before ($i, @list) {
    while ($i > 0) {
	$i--;
	# found newline, exit search
	if ($list[$i]->[1] =~ /\n\z/) {
	    return 1;
	}
	# found non whitespace
	if ($list[$i]->[1] =~ /\S/) {
	    return;
	}
    }
    return 1;
}

# there is only whitespace after $list[$i] and a processing instruction
sub _ws_only_after_beforepi ($i, @list) {
    while ($i < $#list) {
	$i++;
	# found processing instruction, exit search
	if ($list[$i]->[1] =~ /\{%-?/) {
	    return 1;
	}
	# found non whitespace
	if ($list[$i]->[1] =~ /\S/) {
	    return;
	}
    }
    return;
}

# liquid indenter main routine
# $obj - the root element object, subclass of Template::Liquid::Document
# $args - indenter configuration
# @list - a list of [ level, string fragment ] pairs as produced by _tidy_html / _tidy_list
# returns the indented document string
sub _tidy_make_string ($obj, $args, @list) {
    my $level_correct = -1;
    #my $level_correct = 0;
    #use Data::Dumper;
    #print Dumper \@list;

    my $result = '';

    # config
    my $indent = $args->{indent} // $defaults{indent};
    my $short_if = $args->{short_if} // $defaults{short_if} // 0;
    my $indent_html = $args->{html} // $defaults{html};

    # state
    my $next_nl = 0; # next PI needs to have a newline because we just deleted one

    for my $i (0..$#list) {
	# poke = previous line
	my $poke_content = $i > 0 ? $list[$i - 1]->[1] : '';

	my $it = $list[$i];
	my $content = $it->[1];

	# peek = next line
	my $peek_content = $i < $#list ? $list[$i + 1]->[1] : '';

	my $level = $it->[0] + $level_correct;
	my $peek_level = $i < $#list ? $list[$i + 1]->[0] + $level_correct : $level;

	if ($content =~ /$PI_START/) {
#	    $result .= "\e[34mPI;$level\e[0m";
	    if (($content !~ /\n/ && !_force_nl_tags($args, $content))
		|| $content =~ /$PI_START\s*post_url\s/) {
#		$result .= "\e[35mA\e[0m";
		# we stripped a newline, put it back
		if ($next_nl) {
		    $result .= "\n";
		    $next_nl = 0;
		}

		# there was only whitespace before this tag (which we deleted)
		# -> add indentation
		if (_ws_only_before($i, @list)) {
		    my $m1 = $content;
		    $m1 =~ s/^\s*+/' ' x ($indent * $level)/e
			if $indent_html;
		    #$m1 =~ s/\n\K/' ' x ($indent * ($level + 1))/ge;

		    $result .= $m1;
		    next;
		}

		$result .= $content;
		next;
	    }

	    if ($short_if > 0 && !$next_nl && $content !~ /\n/) {
	    	if ($content =~ /$PI_START\s*(if|unless)\s/ && (length $peek_content) <= $short_if
	    	    && ($i + 2 <= $#list) && $list[$i + 2]->[1] =~ /$PI_START/) {
	    	    $result .= $content;
	    	    next;
	    	}
	    	if ($content =~ /$PI_START\s*end(if|unless)\s/ && (length $poke_content) <= $short_if
	    	    && ($i - 2 >= 0) && $list[$i - 2]->[1] =~ /$PI_START\s*(\Q$1\E\s|elsif\s|else)/) {
	    	    $result .= $content;
	    	    next;
	    	}
	    }

	    my $m1 = $content;
	    # normalise
	    $m1 =~ s/\s*($PI_END)/ $1/;
	    $m1 =~ s/($PI_START)\s*/$1 /;
#	    $result .= "[\e[33m$m1\e[0m]";
#	    $result .= "{\e[32m$poke_content\e[0m}";
	    my $line = 0;

	    # previous line not empty
	    # -> we assume the {% goes to previous line
	    if ( ($poke_content =~ /^(.*)\z/m && length $1)
		 || ($indent_html && $poke_content =~ />\s*\n\z/) ) {
		$m1 =~ s/$PI_START\K\s*/\n/;
	    }
	    # there was only whitespace before this tag (which we deleted)
	    # -> add indentation
	    elsif (_ws_only_before($i, @list) || $next_nl) {
#		$result .= "[\e[33mwsonly before $i; next_nl:$next_nl\e[0m]";
		# if ($indent_html && !$next_nl) {
		#     # we can indent the whole tag
		#     $m1 =~ s/^\s*+/' ' x ($indent * $level)/e;
		#     $line++;
		# } else {
		    my $local_indent = $poke_content =~ /^(.*)\z/m ? length $1 : 0;
		    my $required_indent = $indent * $level;
		    $required_indent -= $local_indent;
		    $required_indent -= length '{% ';
		    if ($required_indent >= 0 && !$next_nl) {
			$m1 =~ s/$PI_START\K\s*/' ' x ($required_indent + 1)/e;
		    } else {
			# force newline after {%
			$m1 =~ s/$PI_START\K\s*/\n/;
		    }
		# }
	    }
	    $next_nl = 0;
	    $m1 =~ s/\n\K(?!["'])[ \t]*/' ' x ($indent * ($level + ($line++ ? 1 : 0)))/ge;
#	    $result .= "[\e[33m$m1\e[0m]";

	    # next line is no processing instruction
	    # -> the %} should go to the next line, indented
	    if ($peek_content !~ /$PI_START/ && $peek_content !~ /^\n/) {
		$m1 =~ s/ ($PI_END)/"\n" . (' ' x ($indent * $peek_level)) . $1/e;
	    }

	    # clean "blank" lines
	    $m1 =~ s/^[ \t]+(?=\n)//gm;

	    # special case for the last command in file:
	    # the %} goes on its own line
	    if ($i == $#list || ($peek_content eq "\n"
				 && !grep { $_->[1] ne "\n" } @list[ ($i + 1) .. $#list ]) ) {
		$m1 =~ s/ ($PI_END)/\n$1/;
	    }

#	    $result .= "\e[35mB\e[0m";
	    $result .= $m1;
	    next;
	}

	# indent content that starts with {{ (liquid variables)
	if ($content =~ /^\s*$LV_START/ && (_ws_only_before($i, @list)) ) {
	    my $m1 = $content;
	    if ($indent_html) {
		$m1 =~ s/^\s*+/' ' x ($indent * $level)/e;
	    }
	    $m1 =~ s/\n\K/' ' x ($indent * ($level + 1))/ge;

	    $result .= $m1;
	    next;
	}

	# indent content that start with < (html tag)
	if ($indent_html && $content =~ /^\s*<[^!]/ && ($poke_content =~ /\n\z/) ) {
	    my $m1 = $content;
	    $m1 =~ s/^\s*+/' ' x ($indent * $level)/e;

	    # next line is a processing instruction
	    # -> delete the last newline if the line ends with > (html tag end)
	    if (_ws_only_after_beforepi($i, @list)) {
		$next_nl = $m1 =~ s/>\K\s*\n\z//;
	    }

	    $result .= $m1;
	    next;
	}

	# next line is a processing instruction
	# -> delete the last newline if the line ends with > (html tag end)
	if ($indent_html && _ws_only_after_beforepi($i, @list)) {
	    my $m1 = $content;
	    if ($m1 =~ s/(?<!-)>\K\s*\n\z//) {
		$result .= $m1;
		$next_nl = 1;
		next;
	    }

	    # ignore plain newline if it follows a processing instruction
	    if ($m1 eq "\n" && $poke_content =~ /$PI_START/ && $poke_content !~ /$PI_START\s*capture/) {
		$next_nl = 1;
		next;
	    }
	}

	# ignore white space in front of liquid variables and liquid processing instructions
	if ($indent_html
	    && $content =~ /^[ \t]+$/
	    && ($peek_content =~ /$LV_START/ || $peek_content =~ /$PI_START/)
	    && $poke_content =~ /\n\z/) {

	    # skip this indentation, will be corrected when the next token is processed
	    next;
	}

	# indent html text
	if ($indent_html
	    && !($it->[2] && $it->[2]{open} && $it->[2]{open}->@* && $it->[2]{open}[-1] eq 'script')) {
	    my $m1 = $content;
	    if ($poke_content =~ /\n\z/) {
		$m1 =~ s/^[ \t]++/' ' x ($indent * $level)/e;
	    }
	    # clean "blank" lines
	    $m1 =~ s/^[ \t]+(?=\n)//gm;

	    $result .= $m1;
	    next;
	}

	# fallback: don't touch the content, add as is
	$result .= $content;
	next;
    }
    $result
}

1;

=head1 NAME

Template::LiquidX::Tidy::impl - The implementation of Template::LiquidX::Tidy

=head1 SYNOPSIS

For internal usage.

=head1 METHODS

=head2 _tidy_list($obj, $args, $level, $clevel, $stack = {})

The Liquid indenter part

=over 4

=item B<$obj>

an object, subclass of Template::Liquid::Document

=item B<$args>

The indenter configuration

=back

returns a list of [ level, fragment ] pairs and modifies C<$stack>

=head2 _tidy_make_string($obj, $args, @list)

Liquid indenter main routine. This does the grunt work of joining
together all the tuples returned by the calls to _tidy_list

=over 4

=item B<$obj>

an object, subclass of Template::Liquid::Document

=item B<$args>

The indenter configuration

=back

returns the indented document string

=cut


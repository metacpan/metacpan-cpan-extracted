package Mojo::PrettyTidy;

# ABSTRACT: Format Mojolicious .html.ep templates

use v5.40.0;
use feature 'signatures';

use common::sense;
use Cwd;
use File::Basename;
use File::Path qw(remove_tree make_path);
use File::Spec;
use JavaScript::Beautifier qw/js_beautify/;

our $VERSION = '0.02';

sub new ( $class, %args ) {
  my $self = bless {
          attributes   => defined $args{attributes}   ? $args{attributes} : 1,
          columns      => defined $args{columns}      ? $args{columns}    : 80,
          indent_width => defined $args{indent_width} ? $args{indent_width} : 2,
          javascript   => defined $args{javascript}   ? $args{javascript}   : 1,
          perl         => defined $args{perl}         ? $args{perl}         : 1,
          tab_width    => defined $args{tab_width}    ? $args{tab_width}    : 2,
  }, $class;

  return $self;
}

sub check ( $self, $text ) {
  return $self->tidy( $text ) eq $text ? 1 : 0;
}

sub _chunk ( $self, $text ) {
  my @chunks;

  $text = $self->_ep_early_breakpoints( $text );

  for my $line ( split /\n/, $text, -1 ) {
    if ( $line =~ /^\s*$/ ) {
      push @chunks, {kind => 'blank', text => ''};
      next;
    }

    if ( $line =~ /^\s*<script\b/i || $line =~ /^\s*<\/script>/i ) {
      push @chunks, {kind => 'script', text => $line};
      next;
    }

    my $ep = $self->_ep_control( $line );

    if ( defined $ep ) {
      push @chunks, {kind => 'ep_control', text => $line, ep => $ep};
      next;
    }

    push @chunks, {kind => 'html', text => $line};
  }

  return @chunks;
}

sub _cleanup_artifacts ( $self ) {
  my @dirs = (
               File::Spec->catdir( 'tmp', 'perltidy' ),
               File::Spec->catdir( 'tmp', 'debug' ),
               File::Spec->catdir( 'tmp', 'error' ),
               File::Spec->catdir( 'tmp', 'javascript' ),
               File::Spec->catdir( 'tmp', 'prettytidy' ), );

  for my $dir ( @dirs ) {
    next unless -e $dir;

    remove_tree( $dir, {error => \my $err} );

    if ( @$err ) {
      for my $diag ( @$err ) {
        my ( $path, $message ) = %$diag;
        warn "Could not remove $path: $message\n";
      }
    }
  }

  my @legacy_files = ( File::Spec->catfile( 'tmp', 'pt.raw-perltidy.out' ), );

  for my $file ( @legacy_files ) {
    next unless -e $file;

    unlink $file
        or warn "Could not remove $file: $!";
  }

  return;
}

sub _cols_attrib_split_style_declarations ( $style ) {
  return () unless defined $style && length $style;

  my @parts = split /;/, $style;
  @parts = map {
    my $x = $_;
    $x =~ s/^\s+//;
    $x =~ s/\s+$//;
    $x =~ s/\s+/ /g;
    $x;
  } @parts;

  @parts = grep { length $_ } @parts;
  @parts = map  { $_ . ';' } @parts;

  return @parts;
}

sub _cols_line_exceeds_columns ( $self, $line ) {
  return 0 unless defined $self->{columns} && $self->{columns};
  return length( $line ) > $self->{columns} ? 1 : 0;
}

sub _cols_style_attributes ( $self, $text ) {
  return ''    unless defined $text            && length $text;
  return $text unless defined $self->{columns} && $self->{columns};

  my @out;

  for my $line ( split /\n/, $text, -1 ) {
    if ( !$self->_cols_line_exceeds_columns( $line ) ) {
      push @out, $line;
      next;
    }

    if ( $line !~ /^([ \t]*)(.*?\bstyle=")([^"]*)(".*)\z/ ) {
      push @out, $line;
      next;
    }

    my ( $indent, $before, $style, $after ) = ( $1, $2, $3, $4 );
    my @decls = _cols_attrib_split_style_declarations( $style );

    if ( @decls <= 1 ) {
      push @out, $line;
      next;
    }

    push @out,
        $self->_cols_wrap_style_declarations( $indent, $before, \@decls,
                                              $after, );
  }

  return join "\n", @out;
}

sub _cols_wrap_style_declarations ( $self, $indent, $before, $decls, $after ) {
  my $cols = $self->{columns} || 0;

  my @decls = @$decls;
  return ( $indent . $before . join( ' ', @decls ) . $after ) unless $cols > 0;
  return ( $indent . $before . $after )                       unless @decls;

  my $first_prefix = $indent . $before;

  my $cont_prefix;
  if ( $before =~ /^(.style=")\z/ ) {
    $cont_prefix = $indent . $1 . ( ' ' x $self->{indent_width} );
  } else {
    $cont_prefix = ' ' x length( $first_prefix );
  }

  my @lines;
  my @cur;
  my $cur_prefix = $first_prefix;

  while ( @decls ) {
    my $decl = shift @decls;

    my @candidate_decls = ( @cur, $decl );
    my $candidate =
        $cur_prefix . join( ' ', @candidate_decls ) . ( @decls ? '' : $after );

    if ( length( $candidate ) <= $cols ) {
      @cur = @candidate_decls;
      next;
    }

    if ( @cur ) {
      push @lines, [ $cur_prefix, [@cur] ];
      @cur        = ( $decl );
      $cur_prefix = $cont_prefix;
      next;
    }

    push @lines, [ $cur_prefix, [$decl] ];
    @cur        = ();
    $cur_prefix = $cont_prefix;
  }

  push @lines, [ $cur_prefix, [@cur] ] if @cur;

  if ( @lines >= 2 ) {
    my $prev = $lines[-2];
    my $last = $lines[-1];

    my @prev_decls = @{$prev->[1]};
    my @last_decls = @{$last->[1]};

    if ( @prev_decls > 1 ) {
      my $moved          = pop @prev_decls;
      my @new_last_decls = ( $moved, @last_decls );

      my $new_prev_text = $prev->[0] . join( ' ', @prev_decls );
      my $new_last_text = $last->[0] . join( ' ', @new_last_decls ) . $after;

      my $old_prev_text = $prev->[0] . join( ' ', @{$prev->[1]} );
      my $old_last_text = $last->[0] . join( ' ', @{$last->[1]} ) . $after;

      if (    length( $new_prev_text ) <= $cols
           && length( $new_last_text ) <= $cols
           && length( $old_last_text ) < int( length( $old_prev_text ) / 3 ) )
      {
        $prev->[1] = \@prev_decls;
        $last->[1] = \@new_last_decls;
      }
    }
  }

  my @out;
  for my $i ( 0 .. $#lines ) {
    my ( $prefix, $chunks ) = @{$lines[$i]};
    my $text = $prefix . join( ' ', @$chunks );
    $text .= $after if $i == $#lines;
    push @out, $text;
  }

  return @out;
}

sub _ep_early_breakpoints ( $self, $text ) {
  return '' unless defined $text && length $text;

  # Protect quoted attribute values containing HTML-ish fragments so the
  # breakpoint rules do not split tags inside attributes, e.g.
  # data-bs-title="<b>Regex:</b><code>...</code>"
  my @protected_attr_values;

  $text =~ s{
    =
    (
        "[^"]*<[^"]*"
      | '[^']*<[^']*'
    )
  }{
    my $value = $1;
    push @protected_attr_values, $value;
    '=' . '__PT_ATTRVAL_' . $#protected_attr_values . '__';
  }gex;

  # HTML comments are their own visible units. Multi-line comment bodies are
  # otherwise left alone.
  $text =~ s{\n*(<!--)}{\n$1}g;
  $text =~ s{(-->)\n*}{$1\n}g;

  # Split common block-ish tags that flattening glued together.
  my @document_tags = qw(html head body title meta link);
  my @form_tags     = qw(form label input select option button);
  my @heading_tags  = qw(h1 h2 h3 h4 h5 h6);
  my @inline_tags   = qw(i span b);
  my @layout_tags   = qw(div main pre section article svg);
  my @list_tags     = qw(ul ol li);
  my @media_tags    = qw(picture source img);
  my @script_tags   = qw(script style);
  my @svg_tags      = qw(svg path);
  my @table_tags    = qw(table thead tbody tr td th);

  my $break_tag = join '|',
      @document_tags,
      @form_tags,
      @heading_tags,
      @inline_tags,
      @layout_tags,
      @list_tags,
      @media_tags,
      @script_tags,
      @svg_tags,
      @table_tags,;

  my $b_body = qr{(?:(?:<%[\s\S]*?%>)|[^<\n])*};

  # Headings are block-ish even when glued to surrounding text.
  $text =~ s{(<div\b[^>]*>)[ \t]*(?=<h[1-6]\b)}{$1\n}gi;
  $text =~ s{(</h[1-6]>)[ \t]*(?=\S)}{$1\n}gi;

  # Table cells containing code-ish payload read better as a small block.
  $text =~ s{
    (<t[dh]\b[^>]*>)[ \t]*(<code\b[^>]*>.*?</code>)[ \t]*(</t[dh]>)}
    {$1\n$2\n$3}gis;
  $text =~ s{
    (<t[dh]\b[^>]*>)[ \t]*(<pre\b[^>]*>.*?</pre>)[ \t]*(</t[dh]>)}
    {$1\n$2\n$3}gis;

  # pre/code nesting should be readable as a block.
  $text =~ s{(<pre\b[^>]*>)[ \t]*(<code\b[^>]*>)}{$1\n$2}gi;
  $text =~ s{(</code>)[ \t]*(</pre>)}{$1\n$2}gi;

  # Code-ish block payload inside table cells should not keep </td>/</th> glued.
  $text =~ s{(</(?:pre|code)>)[ \t\r\n]*(</t[dh]>)}{$1\n$2}gi;

  # Closing tag before table-cell close should break away.
  # This avoids <pre>...</pre></td>, <code>...</code></td>, etc.
  $text =~ s{(</[A-Za-z][A-Za-z0-9:_-]*>)[ \t]*(</t[dh]>)}{$1\n$2}g;

  # In pre/code blocks, put simple EP output payload on its own line.
  $text =~ s{
    (<pre\b[^>]*>\s*<code\b[^>]*>)
    [ \t]*
    (<%=[\s\S]*?%>)
    [ \t]*
    (</code>\s*</pre>)}
    {$1\n$2\n$3}gxi;

  # Div text payload should not stay glued to the opening <div>.
  $text =~ s{(<div\b[^>]*>)[ \t]*(?=[^<\s])}{$1\n}gi;

  # Text payload glued to an anchor should break before the anchor.
  $text =~ s{([^\s>])(?=<a\b)}{$1\n}gi;

  # Div payload containing inline/nested markup
  # should not stay glued to the opening <div>.
  $text =~ s{(<div\b[^>]*>)[ \t]*(?=<(?:i|svg|span|b|a)\b)}{$1\n}gi;

  # Div close should not stay glued to text payload.
  $text =~ s{([^\s>])</div>}{$1\n</div>}gi;

  # Input after label text, e.g. <label>Search:<input ...>
  $text =~ s{(<label\b[^>]*>[^<\n]*?)(?=<input\b)}{$1\n}gi;

  # Labels with inline text followed by a form control later on the same line
  $text =~
      s{(<label\b[^>]*>)[ \t]*([^<\n]+)(?=<(?:input|select|textarea|button)\b)}
{$1\n$2\n}gi;

  # Input after another input/tag boundary is already handled elsewhere.
  $text =~ s{(?<!-)>[ \t]*(?=<input\b)}{>\n}gi;

  # Selects are often glued to label text, e.g. <label>Mode:<select ...>.
  $text =~ s{(<label\b[^>]*>[^<\n]*?)(?=<select\b)}{$1\n}gi;

  # Do not split Perl method arrows like app->log->format.
  $text =~ s{(?<!-)>[ \t]*(?=<(?:$break_tag)\b)}{>\n}gi;
  my @perly_words =
      qw(if elsif else unless for foreach while my our state return end given when);
  my $perly = join '|', @perly_words;

  $text =~ s{(?<!-)>[ \t]*(?=%\s*(?:$perly)\b)}{>\n}g;
  $text =~ s{(</script>)[ \t]*(?=<)}{$1\n}gi;
  $text =~ s{(</style>)[ \t]*(?=<)}{$1\n}gi;

  # Media containers: solo media tags should not stay glued to </picture>.
  $text =~ s{(?<!-)>[ \t]*(?=</picture>)}{>\n}gi;
  $text =~ s{(</picture>)[ \t]*(</a>)}{$1\n$2}gi;

  # SVG/icon payload should not stay glued to its closing wrappers.
  $text =~ s{(?<!-)>[ \t]*(?=</(?:svg|i)>)}{>\n}gi;
  $text =~ s{(</svg>)[ \t]*(</i>)}{$1\n$2}gi;

  # Closing tag glued to another tag or EP marker.
  $text =~ s{(</[A-Za-z][A-Za-z0-9:_-]*>)[ \t]*(?=<|%)}{$1\n}g;

  # Keep terse inline table-cell content joined, but not code-ish blocks.
  $text =~
s{(</(?!pre\b|code\b|span\b)[A-Za-z][A-Za-z0-9:_-]*>)\n(</t[dh]>)}{$1$2}gi;
  $text =~ s{(</span>)[ \t]*(</t[dh]>)}{$1\n$2}gi;

  # Code-ish cell payload closers must stay broken away from </td>/</th>.
  $text =~ s{(</(?:pre|code)>)[ \t]*(</t[dh]>)}{$1\n$2}gi;

  # If a table cell contains code payload, put the cell closer on its own line.
  $text =~ s{(</code>)[ \t]*(</td>)}{$1\n$2}gi;
  $text =~ s{(</code>)[ \t]*(</th>)}{$1\n$2}gi;

  # EP statement immediately followed by another EP line.
  $text =~ s/\;%/;\n%/g;

  # EP comment glued to another EP line.
  $text =~ s{(%\s*\#[^\n]*?)(?=%\s*)}{$1\n}gx;

  # EP opener/transition glued to preceding payload.
  $text =~ s{(?<!\n)(?=%\s*(?:if|unless|for|foreach|while)\b)}{\n}g;

  # EP opener/transition glued to trailing payload.
  $text =~ s{
(%\s*(?:\}\s*)?(?:if|elsif|else|unless|for|foreach|while)\b[^\n]*?(?<!@)\{)(?=\S)
}
{$1\n}gx;

  # EP begin glued to trailing template payload.
  $text =~ s{ (%[=\s][^\n]*?\bbegin) (?=<[A-Za-z]) }{$1\n}gx;

  # closing end when glued to HTML
  $text =~ s{(?<!\n)(?=%\s*end\b)}{\n}g;
  $text =~ s{(%\s*end\b)(?=<[A-Za-z])}{$1\n}g;

  # EP closer glued to trailing payload. This intentionally catches both tags
  # and text payload such as `% }&nbsp; ...` so the closer remains classifiable.
  $text =~ s{(%\s*\})(?=\S)}{$1\n}gx;

  # Before EP expression-output lines:
  $text =~ s{ (?<![\n<]) (?=%=) }{\n}gx;

  # EP expression/helper output glued to an HTML closing tag.
  $text =~ s{(^\s*%=\s*[^\n]*?)(?=</[A-Za-z][A-Za-z0-9:_-]*>)}{$1\n}gmx;

  # Before EP control/statement lines.
  $text =~ s{
    (?<!\n)
    (?=%\s*(?:if|elsif|else|unless|for|foreach|while|my|our|state|return)\b)
  }{\n}gx;

  # Before standalone EP comments only. Do not touch inline trailing # comments.
  $text =~ s{(?<!\n)(?=%\s*\#\s)}{\n}g;

  # Before EP close/transition lines.
  $text =~ s/(?<!\n)(?=%\s*\})/\n/g;

  # EP statement/comment glued to an opening HTML tag.
  $text =~ s{(^%\s*[^\n]*?;)(?=<!?[A-Za-z])}{$1\n}gmx;
  $text =~ s{(%\s*(?:my|our|state|return)\b[^\n]*?;)(?=<[A-Za-z])}{$1\n\n}gx;
  $text =~ s{(%\s*\#[^\n]*?;)(?=<[A-Za-z])}{$1\n\n}gx;

  $text = $self->_js_prebake_scripts( $text );

  for my $i ( 0 .. $#protected_attr_values ) {
    my $token = '__PT_ATTRVAL_' . $i . '__';
    $text =~ s{\Q$token\E}{$protected_attr_values[$i]}g;
  }

  return $text;
}

sub _ep_control ( $self, $line ) {
  return undef unless defined $line && length $line;

  my $x = $line;
  $x =~ s/^\s+//;
  $x =~ s/\s+$//;

  my $is_output_begin = $x =~ /^%=\s+.*\bbegin\s*\z/;

  return undef if $x =~ /^%=/ && !$is_output_begin;

  if ( $is_output_begin ) {
    $x =~ s/^%=\s+// or return undef;
  } else {
    $x =~ s/^%\s+// or return undef;
  }

  return 'comment' if $x =~ /\A#/;
  return 'closer'  if $x =~ /\A}\s*\z/;

  return 'transition' if $x =~ /\A}\s*(?:else|elsif)\b.*\{\s*\z/;
  return 'transition' if $x =~ /\A(?:else|elsif)\b.*\{\s*\z/;

  return 'opener'
      if $x =~ /\A(?:if|for|foreach|while|unless)\b.*\{\s*\z/
      && $x !~ /\@\{\s*\z/;

  #   return 'opener' if $x =~ /\A[^\n]*\}\)\s*\{\s*\z/;

  return 'begin'     if $x =~ /\bbegin\s*\z/;
  return 'end'       if $x =~ /\Aend\b\s*\z/;
  return 'statement' if $x =~ /;\s*(?:#.*)?\z/;

  # Fallback: a full-line EP marker is still Perl code, even when it is
  # a continuation like:
  #   % for my $line (@{
  #   % }) {
  return 'statement';
}

sub _ep_postfix_indentation ( $self, $text ) {
  return '' unless defined $text && length $text;

  # EP control-block payload indentation.
  #
  # Handles:
  #   % if (...) {
  #       <payload>
  #   % }
  #
  # Non-% payload lines inside EP control blocks get one extra visual indent.
  # % lines keep their perltidy-derived indentation.
  my @out;
  my $level     = 0;
  my $in_script = 0;
  my $indent    = ' ' x $self->{indent_width};

  for my $line ( split /\n/, $text, -1 ) {
    my $kind = $self->_ep_control( $line );

    if ( defined $kind && ( $kind eq 'closer' || $kind eq 'transition' ) ) {
      $level-- if $level > 0;
    }

    my $target         = $level > 0 ? $indent x $level         : '';
    my $payload_target = $level > 0 ? $indent x ( $level + 1 ) : '';

    if ( $line =~ /^\s*<script\b/i ) {
      if ( length $target ) {
        $line =~ s/^\s*/$target/;
      }

      $in_script = 1;
      push @out, $line;
      next;
    }

    if ( $in_script ) {
      if ( $line =~ m{^\s*</script>}i ) {
        if ( length $target ) {
          $line =~ s/^\s*/$target/;
        }

        $in_script = 0;
        push @out, $line;
        next;
      }

      if ( length $line ) {
        $line = $target . $indent . $line;
      }

      push @out, $line;
      next;
    }

    # EP/code lines keep their own perltidy-derived indentation.
    # Do not apply payload indentation to them.
    if ( $line =~ /^\s*%/ ) {
      push @out, $line;

      if ( defined $kind && ( $kind eq 'opener' || $kind eq 'transition' ) ) {
        $level++;
      }

      next;
    }

    # Non-EP payload lines inside EP blocks get one extra visual indent.
    if ( $level > 0 && length $line ) {
      my $leading = '';

      if ( $line =~ /^(\s*)/ ) {
        $leading = $1;
      }

      if ( length( $leading ) < length( $payload_target ) ) {
        $line =~ s/^\s*/$payload_target/;
      }
    }

    push @out, $line;

    if ( defined $kind && ( $kind eq 'opener' || $kind eq 'transition' ) ) {
      $level++;
    }
  }

  $text = join "\n", @out;

  # Mojo begin/end helper indentation.
  #
  # Handles:
  #   % my $cb = begin
  #       <payload>
  #   % end
  #
  # existing _reemit_begin_blocks body here
  my @out;
  my $level  = 0;
  my $indent = ' ' x $self->{indent_width};

  for my $line ( split /\n/, $text, -1 ) {
    my $kind = $self->_ep_control( $line );

    if ( defined $kind && $kind eq 'end' ) {
      $level-- if $level > 0;
    }

    if ( $level > 0 && length $line ) {
      my $target  = $indent x $level;
      my $leading = '';

      if ( $line =~ /^(\s*)/ ) {
        $leading = $1;
      }

      if ( length( $leading ) < length( $target ) ) {
        $line =~ s/^\s*/$target/;
      }
    }

    push @out, $line;

    if ( defined $kind && $kind eq 'begin' ) {
      $level++;
    }
  }

  return join "\n", @out;
}

sub ep_source_file ( $self, $file ) {
  $self->{ep_source_file} = $file if defined $file && length $file;
  return $self;
}

sub _flatten ( $self, $text ) {
  return '' unless defined $text && length $text;

  $text = $self->_html_prebake_text_payload_newlines( $text );
  $text =~ s/\r\n?/\n/g;

  my @lines = split /\n/, $text;

  for my $line ( @lines ) {
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
  }

  return join '', grep {length} @lines;
}

sub _html_attrib_option ( $self, $text ) {
  return '' unless defined $text && length $text;

  my $indent = ' ' x $self->{indent_width};

  $text =~ s{
  ^([ \t]*)
  (<option\b)
  (
    (?:
      "[^"]*"
      |
      '[^']*'
      |
      <%=[\s\S]*?%>
      |
      [^'">\n]
    )*
  )
  >
  (
    <%=[\s\S]*?%>
    |
    [^<\n]*
  )
  </option>
}{
    do {
      my ( $leading, $open, $attrs, $body ) = ( $1, $2, $3, $4 );

      $attrs =~ s/^\s+//;
      $attrs =~ s/\s+\z//;
      $body  =~ s/^\s+//;
      $body  =~ s/\s+\z//;

      my @parts = $attrs =~ /(
        <%=[\s\S]*?%>
        |
        [^\s=<]+(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^\s"'>]+))?
      )/gx;

      if ( @parts <= 1 ) {
        "$leading$open $attrs>$body</option>";
      }
      else {
        my $first = shift @parts;
        $first =~ s/^\s+//;
        $first =~ s/\s+\z//;

        my $out = "$leading$open $first";

        for my $part ( @parts ) {
          $part =~ s/^\s+//;
          $part =~ s/\s+\z//;

          $out .= "\n$leading$indent$part";
        }

        $out .= ">$body";
        $out .= "\n$leading</option>";

        $out;
      }
    }
  }gexim;

  return $text;
}

sub _html_attrib_paired ( $self, $text ) {
  return '' unless defined $text && length $text;

  my $indent = ' ' x $self->{indent_width};
  my @tags   = qw(button a);
  my $tag    = join '|', @tags;

  $text =~ s{
    ^([ \t]*)
    (<($tag)\b)
    ((?:"[^"]*"|'[^']*'|[^'">])*)
    >
    ([\s\S]*?)
    </\3>
  }{
    do {
      my ( $leading, $open, $tag_name, $attrs, $body ) =
          ( $1, $2, $3, $4, $5 );

      my $attr_indent    = $leading . ( $indent x 2 );
      my $payload_indent = $leading . $indent;

      $attrs =~ s/\s+/ /g;
      $attrs =~ s/^\s+//;
      $attrs =~ s/\s+\z//;

      # Repair glued attributes like:
      #   aria-controls="navbarNav"aria-expanded="false"
      $attrs =~ s/("[^"]*")(?=[A-Za-z_:][A-Za-z0-9_:.:-]*=)/$1 /g;
      $attrs =~ s/('[^']*')(?=[A-Za-z_:][A-Za-z0-9_:.:-]*=)/$1 /g;

      $body =~ s/^\s+//;
      $body =~ s/\s+\z//;

      if ( $attrs !~ /\S/ ) {
        if ( length $body ) {
          "$leading$open>\n$payload_indent$body\n$leading</$tag_name>";
        }
        else {
          "$leading$open></$tag_name>";
        }
      }
      else {
        my @attrs = $attrs =~ /([^\s=]+(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^\s"'>]+))?)/g;

        if ( @attrs <= 1 && $body !~ /\S/ ) {
          "$leading$open $attrs></$tag_name>";
        }
        else {
          my $first = shift @attrs;
          $first =~ s/^\s+//;
          $first =~ s/\s+\z//;

          my $out = "$leading$open $first";

          for my $attr ( @attrs ) {
            $attr =~ s/^\s+//;
            $attr =~ s/\s+\z//;

            $out .= "\n$attr_indent$attr";
          }

          $out .= ">";

          if ( length $body ) {
            $out .= "\n$payload_indent$body";
          }

          $out .= "\n$leading</$tag_name>";

          $out;
        }
      }
    }
  }gexim;

  return $text;
}

sub _html_attrib_container ( $self, $text ) {
  return '' unless defined $text && length $text;

  my $indent      = ' ' x $self->{indent_width};
  my $attr_indent = $indent x 2;

  my @tags = qw(div form main select picture svg tr);

  my $tag = join '|', @tags;

  $text =~ s{
    ^([ \t]*)
    (<(?:$tag)\b)
    ((?:"[^"]*"|'[^']*'|[^'">\n])*)
    (>)
  }{
    do {
      my ( $leading, $open, $attrs, $close ) = ( $1, $2, $3, $4 );

      if ( $attrs !~ /\S/ ) {
        "$leading$open$attrs$close";
      }
      else {
        my @attrs = $attrs =~ /([^\s=]+(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^\s"'>]+))?)/g;

        if ( @attrs <= 1 ) {
          "$leading$open$attrs$close";
        }
        else {
          my $first = shift @attrs;
          $first =~ s/^\s+//;
          $first =~ s/\s+\z//;

          my $cont_indent = $leading . $attr_indent;
          my $out = "$leading$open $first";

          for my $i ( 0 .. $#attrs ) {
            my $attr = $attrs[$i];

            $attr =~ s/^\s+//;
            $attr =~ s/\s+\z//;

            if ( $i == $#attrs ) {
              $out .= "\n$cont_indent$attr$close";
            }
            else {
              $out .= "\n$cont_indent$attr";
            }
          }

          $out;
        }
      }
    }
  }gexim;

  return $text;
}

sub _html_attrib_solo ( $self, $text ) {
  return '' unless defined $text && length $text;

  my $indent   = ' ' x $self->{indent_width};
  my @tags     = qw(img input path source);
  my @closures = qw(label form div td th li);
  my $tag      = join '|', @tags;
  my $closures = join '|', @closures;

  $text =~ s{
    ^([ \t]*)
    (<($tag)\b)
    ((?:"[^"]*"|'[^']*'|[^'">\n])*)
    (>)
  }{
    do {
      my ( $leading, $open, $tag_name, $attrs, $close ) =
          ( $1, $2, $3, $4, $5 );

      if ( $attrs !~ /\S/ ) {
        "$leading$open$attrs$close";
      }
      else {
        my @attrs = $attrs =~ /([^\s=]+(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^\s"'>]+))?)/g;

        if ( @attrs <= 1 ) {
          "$leading$open$attrs$close";
        }
        else {
          my $first = shift @attrs;
          $first =~ s/^\s+//;
          $first =~ s/\s+\z//;

          my $cont_indent = $leading . ( $indent x 2 );
          my $out = "$leading$open $first";

          for my $i ( 0 .. $#attrs ) {
            my $attr = $attrs[$i];

            $attr =~ s/^\s+//;
            $attr =~ s/\s+\z//;

            if ( $i == $#attrs ) {
              $out .= "\n$cont_indent$attr$close";
            }
            else {
              $out .= "\n$cont_indent$attr";
            }
          }

          $out;
        }
      }
    }
  }gexim;

  # If a multiline solo tag is glued to a closing container tag, split it.
  # The closer belongs one indent level above the solo tag.
  $text =~ s{
    ^([ \t]*)
    ([^<\n]*>)
    [ \t]*
    (</(?:$closures)>)
  }{
    do {
      my ( $leading, $tag_end, $closing ) = ( $1, $2, $3 );
      my $close_indent = $leading;

      if ( length( $close_indent ) >= length( $indent ) ) {
        substr( $close_indent, -length( $indent ) ) = '';
      }

      "$leading$tag_end\n$close_indent$closing";
    }
  }gexim;

  return $text;
}

sub _html_baseline_indentation ( $self, $text ) {
  return '' unless defined $text && length $text;

  my @out;
  my $html_level       = 0;
  my $ep_level         = 0;
  my $ep_html_level    = 0;
  my $in_codeish       = 0;
  my $codeish_close_re = undef;
  my $codeish_target   = '';
  my $indent           = ' ' x $self->{indent_width};

  my $block = qr{
  (?:
    form|label|select|option|button|input
    |div|main|code|picture|source|img|pre
    |i|svg|path
    |table|thead|tbody|tfoot|tr|td|th|p
    |ul|ol|li|a
    |section|article
  )
}x;

  my $void = qr{
  (?:
    input|meta|link
    |img|br|hr
    |h1|h2|h3|h4|h5|h6
    |source|path
  )
}x;

  for my $line ( split /\n/, $text, -1 ) {
    my $kind = $self->_ep_control( $line );

    if ( defined $kind && ( $kind eq 'closer' || $kind eq 'transition' ) ) {
      $ep_level-- if $ep_level > 0;

      if ( $ep_level == 0 ) {
        $ep_html_level = 0;
      }
    }

    if ( $line =~ /^\s*%/ ) {
      push @out, $line;

      if ( defined $kind && ( $kind eq 'opener' || $kind eq 'transition' ) ) {
        $ep_level++;
      }

      next;
    }

    my $in_ep_payload = $ep_level > 0 ? 1 : 0;

    if ( $in_codeish ) {
      my $leading = '';

      if ( $line =~ /^(\s*)/ ) {
        $leading = $1;
      }

      if ( length( $leading ) < length( $codeish_target ) ) {
        $line =~ s/^\s*/$codeish_target/;
      }

      push @out, $line;

      if ( defined $codeish_close_re && $line =~ $codeish_close_re ) {
        $in_codeish       = 0;
        $codeish_close_re = undef;
        $codeish_target   = '';
      }

      next;
    }

    my $active_html_level = $in_ep_payload ? $ep_html_level : $html_level;
    my $is_closing_block  = $line =~ m{^\s*</$block\b}i ? 1 : 0;

    if ( $is_closing_block ) {
      if ( $in_ep_payload ) {
        $ep_html_level-- if $ep_html_level > 0;
        $active_html_level = $ep_html_level;
      } else {
        $html_level-- if $html_level > 0;
        $active_html_level = $html_level;
      }
    }

    my $base_level =
          $in_ep_payload
        ? $ep_level + 1
        : 0;

    my $target = $indent x ( $base_level + $active_html_level );

    if ( $line =~ /^\s*<(script|style)\b/i ) {
      my $tag = $1;

      my $leading = '';
      if ( $line =~ /^(\s*)/ ) {
        $leading = $1;
      }

      if ( length( $leading ) < length( $target ) ) {
        $line =~ s/^\s*/$target/;
      }

      push @out, $line;

      if ( $line !~ m{</$tag>}i ) {
        $in_codeish       = 1;
        $codeish_close_re = qr{^\s*</$tag>}i;
        $codeish_target   = $target;
      }

      next;
    }

    if ( length $line ) {
      my $leading = '';

      if ( $line =~ /^(\s*)/ ) {
        $leading = $1;
      }

      if ( $is_closing_block ) {
        $line =~ s/^\s*/$target/;
      } elsif ( length( $leading ) < length( $target ) ) {
        $line =~ s/^\s*/$target/;
      }
    }

    push @out, $line;

    if (    $line =~ /^\s*<$block\b/i
         && $line !~ /^\s*<$void\b/i
         && $line !~ m{</$block>}i
         && $line !~ m{/>[ \t]*\z} )
    {
      if ( $in_ep_payload ) {
        $ep_html_level++;
      } else {
        $html_level++;
      }
    }
  }

  return join "\n", @out;
}

sub _html_prebake_text_payload_newlines ( $self, $text ) {
  return '' unless defined $text && length $text;

  # Flattening plain text lines should preserve word separation.
  # Do not use this inside code-ish blocks.
  $text =~ s{([A-Za-z0-9,.;:!?'\")\]])\n[ \t]*(?=[A-Za-z0-9'\"])}{$1 }g;

  return $text;
}

sub _html_separate_blocks ( $self, $text ) {
  return '' unless defined $text && length $text;

  my $block =
      qr/(?:div|label|section|article|table|thead|tbody|tfoot|tr|th|ul|ol|p)/;

  $text =~ s{(<$block\b[^>]*>)[ \t]*(?=<$block\b)}{$1\n}gi;
  $text =~ s{(</$block>)[ \t]*(?=<$block\b)}{$1\n}gi;
  $text =~ s{(</$block>)[ \t]*(?=</$block>)}{$1\n}gi;

  # Lists get a visual block break before them.
  $text =~ s{(</$block>)[ \t]*\n?(<(?:ul|ol)\b[^>]*>)}{$1\n\n$2}gi;

  # List items: break before each <li>, and after each </li>.
  $text =~ s{(<(?:ul|ol)\b[^>]*>)[ \t]*(?=<li\b)}{$1\n}gi;
  $text =~ s{(</li>)[ \t]*(?=<li\b)}{$1\n}gi;
  $text =~ s{(</li>)[ \t]*(?=</(?:ul|ol)>)}{$1\n}gi;

  # List items: put primary child anchors/divs on their own lines.
  $text =~ s{(<li\b[^>]*>)[ \t]*(?=<(?:a|div)\b)}{$1\n}gi;

  # Dropdown/menu anchors: one item per line.
  $text =~ s{(<div\b[^>]*\bdropdown-menu\b[^>]*>)[ \t]*(?=<a\b)}{$1\n}gi;
  $text =~ s{(</a>)[ \t]*(?=<a\b)}{$1\n}gi;
  $text =~ s{(</a>)[ \t]*(?=<div\b[^>]*\bdropdown-divider\b)}{$1\n}gi;
  $text =~ s{(</div>)[ \t]*(?=<a\b)}{$1\n}gi;

  # Paragraphs are visual text blocks; separate them from preceding HTML closes.
  $text =~ s{(</[A-Za-z][A-Za-z0-9:_-]*>)[ \t]*\n?(<p\b)}{$1\n\n$2}gi;

  # Paragraph text should not stay glued to <p> when mixed EP content follows.
  $text =~ s{(<p\b[^>]*>)[ \t]*(?=\S)}{$1\n}gi;

  # Paragraph text should not stay glued to the opening <p>.
  $text =~ s{(<p\b[^>]*>)[ \t]*(?=\S)}{$1\n}gi;

  # Paragraph close should not stay glued to text payload.
  $text =~ s{([^\s>])</p>}{$1\n</p>}gi;

  # Paragraph payload text to be preserved including internal tags.
  $text =~ s{
    (<(p)\b[^>]*>)
    ([\s\S]*?)
    (</\2>)
  }{
    my ( $open, $tag_name, $body, $close ) = ( $1, $2, $3, $4 );
    $body =~ s/^\s+//;
    $body =~ s/\s+\z//;
    "$open\n$body\n$close";
  }gexi;

  # Inline code in prose gets readable line breaks.
  $text =~ s{([^\s>])(<code\b)}{$1\n$2}gi;
  $text =~ s{(</code>)[ \t]*(?=[,.;:!?]|\w)}{$1\n}gi;

  # Close list-item internals cleanly.
  $text =~ s{(</a>)[ \t]*(?=</li>)}{$1\n}gi;
  $text =~ s{(</div>)[ \t]*(?=</li>)}{$1\n}gi;

  # Closing container tags glued to prior tag should be separated before
  # baseline HTML indentation sees the structure.
  $text =~ s{(?<!-)>[ \t]*(?=</(?:$block)>)}{>\n}gi;

  return $text;
}

sub _html_separate_landmarks ( $self, $text ) {
  return '' unless defined $text && length $text;

  # Top-level document landmarks.
  $text =~ s{(<html\b[^>]*>)\n(<head\b[^>]*>)}{$1\n\n$2}gi;
  $text =~ s{(</head>)\n(<body\b[^>]*>)}{$1\n\n$2}gi;

  # Body/header/nav opening sequence.
  $text =~ s{(<body\b[^>]*>)\n?(<header\b[^>]*>)}{$1\n$2}gi;
  $text =~ s{(<header\b[^>]*>)\n?(<nav\b[^>]*\bnavbar\b[^>]*>)}{$1\n$2\n}gi;

  # Brand/link block inside navbar.
  $text =~
s{(<nav\b[^>]*\bnavbar\b[^>]*>)\n?(<a\b[^>]*\bnavbar-brand\b[^>]*>)}{$1\n\n$2}gi;

  # Main content landmark.
  $text =~ s{(<div\b[^>]*>)\n(<main\b[^>]*>)}{$1\n$2}gi;

  # Footer landmark.
  $text =~ s{(</div>)\n(</div>)\n(<footer\b[^>]*>)}{$1\n$2\n\n$3}gi;

  return $text;
}

sub _js_prebake_inject ( $self ) {
  return
        "\n"
      . "<!--\n"
      . "This block has been reformatted from the original.\n"
      . "If the JavaScript no longer runs,\n"
      . "rerun with --javascript=off.\n"
      . "-->\n\n";
}

sub _js_prebake_scripts ( $self, $text ) {
  return '' unless defined $text && length $text;

  # Basic boundary cleanup before extraction.
  $text =~ s{\n*(?=<script\b)}{\n\n}gi;
  $text =~ s{(<script\b[^>]*>)\s*(?=\S)}{$1\n}gi;
  $text =~ s{([^\n])(?=</script>)}{$1\n}gi;
  $text =~ s{(</script>)\n*}{$1\n\n}gi;

  my $out     = '';
  my $pos     = 0;
  my $matched = 0;

  while ( $text =~ m{(<script\b(?![^>]*\bsrc\s*=)[^>]*>)(.*?)(</script>)}gis ) {
    $matched++;

    my $match_start = $-[0];
    my $match_end   = $+[0];

    my ( $open, $body, $close ) = ( $1, $2, $3 );

    $out .= substr( $text, $pos, $match_start - $pos );

    $body =~ s/\A\s+//;
    $body =~ s/\s+\z//;

    my $original_body = $body;

    $body = $self->_js_format_text( $body, $matched );

    my $note = '';
    if ( $body ne $original_body ) {
      $note = $self->_js_prebake_inject;
    }

    $out .= "$open\n$note$body\n$close";

    $pos = $match_end;
  }

  $out .= substr( $text, $pos );

  if ( $matched ) {
    $text = $out;
  }

  # Re-apply boundary cleanup after reconstruction.
  $text =~ s{\n*(?=<script\b)}{\n\n}gi;
  $text =~ s{(<script\b[^>]*>)\s*(?=\S)}{$1\n}gi;
  $text =~ s{([^\n])(?=</script>)}{$1\n}gi;
  $text =~ s{(</script>)\n*}{$1\n\n}gi;

  return $text;
}

sub _js_format_text ( $self, $js, $matched = undef ) {
  return '' unless defined $js && length $js;

  my $original = $js;

  $js = $self->_js_prebake( $js );

  #   if ( $js =~ /reset UI/ ) {
  #     my $slice = $js;
  #     $slice =~ s/\n/⏎\n/g;
  #
  #   }

  my $formatted = eval {
    js_beautify(
                 $js,
                 {
                  indent_size               => $self->{indent_width},
                  indent_character          => ' ',
                  preserve_newlines         => 1,
                  space_after_anon_function => 0,
                 } );
  };

  if ( $@ ) {
    warn
"JavaScript::Beautifier failed; leaving original JavaScript unchanged: $@";
    return $original;
  }

  return $original unless defined $formatted && length $formatted;

  $formatted = $self->_js_postfix_munges( $js, $formatted );
  $formatted = $self->_js_postfix_ternary_assignments( $formatted );

  if ( $self->_js_formatter_munged( $js, $formatted, $matched ) ) {
    return $original;
  }

  $formatted =~ s/\s+\z//;

  return $formatted;
}

sub _js_formatter_munged ( $self, $before, $after, $matched = undef ) {
  return 0 if !defined $before || !defined $after;
  return 0 if $before eq $after;

  my @problems;

  if ( $before =~ /=>/ && $after =~ /=\s+>/ ) {
    push @problems, 'arrow function token => became = >';
  }

  if ( $before =~ /\?\./ && $after =~ /\?\s+\./ ) {
    push @problems, 'optional chaining token ?. was split';
  }

  if ( $before =~ /\?\?/ && $after =~ /\?\s+\?/ ) {
    push @problems, 'nullish coalescing token ?? was split';
  }

  if ( $before =~ /\?\?=/ && $after =~ /\?\s+\?\s*=/ ) {
    push @problems, 'nullish assignment token ??= was split';
  }

  if ( $before =~ /\|\|=/ && $after =~ /\|\s+\|\s*=/ ) {
    push @problems, 'logical OR assignment token ||= was split';
  }

  if ( $before =~ /&&=/ && $after =~ /&\s+&\s*=/ ) {
    push @problems, 'logical AND assignment token &&= was split';
  }

  if (    $before =~ /\basync[ \t]+function\b/
       && $after =~ /\basync[ \t]*\n[ \t]*function\b/ )
  {
    push @problems, 'async function was split across lines';
  }

  if ( $before =~ m{//[^\n]*\n\s*\S} ) {
    for my $line ( split /\n/, $after ) {
      if (
        $line =~
m{//[^\n]*[A-Za-z0-9_\)](?:document\.|window\.|console\.|const\s+|let\s+|var\s+|if\s
*\(|for\s*\(|while\s*\(|return\b|function\s+|async\s+function\s+|class\s+|new\s+)}
          )
      {
        push @problems, 'line comment may have swallowed following JavaScript';
        last;
      }
    }
  }
  return 0 if !@problems;

  my $where = defined $matched ? " in <script> block $matched" : '';

  warn "PrettyTidy JavaScript formatter may have munged syntax$where;\n"
      . "\tleaving original JavaScript unchanged:\n";

  for my $problem ( @problems ) {
    warn "  - $problem\n";
  }

  return 1;
}

sub _js_postfix_ternary_assignments ( $self, $js ) {
  return '' unless defined $js && length $js;

  my $indent = ' ' x $self->{indent_width};

  $js =~ s{
    ^
    ([ \t]*)
    ([^\n;]*?\.textContent)
    [ \t]*
    =
    [ \t]*
    ([^\n;]*\?[^\n;]*:[^\n;]*;)
  }{
    "$1$2 =\n$1$indent$3"
  }gmex;

  return $js;
}

sub _js_prebake ( $self, $js ) {
  return '' unless defined $js && length $js;

  my $indent = ' ' x $self->{indent_width};

# If flattening glued code/comment boundaries together, restore line-comment shape.
  $js =~ s{;\s*(?=//)}{;\n}g;
  $js =~ s{\{\s*(?=//)}{\{\n}g;
  $js =~ s{\}\s*(?=//)}{\}\n}g;

  # If a line comment is glued to the following likely code boundary, split it.
  $js =~ s{
  (//[^\n]*?\S)
  (?=
      document\.
    | window\.
    | console\.
    | const\s+
    | let\s+
    | var\s+
    | if\s*\(
    | for\s*\(
    | while\s*\(
    | switch\s*\(
    | return\b
    | async\s+function\s+
    | function\s+
    | class\s+
    | new\s+
    | await\s+
    | \}\s*else\b
    | \}\s*catch\b
    | \}\s*finally\b
  )
}{$1\n}gx;

  # Flattening can glue a line comment to following code on the same line.
  # Split before likely statement starts even when the comment has normal text
  # immediately before the code keyword.
  $js =~ s{
    (//[^\n]*?)
    [ \t]+
    (
        (?:const|let|var)\s+
      | (?:document|window|console)\.
      | [A-Za-z_\$][A-Za-z0-9_\$]*\.
      | if\s*\(
      | for\s*\(
      | while\s*\(
      | switch\s*\(
      | return\b
      | async\s+function\s+
      | function\s+
      | class\s+
      | new\s+
      | await\s+
    )
  }{$1\n$2}gx;

  # Flattening can also glue a line comment to a block transition.
  # Example:
  #   // comment} else {
  $js =~ s{
  (//[^\n]*?\S)
  (?=
      \}\s*else\b
    | \}\s*catch\b
    | \}\s*finally\b
  )
}{$1\n}gx;

  # Conservative statement boundaries.
  # Do not split semicolons inside for (...) headers.
  $js =~ s{;\s*(?=(?:const|let|var)\s+)}{;\n}g;
  $js =~ s{;\s*(?=(?:if|for|while|switch|try|catch|finally)\b)}{;\n}g;
  $js =~ s{;\s*(?=(?:async\s+function|function|class)\s+)}{;\n}g;
  $js =~ s{;\s*(?=(?:document|window|console)\.)}{;\n}g;
  $js =~ s{;\s*(?=(?:document|window|console)\.)}{;\n}g;
  $js =~ s{;\s*(?=return\b)}{;\n}g;

  # Function/block boundaries commonly glued by flattening.
  $js =~ s{\}\s*(?=(?:const|let|var)\s+)}{\}\n}g;
  $js =~ s{\}\s*(?=(?:async\s+function|function|class)\s+)}{\}\n}g;
  $js =~ s{\}\s*(?=(?:document|window|console)\.)}{\}\n}g;

  return $js;
}

sub _js_postfix_munges ( $self, $before, $after ) {
  return $after if !defined $before || !defined $after;
  return $after if $before eq $after;

  if ( $before =~ /=>/ ) {
    $after =~ s/=\s+>/=>/g;
    $after =~ s/=>\s*\{/=> {/g;
  }

  if ( $before =~ /\?\?=/ ) {
    $after =~ s/\?\s+\?\s*=/??=/g;
  }

  if ( $before =~ /\?\?/ ) {
    $after =~ s/\?\s+\?/??/g;
  }

  if ( $before =~ /\?\./ ) {
    $after =~ s/\?\s+\./?./g;
  }

  if ( $before =~ /\|\|=/ ) {
    $after =~ s/\|\s+\|\s*=/||=/g;
  }

  if ( $before =~ /&&=/ ) {
    $after =~ s/&\s+&\s*=/&&=/g;
  }

  if ( $before =~ /\basync\s+function\b/ ) {
    $after =~ s/\basync\s*\n\s*function\b/async function/g;
  }

  return $after;
}

sub _pt_debug_write_file ( $self, $idx, $perl ) {
  my $dir = File::Spec->catdir( 'tmp', 'perltidy' );

  if ( !-d $dir ) { File::Path::make_path( $dir ); }

  my $path = File::Spec->catfile( $dir, sprintf 'pt-region-%03d.pl', $idx );

  open my $fh, '>', $path or die "Cannot write $path: $!";
  print {$fh} $perl;
  close $fh or die "Cannot close $path: $!";

  return $path;
}

sub _pt_prebake_region ( $self, @chunks ) {
  my @out;

  for my $i ( 0 .. $#chunks ) {
    my $chunk = $chunks[$i];
    my $line  = $chunk->{text};

    if ( $chunk->{kind} eq 'blank' ) {
      my $prev = $i > 0        ? $chunks[ $i - 1 ]{text} : '';
      my $next = $i < $#chunks ? $chunks[ $i + 1 ]{text} : '';

      if ( $prev =~ m{</script>\s*\z}i || $next =~ m{\A<script\b}i ) {
        push @out, '0; # PrettyTidy:';
      }

      next;
    }

    if ( $chunk->{kind} eq 'ep_control' ) {
      $line =~ s/^\s*%\s?//;
      push @out, $line;
      next;
    }

    if ( $line =~ /^\s*<script\b/i ) {
      push @out, '0; # PrettyTidy:';
    }

    push @out, '0; # PrettyTidy:' . $line;
  }

  return join "\n", @out;
}

sub _pt_reemit_regions ( $self, @chunks ) {
  my @out;
  my @current;
  my $depth     = 0;
  my $in_region = 0;
  my $idx       = 0;

  for my $pos ( 0 .. $#chunks ) {
    my $chunk = $chunks[$pos];
    my $ep    = $chunk->{kind} eq 'ep_control' ? $chunk->{ep} : undef;

    if ( !$in_region ) {
      if ( defined $ep && $ep eq 'opener' ) {
        $in_region = 1;
        $depth     = 0;
        @current   = ();
      } else {
        my $line = $chunk->{text};

        push @out, '' if $line =~ /^\s*<script\b/i && @out && $out[-1] ne '';
        push @out, $line;
        push @out, '' if $line =~ m{</script>\s*$}i;

        next;
      }
    }

    push @current, $chunk;

    if ( defined $ep && ( $ep eq 'closer' || $ep eq 'transition' ) ) {
      $depth-- if $depth > 0;
    }

    my $next_ep = undef;

    if ( defined $ep && $ep eq 'closer' && $depth == 0 ) {
      for my $j ( ( $pos + 1 ) .. $#chunks ) {
        next if $chunks[$j]{kind} eq 'blank';
        $next_ep = $chunks[$j]{kind} eq 'ep_control' ? $chunks[$j]{ep} : undef;
        last;
      }
    }

    if (    defined $ep
         && $ep eq 'closer'
         && $depth == 0
         && ( $next_ep // '' ) ne 'transition' )
    {
      $idx++;
      my $perl = $self->_pt_prebake_region( @current );

      if (    !defined $perl
           || !length $perl
           || $perl =~ /\@\{\s*(?:\n|\z)/
           || $perl =~ /\bbegin\s*(?:\n|\z)/ )
      {
        for my $chunk ( @current ) {
          my $line = $chunk->{text};
          push @out, '' if $line =~ /^\s*<script\b/i && @out && $out[-1] ne '';
          push @out, $line;
          push @out, '' if $line =~ m{</script>\s*$}i;

        }
      } else {
        my ( $ok, $tidied ) = $self->_pt_run( $perl, $idx );

        if ( !$ok ) {
          for my $chunk ( @current ) {
            my $line = $chunk->{text};
            push @out, ''
                if $line =~ /^\s*<script\b/i && @out && $out[-1] ne '';
            push @out, $line;
            push @out, '' if $line =~ m{</script>\s*$}i;
          }
        } else {
          my $template = $self->_pt_template_from_region( $tidied );
          push @out, split /\n/, $template, -1;
        }
      }

      @current   = ();
      $in_region = 0;
      next;
    }

    if ( defined $ep && ( $ep eq 'opener' || $ep eq 'transition' ) ) {
      $depth++;
    }
  }

  # EOF block
  if ( @current ) {
    $idx++;

    my $perl = $self->_pt_prebake_region( @current );

    if (    !defined $perl
         || !length $perl
         || $perl =~ /\@\{\s*(?:\n|\z)/
         || $perl =~ /\bbegin\s*(?:\n|\z)/ )
    {
      #     if ( !$self->_pt_region_supported( $perl ) ) {
      for my $chunk ( @current ) {
        my $line = $chunk->{text};
        push @out, '' if $line =~ /^\s*<script\b/i && @out && $out[-1] ne '';
        push @out, $line;
        push @out, '' if $line =~ m{</script>\s*$}i;
      }
    } else {
      my ( $ok, $tidied ) = $self->_pt_run( $perl, $idx );

      if ( !$ok ) {
        for my $chunk ( @current ) {
          my $line = $chunk->{text};
          push @out, '' if $line =~ /^\s*<script\b/i && @out && $out[-1] ne '';
          push @out, $line;
          push @out, ''
              if $line =~ m{</script>\s*$}i;
        }
      } else {
        my $template = $self->_pt_template_from_region( $tidied );
        push @out, split /\n/, $template, -1;
      }
    }
  }

  return join "\n", @out;
}

sub _pt_run ( $self, $perl, $idx = 1 ) {

  # try stdin/stdout first
  # if success, return tidied stdout
  # if fail, write debug file and rerun file-mode for .ERR/.LOG
  # return original $perl
  return '' unless defined $perl && length $perl;

  if ( !$self->{perl} ) {
    return ( 0, $perl );
  }

  require IPC::Open3;
  require IO::Select;
  require Symbol;

  my @pipe_cmd = ( 'perltidy', '-q', '-st', '-se' );

  my $home_rc = defined $ENV{HOME} ? "$ENV{HOME}/.perltidyrc" : '';

  push @pipe_cmd, "-pro=$home_rc" if length $home_rc && -f $home_rc;

  # PrettyTidy owns wrapping/columns later.
  # Keep perltidy from making width decisions.
  push @pipe_cmd, '-l=9999';
  push @pipe_cmd, '-nbbc';

  #   push @pipe_cmd, '-nbbb';

  my $err = Symbol::gensym();
  my ( $in, $out );

  my $pid = eval { IPC::Open3::open3( $in, $out, $err, @pipe_cmd ) };

  if ( $@ ) {
    warn "Cannot run perltidy: $@";
    $self->_pt_debug_write_file( $idx, $perl );
    return ( 0, $perl );
  }

  print {$in} $perl;
  close $in;

  my ( $tidied, $errors ) = ( '', '' );
  my $sel = IO::Select->new( $out, $err );

  while ( my @ready = $sel->can_read ) {
    for my $fh ( @ready ) {
      my $buf = '';
      my $len = sysread $fh, $buf, 8192;

      if ( !defined $len ) {
        next if $!{EINTR};
        $sel->remove( $fh );
        next;
      }

      if ( $len == 0 ) {
        $sel->remove( $fh );
        next;
      }

      if ( fileno( $fh ) == fileno( $out ) ) {
        $tidied .= $buf;
      } else {
        $errors .= $buf;
      }
    }
  }

  waitpid $pid, 0;
  my $status = $? >> 8;

  #   open my $dbg, '>>', './tmp/pt.raw-perltidy.out'
  #       or die "Cannot write ./tmp/pt.raw-perltidy.out: $!";
  #   print {$dbg} $tidied;
  #   close $dbg;

  return ( 1, $tidied ) if $status == 0 && length $tidied;

  warn "perltidy failed with status $status; writing debug file\n";
  warn $errors if length $errors;

  my $path = $self->_pt_debug_write_file( $idx, $perl );

  my @file_cmd = ( 'perltidy', '-b' );

  push @file_cmd, "-pro=$home_rc" if length $home_rc && -f $home_rc;

  # PrettyTidy owns wrapping/columns later.
  # Keep perltidy from making width decisions.
  push @file_cmd, '-l=9999';
  push @file_cmd, '-nbbc';

  # Debug mode: force sidecar LOG output.
  push @file_cmd, '-g';

  push @file_cmd, $path;
  warn "PERLTIDY PIPE CMD: @pipe_cmd\n";
  system @file_cmd;

  warn "perltidy debug input: $path\n";
  warn "perltidy debug log:   $path.LOG\n" if -f "$path.LOG";
  warn "perltidy debug err:   $path.ERR\n" if -f "$path.ERR";

  return ( 0, $perl );

}

sub _pt_template_from_region ( $self, $text ) {
  return '' unless defined $text && length $text;

  my @out;

  for my $line ( split /\n/, $text, -1 ) {
    if ( $line eq '' ) {
      push @out, '';
      next;
    }

    # Template payload carried through perltidy as:
    #
    #   0; # PrettyTidy:<html...>
    #
    # Keep perltidy's leading indent before the payload, but remove
    # the fake Perl marker itself.
    if ( $line =~ /^(\s*)0;\s*# PrettyTidy:(.*)\z/ ) {
      my ( $leading, $payload ) = ( $1, $2 );

      if ( $payload !~ /\S/ ) {
        push @out, '';
        next;
      }

      push @out, $leading . $payload;
      next;
    }

    # Real Perl code carried through perltidy.
    #
    # Preserve perltidy's leading/template indent before the EP marker,
    # but keep exactly one space between "%" and the Perl code.
    if ( $line =~ /^(\s*)(.*)\z/ ) {
      my ( $leading, $code ) = ( $1, $2 );

      $code =~ s/^\s+//;

      push @out, $leading . '% ' . $code;
      next;
    }
  }

  return join "\n", @out;
}

sub _remove_extra_newlines ( $self, $text ) {
  return '' unless defined $text && length $text;

  $text =~ s/\n{3,}/\n\n/g;

  # Do not leave an empty line before paragraph close.
  $text =~ s{\n{2,}(?=</p>)}{\n}gi;

  # Empty div containers should collapse to one line.
  $text =~ s{
  (<div\b[^>]*>)
  \s*
  (</div>)
}{$1$2}gix;

  return $text;
}

sub _separate_blocks ( $self, $text ) {
  return '' unless defined $text && length $text;

  # Mojo begin/end helper blocks.
  #
  # Handles:
  #   % my $cb = begin
  #     ...
  #   % end
  #
  # Keep begin/end helper regions visually separated from nearby payload.
  my @in = split /\n/, $text, -1;
  my @out;
  my $level = 0;

  for my $i ( 0 .. $#in ) {
    my $line = $in[$i];
    my $kind = $self->_ep_control( $line );

    if ( defined $kind && $kind eq 'end' ) {
      $level-- if $level > 0;
    }

    if (    defined $kind
         && $kind eq 'begin'
         && $level == 0
         && @out
         && $out[-1] ne '' )
    {
      push @out, '';
    }

    push @out, $line;

    if ( defined $kind && $kind eq 'end' && $level == 0 ) {
      my $next = $in[ $i + 1 ] // '';
      push @out, '' if $next =~ /\S/ && @out && $out[-1] ne '';
    }

    if ( defined $kind && $kind eq 'begin' ) {
      $level++;
    }
  }

# EP brace/control blocks.
#
# Handles:
#   % if (...) {
#     ...
#   % } else {
#     ...
#   % }
#
# Keep control blocks readable while avoiding a blank line before else/elsif/etc.

  my @in = split /\n/, $text, -1;
  my @out;
  my $depth = 0;

  for my $i ( 0 .. $#in ) {
    my $line = $in[$i];
    my $kind = $self->_ep_control( $line );

    my $leading = 0;
    $leading = length( $1 ) if $line =~ /\A(\s*)/;

    if ( defined $kind && ( $kind eq 'closer' || $kind eq 'transition' ) ) {
      $depth-- if $depth > 0;
    }

    if (    defined $kind
         && $kind eq 'opener'
         && $depth == 0
         && $leading == 0
         && @out
         && $out[-1] ne '' )
    {
      push @out, '';
    }

    push @out, $line;

    if (    defined $kind
         && $kind eq 'closer'
         && $depth == 0
         && $leading == 0 )
    {
      my $next = $in[ $i + 1 ] // '';

      if ( $next =~ /\S/ && $next !~ /^\s*%\s*(?:\}\s*)?(?:else|elsif)\b/ ) {
        push @out, '' unless @out && $out[-1] eq '';
      }
    }

    if ( defined $kind && ( $kind eq 'opener' || $kind eq 'transition' ) ) {
      $depth++;
    }
  }

  # Adjacent EP blocks / EP-to-payload boundaries.
  #
  # Handles EP statements or control lines that are glued to nearby
  # HTML/template payload.
  $text =~ s{
    \A
    (
      (?:
        %\s*(?:layout|title|my|our|state)\b[^\n]*;\n
      )+
    )
    (?=<[A-Za-z])
  }{$1\n}gx;

  # separate adjacent ep blocks
  my $tag = qr/[A-Za-z][A-Za-z0-9:_-]*/;
  my $ctl = qr/(?:if|unless|for|foreach|while)/;
  $text =~ s{(<$tag\b[^>]*>)\n(%\s*$ctl\b)}{$1\n\n$2}g;
  $text =~ s{(</$tag>)\n(%\s*$ctl\b)}{$1\n\n$2}g;

  return $text;

}

sub tidy ( $self, $input ) {
  $self->_cleanup_artifacts;
  my $text = defined $input ? $input : '';
  my $flat = $self->_flatten( $text );

  my @chunks = $self->_chunk( $flat );
  my $out    = $self->_pt_reemit_regions( @chunks );

  $out = $self->_html_separate_blocks( $out );
  $out = $self->_html_separate_landmarks( $out );

  $out = $self->_ep_postfix_indentation( $out );

  $out = $self->_html_baseline_indentation( $out );

  if ( $self->{attributes} ) {
    $out = $self->_html_attrib_container( $out );
    $out = $self->_html_attrib_solo( $out );
    $out = $self->_html_attrib_option( $out );
    $out = $self->_html_attrib_paired( $out );

    #     $out = $self->_html_baseline_indentation( $out );    # yes, again
  }
  if ( $self->{columns} ) {

    $out = $self->_cols_style_attributes( $out );
    $out = $self->_html_baseline_indentation( $out );
  }

  $out = $self->_separate_blocks( $out );
  $out = $self->_remove_extra_newlines( $out );

  return $out;
}

1;

=head1 NAME

Mojo::PrettyTidy - Format Mojolicious .html.ep templates

=head1 DESCRIPTION

Mojo::PrettyTidy is a conservative formatter for Mojolicious
C<.html.ep> templates.

See L<Mojo::PrettyTidy::Manual> for user-facing command-line
documentation.

=cut

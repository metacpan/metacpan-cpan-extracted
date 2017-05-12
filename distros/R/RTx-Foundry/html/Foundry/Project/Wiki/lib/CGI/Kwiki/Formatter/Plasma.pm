package CGI::Kwiki::Formatter::Plasma;
$VERSION = '0.1';
use strict;
use base 'CGI::Kwiki', 'CGI::Kwiki::Privacy';
use CGI::Kwiki qw(:char_classes);
use Data::Dumper;

sub process_order {
    return qw(
              blockquote
              table
              definition_list
              code function 
              header_1 header_2 header_3 header_4 header_5 header_6 
              escape_html
              lists comment horizontal_line
              paragraph
              text_process
             );
}

sub process_text_order {
    return qw(
              inline_function
              smiles
              inline
              named_http_link no_http_link http_link
              no_mailto_link mailto_link
              no_wiki_link force_wiki_link wiki_link
              version negation
              bold italic underscore
             );
}

sub text_process {
    my ($self, $wiki_text) = @_;
    my $array = [];
    push @$array, $wiki_text;
    for my $method ($self->process_text_order) {
        $array = $self->dispatch($array, $method);
    }
    return $self->combine_chunks($array);
}

my $slide_num;
sub process {
    $slide_num = 0;
    my ($self, $wiki_text) = @_;

    if ($wiki_text =~ m/^__POD__\n/) {
        my $parser = new CGI::Kwiki::Formatter::Plasma::_Pod();
        my @lines = split /\n/, $wiki_text;
        shift @lines;
        my $input =
            CGI::Kwiki::Formatter::Plasma::_PodInputHelper->new( \@lines );
        $parser->parse_from_filehandle( $input );
        return $parser->output();
    } else {
        my $array = [];
        push @$array, $wiki_text;
        for my $method ($self->process_order) {
            $array = $self->dispatch($array, $method);
        }
        return $self->combine_chunks($array);
    }
}

sub dispatch {
    my ($self, $old_array, $method) = @_;
    return $old_array unless $self->can($method);
    my $new_array;
    for my $chunk (@$old_array) {
        if (ref $chunk eq 'ARRAY') {
            push @$new_array, $self->dispatch($chunk, $method);
        }
        else {
            if (ref $chunk) {
                push @$new_array, $chunk;
            }
            else {
                push @$new_array, $self->$method($chunk);
            }
        }
    }
    return $new_array;
}

sub combine_chunks {
    my ($self, $chunk_array) = @_;
    my $formatted_text = '';
    for my $chunk (@$chunk_array) {
        $formatted_text .= 
          (ref $chunk eq 'ARRAY') ? $self->combine_chunks($chunk) :
          (ref $chunk) ? $$chunk :
          $chunk
    }
    return $formatted_text;
}

sub split_method {
    my ($self, $text, $regexp, $method) = @_;
    my $i = 0;
    map {$i++ % 2 ? \ $self->$method($_) : $_} split $regexp, $text;
}

sub user_functions {
    qw(
        SLIDESHOW_SELECTOR
        total_bullets
        AlignBegin
        AlignEnd
        ColorBegin
        ColorEnd
        TagBegin
        TagEnd
        Entity
      );
}

sub isa_function {
    my ($self, $function) = @_;
    defined { map { ($_, 1) } $self->user_functions }->{$function} and
    $self->can($function)
}

sub function {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{\[\&([^_]\w+\b.*?)\]},
        'function_format',
    );
}

sub inline_function {
    my ($self, $text) = @_;
    $self->combine_chunks( [ $self->split_method($text,
        qr{\[\&(?:amp;)?_(\w+\b.*?)\]},
        'function_format',
    ) ] );
}

sub function_format {
    my ($self, $text) = @_;
    my ($method, @args) = split;
    $self->isa_function($method) 
      ? $self->$method(@args)
      : "<!-- Function not supported here: $text -->\n";
}

sub AlignBegin {
    my ($self, $align) = @_;

    ($align) = $align =~ m/^(center|justify|left|right)$/i;
    $align ||= qq{left};

    return qq{<div style="text-align:$align;">};
}

sub AlignEnd {
    
    return qq{</div>};
}

sub ColorBegin {
    my ($self, $color, $bcolor) = @_;

    return qq{<span>}
        unless $color;

    ($color)  = $color  =~ m/(\w+|#[0-9A-Fa-f]+)/;
    my $style = qq{color:$color;};
    if ($bcolor) {
        ($bcolor) = $bcolor =~ m/(\w+|#[0-9A-Fa-f]+)/;
        $style .= qq{background:$bcolor;} if $bcolor;
    }

    return qq{<span style="$style">};
}

sub ColorEnd {
    my ($self) = @_;

    return qq{</span>};
}

sub TagBegin {
    my ($self, $tag) = (shift, shift);

    return qq{<$tag>};
}

sub TagEnd {
    my ($self, $tag) = (shift, shift);

    return qq{</$tag>};
}

sub Entity {
    my ($self, $entity) = @_;

    return qq{} unless $entity;

    ($entity) = $entity =~ m/([0-9A-Fa-f]+)/;

    return qq{&#$entity;};
}

sub total_bullets {
    my ($self) = @_;
    scalar(() = $self->database->load($self->cgi->page_id) =~ /^\* /gm);
}

sub SLIDESHOW_SELECTOR {
    my ($self) = @_;
    $slide_num = 1;
    my $page_id = $self->cgi->page_id;
    my $start = $self->loc('start');
    my $html = <<END;
<script src="javascript/SlideStart.js"></script>
<form>
${ \ CGI::popup_menu(
         -name => 'size',
         -values => [qw(640x480 800x600 1024x768 1280x1024 1600x1200), $self->loc('fullscreen')]
     )
 }
<input type="button" name="button" value="$start" onclick="startSlides()">
<input type="hidden" name="action" value="START">
<input type="hidden" name="page_id" value="$page_id">
</form>
END
    $html;
}

sub TRANSCLUDE_HTTP_BODY {
    my ($self, $url) = @_;
    require LWP::Simple;
    my $html = LWP::Simple::get($url)
      or return '';
    $html =~ s#.*<body>(.*)</body>.*#$1#is;
    \ $html;
}

sub smiles {
  my ($self, $text) = @_;
  $self->split_method($text,
    qr{(?<!\!)\[:([A-Za-z_]+?):\]},
    'smiles_format',
  );
}

sub smiles_format {
  my ($self, $text) = @_;

  if ($self->config->exists('smiles_page')) {
      my $smiles = $self->config->smiles_page;
      my %smiles;
      if ( $self->driver->database->exists( $smiles ) ) {
          my $smiles_text = $self->driver->database->load( $smiles );
          %smiles = $smiles_text =~ m/
                                      \[:([A-Za-z_]+?):\]
                                      \s*[:|;]\s*
                                      ((?:https?|ftp):\S+?\.(?i:jpg|gif|jpeg|png))
                                      /migx;
      }
      if ($smiles{$text}) {
          return qq{<img class="smiley" src="$smiles{$text}" border="0" alt="$text smiley" />};
      }
  }
  return qq{<tt>[:$text:]</tt>};
}

sub definition_list {
    my ($self, $text) = @_;
    $self->split_method($text,
                        qr{^(;+[^:]+:.*)}m,
                        'definition_list_format',
                       );
}

sub definition_list_format {
    my ($self, $text) = @_;
    my ($dt_marks, $term, $definition) = $text =~ m/(;+)([^:]*?):(.*)/;
    my $depth = length($dt_marks);

    $term = $self->text_process($term);
    $term =~ s#(^<p>\n|\n</p>\n$)##gs;
    $definition = $self->text_process($definition);
    $definition =~ s#(^<p>\n|\n</p>\n$)##gs;

    my $html;
    $html .= qq{<blockquote>} x ($depth - 1) . qq{<dl>\n};
    $html .= qq{  <dt>$term</dt>\n};
    $html .= qq{  <dd>$definition</dd>\n};
    $html .= qq{</dl>\n} . qq{</blockquote>} x ($depth - 1);

    return $html;
}

sub blockquote
{
    my ($self, $text) = @_;
    $self->split_method( $text,
                         qr{^(:+\s?.*?)\n}m,
                         'blockquote_format',
                       );
}

sub blockquote_format {
    my ($self, $text) = @_;

    my ($block_marks, $content) = $text =~ m/(:+)\s?(.*)/;
    my $depth = length $block_marks;

    $content = $self->text_process($content);

    return "<blockquote>"x$depth . $content . "</blockquote>"x$depth;
}

sub table {
    my ($self, $text) = @_;
    my @array;
    while ($text =~ /(.*?)(^\|[^\n]*\|\n.*)/ms) {
        push @array, $1;
        my $table;
        ($table, $text) = $self->parse_table($2);
        push @array, $table;
    }
    push @array, $text if length $text;
    return @array;
}

sub parse_table {
    my ($self, $text) = @_;
    my $error = '';
    my $rows;
    while ($text =~ s/^(\|(.*)\|\n)//) {
        $error .= $1;
        my $data = $2;
        my $row = [];
        for my $datum (split /\|/, $data, -1) {
            if ($datum =~ s/^\s*<<(\S+)\s*$//) {
                my $marker = $1;
                while ($text =~ s/^(.*\n)//) {
                    my $line = $1;
                    $error .= $line;
                    if ($line eq "$marker\n") {
                        $marker = '';
                        last;
                    }
                    $datum .= $line;
                }
                if (length $marker) {
                    return ($error, $text);
                }
            }
            push @$row, $datum;
        }
        push @$rows, $row;
    }
    return ($self->format_table($rows), $text);
}

sub format_table {
    my ($self, $rows) = @_;
    my $cols = 0;
    # Find largest column number
    for (@$rows) {
        $cols = @$_ if @$_ > $cols;
    }
    # Fill them all up for easy processing later
    for (@$rows) {
        if (@$_ < $cols) {
            $_->[$cols - 1] = undef;
        }
    }
    my $table = qq{<blockquote>\n<table border="1">\n};
    for (my $p = 0; $p < @$rows; $p++) {
        my $row = $rows->[$p];
        $table .= qq{<tr valign="top">\n};
        for (my $i = 0; $i < @$row; $i++) {
            my $cell = $row->[$i];
            next if !defined($cell) || !length($cell) || $cell eq "^";

            # calculate colspan
            my $colspan = "";
            if ($i < $#$row
                && (!defined($row->[$i + 1])
                    || !length($row->[$i + 1]))) {
                $colspan = 1;
                for (my $j = $i + 1; $j < @$row; $j++) {
                    last if $row->[$j];
                    $colspan++;
                }
                $colspan = qq{ colspan="$colspan"};
            }

            # calculate rowspan
            my $rowspan = "";
            if ( $p < $#$rows
                 && defined($rows->[$p + 1][$i])
                 && $rows->[$p + 1][$i] eq "^" ) {
                $rowspan = 1;
                for (my $q = $p + 1; $q < @$rows; $q++) {
                    last if $rows->[$q][$i] ne "^";
                    $rowspan++;
                }
                $rowspan = qq{ rowspan="$rowspan"};
            }

            my $align = "";
            if ($cell =~ /\n/) {
                $cell = qq{<pre>$cell</pre>\n};
            } else {
                {
                    my ($ls, $text, $rs) = $cell =~ m/^( )?(.*?)( )?$/;
                    if (defined $ls && defined $rs) {
                        $align = "center";
                    } elsif (defined $ls) {
                        $align = "right";
                    } elsif (defined $rs) {
                        $align = "left";
                    }
                    $align = qq( align="$align") if $align;
                    $cell = defined($text) ? $text : "";
                }

                $cell = $self->escape_html($cell);
                $cell = $self->text_process($cell);
            }

            $cell = '&nbsp;' unless length $cell;
            $table .= qq{<td$rowspan$colspan$align>$cell</td>\n};
        }
        $table .= qq{</tr>\n};
    }
    $table .= qq{</table></blockquote>\n};
    return \$table;
}

sub no_wiki_link {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{!([$UPPER](?=[$WIKIWORD]*[$UPPER])(?=[$WIKIWORD]*[$LOWER])[$WIKIWORD]+)},
        'no_wiki_link_format',
    );
}

sub no_wiki_link_format {
    my ($self, $text) = @_;
    return $text;
}

sub wiki_link {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{([$UPPER](?=[$WIKIWORD]*[$UPPER])(?=[$WIKIWORD]*[$LOWER])[$WIKIWORD]+)},
        'wiki_link_format',
    );
}

sub force_wiki_link {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{(?<!\!)\[([$ALPHANUM\-:]+)\]},
        'wiki_link_format',
    );
}

sub wiki_link_format {
    my ($self, $text) = @_;
    my $script = $self->script;
    my $url = $self->escape($text);
    my $wiki_link = qq{<a href="$script?$url">$text</a>};
    if (not $self->database->exists($text)) {
        $wiki_link =~ s/<a/<a class="empty"/;
    }
    elsif (not $self->is_readable($text)) {
	$url = $self->escape($self->loc("KwikiPrivatePage"));
        $wiki_link = 
          qq{<a class="private" href="$script?$url">$text</a>};
    }
    return $wiki_link;
}

sub no_http_link {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{(!(?:https?|ftp|irc):\S+?)}m,
        'no_http_link_format',
    );
}

sub no_http_link_format {
    my ($self, $text) = @_;
    $text =~ s#!##;
    return $text;
}

sub http_link {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{((?:https?|ftp|irc):\S+?(?=[),.:;]?\s|$))}m,
        'http_link_format',
    );
}

sub http_link_format {
    my ($self, $text) = @_;
    if ($text =~ /^http.*\.(?i:jpg|gif|jpeg|png)$/) {
        return $self->img_format($text);
    }
    else {
        return $self->link_format($text);
    }
}

sub no_mailto_link {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{(![$ALPHANUM][$WORD\-\.]*@[$WORD][$WORD\-\.]+)}m,
        'no_mailto_link_format',
    );
}

sub no_mailto_link_format {
    my ($self, $text) = @_;
    $text =~ s#!##;
    return $text;
}

sub mailto_link {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{([$ALPHANUM][$WORD\-\.]*@[$WORD][$WORD\-\.]+)}m,
        'mailto_link_format',
    );
}

sub mailto_link_format {
    my ($self, $text) = @_;
    my $dot = ($text =~ s/\.$//) ? '.' : '';
    qq{<a href="mailto:$text">$text</a>$dot};
}

sub img_format {
    my ($self, $url) = @_;
    return qq{<img src="$url">};
}

sub link_format {
    my ($self, $text) = @_;
    $text =~ s/(^\s*|\s+(?=\s)|\s$)//g;
    my $url = $text;
    $url = $1 if $text =~ s/(.*?) +//;
    $url =~ s/https?:(?!\/\/)//;
    return qq{<a href="$url">$text</a>};
}

sub named_http_link {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{(?<!\!)\[([^\[\]]*?(?:https?|ftp|irc):\S.*?)\]},
        'named_http_link_format',
    );
}

sub named_http_link_format {
    my ($self, $text) = @_;
    if ($text =~ m#(.*)(?:https?|ftp|irc):(\S+)(.*)#) {
        $text = "$2 $1$3";
    }
    return $self->link_format($text);
}

sub version {
    my ($self, $text) = @_;
    $text =~ s#(?<!\!)\[\#\.\#\]#$CGI::Kwiki::VERSION#g;
    return $text;
}

sub inline {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{(?<!\!)\[=(.*?)\]},
        'inline_format',
    );
}

sub inline_format {
    my ($self, $text) = @_;
    "<tt>$text</tt>";
}

sub negation {
    my ($self, $text) = @_;
    $text =~ s#\!(?=\[)##g;
    return $text;
}

sub bold {
    my ($self, $text) = @_;
    $text =~ s#(?<![$WORD])\*(\S.*?\S)\*(?![$WORD])#<b>$1</b>#g;
    return $text;
}

sub italic {
    my ($self, $text) = @_;
    $text =~ s#(?<![$WORD<])/(\S.*?\S)/(?![$WORD])#<em>$1</em>#g;
    return $text;
}

sub underscore {
    my ($self, $text) = @_;
    $text =~ s#(?<![$WORD])_(\S.*?\S)_(?![$WORD])#<u>$1</u>#g;
    return $text;
}

sub code {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{(^ +[^ \n].*?\n)(?-ms:(?=[^ \n]|$))}ms,
        'code_format',
    );
}

sub code_format {
    my ($self, $text) = @_;
    $self->code_postformat($self->code_preformat($text));
}

sub code_preformat {
    my ($self, $text) = @_;
    my ($indent) = sort { $a <=> $b } map { length } $text =~ /^( *)\S/mg;
    $text =~ s/^ {$indent}//gm;
    return $self->escape_html($text);
}

sub code_postformat {
    my ($self, $text) = @_;
    return "<blockquote><pre>$text</pre></blockquote>\n";
}

sub escape_html {
    my ($self, $text) = @_;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text;
}

sub lists {
    my ($self, $text) = @_;
    my $switch = 0;
    return map {
        my $level = 0;
        my @tag_stack;
        if ($switch++ % 2) {
            my $text = '';
            my @lines = /(.*\n)/g;
            for my $line (@lines) {
                $line =~ s/^([0\*]+) //;
                my $new_level = length($1);
                my $tag = ($1 =~ /0/) ? 'ol' : 'ul';
                if ($new_level > $level) {
                    for (1..($new_level - $level)) {
                        push @tag_stack, $tag;
                        $text .= "<$tag>\n";
                    }
                    $level = $new_level;
                }
                elsif ($new_level < $level) {
                    for (1..($level - $new_level)) {
                        $tag = pop @tag_stack;
                        $text .= "</$tag>\n";
                    }
                    $level = $new_level;
                }
                $text .= "<li>$line";
            }
            for (1..$level) {
                my $tag = pop @tag_stack;
                $text .= "</$tag>\n";
            }
            $_ = $self->lists_format($text);
        }
        $_;
    }
    split m!(^[0\*]+ .*?\n)(?=(?:[^0\*]|$))!ms, $text;
}

sub lists_format {
    my ($self, $text) = @_;
    return $text;
}

sub paragraph {
    my ($self, $text) = @_;
    my $switch = 0;
    return map {
        unless ($switch++ % 2) {
            $_ = $self->paragraph_format($_);
        }
        $_;
    }
    split m!(\n\s*\n)!ms, $text;
}

sub paragraph_format {
    my ($self, $text) = @_;
    return '' if $text =~ /^[\s\n]*$/;
    return $text if $text =~ /^<(d|o|u)l>/i;
    return "<p>\n$text\n</p>\n";
}

sub horizontal_line {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{(^----+\n)}m,
        'horizontal_line_format',
    );
}

sub horizontal_line_format {
    my ($self) = @_;
    my $text = "<hr>\n";
    if ($slide_num) {
        my $page_id = $self->cgi->page_id;
	my $go = $self->loc('Go');
        $text .= qq{<a target="SlideShow" href="index.cgi?action=slides&page_id=$page_id&slide_num=$slide_num">$go</a>\n};
        $slide_num++;
    }
    return $text;
}

sub comment {
    my ($self, $text) = @_;
    $self->split_method($text,
        qr{^\# (.*)\n}m,
        'comment_line_format',
    );
}

sub comment_line_format {
    my ($self, $text) = @_;
    return "<!-- $text -->\n";
}

for my $num (1..6) {
    no strict 'refs';
    *{"header_$num"} = 
    sub {
        my ($self, $text) = @_;
        $self->split_method($text,
            qr{^={$num} (.*?)(?: ={$num})?\n}m,
            "header_${num}_format",
        );
    };
    *{"header_${num}_format"} = 
    sub {
        my ($self, $text) = @_;
        $text = $self->text_process($text);
        return "<h$num>$text</h$num>\n";
    };
}

# {{{ Helper modules for POD formatting

package CGI::Kwiki::Formatter::Plasma::_PodInputHelper;

sub new {
    my $class = shift;
    my $self = {};

    $self->{Data} = shift;

    print STDERR "InputHelper: length of data is " . scalar(@{$self->{Data}});

    bless $self, $class;
    return $self;
}

sub getline {
    my $self = shift;
    my $result = shift @{$self->{Data}};
    return (defined $result) ? "$result\n" : $result;
}

package CGI::Kwiki::Formatter::Plasma::_Pod;

use base qw(Pod::Parser);

my @contents;

sub command {
    my ($self,$cmd,$text,$line_num,$pod_para) = @_;

    $text = $self->interpolate( $text, $line_num );

    if    ( $cmd eq "head1" ) { push @contents, qq{<h1>$text</h1>} }
    elsif ( $cmd eq "head2" ) { push @contents, qq{<h2>$text</h2>} }
    elsif ( $cmd eq "head3" ) { push @contents, qq{<h3>$text</h3>} }
    elsif ( $cmd eq "head4" ) { push @contents, qq{<h4>$text</h4>} }
    elsif ( $cmd eq "head5" ) { push @contents, qq{<h5>$text</h5>} }
    elsif ( $cmd eq "head6" ) { push @contents, qq{<h6>$text</h6>} }
    elsif ( $cmd eq "over" ) { push @contents, qq{<ul>} }
    elsif ( $cmd eq "item" ) { push @contents, qq{<li>$text</li>} }
    elsif ( $cmd eq "back" ) { push @contents, qq{</ul>} }
    else {
        #print "command($cmd, $text, $line_num, $pod_para)\n";
    };
}

sub verbatim {
    my ($self,$text,$line_num,$pod_para) = @_;

    push @contents, qq{<pre>$text</pre>};
}

sub textblock {
    my ($self,$text,$line_num,$pod_para) = @_;

    $text = $self->interpolate( $text, $line_num );
    push @contents, qq{<p>$text</p>};
}

sub interior_sequence {
    my ($self,$seq_cmd,$seq_arg,$pod_seq) = @_;

    if    ( $seq_cmd eq "B" ) { return qq{<b>$seq_arg</b>} }
    elsif ( $seq_cmd eq "I" ) { return qq{<i>$seq_arg</i>} }
    elsif ( $seq_cmd eq "C" ) { return qq{<code>$seq_arg</code>} }
    elsif ( $seq_cmd eq "F" ) { return qq{<code>$seq_arg</code>} }
    elsif ( $seq_cmd eq "L" ) { return qq{<tt>$seq_arg</tt>} }
    elsif ( $seq_cmd eq "E" ) {
        if    ( $seq_arg eq "lt" ) { return qq{&lt;} }
        elsif ( $seq_arg eq "gt" ) { return qq{&gt;} }
        elsif ( $seq_arg eq "verbar" ) { return qq{|} }
        elsif ( $seq_arg eq "sol" ) { return qq{/} }
        elsif ( $seq_arg =~ m/^0x/ ) {
            $seq_arg = hex $seq_arg;
            return qq{&#$seq_arg;};
        } elsif ( $seq_arg =~ m/^0/ ) {
            $seq_arg = oct $seq_arg;
            return qq{&#$seq_arg;};
        } elsif ( $seq_arg =~ m/^\d+$/ ) { return qq{$&#seq_arg;} }
        else { return qq{&$seq_arg;} }
    }
    elsif ( $seq_cmd eq "S" ) {
        $seq_arg =~ s/ /&nbsp;/;
        return qq{<code>$seq_arg</code>};
    }
    else {
        #print "interior_sequence($seq_cmd, $seq_arg, $pod_seq)\n";
    }
}

sub output {
    my $self = shift;

    my $text = join "", @contents;

    # reformat headers
    $text =~ s{<(h\d)><p>}{<$1>}g;
    $text =~ s{<p></(h\d)>}{</$1>}g;

    # reformat verbatim blocks
    $text =~ s{</pre><pre>}{\n}g;
    $text =~ s{<pre>}{<blockquote><pre>}g;
    $text =~ s{</pre>}{</pre></blockquote>}g;

    # reformat lists with bullets
    $text =~ s{(<ul>.+?</ul>)}{
        my $chunk = $1;
        $chunk =~ s{<li>[*]\s+</li><p>(.+?)</p>}{<li>$1</li>}gs;
        $chunk;
    }xegs;

    return $text;
}

# }}}

1;

__END__

=head1 NAME 

CGI::Kwiki::Formatter::Plasma - Plasma's Formatter for CGI::Kwiki

=head1 DESCRIPTION

See installed kwiki pages for more information.

=head1 AUTHOR

Chen, Wei-Hon a.k.a plasma <plasmaball@pchome.com.tw>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.
Copyright (c) 2003. Chen, Wei-Hon. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

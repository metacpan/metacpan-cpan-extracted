# ABSTRACT: pack novel/bbs content to ebook
package Novel::Robot::Packer;
use strict;
use warnings;
use utf8;
use Encode::Locale;
use Encode;
use File::Temp qw/tempfile /;
use Template;

#our $VERSION = 0.21;

sub new {
  my ( $self, %opt ) = @_;

  $opt{type} ||= 'html';

  bless {%opt}, __PACKAGE__;
}

sub set_type {
  my ( $self, $output, $o ) = @_;

  if ( exists $o->{type} ) {
    return $o->{type};
  } elsif ( defined $output
    and ( !exists $o->{output_scalar} ) ) {
    ( $o->{type} ) = $output =~ m#\.([^.]+)$#;
  } else {
    $o->{type} = 'html';
  }

  return $o->{type};
}

sub detect_writer_book_type {
  my ( $self, $input, $o ) = @_;

  $input = decode( locale => $input );
  my ( $writer, $book, $type ) = $input =~ /([^\\\/]+?)-([^\\\/]+?)\.([^.\\\/]+)$/;

  $writer = $o->{writer} if ( defined $o->{writer} );
  $writer //= '';

  $book = $o->{book} if ( defined $o->{book} );
  $book //= '';

  return ( $writer, $book, $type );
}

sub convert_novel {
  my ( $self, $input, $output, $o ) = @_;

  return $input unless ( -f $input and -s $input );

  my ( $writer, $book, $in_type ) = $self->detect_writer_book_type( $input, $o );

  if ( !defined $output ) {
    $output = $input;
    $output =~ s/\.([^.]+)$/.$o->{type}/;
  }
  return $input if ( $output eq $input );

  my ( $out_type ) = $output =~ m#\.([^.]+)$#;

  my %conv = (
    'authors'            => $writer,
    'author-sort'        => $writer,
    'title'              => $book,
    'chapter-mark'       => "none",
    'page-breaks-before' => "/",
    'max-toc-links'      => 0,
  );

  my $conv_str = join( " ", map { qq[--$_ "$conv{$_}"] } keys( %conv ) );
  if ( $o->{type} =~ /\.epub$/ ) {
    $conv_str .= " --dont-split-on-page-breaks ";
  } elsif ( $o->{type} =~ /\.mobi$/ ) {
    $conv_str .= " --mobi-keep-original-images ";
  }

  $conv_str = encode( locale => $conv_str );
  my $cmd = qq[ebook-convert "$input" "$output" $conv_str];
  #print "$cmd\n";
  #system($cmd);
  `$cmd`;

  return $output;
} ## end sub convert_novel

sub main {
  my ( $self, $book_ref, $o ) = @_;

  $self->set_type( $o->{output}, $o );
  $self->format_item_output( $book_ref, $o );

  if ( $o->{type} ne 'html' and ( !exists $o->{output_scalar} ) ) {
    my ( $fh, $html_f ) = tempfile( "run_novel-html-XXXXXXXXXXXXXX", TMPDIR => 1, SUFFIX => ".html" );
    $self->process_html_template( $book_ref, $html_f, $o );
    $self->convert_novel( $html_f, $o->{output}, { type => $o->{type}, writer => $book_ref->{writer}, book => $book_ref->{book} } );
  } else {
    $self->process_html_template( $book_ref, $o->{output}, $o );
  }

  return $o->{output};
}

sub format_item_output {
  my ( $self, $book_ref, $o ) = @_;
  if ( !$o->{output} ) {
    my $html = '';
    $o->{output} =
      exists $o->{output_scalar}
      ? \$html
      : $self->format_default_filename( $book_ref, $o );
  }
  return $o->{output};
}

sub format_default_filename {
  my ( $self, $r, $o ) = @_;

  my $item_info = '';
  if ( exists $o->{min_item_num} and $o->{min_item_num} > 1 ) {
    $item_info = "-$o->{min_item_num}";
  } elsif ( exists $o->{min_page_num} and $o->{min_page_num} > 1 ) {
    $item_info = "-$o->{min_page_num}";
  }
  my $f = "$r->{writer}-$r->{book}$item_info." . $o->{type};
  $f =~ s{[\[\]/><\\`;'\$^*\(\)\%#@!"&:\?|\s^,~]}{}g;
  return encode( locale => $f );
}

sub process_html_template {
  my ( $self, $book_ref, $dst, $o ) = @_;

  my $toc = $o->{with_toc}
    ? qq{<div id="toc"><ul>
    [% FOREACH r IN item_list %]
    [% IF r.content %] <li>[% r.id %]. <a href="#toc[% r.id %]">[% r.writer %] [% r.title %]</a></li> [% END %] 
    [% END %]
    </ul>
    </div>}
    : '';

  my $txt = <<__HTML__;
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
        <html>

        <head>
        <meta charset="UTF-8">
        <meta property="opf.authors" content="[% writer %]">
        <meta property="opf.titlesort" content="[% book %]">
        <title> [% writer %] 《 [% book %] 》</title>
        <style type="text/css">
body {
	font-size: large;
	margin: 1em 8em 1em 8em;
	text-indent: 2em;
	line-height: 145%;
}
#title, .chapter {
	border-bottom: 0.2em solid #ee9b73;
	margin: 0.8em 0.2em 0.8em 0.2em;
	text-indent: 0em;
	font-size: xx-large;
    font-weight: bold;
    padding-bottom: 0.25em;
}
#title, ol { line-height: 150%; }
#title { text-align: center; }
        </style>
        </head>

        <body>
        <div id="title"><a href="[% writer_url %]">[% writer %]</a> 《 <a href="[% url %]">[% book %]</a> 》</div>
        $toc
<div id="content">
    [% FOREACH r IN item_list %]
    [% IF r.content %]
<div class="item">
<div class="chapter">[% r.id %]. <a name="toc[% r.id %]">[% r.writer %] [% r.title %]</a>  [% r.time %]</div>
<div class="content">[% r.content %]</div>
</div>[% END %]
[% END %]
</div>
</body>
</html>
__HTML__
  my $tt = Template->new();
  $tt->process( \$txt, $book_ref, $dst, { binmode => ':utf8' } ) || die $tt->error(), "\n";
  return $dst;
} ## end sub process_html_template

1;


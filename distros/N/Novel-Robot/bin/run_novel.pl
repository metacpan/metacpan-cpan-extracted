#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use File::Temp qw/tempfile /;
use Encode;
use Encode::Locale;
use File::Copy;
use Getopt::Std;
use Novel::Robot;
use POSIX qw/ceil/;
use FindBin;
use Data::Dumper;

$| = 1;
binmode( STDIN,  ":encoding(console_in)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );

our $GET_NOVEL = "$FindBin::RealBin/get_novel.pl ";

my %opt;
getopt( 'sfwbutTGCSoh', \%opt );

if($opt{o} and $opt{o}=~m#[^\/\\]+\.[^\/\\]+$#){
    my ($t) = $opt{o}=~m#[^\/\\]+\.([^\/\\]+)$#;
    $opt{T} ||= $t;
}else{
    $opt{T} ||= 'mobi';
}

for ( qw/G C S o w b/ ) {
  $opt{$_} = exists $opt{$_} ? decode( locale => $opt{$_} ) : '';
}

main_ebook( %opt );

sub main_ebook {
  my ( %o ) = @_;

  my ( $fh, $f_e, $msg );

  if ( $o{f} and -f $o{f} ) {
    if ( $o{f} =~ /\.txt/i ) {
      my $fname = decode( locale => $o{f} );
      my ( $writer, $book ) = $fname =~ /([^\\\/]+?)-([^\\\/]+?)\.[^.\\\/]+$/;
      $o{w} ||= $writer;
      $o{b} ||= $book;
      $f_e = get_ebook( $o{f}, $o{w}, $o{b}, %o );
      $msg = "$o{w} 《$o{b}》";
    } else {
      my ( $f_s ) = $o{f} =~ /\.([^.]+)$/i;
      ( $fh, $f_e ) = tempfile( "run_novel-raw-XXXXXXXXXXXXXX", TMPDIR => 1, SUFFIX => ".$f_s" );
      copy( $o{f}, $f_e );
      $msg = decode( locale => $o{f} );
    }
  } elsif($o{u}) {
    my $info = decode( locale => `$GET_NOVEL -u "$o{u}" -D 1` );
    chomp( $info );
    my ( $writer, $book, $url, $chap_num ) = split ',', $info;
    $writer = $o{w} if($o{w});
    $book = $o{b} if($o{b});
    $f_e = get_ebook( $o{u}, $writer, $book, %o );
    $msg = "$writer 《$book》 $chap_num   $url";
  }else {
    $f_e = get_ebook( undef, $o{w}, $o{b}, %o );
    $msg = "$o{s} : $o{w} 《$o{b}》";
  }

  send_ebook( $f_e, $msg, %o ) if ( $o{t} and $f_e and -f $f_e );
  return $f_e;
} ## end sub main_ebook

sub get_ebook {
  my ( $src, $writer, $book, %o ) = @_;

  #conv txt to html / get novel to html
  my ( $fh, $html_f ) = tempfile( "run_novel-html-XXXXXXXXXXXXXX", TMPDIR => 1, SUFFIX => ".html" );
  if ( $src and -f $src ) {
    my $s = decode( locale => $src );
    system( encode( locale => qq[$GET_NOVEL -f "$s" -w "$writer" -b "$book" -o $html_f $o{G}] ) );
  } elsif($src) {
    system( encode( locale => qq[$GET_NOVEL -u "$src" -w "$writer" -b "$book" -o $html_f $o{G}] ) );
  } else {
    system( encode( locale => qq[$GET_NOVEL -s "$o{s}" -w "$writer" -b "$book" -o $html_f $o{G}] ) );
  }

  my $min_id='';
  if($o{G} and ($min_id) = $o{G}=~m#-i\s+(\d+)-#){
      $book.="-$min_id" if($min_id and $min_id>1);
  }

  $o{o}=~s#/?$##;
  my $ebook_f = ($o{o} and -d $o{o}) ? "$o{o}/$writer-$book.$o{T}" : 
                $o{o} ? $o{o} : "$writer-$book.$o{T}";
  my ( $type ) = $ebook_f =~ /\.([^.]+)$/;

  return unless(-f $html_f and -s $html_f);

  #conv html to ebook
  my ( $fh_e, $f_e ) = $o{t}
    ? tempfile(
    "run_novel-ebook-XXXXXXXXXXXXXXXX",
    TMPDIR => 1,
    SUFFIX => ".$type"
    )
    : ( '', $ebook_f );
  print "conv to ebook $f_e\n";
  if ( $type ne 'html' ) {
    system( encode( locale => qq[conv_novel.pl -f "$html_f" -T "$f_e" -w "$writer" -b "$book" $o{C}] ) );
    unlink( $html_f );
  } else {
    rename( $html_f, $f_e );
  }
  return $f_e;
} ## end sub get_ebook

sub send_ebook {
  my ( $f_e, $msg, %o ) = @_;

  print "send ebook : $msg, $f_e, $o{t}\n";
  my $cmd = qq[sendEmail -u "$msg" -m "$msg" -a "$f_e" -t "$o{t}" $o{S}];
  if ( $o{h} ) {
    system( qq[ansible $o{h} -m copy -a 'src=$f_e dest=/tmp/'] );
    system( encode( locale => qq[ansible $o{h} -m shell -a '$cmd'] ) );
    system( qq[ansible $o{h} -m shell -a 'rm $f_e'] );
  } else {
    $cmd = encode( locale => $cmd );
    system($cmd);
  }
  unlink( $f_e );
}

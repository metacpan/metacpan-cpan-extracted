#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Getopt::Long qw(:config no_ignore_case);
use Novel::Robot;
use Data::Dumper;

$| = 1;
#binmode( STDIN,  ":encoding(console_in)" );
#binmode( STDOUT, ":encoding(console_out)" );
#binmode( STDERR, ":encoding(console_out)" );

my %opt;
GetOptions(
  \%opt,

  'site|s=s',       'url|u=s', 'file|f=s', 'writer|w=s', 'book|b=s',
  'type|t=s',       'output|o=s',
  'item|i=s',       'page|j=s', 'cookie|c=s',
  'not_download|D', 'verbose|v',
  'progress',

  'use_chrome',
  'with_toc', 'grep_content=s', 'filter_content=s', 'only_poster', 'min_content_word_num=i',
  'max_process_num=i',
  'chapter_regex=s',
  'content_path=s',  'writer_path=s',  'book_path=s', 'item_list_path=s',
  'content_regex=s', 'writer_regex=s', 'book_regex=s',

  'query_type|q=s', 'query_keyword|k=s', 'board|B=s', 

  # remote ansible host
  #'remote|R=s',

    # mail
    'mail_msg|m=s',
    'mail_server|M=s',
    'mail_port|p=s',
    'mail_usr|U=s',
    'mail_pwd|P=s',
    'mail_from|F=s', 'mail_to|T=s',
);

%opt = read_option( %opt );

our $xs = Novel::Robot->new( %opt );
if ( $opt{cookie} ) {
  my ( $dom, $base_dom ) = $xs->{parser}->detect_domain( $xs->{parser}->domain() || $opt{url} );
  $xs->{browser}->read_moz_cookie( $opt{cookie}, $base_dom );
}

my ( $outf, $bookr );
if ( $opt{file} ) {
  if ( $opt{site} eq 'txt' ) {
    my @path = split ',', $opt{file};
    ( $outf, $bookr ) = $xs->get_novel( \@path, %opt );
  } else {
    $xs->{packer}->convert_novel( $opt{file}, $opt{output}, \%opt );
  }
} elsif ( $opt{url} ) {
  if ( $opt{not_download} ) {
    my $r = $xs->{parser}->get_novel_info( $opt{url}, %opt, max_page_num => 1 );
    print join( ",", $r->{writer} || '', $r->{book} || $r->{title} || '', $r->{url} || '', $r->{item_num} || '' ), "\n";
  } else {
    ( $outf, $bookr ) = $xs->get_novel( $opt{url}, %opt );
  }
} elsif ( $opt{site} and $opt{writer} and $opt{book} ) {
  ( $outf, $bookr ) = $xs->get_novel( "$opt{writer}:$opt{book}", %opt );
} elsif ( defined $opt{query_keyword} or defined $opt{board}) {
    my $info_ref;
    if(defined $opt{query_keyword}){
        $info_ref  = $xs->{parser}->get_query_ref( $opt{query_keyword}, %opt );
    }else{
        $info_ref = $xs->{parser}->get_board_ref($opt{board}, %opt);
    }

    my $items_ref = $info_ref->{item_list};

  for my $r ( @$items_ref ) {
    my $u = $r->{url};
    next unless($u);
    if ( $opt{not_download} ) {
      print encode(locale=>join( ",", $r->{writer} // $info_ref->{writer} // 'unknown', $r->{book} // $r->{title}, $r->{url} )), "\n";
    } else {
      $xs->get_novel( $u, %opt );
    }
  }
}

if($opt{mail_to} and -f $outf){
    send_novel( $outf, $bookr, %opt );
}

sub send_novel {
  my ( $outf, $bookr, %o ) = @_;

  my $msg = qq[$bookr->{writer}-$bookr->{book}-$bookr->{item_num}] ;
  my $outfname= decode(locale=>$outf);

  my $cmd = qq[calibre-smtp -a "$outfname" -s "$msg" --relay $o{mail_server} --port $o{mail_port} -u "$o{mail_usr}" -p "$o{mail_pwd}" "$o{mail_from}" "$o{mail_to}" "$msg"];
  print encode(locale=>$cmd), "\n";

  system( $cmd );
    
  unlink($outf) if($o{url});

}

sub read_option {
  my ( %opt ) = @_;
  $opt{site} ||= $opt{url} || $opt{file} || $opt{board};
  $opt{type} ||= 'html';
  $opt{with_toc}        //= 1;
  $opt{progress}        //= 0;
  $opt{max_process_num} //= 1;
  $opt{verbose}         //= 0;

  for my $k (
    qw/writer writer_path writer_regex book book_path book_regex content_path content_regex item_list_path
    chapter_regex
    grep_content filter_content
    query_keyword query_type
    /
  ) {
    next unless ( exists $opt{$k} );
    $opt{$k} = decode( locale => $opt{$k} );
  }

  if ( $opt{page} ) {
    @opt{qw/min_page_num max_page_num/} = Novel::Robot::split_index( $opt{page} );
  }

  if ( $opt{item} ) {
    @opt{qw/min_item_num max_item_num/} = Novel::Robot::split_index( $opt{item} );
  }

  if ( $opt{file} ) {
    my $tf = decode( locale => $opt{file} );
    my ( $tw, $tb, $suffix ) = $tf =~ m#([^\/\\]+)-([^\/\\]+)\.([^.]+)$#;
    $opt{writer} = $tw unless ( defined $opt{writer} );
    $opt{book}   = $tb unless ( defined $opt{book} );
  }

  return %opt;
} ## end sub read_option

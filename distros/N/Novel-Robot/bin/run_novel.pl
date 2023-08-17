#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Data::Dumper;
use Encode::Locale;
use Encode;
use File::Copy;
use File::Temp qw/tempfile /;
use FindBin;
use Getopt::Long qw(:config no_ignore_case);
use Novel::Robot;
use POSIX qw/ceil/;
#use Smart::Comments;

$| = 1;
#binmode( STDIN,  ":encoding(console_in)" );
#binmode( STDOUT, ":encoding(console_out)" );
#binmode( STDERR, ":encoding(console_out)" );

our $GET_NOVEL = "$FindBin::RealBin/get_novel.pl ";
our $CONV_NOVEL = "$FindBin::RealBin/conv_novel.pl ";
our $SEND_NOVEL = "$FindBin::RealBin/send_novel.pl ";

my %opt;
GetOptions(
    \%opt,
    'site|s=s', 'url|u=s', 'file|f=s', 'writer|w=s', 'book|b=s',
    'type|t=s', 'output|o=s',
    'item|i=s', 'page|j=s', 'cookie|c=s',
    'not_download|D', 'verbose|v',
    'term_progress_bar', 

    'board|B=s', 

    'use_chrome', 
    'with_toc', 'grep_content=s', 'filter_content=s', 'only_poster', 'min_content_word_num=i',
    'max_process_num=i', 
    'chapter_regex=s', 
    'content_path=s',  'writer_path=s',  'book_path=s', 'item_list_path=s',
    'content_regex=s', 'writer_regex=s', 'book_regex=s',

    # query type, keyword
    'query|q=s', 'keyword|k=s', 

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

#%opt = read_option(%opt);

main_ebook( %opt );

sub main_ebook {
my ( %o ) = @_;

my %get_opt = map { $_ => $o{$_} } grep { ! /^mail_/ } keys( %o );
$get_opt{verbose}=1;
my $o_str = join( " ", map { qq[--$_  "$get_opt{$_}"] } keys(%get_opt));

my $msg = `$GET_NOVEL $o_str`;
my %m = map { split /:\s+/, $_ } (split /\n/, $msg);

if($o{mail_to} and -f $m{output}){
    $o{mail_attach} //= $m{output};
    $o{mail_msg} //= $m{info};
    my $o_str = join( " ", map { qq[--$_  "$o{$_}"] } grep { /^mail_/ } keys( %o ) );
    system(qq[$SEND_NOVEL $o_str]);
    if($o{url}=~/^https?:/){
        unlink($m{output});
    }
}

return $m{output};
} ## end sub main_ebook

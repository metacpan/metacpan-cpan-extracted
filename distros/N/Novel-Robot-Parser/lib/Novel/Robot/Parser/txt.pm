# ABSTRACT: txt parser
=pod

=encoding utf8

=head1 FUNCTION

=head2 parse_novel

解析txt
  
  my $txt_content_ref = $self->parse_novel(
    [ '/somedir/', '/someotherdir/somefile.txt' ], 
	writer => 'some_writer',
    book => 'some_book',
    chapter_regex => qr/(第\d+章)/, 
   );


=cut
package Novel::Robot::Parser::txt;
use strict;
use warnings;
use base 'Novel::Robot::Parser';

use File::Find::Rule;
use Encode;
use Encode::Locale;
use Encode::Detect::CJK qw/detect/;
use utf8;


sub parse_novel {
    my ($self, $path, %opt) = @_;
    $opt{chapter_regex} ||= get_default_chapter_regex();

    my %data;
    $data{writer} = $opt{writer} || 'unknown';
    $data{book} = $opt{book} || 'unknown';

    my $p_ref = ref($path) eq 'ARRAY' ? $path : [ $path ];
    for my $p (@$p_ref){
        my @txts = sort File::Find::Rule->file()->in($p);
        for my $txt (@txts){
            my $txt_data_ref = $self->read_single_txt($txt, %opt);
            my $txt_file = decode(locale => $txt);
            for my $t (@$txt_data_ref){
                #$t->{url} = $txt_file;
                push @{$data{floor_list}}, $t;
            }
        }
    }

    $self->update_url_list($data{floor_list});

    #$data{url} = '';

    return \%data;
}

sub get_default_chapter_regex { 
    #指定分割章节的正则表达式

    #序号
    my $r_num =
qr/[０１２３４５６７８９零○〇一二三四五六七八九十百千\d]+/;
    my $r_split = qr/[上中下]/;
	my $r_not_chap_head = qr/引子|楔子|尾声|内容简介|正文|番外|终章|序言|后记|文案/;

    #第x章，卷x，第x章(大结局)，尾声x
    my $r_head = qr/(卷|第|$r_not_chap_head)?/;
    my $r_tail  = qr/(章|卷|回|部|折)?/;
    my $r_post  = qr/([.\s\-\(\/（]+.{0,35})?/;
    my $regex_a = qr/(【?$r_head\s*$r_num\s*$r_tail$r_post】?)/;

    #(1)，(1)xxx
    #xxx(1)，xxx(1)yyy
    #(1-上|中|下)
    my $regex_b_index = qr/[(（]$r_num[）)]/;
    my $regex_b_tail  = qr/$regex_b_index\s*\S+/;
    my $regex_b_head  = qr/\S+\s*$regex_b_index.{0,10}/;
    my $regex_b_split = qr/[(（]$r_num[-－]$r_split[）)]/;
    my $regex_b = qr/$regex_b_head|$regex_b_tail|$regex_b_index|$regex_b_split/;

    #1、xxx，一、xxx
    my $regex_c = qr/$r_num[、．. ].{0,10}/;

    #第x卷 xxx 第x章 xxx
    #第x卷/第x章 xxx
    my $regex_d = qr/($regex_a(\s+.{0,10})?){2}/;

	#后记 xxx
	my $regex_e = qr/(【?$r_not_chap_head\s*$r_post】?)/;

	#总体
    my $chap_r = qr/^\s*($regex_a|$regex_b|$regex_c|$regex_d|$regex_e)\s*$/m;

    return $chap_r;
 }



sub read_single_txt {

    #读入单个txt文件
    my ($self, $txt, %opt) = @_;

    my $charset = $self->detect_file_charset($txt);
    open my $sh, "<:encoding($charset)", $txt;

    my @data;
    my ( $single_toc, $single_content ) = ( '', '' );

    #第一章
    while (<$sh>) {
        next unless /\S/;
        $single_toc = /$opt{chapter_regex}/ ? $1 : $_;
        last;
    } ## end while (<$sh>)

    #后续章节
    while (<$sh>) {
        next unless /\S/;
        if ( my ($new_single_toc) = /$opt{chapter_regex}/ ) {
            if ( $single_toc =~ /\S/ and $single_content =~ /\S/s ) {
                push @data, { title => $single_toc, content => $single_content };
                $single_toc = '';
            } ## end if ( $single_toc =~ /\S/...)
            $single_toc .= $new_single_toc . "\n";
            $single_content = '';
        }
        else {
            $single_content .= $_;
        } ## end else [ if ( my ($new_single_toc...))]
    } ## end while (<$sh>)

    push @data, { title => $single_toc, content => $single_content };
    $self->format_chapter_content($_) for @data;

    return \@data;
} ## end sub read_single_txt

sub format_chapter_content {
    my ($self, $r) = @_;
    for ($r->{content}) {
        s#<br\s*/?\s*>#\n#gi;
        s#\s*(.*\S)\s*#<p>$1</p>\n#gm;
        s#<p>\s*</p>##g;
    } ## end for ($chap_c)

    return $self;
}

sub detect_file_charset {
    my ($self, $file) = @_;
    open my $fh, '<', $file;
    read $fh, my $text, 360;
    return detect($text);
} ## end sub detect_file_charset

1;

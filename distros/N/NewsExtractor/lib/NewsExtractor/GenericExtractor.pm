package NewsExtractor::GenericExtractor;
use v5.18;
use utf8;

use Moo;
extends 'NewsExtractor::TXExtractor';

use HTML::ExtractContent;
use Mojo::DOM;
use NewsExtractor::Types qw(is_NewspaperName);

use Importer 'NewsExtractor::TextUtil'  => qw( u normalize_whitespace parse_dateline_ymdhms );
use Importer 'NewsExtractor::Constants' => qw( %RE );

with 'NewsExtractor::Role::ContentTextExtractor';

no Moo;

sub headline {
    my ($self) = @_;

    my ($title, $el);
    my $dom = $self->dom;
    if ($el = $dom->at("#story #news_title, #news_are .newsin_title, .data_midlle_news_box01 dl td:first-child")) {
        $title = $el->text;
    } elsif ($el = $dom->at("meta[property='og:title']")) {
        $title = $el->attr("content");
    } elsif ($el = $dom->at("meta[name='title']")) {
        $title = $el->attr('content');
    } elsif ($el = $dom->at("title")) {
        $title = $el->text;
    } else {
        return;
    }
    $title .= "";

    if (my $site_name = $self->site_name) {
        $title =~ s/\s* \p{Punct} \s* $site_name \s* \z//x;
    }
    if (defined($title)) {
        my $delim = qr<(?: \p{Punct} | \| | │ )>x;
        $title =~ s/ \s* $delim \s* $RE{newspaper_names} \s* \z//x;
        $title =~ s/\A $RE{newspaper_names} \s* $delim \s* //x;
        $title =~ s/\r\n/\n/g;
        $title =~ s/\A\s+//;
        $title =~ s/\s+\z//;
    }
    return $title && normalize_whitespace($title);
}

sub dateline {
    my ($self) = @_;
    my $dateline;
    my $guess;

    my $dom = $self->dom;
    if ($guess = $dom->at("meta[property='article:modified_time'], meta[property='article:published_time'], meta[itemprop=dateModified][content], meta[itemprop=datePublished][content]")) {
        $dateline = $guess->attr('content');
    }
    elsif ($guess = $dom->at("time[itemprop=datePublished][datetime], h1 time[datetime], .func_time time[pubdate], span.time > time.post-published")) {
        $dateline = $guess->attr('datetime');
    }
    elsif ($guess = $dom->at(".reporter time, span.viewtime, header.article-desc time, .timeBox .updatetime span, .caption div.label-date, .contents_page span.date, .main-content span.date, .newsin_date, .news .date, .author .date, ul.info > li.date > span:nth-child(2), #newsHeadline span.datetime, article p.date, .post-meta > .icon-clock > span, .article_info_content span.info_time, .content time.page-date, .c_time, .newsContent p.time, div.title > div.time, div.article-meta div.article-date, address.authorInfor time, .entry-meta .date a, .author-links .posts-date, .top_title span.post_time, .node-inner > .submitted > span")) {
        $dateline = $guess->text;
    }
    elsif ($guess = $dom->at("div#articles cite")) {
        $guess->at("a")->remove;
        $dateline = $guess->text;
    }
    elsif ($guess = $dom->at("article.ndArticle_leftColumn div.ndArticle_creat, ul.info li.date, .cpInfo .cp, .nsa3 .tt27")) {
        ($dateline) = $guess->text =~ m#([0-9]{4}[\-/][0-9]{2}[\-/][0-9]{2} [0-9]{2}:[0-9]{2})#;
    }
    elsif ($guess = $dom->at(".news-toolbar .news-toolbar__cell")) {
        ($dateline) = $guess->text =~ m#([0-9]{4}/[0-9]{2}/[0-9]{2})#;
    }
    elsif ($guess = $dom->at(".content .writer span:nth-child(2)")) {
        ($dateline) = $guess->text =~ m#([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2})#;
    }
    elsif ($guess = $dom->at("div.content-wrapper-right > div > div > div:nth-child(4)")) {
        ($dateline) = $guess->text =~ m#([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})#;
    }
    elsif ($guess = $dom->at("span#ctl00_ContentPlaceHolder1_News_Label, #ctl00_ContentPlaceHolder1_UpdatePanel2 font[color=darkred]")) {
        ($dateline) = $guess->text =~ m#([0-9]{4}/[0-9]{1,2}/[0-9]{1,2})#;
    }
    elsif ($guess = $dom->at(".news-info dd.date:nth-child(6)")) {
        ($dateline) = $guess->text =~ m#([0-9]{4}年[0-9]{1,2}月[0-9]{1,2}日[0-9]{2}:[0-9]{2})#;
    }
    elsif ($guess = $dom->at("article.entry-content div:nth-child(2)")) {
        ($dateline) = $guess->text =~ m#([0-9]{4}-[0-9]{1,2}-[0-9]{1,2})#;
    }
    elsif ($guess = $dom->at("span.submitted-by")) {
        # www.thinkingtaiwan.com
        my ($month, $day, $year) = $guess->text =~ m/([0-9]+)/g;
        $dateline = u(
            sprintf(
                '%04d-%02d-%02dT%02d:%02d:%02d%s',
                $year, $month, $day, 23, 59, 59, '+08:00'
            )
        );
    }
    elsif ($guess = $dom->at('#story #news_author')) {
        ($dateline) = $guess->all_text =~ m{\A 【記者.+ 】\s* (.+) \z}x;
    }
    elsif ($guess = $dom->at('.data_midlle_news_box01 dl dd ul li:first-child')) {
        ($dateline) = $guess->text;
        my ($year, $mmdd) = $dateline =~ /\A ([0-9]{3}) - (.+) \z /x;
        $year += 1911;
        $dateline = $year . '-' . $mmdd;
    }
    elsif ($guess = $dom->at('#details_block .left .date, .article_header > .author > span:last-child')) {
        $dateline = normalize_whitespace $guess->text;
    }
    elsif ($guess = $dom->at(
        join(','
             , '.timebox > .publishtime'  # howlife.cna.com.tw
             , 'div.newsInfo > span.time' # n.yam.com
        ))) {
        $dateline = parse_dateline_ymdhms($guess->all_text, '+08:00');
    }

    if ($dateline) {
        $dateline = normalize_whitespace($dateline);

        $dateline =~ s<\A ([0-9]{4}) (\p{Punct}) ([0-9]{1,2}) \2 ([0-9]{1,2}) \z>< sprintf('%04d-%02d-%02d', $1, $3, $4) >ex;

        if ($dateline =~ /^([0-9]{4})[^0-9]/) {
            if ($1 > ((localtime)[5] + 1900)) {
                $dateline = undef;
            }
        }
    }

    return $dateline;
}

sub journalist {
    my ($self) = @_;

    my $dom = $self->dom;
    my ($ret, $guess);

    if ( $guess = $dom->at('meta[property="og:article:author"]') ) {
        $ret = $guess->attr('content');
    } elsif ( $guess = $dom->at('meta[name="author"]') ) {
        $ret = $guess->attr('content');
    } elsif ( $guess = $dom->at('.bt_xmic span[itemprop=author], div.tdb_single_author a.tdb-author-name, div.field-item a[href^=/author/], div.content_reporter a[itemprop=author], span[itemprop=author] a, div.author div.intro a div.name, div.article-author > h5 > a, div.article-meta > div.article-author > a, div.authorInfo li.authorName > a, .article .writer > p, .info_author, .news-info dd[itemprop=author], .content_reporter a, .top_title span.reporter_name, .post-heading time span, header .article-meta .article-author,  .article_header > .author > span:first-child, .mid-news > .m-left-side > .maintype-wapper > .subtype-sort, .newsCon > .newsInfo > span:first-child, .newsdetail_content > .title > h4 > a[href^="/news/searchresult/news?search_text="], .m-from-author > .m-from-author__name, .post-author-name a[itemprop*=author], a.post-author-avatar .post-author-name > b, div#news_content div.author') ) {
        $ret = $guess->text;
    } elsif ($guess = $dom->at('div#yt_container_placeholder + p')) {
        ($ret) = $guess->text =~ m{\A \s* (.+) \s+ 報導 \s+ / }x;
    } elsif ($guess = $dom->at('h4.font_color5')) {
        ($ret) = $guess->all_text =~ m{\A \s* 編輯 \s* (.+) \s+ 報導 }x;
    } elsif ($guess = $dom->at('#story #news_author')) {
        ($ret) = $guess->all_text =~ m{\A 【 (記者 .+) 】}x;
    } elsif ($guess = $dom->at('#details_block .left .name, .articleMain .article-author a.author-title, .article__credit a[href^="/author/"], span[itemprop=author] span[itemprop=name], .post-header-additional .post-meta-info a.nickname')) {
        $ret = $guess->text;
    } elsif ($guess = $dom->at('div.single-post-meta a[rel="author"]')) {
        ($ret) = $guess->text =~ m<^工商時報 (.+)\z>x;
    } elsif ($guess = $dom->at('#PostContent .head-section-content p.meta')) {
        ($ret) = $guess->text =~ m<(記者.+?報導)>x;
    }

    $ret = undef if ($ret && is_NewspaperName($ret));

    if ( !$ret && (my $content_text = $self->content_text)) {
        my @patterns = (
            qr<\b (?:特[約派])? [记記]者 \s* ([\s\p{Letter}、]+?) \s* [/╱／] \s* (?: 特稿 | 專訪 | \p{Letter}+ (?:報導|报导)) \b>xs,
            qr<\A 【(記者.+?報導)】>x,
            qr<\A 中評社 .+? \d+ 月 \d+ 日電（記者(.+?)）>x,
            qr<\A ( 記者[^／]+／.+?電 )>x,
            qr<\A 匯流新聞網記者 (\p{Letter}+) ／(?:\p{Letter}+)報導 >x,
            qr<\A 匯流新聞網記者\s*/\s*(\p{Letter}+)綜合報導>x,
            qr<（(中央社[记記]者 \S+ 日 專?[電电] | 大纪元记者\p{Letter}+报导 | 記者.+?報導/.+?)）>x,
            qr< \( ( \p{Letter}+ ／ \p{Letter}+ 報導 ) \) >x,
            qr<\A 文：記者(\p{Letter}+) \n>x,
            qr<（ (譯者：.+?/核稿：.+?) ）[0-9]+(?:\n|\z)>x,
            qr< \(記者 (.+?) \) \z >x,
            qr<^(編譯[^／]+?／.+?報導)$>xsm,
            qr<（( (?:譯者|編輯)：.+) ） (?:[0-9]{7})? \z >x,
            qr<（記者 (\p{Letter}+) ） \z>x,
            qr< （記者 (\p{Letter}+) 綜合報導）\s+ （ (責任編輯：\p{Letter}+) ） \z>x,
            qr< （ (責任編輯：\p{Letter}+) ）\z>x,
            qr< \s (公民記者 .+ 採訪報導) \z>x,
            qr<\A 【大成報記者 (\p{Letter}+) / .+報導】 >x,
            qr<\A  記者 (\p{Letter}+) ／報導 >x,
            qr<\A  \[ (記者.+報導) \] >x,
            qr<\A  （ (記者.+報導) ） >x,
            qr<\A 【(本報記者.+報導)】 >x,
            qr<\b ﹝記者(\p{Letter}+?)／.+?報導﹞ \b>x,
            qr<\A〔新網記者 ( \p{Letter}+ (?:報導|特稿))〕\b>x,
            qr<\A（芋傳媒記者(\p{Letter}+)報導）\b>x,
            qr<\b文\s*／\s*(\p{Letter}+)\s*（中央社編譯）\n>x,
            qr<\A 香港中通社[0-9]+月[0-9]+日電（記者\s(\p{Letter}+)）>x,
            qr<\A \( (記者\p{Letter}+報導) \)>x,
        );

        for my $pat (@patterns) {
            ($ret) = $content_text =~ m/$pat/;
            last if $ret;
        }

        unless ($ret) {
            my ($guess) = $content_text =~ m{（(\p{Letter}+)）\z}xsm;
            if ($guess && $dom->descendant_nodes->first(sub { $_->type eq 'text' && $_->content =~ m<記者${guess}\b> })) {
                $ret = $guess
            }
        }
    }

    if ($ret) {
        $ret = normalize_whitespace($ret);
        $ret = "" if is_NewspaperName($ret);
    }

    return $ret;
}

1;

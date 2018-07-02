use utf8;
use warnings;
no warnings 'redefine';
use vars qw( $m_sAkt $m_nLength $m_nReplyId );
use Search::Tools::UTF8;
use HTML::Entities;
use Authen::Captcha;

sub show {
    my $threadlength = $m_oDatabase->tableLength('news');
    my $lpp =
        defined param('links_pro_page')
      ? param('links_pro_page') =~ /(\d\d?\d?)/
          ? $1
          : $m_hrSettings->{news}{messages}
      : $m_hrSettings->{news}{messages};
    $m_nStart = $m_nStart >= $threadlength       ? $threadlength - $lpp : $m_nStart;
    $m_nEnd   = $m_nStart + $lpp > $threadlength ? $threadlength        : $m_nStart + $lpp;
    my %needed = (
        action => 'news',
        start  => $m_nStart,
        end    => $m_nEnd,
        thread => 'news',
        id     => 'c',
    );
    print showThread( \%needed );
    my $catlist   = readcats('news');
    my %parameter = (
        action => 'addNews',
        body   => translate('body'),
        class  => 'max',
        attach => $m_nRight >= $m_hrSettings->{uploads}{right}
        ? $m_hrSettings->{uploads}{enabled}
        : 0,
        path     => "$m_hrSettings->{cgi}{bin}/templates",
        reply    => 'none',
        server   => $m_hrSettings->{cgi}{serverName},
        style    => $m_sStyle,
        thread   => 'news',
        headline => translate('headline'),
        title    => translate('newMessage'),
        catlist  => $catlist,
        right    => $m_nRight,
        html     => 0,
        atemp    => qq(<input  name="von" value="$m_nStart" style="display:none;"/><input  name="bis" value="$m_nEnd" style="display:none;"/>),
    );
    my $editor = new HTML::Editor( \%parameter );
    print '<div align="center">';
    print $editor->show() if ( $m_nRight >= $m_hrSettings->{news}{right} );
    print '</div>';
} ## end sub show

sub addNews {
    my $sbm = param('submit') ? param('submit') : 'save';
    if ( not defined $sbm or ( $sbm ne translate('preview') ) ) {
        if (   defined param('message')
            && defined param('headline')
            && defined param('thread')
            && defined param('catlist') ) {
            my $message  = param('message');
            my $headline = param('headline');
            $headline =
              ( $headline =~ /^(.{3,100})$/s )
              ? $1
              : translate('invalidHeadline');
            my $thread = param('thread');
            $thread = ( $thread =~ /^(\w+)$/ ) ? $1 : 'news';
            my @cat = param('catlist');
            my $cat = join '|', @cat;
            &saveUpload() if $m_nRight >= $m_hrSettings->{uploads}{right};
            unless ( is_valid_utf8($headline) ) { utf8::encode($headline); }
            unless ( is_valid_utf8($message) )  { utf8::encode($message); }
            $headline = encode_entities( $headline, '<>&' );
            my $attach =
                ( defined param('file') )
              ? ( split( /[\\\/]/, param('file') ) )[-1]
              : 0;
            my $cit  = ( defined $attach ) ? $attach =~ /^(\S+)\.[^\.]+$/ ? $1 : 0 : 0;
            my $type = ( defined $attach ) ? ( $attach =~ /\.([^\.]+)$/ ) ? $1 : 0 : 0;
            $cit =~ s/("|'|\s| )//g;
            my $sra = ( $cit && $type ) ? "$cit.$type" : undef;
            my $format = param('format') eq 'on' ? 'html' : 'markdown';
            unless ( is_valid_utf8($headline) ) { utf8::encode($headline); }
            unless ( is_valid_utf8($body) )     { utf8::encode($body); }

            if (   defined $headline
                && defined $message
                && defined $thread
                && $m_nRight >= $m_hrSettings->{news}{right} ) {
                my %message = (
                    title  => $headline,
                    body   => $message,
                    thread => $thread,
                    user   => $m_sUser,
                    cat    => $cat,
                    attach => $sra,
                    format => $format,
                    ip     => remote_addr()
                );
                if ( $m_oDatabase->addMessage( \%message ) ) {
                    my $tx = translate('newMessageReleased');
                    print qq|<div align="center">$tx<br/></div>|;
                } else {
                    print '<div align="center">' . translate('floodtext') . '<br/></div>';
                } ## end else [ if ( $m_oDatabase->addMessage...)]
            } ## end if ( defined $headline...)
        } ## end if ( defined param('message'...))
        &show();
    } else {
        &preview();
    } ## end else [ if ( not defined $sbm ...)]
} ## end sub addNews

sub saveedit {
    if ( not defined param('submit')
        or ( param('submit') ne translate('preview') ) ) {
        my $thread = param('thread');
        $thread = ( $thread =~ /^(\w+)$/ ) ? $1 : 'news';
        my $id = param('reply');
        $id = ( $id =~ /^(\d+)$/ ) ? $1 : 0;
        my $headline = param('headline');
        $headline = ( $headline =~ /^(.{3,50})$/ ) ? $1 : 0;
        my $body = param('message');
        unless ( is_valid_utf8($headline) ) { utf8::encode($headline); }
        unless ( is_valid_utf8($body) )     { utf8::encode($body); }
        $headline = encode_entities( $headline, '<>&' );
        &saveUpload() if $m_nRight >= $m_hrSettings->{uploads}{right};
        my $attach =
          ( param('file') ) ? ( split( /[\\\/]/, param('file') ) )[-1] : 0;
        my $cit  = ( defined $attach ) ? $attach =~ /^(\S+)\.[^\.]+$/ ? $1 : 0 : 0;
        my $type = ( defined $attach ) ? ( $attach =~ /\.([^\.]+)$/ ) ? $1 : 0 : 0;
        $cit =~ s/("|'|\s| )//g;
        my $sra    = ( $cit && $type )       ? "$cit.$type" : undef;
        my $format = param('format') eq 'on' ? 'html'       : 'markdown';
        my @cat    = param('catlist');
        my $c = join '|', @cat;
        my %message = (
            thread     => $thread,
            title      => $headline,
            body       => $body,
            thread     => $thread,
            cat        => $c,
            attach     => $sra,
            format     => $format,
            id         => $id,
            user       => $m_sUser,
            ip         => remote_addr(),
            uploadpath => $m_hrSettings->{uploads}{path}
        );
        $m_oDatabase->editMessage( \%message );
        my $rid = $id;

        if ( $thread eq 'replies' ) {
            my @tid = $m_oDatabase->fetch_array("select refererId from  `replies` where id = '$id'");
            $rid = $tid[0];
        } ## end if ( $thread eq 'replies')
        &showMessage($rid);
    } else {
        &preview();
    } ## end else [ if ( not defined param...)]
} ## end sub saveedit

sub editNews {
    my $id = param('edit');
    $id = ( $id =~ /^(\d+)$/ ) ? $1 : 0;
    my $th = param('thread');
    $th = ( $th =~ /^(\w+)$/ ) ? $1 : 'news';
    if ( not defined param('submit')
        or ( param('submit') ne translate('preview') ) and $th ) {
        my @data = $m_oDatabase->fetch_array(
            "select title,body,date,id,user,attach,format,cat from  `$th`  where `id` = '$id'  and  (`user` = '$m_sUser'  or `right` < '$m_nRight' );"
        );
        my $catlist   = readcats( $data[7] );
        my $html      = $data[6] eq 'html' ? 1 : 0;
        my %parameter = (
            action => 'saveedit',
            body   => $data[1],
            class  => 'max',
            attach => $m_nRight >= $m_hrSettings->{uploads}{right}
            ? $m_hrSettings->{uploads}{enabled}
            : '',
            path     => "$m_hrSettings->{cgi}{bin}/templates",
            reply    => $id,
            server   => $m_hrSettings->{cgi}{serverName},
            style    => $m_sStyle,
            thread   => $th,
            headline => $data[0],
            title    => translate('editMessage'),
            right    => $m_nRight,
            catlist  => ( $th eq 'news' ) ? $catlist : ' ',
            html     => $html,
            atemp    => qq(<input  name="von" value="$m_nStart" style="display:none;"/><input  name="bis" value="$m_nEnd" style="display:none;"/>),
        );
        my $editor = new HTML::Editor( \%parameter );
        print '<div align="center"><br/>';
        print $editor->show();
        print '</div>';
    } else {
        &preview();
    } ## end else [ if ( not defined param...)]
    my $rid = $id;
    if ( $th eq 'replies' ) {
        my @tid = $m_oDatabase->fetch_array( "select refererId from  `replies` where id = ?", $id );
        $rid = $tid[0];
    } ## end if ( $th eq 'replies' )
    &showMessage($rid);
} ## end sub editNews

sub replyNews {
    my $id = param('reply');
    $id = ( $id =~ /^(\d+)$/ ) ? $1 : 0;
    my $th = param('thread');
    $th = ( $th =~ /^(\w+)$/ ) ? $1 : 'news';
    my $attachment;
    if ( $m_nRight <= 2 ) {
        my $captcha = Authen::Captcha->new(
            data_folder   => "$m_hrSettings->{cgi}{bin}/config/",
            output_folder => "$m_hrSettings->{cgi}{DocumentRoot}/images",
            expire        => 300
        );
        my $md5sum = $captcha->generate_code(3);
        $attachment =
qq|<input size="5" type="hidden" name="md5" value="$md5sum"/><div align="center"><img src="$m_hrSettings->{cgi}{serverName}/images/$md5sum.png" border="0"/><br/><br/><input size="5"" name="captcha" value=""/></div>|;
    } ## end if ( $m_nRight <= 2 )
    my %parameter = (
        action   => 'addreply',
        body     => translate('insertText'),
        class    => 'max',
        attach   => $attachment,
        path     => "$m_hrSettings->{cgi}{bin}/templates",
        reply    => $id,
        server   => $m_hrSettings->{cgi}{serverName},
        style    => $m_sStyle,
        thread   => $th,
        headline => translate('headline'),
        title    => translate('reply'),
        right    => $m_nRight,
        catlist  => '',
        html     => 0,
        atemp    => qq(<input  name="von" value="$m_nStart" style="display:none;"/><input  name="bis" value="$m_nEnd" style="display:none;"/>),
    );
    my $editor = new HTML::Editor( \%parameter );
    print '<div align="center"><br/>';
    print $editor->show();
    print '</div>';
    &saveUpload() if $m_nRight >= $m_hrSettings->{uploads}{right};
    &showMessage($id);
} ## end sub replyNews

sub addReply {
    my $body     = param('message');
    my $headline = param('headline');
    unless ( is_valid_utf8($headline) ) { utf8::encode($headline); }
    unless ( is_valid_utf8($body) )     { utf8::encode($body); }
    $headline = encode_entities( $headline, '<>&' );
    my $reply  = param('reply');
    my $format = 'markdown';
    if ( defined param('format') ) {
        $format = 'html' if param('format') eq 'on';
    } ## end if ( defined param('format'...))
    my $result = 0;
    if ( $m_nRight <= 2 ) {
        my $captcha = Authen::Captcha->new(
            data_folder   => "$m_hrSettings->{cgi}{bin}/config/",
            output_folder => "$m_hrSettings->{cgi}{DocumentRoot}/images"
        );
        $result = $captcha->check_code( param("captcha"), param("md5") );
        $result = 1
          if $@;

        # skip captcha without gd
    } else {
        $result = 1;
    } ## end else [ if ( $m_nRight <= 2 ) ]
    print div( { align => 'center' }, translate('Codenotchecked') )
      if $result eq 0;
    print div( { align => 'center' }, translate('Failedcodeexpired') )
      if $result eq -1;
    print div( { align => 'center' }, translate('Failednotindatabase') )
      if $result eq -2;
    print div( { align => 'center' }, translate('Failedinvalidcode') )
      if $result eq -3;
    my $submit = param('submit') ? param('submit') : 'save';
    if ( $submit ne translate('preview') && $result eq 1 ) {
        if ( upload('file') ) {
            my $attach = ( split( /[\\\/]/, param('file') ) )[-1];
            my $cit  = $attach =~ /^(\S+)\.[^\.]+$/ ? $1 : 0;
            my $type = ( $attach =~ /\.([^\.]+)$/ ) ? $1 : 0;
            $cit =~ s/("|'|\s| )//g;
            my $sra   = "$cit.$type";
            my %reply = (
                title  => $headline,
                body   => $body,
                id     => $reply,
                user   => $m_sUser,
                attach => $sra,
                format => $format,
                ip     => remote_addr(),
            );
            $m_oDatabase->reply( \%reply );
        } else {
            my %reply = (
                title  => $headline,
                body   => $body,
                id     => $reply,
                user   => $m_sUser,
                format => $format,
                ip     => remote_addr(),
            );
            $m_oDatabase->reply( \%reply );
        } ## end else [ if ( upload('file') ) ]
        &saveUpload() if $m_nRight >= $m_hrSettings->{uploads}{right};
    } else {
        &preview();
    } ## end else [ if ( $submit ne translate...)]
    &showMessage($reply);
} ## end sub addReply

sub deleteNews {
    my $th = param('thread');
    $th = ( $th =~ /^(\w+)$/ ) ? $1 : 'news';
    my $del = param('delete');
    $del = ( $del =~ /^(\d+)$/ ) ? $1 : 0;
    my $trash = $m_oDatabase->fetch_hashref( 'select * from news where id = ?', $del );
    $m_oDatabase->void(
        "insert into trash (`title`,`body`,`attach`,`cat`,`right`,`user`,`action`,`format`,`date`,`oldId`,`table` ) values(?,?,?,?,?,?,?,?,?,?,?)",
        $trash->{title},  $trash->{body},   $trash->{attach}, $trash->{cat}, $trash->{right}, $trash->{user},
        $trash->{action}, $trash->{format}, $trash->{date},   $trash->{id},  $th
    );
    $m_oDatabase->deleteMessage( $th, $del );
    my @a_hr = $m_oDatabase->fetch_AoH( "select * from `replies` where refererId = ?", $del );

    foreach my $hr_reply (@a_hr) {
        $m_oDatabase->void(
            "insert into trash (`title`,`body`,`attach`,`cat`,`right`,`user`,`format`,`refererId`,`date`,`id`,`table`) values(?,?,?,?,?,?,?,?,?,?)",
            $hr_reply->{title},
            $hr_reply->{body},
            $hr_reply->{attach},
            $hr_reply->{cat},
            $hr_reply->{right},
            $hr_reply->{user},
            $hr_reply->{format},
            $hr_reply->{refererId},
            $hr_reply->{date},
            $hr_reply->{oldId},
            'replies'
        );
        $m_oDatabase->deleteMessage( 'replies', $hr_reply->{id} );
    } ## end foreach my $hr_reply (@a_hr)
    &show();
} ## end sub deleteNews

sub showMessage {
    my $id = $_[0] ? shift : defined param('reply')
      && param('reply') =~ /(\d+)/ ? $1 : 0;
    my $qcats = $m_oDatabase->fetch_string( "SELECT cats FROM users where user = ?", $m_sUser );
    $qcats = $m_oDatabase->quote($qcats);
    my $sql_read = qq/select title,body,date,id,user,attach,format from  news where `id` = $id && `right` <= $m_nRight && cat REGEXP($qcats)/;
    my $ref      = $m_oDatabase->fetch_hashref($sql_read);
    if ( $ref->{id} eq $id ) {
        my $m_sTitle = $ref->{title};
        $ref->{body} =~ s/\[previewende\]//s;
        if ( $ref->{format} eq 'markdown' ) { Markdown( \$ref->{body} ); }
        my $menu       = "";
        my $answerlink = "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=reply&reply=$ref->{id}&thread=news')";
        my %reply      = (
            title    => translate('reply'),
            descr    => translate('reply'),
            src      => 'e96a',
            location => $answerlink,
            style    => $m_sStyle,
        );
        my $thread = defined param('thread') ? param('thread') : 'news';
        $menu .= action( \%reply )
          unless ( $thread =~ /.*\d$/ && $m_nRight < 5 );
        my $editlink =
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=edit&edit=$ref->{id}&thread=news&von=$m_nStart&bis=$m_nEnd;')";
        my %edit = (
            title    => translate('edit'),
            descr    => translate('edit'),
            src      => 'e905',
            location => $editlink,
            style    => $m_sStyle,
        );
        $menu .= action( \%edit ) if ( $m_nRight >= 5 );
        my $trdelete = translate('delete');
        my $deletelink =
"javascript:confirm2('$trdelete ?',requestURI,'$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=delete&delete=$ref->{id}&thread=news&von=$m_nStart&bis=$m_nEnd','delete','delete')";
        my %delete = (
            title    => translate('delete'),
            descr    => translate('delete'),
            src      => 'e9ac',
            location => $deletelink,
            style    => $m_sStyle,
        );
        $menu .= action( \%delete ) if ( $m_nRight >= 5 );
        print br()
          . qq(<table class="ShowTables"><tr><td class="headline">$ref->{title}</td></tr><tr><td align="left" class="batch">$menu</td></tr><tr><td align="left"><table align="left" border ="0" cellpadding="0" cellspacing="0" summary="user_date" width="100%"><tr><td align="left" class="username">$ref->{user}</td><td align="right" class="date">$ref->{date}</td></tr></table></td></tr><tr><td align="left">$ref->{body}</td></tr>);
        print qq(<tr><td><a target="_blank" href="download/$ref->{attach}">$ref->{attach}</a></td></tr>)
          if ( -e "$m_hrSettings->{uploads}{path}/$ref->{attach}" );
        print '</table>';
        my @rps = $m_oDatabase->fetch_array( "select count(*) from replies where refererId = ?;", $id );

        if ( $rps[0] > 0 ) {
            $m_nStart = $m_nStart > $rps[0] ? $rps[0] - 1 : $m_nStart;
            my %needed = (
                action  => 'showthread',
                start   => $m_nStart,
                end     => $m_nEnd,
                thread  => 'replies',
                replyId => $id,
                id      => 'c',
            );
            print showThread( \%needed );
        } ## end if ( $rps[0] > 0 )
    } else {
        &show();
    } ## end else [ if ( $ref->{id} eq $id)]
} ## end sub showMessage

# privat
sub readcats {
    my $selected = lc(shift);
    my @select = split /\|/, $selected;
    my %sel;
    $sel{$_} = 1 foreach @select;
    my @cats = $m_oDatabase->fetch_AoH( "select * from cats where `right` <= ?", $m_nRight );
    my $cat  = translate('catslist');
    my $list = qq|<select name="catlist" size="5" class="selectpicker" multiple >|;
    for ( my $i = 0 ; $i <= $#cats ; $i++ ) {
        my $catname = lc( $cats[$i]->{name} );
        $list .=
          $sel{$catname}
          ? qq(<option value="$catname" selected="selected">$catname</option>)
          : qq(<option value="$catname">$catname</option>);
    } ## end for ( my $i = 0 ; $i <=...)
    $list .= '</select>';
    return $list;
} ## end sub readcats

sub preview {
    my $thread = param('thread');
    $thread = ( $thread =~ /^(\w+)$/ ) ? $1 : 'news';
    my $id = param('reply');
    $id = ( $id =~ /^(\d+)$/ ) ? $1 : 0;
    my $headline = param('headline');
    $headline = ( $headline =~ /^(.{3,50})$/ ) ? $1 : 0;
    my $body    = param('message');
    my @cat     = param('catlist');
    my $cat     = join '|', @cat;
    my $catlist = $m_sAction ne 'addreply' ? readcats($cat) : ' ';
    print '<br/>';
    my $html = defined param('format') ? param('format') : 'off';
    $html = $html eq 'on' ? 1 : 0;
    my $previewBody = $body;

    unless ($html) {
        Markdown( \$previewBody );
    } ## end unless ($html)

    #Don't works fine on win32
    if ( !is_valid_utf8($body) || $^O eq 'MSWin32' ) {
        utf8::encode($body);
    } ## end if ( !is_valid_utf8($body...))
    if ( !is_valid_utf8($headline) || $^O eq 'MSWin32' ) {
        utf8::encode($previewHeadline);
    } ## end if ( !is_valid_utf8($headline...))
    $previewHeadline = encode_entities( $headline, '<>&' );
    print
qq(<table class="ShowTables" style="padding:1%;"><tr><td class="headline">$previewHeadline</td></tr><tr><td align="left">$previewBody</td></tr></table>);
    my $attachment;
    if ( $m_nRight <= 2 ) {
        my $captcha = Authen::Captcha->new(
            data_folder   => "$m_hrSettings->{cgi}{bin}/config/",
            output_folder => "$m_hrSettings->{cgi}{DocumentRoot}/images",
            expire        => 300,
        );
        my $md5sum = $captcha->generate_code('3');
        $attachment =
qq|<input size="5" type="hidden" name="md5" value="$md5sum"/><div align="center"><img src="$m_hrSettings->{cgi}{serverName}/$m_hrSettings->{cgi}{prefix}/images/$md5sum.png" border="0"/><br/><br/><input size="5"" name="captcha" value=""/></div>|;
    } ## end if ( $m_nRight <= 2 )
    #
    my %parameter = (
        action   => $m_sAction,
        body     => $body,
        class    => 'max',
        attach   => $attachment,
        path     => "$m_hrSettings->{cgi}{bin}/templates",
        reply    => $id,
        server   => $m_hrSettings->{cgi}{serverName},
        style    => $m_sStyle,
        thread   => $thread,
        headline => $headline,
        title    => translate("editMessage"),
        right    => $m_nRight,
        catlist  => ( $thread eq 'news' ) ? $catlist : '',
        html     => $html,
        template => 'editor.htm',
        atemp    => qq(<input  name="von" value="$m_nStart" style="display:none;"/><input  name="bis" value="$m_nEnd" style="display:none;"/>),
    );
    my $editor = new HTML::Editor( \%parameter );
    print '<div align="center">';
    print $editor->show();
    print '</div>';
} ## end sub preview

sub showThread {
    my $needed = shift;
    $m_sAkt     = $needed->{action};
    $m_nEnd     = $needed->{end};
    $m_nStart   = $needed->{start};
    $thread     = $needed->{thread};
    $m_nReplyId = $needed->{replyId};
    $replylink  = defined $m_nReplyId ? "&reply=$m_nReplyId" : ' ';
    my $qcats = $m_oDatabase->fetch_string( "SELECT cats FROM users where user = ?", $m_sUser );
    $qcats = $m_oDatabase->quote($qcats);
    my @rp = $m_oDatabase->fetch_array("select count(*) from news where `right` <= $m_nRight && cat REGEXP($qcats)");
    $m_nLength = $rp[0] =~ /(\d+)/ ? $rp[0] : 0 unless ( $thread eq 'replies' );

    if ( defined $needed->{replyId} ) {
        my @rps = $m_oDatabase->fetch_array("select count(*) from replies where refererId = $needed->{replyId};");
        if   ( $rps[0] > 0 ) { $m_nLength = $rps[0]; }
        else                 { $m_nLength = 0; }
    } ## end if ( defined $needed->...)
    $m_nLength = 0 unless ( defined $m_nLength );
    my $lpp =
        defined param('links_pro_page')
      ? param('links_pro_page') =~ /(\d\d?\d?)/
          ? $1
          : $m_hrSettings->{news}{messages}
      : $m_hrSettings->{news}{messages};
    my $itht = '<table align="center" border ="0" cellpadding ="0" cellspacing="0" summary="showThread" width="100%" >';
    $itht .= Tr(
        td(
            div(
                { align => 'right' },
                ( $m_nLength > 5 ? translate('news_pro_page') . ' | ' : '' )
                  . (
                    $m_nLength > 5
                    ? a(
                        {
                            href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=$m_sAkt&links_pro_page=5&von=$m_nStart$replylink','news','news')",
                            class => ( $lpp eq 5 ? 'menuLink2' : 'menuLink3' )
                        },
                        '5'
                      )
                      . ' '
                    : ''
                  )
                  . (
                    $m_nLength > 9
                    ? a(
                        {
                            href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=$m_sAkt&links_pro_page=10&von=$m_nStart$replylink','news','news')",
                            class => ( $lpp eq 10 ? 'menuLink2' : 'menuLink3' )
                        },
                        '10'
                      )
                      . ' '
                    : ''
                  )
                  . (
                    $m_nLength > 29
                    ? a(
                        {
                            href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=$m_sAkt&links_pro_page=30&von=$m_nStart$replylink','news','news')",
                            class => ( $lpp eq 30 ? 'menuLink2' : 'menuLink3' )
                        },
                        '30'
                      )
                    : ''
                  )
            )
        )
    );
    my %needed = (
        start          => $m_nStart,
        length         => $m_nLength,
        style          => $m_sStyle,
        action         => $m_sAkt,
        append         => "links_pro_page=$lpp$replylink",
        path           => $m_hrSettings->{cgi}{bin},
        links_pro_page => $lpp,
        server         => "$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}",
    );
    my $pages = makePages( \%needed );
    $itht .= '<tr><td style="padding:5px;">' . $pages . '</td></tr>';
    $itht .= '<tr><td>' . threadBody($thread) . '</td></tr>';
    $itht .= '<tr><td style="padding:5px;">' . $pages . '</td></tr>';
    $itht .= '</table>';
    return $itht;
} ## end sub showThread

sub threadBody {
    my $th = shift;
    my $output;
    if ( ( $m_oDatabase->tableExists($th) ) ) {
        $output .= '<table border="0" cellpadding="0" cellspacing="0" summary="contentLayout" width="100%">';
        my $lpp =
            defined param('links_pro_page')
          ? param('links_pro_page') =~ /(\d\d?\d?)/
              ? $1
              : $m_hrSettings->{news}{messages}
          : $m_hrSettings->{news}{messages};
        my $qcats = $m_oDatabase->fetch_string( "SELECT cats FROM users where user = ?", $m_sUser );
        $qcats = $m_oDatabase->quote($qcats);
        $qcats = $qcats ? $qcats : 'news';
        my $answers =
          defined $m_nReplyId
          ? " && refererId =$m_nReplyId"
          : "&& cat REGEXP($qcats)";
        my $sql_read =
          qq/select title,body,date,id,user,attach,format from $th where `right` <= $m_nRight $answers  order by date desc LIMIT $m_nStart,$lpp /;
        my $sth = $m_dbh->prepare($sql_read);
        $sth->execute() or warn $m_dbh->errstr;
        return '' if $m_dbh->errstr;

        while ( my @data = $sth->fetchrow_array() ) {
            my $headline    = $data[0];
            my $body        = $data[1];
            my $date        = $data[2];
            my $id          = $data[3];
            my $m_sUsername = $data[4];
            my $attach      = $data[5];
            my $format      = $data[6];
            my $replylink   = "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=showthread&reply=$id&thread=$th')";
            my $answer      = translate('answers');
            my @rps         = $m_oDatabase->fetch_array("select count(*) from replies where refererId = $id;");
            my $reply =
              ( ( $rps[0] > 0 ) && $th eq 'news' )
              ? qq(<br/><a href="$replylink" class="replylink" >$answer:$rps[0]</a>)
              : '<br/>';
            my $menu = "";

            if ( $th ne 'replies' ) {
                my $answerlink =
                  "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=reply&reply=$id&thread=$th','reply','reply')";
                my %reply = (
                    title    => translate('reply'),
                    descr    => translate('reply'),
                    src      => 'e96a',
                    location => $answerlink,
                    style    => $m_sStyle,
                );
                $menu .= action( \%reply );
            } ## end if ( $th ne 'replies' )
            my $txtEdit = translate('edit');
            my $editlink =
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=edit&edit=$id&thread=$th&von=$m_nStart&bis=$m_nEnd;','edit','edit')";
            my %edit = (
                title    => $txtEdit,
                descr    => $txtEdit,
                src      => 'e905',
                location => $editlink,
                style    => $m_sStyle,
            );
            $menu .= action( \%edit ) if ( $m_nRight > 1 );
            my $trdelete = translate('delete');
            my $deletelink =
"javascript:confirm2('$trdelete ?',requestURI,'$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=delete&delete=$id&thread=$th&von=$m_nStart&bis=$m_nEnd','$trdelete','$trdelete')";
            my %delete = (
                title    => translate('delete'),
                descr    => translate('delete'),
                src      => 'e9ac',
                location => $deletelink,
                style    => $m_sStyle,
            );
            $menu .= action( \%delete ) if ( $m_nRight >= 5 );
            my $h1       = qq(<tr id="trw$id"><td valign="top">);
            my $readmore = translate('readmore');
            $reply .= qq( <a href="$replylink" class="link" >$readmore</a>)
              if $body =~ /\[previewende\]/i && $thread eq 'news';
            if ( $format eq 'markdown' ) { Markdown( \$body ); }
            $h1 .=
qq(<table class="ShowTables" style="padding:1%;"><tr><td class="headline">$headline</td></tr><tr><td align="left" >$menu</td></tr><tr><td align="left"><table align="left" border ="0" cellpadding="0" cellspacing="0" summary="user_datum"  width="100%"><tr><td align="left" class="username">$m_sUsername</td><td align="right" class="date">$date</td></tr></table></td></tr><tr><td align="left">$body</td></tr>);
            $h1 .= qq(<tr><td><a target="_blank" href="download/$attach">$attach</a></td></tr>)
              if ( -e "$m_hrSettings->{uploads}{path}/$attach" );
            $h1     .= qq(<tr><td align="left">$reply</td></tr></table>);
            $output .= qq|$h1</td></tr>|;
        } ## end while ( my @data = $sth->...)
        $output .= '</table>';
    } ## end if ( ( $m_oDatabase->tableExists...))
    return $output;
} ## end sub threadBody

sub saveUpload {
    my $ufi = param('file');
    if ( $m_nRight >= $m_hrSettings->{news}{uploadright} ) {
        if ( upload('file') ) {
            my $attach = ( split( /[\\\/]/, param('file') ) )[-1];
            my $cit  = $attach =~ /^(\S+)\.[^\.]+$/ ? $1 : 0;
            my $type = ( $attach =~ /\.([^\.]+)$/ ) ? $1 : 0;
            $cit =~ s/("|'|\s| )//g;
            my $sra = "$cit.$type";
            my $up  = upload('file');
            use Symbol;
            my $fh = gensym();
            open $fh, ">$m_hrSettings->{uploads}{path}/$sra.bak"
              or warn "news.pl::saveUpload: $!";
            while (<$up>) { print $fh $_; }
            close $fh;
            rename "$m_hrSettings->{uploads}{path}/$sra.bak", "$m_hrSettings->{uploads}{path}/$cit.$type"
              or warn "news.pl::saveUpload: $!";
            chmod( "$m_hrSettings->{'uploads'}{'chmod'}", "$m_hrSettings->{uploads}{path}/$sra" )
              if ( -e "$m_hrSettings->{uploads}{path}/$sra" );
        } ## end if ( upload('file') )
    } ## end if ( $m_nRight >= $m_hrSettings...)
} ## end sub saveUpload

sub trash {
    my @trash = $m_oDatabase->fetch_AoH('select * from trash');
    print
qq(    <div class="ShowTables marginTop">    <form action="$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}" onsubmit="return false" method="get" enctype="multipart/form-data">    <input type="hidden" name="action" value="rebuildtrash"/>    <table align="center" border ="0" cellpadding="0" cellspacing="0" summary="threadBody"  width="100%">        <tr>        <td class="caption captionLeft"></td>        <td class="caption">title</td>        <td class="caption">date</td>        <td class="caption">user</td>        <td class="caption">table</td>        <td class="caption">oldId</td>        <td class="caption">refererId</td>        <td class="caption">cat</td>        <td class="caption captionRight"></td>        </tr>        );
    for ( my $i = 0 ; $i <= $#trash ; $i++ ) {
        my $rebuild = translate('rebuild');
        my $delete  = translate('delete');
        unless ( is_valid_utf8( $trash[$i]->{title} ) ) {
            utf8::encode( $trash[$i]->{title} );
        } ## end unless ( is_valid_utf8( $trash...))
        print
qq(<tr>                <td style="padding-left:1%;"><input type="checkbox" name="markBox$i" class="markBox" value="$trash[$i]->{id}" /></td>                <td>$trash[$i]->{title}</td>                <td>$trash[$i]->{date}</td>                <td>$trash[$i]->{user}</td>                <td>$trash[$i]->{table}</td>                <td align="center">$trash[$i]->{oldId}</td>                <td align="center">$trash[$i]->{refererId}</td>                <td align="center">$trash[$i]->{cat}</td>                <td align="right" style="padding-right:1%;"><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=rebuildtrash&id=$trash[$i]->{id}','news','news')" width="50">$rebuild</a> <a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=DeleteEntry&table=trash&&id=$trash[$i]->{id}','news','$m_sTitle');">$delete</a></td>                </tr>);
    } ## end for ( my $i = 0 ; $i <=...)
    my $delete   = translate('delete');
    my $mmark    = translate('selected');
    my $markAll  = translate('select_all');
    my $umarkAll = translate('unselect_all');
    my $rebuild  = translate('rebuild');
    print
qq{                <td colspan="9" style="padding-left:1%;">                <table align="center" border="0" cellpadding="0"  cellspacing="0" summary="layout" width="100%" ><tr>                <td align="left"><a id="markAll" href="javascript:markInput(true);" class="links">$markAll</a><a class="links" id="umarkAll" style="display:none;" href="javascript:markInput(false);">$umarkAll</a>                </td><td align="right" style="padding-right:1%;">                <select  name="MultipleRebuild"  onchange="if(this.value != '$mmark' )submitForm(this.form,'rebuildtrash','rebuildtrash');">                <option  value="$mmark" selected="selected">$mmark</option>                <option value="delete">$delete</option>                <option value="rebuild">$rebuild</option>                </select>                </form>                </td></tr></table>                };
    print '</table></div>';
} ## end sub trash

sub rebuildtrash {
    unless ( param("MultipleRebuild") ) {
        my $id = param('id');
        my $trash = $m_oDatabase->fetch_hashref( 'select * from trash where id = ?', $id );
        if ( $trash->{table} eq 'news' ) {
            $m_oDatabase->void(
                "insert into news (`title`,`body`,`attach`,`cat`,`right`,`user`,`action`,`format`,`date`) values(?,?,?,?,?,?,?,?,?)",
                $trash->{title}, $trash->{body},   $trash->{attach}, $trash->{cat}, $trash->{right},
                $trash->{user},  $trash->{action}, $trash->{format}, $trash->{date}
            );
            &trash();
            $m_oDatabase->void( "delete from ˋtrashˋ where id = ?", $id );
        } else {
            $m_oDatabase->void(
                "insert into replies (`title`,`body`,`attach`,`cat`,`right`,`user`,`format`,`refererId`,`date`) values(?,?,?,?,?,?,?,?,?)",
                $trash->{title}, $trash->{body},   $trash->{attach},    $trash->{cat}, $trash->{right},
                $trash->{user},  $trash->{format}, $trash->{refererId}, $trash->{date}
            );
            &showMessage( $trash->{refererId} );
            $m_oDatabase->void( "delete from ˋtrashˋ where id = ?", $id );
        } ## end else [ if ( $trash->{table} eq...)]
    } else {
        &multipleRebuild();
    } ## end else
} ## end sub rebuildtrash

=head2 multipleRebuild() 
    Action : multipleRebuild 
    
=cut

sub multipleRebuild {
    my $a      = param('MultipleRebuild');
    my @params = param();
    for ( my $i = 0 ; $i <= $#params ; $i++ ) {
        if ( $params[$i] =~ /markBox\d?/ ) {
            my $id = param( $params[$i] );
            my $trash = $m_oDatabase->fetch_hashref( 'select * from trash where id = ?', $id );
          SWITCH: {
                if ( $a eq "delete" ) {
                    $m_oDatabase->void( "delete from trash where id = ?", $id );
                    last SWITCH;
                } ## end if ( $a eq "delete" )
                if ( $a eq "rebuild" ) {
                    if ( $trash->{table} eq 'news' ) {
                        $m_oDatabase->void(
                            "insert into news (`title`,`body`,`attach`,`cat`,`right`,`user`,`action`,`format`,`date`) values(?,?,?,?,?,?,?,?,?)",
                            $trash->{title}, $trash->{body},   $trash->{attach}, $trash->{cat}, $trash->{right},
                            $trash->{user},  $trash->{action}, $trash->{format}, $trash->{date}
                        );
                        $m_oDatabase->void( "delete from trash where id = ?", $id );
                    } else {
                        $m_oDatabase->void(
"insert into replies (`title`,`body`,`attach`,`cat`,`right`,`user`,`format`,`refererId`,`date`) values(?,?,?,?,?,?,?,?,?)",
                            $trash->{title}, $trash->{body},   $trash->{attach},    $trash->{cat}, $trash->{right},
                            $trash->{user},  $trash->{format}, $trash->{refererId}, $trash->{date}
                        );
                        $m_oDatabase->void( "delete from trash where id = ?", $id );
                    } ## end else [ if ( $trash->{table} eq...)]
                    last SWITCH;
                } ## end if ( $a eq "rebuild" )
            } ## end SWITCH:
        } ## end if ( $params[$i] =~ /markBox\d?/)
    } ## end for ( my $i = 0 ; $i <=...)
    &show();
} ## end sub multipleRebuild
1;

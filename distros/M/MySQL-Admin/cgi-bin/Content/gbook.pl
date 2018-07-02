use utf8;
use warnings;
no warnings 'redefine';

sub newGbookEntry {
    my $message = param('message');
    $message = ( $message =~ /^(.{3,1000})$/s ) ? $1 : translate("gbook_body");
    my $headline = param('headline') ? param('headline') : translate('headline');
    $headline = ( $headline =~ /^(.{3,50})$/s ) ? $1 : translate('headline');
    my $attachment;
    eval( '
    use Authen::Captcha;
    my $captcha = Authen::Captcha->new(
    data_folder   => "$m_hrSettings->{cgi}{bin}/config/",
    output_folder => "$m_hrSettings->{cgi}{DocumentRoot}/images",
    expire        => 300);
    my $md5sum = $captcha->generate_code(3);
    $attachment = qq|
    <input size="5" type="hidden" name="md5" value="$md5sum"/>
    <div align="center"><img style="height:35px;" src="$m_hrSettings->{cgi}{serverName}/$m_hrSettings->{cgi}{prefix}/images/$md5sum.png" border="0"/>
    <br/>
    <input size="5"" name="captcha" value=""/></div>|;
    ' );
    my %parameter = (
        attach    => $attachment,
        action    => "addnewGbookEntry",
        body      => $message,
        class     => 'max',
        maxlength => 1000,
        path      => "$m_hrSettings->{cgi}{bin}/templates",
        server    => $m_hrSettings->{cgi}{serverName},
        style     => $m_sStyle,
        thread    => 'gbook',
        headline  => $headline,
        title     => translate("Gbook"),
        right     => 0,
        catlist   => '',
        html      => 0,
        atemp     => qq(<input  name="von" value="$m_nStart" style="display:none;"/><input  name="bis" value="$m_nEnd" style="display:none;"/>)
    );
    use HTML::Editor;
    my $editor = new HTML::Editor( \%parameter );
    print '<div align="center marginTop"><script language="JavaScript1.5" type="text/javascript">html = 1;bbcode = false;</script>';
    print $editor->show();
    print '</div>';
} ## end sub newGbookEntry

sub addnewGbookEntry {
    my $message = param('message');
    $message = ( $message =~ /^(.{3,1000})$/s ) ? $1 : 'Invalid body';
    my $headline = param('headline');
    $headline = ( $headline =~ /^(.{3,50})$/s ) ? $1 : 'Invalid headline';
    if ( ( param('submit') ne translate('preview') ) ) {
        for ( my $i = 0 ; $i <= $#data ; $i++ ) {
            unless ( utf8::is_utf8( $data[$i] ) ) {
                utf8::decode( $data[$i] );
            } ## end unless ( utf8::is_utf8( $data...))
        } ## end for ( my $i = 0 ; $i <=...)
        $m_oDatabase->floodtime(5);
        if ( $m_oDatabase->checkFlood( remote_addr() ) ) {
            my $m_bCaptcha = 0;
            eval( '
	    use Authen::Captcha;
	    my $captcha = Authen::Captcha->new(data_folder   => "$m_hrSettings->{cgi}{bin}/config/",
					      output_folder => "$m_hrSettings->{cgi}{DocumentRoot}/images");
	    $m_bCaptcha = $captcha->check_code(param("captcha"), param("md5"));
	    ' );
            $m_bCaptcha = 1 if $@;
            print div( { align => 'center' }, translate('Codenotcheckedfileerror') )
              if $m_bCaptcha eq 0;
            print div( { align => 'center' }, translate('Codenotcheckedfileerror') )
              if $m_bCaptcha eq -1;
            print div( { align => 'center' }, translate('Failednotindatabase') ) if $m_bCaptcha eq -2;
            print div( { align => 'center' }, translate('Failedinvalidcode') )   if $m_bCaptcha eq -3;
            my $sql = q/INSERT INTO gbook (`title`,`body`,`user`) VALUES (?,?,?)/;
            $m_oDatabase->void( $sql, $headline, $message, $m_sUser ) if ( $m_bCaptcha eq 1 );
            &showGbook();
        } else {
            print translate('floodtext');
            &showGbook();
        } ## end else [ if ( $m_oDatabase->checkFlood...)]
    } else {
        my $bbcode = $message;
        utf8::decode($bbcode) unless ( utf8::is_utf8($bbcode) );
        BBCODE( \$bbcode, $m_nRight );
        print qq(
<table class="ShowTables" style="padding:1%;width:100%" >
<tr><td align="left">$headline</td></tr>
<tr><td align="left">$bbcode</td></tr>
</table>);
        my $attachment;
        eval( '
      use Authen::Captcha;
      my $captcha = Authen::Captcha->new(
      data_folder   => "$m_hrSettings->{cgi}{bin}/config/",
      output_folder => "$m_hrSettings->{cgi}{DocumentRoot}/images",
      expire        => 300);
      my $md5sum = $captcha->generate_code(3);
      $attachment = qq|
 <input size="5" type="hidden" name="md5" value="$md5sum" /></div>
<div align="center" ><img style="height:35px;" src="$m_hrSettings->{cgi}{serverName}/$m_hrSettings->{cgi}{prefix}/images/$md5sum.png" border="0"/>
      <br/><br/>
      <input size="5"" name="captcha" value=""/></div>|;
      ' );
        my %parameter = (
            action    => 'addnewGbookEntry',
            body      => $message,
            class     => 'max',
            maxlength => 1000,
            path      => "$m_hrSettings->{cgi}{bin}/templates",
            server    => $m_hrSettings->{cgi}{serverName},
            style     => $m_sStyle,
            thread    => 'gbook',
            headline  => $headline,
            title     => translate('gbook'),
            right     => 0,
            catlist   => '',
            html      => 0,
            attach    => $attachment,
        );
        use HTML::Editor;
        my $editor = new HTML::Editor( \%parameter );
        print '<script language="JavaScript1.5" type="text/javascript">html = 1;bbcode = false;</script>';
        print $editor->show();
    } ## end else [ if ( ( param('submit')...))]
} ## end sub addnewGbookEntry

sub showGbook {
    my $length = $m_oDatabase->tableLength( 'gbook', 0 );
    &newGbookEntry();
    if ( $length > 0 ) {
        my %needed = (
            start          => $m_nStart,
            length         => $length,
            style          => $m_sStyle,
            action         => 'gbook',
            links_pro_page => 5,
            path           => $m_hrSettings->{cgi}{bin},
            server         => "$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}",
        );
        print makePages( \%needed );
        my $sql_read = qq/select title,body,date,id,user from  `gbook` order by date desc LIMIT $m_nStart,10 /;
        my $sth      = $m_dbh->prepare($sql_read);
        $sth->execute();
        while ( my @data = $sth->fetchrow_array() ) {
            for ( my $i = 1 ; $i <= $#data ; $i++ ) {
                unless ( utf8::is_utf8( $ref->{ $data[$i] } ) ) {
                    utf8::decode( $data[$i] );
                } ## end unless ( utf8::is_utf8( $ref...))
            } ## end for ( my $i = 1 ; $i <=...)
            my $headline    = $data[0];
            my $body        = $data[1];
            my $datum       = $data[2];
            my $id          = $data[3];
            my $m_sUsername = $data[4];
            BBCODE( \$body, $m_nRight );
            print qq(
<table class="ShowTables"style="padding:1%;width:100%;">
<tr>
  <td align="left">
    <table align="left" border ="0" cellpadding="0" cellspacing="0" summary="user_datum"  width="100%">
    <tr>
      <td align="left" class="headline">$headline</td>
      <td align="right" class="date">$datum</td>
    </tr>
    </table>
  </td>
</tr>
<tr><td align="left">$body</td></tr>
<tr><td align="left" class="username">$m_sUsername</td></tr>
</table>
);
        } ## end while ( my @data = $sth->...)
    } ## end if ( $length > 0 )
} ## end sub showGbook

use utf8;
use warnings;
no warnings 'redefine';

sub fulltext {
    my $search = param('query');
    print '<div align="center">';
    print br();
    my $ts      = translate('search');
    my $checked = defined param('regexp') ? 'checked="checked"' : '';
    my $regexp  = translate('regexp');
    print qq(
<div align="center">
<form action="$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}" onsubmit="submitForm(this,'fulltext','fulltext');return false;" name="search" accept-charset="UTF-8">
<input align="top" type="text" maxlength="100" title="$ts" name="query" id="query" value="$search"/><input type="submit"  name="submit" value="$ts" maxlength="15" alt="$ts" align="left" />
<input  type="hidden" name="action"  value="fulltext"/><br/>
$regexp: <input type="checkbox" $checked name="regexp" value="regexp" alt="regexp" align="left" />
</form></div>
);
    print br();
    my $qsearch = $m_oDatabase->quote($search);
    my @count =
      $search
      ? (
        ( defined param('regexp') )
        ? $m_oDatabase->fetch_array(
            "SELECT count(*) FROM news WHERE  `right` <= $m_nRight  && ( body REGEXP $qsearch || title REGEXP $qsearch )  order by date desc  ")
        : $m_oDatabase->fetch_array( "SELECT count(*) FROM news  where `right` <= $m_nRight and MATCH (title,body) AGAINST(?)", $search )
      )
      : 0;
    my $length = $count[0];

    if ( $length > 0 ) {
        print '<table align="center" border ="0" cellpadding ="0" cellspacing="0" summary="showThread" width="100%" >';
        print Tr(
            td(
                div(
                    { align => 'right' },
                    (
                        $length > 5
                        ? translate('news_pro_page') . '&#160;|&#160;'
                        : ''
                      )
                      . (
                        $length > 5
                        ? a(
                            {
                                href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=$akt&links_pro_page=5&von=$m_nStart$replylink','$akt','$akt')",
                                class => ( $lpp == 5 ? 'menuLink2' : 'menuLink3' )
                            },
                            '5'
                          )
                          . '&#160;'
                        : ''
                      )
                      . (
                        $length > 10
                        ? a(
                            {
                                href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=$akt&links_pro_page=10&von=$m_nStart$replylink','$akt','$akt')",
                                class => ( $lpp == 10 ? 'menuLink2' : 'menuLink3' )
                            },
                            '10'
                          )
                          . '&#160;'
                        : ''
                      )
                      . (
                        $length > 30
                        ? a(
                            {
                                href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=$akt&links_pro_page=30&von=$m_nStart$replylink','$akt','$akt')",
                                class => ( $lpp == 30 ? 'menuLink2' : 'menuLink3' )
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
            length         => $length,
            style          => $m_sStyle,
            action         => "fulltext",
            links_pro_page => $lpp,
            append         => "&query=$search" . ( defined param('regexp') ? '&regexp=regexp' : '' ),
            server         => "$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}",
        );
        my $pages = makePages( \%needed );
        print '<tr><td>' . $pages . '</td></tr>';
        if ( defined param('regexp') ) {
            print '<tr><td>' . $m_oDatabase->searchDB( $search, 'body', 'news', $m_nRight, $m_nStart, $m_nEnd ) . '</td></tr>';
        } else {
            print '<tr><td>' . $m_oDatabase->fulltext( $search, 'news', $m_nRight, $m_nStart, $m_nEnd ) . '</td></tr>';
        } ## end else [ if ( defined param('regexp'...))]
        print '<tr><td>' . $pages . '</td></tr>';
        print '</table>';
    } ## end if ( $length > 0 )
    print '</div>';
} ## end sub fulltext
1;

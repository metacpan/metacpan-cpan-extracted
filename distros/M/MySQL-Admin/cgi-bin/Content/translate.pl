use warnings;
no warnings 'redefine';
use vars qw($m_hrLng @l);
use CGI::QuickForm;
use utf8;
no warnings 'redefine';
no warnings 'uninitialized';
use Search::Tools::UTF8;
loadTranslate($m_hrSettings->{translate});
*m_hrLng = \$MySQL::Admin::Translate::lang;
my $title = translate('editTranslation');
my @translate;
my $lg = param('lang') ? param('lang') : 'de';
foreach my $key (sort keys %{$m_hrLng->{$lg}}) {
    push @translate,
      {
        -LABEL  => $key,
        -TYPE   => '',
        -values => $m_hrLng->{$lg}{$key},
      }
      unless $key eq 'action';
}
print '<div align="center" class="ShowTables marginTop">';

foreach my $key (sort keys %{$m_hrLng}) {
    push @l, $key;
    print a(
        {
         href =>
           "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=translate&lang=$key','translate','$key')"
        },
        $key
      )
      . '&#160;|&#160;';
}
my $addtranslate = translate('addTranslation');
print a(
    {
     href =>
       "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=showaddTranslation','translate','translate')"
    },
    $addtranslate
  )
  . '&#160;';
show_form(
         -HEADER   => qq(&#160;),
         -ACCEPT   => \&on_valid_form,
         -CHECK    => (param('checkFormsddfsds') ? 1 : 0),
         -LANGUAGE => $ACCEPT_LANGUAGE,
         -ONSUBMIT => "submitForm(this,'translate','" . translate('translate') . "');return false;",
         -FIELDS   => [
                     {
                      -LABEL   => 'action',
                      -default => 'translate',
                      -TYPE    => 'hidden',
                     },
                     {
                      -LABEL   => 'checkFormsddfsds',
                      -default => 'true',
                      -TYPE    => 'hidden',
                     },
                     {
                      -LABEL   => 'lang',
                      -default => $lg,
                      -TYPE    => 'hidden',
                     },
                     @translate,
                    ],
         -BUTTONS => [{-name => translate('save')},],
         -FOOTER  => '<br/>',
);
print qq|</div>|;

sub on_valid_form {
    my $savetranslate = translate('savetranslate');
    my $rs =
      "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=translate','$m_sAction','$savetranslate')";
    my %parameter = (
                     path   => $m_hrSettings->{cgi}{bin} . '/templates',
                     style  => $m_sStyle,
                     title  => $savetranslate,
                     server => $m_hrSettings->{serverName},
                     id     => 'savetranslate',
                     class  => 'max',
                    );
    print '<br/><div align="center" style="width:75%;"><b>'
      . translate('Done')
      . qq(&#160;<a href="$rs">)
      . translate('next')
      . '</a></b><br/><div align="left">';
    my @entrys = param();
    for (my $i = 0 ; $i <= $#entrys ; $i++) {
        my $rkey = lc $entrys[$i];
        delete $m_hrLng->{$lg}{$entrys[$i]};
        my $txt = param($entrys[$i]) ;
        utf8::encode( $txt);
        print "$rkey: " . $txt . '<br/>'
          unless $rkey eq 'sid'
          or $rkey eq 'action'
          or $rkey eq 'checkFormsddfsds';
        $m_hrLng->{$lg}{$rkey} =$txt 
          unless $rkey eq 'sid'
          or $rkey eq 'action'
          or $rkey eq 'checkFormsddfsds';
    }
   saveTranslate($m_hrSettings->{translate});
    print '</div></div>';
}
1;

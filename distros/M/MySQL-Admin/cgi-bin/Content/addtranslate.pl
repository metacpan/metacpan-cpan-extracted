use utf8;
use warnings;
no warnings 'redefine';
use vars qw($title $txt @l);
$title = translate('editTranslation');
print '<div class="ShowTables marginTop">';

loadTranslate($m_hrSettings->{translate});
*m_hrLng = \$MySQL::Admin::Translate::lang;

foreach my $key (sort keys %{$m_hrLng}) {
    push @l, $key;
}
$txt = translate('translate');
print start_form(
                 -method   => 'POST',
                 -onSubmit => "submitForm(this,'showaddTranslation','$txt');return false;",
                 -action   => "$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}"
                )
  . hidden({-name => 'action'}, 'showaddTranslation')
  . hidden(
           {
            -name    => 'do',
            -default => '1'
           },
           'true'
          )
  . table(
          {
           -align  => 'center',
           -border => 0,
           width   => '70%'
          },
          caption('Add translation'),
          Tr(
              {
               -align  => 'left',
               -valign => 'top'
              },
              td('Key'),
              td(
                  textfield(
                            {
                             -style => 'width:100%',
                             -name  => 'key'
                            },
                            'name'
                           )
                )
            ),
          Tr(
              {
               -align  => 'left',
               -valign => 'top'
              },
              td("Txt"),
              td(
                  textfield(
                            {
                             -style => 'width:100%',
                             -name  => 'txt'
                            },
                            'txt'
                           )
                )
            ),
          Tr(
              {
               -align  => 'left',
               -valign => 'top'
              },
              td('Language'),
              td(
                  popup_menu(
                             -onchange => 'setLang(this.options[this.options.selectedIndex].value)',
                             -name     => 'lang',
                             -values   => [@l],
                             -style    => 'width:100%'
                            ),
                )
            ),
          Tr(
              {
               -align  => 'right',
               -valign => 'top'
              },
              td({colspan => 2}, submit(-value => 'Add Translation'))
            )
         )
  . end_form;
if (param('do')) {
    my $key = param('key');
    my $txt = param('txt');
    my $lgn = param('lang');
    unless (defined $m_hrLng->{$lgn}{$key}) {
        $m_hrLng->{$lgn}{$key} = $txt;
        print "Translation added $lgn<br/>$key:  $m_hrLng->{$lgn}{$key}<br/>";
        saveTranslate($m_hrSettings->{translate});
        loadTranslate($m_hrSettings->{translate});
    } else {
        print "Key already defined<br/>$key:  $m_hrLng->{$lgn}{$key}<br/>";
    }

}
print '</div>';
1;

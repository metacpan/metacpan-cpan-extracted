use utf8;
use warnings;
no warnings 'redefine';
use vars qw($TITLE);
loadSettings("$m_hrSettings->{cgi}{bin}/config/settings.pl");
use vars qw($TITLE);
$TITLE = translate('settings');
show_form(
          -HEADER   => qq(<div class="ShowTables marginTop"><h2>$TITLE</h2>),
          -ACCEPT   => \&on_valid_form,
          -CHECK    => param('checkForm') ? 1 : 0,
          -LANGUAGE => $ACCEPT_LANGUAGE,
          -ONSUBMIT => "submitForm(this,'settings','" . translate('settings') . "');return false;",
          -FIELDS   => [
                      {
                       -LABEL   => 'action',
                       -default => 'settings',
                       -TYPE    => 'hidden',
                      },
                      {
                       -LABEL   => 'checkForm',
                       -default => 'true',
                       -TYPE    => 'hidden',
                      },
                      {
                       -LABEL    => 'Default Action',
                       -name     => 'defaultAction',
                       -default  => $m_hrSettings->{defaultAction},
                       -VALIDATE => \&validDefaultAction,
                      },
                      {
                       -LABEL    => 'CGI',
                       -HEADLINE => 1,
                       -COLSPAN  => 2,
                       -END_ROW  => 1,
                      },
                      {
                       -LABEL   => translate('homepageTitle'),
                       -name    => 'homepageTitle',
                       -default => $m_hrSettings->{cgi}{title},
                      },
                      {
                       -LABEL    => translate('DocumentRoot'),
                       -name     => 'documentRoot',
                       -VALIDATE => \&exits,
                       -default  => $m_hrSettings->{cgi}{DocumentRoot},
                      },
                      {
                       -LABEL    => 'cgi-bin',
                       -name     => 'cgi-bin',
                       -VALIDATE => \&exits,
                       -default  => $m_hrSettings->{cgi}{bin},
                      },
                      {
                       -LABEL    => translate('Style'),
                       -name     => 'style',
                       -VALIDATE => \&validStyle,
                       -default  => $m_hrSettings->{cgi}{style},
                      },
                      {
                       -LABEL   => translate('CookiePath'),
                       -name    => 'cookiePath',
                       -default => $m_hrSettings->{cgi}{cookiePath},
                      },
                      {
                       -LABEL   => translate('size'),
                       -name    => 'size',
                       -default => $m_hrSettings->{size},
                      },
                      {
                       -LABEL    => translate('htmlright'),
                       -name     => 'htmlright',
                       -VALIDATE => \&validInt,
                       -default  => $m_hrSettings->{htmlright},
                      },
                      {
                       -LABEL   => translate('ServerName'),
                       -name    => 'serverName',
                       -default => $m_hrSettings->{cgi}{serverName},
                      },
                      {
                       -LABEL    => 'admin',
                       -HEADLINE => 1,
                       -COLSPAN  => 2,
                       -END_ROW  => 1,
                      },
                      {
                       -LABEL   => translate('Email'),
                       -name    => 'email',
                       -default => $m_hrSettings->{admin}{email},
                      },
                      {
                       -LABEL    => 'News',
                       -HEADLINE => 1,
                       -COLSPAN  => 2,
                       -END_ROW  => 1,
                      },
                      {
                       -LABEL   => translate('uploadright'),
                       -name    => 'maxlength',
                       -default => $m_hrSettings->{news}{maxlength},
                      },
                      {
                       -LABEL    => translate('Uploads'),
                       -name     => 'uploads',
                       -HEADLINE => 1,
                       -COLSPAN  => 2,
                       -END_ROW  => 1,
                      },
                      {
                       -LABEL    => translate('activates'),
                       -name     => 'activates',
                       -TYPE     => 'scrolling_list',
                       '-values' => [
                                       ($m_hrSettings->{uploads}{enabled})
                                     ? ('Enabled', 'Disabled')
                                     : ('Disabled', 'Enabled')
                                    ],
                       -size      => 1,
                       -multiples => 0,
                       -VALIDATE  => \&enabledDisabled,
                      },
                      {
                       -LABEL   => translate('uploadChmod'),
                       -name    => 'uploadChmod',
                       -default => $m_hrSettings->{uploads}{chmod},
                      },
                      {
                       -LABEL   => translate('uploadSize'),
                       -name    => 'uploadSize',
                       -default => $m_hrSettings->{uploads}{size},
                      },
                      {
                       -LABEL   => translate('uploadPath'),
                       -name    => 'uploadPath',
                       -default => $m_hrSettings->{uploads}{path},
                      },
                      {
                       -LABEL   => translate('timebetweenPosts'),
                       -name    => 'floodtime',
                       -default => $m_hrSettings->{floodtime},
                      },
                      {
                       -LABEL    => translate('newsPerPage'),
                       -name     => 'messages',
                       -default  => $m_hrSettings->{news}{messages},
                       -VALIDATE => \&newsPerPage
                      },
                     ],
          -BUTTONS => [{-name => translate('save')},],
          -FOOTER  => '</div>',
         );

sub on_valid_form {
    $m_hrSettings->{cgi}{style}        = param('style');
    $m_hrSettings->{cgi}{title}        = param('homepageTitle');
    $m_hrSettings->{cgi}{DocumentRoot} = param('documentRoot');
    $m_hrSettings->{cgi}{bin}          = param('cgi-bin');
    $m_hrSettings->{size}              = param('size');
    $m_hrSettings->{admin}{email}      = param('email');
    $m_hrSettings->{admin}{name}       = param('name');
    $m_hrSettings->{cgi}{cookiePath}   = param('cookiePath');
    $m_hrSettings->{cgi}{serverName}   = param('serverName');
    $m_hrSettings->{htmlright}         = param('htmlright');
    $m_hrSettings->{floodtime}         = param('floodtime');
    $m_hrSettings->{news}{messages}    = param('messages');
    $m_hrSettings->{news}{uploadright} = param('uploadright');

    #general
    $m_hrSettings->{language}      = param('language');
    $m_hrSettings->{defaultAction} = param('defaultAction');

    #upload
    $m_hrSettings->{uploads}{chmod} = param('uploadChmod');
    $m_hrSettings->{uploads}{size}  = param('uploadSize');
    $m_hrSettings->{uploads}{path}  = param('uploadPath');

    MySQL::Admin::Settings::saveSettings("$m_hrSettings->{cgi}{bin}/config/settings.pl");
    $m_sStyle = $p1;
    my $rs = "javascript:requestURI('$ENV{SCRIPT_NAME}?action=settings','settings','settings')";
    print '<div class="ShowTables"><b>Done</b><br/>'
      . qq(<a href="$rs">)
      . translate('next') . '</a>';
    my @entrys = param();
    for (my $i = 0 ; $i <= $#entrys ; $i++) {
        print "$entrys[$i]: " . param($entrys[$i]) . '<br/>';
    }
    print qq(<a href="$rs">) . translate('next') . '</a></div>';
}
sub validStyle         { return -e "$m_hrSettings->{cgi}{DocumentRoot}/style/$_[0]"; }
sub exits              { return -e $_[0]; }
sub enabledDisabled    { $_[0] =~ /^(Enabled|Disabled)$/; }
sub acceptLanguage     { $_[0] =~ /^\w\w-?\w?\w?$/; }
sub validDefaultAction { $_[0] =~ /^\w+$/; }
sub validBox           { $_[0] =~ /^(left|right|disabled)$/; }
sub newsPerPage        { $_[0] =~ /^(5|10|30|100)$/; }
sub validhtmlright     { $_[0] =~ /^\d+$/; }
sub validInt           { $_[0] > 0 && $_[0] < 32766 }
1;


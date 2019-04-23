use utf8;
use warnings;
no warnings 'redefine';

sub reg {
    my $sUserRegName = param('username');
    $sUserRegName = ( $sUserRegName =~ /^(\w{3,10})$/ ) ? $1 : translate('insertname');
    $sUserRegName = lc $sUserRegName;
    my $email     = param('email');
    my $register  = translate('register');
    my $t_regtext = translate('t_regtext');
    my $disclaimer  = translate('disclaimer');
    print qq|
      <div class="dbForm">
      $t_regtext<br/>
      <form onsubmit="var self = this; disclaimer('$disclaimer', function(){ submitForm(self,'makeUser','makeUser');});return false;" method="get">
      <label for="username">Name</label><br/>
      <input type="text" name="username" id="username" value="$sUserRegName" size="20" maxlength="10" alt="Login" align="left"/>
      <br/>
      <label for="email">Email</label>
      <br/>
      <input type="text" name="email" value="$email" id="email" size="20" maxlength="200" alt="email" align="left"/><br/>
      <input type="hidden" name="action" value="makeUser"/>
      <br/>
      <input type="submit" name="submit" value="$register" size="15" alt="$register" align="left"/>
      </form>
      </div>
     |;
} ## end sub reg

sub lostPassword {
    my $email          = param('email');
    my $t_lostpassText = translate('register');
    my $t_lostpass     = translate('sendpassword');
    print qq(
      <div class="dbForm">
      $t_lostpassText<br/>
      <form onsubmit="submitForm(this,'makePassword','makePassword');return false;" >
      <label for="email">Email</label>
      <br/>
      <input type="text" name="email" value="$email" id="email" size="20" maxlength="200" alt="email" align="left"/><br/>
      <input type="hidden" name="action" value="makePassword"/>
      <br/>
      <input type="submit" name="submit" value="$t_lostpass" size="15" alt="$t_lostpass" align="left"/>
      </form>
      </div>
     );
} ## end sub lostPassword

sub makePassword {
    my $fr           = 0;
    my $sUserRegName = param('username');
    my $email        = param('email');
    my $tlt          = translate('register');
    my $hr_user      = $m_oDatabase->fetch_hashref( "select * from users where email = ?", $email );
    eval {
        use Mail::Sendmail;
        my %mail = (
            To      => "$email",
            From    => $m_hrSettings->{'admin'}{'email'},
            subject => translate('lostpass'),
            Message => translate('lostpassmessage') . translate('username') . ": $hr_user->{user} " . translate('password') . ":$hr_user->{pass}"
        );
        sendmail(%mail) or print $Mail::Sendmail::error;
    };
    print translate('sendpassword');
} ## end sub makePassword

sub make {
    my $fr           = 0;
    my $sUserRegName = param('username');
    my $email        = param('email');
    my $tlt          = translate('register');
  SWITCH: {
        if ( defined $sUserRegName ) {
            if ( $m_oDatabase->isMember($sUserRegName) ) {
                print translate('userexits');
                $fr           = 1;
                $sUserRegName = undef;
            } ## end if ( $m_oDatabase->isMember...)
        } else {
            print translate('wrongusername');
            $fr = 1;
        } ## end else [ if ( defined $sUserRegName)]
        unless ( defined $email ) {
            print translate('nomail');
            $fr = 1;
        } ## end unless ( defined $email )
        &reg() if ($fr);
        last SWITCH if ($fr);
        my $pass = int( rand(1000) + 1 ) x 3;
        eval {
            use Mail::Sendmail;
            my %mail = (
                To      => "$email",
                From    => $m_hrSettings->{'admin'}{'email'},
                subject => translate('mailsubject'),
                Message => translate('regmessage') . translate('username') . ": $sUserRegName " . translate('password') . ":$pass"
            );
            sendmail(%mail) or print $Mail::Sendmail::error;
        };
        $m_oDatabase->addUser( $sUserRegName, $pass, $email );
        my $trlogin = translate('next');
        my $authen  = '';
        eval {
            my $right_captcha_text = translate("right_captcha_text");
            my $wrong_captcha_text = translate("wrong_captcha_text");
            use Authen::Captcha;
            my $captcha = Authen::Captcha->new(
                data_folder   => "$m_hrSettings->{cgi}{bin}/config/",
                output_folder => "$m_hrSettings->{cgi}{DocumentRoot}/images",
                expire        => 300
            );
            my $md5sum = $captcha->generate_code(3);
            $authen = qq|<input size="5" type="hidden" name="md5" value="$md5sum"/>
        <label for="captcha">
        <img src="$m_hrSettings->{cgi}{serverName}/$m_hrSettings->{cgi}{prefix}/images/$md5sum.png" border="0" style="margin:0.2em;"/></label>
        <br/>
        <input style="width:40px;" autocomplete="off" onkeypress="if(enter(event))return false;" type="text" size="5" data-regexp="|
              . '/^.{3}$/' . qq|" data-error="$wrong_captcha_text" data-right="$right_captcha_text"  name="captcha"/>|;
        };
        print $@ if $@;
        print qq(<div align="left" id="form">
          <form  name="Login" onSubmit="m_sid ='123';submitForm(this,'login','login');return false;">
          <label for="user">Name</label>
          <br/>$sUserRegName
          <input type="hidden" id="user" name="user" value="$sUserRegName"/><br/>
          <label for="password">Password</label><br/>$pass
          <input type="hidden" name="action" value="login"/>
          <input type="hidden" id="password" name="pass" value ="$pass"/>
          <br/>
          $authen
          <br/>
          <input type="submit" name="submit" value="$trlogin" size="15" maxlength="15" alt="submit" align="left"/></form></div>);
    } ## end SWITCH:
} ## end sub make
1;

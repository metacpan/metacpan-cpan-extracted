use utf8;
use warnings;
no warnings 'redefine';
if ($m_nRight < 1) {
    my $trlogin             = translate('login');
    my $password            = translate('password');
    my $name                = translate('name');
    my $right_username_text = translate('right_username_text');
    my $wrong_username_text = translate('wrong_username_text');
    my $right_passwort_text = translate('right_passwort_text');
    my $wrong_passwort_text = translate('wrong_passwort_text');
    my $authen              = '';
    eval{
      my $right_captcha_text = translate("right_captcha_text");
      my $wrong_captcha_text = translate("wrong_captcha_text");
      use Authen::Captcha;
      my $captcha = Authen::Captcha->new(
	data_folder   => "$m_hrSettings->{cgi}{bin}/config/",
	output_folder => "$m_hrSettings->{cgi}{DocumentRoot}/images",
	expire        => 300);
      my $md5sum = $captcha->generate_code(3);
      $authen = qq|<input size="5" type="hidden" name="md5" value="$md5sum"/>
      <label for="captcha"><img src="$m_hrSettings->{cgi}{serverName}/$m_hrSettings->{cgi}{prefix}/images/$md5sum.png" border="0" style="margin:0.2em;"/></label>
      <input autocomplete="off" onkeypress="if(enter(event))return false;" type="text" size="5" data-regexp="|.'/^.{3}$/'.qq|" data-error="$wrong_captcha_text" data-right="$right_captcha_text"  name="captcha"/>|;
    };
    print $@ if $@;
    print div({align => 'center'}, translate('Codenotcheckedfileerror')) if $m_nSkipCaptch eq 0;
    print div({align => 'center'}, translate('Codenotcheckedfileerror')) if $m_nSkipCaptch eq -1;
    print div({align => 'center'}, translate('Failednotindatabase'))     if $m_nSkipCaptch eq -2;
    print div({align => 'center'}, translate('Failedinvalidcode'))       if $m_nSkipCaptch eq -3;
    my $register = translate('register');
    my $t_forgetPass = translate('forgetPass');
    print qq(
    <div class="dbForm">
    <form  name="login" id="loginForm" class="dbForm" target="_parent" method="get" name="Login"  onsubmit="m_sid ='123';submitForm(this,'login','login');return false;">
    <label for="user" class="caption">$name</label>
    <input type="text" id="user" data-regexp=")
      . '/^\w{4,100}$/'
      . qq(" data-error="$wrong_username_text" data-right="$right_username_text" name="user"/>
    <label for="password" class="caption">$password</label>
    <input type="hidden" name="action" value="login"/>
    <input autocomplete="off" type="password" data-regexp="/.{6,20}/" data-error="$wrong_passwort_text"  data-right="$right_passwort_text" id="password" name="pass"/>
    $authen
    <input type="submit"  name="submit" value="$trlogin" size="15" alt="submit" align="left"/>
    </form>
    <br/>
    <a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=reg','register','register');">$register</a>
    <br/>
    <a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=lostPassword','lostPassword','lostPassword')">$t_forgetPass</a>
    </div>);
} else {
    my $lg =
      "javascript:m_sid='123';closeMenu();requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=logout','logout','logout')";
    my $welcome = translate('welcome');
    my $logout  = translate('logout');
    print qq ($welcome, $m_sUser <br/><a  class="link" href="$lg">$logout</a><br/>);
}




1;

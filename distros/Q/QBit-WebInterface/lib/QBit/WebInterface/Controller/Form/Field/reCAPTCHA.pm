package QBit::WebInterface::Controller::Form::Field::reCAPTCHA;
$QBit::WebInterface::Controller::Form::Field::reCAPTCHA::VERSION = '0.029';
use qbit;

use base qw(QBit::WebInterface::Controller::Form::Field);

use LWP::UserAgent;

use Exception::Form;

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    $self->{'name'} = 'captcha' . $self;
    $self->{'theme'} = 'clean' unless defined($self->{'theme'});
}

sub check {
    my ($self) = @_;

    $self->{'__UA__'} ||= LWP::UserAgent->new();

    my $response = $self->{'__UA__'}->post(
        'http://www.google.com/recaptcha/api/verify',
        {
            privatekey => (
                $self->form->controller->{'app'}->get_option('reCAPTCHA_privkey')
                  || throw gettext('Missed required option "%s"', 'reCAPTCHA_privkey')
            ),
            remoteip  => $self->form->controller->request->remote_addr(),
            challenge => $self->form->controller->request->param('recaptcha_challenge_field'),
            response  => $self->form->controller->request->param('recaptcha_response_field'),
        },
    );

    throw Exception::Form gettext('HTTP error: %s', $response->status_line())
      unless $response->is_success();

    my ($result, $error) = split(/[\r\n]+/, $response->decoded_content());

    throw Exception::Form $error eq 'incorrect-captcha-sol'
      ? gettext('Incorred CAPTCHA')
      : gettext('Cannot validate CAPTCHA: %s', $error)
      if $result ne 'true';
}

sub control_html {
    my ($self) = @_;

    my $key = $self->form->controller->{'app'}->get_option('reCAPTCHA_pubkey')
      || throw gettext('Missed required option "%s"', 'reCAPTCHA_pubkey');

    my $text_values = join(",", map {"$_:'$self->{$_}'"} grep {defined($self->{$_})} qw(lang theme));

    my $html = qq{<script type="text/javascript">var RecaptchaOptions = {$text_values}</script>}
      . qq{<script type="text/javascript" src="http://www.google.com/recaptcha/api/challenge?k=$key"></script>};

    $html .= $self->_html_error();

    return $html;
}

TRUE;

package QBit::Application::_Utils::TmpLocale;
$QBit::Application::_Utils::TmpLocale::VERSION = '0.015';
use qbit;

use base qw(QBit::Class);

sub init {
    my ($self) = @_;

    my @missed_required_params = grep {!exists($self->{$_})} qw(app old_locale);
    throw Exception::BadArguments gettext('Missed requred fields "%s"', join(', ', @missed_required_params))
      if @missed_required_params;
}

sub DESTROY {
    my ($self) = @_;

    $self->{'app'}->set_app_locale($self->{'old_locale'});
}

TRUE;

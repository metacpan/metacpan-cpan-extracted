package QBit::Application::_Utils::TmpRights;
$QBit::Application::_Utils::TmpRights::VERSION = '0.016';
use qbit;

use base qw(QBit::Class);

sub init {
    my ($self) = @_;

    my @missed_required_params = grep {!exists($self->{$_})} qw(app rights);
    throw Exception::BadArguments gettext('Missed requred fields "%s"', join(', ', @missed_required_params))
      if @missed_required_params;

    $self->{'app'}->set_cur_user_rights($self->{'rights'});
}

sub DESTROY {
    my ($self) = @_;

    $self->{'app'}->revoke_cur_user_rights($self->{'rights'});
}

TRUE;

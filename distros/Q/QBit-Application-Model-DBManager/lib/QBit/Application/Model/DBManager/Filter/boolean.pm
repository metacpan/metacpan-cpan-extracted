package QBit::Application::Model::DBManager::Filter::boolean;
$QBit::Application::Model::DBManager::Filter::boolean::VERSION = '0.017';
use qbit;

use base qw(QBit::Application::Model::DBManager::Filter);

sub need_tokens {return [qw(NOT)]}

sub expressions {
    my ($self, $field_name) = @_;

    my $uc_field_name = uc($field_name);

    return ["$uc_field_name { [\$_[1] => '=' => TRUE] }", "NOT $uc_field_name { [\$_[2] => '=' => FALSE] }"];
}

sub check {
    throw gettext('Bad data') if $_[1]->[1] ne '=';
}

sub as_text {
    $_[1]->[2] ? $_[1]->[0] : 'NOT ' . $_[1]->[0];
}

sub as_filter {
    $_[1]->[2]
      ? (defined($_[2]->{'db_expr'}) ? $_[2]->{'db_expr'} : $_[1]->[0])
      : [AND => [{NOT => [defined($_[2]->{'db_expr'}) ? $_[2]->{'db_expr'} : $_[1]->[0]]}]];
}

TRUE;

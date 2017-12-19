package QBit::Application::Model::DBManager::Filter::number;
$QBit::Application::Model::DBManager::Filter::number::VERSION = '0.019';
use qbit;

use base qw(QBit::Application::Model::DBManager::Filter);

sub need_tokens {return [qw(NUMBER NOT IN IS)]}

sub nonterminals {
    return {
        numbers     => "NUMBER { [\$_[1]] }\n        |   NUMBER ',' numbers { [\$_[1], \@{\$_[3]}] }\n        ;",
        number_list => "'[' numbers ']' { \$_[2] }\n        ;"
    };
}

sub expressions {
    my ($self, $field_name) = @_;

    my $uc_field_name = uc($field_name);

    return [
        "$uc_field_name '='    NUMBER      { [$field_name => '='      => \$_[3]] }",
        "$uc_field_name '<>'   NUMBER      { [$field_name => '<>'     => \$_[3]] }",
        "$uc_field_name '>'    NUMBER      { [$field_name => '>'      => \$_[3]] }",
        "$uc_field_name '>='   NUMBER      { [$field_name => '>='     => \$_[3]] }",
        "$uc_field_name '<'    NUMBER      { [$field_name => '<'      => \$_[3]] }",
        "$uc_field_name '<='   NUMBER      { [$field_name => '<='     => \$_[3]] }",
        "$uc_field_name IS     NUMBER      { [$field_name => IS       => \$_[3]] }",
        "$uc_field_name 'IS NOT' NUMBER      { [$field_name => 'IS NOT'   => \$_[3]] }",
        "$uc_field_name '='    number_list { [$field_name => '='      => \$_[3]] }",
        "$uc_field_name '<>'   number_list { [$field_name => '<>'     => \$_[3]] }",
        "$uc_field_name IN     number_list { [$field_name => 'IN'     => \$_[3]] }",
        "$uc_field_name NOT IN number_list { [$field_name => 'NOT IN' => \$_[4]] }"
    ];
}

sub check {
    throw gettext('Bad data') unless ref($_[1]->[2]) eq 'ARRAY' || !ref($_[1]->[2]);
    throw gettext('Bad operation "%s"', $_[1]->[1])
      unless in_array($_[1]->[1],
        ref($_[1]->[2]) eq 'ARRAY' ? [qw(= <> IN), 'NOT IN'] : [qw(= <> > >= < <= IS), 'IS NOT']);
}

sub as_text {
    "$_[1]->[0] $_[1]->[1] "
      . (ref($_[1]->[2]) eq 'ARRAY' ? '[' . join(', ', @{$_[1]->[2]}) . ']' : $_[1]->[2] // 'NULL');
}

sub as_filter {
    [defined($_[2]->{'db_expr'}) ? $_[2]->{'db_expr'} : $_[1]->[0] => $_[1]->[1] => \$_[1]->[2]];
}

TRUE;

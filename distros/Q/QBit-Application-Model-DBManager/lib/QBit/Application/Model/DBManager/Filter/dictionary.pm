package QBit::Application::Model::DBManager::Filter::dictionary;
$QBit::Application::Model::DBManager::Filter::dictionary::VERSION = '0.022';
use qbit;

use base qw(QBit::Application::Model::DBManager::Filter);

sub public_fields {
    return ($_[0]->SUPER::public_fields(), 'values');
}

sub expressions {
    my ($self, $field_name, $field, %opts) = @_;

    my $uc_field_name = uc($field_name);
    my $ns = lc(join('___', @{$opts{'ns'} || []}));

    return [
        $uc_field_name
          . " '='  "
          . ($ns ? "${ns}___" : '')
          . "${field_name}___dictionary"
          . " { [$_[1] => '='  => \$_[3]] }",
        $uc_field_name
          . " '<>' "
          . ($ns ? "${ns}___" : '')
          . "${field_name}___dictionary"
          . " { [$_[1] => '<>' => \$_[3]] }",
        $uc_field_name
          . " '='  "
          . ($ns ? "${ns}___" : '')
          . "${field_name}___dictionary_list"
          . " { [$_[1] => '='  => \$_[3]] }",
        $uc_field_name
          . " '<>' "
          . ($ns ? "${ns}___" : '')
          . "${field_name}___dictionary_list"
          . " { [$_[1] => '<>' => \$_[3]] }"
    ];
}

sub public_keys {return [qw(values)];}

sub pre_process {
    my ($self, $field, $field_name, %opts) = @_;

    $field->{'values'} = $field->{'values'}($self->{'db_manager'}) if ref($field->{'values'}) eq 'CODE';
    $field->{'values'} ||= [];

    foreach my $value (@{$field->{'values'}}) {
        unless (exists($value->{'key'})) {
            $value->{'key'} = lc($value->{'id'});
            $value->{'key'} =~ s/\s/_/g;
            $value->{'key'} =~ s/[^\w\d]//g;
            $value->{'key'} = "id$value->{'key'}" unless $value->{'key'} =~ /^[a-zA-Z_]/;
        }

        $field->{'key2id'}{$value->{'key'}} = $value->{'id'};
        $field->{'id2key'}{$value->{'id'}}  = $value->{'key'};
    }

    return TRUE;
}

sub tokens {
    my ($self, $field_name, $field) = @_;

    return {
        map {
            uc($_->{'key'}) => {
                re       => '/\G(\Q' . uc($_->{'key'}) . '\E)/igc and return (' . uc($_->{'key'}) . ' => $1)',
                priority => length($_->{'key'})
              }
          } @{$field->{'values'}}
    };
}

sub nonterminals {
    my ($self, $field_name, $field, %opts) = @_;

    my $ns = lc(join('___', @{$opts{'ns'} || []}));

    my $name = ($ns ? "${ns}___" : '') . "${field_name}___dictionary";

    return {
        $name => join("\n        |   ",
            map {uc($_->{'key'}) . ' { \'' . $field->{'key2id'}{$_->{'key'}} . '\' }'} @{$field->{'values'}})
          . "\n        ;",

        "${name}_sl"   => "$name { [\$_[1]] }\n        |   $name ',' ${name}_sl { [\$_[1], \@{\$_[3]}] }\n        ;",
        "${name}_list" => "'[' ${name}_sl ']' { \$_[2] }\n        ;"
    };
}

sub check {
    throw gettext('Bad operation "%s"', $_[1]->[1])
      unless in_array($_[1]->[1], [qw(= <> IS), 'IS NOT']);
}

sub as_text {
    "$_[1]->[0] $_[1]->[1] "
      . (
          ref($_[1]->[2]) eq 'ARRAY' ? '[' . join(', ', map {$_[2]->{'id2key'}{$_}} @{$_[1]->[2]}) . ']'
        : defined($_[1]->[2]) ? $_[2]->{'id2key'}{$_[1]->[2]}
        : 'NULL'
      );
}

sub as_filter {
    [defined($_[2]->{'db_expr'}) ? $_[2]->{'db_expr'} : $_[1]->[0] => $_[1]->[1] => \$_[1]->[2]];
}

TRUE;

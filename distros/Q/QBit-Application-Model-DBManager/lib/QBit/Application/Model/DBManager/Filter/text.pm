package QBit::Application::Model::DBManager::Filter::text;
$QBit::Application::Model::DBManager::Filter::text::VERSION = '0.022';
use qbit;

use base qw(QBit::Application::Model::DBManager::Filter);

sub need_tokens {return [qw(STRING NOT LIKE IN IS)]}

sub nonterminals {
    return {
        strings     => "STRING { [\$_[1]] }\n        |   STRING ',' strings { [\$_[1], \@{\$_[3]}] }\n        ;",
        string_list => "'[' strings ']' { \$_[2] }\n        ;"
    };
}

sub expressions {
    my ($self, $field_name) = @_;

    my $uc_field_name = uc($field_name);

    return [
        "$uc_field_name '='      STRING      { [$field_name => '='        => \$_[3]] }",
        "$uc_field_name '<>'     STRING      { [$field_name => '<>'       => \$_[3]] }",
        "$uc_field_name LIKE     STRING      { [$field_name => 'LIKE'     => \$_[3]] }",
        "$uc_field_name NOT LIKE STRING      { [$field_name => 'NOT LIKE' => \$_[4]] }",
        "$uc_field_name 'IS'     STRING      { [$field_name => 'IS'       => \$_[3]] }",
        "$uc_field_name 'IS NOT' STRING      { [$field_name => 'IS NOT'   => \$_[3]] }",
        "$uc_field_name '='      string_list { [$field_name => '='        => \$_[3]] }",
        "$uc_field_name '<>'     string_list { [$field_name => '<>'       => \$_[3]] }",
        "$uc_field_name IN       string_list { [$field_name => 'IN'       => \$_[3]] }",
        "$uc_field_name NOT IN   string_list { [$field_name => 'NOT IN'   => \$_[4]] }",
    ];
}

sub check {
    throw gettext('Bad data') unless !ref($_[1]->[2]) || ref($_[1]->[2]) eq 'ARRAY';
    throw gettext('Bad operation "%s"', $_[1]->[1])
      unless in_array($_[1]->[1], [qw(= <> LIKE IN IS), 'NOT LIKE', 'NOT IN', 'IS NOT']);
}

sub as_text {
    my $string;
    if (ref($_[1]->[2]) eq 'ARRAY') {
        $string = '[' . join(', ', map {s/'/\\'/g; "'$_'"} @{$_[1]->[2]}) . ']';
    } elsif (defined($_[1]->[2])) {
        $string = $_[1]->[2];
        $string =~ s/'/\\'/g;
        $string = "'$string'";
    } else {
        $string = 'NULL';
    }
    "$_[1]->[0] $_[1]->[1] $string";
}

sub as_filter {
    [
        defined($_[2]->{'db_expr'})
        ? $_[2]->{'db_expr'}
        : $_[1]->[0] => $_[1]->[1] => \($_[1]->[1] =~ /LIKE/ ? __like_str($_[1]->[2]) : $_[1]->[2])
    ];
}

sub __like_str {
    my ($text) = @_;

    $text =~ s/%/\\%/g;
    $text =~ s/_/\\_/g;

    $text =~ s/\*/%/g;
    $text =~ s/\?/_/g;

    $text = '%' . $text unless $text =~ s/^\^//;
    $text = $text . '%' unless $text =~ s/([^\\])\$$/$1/;

    $text =~ s/^\Q%\^/%^/;
    $text =~ s/\Q\$%\E$/\$%/;

    return $text;
}

TRUE;

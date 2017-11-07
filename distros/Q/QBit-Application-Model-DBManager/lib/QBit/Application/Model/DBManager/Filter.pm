package QBit::Application::Model::DBManager::Filter;
$QBit::Application::Model::DBManager::Filter::VERSION = '0.018';
use qbit;

use base qw(QBit::Class);

__PACKAGE__->abstract_methods(qw(expressions));
__PACKAGE__->mk_ro_accessors(qw(db_manager name));

my %TOKENS = (
    AND    => {re => '/\G(AND)/igc and return (AND => $1)',     priority => 3},
    OR     => {re => '/\G(OR)/igc and return (OR => $1)',       priority => 2},
    IN     => {re => '/\G(IN)/igc and return (IN => $1)',       priority => 2},
    IS     => {re => '/\G(IS)/igc and return (IS => $1)',       priority => 2},
    NOT    => {re => '/\G(NOT)/igc and return (NOT => $1)',     priority => 3},
    LIKE   => {re => '/\G(LIKE)/igc and return (LIKE => $1)',   priority => 4},
    NOT    => {re => '/\G(NOT)/igc and return (NOT => $1)',     priority => 3},
    MATCH  => {re => '/\G(MATCH)/igc and return (MATCH => $1)', priority => 5},
    STRING => {
        re       => '/\G(?:"([^"]*?)"|\'([^\']*?)\')/igc and return (STRING => defined($1) ? $1 : $2)',
        priority => 0
    },
    NUMBER => {re => '/\G(\d+(?:\.\d*)?)/igc and return (NUMBER => $1)', priority => 0},
);

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    weaken($self->{'db_manager'});
}

sub is_simple {return TRUE}

sub public_fields {return qw(type label)}

sub tokens {$TOKENS{$_[0]}}

sub need_tokens { }

sub nonterminals { }

sub public_keys { }

sub __merge_expr {
    my ($expr1, $expr2, $type) = @_;

    if (ref($expr1) eq 'ARRAY' && @$expr1 == 2 && $expr1->[0] eq $type) {
        push(@{$expr1->[1]}, ref($expr2) eq 'ARRAY' && @$expr2 == 2 && $expr2->[0] eq $type ? @{$expr2->[1]} : $expr2);
    } else {
        $expr1 = [$type => [$expr1, $expr2]];
    }

    return $expr1;
}

TRUE;

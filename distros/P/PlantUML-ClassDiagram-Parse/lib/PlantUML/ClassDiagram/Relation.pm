package PlantUML::ClassDiagram::Relation;

use strict;
use warnings;
use utf8;

use parent qw/Class::Accessor::Fast/;
__PACKAGE__->follow_best_practice;

my @self_valiables = qw/
name
from
to
/;
__PACKAGE__->mk_ro_accessors(@self_valiables);

my $symbol_name_map = +{
    '<-'  => 'association',
    '->'  => 'association',
    '<|-' => 'generalization',
    '-|>' => 'generalization',
    '<|.' => 'realization',
    '.|>' => 'realization',
    'o-'  => 'aggregation',
    '-o'  => 'aggregation',
    '*-'  => 'composite',
    '-*'  => 'composite',
};

my $symbol_is_from_right_side = +{
    '<-'  => 1,
    '<|-' => 1,
    '<|.' => 1,
    'o-'  => 1,
    '*-'  => 1,
    '-|>' => 0,
    '->'  => 0,
    '.|>' => 0,
    '-o'  => 0,
    '-*'  => 0,
};

sub new {
    my ($class, $name, $from, $to) = @_;
    my $attr = +{
        name => $name || '',
        from => $from || '',
        to   => $to || '',
    };
    return $class->SUPER::new($attr);
}

sub build {
    my ($class, $string) = @_;

    my ($symbol, $left, $right);
    $string =~ /([\w|:]+)\s+(.+?)\s+([\w|:]+)/;

    $left   = $1;
    $symbol = $2;
    $right  = $3;

    my $name = $class->_get_symbol_name($symbol);
    my ($from, $to) = $class->_get_from_and_to($symbol, $left, $right);

    return $class->new($name, $from, $to);
}

sub _get_symbol_name {
    my ($class, $symbol) = @_;
    for my $pattern (keys %$symbol_name_map){
        my $escaped_pattern = quotemeta($pattern);
        return $symbol_name_map->{$pattern} if $symbol =~ /$escaped_pattern/;
    }

    return undef;
}

# return (from, to)
sub _get_from_and_to {
    my ($class, $symbol, $left, $right) = @_;

    for my $pattern (keys %$symbol_is_from_right_side){
        my $escaped_pattern = quotemeta($pattern);
        if ($symbol =~ /$escaped_pattern/) {

            return ($right, $left) if $symbol_is_from_right_side->{$pattern};
            return ($left, $right);
        }
    }

    return ($left, $right);
}

1;

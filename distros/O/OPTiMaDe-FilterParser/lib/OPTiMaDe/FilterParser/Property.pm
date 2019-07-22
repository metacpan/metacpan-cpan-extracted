package OPTiMaDe::FilterParser::Property;

use strict;
use warnings;

sub new {
    my( $class ) = @_;
    return bless { name => [] }, $class;
}

sub push_identifier {
    my( $self, $identifier ) = @_;
    push @{$self->{name}}, $identifier;
}

sub to_SQL
{
    my( $self, $delim ) = @_;
    $delim = "'" unless $delim;

    return join '.', map { "${delim}$_${delim}" } @{$self->{name}};
}

1;

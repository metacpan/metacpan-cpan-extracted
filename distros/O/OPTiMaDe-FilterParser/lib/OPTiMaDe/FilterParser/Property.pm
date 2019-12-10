package OPTiMaDe::FilterParser::Property;

use strict;
use warnings;

use overload '@{}' => sub { return $_[0]->{name} },
             '""'  => sub { return $_[0]->to_filter };

sub new {
    my $class = shift;
    return bless { name => \@_ }, $class;
}

sub to_filter
{
    my( $self ) = @_;
    return join '.', @$self;
}

sub to_SQL
{
    my( $self, $options ) = @_;
    $options = {} unless $options;
    my( $delim, $placeholder ) = (
        $options->{delim},
        $options->{placeholder},
    );
    $delim = "'" unless $delim;

    my $sql = join '.', map { "${delim}$_${delim}" } @$self;

    if( wantarray ) {
        return ( $sql, [] );
    } else {
        return $sql;
    }
}

sub modify
{
    my $self = shift;
    my $code = shift;

    return $code->( $self, @_ );
}

1;

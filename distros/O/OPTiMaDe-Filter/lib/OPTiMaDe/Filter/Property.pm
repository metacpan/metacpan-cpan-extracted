package OPTiMaDe::Filter::Property;

use strict;
use warnings;

use overload '@{}' => sub { return $_[0]->{name} },
             '""'  => sub { return $_[0]->to_filter };

our $identifier_re = q/([a-z_][a-z0-9_]*)/;

sub new {
    my $class = shift;
    return bless { name => [ map { lc } @_ ] }, $class;
}

sub to_filter
{
    my( $self ) = @_;
    $self->validate;
    return join '.', @$self;
}

sub to_SQL
{
    my( $self, $options ) = @_;
    $self->validate;

    $options = {} unless $options;
    my( $delim, $placeholder ) = (
        $options->{delim},
        $options->{placeholder},
    );
    $delim = "'" unless $delim;

    if( @$self > 2 ) {
        die 'no SQL representation for properties of more than two ' .
            "identifiers\n";
    }

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

sub validate
{
    my $self = shift;
    die 'name undefined for OPTiMaDe::Filter::Property' if !@$self;

    for my $name (@$self) {
        next if $name =~ /^$identifier_re$/;
        die "name '$name' does not match identifier syntax: $identifier_re";
    }
}

1;

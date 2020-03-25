package OPTIMADE::Filter::Property;

use strict;
use warnings;

use overload '@{}' => sub { return $_[0]->{name} },
             '""'  => sub { return $_[0]->to_filter };

our $identifier_re = q/([a-z_][a-z0-9_]*)/;

sub new {
    my $class = shift;
    return bless { name => \@_ }, $class;
}

sub to_filter
{
    my( $self ) = @_;

    # Validate
    $self->validate;
    for my $name (@$self) {
        my $lc_name = lc $name;
        next if $lc_name =~ /^$identifier_re$/;
        die "name '$lc_name' does not match identifier syntax: $identifier_re";
    }

    return join '.', map { lc } @$self;
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

    # Validate
    $self->validate;
    if( @$self > 2 ) {
        die 'no SQL representation for properties of more than two ' .
            "identifiers\n";
    }

    # Construct the SQL
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
    die 'name undefined for OPTIMADE::Filter::Property' if !@$self;
}

1;

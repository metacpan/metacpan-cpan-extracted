package OPTIMADE::Filter::Boolean;

use strict;
use warnings;

use parent 'OPTIMADE::Filter::Modifiable';

our $VERSION = '0.11.0'; # VERSION

sub new {
    my( $class, $value ) = @_;
    return bless { value => $value }, $class;
}

sub to_filter
{
    my $self = shift;
    return $self->{value} ? 'TRUE' : 'FALSE';
}

sub to_SQL
{
    die "no SQL representation\n";
}

sub modify
{
    my $self = shift;
    my $code = shift;

    return $code->( $self, @_ );
}

1;

package 
    Net::FileMaker::XML::ResultSet::FieldsDefinition::Field;

use strict;
use warnings;
use Carp;

=head1 NAME

Net::FileMaker::XML::ResultSet::FieldsDefinition::Field

=head1 SYNOPSIS

This module handles the single field definition hash returned by the
L<Net::FileMaker::XML> search methods. Don't call this module directly,
instead use L<Net::FileMaker::XML>.

=head1 METHODS

=cut

sub new
{
    my($class, $res_hash) = @_;
    
    my $self = {
        result_hash      => $res_hash        
    };
    bless $self , $class;
    $self->_parse;
    return $self;
}

=head2 get($field_name)

Returns the value for the supplied field name.

It may return (possible results in parentheses):
    
=over

=item 

* global (0,1)

=item 

* numeric-only (0,1)

=item 

* four-digit-year (0,1)

=item 

* not-empty (0,1)

=item 

* auto_enter (0,1)

=item 

* type ("normal", "calculation", or "summary")

=item 

* time-of_day (0,1)

=item 

* max-repeat (int)

=item 

* max-characters (int)

=item 

* result ("text", "number", "date", "time", "timestamp", or "container") 

=back


=cut

my @availables = qw( global numeric-only four-digit-year not-empty auto-enter type time-of-day max-repeat max-characters result );

sub get
{
    my ( $self, $par ) = @_;
    croak 'this parameter is not defined!' if(! grep { $_ eq $par } @availables);
    return $self->{$par};
}

=head2 get_all

Returns a reference to an hash with all the parameters of this field.

=cut

sub get_all
{
    my $self = shift;
    my %tmp = map { $_ => $self->{$_} } @availables;
    return \%tmp;
}


# _parse
# 
sub _parse
{
    my $self = shift;
    
    # boolean fields ( "yes" or "no" ) to be converted into 1 or 0
    my @bools = qw( global numeric-only four-digit-year not-empty auto-enter time-of-day );
    foreach my $key (keys %{$self->{result_hash}}) {
        if(grep {$_ eq $key} @bools){
            $self->{$key} = $self->{result_hash}{$key} eq 'no' ? 0 : 1;    
        }else{
            $self->{$key} = $self->{result_hash}{$key};  
        }
    }
    return;
}

1;

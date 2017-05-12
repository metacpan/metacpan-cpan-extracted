package 
    Net::FileMaker::XML::ResultSet::Row;

use strict;
use warnings;
use Carp;
use DateTime;
use DateTime::Format::CLDR;

=head1 NAME

Net::FileMaker::XML::ResultSet::FieldsDefinition::Row

=head1 SYNOPSIS

This module handles the single row of the resultset returned by the
L<Net::FileMaker::XML> search methods. Don't call this module directly, 
instead use L<Net::FileMaker::XML>.

=head1 METHODS

=cut

sub new
{
    my($class, $res_hash , $dataset) = @_;
    
    my $cd = $dataset->fields_definition;    # column definition, I need it for the inflater
    my $ds = $dataset->datasource;
    my $db = $dataset->{db};
    
    my $self = {
        columns_def => $cd,
        datasource => $ds,    
        result_hash => $res_hash,
        db_ref => $db        
    };
    bless $self , $class;
    return $self;
}

=head2 mod_id

Returns the mod id for this row.

=cut

sub mod_id
{
    my $self = shift;
    return $self->{result_hash}{'mod-id'};
}


=head2 record_id

Returns the record id for this row.

=cut

sub record_id
{
    my $self = shift;
    return $self->{result_hash}{'record-id'};
}


=head2 get('colname')

Returns the value of the selected column for this row.

=cut

sub get
{
    my ( $self , $col ) = @_;
    return $self->{result_hash}{field}{$col}{data};
}

=head2 get_type('colname')

Returns the type of the selected column for this row.

=cut

sub get_type
{
    my ( $self , $col ) = @_;
    return $self->{columns_def}{$col}{result};
}

=head2 get_max_length('colname')

Returns the type of the selected column for this row.

=cut

sub get_max_length
{
    my ( $self , $col ) = @_;
    return $self->{columns_def}{$col}{'max-repeat'};
}

=head2 get_inflated('colname')

Returns the value of the selected column for this row. If the type is
date, time or datetime returns, it will return a L<DateTime> object.

=cut

sub get_inflated
{
    my ( $self , $col ) = @_;
    # if the field is a  “date”, “time” or “timestamp"
    if(defined $self->get_type($col)){
        if($self->get_type($col) =~ m/^(date|time|timestamp)$/xms ){
            # let's convert it to a DateTime
            my $pattern = $self->{datasource}{"$1-format"}; # eg. 'MM/dd/yyyy HH:mm:ss'
            my $cldr = DateTime::Format::CLDR->new(
                pattern     => $pattern
            );
            return $cldr->parse_datetime($self->{result_hash}{field}{$col}{data}) if(defined $self->{result_hash}{field}{$col}{data});
        }
    }
    # if the type is one of the ones above let's convert the value in a DateTime
    return $self->{result_hash}{field}{$col}{data};
}

=head2 get_columns

Returns an hash with column names & relative values for this row.

=cut
sub get_columns
{
    my ( $self , $col ) = @_;
    my %res;
    foreach my $k(sort keys %{$self->{result_hash}{field}}) {
        $res{$k} = $self->get($k);
    }    
    return \%res;
}

=head2 get_inflated_columns

Returns an hash with column names & relative values for this row. 
If the type is date, time or datetime returns a L<DateTime> object.

=cut

sub get_inflated_columns
{
    my ( $self , $col ) = @_;
    my %res;
    foreach my $k(sort keys %{$self->{result_hash}{field}}) {
        $res{$k} = $self->get_inflated($k);
    }    
    return \%res;
}

=head2 update(params => { 'Field Name' => $value , ... })

Updates the row with the fieldname/value pairs passed to params, 
returns an L<Net::FileMaker::XML::ResultSet> object.

=head3 Dates and Times editing

Filemaker accepts time|date editing as a string only in the format 
defined in the datasource, otherwise throws an error.
If you don't want to mess around with that this method allows you 
to pass a L<DateTime> object and does the dirty work for you. 

=head3 Multiple values fields

This method gives you the possibility to pass an array as a value for multiple-values-fields.
Obviously you can pass also an array of DateTimes.

=begin text

This allows you to do this:

my @pars = ( 'hello' , undef , 'world' , '');
$rs->update(params => {{ 'Field Name' => \@pars });

instead of:

$rs->update(params => { 'Field Name[1]' => 'hello' , 'Field Name[3]' => 'world'  , 'Field Name[4]' => '' });

=end text

=cut


sub update
{
    my ( $self , %pars ) = @_;
    my $db = $self->{db_ref};
    my $layout = $self->{datasource}{layout};
    
    # let's play with DateTimes and arrays if passed
    foreach my $key (keys %{$pars{params}}){
        my $value = $pars{params}{$key};
        
        # if the type is datetime let's format it right
        $pars{params}{$key} = $self->_get_formatted_dt($key,$value) if(ref($value) eq 'DateTime' );
        
        # let's transform the array into the single params, taking into account the datetimes
        if(ref($value) eq 'ARRAY'){
            
            # fm's arrays have a predefined number of slots
            # throw error if the array is longer than the max size for this field
            croak 'the lenght of the array exceeds the max size of the field' if( scalar @$value > $self->get_max_length($key) );
            
            for(my $i = 0; $i < scalar @$value; $i++) {
            
                # if the user hasn't defined the value of an index it means he doesn't want it to be modified
                if(defined $value->[$i]){
            
                    # manage datetimes
                    $value->[$i] = $self->_get_formatted_dt($key,$value) if(ref($value) eq 'DateTime' );
                    
                    # set the param for the request
                    $pars{params}{$key."[".($i+1)."]"} = $value->[$i];
                    
                }
            }
            #finally let's delete the array from the params
            delete $pars{params}{$key};
        }
    }
    my $result = $db->edit(layout =>$layout  , recid => $self->record_id , params => $pars{params} );
    return $result;
}

# _get_formatted_dt
# returns formatted dt according to the field definition

sub _get_formatted_dt
{
    my ( $self , $fieldname , $dt ) = @_;
    # let's find what kind of field it is
    my $format = $self->get_type($fieldname);
    # and then it's format
    my $pattern = $self->{datasource}{"$format-format"}; # eg. 'MM/dd/yyyy HH:mm:ss'
    my $result = DateTime::Format::CLDR->new(pattern => $pattern)->format_datetime($dt);
    return $result;
}

=head2 remove(params => { 'Field Name' => $value , ... })

Deletes this row, returns an L<Net::FileMaker::XML::ResultSet> object.

=cut


sub remove
{
    my ( $self , %params ) = @_;
    my $db = $self->{db_ref};
    my $layout = $self->{datasource}{layout};
    my $result = $db->delete(layout =>$layout  , recid => $self->record_id , params => $params{params});
    return $result;
}


# 


1;

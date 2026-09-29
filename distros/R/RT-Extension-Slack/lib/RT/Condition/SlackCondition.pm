package RT::Condition::SlackCondition;
use strict;
use warnings;
use base 'RT::Condition';

sub IsApplicable {
    my $self = shift;
   
    # RT6 is more strict about undefined variables and because scrips can now be run on Assets we will 
    # get undef results more often, unless we're more specific.  
    # Ensure undef becomes null by adding the or operator.
    
    my $field = $self->TransactionObj->Field  // '';
    my $type = $self->TransactionObj->Type // '';

    RT->Logger->debug("RTbot Scrip - Condition - transactionObj Field & Type are: ".$field." and ".$type);

    # On Create
    if ( $type eq "Create" ){
        return 1;
    }

    # On Queue Change
    if ( $field eq "Queue" && $type eq "Set" ){
        return 1;
    }

    # On Owner Change
    if ( $field eq "Owner" && $type eq "Set" ){
        return 1;
    }

    # On Status Change - This should catch both the standard "Set" type and the old "Status" type
    if ( ($type eq "Set" || $type eq "Status") && $field eq "Status" ) {
        return 1;
    }

    # On Subject Change
    if ( $field eq "Subject" && $type eq "Set" ) {
        return 1;
    }

    # Or don't do anything at all
    return 0;
}

1;

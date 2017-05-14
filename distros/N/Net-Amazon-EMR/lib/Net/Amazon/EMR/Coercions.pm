package Net::Amazon::EMR::Coercions;
use strict;
use warnings;
use Moose::Util::TypeConstraints;
use DateTime::Format::ISO8601;

BEGIN {

    for my $class (qw/
AddInstanceGroupsResult
BootstrapActionConfig   
BootstrapActionDetail   
DescribeJobFlowsResult
HadoopJarStepConfig     
InstanceGroupDetail    
InstanceGroupConfig 
InstanceGroupModifyConfig 
JobFlowDetail           
JobFlowExecutionStatusDetail
JobFlowInstancesConfig  
JobFlowInstancesDetail  
KeyValue                
PlacementType    
RunJobFlowResult
ScriptBootstrapActionConfig
StepConfig              
StepDetail              
StepExecutionStatusDetail
/) {
        subtype "Net::Amazon::EMR::Type::$class" => as 'Object' => where { $_->isa("Net::Amazon::EMR::$class") };
        subtype "Net::Amazon::EMR::Type::ArrayRefof$class" => as "ArrayRef[Net::Amazon::EMR::$class]";

        eval qq{ coerce 'Net::Amazon::EMR::Type::ArrayRefof$class'
        => from 'HashRef'
        => via { my \$s = \$_->{member} || \$_; [ map { Net::Amazon::EMR::$class->new(\$_) } \@{ref(\$s) eq 'ARRAY' ? \$s : [ \$s ] } ] };
};

        eval qq{ coerce 'Net::Amazon::EMR::Type::ArrayRefof$class'
        => from 'ArrayRef[HashRef]'
        => via { [ map { Net::Amazon::EMR::$class->new(\$_) } \@\$_ ] };
};
        eval qq{ coerce 'Net::Amazon::EMR::Type::$class' 
    => from 'HashRef'
    => via { Net::Amazon::EMR::$class->new(\$_) };
};

    }
}

subtype 'Net::Amazon::EMR::Type::DateTime' => as 'Object' => where { $_->isa('DateTime') };

coerce 'Net::Amazon::EMR::Type::DateTime'
    => from 'Str',
    => via { eval { DateTime::Format::ISO8601->parse_datetime($_) }; };

subtype 'Net::Amazon::EMR::Type::Bool' => as 'Bool';

coerce 'Net::Amazon::EMR::Type::Bool'
    => from 'Str'
    => via { m/true/ ? 1 : 0 };

subtype 'Net::Amazon::EMR::Type::ArrayRefofStr' => as 'ArrayRef[Str]';

coerce 'Net::Amazon::EMR::Type::ArrayRefofStr' 
    => from 'HashRef'
    => via { my $s = $_->{member}; ref($s) eq 'ARRAY' ? $s : [ $s ] };

1;

__END__

=head1 NAME

Net::Amazon::EMR::Coercions

=head1 DESCRIPTION

Provides a range of Moose type coercions to facilitate conversion from hashrefs and arrays to Net::Amazon::EMR class types.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut

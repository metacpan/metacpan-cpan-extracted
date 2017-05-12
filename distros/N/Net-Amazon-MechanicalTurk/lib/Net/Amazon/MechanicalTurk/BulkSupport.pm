package Net::Amazon::MechanicalTurk::BulkSupport;
use strict;
use warnings;
use Net::Amazon::MechanicalTurk::Template::ReplacementTemplate;
use Net::Amazon::MechanicalTurk::DelimitedWriter;

our $VERSION = '1.00';

=head1 NAME

Net::Amazon::MechanicalTurk::BulkSupport - Common code for bulk HIT operations

=cut

#
# The purpose of these alias mappings is to support
# the names used by the JavaSDK which don't quite match
# the names actually used by the web service.
#

my $CREATE_HITTYPE_PROPERTY_ALIASES = reverseLookup({
    Title                       => [qw{ title }],
    Description                 => [qw{ description }],
    Keywords                    => [qw{ keywords }],
    AutoApprovalDelayInSeconds  => [qw{ autoapprovaldelayinseconds autoapprovaldelay }],
    AssignmentDurationInSeconds => [qw{ assignmentdurationinseconds assignmentduration }],
    Reward                      => [qw{ reward }],
    QualificationRequirements   => [qw{ qualificationrequirements }]
});

my $CREATE_HIT_PROPERTY_ALIASES = reverseLookup({
    LifetimeInSeconds   => [qw{ lifetimeinseconds hitlifetime }],
    MaxAssignments      => [qw{ maxassignments assignments }],
    RequesterAnnotation => [qw{ requesterannotation annotation }]
});

sub progressBlock {
    my ($progress) = @_;
    if (!defined($progress)) {
        return $progress;
    }
    elsif (UNIVERSAL::isa($progress, "CODE")) {
        return $progress;
    }
    elsif (UNIVERSAL::isa($progress, "GLOB")) {
        return sub {
            print $progress @_, "\n";
        };
    }
    else {
        Carp::croak("The progress parameters should be an IO handle or a subroutine.");
    }
}

sub defaultSuccessBlock {}

sub defaultFailBlock {
    my %params = @_;
    die $params{error};
}

sub successBlock {
    my ($success) = @_;
    if (!defined($success)) {
        return \&defaultSuccessBlock;
    }
    elsif (UNIVERSAL::isa($success, "CODE")) {
        return $success;
    }
    else {
        return createSuccessBlock($success);
    }
}

sub createSuccessBlock {
    my ($file) = @_;
    my $out;
    my $rowNumber = 0;
    if (UNIVERSAL::isa($file, "GLOB")) {
        $out = Net::Amazon::MechanicalTurk::DelimitedWriter->new(
            output         => $file,
            fieldSeparator => "\t"
        );
    }
    elsif (UNIVERSAL::isa($file, "Net::Amazon::MechanicalTurk::DelimitedWriter")) {
        $out = $file;
    }
    else {
        my $fs = ($file =~ /\.csv$/i) ? "," : "\t";
        $out = Net::Amazon::MechanicalTurk::DelimitedWriter->new(
            lazy           => 1,
            file           => $file,
            fieldSeparator => $fs,
            autoflush      => 1
        );
    }
    return sub {
        my %params = @_;
        if ($rowNumber++ == 0) {
            $out->write(qw{ HITId HITTypeId });
        }
        $out->write($params{HITId}, $params{HITTypeId});
    };
}

sub failBlock {
    my ($fail) = @_;
    if (!defined($fail)) {
        return \&defaultFailBlock;
    }
    elsif (UNIVERSAL::isa($fail, "CODE")) {
        return $fail;
    }
    else {
        return createFailBlock($fail);
    }
}

sub createFailBlock {
    my ($file) = @_;
    my $out;
    my $rowNumber = 0;
    if (UNIVERSAL::isa($file, "GLOB")) {
        $out = Net::Amazon::MechanicalTurk::DelimitedWriter->new(
            output         => $file,
            fieldSeparator => "\t"
        );
    }
    elsif (UNIVERSAL::isa($file, "Net::Amazon::MechanicalTurk::DelimitedWriter")) {
        $out = $file;
    }
    else {
        my $fs = ($file =~ /\.csv$/i) ? "," : "\t";
        $out = Net::Amazon::MechanicalTurk::DelimitedWriter->new(
            lazy           => 1,
            file           => $file,
            fieldSeparator => $fs,
            autoflush      => 1
        );
    }
    return sub {
        my %params = @_;
        my $fields = $params{fields};
        if ($rowNumber++ == 0) {
            $out->write($fields);
        }
        # Have to use the field names to preserve order of columns
        my @row;
        for (my $i=0; $i<=$#{$fields}; $i++) {
            push(@row, $params{row}{$fields->[$i]});
        }
        $out->write(@row);
    };
}

sub formatDataStructure {
    my ($ds, $indent) = @_;
    my $text = Net::Amazon::MechanicalTurk::DataStructure->toString($ds);
    my $out = '';
    foreach my $line (split /\r?\n/s, $text) {
        $out .= ' ' x $indent;
        $out .= $line . "\n";
    }
    return $out;
}

sub createHITType {
    my ($mturk, $createHITTypeProperties, $properties, $progress) = @_;
    
    my $hitTypeId = $mturk->RegisterHITType($createHITTypeProperties)->{HITTypeId}[0];
    $progress->("  Registered HITType $hitTypeId.") if $progress;
    
    # Properties have notification specs
    if (exists $properties->{Notification}) {
        $mturk->SetHITTypeNotification(
            HITTypeId    => $hitTypeId,
            Active       => 'true',
            Notification => $properties->{Notification}
        );
        $progress->("SetHITTypeNotification on $hitTypeId.") if $progress;
    }
    
    return $hitTypeId;
}

sub getCreateHITTypeProperties {
    my ($properties) = @_;
    my $createHITTypeProperties = extractAliasProperties($properties, $CREATE_HITTYPE_PROPERTY_ALIASES);
    # Special handling for reward specified as only a dollar amount in properties file
    if (exists $createHITTypeProperties->{Reward} and
        !ref($createHITTypeProperties->{Reward}))
    {
        $createHITTypeProperties->{Reward} = {
            Amount => $createHITTypeProperties->{Reward},
            CurrencyCode => 'USD'
        };
    }
    return $createHITTypeProperties;
}

sub getCreateHITProperties {
    my ($properties) = @_;
    # Some of the properties for a hit may have values that come from the input data.
    my $createHITProperties = extractAliasProperties($properties, $CREATE_HIT_PROPERTY_ALIASES);
    foreach my $key (keys %$createHITProperties) {
        $createHITProperties->{$key} = Net::Amazon::MechanicalTurk::Template::ReplacementTemplate->new(
            templateSource => $createHITProperties->{$key}
        );
    }
    return $createHITProperties;
}

sub extractAliasProperties {
    my ($properties, $aliases) = @_;
    my $result = {};
    while (my ($prop,$value) = each %$properties) {
        $prop = $aliases->{lc($prop)};
        if (defined($prop)) {
            $result->{$prop} = $value;
        }
    }
    return $result;
}

sub reverseLookup {
    my $inHash = shift;
    my $outHash = {};
    while (my ($key,$array) = each %$inHash) {
        foreach my $value (@$array) {
            $outHash->{lc($value)} = $key;
        }
    }
    return $outHash;
}

return 1;

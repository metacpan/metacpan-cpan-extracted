package Net::Journyx::Project;
use Moose;
extends 'Net::Journyx::Record';

with 'Net::Journyx::Object::WithAttrs';

use constant jx_record_class => 'ProjectRecord';
use constant jx_strip_record_suffix => 1;
use constant jx_meta => {
    load => 'getProject',
    update => {
        operation       => 'modifyProject',
        leading         => 'id',
        leading_argname => 'id',
        record_argname  => 'rec',
    },
    create => {
        operation => 'addFullProject',
        # XXX: name? #XXX: not yet implemented, but do we want to?
        # do we want to add check at all? may be 'defaults' and 'exceptions'
        # is enough
        mandatory => [qw(parent creator)],
        defaults => sub {
            my $self = shift;
            my $args = shift;
            $args->{'parent'} = 'root'
                unless defined $args->{'parent'} && length $args->{'parent'};
            $args->{'creator'} = $self->jx->username
                unless defined $args->{'creator'} && length $args->{'creator'};

# IMPORTANT:
# type shouldn't be 0, either 1 (regular) or
#    2 (subproject, only if you have the subproject
#       feature in your Timesheet license
            if ( defined $args->{'type'} && length $args->{'type'} ) {
                unless ( $args->{'type'} =~ /^[012]$/ ) {
                    # XXX: use Carp
                    warn "Type of a project can be either 1 or 2 when you passed ". $args->{'type'};
                    $args->{'type'} = 1;
                }
            } else {
                $args->{'type'} = 1;
            }
        },
    },
    delete => {
        operation       => 'removeProject',
        leading         => 'id',
        leading_argname => 'id',
    },
};

use Data::Dumper;


# XXX: dependencies and projects are better described
# in the doc for getProjectList JX operation.
# Found types of dependencies there:
#
#    * code (task)
#    * subcode (paytype)
#    * subsubcode (billtype)
#    * expense
#    * expense_source
#    * expense_currency
#    * mileage_reason
#    * mileage_vehicle
#    * mileage_measurement

sub dependencies {
    my $self = shift;
    my $type = shift;
    return unless $self->is_loaded;

    # case is important, so we lc($type)
    $type = lc($type);

    my $response = $self->jx->soap->basic_call(
        'getProjectDependencies',
        project_id => $self->id,
        code_type => $type,
    );
    return unless $response;

    die "Don't know what to do with response: ". Dumper( $response )
        unless ref($response) eq 'HASH';

    return unless my $rec = $response->{ucfirst($type).'Record'};

    my $class = 'Net::Journyx::'. ucfirst($type);
    eval "require $class; 1" or die $@;

    my $jx = $self->jx;
    # one record
    return $class->new(jx => $jx)->load_from_hash( %$rec ) if ref($rec) eq 'HASH';

    # multiple records
    return map { $class->new(jx => $jx)->load_from_hash( %$_ ) } @$rec
        if ref($rec) eq 'ARRAY';

    die "Don't know what to do with response: ". Dumper( $rec );
}

sub add_dependency {
    my $self = shift;
    my $type = shift;
    my $code = shift;

    my $code_id = blessed($code)? $code->id : $code;

    my $response = $self->jx->soap->basic_call(
        'addProjectDependency',
        project_id => $self->id,
        code_type => $type,
        code_id => $code_id,
    );
    # returns some ID
    return $response;
}

sub delete_dependency {
    my $self = shift;
    my $type = shift;
    my $code = shift;

    my $code_id = blessed($code)? $code->id : $code;

    my $response = $self->jx->soap->basic_call(
        'removeProjectDependency',
        project_id => $self->id,
        code_type => $type,
        code_id => $code_id,
    );
    print Dumper( $response );
    return $response;
}

no Moose;
1;

package Net::Journyx::Record;
use Moose;

extends 'Net::Journyx::Object';

with 'Net::Journyx::Object::Loadable' => {
    check_on => [qw(update delete)],
    drop_on => [qw(load_from_hash create delete)],
};

use Data::Dumper;

use constant jx_strip_record_suffix => 0;
use constant jx_meta => {};

# class data implementation via inside out
my %jx_columns = ();
has jx_columns => (
    is       => 'ro',
    init_arg => undef,
    isa      => 'ArrayRef[Str]',
    lazy     => 1,
    default  => sub { return $jx_columns{ ref(shift) } || [] },
);
sub _jx_columns { $jx_columns{ ref($_[0]) || $_[0] } = $_[1] }

my %record_template = ();
has record_template => (
    is       => 'ro',
    init_arg => undef,
    isa      => 'HashRef',
    lazy     => 1,
    default  => sub { return $record_template{ ref($_[0]) } ||= $_[0]->_record_template },
);

sub BUILD {
    my $self = shift;
    my $args = shift;

    return if $self->meta->is_immutable;

    my $jx = $args->{'jx'} or die "No JX";

    my %columns = $jx->soap->record_columns( $self->jx_record_class );

    my %type_map = (
        'xsd:boolean' => 'Bool',
        'xsd:int'     => 'Int',
        'xsd:double'  => 'Math::BigFloat',
        'xsd:string'  => 'Str',
    );
    while (my ($name, $schema_type) = each %columns ) {
        my $moose_type = $type_map{ $schema_type }
            or die "No moose type for JX type '$schema_type'";

        #warn "adding column accessor $name to ". ref($self);
        $self->meta->add_attribute(
            $name,
            is => 'ro',
            isa => $moose_type,
            writer => '_'. $name,
        );
    }

    $self->_jx_columns([keys %columns]);

    $self->meta->make_immutable;
}

sub load {
    my $self = shift;
    my %args = @_;

    my $jx_operation = $self->auto_method(
        $self->jx_meta->{'load'},
        'get'
    );

    my $response = $self->jx->soap->basic_call(
        $jx_operation => pattern => \%args
    );
#    warn "loaded $jx_class ". Dumper($response) ." using ". Dumper(\%args);

    my $jx_class = $self->jx_record_class;

    my $record = $response->{ $jx_class };
    unless ( $record ) {
        die "No '$jx_class' in response ". Dumper($response);
    }

    return $self->load_from_hash( %$record );
}

sub load_from_hash {
    my $self = shift;
    my %args = @_;

    foreach my $k ( keys %args ) {
        if ( $k =~ /^_+(.*)$/ && !exists $args{ $1 } ) {
            $args{ $1 } = delete $args{ $k };
        }
    }

    my @missing;
    foreach my $column ( @{ $self->jx_columns } ) {
        my $method = '_'. $column;
        if ( exists $args{ $column } ) {
            $self->$method( delete $args{ $column } );
        } else {
            push @missing, $column;
            # flush as it can be not empty
            $self->$method( undef );
        }
    }

    my @more = keys %args;
    if ( @missing || @more ) {
        my $msg = "Either during load or load_from_hash of ". $self->jx_record_class
            ." incorrect columns have been provided to load_from_hash.";
        $msg .= " Missing columns: ". join(', ', map "'$_'", @missing) ."."
            if @missing;
        $msg .= " Superfluous columns: ". join(', ', map "'$_'", @more) ."."
            if @more;
        $msg .= " It can be either API bug or incorrect call to load_from_hash."
            ." Record *is not* marked as loaded.";
        warn $msg;
    }
    elsif ( $self->can('id') ) {
        # XXX: load may pass us empty record with all defaults
        $self->_is_loaded(1) if $self->id;
    }
    else {
        $self->_is_loaded(1);
    }

    return $self;
}

sub create {
    my $self = shift;
    my %args = @_;

    my %private_args = map { $_ => delete $args{"__$_"} }
                       grep { s/^__// } # filter and strip leading __
                       keys %args;

    my $jx_class = $self->jx_record_class;
    my $jx_meta = $self->jx_meta->{'create'};

    if ( my $quick = $jx_meta->{'quick'}
        and join(',', sort keys %args) eq join(',', sort @{$jx_meta->{'quick'}{'columns'}}) 
    ) {
        my $response = $self->jx->soap->basic_call(
            $quick->{'operation'},
            map { $quick->{'rewrite'} || $_ => $args{$_} }
                @{ $quick->{'columns'} }
        );

        # load self to get defaults
        return $self->load( id => $response );
    }

    my $defaults = $self->record_template;
    $args{$_} = $defaults->{$_} foreach
        grep !exists $args{$_}, keys %$defaults;

    $jx_meta->{'defaults'}->( $self, \%args )
        if $jx_meta->{'defaults'};

    my $jx_operation = $self->auto_method( $jx_meta->{'operation'}, 'addFull' );
    my $response = $self->jx->soap->basic_call( $jx_operation, rec => \%args );
    #warn "created $jx_class #$response using ". Dumper( \%args );

    return $response if $private_args{do_not_load};

    # load self to get defaults
    return $self->load( id => $response );
}

sub update {
    my $self = shift;
    my %args = @_;

    my $jx_class = $self->jx_record_class;
    my $jx_meta = $self->jx_meta->{'update'};

    my $leading_column = $jx_meta->{'leading'} || 'id';

    my %op_args = ();
    foreach my $col ( @{ $self->jx_columns } ) {
        if ( $col eq $leading_column ) {
            if ( exists $args{ $col } ) {
                my $val = $args{ $col };
                if ( defined $val && length $val && $val eq $self->$col() ) {
                    die "Can not update column '$col' of $jx_class #". $self->$col();
                } else {
                    # just ignore without complain
                    delete $args{ $col };
                }
            }
            # we must pass leading column anyway
            $op_args{ $col } = $self->$col();
        }
        elsif ( exists $args{ $col } ) {
            $op_args{ $col } = delete $args{ $col };
        } else {
            $op_args{ $col } = $self->$col();
        }
    }

    if ( keys %args ) {
        warn "Ignored ". join( ', ', map "'$_'", keys %args )
            ." arguments on update of $jx_class #". $self->$leading_column()
            ." as these are not columns of the record";
    }

    my $jx_operation = $self->auto_method( $jx_meta->{'operation'}, 'modify' );
    my $response = $self->jx->soap->basic_call(
        $jx_operation,
        $jx_meta->{'leading_argname'} || $leading_column => $self->$leading_column(),
        $jx_meta->{'record_argname'} || 'rec' => \%op_args,
    );

    # reload self just in case Journyx may update values on update
    return $self->load( $leading_column => $op_args{ $leading_column } );
}

sub delete {
    my $self = shift;

    my $jx_class = $self->jx_record_class;
    my $jx_meta = $self->jx_meta->{'delete'};
    my $jx_operation = $self->auto_method( $jx_meta->{'operation'}, 'remove' );
    my $leading_column =  $jx_meta->{'leading'} || 'id';
    my $leading_argname =  $jx_meta->{'leading_argname'} || 'id';

    my $response = $self->jx->soap->basic_call(
        $jx_operation, $leading_argname => $self->$leading_column(),
    );

    return $self;
}

sub list {
    die "not implemented"
}


sub attribute {
    my $self = shift;
    my $attr = shift;
    die "Can get attribute of not loaded record";
}

sub _record_template {
    my $self = shift;

    my $jx_class = $self->jx_record_class;
    my $jx_operation = $self->auto_method(
        $self->jx_meta->{'defaults'},
        'getDefault'
    );

    my $response = $self->jx->soap->basic_call( $jx_operation )
        or die "Couldn't get default field values for $jx_class";

    my $record = $response->{$jx_class};
    unless ( $record && ref($record) eq 'HASH' ) {
        die "Couldn't get default field values for $jx_class";
    }
        
    return $record;
}

sub auto_method {
    my $self = shift;
    my ($val, $prefix, $suffix) = @_;
    return $val if $val;

    my $jx_class = $self->jx_record_class;
    $jx_class =~ s/Record$//
        if $self->jx_strip_record_suffix;

    return join '', grep defined && length,
        $prefix, $jx_class, $suffix;
}

no Moose;

1;

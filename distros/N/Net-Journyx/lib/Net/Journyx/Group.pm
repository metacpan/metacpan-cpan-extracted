package Net::Journyx::Group;
use Moose;
extends 'Net::Journyx::Record';

use Scalar::Util qw(blessed);

use constant jx_record_class => 'GroupRecord';
use constant jx_strip_record_suffix => 1;
use constant jx_meta => {
    create => {
        defaults => sub {
            my $self = shift;
            my $args = shift;
            if ( defined $args->{'parent'} && length $args->{'parent'} ) {
                warn "Group's parent field is **deprecated**."
                    ." Please leave this field blank."
                    ." Groups do not have a parent-child relationship.)";
                $args->{'parent'} = '';
            }
        },
    },
};

sub object_classes {
    my $res = (shift)->jx->soap->basic_call('getGroupObjectClasses');
    $res = [$res] unless ref($res) eq 'ARRAY';
    return sort @$res;
}

require Sub::Install;

our @special_members = qw(code project subcode subsubcode user);
our %special_members = map {$_ => 1} @special_members;

foreach my $type ( @special_members ) {
    Sub::Install::install_sub({
       code => sub { return (shift)->list_records($type, @_) },
       into => __PACKAGE__,
       as   => $type .'s',
    });
    Sub::Install::install_sub({
       code => sub { return (shift)->add_record($type, @_) },
       into => __PACKAGE__,
       as   => "add_". $type,
    });
    Sub::Install::install_sub({
       code => sub { return (shift)->delete_record($type, @_) },
       into => __PACKAGE__,
       as   => "delete_". $type,
    });
}

use Data::Dumper;

sub list_records {
    my $self   = shift;
    my $type   = lc(shift);
    my ($res, $trace) = $self->jx->soap->basic_call(
        'listGroupObjects',
        group_id_name => $self->id,
        object_class  => $type,
    );
    $res = [$res] unless ref($res) eq 'ARRAY';

    # XXX: Strange but operation returns string 'Other' as well
    return grep defined && length && $_ ne 'Other', @$res;
}

sub add_record {
    my $self   = shift;
    my $type   = lc(shift);
    my $record = shift;

    my $record_id = blessed($record)? $record->id : $record;

    if ( $special_members{ $type } || ($type =~ s/^(.*)s$/$1/ && $special_members{ $type }) ) {

        my $res = $self->jx->soap->basic_call(
            'add'. ucfirst($type) .'ToGroup',
            id    => $record_id,
            group => $self->id,
        );
    } else {
        my $res = $self->jx->soap->basic_call(
            'addObjectToGroup',
            group_id_name => $self->id,
            object_class  => $type,
            object_id_name => $record_id,
        );
    }
}

sub delete_record {
    my $self   = shift;
    my $type   = lc(shift);
    my $record = shift;

    my $record_id = blessed($record)? $record->id : $record;

    if ( $special_members{ $type } || ($type =~ /^(.*)s$/ && $special_members{ $1 }) ) {
        $type = $1 || $type;
        my $res = $self->jx->soap->basic_call(
            'remove'. ucfirst($type) .'FromGroup',
            id    => $record_id,
            group => $self->id,
        );
    } else {
        my $res = $self->jx->soap->basic_call(
            'removeObjectFromGroup',
            group_id_name  => $self->id,
            object_class   => $type,
            object_id_name => $record_id,
        );
    }
}

1;

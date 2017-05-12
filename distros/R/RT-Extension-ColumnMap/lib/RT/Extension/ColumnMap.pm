use 5.008003;
use strict;
use warnings;

package RT::Extension::ColumnMap;

our $VERSION = '0.02';

=head1 NAME

RT::Extension::ColumnMap - bring ColumnMap to libraries

=head1 DESCRIPTION

This extension provides API to turn ColumnMap like strings
into values. It can be used in other extensions and/or
local customizations.

=cut

our %MAP;

$MAP{'RT::Record'} = {
    _default => sub { return $_[0]->id },

    id => sub { return $_[0]->id },

    ( map { my $m = $_ .'Obj'; $_ => sub { return $_[0]->$m() } }
    qw(Created LastUpdated CreatedBy LastUpdatedBy) ),

    CustomField => sub {
        my $obj = shift;
        my %args = @_;
        return $obj->CustomFieldValues( @{ $args{'Arguments'}[0] } )
    },
};

$MAP{'RT::Ticket'} = {
    ( map { my $m = $_ .'Obj'; $_ => sub { return $_[0]->$m() } }
    qw(Queue Owner Starts Started Told Due Resolved) ),

    ( map { my $m = $_; $_ => sub { return $_[0]->$m() } }
    qw(
        Status Subject
        Priority InitialPriority FinalPriority
        EffectiveId Type
        TimeWorked
    ) ),
};

foreach my $type (qw(Requestor Cc AdminCc)) {
    my $method = $type eq 'Requestor'? $type.'s': $type;
    my $map = {
        Trailing => sub { return $_[0]->$method()->UserMembersObj },
        Default => sub { return $_[0]->$method() },
    };
    $MAP{'RT::Ticket'}{$type} = $MAP{'RT::Ticket'}{$type .'s'} = $map;
}

$MAP{'RT::Transaction'} = {
    ( map { my $m = $_; $_ => sub { return $_[0]->$m() } }
    qw(
        Object
        Type Field
        OldValue NewValue
    ) ),
};

$MAP{'RT::ObjectCustomFieldValue'} = {
    ( map { my $m = $_; $_ => sub { return $_[0]->$m() } }
    qw(Object Content) ),

    ( map { my $m = $_ .'Obj'; $_ => sub { return $_[0]->$m() } }
    qw(CustomField) ),
};


$MAP{'RT::User'} = {
    _default => sub { return $_[0]->Name },

    ( map { my $m = $_; $_ => sub { return $_[0]->$m() } }
    qw(Name Comments Signature EmailAddress FreeformContactInfo
    Organization RealName NickName Lang EmailEncoding WebEncoding
    ExternalContactInfoId ContactInfoSystem ExternalAuthId
    AuthSystem Gecos HomePhone WorkPhone MobilePhone PagerPhone
    Address1 Address2 City State Zip Country Timezone PGPKey) ),
};

use Storable qw(dclone);
use Scalar::Util qw(blessed);


use Regexp::Common qw(delimited);
use Regexp::Common::WithActions;

my $re_quoted = qr/$RE{delimited}{-delim=>q{'"}}{-esc=>'\\'}/;
my $dequoter = $RE{delimited}{-delim=>q{'"}}{-esc=>'\\'}->action('dequote');
my $re_not_quoted = qr/[^{}'"\\]+/;

my $re_arg_value = qr/ $re_quoted | $re_not_quoted /x;
my $re_arg = qr/\.?{$re_arg_value}/x;

my $re_field_name = qr/\w+/;
my $re_field = qr/$re_field_name $re_arg*/x;

my $re_column = qr/$re_field(?:\.$re_field)*/;

my %LOCAL_RE = (
    column => $re_column,
    field_name => $re_field_name,
    field => $re_field,
    argument => $re_arg,
);

sub RE {
    my $self = shift;
    my $name = shift or die "Must specify regular expression to return";
    return $LOCAL_RE{ lc $name } or die "Unknown regular expression '$name'";
}

sub Get {
    my $self = shift;

    my ($struct, $object) = $self->FindStart( @_ );

    return $self->_Get( $struct, $object );
}

sub FindStart {
    my $self = shift;
    my %args = (String => undef, Objects => undef, @_);

    my $struct = $self->Parse( $args{'String'} );

    my @objects;
    while ( my ($k, $v) = each %{ $args{'Objects'} } ) {
        my %tmp = (
            object => $v,
            struct => $self->Parse( $k )
        );
        push @objects, \%tmp;
    }
    @objects = sort { @{$b->{struct}} <=> @{$b->{struct}} } @objects;

    my $prefix;
    foreach ( @objects ) {
        $prefix = $_;
        last if $self->IsPrefix( $prefix->{'struct'} => $struct );
    }
    return undef unless $prefix;

    splice @$struct, 0, scalar @{$prefix->{'struct'}};

    return $struct, $prefix->{'object'};
}


sub _Get {
    my $self = shift;
    my $struct = shift;
    my $object = shift;

    my ($entry, $callback) = $self->Entry( $struct, $object );
    die "boo" unless $entry;

    my %args = ( Arguments => [] );
    foreach ( grep ref $_, @{$struct}[0 .. @$entry-1] ) {
        push @{ $args{'Arguments'} }, $_->{'arguments'};
    }
    my $value = $callback->( $object, %args );
    splice @$struct, 0, scalar @$entry;
    return $value;
}

sub Check {
    my $self = shift;
    my %args = @_;

    my ($struct, $object) = $self->FindStart( @_ );
    die "Couldn't find prefix" unless $struct;

    return $self->_Check($struct, $object, $args{'Checker'} );
}

sub _Check {
    my $self = shift;
    my ($struct, $object, $checker) = @_;

    my $value = $self->_Get( $struct, $object );
    unless ( @$struct ) {
        if ( blessed $value ) {
            $value = $self->_Get(['_default'], $value);
            return $checker->( $value );
        } else {
            return $checker->( $value );
        }
    } else {
        die "Recieved value instead of object in the middle"
            unless blessed $value;

        if ( $value->isa('RT::SearchBuilder') ) {
            my $executed = 0;
            while ( my $entry = $value->Next ) {
                my $executed = 1;
                my $res = $self->_Check(
                    Storable::dclone($struct), $entry, $checker
                );
                return $res if $res;
            }
            return $checker->(undef) unless $executed;
        } elsif ( $value->isa('RT::Record') ) {
            return $self->_Check( $struct, $value, $checker );
        } else {
            die "Don't know how to continue with $value";
        }
    }
}

sub Entry {
    my $self = shift;
    my ($struct, $object) = (shift, shift);
    
    my ($entry, $callback) = $self->_Entry( $struct, $object, @_ );
    if ( !$entry && blessed $object && $object->isa('RT::Record') ) {
        ($entry, $callback) = $self->_Entry( $struct, 'RT::Record', @_ );
    }
    return ($entry, $callback) unless $entry;
    return ($entry, $callback) unless ref $callback eq 'HASH';

    $callback =
        (@$struct == @$entry? $callback->{'Trailing'} : undef)
        || $callback->{'Default'};

    return ($entry, $callback);
}

sub _Entry {
    my $self = shift;
    my $struct = shift;
    my $object = shift;

    my $type = ref $object || $object;
    my $map = $MAP{$type} or die "No map for $type";

    foreach my $e ( sort {length $b <=> length $a } keys %$map ) {
        my $parse = $self->Parse($e);
        next unless $self->IsPrefix(
            $parse => $struct,
            SkipArguments => 1
        );
        return ($parse, $map->{$e});
    }
    return ();
}

sub Parse {
    my $self = shift;
    my $string = shift;
    return $string if ref $string;
    return [] unless defined $string && length $string;

    my @fields = split /\.(?=$re_field)/o, $string;
    foreach my $field ( @fields ) {
        my ($name, $args_string) = ($field =~ /^($re_field_name)(.*)/);
        next unless length $args_string;

        my @args;
        push @args, $1 while $args_string =~ s/^\.?{($re_arg_value)}//;
        $dequoter->($_) foreach @args;
        $field = { name => $name, arguments => \@args };
    }
    return \@fields;
}

sub IsPrefix {
    my $self = shift;
    my $what = shift;
    my $in = shift;
    my %args = @_;

    return 1 unless @$what;
    return 0 if @$what > @$in;
    foreach ( my $i = 0; $i < @$what; $i++ ) {
        my ($l, $r) = map ref $_? $_->{name} : $_, $what->[$i], $in->[$i];
        return 0 unless $l eq $r;
        next if $args{'SkipArguments'};

        ($l, $r) = map ref $_? $_->{arguments} : [], $what->[$i], $in->[$i];
        return 0 unless @$l == @$r;
        return 0 if grep $l->[$_] ne $r->[$_], 0 .. (@$l-1);
    }
    return 1;
}


=head1 LICENSE

Under the same terms as perl itself.

=head1 AUTHOR

Ruslan Zakirov E<lt>Ruslan.Zakirov@gmail.comE<gt>

=cut

1;

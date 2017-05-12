package Rose::Planter::Soil;

=head1 NAME

Rose::Planter::Soil -- default base object class for classes created by Rose::Planter.

=head1 DESCRIPTION

This provides a few extra handy functions and
defaults for manipulating Rose classes.

=head1 METHODS

=cut

use strict;
use warnings;

use Log::Log4perl qw/:easy/;
use base 'Rose::DB::Object';
use Rose::DB::Object::Helpers qw/:all/;

=head2 as_hash

Like Rose::DB::Object::Helper::as_tree but with a few differences :

- parent keys in a child table are excluded.

- datetimes are returned in ISO 8601 format.

- the parameter skip_re can be given to skip columns matching a regex.

- only one-to-one and one-to-many relationships are traversed

=cut

sub as_hash {
    my $self = shift;
    my %args = @_;
    my $skip_re     = $args{skip_re};
    my $parent      = $args{_parent};
    my %parent_columns;

    if ($parent) {
        %parent_columns = reverse $parent->column_map;
    }

    my %h; # to be returned.

    for my $col ( $self->meta->columns ) {
        next if $parent_columns{$col->name};
        my $accessor = $col->accessor_method_name;
        my $value    = scalar( $self->$accessor );
        if (ref $value eq 'DateTime') {
            # timezone may be a DateTime::TimeZone::OffsetOnly
            # whose name is e.g. -0400.  It needs to be -04:00 for iso 8601.
            my $offset = $value->time_zone->name;
            $value = $value->iso8601;
            if ($offset =~ /\d{4}/ ) {
                $offset=~ s/00$/:00/;
                $value .= $offset;
            } elsif ($offset =~ /^UTC|floating/) {
                # ok
            } else {
                # Could this happen with an explicitly set timezone?
                WARN "unrecognized timezone name : $offset";
            }
        }
        next if $skip_re && $accessor =~ /$skip_re/;
        $h{$accessor} = $value;
    }

    for my $rel ($self->meta->relationships) {
        next unless $rel->object_has_related_objects($self); # undocumented API call
        my $name = $rel->name;
        die "cannot recurse" unless $self->can($name);
        if ($rel->type eq 'one to one') {
                $h{$name}  = $self->$name->as_hash( _parent => $rel);
        } elsif ($rel->type eq 'one to many') {
            my @children = $self->$name;
            for my $child (@children) {
                die "cannot dump $name" unless $child->can('as_hash');
                $h{$name} ||= [];
                push @{ $h{$name} }, $child->as_hash( _parent => $rel);
            }
        } else {
            # warn "relationship type ".$rel->type." not implemented in as_hash";
            # silently skip many-to-one relationships
        }
    }

    return \%h;
}

=head2 nested_tables

Get or set a list of "nested table" associated with this
class.  These are tables which are always retrieved alongside
this one.

=cut

our %NestedMap;
sub nested_tables {
    # The Right way to do this is probably to provide our own base meta class, too.
    my $self = shift;
    my $class = ref $self || $self;
    return $NestedMap{$class} unless @_ > 0;
    $NestedMap{$class} = ref($_[0]) ? shift : [ @_ ];
    return $NestedMap{$class};
}

1;


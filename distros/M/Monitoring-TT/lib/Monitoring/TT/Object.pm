package Monitoring::TT::Object;

use strict;
use warnings;
use utf8;
use Carp;
use Monitoring::TT::Object::Contact;
use Monitoring::TT::Object::Host;

#####################################################################

=head1 NAME

Monitoring::TT::Object - Object representation of a data item

=head1 DESCRIPTION

contains generic methods which can be used in templates for each object

=cut

#####################################################################

=head1 CONSTRUCTOR

=head2 new

returns new object

=cut
sub new {
    my( $class, $type, $data ) = @_;
    $type = substr($type, 0, -1);
    my $objclass = 'Monitoring::TT::Object::'.ucfirst($type);
    my $obj      = \&{$objclass."::BUILD"};
    die("no such type: $type") unless defined &$obj;
    $data->{'object_type'} = lc($type);
    my $current_object = &$obj($objclass, $data);
    $current_object->{'montt'}->{$type.'spossible_tags'} = {} unless defined $current_object->{'montt'}->{$type.'spossible_tags'};
    $current_object->{'possibletags'} = $current_object->{'montt'}->{$type.'spossible_tags'};
    return $current_object;
}

#####################################################################

=head1 METHODS

=head2 has_tag

returns true if object has specific tag, false otherwise.

=cut
sub has_tag {
    my( $self, $tag, $val ) = @_;
    $tag = lc($tag);
    $self->{'possibletags'}->{$tag} = 1;
    return &_has_something($self, 'conf', $tag, $val) || &_has_something($self, 'extra_tags', $tag, $val) || &_has_something($self, 'tags', $tag, $val);
}

#####################################################################

=head2 tags

returns list of tags or empty list otherwise

=cut
sub tags {
    my( $self ) = @_;
    return $self->{'tags'} if exists $self->{'tags'};
    return [];
}

#####################################################################

=head2 extra_tags

returns list of extra tags or empty list otherwise

=cut
sub extra_tags {
    my( $self ) = @_;
    return $self->{'extra_tags'} if exists $self->{'extra_tags'};
    return [];
}

#####################################################################

=head2 tag

returns value of this tag or empty string if not set

=cut
sub tag {
    my( $self, $tag, $val ) = @_;
    croak('tag() does not accept value, use has_tag() instead') if $val;
    $tag = lc $tag;
    $self->{'montt'}->{$self->{'object_type'}.'spossible_tags'}->{$tag} = 1;
    if($self->{'extra_tags'}->{$tag} and $self->{'tags'}->{$tag}) {
        my @list = @{$self->{'extra_tags'}->{$tag}};
        push @list, ref $self->{'tags'}->{$tag} eq 'ARRAY' ? @{$self->{'tags'}->{$tag}} : $self->{'tags'}->{$tag};
        return(Monitoring::TT::Utils::get_uniq_sorted(\@list));
    }
    return $self->{'extra_tags'}->{$tag} if $self->{'extra_tags'}->{$tag};
    return $self->{'tags'}->{$tag}       if $self->{'tags'}->{$tag};
    return $self->{'conf'}->{$tag}       if $self->{'conf'}->{$tag};
    return "";
}

#####################################################################

=head2 set_tag

set additional tag

=cut
sub set_tag {
    my( $self, $tag, $val ) = @_;
    return $self->_set_something('extra_tags', $tag, $val);
}

#####################################################################
# INTERNAL SUBS
#####################################################################
sub _has_something {
    my( $self, $type, $tag, $val ) = @_;
    return 0 unless exists $self->{$type};
    $tag = lc $tag;
    return 0 unless exists $self->{$type}->{$tag};
    if(defined $val) {
        $val = lc $val;
        my $tags = $self->{$type}->{$tag};
        if(ref $tags eq 'ARRAY') {
            for my $a (@{$tags}) {
                return 1 if lc($a) eq $val;
            }
        } else {
            return 1 if lc($tags) eq $val;
        }
    } else {
        return 1 if exists $self->{$type}->{$tag};
    }
    return 0;
}

#####################################################################
sub _set_something {
    my( $self, $type, $tag, $val ) = @_;
    $tag = lc $tag;
    $val = "" unless defined $val;
    $self->{$type}->{$tag} = [] unless defined $self->{$type}->{$tag};
    if(ref $self->{$type}->{$tag} ne 'ARRAY') {
        $self->{$type}->{$tag} = Monitoring::TT::Utils::get_uniq_sorted([$self->{$type}->{$tag}, $val]);
    } else {
        $self->{$type}->{$tag} = Monitoring::TT::Utils::get_uniq_sorted([@{$self->{$type}->{$tag}}, $val]);
    }
    return "";
}

#####################################################################

=head1 AUTHOR

Sven Nierlein, 2013, <sven.nierlein@consol.de>

=cut

1;

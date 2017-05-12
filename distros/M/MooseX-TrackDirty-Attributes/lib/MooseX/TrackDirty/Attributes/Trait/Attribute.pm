#
# This file is part of MooseX-TrackDirty-Attributes
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::TrackDirty::Attributes::Trait::Attribute;
BEGIN {
  $MooseX::TrackDirty::Attributes::Trait::Attribute::AUTHORITY = 'cpan:RSRCHBOY';
}
$MooseX::TrackDirty::Attributes::Trait::Attribute::VERSION = '2.003';
# ABSTRACT: Track dirtied attributes

use Moose::Role;
use namespace::autoclean;
use MooseX::Types::Perl ':all';
use MooseX::AttributeShortcuts 0.008;

use Moose::Util::MetaRole;
use MooseX::TrackDirty::Attributes::Util ':all';
use MooseX::TrackDirty::Attributes::Trait::Attribute::Native::Trait ();

# roles to help us track / do-the-right-thing when native traits are also used
Moose::Util::MetaRole::apply_metaroles(
    for            => __PACKAGE__->meta,
    role_metaroles => {
        role                    => [ trait_for 'Role' ],
        application_to_class    => [ ToClass          ],
        application_to_role     => [ ToRole           ],
        application_to_instance => [ ToInstance       ],
    },
);


# debugging
#use Smart::Comments '###', '####';

has is_dirty       => (is => 'ro', isa => Identifier, predicate => 1);
has original_value => (is => 'ro', isa => Identifier, predicate => 1);
has cleaner        => (is => 'ro', isa => Identifier, predicate => 1);

# ensure that our is_dirty option is correct, as we apparently cannot rely on
# $self->name anymore.  *le sigh*
after _process_options => sub {
    my ($class, $name, $options) = @_;

    $options->{is_dirty} = $name . '_is_dirty'
        unless defined $options->{is_dirty};

    return;
};

has value_slot => (is => 'lazy', isa => 'Str');
has dirty_slot => (is => 'lazy', isa => 'Str');

sub _build_value_slot { shift->name                        }
sub _build_dirty_slot { shift->name . '__DIRTY_TRACKING__' }

around slots => sub {
    my ($orig, $self) = @_;
    return ($self->$orig(), $self->dirty_slot);
};

before set_value => sub {
    my ($self, $instance) = @_;

    my $mi = $self->associated_class->get_meta_instance;

    my $_get    = sub { $mi->get_slot_value($instance, @_)      };
    my $_set    = sub { $mi->set_slot_value($instance, @_)      };
    my $_exists = sub { $mi->is_slot_initialized($instance, @_) };

    $_set->($self->dirty_slot, $_get->($self->value_slot))
        if $_exists->($self->value_slot) && !$_exists->($self->dirty_slot);

    return;
};

sub mark_clean { shift->clear_dirty_slot(@_) }
after clear_value => sub { shift->clear_dirty_slot(@_) };

around _inline_clear_value => sub {
    my ($orig, $self) = (shift, shift);
    my ($instance) = @_;

    my $mi = $self->associated_class->get_meta_instance;

    return $self->$orig(@_)
        . $self->_inline_mark_clean(@_)
        ;
};

sub _inline_mark_clean {
    my ($self, $instance) = @_;

    my $mi = $self->associated_class->get_meta_instance;
    return $mi->inline_deinitialize_slot($instance, $self->dirty_slot);
}

sub _inline_is_dirty_set {
    my $self = shift;
    my ($instance, $value) = @_;

    # set tracker if dirty_slot is not init and value_slot value_slot is

    my $mi = $self->associated_class->get_meta_instance;
    return $mi->inline_set_slot_value($instance, $self->dirty_slot, $value);
}

sub _inline_is_dirty_get {
    my $self = shift;
    my ($instance, $value) = @_;

    # set tracker if dirty_slot is not init and value_slot value_slot is

    my $mi = $self->associated_class->get_meta_instance;
    return $mi->inline_get_slot_value($instance, $self->dirty_slot, $value);
}

sub _inline_set_dirty_slot_if_dirty {
    my ($self, $instance, $value) = @_;
    # set dirty_slot from value_slot if dirty_slot is not init and value_slot value_slot is

    ### $instance
    ### $value

    my $mi = $self->associated_class->get_meta_instance;
    my $_exists = sub { $mi->inline_is_slot_initialized($instance, shift) };

    # use our predicate method if we have one, as it may have been wrapped/etc
    my $value_slot_exists
        = $self->has_predicate
        ? "${instance}->" . $self->predicate . '()'
        : $_exists->($self->value_slot)
        ;

    my $dirty_slot_exists = $_exists->($self->dirty_slot);

    my $set_dirty_slot = $self
        ->_inline_is_dirty_set(
            $instance,
            'do { ' .  $mi->inline_get_slot_value($instance, $self->value_slot) . ' } ',
        )
        ;

    my $code =
        "do { $set_dirty_slot } " .
        "   if $value_slot_exists && !$dirty_slot_exists;"
        ;

    return $code;
}

around _inline_instance_set => sub {
    my ($orig, $self) = (shift, shift);
    my ($instance, $value) = @_;

    my $code = $self->_inline_set_dirty_slot_if_dirty(@_);
    $code = "do { $code; " . $self->$orig(@_) . " }";

    ### $code
    return $code;
};

# TODO remove_accessors

sub mark_tracking_dirty { shift->set_dirty_slot(@_) }

sub original_value_get { shift->is_dirty_get(@_) }

sub is_dirty_set {
    my ($self, $instance) = @_;

    return $self
        ->associated_class
        ->get_meta_instance
        ->set_slot_value($instance, $self->dirty_slot)
        ;
}

sub is_dirty_get {
    my ($self, $instance) = @_;

    return $self
        ->associated_class
        ->get_meta_instance
        ->get_slot_value($instance, $self->dirty_slot)
        ;
}

sub is_dirty_instance {
    my ($self, $instance) = @_;

    return $self
        ->associated_class
        ->get_meta_instance
        ->is_slot_initialized($instance, $self->dirty_slot)
        ;
}

sub clear_dirty_slot {
    my ($self, $instance) = @_;

    return $self
        ->associated_class
        ->get_meta_instance
        ->deinitialize_slot($instance, $self->dirty_slot)
        ;
}

around accessor_metaclass => sub {
    my ($orig,$self,@args) = @_;

    my $classname = Moose::Meta::Class->create_anon_class(
        superclasses => [ $self->$orig(@args) ],
        roles        => [ 'MooseX::TrackDirty::Attributes::Trait::Method::Accessor' ],
        cache        => 1,
    )->name;

    return $classname;
};

after install_accessors => sub { shift->install_trackdirty_accessors(@_) };

sub install_trackdirty_accessors {
    my ($self, $inline) = @_;
    my $class = $self->associated_class;

    ### in install_accessors...
    $class->add_method(
        $self->_process_accessors(is_dirty => $self->is_dirty, $inline)
    ) if $self->has_is_dirty;
    $class->add_method(
        $self->_process_accessors(original_value => $self->original_value, $inline)
    ) if $self->has_original_value;
    $class->add_method(
        $self->_process_accessors(cleaner => $self->cleaner, $inline)
    ) if $self->has_cleaner;

    return;
};

before remove_accessors => sub { shift->remove_trackdirty_accessors(@_) };

sub remove_trackdirty_accessors {
    my $self = shift @_;

    # stolen from Class::MOP::Attribute
    my $_remove_accessor = sub {
        my ($accessor, $class) = @_;
        if (ref($accessor) && ref($accessor) eq 'HASH') {
            ($accessor) = keys %{$accessor};
        }
        my $method = $class->get_method($accessor);
        $class->remove_method($accessor)
            if (ref($method) && $method->isa('Class::MOP::Method::Accessor'));
    };

    $_remove_accessor->($self->is_dirty,       $self->associated_class) if $self->is_dirty;
    $_remove_accessor->($self->original_value, $self->associated_class) if $self->original_value;

    return;
};


!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Ceccarelli Gianni attribute's

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

MooseX::TrackDirty::Attributes::Trait::Attribute - Track dirtied attributes

=head1 VERSION

This document describes version 2.003 of MooseX::TrackDirty::Attributes::Trait::Attribute - released December 23, 2014 as part of MooseX-TrackDirty-Attributes.

=head1 DESCRIPTION

This is a trait for attribute metaclasses.  You really don't need to do
anything with it; you want L<MooseX::TrackDirty::Attributes>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::TrackDirty::Attributes|MooseX::TrackDirty::Attributes>

=item *

L<MooseX::TrackDirty::Attributes>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/RsrchBoy/moosex-trackdirty-attributes>
and may be cloned from L<git://https://github.com/RsrchBoy/moosex-trackdirty-attributes.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/moosex-trackdirty-attributes/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://www.gittip.com/RsrchBoy/"><img src="https://raw.githubusercontent.com/gittip/www.gittip.com/master/www/assets/%25version/logo.png" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fmoosex-trackdirty-attributes&title=RsrchBoy's%20CPAN%20MooseX-TrackDirty-Attributes&tags=%22RsrchBoy's%20MooseX-TrackDirty-Attributes%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr this|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fmoosex-trackdirty-attributes&title=RsrchBoy's%20CPAN%20MooseX-TrackDirty-Attributes&tags=%22RsrchBoy's%20MooseX-TrackDirty-Attributes%20in%20the%20CPAN%22>,
L<gittip me|https://www.gittip.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

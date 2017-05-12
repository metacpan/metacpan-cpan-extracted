#
# This file is part of MooseX-TrackDirty-Attributes
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::TrackDirty::Attributes::Trait::Method::Accessor;
BEGIN {
  $MooseX::TrackDirty::Attributes::Trait::Method::Accessor::AUTHORITY = 'cpan:RSRCHBOY';
}
$MooseX::TrackDirty::Attributes::Trait::Method::Accessor::VERSION = '2.003';
# ABSTRACT: Track dirtied attributes

use Moose::Role;
use namespace::autoclean;

# debugging
#use Smart::Comments '###', '####';

sub _generate_cleaner_method {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return sub {
        confess "Clearer accessors take no arguments"
            if @_ > 1;
        $attr->mark_clean($_[0]);
    };
}

sub _generate_cleaner_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return try {
        $self->_compile_code([
            'sub {',
                'if (@_ > 1) {',
                    # XXX: this is a hack, but our error stuff is terrible
                    $self->_inline_throw_error(
                        '"Clearer accessors take no arguments"',
                        'data => \@_'
                    ) . ';',
                '}',
                $attr->_inline_mark_clean('$_[0]'),
            '}',
        ]);
    }
    catch {
        confess "Could not generate inline clearer because : $_";
    };
}

sub _generate_original_value_method {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return sub {
        confess "Cannot assign a value to a read-only accessor"
            if @_ > 1;
        $attr->is_dirty_get($_[0]);
    };
}

sub _generate_original_value_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return try {
        $self->_compile_code([
            'sub {',
                'if (@_ > 1) {',
                    # XXX: this is a hack, but our error stuff is terrible
                    $self->_inline_throw_error(
                        '"Cannot assign a value to a read-only accessor"',
                        'data => \@_'
                    ) . ';',
                '}',
                $attr->_inline_is_dirty_get('$_[0]'),
            '}',
        ]);
    }
    catch {
        confess "Could not generate inline original_value because : $_";
    };
}

sub _generate_is_dirty_method {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return sub {
        confess "Cannot assign a value to a read-only accessor"
            if @_ > 1;
        $attr->is_dirty_instance($_[0]);
    };
}

sub _generate_is_dirty_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return try {
        $self->_compile_code([
            'sub {',
                'if (@_ > 1) {',
                    # XXX: this is a hack, but our error stuff is terrible
                    $self->_inline_throw_error(
                        '"Cannot assign a value to a read-only accessor"',
                        'data => \@_'
                    ) . ';',
                '}',
                $attr->_inline_is_dirty_instance('$_[0]'),
            '}',
        ]);
    }
    catch {
        confess "Could not generate inline is_dirty because : $_";
    };
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Ceccarelli Gianni attribute's

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

MooseX::TrackDirty::Attributes::Trait::Method::Accessor - Track dirtied attributes

=head1 VERSION

This document describes version 2.003 of MooseX::TrackDirty::Attributes::Trait::Method::Accessor - released December 23, 2014 as part of MooseX-TrackDirty-Attributes.

=head1 DESCRIPTION

This is a trait for accessor methods.  You really don't need to do anything
with it; you want L<MooseX::TrackDirty::Attributes>.

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

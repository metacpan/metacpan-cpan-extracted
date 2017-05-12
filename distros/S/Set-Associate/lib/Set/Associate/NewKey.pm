use 5.006;
use strict;
use warnings;

package Set::Associate::NewKey;

# ABSTRACT: New Key assignment methods

our $VERSION = '0.004001';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp qw( croak );
use Moose qw( has with );
use MooseX::AttributeShortcuts;

use Set::Associate::Utils qw( _warn_nonmethod );









has name => (
  isa      => Str =>,
  is       => rwp =>,
  required => 1,
);









has code => (
  isa      => CodeRef =>,
  is       => rwp     =>,
  required => 1,
  traits   => ['Code'],
  handles  => {
    get_assoc => execute_method =>,
  },
);

with 'Set::Associate::Role::NewKey' => { can_get_assoc => 1, };

__PACKAGE__->meta->make_immutable;
no Moose;


















sub linear_wrap {
  shift @_ unless _warn_nonmethod( $_[0], __PACKAGE__, 'linear_wrap' );
  require Set::Associate::NewKey::LinearWrap;
  return Set::Associate::NewKey::LinearWrap->new(@_);
}

















sub random_pick {
  shift @_ unless _warn_nonmethod( $_[0], __PACKAGE__, 'random_pick' );
  require Set::Associate::NewKey::RandomPick;
  return Set::Associate::NewKey::RandomPick->new(@_);
}























sub pick_offset {
  shift @_ unless _warn_nonmethod( $_[0], __PACKAGE__, 'pick_offset' );
  require Set::Associate::NewKey::PickOffset;
  return Set::Associate::NewKey::PickOffset->new(@_);
}



















sub hash_sha1 {
  shift @_ unless _warn_nonmethod( $_[0], __PACKAGE__, 'hash_sha1' );
  require Set::Associate::NewKey::HashSHA1;
  return Set::Associate::NewKey::HashSHA1->new(@_);
}



















sub hash_md5 {
  shift @_ unless _warn_nonmethod( $_[0], __PACKAGE__, 'hash_md5' );
  require Set::Associate::NewKey::HashMD5;
  return Set::Associate::NewKey::HashMD5->new(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Set::Associate::NewKey - New Key assignment methods

=head1 VERSION

version 0.004001

=head1 DESCRIPTION

This class implements the mechanism which controls how the values are assigned to 'new' keys.

The part you're mostly interested in are the L</CLASS METHODS>, which return the right assignment method.

This is more or less a wrapper for passing around subs with an implicit interface.

    my $assigner = Set::Associate::NewKey->new(
        name => 'linear_wrap',
        code => sub {
            my ( $self, $sa , $key ) = @_;
            ....
        },
    );

    my $value = $assigner->run( $set_associate_object, $key );

=head1 CONSTRUCTOR ARGUMENTS

=head2 name

    required Str

=head2 code

    required CodeRef

=head1 CLASS METHODS

=head2 linear_wrap

C<shift>'s the first item off the internal C<_items_cache>

    my $sa = Set::Associate->new(
        ...
        on_new_key => Set::Associate::NewKey->linear_wrap
    );

or alternatively

    my $code = Set::Associate::NewKey->linear_wrap
    my $newval = $code->run( $set, $key_which_will_be_ignored );

=head2 random_pick

non-destructively picks an element from C<_items_cache> at random.

    my $sa = Set::Associate->new(
        ...
        on_new_key => Set::Associate::NewKey->random_pick
    );

or alternatively

    my $code = Set::Associate::NewKey->random_pick
    my $newval = $code->run( $set, $key_which_will_be_ignored );

=head2 pick_offset

Assuming offset is numeric, pick either that number, or a modulo of that number.

B<NOTE:> do not use this unless you are only working with numeric keys.

If you're using anything else, the hash_sha1 or hash_md5 methods are suggested.

    my $sa = Set::Associate->new(
        ...
        on_new_key => Set::Associate::NewKey->pick_offset
    );

or alternatively

    my $code = Set::Associate::NewKey->pick_offset
    my $newval = $code->run( $set, 9001 ); # despite picking numbers OVER NINE THOUSAND
                                           # will still return items in the array

=head2 hash_sha1

B<requires C<bigint> support>

Determines the offset for L</pick_offset> from taking the numeric value of the C<SHA1> hash of the given string

    my $sa = Set::Associate->new(
        ...
        on_new_key => Set::Associate::NewKey->hash_sha1
    );

or alternatively

    my $code = Set::Associate::NewKey->hash_sha1();
    my $newval = $code->run( $set, "Some String" );

=head2 hash_md5

B<requires C<bigint> support>

Determines the offset for L</pick_offset> from taking the numeric value of the MD5 hash of the given string

    my $sa = Set::Associate->new(
        ...
        on_new_key => Set::Associate::NewKey->hash_md5
    );

or alternatively

    my $code = Set::Associate::NewKey->hash_md5();
    my $newval = $code->run( $set, "Some String" );

=head1 ATTRIBUTES

=head2 name

=head2 code

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

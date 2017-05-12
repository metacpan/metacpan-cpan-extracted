package PHP::Serialization::XS;

use strict;
use warnings;
use bytes;

use PHP::Serialization ();

require Exporter;

our @ISA = qw(PHP::Serialization Exporter);

our %EXPORT_TAGS = (all => [ qw(serialize unserialize) ]);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} };

our $VERSION = '0.08';

our %DEFAULT_OPTS = (
    prefer_hash  => 0,
    prefer_array => 1,
    prefer_undef => 0,
);

require XSLoader;
XSLoader::load('PHP::Serialization::XS', $VERSION);

# in XS
sub new;

sub unserialize
{
    my ($str, $class) = @_;
    return __PACKAGE__->new(%DEFAULT_OPTS)->decode($str, $class);
}

sub serialize
{
    goto \&PHP::Serialization::serialize;
}

sub decode
{
    my ($self, $str, $class) = @_;
    $self = $self->new(%DEFAULT_OPTS) unless ref $self;
    return $self->_c_decode($str || "", $class);
}

sub encode
{
    my ($self, @rest) = @_;
    my $parent = $self->_get_parent;
    return $parent->encode(@rest);
}

1;
__END__

=head1 NAME

PHP::Serialization::XS - simple flexible means of converting the output
of PHP's serialize() into the equivalent Perl memory structure, and vice
versa - XS version.

=head1 SYNOPSIS

    use PHP::Serialization:XS qw(serialize unserialize);
    my $encoded = serialize({ a => 1, b => 2 });
    my $hashref = unserialize($encoded);

    my $psx = PHP::Serialization::XS->new(prefer_hash => 1);
    my $hash = $psx->decode("a:0:{}");
    my $psy = PHP::Serialization::XS->new(prefer_array => 1);
    my $array = $psy->decode("a:0:{}");

Also see L<PHP::Serialization>.

=head1 DESCRIPTION

This module provides the same interface as L<PHP::Serialization>, but
uses XS during deserialization, for speed enhancement.

If you have code written for C<PHP::Serialization>, you should be able to
replace all references to C<PHP::Serialization> with
C<PHP::Serialization::XS> and notice no change except for an increase in
speed of deserialization.

Node that serialization is still provided by C<PHP::Serialization>, and
its speed should therefore not be affected. This is why
C<PHP::Serialization::XS> requires C<PHP::Serialization> to be
installed.

=head1 CAVEATS

PHP "arrays" are all associative ; some of them just happen to have all
numeric keys. L<PHP::Serialization> tries to Do What You Mean by
converting PHP arrays with gapless numeric indices from 0..n into a
Perl array instead of a hash. This may be convenient, but by itself
it is wrong, because it is not predictable. The special case of an empty
array stands out : if there are no keys, should the resulting structure
be an array or a hash ? Neither answer works universally, so the code
that uses the Perl structure has to check for both cases on every access.

For this reason, PHP::Serialization::XS accepts two additional options
to its C<new()> constructor, C<prefer_hash> and C<prefer_array>.
Currently, C<prefer_array> is the default, for backward-compatibility
reasons, but if you wish your code to act consistently, you should
always use the OO interface and specify the behavior you want (this
configurability is not available through the procedural interface).

=head1 TODO

More tests.

=head1 SEE ALSO

L<PHP::Serialization>

=head1 AUTHOR

Darren Kulp, E<lt>kulp@cpan.orgE<gt>

Tests stolen shamelessly from Tomas Doran's L<PHP::Serialization> package.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Darren Kulp

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut


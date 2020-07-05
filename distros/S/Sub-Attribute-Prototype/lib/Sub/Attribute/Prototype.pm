#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Sub::Attribute::Prototype;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

C<Sub::Attribute::Prototype> - polyfill for C<:prototype> attribute on older perls

=head1 SYNOPSIS

   use Sub::Attribute::Prototype;

   sub afunc :prototype(&@) {
      ...
   }

=head1 DESCRIPTION

This polyfill allows a module to use the C<:prototype> function attribute to
apply a prototype to a function, even on perls too old to natively support it.

Perl version 5.20 introduced the C<:prototype> attribute, as part of the wider
work surrounding subroutine signatures. This allows a function to declare a
prototype even when the C<use feature 'signatures'> pragma is in effect.

If a newer version of perl switches the defaults to making signature syntax
default, it will no longer be possible to write prototype-using functions
using the old syntax, so authors will have to use C<:prototype> instead. By
using this polyfill module, an author can ensure such syntax is still
recognised by perl versions older than 5.20.

When used on a version of perl new enough to natively support the
C<:prototype> attribute (i.e. 5.20 or newer), this module does nothing. Any
C<:prototype> attribute syntax used by the user of this module is simply
handled by core perl in the normal way.

When used on an older version of perl, a polyfilled compatibility attribute
is provided to the caller to (mostly) perform the same work that newer
versions of perl would do; subject to some caveats.

=head2 Caveats

The following caveats should be noted about the pre-5.20 polyfilled version
of the C<:prototype> attribute.

=over 4

=item *

Due to the way that attributes are applied to functions, it is not possible
to apply the prototype immediately during compiletime. Instead, they must be
deferred until a slightly later time. The earliest time that can feasibly be
implemented is C<UNITCHECK> time of the importing module.

This has the unfortunate downside that function prototypes are B<NOT> visible
to later functions in the module itself, though they are visible to the
importing code in the usual way. This means that exported functions will work
just fine from the perspective of a module that C<use>s them, they cannot be
used internally within the module itself.

Because this limitation only applies to the polyfilled version of the
attribute for older versions of perl, it means the behavior will differ on a
newer version of perl. Thus it is important that if you wish call a prototyped
function from other parts of your module, you I<must> use the
prototype-defeating form of

   my $result = &one_of_my_functions( @args )

in order to get reliable behaviour between older and newer perl versions.

=item *

Perl versions older than 5.20 will provoke a warning in the C<reserved>
category when they encounter the attribute syntax provided by this polyfill,
even though the polyfill has consumed the attribute. In order not to cause this
warning to appear to users of modules using this syntax, it is necessary for
this polyfill to suppress the entire C<reserved> warning category. This means
that all such warnings will be silenced, including those about different
attributes.

=item *

Because core perl does not have a built-in way for exporter to inject a
C<UNITCHECK> block into their importer, it is necessary to use a non-core XS
module, L<B::CompilerPhase::Hook>, to provide this. As a result, this polyfill
has non-core depenencies when running on older perl versions, and this
dependency includes XS (i.e. compiled) code, and is no longer Pure Perl. It
will not be possible to use tools such as L<App::FatPacker> to bundle this
dependency in order to ship a pure-perl portable script.

=back

It should be stressed that none of these limitations apply when running on a
version of perl 5.20 or later. Though in that case there is no need to use
this polyfill at all, because the C<:prototype> attribute will be natively
recognised.

=cut

sub import
{
   # Perl 5.20 onwards already recognises a :prototype attribute, so we've
   # nothing to do
   return if $] >= 5.020;

   my $pkg = caller;

   require Sub::Util; Sub::Util->VERSION( '1.40' );
   require B::CompilerPhase::Hook;

   my @prototypes;

   my $MODIFY_CODE_ATTRIBUTES = sub {
      my ( $pkg, $code, @attrs ) = @_;

      my @ret;
      foreach my $attr ( @attrs ) {
         if( $attr =~ m/^prototype\((.*)\)$/ ) {
            my $prototype = "$1";
            push @prototypes, [ $code, $prototype ];
            next;
         }
         push @ret, $attr;
      }

      return @ret;
   };
   { no strict 'refs'; *{"${pkg}::MODIFY_CODE_ATTRIBUTES"} = $MODIFY_CODE_ATTRIBUTES }

   B::CompilerPhase::Hook::enqueue_UNITCHECK( sub {
      foreach ( @prototypes ) {
         my ( $code, $prototype ) = @$_;
         Sub::Util::set_prototype( $_->[1], $_->[0] );
      }
   } );

   warnings->unimport( qw( reserved ) );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

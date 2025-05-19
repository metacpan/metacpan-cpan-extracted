package MooX::Const;

# ABSTRACT: Syntactic sugar for constant and write-once Moo attributes

use utf8;
use v5.14;

use Carp qw( croak );
use Devel::StrictMode;
use Moo       ();
use Moo::Role ();
use Scalar::Util qw/ blessed /;
use Types::Const qw( Const );
use Types::Standard qw( is_CodeRef Value Object Ref );

# RECOMMEND PREREQ: Types::Const v0.3.6
# RECOMMEND PREREQ: Type::Tiny::XS
# RECOMMEND PREREQ: MooX::TypeTiny

use namespace::autoclean;

our $VERSION = 'v0.6.3';


sub import {
    my $class = shift;

    my $target = caller;

    my $installer =
      $target->isa("Moo::Object")
      ? \&Moo::_install_tracked
      : \&Moo::Role::_install_tracked;

    if ( my $has = $target->can('has') ) {
        my $new_has = sub {
            $has->( _process_has(@_) );
        };
        $installer->( $target, "has", $new_has );
    }

}

sub _process_has {
    my ( $name, %opts ) = @_;

    my $strict = STRICT || ( $opts{strict} // 1 );

    my $is = $opts{is};

    my $once = $is && $is eq "once";

    if ($is && $is =~ /^(?:const|once)$/ ) {

        if ( my $isa = $opts{isa} ) {

            unless ( blessed($isa) && $isa->isa('Type::Tiny') ) {
                croak "isa must be a Type::Tiny type";
            }

            if ($isa->is_a_type_of(Value)) {

                if ($once) {

                    croak "write-once attributes are not supported for Value types";

                }
                else {

                    $opts{is}  = 'ro';

                }

            }
            else {

                unless ( $isa->is_a_type_of(Ref) ) {
                    croak "isa must be a type of Types::Standard::Ref";
                }

                if ( $isa->is_a_type_of(Object) ) {
                    croak "isa cannot be a type of Types::Standard::Object";
                }

                if ($strict) {
                    $opts{isa} = Const[$isa];
                    if ( my $next = $opts{coerce} ) {

                        if (is_CodeRef($next)) {
                            $opts{coerce} = sub { $opts{isa}->coercion->( $next->( $_[0] ) ) };
                        }
                        else {
                            $opts{coerce} = sub { $opts{isa}->coercion->( $isa->coercion->( $_[0] ) ) };
                        }
                    }
                    else {
                        $opts{coerce} = $opts{isa}->coercion;
                    }
                }

                $opts{is} = $once ? 'rw' : 'ro';

            }

            if ($opts{trigger} && ($is ne "once")) {
                croak "triggers are not applicable to const attributes";
            }

            if ($opts{writer} && ($is ne "once")) {
                croak "writers are not applicable to const attributes";
            }

            if ($opts{clearer}) {
                croak "clearers are not applicable to const attributes";
            }

        }
        else {

            croak "Missing isa for a const attribute";

        }

    }

    return ( $name, %opts );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::Const - Syntactic sugar for constant and write-once Moo attributes

=head1 VERSION

version v0.6.3

=head1 SYNOPSIS

  use Moo;
  use MooX::Const;

  use Types::Standard -types;

  has thing => (
    is  => 'const',
    isa => ArrayRef[HashRef],
  );

=head1 DESCRIPTION

This is syntactic sugar for using L<Types::Const> with L<Moo>. The
SYNOPSIS above is equivalent to:

  use Types::Const -types;

  has thing => (
    is     => 'ro',
    isa    => Const[ArrayRef[HashRef]],
    coerce => 1,
  );

It modifies the C<has> function to support "const" attributes.  These
are read-only ("ro") attributes for references, where the underlying
data structure has been set as read-only.

This will return an error if there is no "isa", the "isa" is not a
L<Type::Tiny> type, if it is not a reference, or if it is blessed
object.

Simple value types such as C<Int> or C<Str> are silently converted to
read-only attributes.

As of v0.5.0, it also supports write-once ("once") attributes for
references:

  has setting => (
    is  => 'once',
    isa => HashRef,
  );

This allows you to set the attribute I<once>. The value is coerced
into a constant, and cannot be changed again.

Note that "wo" is a removed synonym for "once". It no longer works in
v0.6.0, since "wo" is used for "write-only" in some Moose-like
extensions.

As of v0.4.0, this now supports the C<strict> setting:

  has thing => (
    is     => 'const',
    isa    => ArrayRef[HashRef],
    strict => 0,
  );

When this is set to a false value, then the read-only constraint will
only be applied when running in strict mode, see L<Devel::StrictMode>.

If omitted, C<strict> is assumed to be true.

=head1 KNOWN ISSUES

Accessing non-existent keys for hash references will throw an
error. This is a feature, not a bug, of read-only hash references, and
it can be used to catch mistakes in code that refer to non-existent
keys.

Unfortunately, this behaviour is not replicated with array references.

See L<Types::Const> for other known issues related to the C<Const>
type.

=head2 Using with Moose and Mouse

This module appears to work with L<Moose>, and there is now a small
test suite.

It does not work with L<Mouse>. Pull requests are welcome.

=head1 SUPPORT FOR OLDER PERL VERSIONS

Since v0.6.0, the this module requires Perl v5.14 or later.

Future releases may only support Perl versions released in the last ten years.

If you need this module on Perl v5.10, please use one of the v0.5.x
versions of this module.  Significant bug or security fixes may be
backported to those versions.

=head1 SEE ALSO

<MooX::Readonly::Attribute>, which has similar functionality to this module.

L<Const::Fast>

L<Devel::StrictMode>

L<Moo>

L<MooseX::SetOnce>

L<Sub::Trigger::Lock>

L<Types::Const>

L<Type::Tiny>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/MooX-Const>
and may be cloned from L<git://github.com/robrwo/MooX-Const.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/MooX-Const/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

This module was inspired by suggestions from Kang-min Liu 劉康民
<gugod@gugod.org> in a L<blog post|http://blogs.perl.org/users/robert_rothenberg/2018/11/typeconst-released.html>.

=head1 CONTRIBUTOR

=for stopwords Kang-min Liu 劉康民

Kang-min Liu 劉康民 <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2025 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

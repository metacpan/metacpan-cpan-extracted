package MooX::Const;

# ABSTRACT: Syntactic sugar for constant and write-once Moo attributes

use utf8;
use v5.8;

use Carp qw( croak );
use Moo       ();
use Moo::Role ();
use Safe::Isa qw( $_isa );
use Types::Const qw( Const );
use Types::Standard qw( Value Object Ref );

use namespace::autoclean;

our $VERSION = 'v0.2.0';


sub VERSION { # for older Perls
    my ( $class, $wanted ) = @_;
    require version;
    return version->parse($VERSION);
}


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

    my $is = $opts{is};

    if ($is && $is =~ /^(?:const|wo)$/ ) {

        if ( my $isa = $opts{isa} ) {

            unless ( $isa->$_isa('Type::Tiny') ) {
                croak "isa must be a Type::Tiny type";
            }

            if ($isa->is_a_type_of(Value)) {

                if ($is eq 'wo') {

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

                $opts{isa} = Const[$isa];
                $opts{coerce} = $opts{isa}->coercion;

                if ($opts{trigger} && ($is ne 'wo')) {
                    croak "triggers are not applicable to const attributes";
                }

                $opts{is}  = $is eq 'wo' ? 'rw' : 'ro';

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

version v0.2.0

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

As of v0.2.0, it also supports write-once ("wo") attributes for
references:

  has setting => (
    is  => 'wo',
    isa => HashRef,
  );

This allows you to set the attribute I<once>. The value is coerced
into a constant, and cannot be changed again.

=for Pod::Coverage VERSION

=head1 SEE ALSO

L<Moo>

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

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

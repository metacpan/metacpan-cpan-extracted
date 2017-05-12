package Parse::RecDescent::Topiary;
use strict;
use warnings;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.05';
    @ISA         = qw(Exporter);
    @EXPORT      = qw(topiary);
    @EXPORT_OK   = qw(topiary delegation_class);
    %EXPORT_TAGS = ( all => [qw/topiary delegation_class/] );
}

=head1 NAME

Parse::RecDescent::Topiary - tree surgery for Parse::RecDescent autotrees

=head1 SYNOPSIS

  use Parse::RecDescent::Topiary;
  my $parser = Parse::RecDescent->new($grammar);
  ...
  my $tree = topiary(
  		tree => $parser->mainrule,
		namespace => 'MyModule::Foo',
		ucfirst => 1
		);

=head1 DESCRIPTION

L<Parse::RecDescent> has a mechanism for automatically generating parse trees.
What this does is to bless each resulting node into a package namespace
corresponding to the rule. This might not be desirable, for a couple of
reasons:

=over 4

=item *

You probably don't want to pollute the top-level namespace with packages,
and you probably don't want your grammar rules to be named according to CPAN
naming conventions. Also, the namespaces could collide if an application has
two different RecDescent grammars, that share some rule names.

=item *

Parse::RecDescent merely blesses the data structures. It does not call a
constructor. Parse::RecDescent::Topiary calls C<new> for each class. A base
class, L<Parse::RecDescent::Topiary::Base> is provided in the distribution,
to construct hashref style objects. The user can always supply their own -
inside out or whatever.

=back

=head2 C<topiary>

This is a function which recursively rebuilds an autotree returned by 
L<Parse::RecDescent>, using constructors for each node.

This exported function takes a list of option / value pairs:

=over 4

=item C<tree>

Pass in the resulting autotree returned by a Parse::RecDescent object.

=item C<namespace>

If not specified, topiary will not use objects in the new parse tree. This
can be specified either as a single prefix value, or a list of namespaces
as an arrayref.

As the tree is walked, each blessed node is used to form a candidate
class name, and if such a candidate class has a constructor, i.e. if
C<Foo::Bar::Token-E<gt>can('new')> returns true, this will be used to
construct the new node object (see L<delegation_class>).

If a list of namespaces are given, each one is tried in turn, until a 
C<new> method is found. If no constructor is found, the node is built
as a data structure, i.e. it is not blessed or constructed.

=item C<ucfirst>

Optional flag to upper case the first character of the rule when forming the
class name.

=item C<consolidate>

Optional flag that causes topiary to reduce the nesting, unambiguously, of 
optionally quantified productions. The production foo(?) causes generation
of the hash entry 'foo(?)' containing an arrayref of either 0 or 1 elements
depending whether foo was present or not in the input string.

If consolidate is a true value, topiary processes this entry, and either
generates a hash entry foo => foo_object if foo was present, or does not
generate a hash entry if it was absent.

=item C<args>

Optional user arguments passed in. These are available to the constructors,
and the default constructor will put them into the new objects as 
$self->{__ARGS__}.

=back

=head2 C<delegation_class>

  @class_list = qw(Foo::Bar Foo::Baz);
  my $class = delegation_class( 'Dongle', \@class_list, 'wiggle' );

This subroutine is not exported by default, and is used internally by topiary.
C<$class> is set to C<Foo::Bar::Dongle> if 
C<Foo::Bar::Dongle-E<gt>can('wiggle')> or set to C<Foo::Baz::Dongle> if
C<Foo::Baz::Dongle-E<gt>can('wiggle')> or return undef if no match is found.

=head1 BUGS

Please report bugs to http://rt.cpan.org

=head1 AUTHOR

    Ivor Williams
    CPAN ID: IVORW
     
    ivorw@cpan.org
     

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Parse::RecDescent>.

=cut

use Params::Validate::Dummy qw();
use Module::Optional qw(Params::Validate :all);
use Scalar::Util qw(blessed reftype);

sub topiary {
    my %par = validate(
        @_,
        {   tree      => 1,
            namespace => {
                regex   => qr/\w+(\:\:\w+)*/,
                type    => SCALAR | ARRAYREF,
                default => '',
            },
            ucfirst     => 0,
            args        => 0,
            consolidate => 0,
        }
    );

    my $tree      = $par{tree};
    my $namespace = $par{namespace};
    my @ns        = ref($namespace) ? @$namespace : ($namespace);
    my $origpkg   = blessed $tree;
    my $class;
    if ($origpkg) {
        $origpkg = ucfirst $origpkg if $par{ucfirst};
        $class = delegation_class( $origpkg, \@ns, 'new' );
    }

    my $type = reftype($tree) || '';
    my $rv;
    if ( $type eq 'ARRAY' ) {
        my @proto = map { topiary( %par, tree => $_ ) } @$tree;
        if ($class) {
            if ( exists $par{args} ) {
                push @proto, __ARGS__ => $par{args};
            }
            $rv = $class->new(@proto);
        }
        else {
            $rv = \@proto;
        }
    }
    elsif ( $type eq 'HASH' ) {

        #my %proto = map { $_, topiary( %par, tree => $tree->{$_} ) }
        my %proto = map { _consolidate_hash( $_, $tree->{$_}, \%par ) }
            keys %$tree;
        if ($class) {
            if ( exists $par{args} ) {
                $proto{__ARGS__} = $par{args};
            }
            $rv = $class->new(%proto);
        }
        else {
            $rv = \%proto;
        }
    }
    else {
        $rv = $class ? $class->new($tree) : $tree;
    }
    return $rv;
}

sub _consolidate_hash {
    my ( $key, $tree, $args ) = @_;

    return $key, topiary( %$args, tree => $tree ) unless $args->{consolidate};
    if ( $key =~ /(\w+)\(\?\)$/ ) {
        return () unless @$tree;
        return $1, topiary( %$args, tree => $tree->[0] );
    }
    return $key, topiary( %$args, tree => $tree );
}

sub delegation_class {
    my ( $node, $plist, $method ) = @_;

    for my $prefix (@$plist) {
        my $pclass = $prefix . '::' . $node;
        next unless $pclass->can($method);
        return $pclass;
    }
    undef;
}

1;

# The preceding line will help the module return a true value


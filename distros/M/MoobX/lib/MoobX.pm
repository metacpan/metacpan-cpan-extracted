package MoobX;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Reactive programming framework heavily inspired by JavaScript's MobX
$MoobX::VERSION = '0.1.0';

use 5.20.0;

use MoobX::Observer;

our @DEPENDENCIES;
our $WATCHING = 0;

use Scalar::Util qw/ reftype refaddr /;
use Moose::Util qw/ with_traits /;
use Module::Runtime 'use_module';
use Graph::Directed;

use experimental 'signatures';

use parent 'Exporter::Tiny';

our @EXPORT = qw/ observer observable autorun :attributes :traits /;

our $WARN_NO_DEPS = 1;

sub _exporter_expand_tag {
    my( $class, $name, $args, $globals ) = @_;

    if ( $name eq 'attributes' ) {
        my $target = $globals->{into};

        eval qq{
            package $target;
            use parent 'MoobX::Attributes';
            1;
        } or die $@;
    }
    elsif( $name eq 'traits' ) {
        use_module( 'MoobX::Trait::'.$_) for qw/ Observer Observable /;
    }

    return ();
}

our $graph = Graph::Directed->new;

sub observable_modified($obs) {

    my @preds = $graph->all_predecessors( refaddr $obs );

    for my $pred ( @preds ) {
        my $info = $graph->get_vertex_attribute(
            $pred, 'info'
        );

        local @MoobX::DEPENDENCIES = ( @MoobX::DEPENDENCIES, $obs );
        $info->clear_value;
    }
}

sub dependencies_for($self,@deps) {
    $graph->delete_edges(
        map { 
            refaddr $self => $_
        } $graph->successors(refaddr $self)
    );

    $graph->add_edges( 
        map { refaddr $self => refaddr $_ } @deps 
    );

    $graph->set_vertex_attribute(
        refaddr $_, info => $_ 
    ) for $self, @deps; 
}

sub observable :prototype(\[$%@]) {
    observable_ref( @_ );
}

sub observable_ref {
    my $ref = shift;

    my $type = reftype $ref;

    my $class = 'MoobX::'. ucfirst lc  $type || 'SCALAR';

    $class = with_traits( 
        map { use_module($_) }
        map { $_, $_ . '::Observable' } $class
    );

    if( $type eq 'SCALAR' ) {
        my $value = $$ref;
        tie $$ref, $class;
        $$ref = $value;
    }
    elsif( $type eq 'ARRAY' ) {
        my @values = @$ref;
        tie @$ref, $class;
        @$ref = @values;
    }
    elsif( $type eq 'HASH' ) {
        my %values = %$ref;
        tie %$ref, $class;
        %$ref = %values;
    }
    elsif( not $type ) {
        my $value = $ref;
        tie $ref, $class;
        $ref = $value;
    }


    return $ref;

}

sub observer :prototype(&) { MoobX::Observer->new( generator => @_ ) }
sub autorun  :prototype(&) { MoobX::Observer->new( autorun => 1, generator => @_ ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoobX - Reactive programming framework heavily inspired by JavaScript's MobX

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    use 5.20.0;

    use MoobX;

    my $first_name :Observable;
    my $last_name  :Observable;
    my $title      :Observable;

    my $address = observer {
        join ' ', $title || $first_name, $last_name;
    };

    say $address;  # nothing

    $first_name = "Yanick";
    $last_name  = "Champoux";

    say $address;  # Yanick Champoux

    $title = 'Dread Lord';

    say $address;  # Dread Lord Champoux

=head1 DESCRIPTION

As I was learning how to use L<https://github.com/mobxjs/mobx|MobX>, I thought
it'd be fun to try to implement something similar in Perl. So I did. 

To set Moose object attributes to be observers or observables, take
a gander at L<MoobX::Trait::Observable> and L<MoobX::Trait::Observer>.

To have an idea of the mechanics of MoobX, see the two blog entries in the SEE ALSO
section.

This is also the early stages of life for this module. Consider everythign as alpha quality,
and the API still subject to huge changes.

=head1 EXPORTED FUNCTIONS

The module automatically exports 3 functions: C<observer>, C<observable> and C<autorun>.

=head2 observable

    observable my $foo;
    observable my @bar;
    observable my %quux;

Marks the variable as an observable, i.e. a variable which value can be 
watched by observers, which will be updated when it changes.

Under the hood, the variable is tied to the relevant L<MoobX::TYPE> class 
L<MoobX::TYPE::Observable> role.

If you want to declare the variable, assign it a value and set it as observable,
there are a few good ways to do it, and one bad:

    my $foo = 3;
    observable $foo;            # good

    observable( my $foo = 3 );  # good

    observable my $foo;         # good
    $foo = 3;

    observable my $foo = 3;     # bad

That last one doesn't work because Perl parses it as C<observable( my $foo ) = 3>,
and assigning values to non I<lvalue>ed functions don't work.

Or, better, simply use the C<:Observable> attribute when you define the variable.

    my $foo :Observable = 2;
    my @bar :Observable = 1..10;
    my %baz :Observable = ( a => 1, b => 2 );

=head2 observer

    observable my $quantity;
    observable my $price;

    my $total = observer {
        $quantity * $price
    };

    $quantity = 2;
    $price = 6.00;

    print $total; # 12

Creates a L<MoobX::Observer> object. The value returned by the object will
react to change to any C<observable> values within its definition.

Observers are lazy, meaning that they compute or recompute their values 
when they are accessed. If you want
them to eagerly recompute their values, C<autorun> is what you want.

If an observer function is run and doesn't report any dependency,
it'll emit the warning 'C<MoobX observer doesn't observe anything>',
because chances are there's something weird going on. The warning can 
be silenced via the global variable C<$MoobX::WARN_NO_DEPS>.

    my $foo :Observable;

    my $debugging = 0;

    # if $debugging == 1, we'd get a warning
    local $MoobX::WARN_NO_DEPS = 0;

    my $spy = observer {
        return unless $debugging;

        say $foo;
    };

=head2 autorun 

    observable my $foo;

    autorun {
        say "\$foo is now $foo";
    };

    $foo = 1; # prints '$foo is now 1'

    $foo = 2; # prints '$foo is now 2'

Like C<observer>, but immediatly recompute its value when its observable dependencies change.

=head1 SEE ALSO

=over

=item L<https://github.com/mobxjs/mobx|MobX> - the original inspiration

=item L<http://techblog.babyl.ca/entry/moobx> and L<http://techblog.babyl.ca/entry/moobx-2> - the two blog entries that introduced MobX.

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package MooseX::AttributeInflate;
use warnings;
use strict;
use Moose ();
use Moose::Exporter ();

our $VERSION = '0.03';

Moose::Exporter->setup_import_methods(
    with_caller => ['has_inflated'],
    also => 'Moose',
);

sub has_inflated {
    my $caller = shift;
    my $name = shift;
    my %options = @_;
    $options{traits} ||= [];
    unshift @{$options{traits}}, 'Inflated';
    Class::MOP::Class->initialize($caller)->add_attribute($name, %options);
}

=head1 NAME

MooseX::AttributeInflate - Auto-inflate your Moose attribute objects

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

Lazily constructs ("inflates") an object attribute, optionally using constant
parameters.

    package MyClass;
    use MooseX::AttributeInflate;

    has_inflated 'helper' => (
        is => 'ro', isa => 'MyHelper'
    );

    # OR, explicitly

    has 'helper' => (
        is => 'ro', isa => 'MyHelper',
        traits => [qw/Inflated/],
        inflate_args => [],
        inflate_method => 'new',
    );

    my $obj = MyClass->new();
    $obj->helper->help();

=head1 DESCRIPTION

For each attribute defined with L</has_inflated>, this module overrides the
C<default> for that attribute, calling instead that attribute's type's
constructor.  The construction is done lazily unless overriden with 
C<< lazy => 0 >>.

See L</has_inflated> for options and more detail.

Construction only works with objects; an exception will be thrown if the
C<isa> type of this attribute is not a decendant of C<Object> (this includes
C<ArrayRef> and C<HashRef> types).

Alternatively, you may use the attribute trait C<Inflated> to compose an
attribute with other attribute trais.

=head1 EXPORTS

=head2 has_inflated

Just like Moose's C<has>, but applies the attribute trait C<Inflated> and
defaults C<lazy> to be on.  See L<Moose/EXPORTED FUNCTIONS> for more detail on
C<has>.

If C<lazy_build> is defined, the canonical build method (e.g.
C<_build_helper>) B<IS NOT> called.  Otherwise, C<lazy_build> works as usual,
setting C<required> and installing a clearer and predicate.

Additional options:

=over 4

=item lazy

Defaults on, but can be turned off with C<< lazy => 0 >>.

=item lazy_build

Just like L<Moose>'s C<lazy_build>, but does not call the canonical builder
method (e.g. C<_build_$name>).

=item inflate_method

The name of the constructor to use. Defaults to 'new'.

=item inflate_args

The arguments to pass to the constructor.  Defaults to an empty list.

=back

=head1 SEE ALSO

L<MooseX::CurriedHandles> - combine with this module for auto-inflating moose curry!

L<http://github.com/stash/moosex-attributeinflate/> - Github repository

=head1 AUTHOR

Stash <jstash+cpan@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-attrinflate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-AttributeInflate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::AttributeInflate


You can also look for information at:

=over 4

=item * C<#moose> on irc.perl.org

L<irc://irc.perl.org#moose>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-AttributeInflate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-AttributeInflate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-AttributeInflate>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-AttributeInflate>

=back


=head1 ACKNOWLEDGEMENTS

C<konobi> for Meta-advice and CPAN help

C<perigrin>, C<doy>, C<Sartak> and other C<#moose> folks for suggestions & patches.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jeremy Stashewsky

Copyright 2009 Socialtext Inc., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package MooseX::Meta::Attribute::Trait::Inflated;
use Moose::Role;
use Moose::Util::TypeConstraints ();

has 'inflate_args' => (
    is => 'rw', isa => 'ArrayRef',
    predicate => 'has_inflate_args'
);
has 'inflate_method' => (
    is => 'rw', isa => 'Str',
    default => 'new'
);

sub inflate {
    my $self = shift;
    my $class = $self->type_constraint->name;
    my $ctor = $self->inflate_method;
    return $class->$ctor($self->has_inflate_args ? @{$self->inflate_args} : ());
}

around 'new' => sub {
    my $code = shift;

    my $class = shift;
    my $name = shift;
    my %options = @_;

    $options{lazy} = 1 unless exists $options{lazy};

    if ($options{lazy_build}) {
        delete $options{lazy_build};
        delete $options{builder};
        $options{lazy} = 1;
        $options{required} = 1;
        if ($name =~ /^_/) {
            $options{predicate} ||= "_has$name";
            $options{clearer} ||= "_clear$name";
        }
        else {
            $options{predicate} ||= "has_$name";
            $options{clearer} ||= "clear_$name";
        }
    }
    $options{required} = 1;
    $options{default} = sub {
        $_[0]->meta->get_attribute($name)->inflate()
    };

    my $self = $class->$code($name,%options);

    my $type = $self->type_constraint;
    confess "type constraint isn't a subtype of Object"
        unless $type->is_subtype_of('Object');

    return $self;
};

if ($Moose::VERSION < 1.09) {
    around 'legal_options_for_inheritance' => sub {
        my $code = shift;
        my $self = shift;
        return ($self->$code(@_), 'inflate_args', 'inflate_method')
    };
}


no Moose::Role;

package # happy PAUSE
    Moose::Meta::Attribute::Custom::Trait::Inflated;
sub register_implementation { 'MooseX::Meta::Attribute::Trait::Inflated' }

1;

package MooseX::Scaffold;

use warnings;
use strict;

=head1 NAME

MooseX::Scaffold - Template metaprogramming with Moose

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    package MyScaffolder;

    use MooseX::Scaffold;

    MooseX::Scaffold->setup_scaffolding_import;

    sub SCAFFOLD {
        my $class = shift; my %given = @_;

        $class->has($given{kind} => is => 'ro', isa => 'Int', required => 1);

        # Using MooseX::ClassAttribute
        $class->class_has(kind => is => 'ro', isa => 'Str', default => $given{kind});
    }

    package MyAppleClass;

    use Moose;
    use MooseX::ClassAttribute;
    use MyScaffolder kind => 'apple';

    package MyBananaClass;

    use Moose;
    use MooseX::ClassAttribute;
    use MyScaffolder kind => 'banana';

    # ... meanwhile, back at the Batcave ...

    use MyAppleClass;
    use MyBananaClass;

    my $apple = MyAppleClass->new(apple => 1);
    my $banana = MyBananaClass->new(banana => 2);

=head1 DESCRIPTION

MooseX::Scaffold is a tool for creating or augmenting Moose classes on-the-fly. 

Scaffolding can be triggered when a C<use> is executed (any import arguments are passed
to the scaffold subroutine) or you can explicitly call MooseX::Scaffold->scaffold with the scaffolding
subroutine and the package name for the class.

Depending on what you're trying to do, MooseX::Scaffold can behave in three different ways (Assume My::Class is the class
you're trying to create/augment):

    load_and_scaffold (scaffold)   - Attempt to require My::Class from My/Class.pm or do Moose::Meta::Class->create('My::Class')
                                     to make the package on-the-fly. Scaffold the result.

    load_or_scaffold (load)        - Attempt to require My::Class from My/Class.pm and stop if that works. If no My/Class.pm is
                                     found in @INC, then make a Moose class on-the-fly and scaffold it.
                                     This option can be used to create a default class if one isn't found.

    scaffold_without_load          - Don't attempt to require My::Class, just create it on-the-fly and scaffold it.

=head1 METHODS

=head2 MooseX::Scaffold->scaffold( ... )

Scaffold a class by either loading it or creating it. You can pass through the following:

    scaffolder              
    scaffolding_package     This should be either a subroutine (sub { ... }) or a package name. If a package name
                            is given, then the package should contain a subroutine called SCAFFOLD

    class
    class_package           The package name of resulting class

    load_or_scaffold        Attempt to load $class_package first and do nothing successful. Otherwise create
                            $class_package and scaffold it

    scaffold_without_load   Scaffold $class_package without attempting to load it first. Does not have
                            any effect if $class_package has been loaded already

    no_class_attribute      Set this to 1 to disable applying the MooseX::ClassAttribute meta-role
                            on class creation. This has no effect if the class is loaded (If you
                            want class_has with a loaded class, make sure to 'use MooseX::ClassAttribute')

=head2 MooseX::Scaffold->load_and_scaffold( ... )

An alias for ->scaffold

=head2 MooseX::Scaffold->load_or_scaffold( ... )

An alias for ->scaffold with C<load_or_scaffold> set to 1

=head2 MooseX::Scaffold->load( ... )

An alias for ->load_or_scaffold

=head2 MooseX::Scaffold->scaffold_without_load( ... )

An alias for ->scaffold with C<scaffold_without_load> set to 1

=head2 MooseX::Scaffold->build_scaffolding_import( ... )

Return an anonymous subroutine suitable for use an an import function

Anything passable to ->scaffold is fair game. In addition:

    scaffolder      This will default to the package of caller() if unspecified

    chain_import    An (optional) subroutine that will goto'd after scaffolding is complete

=head2 MooseX::Scaffold->setup_scaffolding_import( ... )

Install an import subroutine. By default, caller() will be used for the exporting package, but
another may be specified.

Anything passable to ->build_scaffolding_import is fair game. In addition:

    exporter
    exporting_package   The package that will house the import subroutine (the scaffolding will trigger
                        when the package is used or imported)

=cut

use Class::Inspector;
use Carp::Clan;
use Moose();
no Moose;
use Moose::Exporter;
use MooseX::ClassAttribute();

use MooseX::Scaffold::Class;

=head2 MooseX::Scaffold->load_package( $package )

=head2 MooseX::Scaffold->load_class( $class )

A convenience method that will attempt to require $package or $class if not already loaded

Essentially does ...

    eval "require $package;" or die $@

... but uses Class::Inspector to check for $package existence first (%INC is not trustworthy)

=cut

sub load_package {
    my $self = shift;
    my $package = shift;
    return 1 if Class::Inspector->loaded($package);
    eval "require $package;" or die $@;
    return 1; # FIXME
}

sub load_class {
    return shift->load_package(@_);
}

sub setup_scaffolding_import {
    my $self = shift;
    my %given = @_;

    my $exporting_package = $given{exporting_package};
    $exporting_package ||= $given{exporter} ? delete $given{exporter} : scalar caller;

    my $scaffolder = $given{scaffolder} ||= scalar caller;

    my ( $import, $unimport ) = $self->build_scaffolding_import( %given );

    eval "package $exporting_package;";
    croak "Couldn't open exporting package $exporting_package since: $@" if $@;

    no strict 'refs';
    *{ $exporting_package . '::import' }   = $import;
}

sub build_scaffolding_import {
    my $self = shift;
    my %given = @_;

    my $scaffolder = $given{scaffolder} ||= scalar caller;
    my $chain_import = $given{chain_import};

    return sub {
        my $CALLER = Moose::Exporter::_get_caller(@_);
        my $exporting_package = shift;

        return if $CALLER eq 'main';

        # TODO Check to see if $CALLER is a Moose::Object?
        $self->scaffold(
            class_package => $CALLER,
            exporting_package => $exporting_package,
            %given, \@_
        );

        goto &$chain_import if $chain_import;
    };
}

sub load {
    my $self = shift;
    return $self->scaffold(@_, load_or_scaffold => 1);
}

sub load_or_scaffold {
    my $self = shift;
    return $self->load(@_);
}

sub load_and_scaffold {
    my $self = shift;
    return $self->scaffold(@_);
}

sub scaffold_without_load {
    my $self = shift;
    return $self->scaffold(@_, scaffold_without_load => 1);
}

sub scaffold {
    my $self = shift;
    my $arguments = [];
    $arguments = pop @_ if ref $_[-1] eq 'ARRAY';
    my %given = @_;

    my $class_package = $given{class_package} || $given{class};
    my $scaffolder = $given{scaffolding_package} || $given{scaffolder};
    my $load_or_scaffold = $given{load_or_scaffold};
    my $scaffold_without_load = $given{scaffold_without_load};
    my $no_class_attribute = $given{no_class_attribute};

    if (Class::Inspector->loaded($class_package)) {
        return if ! $scaffold_without_load && $load_or_scaffold;
    }
    else {
        if (! $scaffold_without_load && Class::Inspector->installed($class_package)) {
            eval "require $class_package;";
            die $@ if $@;
            return if $load_or_scaffold;
        }
        else {
            my $meta = Moose::Meta::Class->create($class_package);
            unless ($no_class_attribute) {
                MooseX::ClassAttribute->init_meta( for_class => $class_package );
            }
        }
    }

    my $scaffolding_package;
    if (ref $scaffolder eq 'CODE') {
    }
    else {
        $scaffolding_package = $scaffolder;
        $self->_load_scaffolding_package( $scaffolding_package );
        $scaffolder = $scaffolding_package->can('SCAFFOLD');
        croak "Unable to find method SCAFFOLD in package $scaffolding_package" unless $scaffolder;
    }

    $self->_scaffold( $class_package, $scaffolder, @$arguments, scaffolding_package => $scaffolding_package );

}

sub _load_scaffolding_package {
    my $self = shift;
    my $scaffolding_package = shift;
    return if Class::Inspector->loaded($scaffolding_package);
    eval "require $scaffolding_package;" or croak "Unable to load scaffolding class $scaffolding_package since: $@";
}

sub _scaffold {
    my $self = shift;
    my $class_package = shift;
    my $scaffolder = shift;

    my $class = MooseX::Scaffold::Class->new($class_package);
    $scaffolder->($class, @_, class_package => $class_package);
}

sub parent_package {
    my $self = shift;
    my $package = shift;
    return $self->repackage($package, undef, shift);
}

sub child_package {
    my $self = shift;
    my $package = shift;
    return $self->repackage($package, shift);
}

sub repackage {
    my $self = shift;
    my $package = shift;
    my $replacement = shift;
    my $count = shift;

    $count = 0 unless defined $count && length $count;

    return $package unless $count >= 1;
    
    my @package = split m/::/, $package;
    pop @package while $count--;
    push @package, $replacement if defined $replacement && length $replacement;
    return join '::', @package;
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SOURCE

You can contribute or fork this project via GitHub:

L<http://github.com/robertkrimen/moosex-scaffold/tree/master>

    git clone git://github.com/robertkrimen/moosex-scaffold.git MooseX-Scaffold

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-classscaffold at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Scaffold>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Scaffold


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Scaffold>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Scaffold>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Scaffold>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Scaffold>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of MooseX::Scaffold

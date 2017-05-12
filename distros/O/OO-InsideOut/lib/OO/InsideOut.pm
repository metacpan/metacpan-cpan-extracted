#!/usr/bin/perl 
package OO::InsideOut;

use 5.008;

use strict;
use warnings;

use Exporter 'import';
use Carp qw(croak);
use Class::ISA ();
use Scalar::Util 1.09 qw(weaken refaddr);

our $VERSION   = '0.03';
our @EXPORT    = qw(); 
our @EXPORT_OK = qw(Dumper id register);

my (%Hash, %Object, %Method);

my $Dumper = eval {
    use Data::Dumper ();
    return \&Data::Dumper::Dumper;
};

### Internal Functions ###

my $classes = sub {
    my $self = shift;

    # no point in returning classes that dont use OO::InsideOut
    return 
        grep { exists $Object{ $_ } }
            Class::ISA::self_and_super_path( ref $self || $self );
};

my $register_object = sub {
    my $self = shift;
    my $id   = id( $self );

    for my $class ( $self->$classes ) {
        my $obj = $Object{ $class };

        # object allready registered, skip
        exists $obj->{ $id }
            && next;

        # to allow object destruction
        weaken( $obj->{ $id } = $self );
    }

    return $self;
};

my $unregister_object = sub {
    my $self = shift;
    my $id   = id( $self );

    for my $class ( $self->$classes ) {
        # Even if there's no new, there can be stored values
        map { delete $_->{ $id } }
            @{ $Hash{ $class } };

        my $obj = $Object{ $class };

        # object may allready been destroyed, skip
        exists $obj->{ $id }
            || next;

        delete $obj->{ $id };

        # force cleanup on classes with no active objects
        unless ( keys %{ $Object{ $class } } ) {
            delete $Hash{ $class };
            delete $Object{ $class };
        }
    }

    return $self;
};

my $register_new = sub {
    my $class = shift;    

    my $new = $class->can('new');

    # no new defined, no object registration needed
    defined $new
        || return;
   
    # we allready wrapped new 
    exists $Method{ refaddr $new }
        && return;

    my $method = sub {
        return shift->$new( @_ )->$register_object;
    };

    no strict 'refs';
    no warnings 'redefine';
    *{ $class . '::new' } = $method;

    return ++$Method{ refaddr $method };
};

my $register_destroy = sub {
    my $class = shift;    

    my $DESTROY = $class->can('DESTROY');
    
    # allready exists a DESTROY method and we allready wrapped it, skip
    $DESTROY
        && exists $Method{ refaddr $DESTROY }
        && return;

    my $method  = sub {
        my $self = shift;

        $DESTROY 
            && $self->$DESTROY();

        $self->$unregister_object;

        return 1;
    };

    no strict 'refs';
    no warnings 'redefine';
    *{ $class . '::DESTROY' } = $method;

    $Method{ refaddr $method }++;

    return 1;
};

my $register_hashes = sub {
    my $class  = shift;
    my @hashes = @_;

    # no hashes, no joy, skip
    scalar @hashes
        or return;

    # we may allready registered this class, skip if so
    unless ( exists $Hash{ $class } ) {
        $class->$register_new;
        $class->$register_destroy;
    }

    # register this class to avoid re-registering
    $Object{ $class } ||= {};
    push @{ $Hash{ $class } }, @hashes;

    # if they ask for it, return this class's object registry
    return defined wantarray ? $Object{ $class } : 1;
};

### Exportable Functions ###

sub Dumper {
    my $object = shift;
    my $id     = id( $object );
   
    my %dump;
    for my $class ( $object->$classes ) {
        exists $Hash{ $class } 
            || next;

        push @{ $dump{ $class } }, 
            map { $_->{ $id } }
                grep { exists $_->{ $id } }
                     @{ $Hash{ $class } };
    }

    return $Dumper->( \%dump );
}

sub id { return refaddr shift; }

sub register {
    my @args   = @_;

    my @hashes = grep { ref eq 'HASH' } @args;
    
    scalar @hashes
        or croak 'must provide, at least, one hash ref!';

    my $caller = caller(0);
    return $caller->$register_hashes( @hashes );
}

### Methods ###

sub CLONE {
    my $class = shift;

    for my $class ( keys %Object ) {
        my $obj = $Object{ $class };

        for my $old ( keys %{ $obj } ) {
            my $new = delete $obj->{ $old };

            map { $_->{ id $new } = delete $_->{ $old } } 
                @{ $Hash{ $class } };

            $new->$register_object;
        }

        return ;
    }
}

1; # End of OO::InsideOut

__END__

=pod

=encoding utf8

=head1 NAME

OO::InsideOut - Minimal support for Inside-Out Classes

=head1 VERSION

0.03

=head1 SYNOPSIS

    package My::Name;

    use OO::InsideOut qw(id register);

    register \my( %Name, %Surname );

    sub new {
        my $class = shift;

        return bless \(my $o), ref $class || $class;
    }

    sub name { 
        my $id = id( shift );

        scalar @_
            and $Name{ $id } = shift;

        return $Name{ $id };
    }

    sub surname { 
        my $id = id( shift );

        scalar @_
            and $Surname{ $id } = shift;

        return $Surname{ $id };
    }

    ...


=head1 EXPORT

Nothing by default but every function, in L<FUNCTIONS>, can be exported on demand.

=head1 DESCRIPTION

B<NOTE: If you're developing for perl 5.10 or later, please consider 
using L<Hash::Util::FieldHash> instead.>

OO::InsideOut provides minimal support for Inside-Out Classes for perl 5.8 
or later. By minimal, understand;

=over 4

=item * No special methods or attributtes;

=item * Don't use source filters or any kind of metalanguage;

=item * No need for a special constructor;

=item * No need to register objects;

=item * No serialization hooks (like Storable, Dumper, etc);

=back


It provides:

=over 4

=item * Automatic object registration;

=item * Automatic object destruction;

=item * Thread support (but not shared);

=item * Foreign inheritance;

=item * mod_perl compatibility 

=back


=head1 FUNCTIONS

=head2 id

    id( $object );

Uses L<Scalar::Util::refaddr|Scalar::Util/refaddr> to return the reference 
address of $object.

=head2 register

    register( @hashrefs );

Register the given hashrefs for proper cleanup.

Returns an HASH ref with registered objects in the CLASS. See L<CAVEATS>.

=head2 Dumper

    Dumper( $object );

If available, uses L<Data::Dumper::Dumper|Data::Dumper/Dumper> to dump the
object's data.

B<WARNING: May be removed in the future!!!>

=head1 HOW IT WORKS

When registering hashes, and only then, B<OO::InsideOut> will:

=over 4

=item * Wrap any new() methodB<*>, in the inheritance tree, with the ability to register objects;

=item * Wrap any DESTROY() methodB<*>, in the inheritance tree, with the ablity to cleanup the object's data;

=item * If no DESTROY() method was found, it provides one in the firs package of the inheritance tree;

=back


B<* This is done only once per package>.

=head1 PERFORMANCE

Every Inside-Out technique, using an B<id> to identify the B<object>, will be 
slower than the classic OO approach: it's just the way it is.

Consider:

    sub name {
        my $self = shift;

        scalar @_
            && $Name{ id( $self ) } = shift;

        return $Name{ id( $self ) );
    }


In this example, the code is calling the B<id> twice, causing uncessary 
overload. If you are going to use B<id> more than once, in the same scope, 
consider saving it in an variable earlier: 

    sub name { 
        my $id = id( shift );

        scalar @_
            && $Name{ $id } = shift;

        return $Name{ $id };
    }


=head1 MIGRATING TO L<Hash::Util::FieldHash>

Bare in mind that, besides the obvious diferences between the two modules, 
in L<Hash::Util::FieldHash>, the cleanup process is triggered before 
calling DESTROY(). In OO::Insideout, this only happens after any 
DESTROY() defined in the package.

See L<How to use Field Hashes|Hash::Util::FieldHas/How to use Field Hashes>.

=head1 DIAGNOSTICS

=over

=item must provide, at least, one hash ref! 

Besides the obvious reason, this migth happen while using C<my> with a list with only one item:

    register \my( %Field ) #WRONG
    register \my %Field    #RIGTH

=back


=head1 CAVEATS

register(), on request, will return an HASH ref with all the objects 
registered in the CLASS. 

If, for any reason, you need to copy/grep this HASH ref, make sure to 
L<weaken|Scalar::Util/weaken> every entry again. See 
L<Scalar::Util::weaken|Scalar::Util/weaken> for more detail on this subject.

=head1 AUTHOR

André "Rivotti" Casimiro, C<< <rivotti at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/ARivottiC/OO-InsideOut/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OO::InsideOut


You can also look for information at:

=over 4

=item * GitHub 

L<https://github.com/ARivottiC/OO-InsideOut>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OO-InsideOut>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OO-InsideOut>

=item * Search CPAN

L<http://search.cpan.org/dist/OO-InsideOut/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 SEE ALSO

L<Alter>, L<Class::InsideOut>, L<Class::Std>, L<Hash::Util::FieldHash>, 
L<Object::InsideOut>.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 André Rivotti Casimiro.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

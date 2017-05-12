package Net::LDAP::Class::MethodMaker;
use strict;
use warnings;
use base qw( Rose::Object::MakeMethods::Generic );
use Carp;
use Data::Dump;

our $VERSION = '0.27';

=head1 NAME

Net::LDAP::Class::MethodMaker - create methods for Net::LDAP::Class classes

=head1 SYNOPSIS

 package MyUser;
 use base qw( Net::LDAP::Class::User );
 use Net::LDAP::Class::MethodMaker (
    'scalar --get_set_init' => [qw( foo )],
    'related_objects'       => [qw( bars )],
 );
 
 __PACKAGE__->metadata->setup(
    base_dn             => 'dc=local',
    attributes          => [qw( foo )],
    unique_attributes   => [qw( foo )],
 );
 
 # must define a fetch_bars method
 sub fetch_bars {
    my $user = shift;
    
    # do something to get bar objects.
    
 }

 1;
 
 # elsewhere
 
 my $user = MyUser->new( foo => '1234' )->read or die;
 $user->foo;        # == $user->ldap_entry->get_value('foo');
 $user->foo(5678);  # == $user->ldap_entry->replace( foo => 5678 );
 $user->foo;        # returns '5678'
 
 my $bars       = $user->bars;  # == $user->fetch_bars;
 push(@$bars, 'new bar');
 $user->bars($bars);
 my $newbars    = $user->bars;  # != $user->fetch_bars;
 $user->clear_bars;
 $newbars       = $user->bars;  # == $user->fetch_bars;
 
 
=head1 DESCRIPTION

Net::LDAP::Class::MethodMaker is a subclass of Rose::Object::MakeMethods::Generic.
It extends the base class with two new method types: related_objects and ldap_entry.

=head1 METHODS

=head2 related_objects( I<name>, I<args> )

The related_objects method type creates three methods for each
I<name> when using the 'get_set' (default) interface: 
C<name>, C<fetch_name>, and C<clear_name>.

The I<fetch_> method must be defined by your class. It should return
values from the LDAP server.

The I<name> method is a get/set method. If nothing is set, it calls
through to I<fetch_>. Otherwise, if you have set something, it returns
what you have set.

The I<clear_> method will delete any set value from the object and return it.

=cut

sub related_objects {
    my ( $class, $name, $args ) = @_;

    my %methods;

    my $key       = $args->{'hash_key'}  || $name;
    my $interface = $args->{'interface'} || 'get_set';

    if ( $interface eq 'get_set_init' ) {
        croak
            "get_set_init interface not supported for related_objects: $name";
    }
    elsif ( $interface eq 'get_set' ) {
        my $fetcher_method = $args->{'fetch_method'} || "fetch_$name";
        $methods{$name} = sub {
            if ( @_ > 1 ) {
                if ( !$_[0]->validate( $key, $_[1] ) ) {
                    croak "validate failed for attribute $key: "
                        . $_[0]->error;
                }
                return $_[0]->{$key} = $_[1];
            }
            return exists $_[0]->{$key}
                ? $_[0]->{$key}
                : $_[0]->$fetcher_method;
        };

        $methods{"clear_$name"} = sub { return delete $_[0]->{$key} };
    }
    else {
        croak "Unknown interface: $interface";
    }

    return \%methods;
}

=head2 ldap_entry

The ldap_entry method type supports the 'get_set' interface only.

This method type negotiates the getting and setting of values
in the delegate ldap_entry() object.

=cut

# get/set attributes on the delegate ldap_entry
sub ldap_entry {
    my ( $class, $name, $args ) = @_;

    if ( $class->can($name) ) {
        carp "class $class already has method for $name";
        return;
    }

    my %methods;

    my $attribute = $args->{'hash_key'}  || $name;
    my $interface = $args->{'interface'} || 'get_set';

    if ( $interface eq 'get_set' ) {

        $methods{$name} = sub {
            my $self = shift;
            my @args = @_;

            # we do not support values of more than one arg
            if ( scalar @args > 1 ) {
                croak "cannot set more than one value at a time";
            }

            # if we haven't yet loaded a Net::LDAP::Entry via read()
            # cache the values and set them when/if we read().
            if ( !defined $self->ldap_entry ) {

                if ( scalar @args ) {
                    $self->{_not_yet_set}->{$attribute} = $args[0];
                }
                return
                    exists $self->{_not_yet_set}->{$attribute}
                    ? $self->{_not_yet_set}->{$attribute}
                    : undef;

            }

# otherwise, delegate to the ldap_entry
#unless ( grep { $_ eq $attribute } @{ $self->attributes } ) {
#                croak
#                    qq[no such attribute or method "$attribute" defined for package "]
#                    . ref($self)
#                    . qq[ -- do you need to add '$attribute' to your setup() call?"];
#            }

            if ( scalar @args ) {

                if ( !$self->validate( $attribute, $args[0] ) ) {
                    croak "validate failed for attribute $attribute: "
                        . $self->error;
                }

                #warn "AUTOLOAD set $attribute -> $args[0]";
                my @old = $self->ldap_entry->get_value($attribute);
                $self->ldap_entry->replace( $attribute, $args[0] );
                $self->{_was_set}->{$attribute}->{new} = $args[0];

       # do not overwrite an existing 'old' value, since we might need to know
       # what was originally in the ldap_entry in order to replace it.
                unless ( exists $self->{_was_set}->{$attribute}->{old} ) {
                    $self->{_was_set}->{$attribute}->{old}
                        = @old > 1 ? \@old : $old[0];
                }
            }

            my (@ret) = ( $self->ldap_entry->get_value($attribute) );
            if (wantarray) {
                return @ret;
            }
            else {
                return @ret > 1 ? \@ret : $ret[0];
            }
        };

    }
    else {
        croak "Unknown interface: $interface";
    }

    return \%methods;
}

=head2 object_or_class_meta

Similar to the 'scalar --get-set-init' method type but may be called as a class method,
in which case it will call through to the class metadata() object.

=cut

sub object_or_class_meta {
    my ( $class, $name, $args ) = @_;

    my %methods;
    my $key         = $args->{'hash_key'}    || $name;
    my $init_method = $args->{'init_method'} || "init_$name";

    $methods{$name} = sub {
        if ( ref( $_[0] ) ) {
            return $_[0]->{$key} = $_[1] if ( @_ > 1 );

            if ( $_[0]->can($init_method) ) {
                return defined $_[0]->{$key}
                    ? $_[0]->{$key}
                    : ( $_[0]->{$key} = $_[0]->$init_method() );
            }
            else {
                return defined $_[0]->{$key}
                    ? $_[0]->{$key}
                    : ( $_[0]->{$key} = $_[0]->metadata->$key );
            }
        }
        else {
            return $_[0]->metadata->$key;
        }
    };

    return \%methods;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-ldap-class at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-Class>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::Class

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-Class>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-Class>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT

Copyright 2008 by the Regents of the University of Minnesota.
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Net::LDAP::Class, Rose::Object::MakeMethods::Generic

=cut

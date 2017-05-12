package Net::LDAP::Class::User;
use strict;
use warnings;
use Carp;
use base qw( Net::LDAP::Class );
use Net::LDAP::Class::MethodMaker (
    'scalar --get_set_init' => [qw( group_class )],
    'related_objects'       => [qw( group groups )],
);

our $VERSION = '0.27';

=head1 NAME

Net::LDAP::Class::User - base class for LDAP user objects

=head1 SYNOPSIS

 package MyUser;
 use strict;
 use base qw( Net::LDAP::Class::User );
 
 # define action_for_* methods for your LDAP schema
 
 1;

=head1 DESCRIPTION

Net::LDAP::Class::User is a simple base class intended to be
subclassed by schema-specific Net::LDAP::Class::User::* classes.

=head1 METHODS

=head2 init

Overrides base method to check that group_class() is defined.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    unless ( defined $self->group_class ) {
        croak "must define group_class()";
    }
    return $self;
}

=head2 add_to_group( I<group_object> )

Adds I<group_object> via the groups() method. A convenience method.

Must call update() to actually write the changes to the LDAP database.

=cut

sub add_to_group {
    my $self = shift;
    my $group = shift or croak "Group required";
    if ( !ref($group) or !$group->isa('Net::LDAP::Class::Group') ) {
        croak "Group should be a Net::LDAP::Class::Group-derived object";
    }
    if ( !$group->ldap_entry ) {
        croak "Group should be read() prior to adding User $self as a member";
    }
    my @groups = @{ $self->groups };
    my $uniq_method;
    for my $g (@groups) {
        $uniq_method ||= $g->unique_attributes->[0];
        if ( $g->$uniq_method eq $group->$uniq_method ) {
            croak "User $self is already a member of Group $group";
        }
    }
    push( @groups, $group );
    $self->groups( \@groups );
    return $self;
}

=head2 remove_from_group( I<group_object> )

Removes I<group_object> using the groups() method. A convenience method.

Must call update() to actually write the changes to the LDAP database.

=cut

sub remove_from_group {
    my $self = shift;
    my $group = shift or croak "Group required";
    if ( !ref($group) or !$group->isa('Net::LDAP::Class::Group') ) {
        croak "Group should be a Net::LDAP::Class::Group-derived object";
    }
    if ( !$group->ldap_entry ) {
        croak
            "Group should be read() prior to removing User $self as a member";
    }
    my @groups = @{ $self->groups };
    my @new;
    my $uniq_method;
    for my $g (@groups) {
        $uniq_method ||= $g->unique_attributes->[0];
        if ( $g->$uniq_method eq $group->$uniq_method ) {
            next;
        }
        push( @new, $g );
    }
    if ( scalar(@new) == scalar(@groups) ) {
        croak "User $self is not a member of $group and cannot be removed.\n"
            . "$self is in these groups: "
            . join( ", ", map {"$_"} @groups );
    }
    $self->groups( \@new );
    return $self;
}

=head2 init_group_class

Default is to croak indicating you must override this method in your subclass.

=cut

sub init_group_class {
    croak "Must override init_group_class() or set group_class in metadata. "
        . "Have you created a group subclass yet?";
}

=head2 stringify

Aliased to username().

=cut

sub stringify { shift->username }

=head2 username

Get/set the value of the first unique attribute.

=cut

sub username {
    my $self = shift;
    my $attr = $self->unique_attributes->[0];
    return $self->$attr(@_);
}

=head2 random_string([I<len>])

Returns a random alphanumeric string of length I<len> (default: 10).

=cut

# possible characters (omits common mistaken letters Oh and el)
my @charset = (
    'a' .. 'k', 'm' .. 'z', 'A' .. 'N', 'P' .. 'Z', '2' .. '9', '.',
    ',',        '$',        '?',        '@',        '!'
);

# sanity check for collisions in tight loops
my %rand_string_cache;

sub random_string {
    my $self = shift;
    my $len = shift || 10;

    # set random seed
    my ( $usert, $system, $cuser, $csystem ) = times;
    srand( ( $$ ^ $usert ^ $system ^ time ) );

    # select characters
    # retry until we get at least:
    #  * one UPPER
    #  * one lower
    #  * one \d
    #  * one \W

    my @chars;
    my $str = '';
    until (    $str =~ /\d/
            && $str =~ /[A-Z]/
            && $str =~ /[a-z]/
            && $str =~ /\W/
            && !$rand_string_cache{$str}++ )
    {
        @chars = ();
        for ( my $i = 0; $i <= ( $len - 1 ); $i++ ) {
            $chars[$i] = $charset[ int( rand($#charset) + 1 ) ];
        }
        $str = join( '', @chars );
    }

    return $str;
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

Net::LDAP

=cut

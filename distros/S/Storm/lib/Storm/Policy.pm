package Storm::Policy;
{
  $Storm::Policy::VERSION = '0.240';
}
use strict;
use warnings;

#
# code modified from Dave Rolsky's Fey::ORM module
#

use Storm::Policy::Object;

use Sub::Exporter -setup => {
    exports => [qw/Policy define deflate inflate transform /],
    groups  => { default => [qw/Policy define deflate inflate transform /] },
};

{
    my %Policies;

    sub Policy {
        my $caller = shift;
        return $Policies{$caller} ||= Storm::Policy::Object->new;
    }
}


sub define {
    my $class = caller();
    my ( $type, $definition ) = @_;
    $class->Policy()->add_definition( $type => $definition );
}

sub deflate (&) {
    return ( deflate => $_[0] );
}

sub inflate (&) {
    return ( inflate => $_[0] );
}

sub transform {
    my $class = caller();
    my $type  = shift;
    $class->Policy()->add_transformation( $type => {@_} );
}

1;



__END__

=pod

=head1 NAME

Storm::Policy - Define how types are stored/retrieve from the database

=head1 SYNOPSIS

    package MyPolicy;
    use Storm::Policy;
    use Moose::Util::TypeConstraints;
    use DateTime::Format::SQLite;

    class_type 'DateTime',
        { class => 'DateTime' };

    define 'DateTime', 'DATETIME';

    transform 'DateTime',
        inflate { DateTime::Format::SQLite->parse_datetime( $_ ) },
        deflate { DateTime::Format::SQLite->format_datetime( $_ ) };


    # and then later

    $storm = Storm->new( source => ... , policy => 'MyPolicy' );
    
=head1 DESCRIPTION

The policy defines how data is stored in the database. Storm::Policy provides
sugar for defining the data type for the DBMS and transforming values on
inflation/deflation.

=head1 SUGAR

=over 4

=item define $type, $dbms_type

C<define> declares the data type to be used by the DBMS (Database Management
Software) when storing values of the given $type.

=item transform inflate \&func, deflate \&func

C<transform> is used to declare how values of the given type will be serialized
when stored to the database. Using transformations can allow you to store
complex objects.

The C<deflate> function is used when storing value to the database. C<$_> is the
value to be deflated, and the return value is what will be saved to the
database.

The C<inflate> function is used when retrieving the value from the database.
C<$_> is the value to be inflated, and the return value is the value Storm will
use.

=back

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

Modified from code in Dave Rolsky's L<Fey::ORM> module.

=head1 COPYRIGHT

    Copyright (c) 2010 Jeffrey Ray Hallock. All rights reserved.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

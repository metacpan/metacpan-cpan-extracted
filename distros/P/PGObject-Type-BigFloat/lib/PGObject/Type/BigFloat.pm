package PGObject::Type::BigFloat;

use 5.010;
use strict;
use warnings;
use base qw(Math::BigFloat);
use PGObject;
use Carp;

=head1 NAME

PGObject::Type::BigFloat - Math::BigFloat wrappers for PGObject classes

=head1 VERSION

Version 2.001

=cut

our $VERSION = 2.001000;

our ($accuracy, $precision, $round_mode, $div_scale);

# Globals
$accuracy = $precision = undef;
$round_mode = 'even';
$div_scale = 40;

=head1 SYNOPSIS

    use PGObject::Type::BigFloat;
    PGObject::Type::BigFloat->register(); # Get all numeric and float types

    my $self->{foo} = PGObject::Type::BigFloat->new(0);

    $self->call_dbmethod(funcname => 'bar'); # will use this as a numeric 
    

=head1 SUBROUTINES/METHODS

=head2 register(registry => 'default', types => ['float4', 'float8', 'numeric'])


=cut

sub register{
    my $self = shift @_;
    my %args = @_;
    croak "Can't pass reference to register \n".
          "Hint: use the class instead of the object" if ref $self;
    my $registry = $args{registry};
    $registry ||= 'default';
    my $types = $args{types};
    $types = ['float4', 'float8', 'numeric'] unless defined $types and @$types;
    for my $type (@$types){
        if ($PGObject::VERSION =~ /^1\./){
            my $ret = 
                PGObject->register_type(registry => $registry, pg_type => $type,
                                  perl_class => $self);
            return $ret unless $ret;
        } else {
            PGObject::Type::Registry->register_type(
                registry => $registry, dbtype => $type, apptype => $self
            );
        }
    }
    return 1;
}

=head2 to_db

This serializes this into a simple db-friendly form.

=cut

sub to_db {
    my $self = shift @_; 
    return undef if $self->is_undef;
    return $self->bstr;
}

=head2 from_db

take simple normalized db floats and turn them into numeric representations.

=cut

sub from_db {
    my ($self, $value) = @_;
    my $obj = "$self"->new($value);
    $obj->is_undef(1) if ! defined $value;
    return $obj;
}

=head2 is_undef(optionally $set);

Return undef to the db or user interface.  Can be set through apps.

=cut

sub is_undef {
    my ($self, $set) = @_; 
    $self->{_pgobject_undef} = $set if defined $set;
    return $self->{_pgobject_undef};
}

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-type-bigfloat at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Type-BigFloat>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Type::BigFloat


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Type-BigFloat>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Type-BigFloat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Type-BigFloat>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Type-BigFloat/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013-2014 Chris Travers.

This program is released under the following license: BSD


=cut

1; # End of PGObject::Type::BigFloat

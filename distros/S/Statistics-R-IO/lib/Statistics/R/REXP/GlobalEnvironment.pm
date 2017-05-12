package Statistics::R::REXP::GlobalEnvironment;
# ABSTRACT: the global R environment (C<.GlobalEnv>)
$Statistics::R::REXP::GlobalEnvironment::VERSION = '1.0001';
use 5.010;

use Class::Tiny::Antlers;
use namespace::clean;

extends 'Statistics::R::REXP::Environment';


sub BUILD {
    my ($self, $args) = @_;

    # Required attribute type
    die 'Global environment has implicit attributes' if defined $self->attributes;
    die 'Global environment has an implicit enclosure' if defined $self->enclosure;
}

sub name {
    'R_GlobalEnvironment'
}


1; # End of Statistics::R::REXP::GlobalEnvironment

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::REXP::GlobalEnvironment - the global R environment (C<.GlobalEnv>)

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::REXP::GlobalEnvironment
    
    my $env = Statistics::R::REXP::GlobalEnvironment->new([
        x => Statistics::R::REXP::Character->new(['foo', 'bar']),
        b => Statistics::R::REXP::Double->new([1, 2, 3]),
    ]);
    print $env->elements;

=head1 DESCRIPTION

An object of this class represents an R environment (C<ENVSXP>), more
often known as the user's workspace. An assignment operation from the
command line will cause the relevant object to be placed in this
environment.

You shouldn't create instances of this class, it exists mainly to
handle deserialization of C<.GlobalEnv> by the C<IO> classes.

=head1 METHODS

C<Statistics::R::REXP:GlobalEnvironment> inherits from
L<Statistics::R::REXP::Environment>, with the added restriction that it
doesn't have attributes or enclosure. Trying to create a
GlobalEnvironment instance that doesn't follow this restriction will
raise an exception.

=head2 ACCESSORS

=over

=item name

Just as in R, the name of the GlobalEnvironment is "R_GlobalEnvironment".

=back

=head1 BUGS AND LIMITATIONS

Classes in the C<REXP> hierarchy are intended to be immutable. Please
do not try to change their value or attributes.

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=for Pod::Coverage BUILD

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

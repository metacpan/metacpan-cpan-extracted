package PGObject::Type::ByteString;

use strict;
use warnings;

use 5.008;
use Carp;
use DBD::Pg qw(:pg_types);

=head1 NAME

PGObject::Type::ByteString - Wrapper for raw strings mapping to BYTEA columns

=head1 VERSION

Version 1.1.2

=cut

our $VERSION = '1.2.0';

=head1 SYNOPSIS

   PGObject::Type::ByteString->register();

Now all BYTEA columns will be returned as ByteString objects.

=head1 DESCRIPTION

This module provides a basic wrapper around Perl strings, mapping them to

=head1 SUBROUTINES/METHODS

=head2 register

By default registers PG_BYTEA

=cut

sub register {
    my $self = shift @_;
    croak "Can't pass reference to register \n".
          "Hint: use the class instead of the object" if ref $self;
    my %args = @_;
    my $registry = $args{registry};
    $registry ||= 'default';
    my $types = $args{types};
    $types = [ DBD::Pg::PG_BYTEA, 'bytea' ] unless defined $types and @$types;
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


=head2 new


=cut

sub new {
    my ($class, $value) = @_;
    my $self;
    croak 'Must pass scalar or scalar ref' 
        if defined ref $value and ref $value !~ /SCALAR/;
    if (ref $value ) {
       $self = $value;
    } else {
       $self = \$value;
    }
    return bless $self, $class;
}


=head2 from_db

Parses a date from YYYY-MM-DD format and generates the new object based on it.

=cut

sub from_db {
    my ($class, $value) = @_;
    return $class->new($value);
}

=head2 to_db

Returns the date in YYYY-MM-DD format.

=cut

sub to_db {
    my ($self) = @_;
    # hashref with value and type allows us to tell DBD::Pg to bind to binary
    return { value => $$self, type => PG_BYTEA };
}

=head1 AUTHOR

Erik Huelsmann, C<< <ehuels at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-pgobject-type-bytestring at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Type-ByteString>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Type::ByteString


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Type-ByteString>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Type-ByteString>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Type-ByteString>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Type-ByteString/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Erik Huelsmann

This program is released under the following license: BSD


=cut

1; # End of PGObject::Type::DateTime

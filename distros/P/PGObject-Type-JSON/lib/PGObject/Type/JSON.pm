package PGObject::Type::JSON;

use 5.010;
use strict;
use warnings;
use PGObject;
use JSON;
use Carp 'croak';
use Scalar::Util 'blessed';


=head1 NAME

PGObject::Type::JSON - JSON wrappers for PGObject

=head1 VERSION

Version 2.1.1

=cut

our $VERSION = '2.1.1';


=head1 SYNOPSIS

   PGOBject::Type::JSON->register();

Columns of type json will be converted into hashrefs

   my $obj =  PGOBject::Type::JSON->new($hashref);

$obj will now serialize to the database as json.

=head1 DESCRIPTION

This module allows json types or others (specified by custom register) types to
be converted from JSON into objects according to their values.

This module assumes that encoding will be in UTF8 across the board and is not
safe to use with other database encodings.

=head1 SUBROUTINES/METHODS

=head2 register(registry => 'default', types => ['json'])


=cut

sub register{
    my $self = shift @_;
    croak "Can't pass reference to register \n".
          "Hint: use the class instead of the object" if ref $self;
    my %args = @_;
    my $registry = $args{registry};
    $registry ||= 'default';
    my $types = $args{types};
    $types = ['json', 'jsonb'] unless defined $types and @$types;
    for my $type (@$types){
        if ($PGObject::VERSION =~ /^1./){
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


=head2 new($ref)

Stores this as a reference. Nulls are now scoped references to a lexically
scoped variable.

If values other than scalars, arrayrefs, or hashes are passed in, throws an
error.

=cut

sub new {
    my ($class, $ref) = @_;
    $ref = null() unless defined $ref;
    if (not ref $ref){
        my $src = $ref;
	$ref = \$src;
    }
    bless $ref, $class;
    croak 'unsupported reftype' unless $ref->reftype =~ /^(SCALAR|ARRAY|HASH)$/;
    return $ref;
} 

=head2 from_db

serializes from the db. Note that database nulls are preserved distinct from
json null's.

=cut

my $db_null;

sub null { \$db_null} 

my $json_null;
sub json_null { \$json_null }
sub is_json_null { json_null eq shift };

sub from_db {
    my ($class, $var) = @_; 
    return $class->new(undef) unless defined $var;
    return $class->new(json_null) if $var eq 'null';
    my $obj = $class->new(JSON->new->allow_nonref->decode($var));
    return $obj->reftype eq 'SCALAR' ? $$obj : $obj ;
}


=head2 to_db

returns undef if is_null.  Otherwise returns the value encoded as JSON

=cut

=head2 null

Return a null type for storage in the db.

=cut

=head2 TO_JSON

The handler for setting this to the JSON parser

=cut

sub TO_JSON {
    my $self = shift;
    for ($self->reftype){
        if ($_ eq 'SCALAR') { return $$self; }
        if ($_ eq 'ARRAY')  { return [@$self]; }
        if ($_ eq 'HASH')   { return { %$self } }
    }
}

sub to_db {
    my $self = shift @_;
    return undef if $self->is_null;
    return 'null' if $self->is_json_null;
    return JSON->new->allow_blessed->convert_blessed->encode($self);
}

=head2 reftype

Returns the reftype of the object (i.e. HASH, SCALAR, ARRAY)

=cut

sub reftype {
    my ($self) = @_;
    my $reftype = "$self";
    my $pkg = blessed $self;
    $reftype =~ s/${pkg}=(\w+)\(.*\)/$1/;
    $reftype = 'SCALAR' if $reftype eq 'REF';
    return $reftype;
}

=head2 is_null

Returns true if is a database null.

=cut

sub is_null {
    my $self = shift @_;
    return 1 if ref $self && ($self eq null);
    return 0;
}

=head2 json_null

Returns a JSON null

=head2 is_json_null

Returns true if the value is a JSON null.  Else it returns false

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-type-json at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Type-JSON>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Type::JSON


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Type-JSON>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Type-JSON>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Type-JSON>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Type-JSON/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013-2023 Chris Travers.

This program is released under the following license: BSD


=cut

1; # End of PGObject::Type::JSON

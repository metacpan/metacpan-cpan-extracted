package PGObject::Simple::Role;

use 5.010;
use strict;
use warnings;
use Moo::Role;
use PGObject::Simple ':full', '!dbh';
use Carp;

=head1 NAME

PGObject::Simple::Role - Moo/Moose mappers for minimalist PGObject framework

=head1 VERSION

Version 2.0.2

=cut

our $VERSION = 2.000002;

=head1 SYNOPSIS

Take the following (Moose) class:

    package MyAPP::Foo;
    use PGObject::Util::DBMethod;
    use Moose;
    with 'PGObject::Simple::Role';

    has id  => (is => 'ro', isa => 'Int', required => 0);
    has foo => (is => 'ro', isa => 'Str', required => 0);
    has bar => (is => 'ro', isa => 'Str', required => 0);
    has baz => (is => 'ro', isa => 'Int', required => 0);

    sub get_dbh {
        return DBI->connect('dbi:Pg:dbname=foobar');
    }
    #  PGObject::Util::DBMethod exports this
    dbmethod int => (funcname => 'foo_to_int');

And a stored procedure:  

    CREATE OR REPLACE FUNCTION foo_to_int
    (in_id int, in_foo text, in_bar text, in_baz int)
    RETURNS INT LANGUAGE SQL AS
    $$
    select char_length($2) + char_length($3) + $1 * $4;
    $$;

Then the following Perl code would work to invoke it:

    my $foobar = MyApp->foo(id => 3, foo => 'foo', bar => 'baz', baz => 33);
    $foobar->call_dbmethod(funcname => 'foo_to_int');

The following will also work since you have the dbmethod call above:

    my $int = $foobar->int;

The full interface of call_dbmethod and call_procedure from PGObject::Simple are
supported, and call_dbmethod is effectively wrapped by dbmethod(), allowing a
declarative mapping.

=head1 DESCRIPTION



=head1 ATTRIBUTES AND LAZY GETTERS


=cut


has _dbh => (  # use dbh() to get and set_dbh() to set
       is => 'lazy', 
       isa => sub { 
                    croak "Expected a database handle.  Got $_[0] instead"
                       unless eval {$_[0]->isa('DBI::db')};
       },
);

has _DBH => ( # backwards compatible for 1.x. 
	is => 'lazy',
       isa => sub { 
                    warn 'deprecated _DBH used.  rename to _dbh when you can';
                    croak "Expected a database handle.  Got $_[0] instead"
                       unless eval {$_[0]->isa('DBI::db')};
       },
);

sub _build__dbh {
    my ($self) = @_;
    return $self->{_DBH} if $self->{_DBH};
    return $self->_get_dbh;
}

sub _build__DBH {
    my ($self) = @_;
    return $self->{_dbh} if $self->{_dbh};
    return $self->_dbh;
}

sub _get_dbh {
    croak 'Invoked _get_dbh from role improperly.  Subclasses MUST set this method';
}

has _registry => (is => 'lazy');

sub _build__registry {
    my ($self) = @_;
    return $self->_get_registry() if $self->can('_get_registry');
    _get_registry();
}

=head2 _get_registry

This is a method the consuming classes can override in order to set the
registry of the calls for type mapping purposes.

=cut

sub _get_registry{
    return undef;
}

has _funcschema => (is => 'lazy');

=head2 _get_schema

Returns the default schema associated with the object.

=cut

sub _build__funcschema {
    return $_[0]->_get_schema;
}

sub _get_schema {
    return undef;
}

has _funcprefix => (is => 'lazy');

=head2 _get_prefix

Returns string, default is an empty string, used to set a prefix for mapping
stored prcedures to an object class.

=cut

sub _build__funcprefix {
    my ($self)  = @_;
    return $self->_get_prefix;
}

sub _get_prefix {
    return '';
}

=head1 READ ONLY ACCESSORS (PUBLIC)

=head2 dbh

Wraps the PGObject::Simple method

=cut

sub dbh {
    my ($self) = @_;
    if (ref $self){
	return $self->_dbh;
    }
    return "$self"->_get_dbh;
}

=head2 funcschema

Returns the schema bound to the object

=cut

sub funcschema {
    my ($self)  = @_;
    return $self->_funcschema if ref $self;
    return "$self"->_get_schema();
}

=head2 funcprefix

Prefix for functions

=cut

sub funcprefix {
    my ($self) = @_;
    
    return $self->_funcprefix if ref $self;
    return "$self"->_get_prefix();
}

=head1 REMOVED METHODS

These methods were once part of this package but have been removed due to
the philosophy of not adding framework dependencies when an application 
dependency can work just as well. 

=head2 dbmethod

Included in versions 0.50 - 0.71.

Instead of using this directly, use:

   use PGObject::Util::DBMethod;

instead.  Ideally this should be done in your actual class since that will 
allow you to dispense with the extra parentheses.  However, if you need a
backwards-compatible and central solution, since PGObject::Simple::Role 
generally assumes sub-roles will be created for managing db connections etc. 
you can put the use statement there and it will have the same impact as it did
here when it was removed with the benefit of better testing.

=head1 AUTHOR

Chris Travers,, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-simple-role at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Simple-Role>.  I will be notified, and then you'll
Chris Travers,, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-simple-role at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Simple-Role>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Simple::Role


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Simple-Role>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Simple-Role>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Simple-Role>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Simple-Role/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013-2017 Chris Travers,.

Redistribution and use in source and compiled forms with or without 
modification, are permitted provided that the following conditions are met:

=over

=item 

Redistributions of source code must retain the above
copyright notice, this list of conditions and the following disclaimer as the
first lines of this file unmodified.

=item 

Redistributions in compiled form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
source code, documentation, and/or other materials provided with the 
distribution.

=back

THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of PGObject::Simple::Role

use strict;
use warnings;
package SeeAlso::Identifier;
{
  $SeeAlso::Identifier::VERSION = '0.71';
}
#ABSTRACT: Controlled identifier that can be normalized and hashed


use overload (
    '""'   => sub { $_[0]->as_string },
    'bool' => sub { $_[0]->valid },
    '<=>' => sub { $_[0]->cmp( $_[1] ) },
    'cmp' => sub { $_[0]->cmp( $_[1] ) },
    fallback => 1
);


sub parse {
    my $value = shift;
    return defined $value ? "$value" : "";
}


sub new {
    my $class = shift;

    my $value = '';
    my $self = bless \$value, $class;
    $self->value( $_[0] );

    return $self;
}


sub value {
    my $self = shift;
    if ( scalar @_ ) {
        ## no critic
        my $value = eval ref($self).'::parse($_[0])';
        ## use critic
        $$self = defined $value ? "$value" : "";
    }
    return $$self;
}


sub canonical {
    return ${$_[0]};
}


sub hash {
    return $_[0]->canonical;
}


sub valid {
    return ${$_[0]} ne '';
}



sub cmp {
    my $self = shift;
    my $second = shift;
    # TODO: use the same class as the first for comparing (and test this)!
    $second = SeeAlso::Identifier->new( $second )
        unless UNIVERSAL::isa( $second, 'SeeAlso::Identifier' );
    return $self->canonical cmp $second->canonical;
}


sub as_string {
    return $_[0]->canonical;
}


sub normalized { return $_[0]->canonical; }

sub indexed { return $_[0]->hash; }

sub condensed { return $_[0]->hash; }

sub get { return $_[0]->value; }

sub set {
    my $self = shift;
    return $self->value( scalar @_ ? @_ : undef );
}

1;


__END__
=pod

=head1 NAME

SeeAlso::Identifier - Controlled identifier that can be normalized and hashed

=head1 VERSION

version 0.71

=head1 SYNOPSIS

  my $id = new SeeAlso::Identifier("abc");

  if ( $id ) {   # same as if ( $id->valid )
      $id->value("xyz");  # set a new value
      $id->set("xyz");    # set a new value
  }

  $str = $id->as_string;  # "xyz"
  $str = "$id";           # "xyz"

  # get the plain literal value
  $str = $id->value;
  $str = $id->get;

  # get the canonical hashed value
  $str = $id->canonical;
  $str = $id->normalized;

  # cat the condensed hash value
  $str = $id->hash;
  $str = $id->indexed;
  $str = $id->condensed;

  $parsed = SeeAlso::Identifier::parse("XYZ");
  $parsed = $id->parse("XYZ");

=head1 DESCRIPTION

SeeAlso::Identifier models identifiers that can be represent in three forms:
literal (plain string), canonical (normalized) and condensed (hashed). Every
identifier is a string value with the empty string as default. Particular kinds
of identifiers can be created by deriving a subclass of SeeAlso::Identifier or
with a L<SeeAlso::Identifier::Factory>.

The design of SeeAlso::Identifier is build upon the assumption that identifiers
should not encode "semantic" or "intelligent" information but just provide a clear
mapping to entities.

=head1 DEFINING PARTICULAR IDENTIFIER TYPES

SeeAlso::Identifier is just a base class for special identifier types. For
particular kinds of identifiers you should write a subclass are create it
with L<SeeAlso::Identifier::Factory>. Defining a particular type of identifier
is limited to overriding one or more of the following methods and functions:

=over

=item * parse

=item * canonical

=item * hash

=back

For most cases one or more of this methods is enough to define the whole
identifier logic. In some cases you may also want to override one or more
of the following methods:

=over

=item * as_string

=item * valid

=item * cmp

=back

The other methods, including the constructor C<new> should not be redefined.

=head2 EXAMPLES

If there already is a module at CPAN: Reuse it!
Otherwise: implement logic

=head3 Library of Congress Control Number (LCCN)

See also <Business::LCCN>.

  package LCCN;

  use base qw(SeeAlso::Identifier);

  # TODO
        prefix => "info:lccn/",
        parse => sub { "$1$2" if $_[0] =~ /^(n) ?([0-9]+)$/ },
        indexed => sub { "$1 $2" if $_[0] =~ /^(n) ?([0-9]+)$/ },
        # => LC|n 50034328 

  sub parse {
      my $value = shift;

      $value =~ s/^\s+|\s+$//g; # trim whitespace

      # permalink or info-URI form or LC|...
      $value =~ s{^(http://lccn.loc.gov/|info:lccn/|LC\|)}{};

      # normalize documented at http://www.loc.gov/marc/lccn-namespace.html
      # and http://lccn.loc.gov/lccnperm-faq.html

        # TODO: this is from Business::LCCN
      my $string = join '', $self->prefix, $self->year_encoded, $self->serial;
       $string =~ s/[\s-]//g;
  }

  sub canonical { # append URI namespace
      my $lccn = shift;
      return 'info:lccn:/' . $lccn->value;
  }

  sub hash { # remove 'n'
      my $lccn = shift;
      return $lccn ? substr($lccn,1) : '';
  }

=head2 VIAF Identifier

The Virtual International Authority File (VIAF) ...

        prefix => "http://viaf.org/",
        parse => sub { $1 if $_[0] =~ /^([0-9]+)$/; },
        indexed => sub { $_[0]; } # TODO: this does not work!

=head1 FUNCTIONS

=head2 parse ( $value )

Parses a value to an identifier value and returns the value as string.
This function called whenever you set the value of an identifier. In
SeeAlso::Identifier it just stringifies values (undef becomes the empty
string) but particular identifier types should do more checking. A typical
implementation of a particular parse function uses this template:

    sub parse {
        my $value = shift;
        $value = do_some_filter_and_checking( $value );
        return defined $value ? "$value" : "";
    }';

=head1 METHODS

=head2 new ( [ $value ] )

Create a new identifier. In initialization the identifier value is set using
the C<value> method with C<undef> as default value. This implieas a call of
the C<parse> method for every new identifier. You should not override this
constructor methods in subclasses of SeeAlso::Identifier.

=head2 value ( [ $value ] )

Get (and optionally set) the value of this identifier. If you provide a value
(including undef), it will be passed to the C<parse> function and stringified
to be used as the new identifier value. You should not override this methods
in subclasses of SeeAlso::Identifier but the C<parse> function instead.

=head2 canonical

Returns a normalized version of the identifier. For most identifiers the
normalized version should be an absolute URI. The default implementation
of this method just returns the full value, so if the 'value' method already
does normalization, you do not have to implement 'canonical'.

=head2 hash

Return a compact form of this identifier that can be used for indexing. 
A usual compact form is the local part without namespace prefix or a 
hash value. The default implementation of this method returns the canonical form
of the identifier.

=head2 valid

Returns whether this identifier is valid - which is the case for all non-empty
strings. This method is automatically called by overloading to derive a boolean
value from an identifier. This means you can use identifiers as boolean values
in most Perl constructs. Please note that in contrast to default scalars the
identifier value '0' is valid!

=head2 cmp ( $identifier )

Compares two identifiers. If the supplied value is not an identifier, it
will be converted first. By default the canonical values are compared.

=head2 as_string

Return an identifier object as plain string which is the canonical form.
Identifiers are also converted to plain strings automatically by overloading.
This means you can use identifiers as plain strings in most Perl constructs.

=head1 ALIAS METHODS

The following method names can be used as alias for the core method names.
When you derive a subclass, Do not override this methods but the corresponding
core methods!

=over

=item normalized

Alias for C<canonical>. Do not override this method but C<canonical>.

=item condensed

Alias for C<hash>. Do not override this method but C<hash>.

=item indexed

Alias for C<hash>. Do not override this method but C<hash>.

=item get

Alias for C<value>. Do not override this method but C<value>.

=item set ( [ $value ] )

Alias for C<value> with C<undef> as default value. Do not override
this method but C<value>.

=back

=head1 SEE ALSO

See L<URI> for an implementation of Uniform Resource Identifiers
which is more specific than SeeAlso::Identifier.

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


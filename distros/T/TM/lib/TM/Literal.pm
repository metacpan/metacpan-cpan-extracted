package TM::Literal;

=pod

=head1 NAME

TM::Literal - Topic Maps, simple values (literals)

=head2 SYNOPSIS

    use TM::Literal;
    my $l = new TM::Literal (42, 'xsd:integer');

    print $l->[0]; # prints 42
    print $l->[1]; # prints http://www.w3.org/2001/XMLSchema#integer

    $l = new TM::Literal (42); # default is xsd:string

=head1 DESCRIPTION

This packages will eventually handle all literal handling, i.e. not only a way to create and
retrieve information about simple values used inside topic maps, but also all necessary operations
such as I<integer addition>, I<string manipulation>.

This is quite a chore, especially since the data types adopted here are the XML Schema Data Types.

=head2 Constants

  XSD      http://www.w3.org/2001/XMLSchema#
  INTEGER  http://www.w3.org/2001/XMLSchema#integer
  DECIMAL  http://www.w3.org/2001/XMLSchema#decimal
  FLOAT    http://www.w3.org/2001/XMLSchema#float
  DOUBLE   http://www.w3.org/2001/XMLSchema#double
  STRING   http://www.w3.org/2001/XMLSchema#string
  URI      http://www.w3.org/2001/XMLSchema#anyURI
  ANY      http://www.w3.org/2001/XMLSchema#anyType

=head2 Grammar

TODO

=head2 Operations

TODO

=cut

use constant XSD => "http://www.w3.org/2001/XMLSchema#";

use constant {
    INTEGER => XSD.'integer',
    DECIMAL => XSD.'decimal',
    FLOAT   => XSD.'float',
    DOUBLE  => XSD.'double',
    BOOLEAN => XSD.'boolean',
    STRING  => XSD.'string',
    URI     => XSD.'anyURI',
    ANY     => XSD.'anyType',
    };

sub new {
    my ($class, $val, $type) = @_;

    $type ||= STRING;
    $type   =~ s/^xsd:/XSD/e;
    return bless [ $val, $type ],$class;
}



our $grammar = q{

    literal                   : decimal                               { $return = new TM::Literal  ($item[1], TM::Literal->DECIMAL); }
                              | integer                               { $return = new TM::Literal  ($item[1], TM::Literal->INTEGER); }
                              | boolean                               { $return = new TM::Literal  ($item[1], TM::Literal->BOOLEAN); }
                              | wuri                                  { $return = new TM::Literal  ($item[1], TM::Literal->URI); }
                              | string 
# TODO | date

    integer                   : /-?\d+/

    decimal                   : /-?\d+\.\d+/
# TODO: optional .234?)

    string                    : /\"{3}(.*?)\"{3}/s ('^^' iri)(?)      { $return = new TM::Literal  ($1,       $item[2]->[0] || TM::Literal->STRING); }
                              | /\"([^\n]*?)\"/    ('^^' iri)(?)      { $return = new TM::Literal  ($1,       $item[2]->[0] || TM::Literal->STRING); }

#   string                     : quoted_string
#                              | triple_quoted_string
#
#   quoted_string              : '"' /[^\"]*/ '"'                      { $return = $item[2]; }
#
#   triple_quoted_string       : '"""' /([^\"]|\"(?!""))*/ '"""'       { $return = $item[2]; }


    boolean                   : 'true' | 'false'

    wuri                      : '<' iri '>'                           { $item[2] }

    uri                       : /(\w+:[^\"\s)\]\>]+)/

    iri                       : /\w[\w\d\+\-\.]+:\/([^\.\s:;]|\.(?!\s)|:(?!\s)|;(?!\s))+/
# | '<' ... '>'
                              | qname                                    # other implementation has to provide this!

# an option? the official pattern -> perldoc URI
#                  uri : m|^(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;


};

our $comparators = {
    ( INTEGER ) => sub { return $_[0] == $_[1]; },
    ( DECIMAL ) => sub { return $_[0] == $_[1]; },
    ( FLOAT   ) => sub { return $_[0] == $_[1]; },
    ( DOUBLE  ) => sub { return $_[0] == $_[1]; },
    ( STRING  ) => sub { return $_[0] eq $_[1]; },
};

our $operators = { 
    '+' => {
	(INTEGER) => {
	    (INTEGER) => \&op_numeric_add,
	},
	(DECIMAL) => {
	    (DECIMAL) => \&op_numeric_add,
	},
	(FLOAT) => {
	    (FLOAT) => \&op_numeric_add,
	},
	(DOUBLE) => {
	    (DOUBLE) => \&op_numeric_add,
	},
    },
    '-' => {
	(INTEGER) => {
	    (INTEGER) => \&op_numeric_subtract,
	},
	(DECIMAL) => {
	    (DECIMAL) => \&op_numeric_subtract,
	},
	(FLOAT) => {
	    (FLOAT) => \&op_numeric_subtract,
	},
	(DOUBLE) => {
	    (DOUBLE) => \&op_numeric_subtract,
	},
    },
    '*' => {
	(INTEGER) => {
	    (INTEGER) => \&op_numeric_multiply,
	},
	(DECIMAL) => {
	    (DECIMAL) => \&op_numeric_multiply,
	},
	(FLOAT) => {
	    (FLOAT) => \&op_numeric_multiply,
	},
	(DOUBLE) => {
	    (DOUBLE) => \&op_numeric_multiply,
	},
    },
    'div' => {
	(INTEGER) => {
	    (INTEGER) => \&op_numeric_divide,
	},
	(DECIMAL) => {
	    (DECIMAL) => \&op_numeric_divide,
	},
	(FLOAT) => {
	    (FLOAT) => \&op_numeric_divide,
	},
	(DOUBLE) => {
	    (DOUBLE) => \&op_numeric_divide,
	},
    },
    '==' => {
	(INTEGER) => {
	    (INTEGER) => \&cmp_numeric_eq,
	},
	(DECIMAL) => {
	    (DECIMAL) => \&cmp_numeric_eq,
	},
	(FLOAT) => {
	    (FLOAT) => \&cmp_numeric_eq,
	},
	(DOUBLE) => {
	    (DOUBLE) => \&cmp_numeric_eq,
	},
    },
};

our %OPS = (
	    'tmql:add_int_int' => \&TM::Literal::op_numeric_add
	    );

sub _lub {
    my $a = shift;
    my $b = shift;

    if (     $a eq DOUBLE  || $b eq DOUBLE) {
	return DOUBLE;
    } elsif ($a eq FLOAT   || $b eq FLOAT) {
	return FLOAT;
    } elsif ($a eq DECIMAL || $b eq DECIMAL) {
	return DECIMAL;
    } else {
	return INTEGER;
    }
}

sub op_numeric_add { # (A, B)
    return new TM::Literal ($_[0]->[0] + $_[1]->[0], _lub ($_[0]->[1], $_[1]->[1]));
}

sub op_numeric_subtract { # (A, B)
    return new TM::Literal ($_[0]->[0] - $_[1]->[0], _lub ($_[0]->[1], $_[1]->[1]));
}

sub op_numeric_multiply { # (A, B)
    return new TM::Literal ($_[0]->[0] * $_[1]->[0], _lub ($_[0]->[1], $_[1]->[1]));
}

sub op_numeric_divide { # (A, B)
    return new TM::Literal ($_[0]->[0] / $_[1]->[0], 
			    $_[0]->[1] eq INTEGER && $_[1]->[1] eq INTEGER ?
			            INTEGER :
			            DECIMAL);
## @@ needs to be fixed
}

sub op_numeric_integer_divide { # (A, B)
    return new TM::Literal (int ($_[0]->[0] / $_[1]->[0]), 'xsd:integer');
}

sub cmp_numeric_eq {
    return $_[0]->[0] == $_[1]->[0] && $_[0]->[1] eq $_[1]->[1];
}




=pod

=head1 SEE ALSO

L<TM>

=head1 COPYRIGHT AND LICENSE

Copyright 200[6] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = 0.1;
our $REVISION = '$Id: Literal.pm,v 1.10 2006/12/29 09:33:42 rho Exp $';

1;

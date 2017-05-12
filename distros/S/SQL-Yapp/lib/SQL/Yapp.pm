#! /usr/bin/perl -w

package SQL::Yapp;

use strict;
use warnings;
use vars         qw($VERSION @EXPORT_OK);
use base         qw(Exporter);
use Carp         qw(longmess carp croak confess);
use Hash::Util   qw(lock_keys lock_hash);
use Scalar::Util qw(looks_like_number blessed);
use Data::Dumper;
use Filter::Simple;
use Text::Balanced;

require v5.8;

$VERSION= 2.001;

@EXPORT_OK=qw(
    dbh
    get_dbh
    quote
    quote_identifier
    check_identifier
    runtime_check
    xlat_catalog
    xlat_schema
    xlat_table
    xlat_column
    xlat_charset
    xlat_collate
    xlat_constraint
    xlat_index
    xlat_transliteration
    xlat_transcoding
    xlat_engine
    parse
    ASTERISK
    QUESTION
    NULL
    TRUE
    FALSE
    UNKNOWN
    DEFAULT
);

use constant SQL_MARK        => "\0__SQL__";
use constant COMMA_STR       => ', ';
use constant LARGE_LIMIT_CNT => '18446744073709551615';

use constant NOT_IN_LIST => 0;
use constant IN_LIST     => 1;

use constant NO_PARENS   => 0;
use constant PARENS      => 1;

use constant NO_SHIFT    => 0;
use constant SHIFT       => 1;

my $get_dbh=              undef;
my $quote_id=             undef;
my $quote_val=            undef;
my $quote_id_default=     undef;
my $quote_val_default=    undef;
my $xlat_catalog=         sub($) { $_[0] };
my $xlat_schema=          sub($) { $_[0] };
my $xlat_table=           sub($) { $_[0] };
my $xlat_column=          sub($) { $_[0] };
my $xlat_charset=         sub($) { $_[0] };
my $xlat_collate=         sub($) { $_[0] };
my $xlat_constraint=      sub($) { $_[0] };
my $xlat_index=           sub($) { $_[0] };
my $xlat_transliteration= sub($) { $_[0] };
my $xlat_transcoding=     sub($) { $_[0] };
my $xlat_engine=          sub($) { $_[0] };
my $check_identifier=     sub($$$$$) { };
my $runtime_check=        0;
my $sql_marker=           'sql';
my $do_prec=              0;
my $debug=                0;

my %dialect= (  # known dialects
    generic    => 1,
    std        => 1,
    mysql      => 1,
    postgresql => 1,
    oracle     => 1,
);

my $write_dialect= 'generic'; # not well-supported yet, only a few things are done
my %read_dialect= (
    mysql    => 1,
    postgresql => 1,
    oracle   => 1,
);

# SQL often has several tokens used as one keyword.  In order to
# simplify the parser, we combine them in the scanner already.  This
# also produces nicer  error messages with more information for the
# user (e.g. 'Unexpected IS NOT NULL'...).
my %multi_token= (
    IS => {
        NULL => {},
        TRUE => {},
        FALSE => {},
        UNKNOWN => {},
        NORMALIZED => {},
        NOT => {
            NULL => {},
            TRUE => {},
            FALSE => {},
            UNKNOWN => {},
            NORMALIZED => {},
            A => { SET => {} },
            OF => {},
        },
        DISTINCT => { FROM => {} },
        A => { SET => {} },
        OF => {},
    },
    GROUP => { BY => {} },
    ORDER => { BY => {} },
    WITH => {
        ROLLUP => {},
        ORDINALITY => {},
        LOCAL => { TIME => { ZONE => {} } },
        TIME  => { ZONE => {} },
    },
    WITHOUT => { TIME => { ZONE => {} } },
    FOR => {
        UPDATE => {},
        SHARE  => {},
    },
    LOCK => { IN => { SHARE => { MODE => {} } } },

    SIMILAR => { TO => {} },
    BETWEEN => {
        SYMMETRIC  => {},
        ASYMMETRIC => {},
    },
    MEMBER => { OF => {} },

    PRIMARY => { KEY => {} },
    FOREIGN => { KEY => {} },

    CHARACTER => {
        SET => {},
        VARYING => {},
    },
    NATIONAL => { CHARACTER => {} },
    NCHAR => {
        VARYING => {}
    },
    DEFAULT => {
        VALUES => {},
        CHARACTER => {
            SET => {}
        },
    },
    ON => {
        DUPLICATE => { KEY => { UPDATE => {} } },
        DELETE => {},
        UPDATE => {},
        COMMIT => {},
    },
    OVERRIDING => {
        USER   => { VALUE => {} },
        SYSTEM => { VALUE => {} }
    },
    CREATE => {
        TABLE => {},
        LOCAL => {
            TABLE => {},
            TEMPORARY => { TABLE => {} },
        },
        GLOBAL => {
            TABLE => {},
            TEMPORARY => { TABLE => {} },
        },
        INDEX => {},
    },
    ALTER => {
        TABLE => {},
        IGNORE => { TABLE => {} },
        ONLINE => {
            TABLE => {},
            IGNORE => { TABLE => {} },
        },
        OFFLINE => {
            TABLE => {},
            IGNORE => { TABLE => {} },
        },
        COLUMN => {
        },
    },
    DROP => {
        TABLE => {},
        TEMPORARY => { TABLE => {} },

        SIGN => {},
        ZEROFILL => {},
        COLLATE  => {},
        TIME => { ZONE => {} },
        CHARACTER => { SET => {} },

        DEFAULT => {},
        UNIQUE => {},
        AUTO_INCREMENT => {},
        UNIQUE => { KEY => {} },
        PRIMARY => { KEY => {} },
        FOREIGN => { KEY => {} },
        KEY => {},
        INDEX => {},

        NOT => { NULL => {} },

        COLUMN => {},
        CONSTRAINT => {},
    },
    NOT => {
        LIKE => {},
        CLIKE => {},
        SIMILAR => { TO => {}, },
        BETWEEN => {
            SYMMETRIC  => {},
            ASYMMETRIC => {},
        },
        MEMBER => { OF => {} },
        NULL => {},
    },

    NO => {
        ACTION => {},
    },

    BINARY => { VARYING => {} },
    TEXT => { BINARY => {} },
    TINYTEXT => { BINARY => {} },
    MEDIUMTEXT => { BINARY => {} },
    LONGTEXT => { BINARY => {} },
    UNIQUE => { KEY => {} },
    IF => {
        NOT => { EXISTS => {} },  # Ouch! (should be :if-does-not-exist, of course)
        EXISTS => {},
    },
    SET => {
        NULL => {},
        DEFAULT => {},
        NOT => { NULL => {} },
        SET => { DATA => { TYPE => {} } },
    },
    PRESERVE => { ROWS => {} },
    DELETE   => { ROWS => {} },
    RENAME => {
        TO => {},
        COLUMN => {},
    },
    ADD => {
        COLUMN => {},
    },
    MODIFY => {
        COLUMN => {},
    },
    CHANGE => {
        COLUMN => {},
    },
);
my %synonym= (
    'NORMALISED'          => 'NORMALIZED',
    'CHAR'                => 'CHARACTER',
    'CHAR_LENGTH'         => 'CHARACTER_LENGTH',
    'CHARACTER VARYING'   => 'VARCHAR',
    'NATIONAL CHARACTER'  => 'NCHAR',
    'CHAR LARGE OBJECT'   => 'CLOB',
    'NCHAR LARGE OBJECT'  => 'NCLOB',
    'BINARY LARGE OBJECT' => 'BLOB',
    'NVARCHAR'            => 'NCHAR VARYING',
    'DEC'                 => 'DECIMAL',
    'INTEGER'             => 'INT',
    'BINARY VARYING'      => 'VARBINARY',
    'CHARSET'             => 'CHARACTER SET',
    'TEMP'                => 'TEMPORARY',
);

my %type_spec= ();

my @SELECT_INITIAL= (
    'SELECT',
    # 'WITH' # NOT YET
);

my @CREATE_TABLE_INITIAL= (
    'CREATE TABLE',
    'CREATE TEMPORARY TABLE',
    'CREATE LOCAL TABLE',
    'CREATE GLOBAL TABLE',
    'CREATE LOCAL TEMPORARY TABLE',
    'CREATE GLOBAL TEMPORARY TABLE',
);

my @DROP_TABLE_INITIAL= (
    'DROP TABLE',
    'DROP TEMPORARY TABLE',
);

my @ALTER_TABLE_INITIAL= (
    'ALTER TABLE',
    'ALTER IGNORE TABLE',
    'ALTER ONLINE TABLE',
    'ALTER ONLINE IGNORE TABLE',
    'ALTER OFFLINE TABLE',
    'ALTER OFFLINE IGNORE TABLE',
);

######################################################################
# Use settings:

sub get_set
{
    my $var= shift;
    my $r= $$var;
    ($$var)= @_ if scalar(@_);
    return $;
}

sub get_dbh()
{
    return $get_dbh->();
}

sub dbh(;&)
{
    get_set (\$get_dbh, @_);
    if ($get_dbh) {
        $quote_id_default=  sub(@) { $get_dbh->()->quote_identifier(@_); };
        $quote_val_default= sub($) { $get_dbh->()->quote($_[0]); };
    }
    else {
        $quote_id_default=  undef;
        $quote_val_default= undef;
    }
}

sub quote_identifier(;&)     { get_set (\$quote_id,             @_); }
sub quote(;&)                { get_set (\$quote_val,            @_); }
sub xlat_catalog(;&)         { get_set (\$xlat_catalog,         @_); }
sub xlat_schema(;&)          { get_set (\$xlat_schema,          @_); }
sub xlat_table(;&)           { get_set (\$xlat_table,           @_); }
sub xlat_column(;&)          { get_set (\$xlat_column,          @_); }
sub xlat_charset(;&)         { get_set (\$xlat_charset,         @_); }
sub xlat_collate(;&)         { get_set (\$xlat_collate,         @_); }
sub xlat_constraint(;&)      { get_set (\$xlat_constraint,      @_); }
sub xlat_index(;&)           { get_set (\$xlat_index,           @_); }
sub xlat_transcoding(;&)     { get_set (\$xlat_transcoding,     @_); }
sub xlat_transliteration(;&) { get_set (\$xlat_transliteration, @_); }
sub xlat_engine(;&)          { get_set (\$xlat_engine,          @_); }

sub check_identifier(;&)     { get_set (\$check_identifier,     @_); }
sub runtime_check(;$)        { get_set (\$runtime_check,        @_); }

sub sql_marker(;$)           { get_set (\$sql_marker,   @_); }  # used only internally

sub catalog_prefix($)        { my ($p)= @_; xlat_catalog    { $p.$_[0] }; }
sub schema_prefix($)         { my ($p)= @_; xlat_schema     { $p.$_[0] }; }
sub table_prefix($)          { my ($p)= @_; xlat_table      { $p.$_[0] }; }
sub column_prefix($)         { my ($p)= @_; xlat_column     { $p.$_[0] }; }
sub constraint_prefix($)     { my ($p)= @_; xlat_constraint { $p.$_[0] }; }

sub debug($)                 { ($debug)= @_; }

sub read_dialect1($)
{
    my ($s)= @_;
    if ($s eq 'all') {
        for my $s1 (keys %dialect) {
            $read_dialect{$s1}= 1;
        }
    }
    else {
        croak "Unknown dialect: read_dialect=$s" unless $dialect{$s};
        $read_dialect{$s}= 1;
    }
}

sub read_dialect($)
{
    my ($s)= @_;
    %read_dialect=();
    if (!ref($s)) {
        read_dialect1($s);
    }
    elsif (ref($s) eq 'ARRAY') {
        for my $s1 (@$s) {
            read_dialect1($s1);
        }
    }
    else {
        die "Illegal reference: ".ref($s);
    }
}

sub write_dialect($)
{
    my ($s)= @_;
    croak "Unknown dialect: write_dialect=$s" unless $dialect{$s};
    $write_dialect= $s;
}

sub dialect($)
{
    my ($s)= @_;
    read_dialect($s);
    write_dialect($s);
}

######################################################################
# Init

my %import_handler_nonref= (
    'marker'               => \&sql_marker,
    'catalog_prefix'       => \&catalog_prefix,
    'schema_prefix'        => \&schema_prefix,
    'table_prefix'         => \&table_prefix,
    'column_prefix'        => \&column_prefix,
    'constraint_prefix'    => \&constraint_prefix,
    'debug'                => \&debug,
    'read_dialect'         => \&read_dialect,
    'write_dialect'        => \&write_dialect,
    'dialect'              => \&dialect,
);
my %import_handler_bool= (
    'runtime_check'        => \&runtime_check,
);
my %import_handler_ref= (
    'dbh'                  => \&dbh,
    'quote'                => \&quote,
    'quote_identifier'     => \&quote_identifier,
    'xlat_catalog'         => \&xlat_catalog,
    'xlat_schema'          => \&xlat_schema,
    'xlat_table'           => \&xlat_table,
    'xlat_column'          => \&xlat_column,
    'xlat_charset'         => \&xlat_charset,
    'xlat_collate'         => \&xlat_collate,
    'xlat_constraint'      => \&xlat_constraint,
    'xlat_index'           => \&xlat_index,
    'xlat_transliteration' => \&xlat_transliteration,
    'xlat_transcoding'     => \&xlat_transcoding,
    'xlat_engine'          => \&xlat_engine,
    'check_identifier'     => \&check_identifier,
);

sub type_spec()
{
    return (
        'DOUBLE PRECISION' => 'INT',
        'REAL'     => 'INT',
        'BIGINT'   => 'INT',
        'SMALLINT' => 'INT',
        'INT' => {
        },

        # numbers with 0 or 1 precision marker:
        'FLOAT' => {
            prec1 => 1,
        },

        # numbers with 0, 1, or 2 precision numbers:
        'NUMERIC' => 'DECIMAL',
        'DECIMAL' => {
            prec1 => 1,
            prec2 => 1,
        },

        # character strings:
        'VARCHAR' => 'CHARACTER',
        'CHARACTER' => {
            prec1   => 1,
            charset => 1,
            collate => 1,
        },

        # clobs:
        'CLOB' => {
            prec1     => 1,
            prec_mul  => 1,
            prec_unit => 1,
            charset   => 1,
            collate   => 1,
        },

        # nchar:
        'NCHAR VARYING' => 'NCHAR',
        'NCHAR' => {
            prec1   => 1,
            collate => 1,
        },

        # nclobs:
        'NCLOB' => {
            prec1     => 1,
            prec_mul  => 1,
            prec_unit => 1,
            collate   => 1,
        },

        # binary strings:
        'VARBINARY' => 'BINARY',     # not standard
        'BINARY' => {
            prec1 => 1,
        },

        # blobs:
        'BLOB' => {
            prec1     => 1,
            prec_mul  => 1,
            prec_unit => 1,
        },

        # simple types without further attributes or lengths:
        'SERIAL' => 'BOOLEAN', # column spec, but handled as type for simplicity reasons
        'BOOLEAN' => {
        },

        # date/time:
        'DATE' => 'TIME',
        'TIMESTAMP' => 'TIME',
        'TIME' => {
            timezone => 1
        },

        # Dialects come last because they may redefine above settings:
        # If two dialects are contracting, you must find a common solution
        # and put it at the end of this list:
        ($read_dialect{mysql} ?
            (
                'SMALLINT'    => 'INT',
                'BIGINT'      => 'INT',
                'TINYINT'     => 'INT',
                'MEDIUMINT'   => 'INT',
                'BIT'         => 'INT',
                'BIT VARYING' => 'INT',
                'FLOAT'       => 'INT',
                'INT' => {
                    prec1    => 1,
                    zerofill => 1,
                    sign     => 1,
                },

                'FLOAT'   => 'NUMERIC',
                'DECIMAL' => 'NUMERIC',
                'REAL'    => 'NUMERIC',
                'DOUBLE'  => 'NUMERIC',
                'NUMERIC' => {
                    prec1    => 1,
                    prec2    => 1,
                    zerofill => 1,
                    sign     => 1,
                },

                'DATETIME'   => 'TIME',
                'YEAR'       => 'TIME',

                'TINYBLOB'   => 'BINARY',
                'MEDIUMBLOB' => 'BINARY',
                'LONGBLOB'   => 'BINARY',

                'TINYTEXT'   => 'CHARACTER',
                'MEDIUMTEXT' => 'CHARACTER',
                'LONGTEXT'   => 'CHARACTER',
                'TEXT'       => 'CHARACTER',

                'TINYTEXT BINARY'   => 'CHARACTER',
                'MEDIUMTEXT BINARY' => 'CHARACTER',
                'LONGTEXT BINARY'   => 'CHARACTER',
                'TEXT BINARY'       => 'CHARACTER',

                'ENUM' => {
                    value_list => 1,
                    charset => 1,
                    collate => 1,
                },

                'SET' => {
                    value_list => 1,
                    charset => 1,
                    collate => 1,
                },
            )
        :   ()
        ),
        ($read_dialect{postgresql} ?
            (
                'BYTEA'     => 'BINARY',
                'INT2'      => 'INT',
                'INT4'      => 'INT',
                'INT8'      => 'INT',
                'POINT'     => 'BOOLEAN',
                'LINE'      => 'BOOLEAN',
                'LSEG'      => 'BOOLEAN',
                'BOX'       => 'BOOLEAN',
                'PATH'      => 'BOOLEAN',
                'POLYGON'   => 'BOOLEAN',
                'CIRCLE'    => 'BOOLEAN',
                'MONEY'     => 'BOOLEAN',
                'IRDR'      => 'BOOLEAN',
                'INET'      => 'BOOLEAN',
                'MACADDR'   => 'BOOLEAN',
                'UUID'      => 'BOOLEAN',
                'TEXT'      => 'CHARACTER',
                'SERIAL4'   => 'SERIAL',
                'SERIAL8'   => 'SERIAL',
                'BIGSERIAL' => 'SERIAL',
            )
        :   ()
        ),
        ($read_dialect{oracle} ?
            (
                'NUMBER' => 'NUMERIC'
            )
        :   ()
        ),
    );
}

sub import
{
    my ($pack, @opt)= @_;
    my @super_param= ();
    my $i=0;
    while ($i < scalar(@opt)) {
        my $k= $opt[$i];
        if ($i+1 < scalar(@opt)) {
            my $v= $opt[$i+1];
            if (my $handler= $import_handler_nonref{$k}) {
                $handler->($v);
                $i++;
            }
            elsif ($v eq '0' || $v eq '1') {
                if (my $handler= $import_handler_bool{$k}) {
                    $handler->($v);
                    $i++;
                }
                else {
                    croak "Error: Unrecognised package option for ".__PACKAGE__.": $k\n";
                }
            }
            elsif (ref($v)) {
                if (my $handler= $import_handler_ref{$k}) {
                    $handler->($v);
                    $i++;
                }
                else {
                    croak "Error: Unrecognised package option for ".__PACKAGE__.": $k\n";
                }
            }
            else {
                push @super_param, $k;
            }
        }
        else {
            push @super_param, $k;
        }
        $i++;
    }

    &Exporter::import($pack,@super_param);

    %type_spec= type_spec();
}

######################################################################
# Tools

sub my_dumper($)
{
    my ($x)= @_;

    my $d= Data::Dumper->new([$x],['x']);
    $d->Terse(1);
    $d->Purity(1);
    $d->Indent(1);

    my $s= $d->Dump;
    return $s
        if length($s) <= 400;

    return substr($s,0,400).'...';
}

# longmess gives me: bizarre copy of hash.  So confess does not work.
# Don't ask me why, I spent some time to debug this, but now I am
# sick of it.  So here's my primitive version:
sub my_longmess()
{
    my $i= 2;
    my @mess= ();
    while (my ($pack, $file, $line, $function)= caller($i)) {
        push @mess, "\t$file:$line: ${pack}::${function}\n";
        $i++;
    }
    return "Call Stack:\n".join('', reverse @mess);
}

sub my_confess(;$)
{
    die my_longmess.'DIED: '.($_[0] || 'Error');
}

######################################################################
# Non-trivial access to module variables:

sub get_quote_val()
{
    return
        $quote_val ||
        $quote_val_default ||
        do {
            croak "Error: No quote() function set.\n".
                  "\tUse ".__PACKAGE__."::quote() or ".__PACKAGE__."::dbh().\n";
        };
}

sub get_quote_id()
{
    return
        $quote_id ||
        $quote_id_default ||
        do {
            croak "Error: No quote_identifier() function set.\n".
                  "\tUse ".__PACKAGE__."::quote_identifier() or ".__PACKAGE__."::dbh().\n";
        };
}

######################################################################
# Recursive Descent parser:

# This is pure theory, because it will probably not occur, but:
#
# Assume:
#     not b + c       == not (b + c)        ; just like in SQL
#     a * b + c       == (a * b) + c
#
# =>  a * not b + c   == (a * not b) + c    ; illegal in SQL for another reason, but
#                                           ; still.  Assume it was ok and numeric
#                                           ; and boolean could be mixed at will.
#
# =>  parsing of the + sign is influenced not only by the immediate predecessor
#     operator 'sin', but also by '*'.
#
# This is currently not so.  Instead a * not b + c is parsed as a * not(b + c).
# I checked this with the Perl parser, which does the same:
#
#    my $a= 1 && not 0 || 1;   # ==> $a == 0
#
# Anyway, precedences are currently disabled, because of so much confusion, and
# particularly because of different precedences of the = operator in different
# positions.

use constant ASSOC_NON   => undef;
use constant ASSOC_LEFT  => -1;
use constant ASSOC_RIGHT => +1;

sub make_op($$;%)
{
    my ($value, $type, %opt)= @_;
    my $read_value= $opt{read_value} || $value;
    my $read_type=  $opt{read_type}  || $type;
    my $result= {
        read_value => $read_value,
        value      => $value,
        value2     => $opt{value2},             # for infix3
        read_type  => $read_type,               # how to parse?
        type       => $type,                    # how to print?
        result0    => $opt{result0},            # for 'infix()' operators invoked with 0 arguments
                                                # if undef => error to invoke with 0 arguments
        prec       => $opt{prec},
        assoc      => $opt{assoc},
        rhs        => $opt{rhs} || 'expr',
        rhs_map    => $opt{rhs_map} || {},
        comparison => $opt{comparison},         # for checking ANY/SOME and ALL
        dialect    => $opt{dialect} || {},
        accept     => $opt{accept},
        allow_when => $opt{allow_when},
    };
    lock_hash %$result;
    return $result;
}

sub declare_op($$;%)
{
    my ($value, $type, %opt)= @_;
    my $result= make_op($value, $type, %opt);
    return ($result->{read_value} => $result);
}

# There are two ways of normalising a functor:
#   (a) Accepting a secondary form for an otherwise standard, and widely supported
#       functor.  Example: the power function.  The std say it's called 'POWER',
#       and this is how we want to always normalise it.  To accept the MySQL form
#       with infixed ^, use the read_value attribute:
#
#           declare_op('POWER', 'funcall', ... read_value => '^');
#
#       The 'dialect' hash keys should not defined were because there's a perfect
#       normalisation for all dialects and accepting ^ is only a convenience.
#
#       These normalisations will *always* be done.
#
#   (b) Translating between non-standard or unavailable operators: here, we need
#       to know which dialect we produce.  It we don't, we keep what the user
#       wrote and pass the syntax on as is.  For translation, use the 'dialect'
#       hash table to define how to write the operator in different output modes.
#       if the output more is not found, the operator will not be touched:
#
#           declare_op('||', 'infix()', ...
#               dialect => {
#                   mysql => make_op('CONCAT', 'funcall')
#               }
#           ),
#
#       If the current print dialect is not found, nothing is changed, otherwise
#       the settings are taken from the corresponding hash entry.  If a '-default'
#       is given, then that one is used for default normalisation.
#       If the value of a hash entry is 1 instead of a ref(), then the functor
#       is not normalised for that dialect.
#
# For reducing input acception, use the 'accept' list: e.g. to accept the
# XOR operator only in MySQL and Postgres modes, use:
#
#           declare_op('XOR', 'infix()', ... accept => [ 'mysql', 'postgresql' ]);
#
# ONLY restrict the input syntax if the input cannot be normalised in a
# standard way.  Currently, we have no strict input mode: we only reject what
# cannot be rectified, regardless of %read_dialect, and that's the rule for now.
#
# Also note: you cannot freely switch type, but only if the number of
# parameters of the write type subsumes those of the read type:
#
#                  min      max
#     funcall      0        undef
#     funcall1col  1        1        # one param which is a column name
#     infix()      0/1      undef    # min depends on whether result0 is set
#     prefix       1        1
#     prefixn      1        1        # never parens around param
#     prefix1      1        1        # disallows point-wise application
#     suffix       1        1
#     infix2       2        2
#     infix23      2        3
#     infix3       3        3
#
# Note that all used symbolic operators must be known to token_scan_rec(),
# otherwise they are not correctly extracted from the input stream.

#
# Missing:
#
#     & | ~ (bit operations in MySQL)
#
#     ::    CAST (or TREAT?) in PostgreSQL
#

# If the type is found in the following table, stringification will be
# handled by _prefix() and _suffix().  Otherwise, the compiled Perl
# code will already contain the logic of how to build the SQL command.
my %functor_kind= (
    'infix()'  => 'suffix',
    'infix2'   => 'suffix',
    #'infix23' => 'suffix',  # complex syntax, cannot be changed later, see funcsep
    #'infix3'  => 'suffix',  # complex syntax, cannot be changed later, see funcsep

    'funcall'  => 'prefix',
    #'funcsep' => 'prefix',  # complex syntax, currently not supported

    # Not built via _suffix() or _prefix():
    #
    # prefixn

    'suffix'   => 'suffix',  # applied point-wise, different from funcall
    'prefix'   => 'prefix',  # applied point-wise, different from funcall
    'funcall1' => 'prefix',  # applied point-wise, different from funcall
    'prefix()' => 'prefix',  # not applied point-wise
);
my %functor_suffix= ( # for functors read in infix or suffix notation
    # aliasses:
    '==' => '=',
    '!=' => '<>',

    # infix2 and infix():
    declare_op('POWER', 'funcall', prec => 80, assoc => ASSOC_RIGHT,
                                read_value => '**', read_type => 'infix2'), # Oracle
    #declare_op('POWER', 'funcall', prec => 80, assoc => ASSOC_RIGHT,
    #                            read_value => '^', read_type => 'infix2'), # not MySQL
    #declare_op('POWER', 'funcall', prec => 80, assoc => ASSOC_RIGHT
    #                           read_value => ':', read_type => 'infix2'),  # Postgres??

    # bitwise operators:
    declare_op('^', 'infix()', result0 => 0,
                               assoc => ASSOC_LEFT,
                               dialect => {
                                   oracle => make_op('BITXOR', 'funcall'),
                               }),

    declare_op('|', 'infix()', result0 => 0,
                               assoc => ASSOC_LEFT,
                               dialect => {
                                   oracle => make_op('BITOR', 'funcall'),
                               }),

    declare_op('&', 'infix()', assoc => ASSOC_LEFT,
                               dialect => {
                                   oracle => make_op('BITAND', 'funcall'),
                               }),

    # others:
    declare_op('*',   'infix()', prec => 70, assoc => ASSOC_LEFT, result0 => 1),
    declare_op('/',   'infix2',  prec => 70, assoc => ASSOC_LEFT),

    declare_op('MOD', 'funcall', prec => 70, assoc => ASSOC_NON,
                                 read_value => '%', read_type  => 'infix2',), # MySQL, Postgres

    declare_op('+',   'infix()', prec => 60, assoc => ASSOC_LEFT, result0 => 0),
    declare_op('-',   'infix2',  prec => 60, assoc => ASSOC_LEFT),

    declare_op('=',   'infix2',  prec => 50, assoc => ASSOC_NON, comparison => 1, allow_when => 1),
    declare_op('<>',  'infix2',  prec => 50, assoc => ASSOC_NON, comparison => 1, allow_when => 1),
    declare_op('<',   'infix2',  prec => 50, assoc => ASSOC_NON, comparison => 1, allow_when => 1),
    declare_op('>',   'infix2',  prec => 50, assoc => ASSOC_NON, comparison => 1, allow_when => 1),
    declare_op('<=',  'infix2',  prec => 50, assoc => ASSOC_NON, comparison => 1, allow_when => 1),
    declare_op('>=',  'infix2',  prec => 50, assoc => ASSOC_NON, comparison => 1, allow_when => 1),

    declare_op('AND', 'infix()', prec => 30, assoc => ASSOC_LEFT, result0 => 1),
    declare_op('OR',  'infix()', prec => 30, assoc => ASSOC_LEFT, result0 => 0),

    declare_op('XOR', 'infix()', prec => 30, assoc => ASSOC_LEFT, result0 => 0,
                                 accept => [ 'mysql', 'postgresql', 'oracle']),

    declare_op('||',  'infix()', assoc => ASSOC_LEFT, result0 => '',
                                 dialect => {
                                     mysql => make_op('CONCAT','funcall',result0 => ''),
                                 }),

    declare_op('OVERLAPS',  'infix2', allow_when => 1),

    declare_op('IS DISTINCT FROM', 'infix2', allow_when => 1),

    declare_op('IS OF',     'infix2', rhs => 'type_list', allow_when => 1),
    declare_op('IS NOT OF', 'infix2', rhs => 'type_list', allow_when => 1),

    declare_op('IN',        'infix2', rhs => 'expr_list', allow_when => 1),
    declare_op('NOT IN',    'infix2', rhs => 'expr_list', allow_when => 1),

    # infix23
    declare_op('NOT SIMILAR TO', 'infix23', value2 => 'ESCAPE', allow_when => 1),
    declare_op('SIMILAR TO',     'infix23', value2 => 'ESCAPE', allow_when => 1),

    declare_op('LIKE',           'infix23', value2 => 'ESCAPE', allow_when => 1),
    declare_op('NOT LIKE',       'infix23', value2 => 'ESCAPE', allow_when => 1),

    declare_op('CLIKE',          'infix23', value2 => 'ESCAPE', allow_when => 1),
    declare_op('NOT CLIKE',      'infix23', value2 => 'ESCAPE', allow_when => 1),

    # infix3
    declare_op('BETWEEN',                'infix3', value2 => 'AND', prec => 31, allow_when => 1),
    declare_op('BETWEEN SYMMETRIC',      'infix3', value2 => 'AND', prec => 31, allow_when => 1),
    declare_op('BETWEEN ASYMMETRIC',     'infix3', value2 => 'AND', prec => 31, allow_when => 1),
    declare_op('NOT BETWEEN',            'infix3', value2 => 'AND', prec => 31, allow_when => 1),
    declare_op('NOT BETWEEN SYMMETRIC',  'infix3', value2 => 'AND', prec => 31, allow_when => 1),
    declare_op('NOT BETWEEN ASYMMETRIC', 'infix3', value2 => 'AND', prec => 31, allow_when => 1),

    # suffix
    declare_op('IS NORMALIZED',     'suffix', prec => 45, allow_when => 1),
    declare_op('IS NOT NORMALIZED', 'suffix', prec => 45, allow_when => 1),
    declare_op('IS TRUE',           'suffix', prec => 45, allow_when => 1),
    declare_op('IS NOT TRUE',       'suffix', prec => 45, allow_when => 1),
    declare_op('IS FALSE',          'suffix', prec => 45, allow_when => 1),
    declare_op('IS NOT FALSE',      'suffix', prec => 45, allow_when => 1),
    declare_op('IS NULL',           'suffix', prec => 45, allow_when => 1),
    declare_op('IS NOT NULL',       'suffix', prec => 45, allow_when => 1),
    declare_op('IS UNKNOWN',        'suffix', prec => 45, allow_when => 1),
    declare_op('IS NOT UNKNOWN',    'suffix', prec => 45, allow_when => 1),
    declare_op('IS A SET',          'suffix', prec => 45, allow_when => 1),
    declare_op('IS NOT A SET',      'suffix', prec => 45, allow_when => 1),
);

my %functor_prefix= ( # functors read in prefix notation:
    declare_op('+',   'prefix1', prec => 90, read_type => 'prefix'), # prefix1 disallows list context
    declare_op('-',   'prefix',  prec => 90),
    declare_op('NOT', 'prefix',  prec => 40),

    declare_op('~', 'prefix',   dialect => {                                   # MySQL
                                    oracle => make_op('BITNOT', 'funcall'),     # funcall1:
                                }),

    # Allow AND and OR as prefix operators.
    # Because - and + are already defined, they are not translated this way.
    declare_op('AND', 'prefix()',, read_type => 'prefix',
               dialect => {
                   -default => make_op('AND', 'infix()', result0 => 1),
               }),
    declare_op('OR', 'prefix()', read_type => 'prefix',
               dialect => {
                   -default => make_op('OR', 'infix()', result0 => 0),
               }),

    declare_op('BITXOR', 'funcall', assoc => ASSOC_LEFT,
                                dialect => {
                                    mysql => make_op('^', 'infix()'),
                                }),
    declare_op('BITOR', 'funcall', assoc => ASSOC_LEFT,
                                dialect => {
                                    mysql => make_op('|', 'infix()'),
                                }),
    declare_op('BITAND', 'funcall', assoc => ASSOC_LEFT,
                                dialect => {
                                    mysql => make_op('&', 'infix()'),
                                }),

    declare_op('POWER',  'funcall',
               read_value => 'POW'), # MySQL

    declare_op('CONCAT', 'funcall',
               dialect => {
                   'mysql'  => undef, # keep
                   -default => make_op('||', 'infix()', result0 => ''),
               }),

    declare_op('CONCATENATE', 'funcall',
               dialect => {
                   'mysql'  => make_op('CONCAT', 'funcall'),
                   -default => make_op('||',     'infix()', result0 => ''),
               }),

    declare_op('VALUES', 'funcall', accept => [ 'mysql' ], read_type => 'funcall1col'),

    # Funcalls with special separators instead of commas (who invented these??):
    # NOTE: These *must* start with (, otherwise they are even more special
    #       than funcsep.  Note that because of the hilarious syntax of UNNEST,
    #       the closing paren is included in the rhs pattern.
    declare_op('CAST', 'funcsep',
                rhs => [ \q{expr}, 'AS', \q{type}, ')' ]),

    declare_op('TREAT', 'funcsep',
                rhs => [ \q{expr}, 'AS', \q{type}, ')' ]),

    declare_op('TRANSLATE', 'funcsep',
                rhs => [ \q{expr}, 'AS', \q{transliteration}, ')' ]),

    declare_op('POSITION','funcsep',
                rhs => [ \q{string_expr}, 'IN', \q{expr},    # hack for 'IN' infix op.
                         [ 'USING', \q{char_unit} ], ')' ]),

    declare_op('SUBSTRING', 'funcsep',
                rhs => [ \q{expr}, 'FROM', \q{expr},
                         [ 'FOR', \q{expr}], [ 'USING', \q{char_unit} ], ')' ]),

    declare_op('CHARACTER_LENGTH', 'funcsep',
                rhs => [ \q{expr}, [ 'USING', \q{char_unit} ], ')' ]),

    declare_op('CONVERT', 'funcsep',
                rhs => [ \q{expr}, 'USING', \q{transcoding}, ')' ]),

    declare_op('OVERLAY', 'funcsep',
                rhs => [ \q{expr}, 'PLACING', \q{expr}, 'FROM', \q{expr},
                         [ 'FOR', \q{expr} ], [ 'USING', \q{char_unit} ], ')' ]),

    declare_op('EXTRACT', 'funcsep',
                rhs => [ \q{expr}, 'FROM', \q{expr}, ')']),

    declare_op('UNNEST', 'funcsep',
                rhs => [ \q{expr}, ')', [ 'WITH ORDINALITY' ] ]),
);

my %functor_special= ( # looked up manually, not generically.
    declare_op('ANY',     'prefixn'),  # n=no paren.  I know, it's lame.
    declare_op('SOME',    'prefixn'),
    declare_op('ALL',     'prefixn'),
    declare_op('DEFAULT', 'funcall', accept => [ 'mysql' ], read_type => 'funcall1col'),
        # Special functor because it collides with DEFAULT pseudo
        # constant, so it needs extra care during parsing.
);

# Reserved words from SQL-2003 spec:
my @reserved= qw(
    ADD ALL ALLOCATE ALTER AND ANY ARE ARRAY AS ASENSITIVE ASYMMETRIC
    AT ATOMIC AUTHORIZATION BEGIN BETWEEN BIGINT BINARY BLOB BOOLEAN
    BOTH BY CALL CALLED CASCADED CASE CAST CHAR CHARACTER CHECK CLOB
    CLOSE COLLATE COLUMN COMMIT CONNECT CONSTRAINT CONTINUE
    CORRESPONDING CREATE CROSS CUBE CURRENT CURRENT_DATE
    CURRENT_DEFAULT_TRANSFORM_GROUP CURRENT_PATH CURRENT_ROLE
    CURRENT_TIME CURRENT_TIMESTAMP CURRENT_TRANSFORM_GROUP_FOR_TYPE
    CURRENT_USER CURSOR CYCLE DATE DAY DEALLOCATE DEC DECIMAL DECLARE
    DEFAULT DELETE DEREF DESCRIBE DETERMINISTIC DISCONNECT DISTINCT
    DOUBLE DROP DYNAMIC EACH ELEMENT ELSE END END-EXEC ESCAPE EXCEPT
    EXEC EXECUTE EXISTS EXTERNAL FALSE FETCH FILTER FLOAT FOR FOREIGN
    FREE FROM FULL FUNCTION GET GLOBAL GRANT GROUP GROUPING HAVING
    HOLD HOUR IDENTITY IMMEDIATE IN INDICATOR INNER INOUT INPUT
    INSENSITIVE INSERT INT INTEGER INTERSECT INTERVAL INTO IS
    ISOLATION JOIN LANGUAGE LARGE LATERAL LEADING LEFT LIKE LOCAL
    LOCALTIME LOCALTIMESTAMP MATCH MEMBER MERGE METHOD MINUTE MODIFIES
    MODULE MONTH MULTISET NATIONAL NATURAL NCHAR NCLOB NEW NO NONE NOT
    NULL NUMERIC OF OLD ON ONLY OPEN OR ORDER OUT OUTER OUTPUT OVER
    OVERLAPS PARAMETER PARTITION PRECISION PREPARE PRIMARY PROCEDURE
    RANGE READS REAL RECURSIVE REF REFERENCES REFERENCING RELEASE
    RETURN RETURNS REVOKE RIGHT ROLLBACK ROLLUP ROW ROWS SAVEPOINT
    SCROLL SEARCH SECOND SELECT SENSITIVE SESSION_USER SET SIMILAR
    SMALLINT SOME SPECIFIC SPECIFICTYPE SQL SQLEXCEPTION SQLSTATE
    SQLWARNING START STATIC SUBMULTISET SYMMETRIC SYSTEM SYSTEM_USER
    TABLE THEN TIME TIMESTAMP TIMEZONE_HOUR TIMEZONE_MINUTE TO
    TRAILING TRANSLATION TREAT TRIGGER TRUE UNION UNIQUE UNKNOWN
    UNNEST UPDATE USER USING VALUE VALUES VARCHAR VARYING WHEN
    WHENEVER WHERE WINDOW WITH WITHIN WITHOUT YEAR
);
my %reserved= ( map { $_ => 1 } @reserved );

sub double_quote_perl($)
{
    my ($s)= @_;
    $s =~ s/([\\\"\$\@])/\\$1/g;
    $s =~ s/\t/\\t/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\r/\\r/g;
    $s =~ s/([\x00-\x1f\x7f])/sprintf("\\x%02x", ord($1))/gsex;
    return "\"$s\"";
}

sub single_quote_perl($)
{
    my ($s)= @_;
    $s =~ s/([\\\'])/\\$1/g;
    return "'$s'";
}

sub quote_perl($)
{
    my ($s)= @_;
    return 'undef' unless defined $s;
    return ($s =~ /[\x00-\x1f\x7f\']/) ? double_quote_perl($s) : single_quote_perl($s);
}

sub skip_ws($)
{
    my ($lx)= @_;
    my $s= $lx->{text_p};

    for(;;) {
        if ($$s =~ /\G\n/gc) {         # count lines
            $lx->{line}++;
            next;
        }
        next if $$s =~ /\G[^\n\S]+/gc; # other space but newline
        next if $$s =~ /\G\#[^\n]*/gc; # comments
        last;
    }
}

sub token_new($$;$%)
{
    my ($lx, $kind, $value, %opt)= @_;
    my_confess unless $kind;
    my $t= {
        lx          => $lx,
        line        => $lx->{line_before},      # start of token: rel. line num. in $lx->{text_p}
        line_after  => $lx->{line},
        pos         => $lx->{pos_before},       # start of token: string position in $lx->{text_p}
        pos_after   => pos(${ $lx->{text_p} }), # end   of token: string position in $lx->{text_p}
        kind        => $kind,
        value       => $value,
        str         => $opt{str},
        type        => $opt{type},              # interproc: 'variable', 'block', 'num', etc.
        perltype    => $opt{perltype},          # interproc: 'array', 'scalar', 'hash', 'list'
        prec        => $opt{prec},
        error       => $opt{error},
    };
    lock_keys %$t;
    return $t;
}

sub token_describe($)
{
    my ($t)= @_;

    my %opt= ();
    for my $key(qw(value str prec)) {
        if (defined $t->{$key}) {
            $opt{$key}= $t->{$key};
        }
    }
    for my $key(qw(perltype type)) {
        if ($t->{$key}) {
            $opt{$key}= $t->{$key};
        }
    }

    if (scalar(keys %opt)) {
        return "$t->{kind} (".
                   join(", ",
                       map {
                           my $k= $_;
                           "$k=".quote_perl($opt{$k})
                       }
                       sort keys %opt
                   ).
               ")";
    }
    else {
        return quote_perl($t->{kind});
    }
}

sub error_new($$$)
{
    my ($lx, $value, $expl)= @_;
    return token_new ($lx, 'error', $value, str => $expl, error => 1);
}

sub syn_new($$$)
{
    my ($lx, $type, $name)= @_;
    return token_new ($lx, $name, undef, perltype => '', type => $type);
        # perltype and type are for * and ?, which can occur as
        # syntactic values in expressions.
}

sub interpol_new($$$$$)
{
    my ($lx, $interpol, $value, $type, $perltype)= @_;
    return token_new ($lx, "interpol$interpol", $value,
               type  => $type,
               perltype => $perltype
           );
}

sub token_scan_codeblock($$)
{
    my ($lx, $interpol)= @_;
    my $s= $lx->{text_p};

    # Text::Balanced actually honours and updates pos($$s), so we can
    # interface directly:
    my ($ex)= Text::Balanced::extract_codeblock($$s, '{}()[]');
    return error_new($lx, 'codeblock', $@->{error})
        if $@;

    $lx->{line}+= ($ex =~ tr/\n//);
    return interpol_new ($lx, $interpol, "do$ex", 'block', 'list');
        # $ex contains {}, so do$ex is sound.
}

sub token_scan_variable($$$)
{
    my ($lx, $interpol, $perltype)= @_;
    my $s= $lx->{text_p};

    my ($ex)= Text::Balanced::extract_variable($$s);
    return error_new($lx, 'variable', $@->{error})
        if $@;

    $lx->{line}+= ($ex =~ tr/\n//);
    return interpol_new ($lx, $interpol, $ex, 'variable', $perltype);
}

sub token_scan_delimited($$$)
{
    my ($lx, $interpol, $delim)= @_;
    my $s= $lx->{text_p};

    my ($ex)= Text::Balanced::extract_delimited($$s, $delim);
    return error_new($lx, 'delimited', $@->{error})
        if $@;

    $lx->{line}+= ($ex =~ tr/\n//);
    return interpol_new ($lx, $interpol, $ex, 'string', 'scalar');
}

sub token_num_new($$$)
{
    my ($lx, $interpol, $value)= @_;
    return interpol_new ($lx, $interpol || 'Expr', $value, 'num', 'scalar');
}

sub ident_new($$)
{
    my ($lx, $value)= @_;
    return token_new ($lx, 'ident', $value, perltype => 'scalar');
}

sub keyword_new($$) # either syn or function
{
    my ($lx, $name)= @_;
    if ($reserved{$name}) {
        return syn_new($lx, 'reserved', $name);
    }
    else {
        return syn_new($lx, 'keyword', $name);
    }
}

sub replace_synonym($)
{
    my ($name)= @_;
    while (my $syn= $synonym{$name}) {
        $name= $syn;
    }
    return $name;
}

sub multi_token_new($$)
{
    my ($lx, $name)= @_;
    my $s= $lx->{text_p};

    $name= replace_synonym($name);
    if (my $tree= $multi_token{$name}) {
        SUB_TOKEN: for (;;) {
            skip_ws($lx);

            my $p= pos($$s);
            last SUB_TOKEN unless $$s =~ /\G ([A-Z][A-Z_0-9]*)\b /gcsx;
            my $sub_name= $1;

            $sub_name= replace_synonym($sub_name);
            $tree= $tree->{$sub_name};
            unless ($tree) {
                pos($$s)= $p; # unscan rejected keyword
                last SUB_TOKEN;
            }

            $name.= " $sub_name";
            $name= replace_synonym($name);
        }
        return syn_new ($lx, 'keyword', $name); # never a function, always a keyword
    }
    else {
        return keyword_new ($lx, $name);
    }
}

sub good_interpol_type($);

sub token_scan_rec($$);
sub token_scan_rec($$)
{
    my ($lx, $interpol)= @_;
    my $s= $lx->{text_p};

    skip_ws($lx);

    $lx->{pos_before}=  pos($$s);
    $lx->{line_before}= $lx->{line}; # strings may contain \n, so this may change.

    # idents: distinguished by case:
    return multi_token_new ($lx, $1) if $$s =~ /\G ([A-Z][A-Z_0-9]*)\b /gcsx;
    return ident_new ($lx, $1)       if $$s =~ /\G ([a-z][a-z_0-9]*)\b /gcsx;
    return ident_new ($lx, $1)       if $$s =~ /\G \`([^\n\\\`]+)\`      /gcsx;

    if ($$s =~ /\G ([A-Z][a-z][A-Za-z0-9]*)\b /gcsx) {
        # type specifiers change the token context itself, so we recurse here.
        my $interpol_new= $1;
        return error_new ($lx, $interpol_new, 'unknown type cast')
            unless good_interpol_type($interpol_new);

        return error_new ($lx, $interpol_new, 'duplicate type case')
            if $interpol;

        my $tok= token_scan_rec ($lx, $interpol_new);
        return $tok if $tok->{error};

        return error_new ($lx, $tok->{kind},
                   "Expected Perl interpolation after type cast to '$interpol_new'")
            unless $tok->{kind} =~ /^interpol/;

        return $tok;
    }

    return error_new ($lx, $1, 'illegal identifier: neither keyword nor name')
        if $$s =~ /\G ([A-Za-z_][A-Za-z_0-9]*) /gcsx;

    # Numbers, strings, and embedded Perl code are handled alike: they will be
    # extracted as is and evaluated as is.  This way, much of the embedded SQL
    # syntax is just like in Perl, and you don't face surprises.  The uniform
    # kind of this token is 'interpol'.  The precise type is stored in the
    # str attribute, in case anyone wants to know later.

    # numbers:
    ## ints:
    return token_num_new ($lx, $interpol, hex($1)) if $$s =~ /\G 0x([0-9a-f_]+)\b /gcsix;
    return token_num_new ($lx, $interpol, oct($1)) if $$s =~ /\G (0b[0-1_]+)\b    /gcsx;
    return token_num_new ($lx, $interpol, $1)      if $$s =~ /\G ([1-9][0-9_]*)\b /gcsx;
    return token_num_new ($lx, $interpol, oct($1)) if $$s =~ /\G ([0][0-7_]*)\b   /gcsx;
         # Note: oct() interprets 0b as binary, and there's not bin().

    return token_num_new ($lx, $interpol, $1)      if $$s =~ /\G ([1-9][0-9_]*)(?=[KMG]\b) /gcsx;
         # special case for <large object length token>, which we split in two.

    ## floats:
    return token_num_new ($lx, $interpol, $1)
        if $$s =~ /\G( (?= [1-9]             # not empty, but numeric
                         | [.][0-9]
                       )
                       (?: [1-9] [0-9_]* )?
                       (?: [.]   [0-9_]+ )?
                       (?: e[-+] [0-9_]+ )?\b )/gcsix;

    return error_new ($lx, $1, 'not a number')
        if $$s =~ /\G ([0-9][a-z_0-9]*) /gcsix;

    # embedded Perl:
    return token_scan_variable  ($lx, $interpol, 'scalar') if $$s =~ /\G (?= \$\S      ) /gcsx;
    return token_scan_variable  ($lx, $interpol, 'array')  if $$s =~ /\G (?= \@\S      ) /gcsx;
    return token_scan_variable  ($lx, $interpol, 'hash')   if $$s =~ /\G (?= \%[^\s\d] ) /gcsx;
    return token_scan_codeblock ($lx, $interpol)           if $$s =~ /\G (?= \{        ) /gcsx;
    return token_scan_delimited ($lx, $interpol, $1)       if $$s =~ /\G (?= [\'\"]    ) /gcsx;

    # symbols:
    return syn_new ($lx, 'symbol', $1)
        if $$s =~ /\G(
                       ==   | !=   | <= | >=
                    |  \&\& | \|\| | \! | \^\^
                    |  \*\* | \^
                    |  [-+*\/;:,.()\[\]{}<=>?\%\&\|]
                    )/gcsx;

    # specials:
    return error_new ($lx, $1, 'Unexpected character') if $$s =~ /\G(.)/gcs;
    return syn_new   ($lx, 'special', '<EOF>');
}

sub token_scan($)
{
   my ($lx)= @_;
   my $t= token_scan_rec($lx, '');
   #print STDERR "DEBUG: scanned: ".token_describe($t)."\n";
   return $t;
}

sub lexer_shift($)
# returns the old token kind
{
    my ($lx)= @_;
    my $r= $lx->{token}{kind};
    $lx->{token}= token_scan($lx);
    return $r;
}

sub lexer_new($$$)
{
    my ($s, $file, $line_start)= \(@_);
    my $lx= {
        text_p      => $s,
        token       => undef,
        file        => $$file,
        line_start  => $$line_start,  # relative start line of text in file
        line        => 1,             # current line (after current token)
        prev_line   => 1,             # end line of previous token (before white space)
        line_before => 1,             # start line of current token (after white space)
        pos_before  => 0,             # pos($$s) at start of current token
        error       => undef,
    };
    lock_keys %$lx;
    lexer_shift($lx);
    return $lx;
}

sub flatten($);
sub flatten($)
{
    my ($x)= @_;
    return $x
        unless ref($x);

    return map { flatten($_) } @$x
        if ref($x) eq 'ARRAY';

    return flatten([ sort keys %$x ])
        if ref($x) eq 'HASH';

    my_confess "No idea how to flatten $x";
}

sub flatten_hash($);
sub flatten_hash($)
{
    my ($x)= @_;
    return map {$_ => 1} flatten $x;
}

sub looking_at_raw($$)
{
    my ($lx, $kind)= @_;
    return unless $kind;

    my %kind= flatten_hash $kind;
    return $lx->{token}{kind}
        if $kind{$lx->{token}{kind}};

    return; # Don't return undef, but an empty list, so in array context, we get 0 results
            # This principle is used everywhere in this file.  In scalar context, we still
            # get undef from am empty list.
}

sub looking_at($$;$)
{
    my ($lx, $kind, $do_shift)= @_;
    if (my $x= looking_at_raw($lx,$kind)) {
        lexer_shift($lx) if $do_shift;
        return $x;
    }
    return;
}

sub english_or(@)
{
    my $map= undef;
    $map= shift
        if ref($_[0]) eq 'CODE';

    my @l= sort map flatten($_), @_;

    @l= map { $map->($_) } @l
        if $map;

    return 'nothing'         if scalar(@l) == 0;
    return $l[0]             if scalar(@l) == 1;
    return "$l[0] or $l[1]" if scalar(@l) == 2;

    return join(", ", @l[0..$#l-1], "or $l[-1]");
}

sub expect($$;$)
{
    my ($lx, $kind, $do_shift)= @_;
    if (my $x= looking_at($lx, $kind, $do_shift)) {
        return $x;
    }
    elsif (my $err= lx_token_error($lx)) {
        $lx->{error}= $err;
    }
    else {
        $lx->{error}= 'Expected '.(english_or \&quote_perl, $kind).
                      ', but found '.token_describe($lx->{token});
    }
    return;
}

# Parse Functions
# ---------------
# These functions return either:
#
#    undef  - in case of a syntax error
#             $lx->{error} will contain more information
#
#    [...]  - In case of a sequence of things (parse_list)
#
#    {...}  - In case of a successfully parsed item.
#             The hash contains a 'type' plus additional
#             slots depending on what was parsed.
#
#             These things can be created with create().
#
#             Note that tokens may be used here, too.
#
# Note: you cannot *try* to parse something and in case of a
# failure, do something else, because pos() and the $lx->{token}
# will have changed.  E.g. when calling parse_list, you *must*
# pass all things that might end a list instead of reading up
# to an error.  That's what the look-ahead token is for!

sub create($$@)
{
    my ($lx, $kind, @more)= @_;
    my $r= {
        (ref($kind) ?
            (
               kind => $kind->[0],
               type => $kind->[1]
            )
        :   (
               kind => $kind,
               type => ''
            )
        ),
        line => $lx->{token}{line},
        map { $_ => undef } @more,
    };
    lock_keys %$r;
    return $r;
}

# special creates that occur frequently:
sub create_Expr($)
{
    my ($lx)= @_;
    return create ($lx, 'Expr', qw(maybe_check token functor arg switchval otherwise));
}

sub parse_list($$$$;$)
# We allow multiple separators and also lists beginning with
# separators, but we do not allow them to end with the same separator.
# If a separator is encountered, we assume that the list continues.

# There is one exception: if you specify an $end, then before the
# $end, there may be too many separators.  This is handy for
# statements that often end in ; just before the closing }.

# <EOF> is implicit treated as an $end in all invocations.

# A token matching $end is not shifted.
#
# If $end is given, lists may be empty.  Otherwise, they may
# not be.

# The result is either a list reference or undef in case
# of an error.  $lx->{error} will then be set accordingly.
{
    my ($result, $lx, $parse_elem, $list_sep, $end)= @_;

    my %pos= ();
    ELEMENT: {do {
        do {
            # check that we have no infinite loop:
            my $p= pos(${ $lx->{text_p} });
            die "BUG: pos() not shifted in list" if $pos{$p}++;

            # check for end:
            last ELEMENT if looking_at($lx, $end);
            last ELEMENT if looking_at($lx, '<EOF>');

            # allow too many separators:
        } while (looking_at($lx, $list_sep, SHIFT));

        # parse one element:
        return unless
            my @result1= $parse_elem->($lx);

        # append that element to result:
        push @$result, @result1;

        # check whether the list continues:
    } while (looking_at($lx, $list_sep, SHIFT))};

    return $result;
}

sub parse_try_list($$$)
# List without delimiter, but sequenced prefix-marked elements.
# For example: a list of JOIN clauses.
#
# The parsers for such elements must handle try-parsing, i.e.,
# returning undef while not setting $lx->{error} to indicate
# that they are not looking at a prefix-marked element.
{
    my ($result, $lx, $parse_elem)= @_;

    while (my @result1= $parse_elem->($lx)) {
        push @$result, @result1;
    }

    return if $lx->{error};
    return $result;
}

sub find_ref(\%$)
# Finds a ref-valued value in a hash table, allowing redirections.
# If nothing is found, '' is returned (which would never be returned
# otherwise, because it is neither a ref(), nor undef).
{
    my ($hash, $key)= @_;
    my $result= undef;
    local $SIG{__DIE__}= \&my_confess;
    if (exists $hash->{$key}) {
        $result= $hash->{$key}
    }
    elsif (exists $hash->{-default}) {
        $result= $hash->{-default}
    }
    else {
        return '';
    }

    until (ref($result) || !defined $result) {      # No infinite loop protection!
        die "'$result' key not in hash table"
            unless exists $hash->{$result};
        $result= $hash->{$result};
    }

    return $result;
}

sub switch($%) # waiting for Perl 5.10: given/when/default
{
    my ($value, %case)= @_;
    if (my $code= find_ref(%case, $value)) {
        return $code->();
    }

    my_confess "Expected ".(english_or \&quote_perl, \%case).", but found '$value'";
}

sub lx_token_error($)
{
    my ($lx)= @_;
    if ($lx->{token}{error}) {
        return 'Found '.
               quote_perl($lx->{token}{value}).': '.
               $lx->{token}{str};
    }
    return;
}

sub parse_choice($%)
{
    my ($lx, %opt)= @_;
    return switch ($lx->{token}{kind},
        -default => sub {
            if (my $err= lx_token_error($lx)) { # already have an error message.
                $lx->{error}= 'In '.(caller(3))[3].": $err";
            }
            elsif (scalar(keys %opt) > 10) {
                $lx->{error}= 'In '.(caller(3))[3].': '.
                              ' Unexpected '.token_describe($lx->{token});
            }
            else {
                $lx->{error}= 'In '.(caller(3))[3].': Expected '.
                              (english_or \&quote_perl, \%opt).
                              ', but found '.
                              token_describe($lx->{token});
            }
            return;
        },
        %opt, # may override -default
    );
}

sub parse_plain_ident($)
{
    my ($lx)= @_;
    return parse_choice($lx,
        'interpol' => sub {
            my $r= $lx->{token};

            # If it is unambiguous, even "..." interpolation is intepreted as
            # a column name.
            #if (FORCE_STRING && $r->{type} eq 'string') {
            #    $lx->{error}=
            #        'Expected identifier, but found string: '.token_describe($r).
            #        "\n\t".
            #        "If you want to construct an identifier name, use {$r->{value}}.";
            #    return;
            #}
            #els
            if ($r->{type} eq 'num') {
                $lx->{error}=
                    'Expected identifier, but found number: '.token_describe($r).
                    "\n\t".
                    "If you want to construct an identifier name, use {$r->{value}}.";
                return;
            }

            lexer_shift($lx);
            return $r;
        },

        'interpolColumn'          => 'ident',
        'interpolTable'           => 'ident',
        'interpolCharSet'         => 'ident',
        'interpolEngine'          => 'ident',
        'interpolCollate'         => 'ident',
        'interpolConstraint'      => 'ident',
        'interpolIndex'           => 'ident',
        'interpolTranscoding'     => 'ident',
        'interpolTransliteration' => 'ident',
        '*' => 'ident',
        'ident' => sub {
            my $r= $lx->{token};
            lexer_shift($lx);
            return $r;
        },
    );
}

sub parse_ident_chain($$)
{
    my ($lx, $arr)= @_;
    return parse_list($arr, $lx, \&parse_plain_ident, '.');
}

sub check_column(@)
{
    while (scalar(@_) < 4) { unshift @_, undef; }
    my ($cat,$sch,$tab,$col)= @_;

    #return unless !defined $cat || my $cat= $cat->{
    #check_ident ('Column', $cat, $sch, $tab, $col);
}

sub parse_column($;$)
# The interpretation of the identifier chain is left to the column{1,2,3,4}
# family of functions.  It is as follows:
#
# Depending on the number of elements in the chain, the following types
# are allowed:
#
# 1 Element:
#    - Column: a fully qualified column object, maybe including
#      a table specification
#    - ColumnName: a single identifier object with a column name
#    - string: a single identifier, too, will be quoted accordingly.
#
# 2 Elements:
#    - First element: Table or string
#      Last element:  ColumnName or string
#
# more Elements:
#    - All but last element: string only
#    - Last element: ColumnName or string
{
    my ($lx, $arr)= @_;
    my $r= create ($lx, 'Column', qw(ident_chain));
    $arr||= [];
    return
        unless parse_ident_chain($lx, $arr);

    my_confess if scalar(@$arr) < 1;
    if (scalar(@$arr) > 4) {
        $lx->{error}= 'Too many parts of column identifier chain. '.
                      'Maximum is 4, found '.scalar(@$arr);
        return;
    }

    check_column(@$arr);

    $r->{ident_chain}= $arr;

    lock_keys %$r;
    return $r;
}

sub parse_schema_qualified($$)
{
    my ($lx, $kind)= @_;

    my $r= create ($lx, $kind, qw(ident_chain));
    my $arr= [];
    return
        unless parse_ident_chain($lx, $arr);

    my_confess if scalar(@$arr) < 1;
    if (scalar(@$arr) > 3) {
        $lx->{error}= 'Too many identifiers in $kind. '.
                      'Maximum is 3, found '.scalar(@$arr);
        return;
    }

    $r->{ident_chain}= $arr;

    lock_keys %$r;
    return $r;
}

sub parse_table($)
# The interpretation of the identifier chain is left to the table{1,2,3}
# family of functions.  It is as follows:
#
# Depending on the number of elements in the chain, the following types
# are allowed:
#
# 1 Element:
#    - Table:  a fully qualified table object
#    - string: a single identifier, too, will be quoted accordingly.
#
# more Elements:
#    - all elements: string
{
    my ($lx)= @_;
    return parse_schema_qualified($lx, 'Table');
}

sub parse_charset($)
{
    my ($lx)= @_;
    return parse_schema_qualified($lx, 'CharSet');
}

sub parse_constraint($)
{
    my ($lx)= @_;
    return parse_schema_qualified($lx, 'Constraint');
}

sub parse_index($)
{
    my ($lx)= @_;
    return parse_schema_qualified($lx, 'Index');
}

sub parse_collate($)
{
    my ($lx)= @_;
    return parse_schema_qualified($lx, 'Collate');
}

sub parse_transliteration($)
{
    my ($lx)= @_;
    return parse_schema_qualified($lx, 'Transliteration');
}

sub parse_transcoding($)
{
    my ($lx)= @_;
    return parse_schema_qualified($lx, 'Transcoding');
}

sub parse_engine($)
{
    my ($lx)= @_;
    return parse_schema_qualified($lx, 'Engine');
}


sub parse_column_name($)
{
    my ($lx)= @_;
    my $r= create ($lx, 'ColumnName', qw(token));

    parse_choice($lx,
        'ident' => sub {
            $r->{type}= 'ident';
            $r->{token}= $lx->{token};
            lexer_shift($lx);
        },

        'interpolColumn' => 'interpol',
        'interpol' => sub {
            $r->{type}= 'interpol';
            $r->{token}= $lx->{token};
            lexer_shift($lx);
        },
    );
    return if $lx->{error};

    lock_keys %$r;
    return $r;
}

sub parse_column_index($)
{
    my ($lx)= @_;
    my $r= create ($lx, 'ColumnIndex', qw(name length desc));

    return unless
        $r->{name}= parse_column_name($lx);

    if (looking_at($lx, '(', SHIFT)) {
        return unless
            $r->{length}= parse_limit_expr($lx)
        and expect ($lx, ')', SHIFT);
    }

    if (looking_at($lx, 'DESC', SHIFT)) {
        $r->{desc}= 1;
    }
    elsif (looking_at($lx, 'ASC', SHIFT)) {
        #ignore
    }

    lock_hash %$r;
    return $r;
}

sub parse_table_name($)
{
    my ($lx)= @_;
    my $r= create ($lx, 'TableName', qw(token));

    parse_choice($lx,
        'ident' => sub {
            $r->{type}= 'ident';
            $r->{token}= $lx->{token};
            lexer_shift($lx);
        },

        'interpolTable' => 'interpol',
        'interpol' => sub {
            $r->{type}= 'interpol';
            $r->{token}= $lx->{token};
            lexer_shift($lx);
        },
    );
    return if $lx->{error};

    lock_keys %$r;
    return $r;
}

sub parse_table_as($)
{
    my ($lx)= @_;
    my $r= create ($lx, 'TableAs', qw(table as));

    return unless
        $r->{table}= parse_table($lx);

    if (looking_at($lx, 'AS', SHIFT)) {
        return unless
            $r->{as}= parse_table_name($lx);
    }

    lock_hash %$r;
    return $r;
}

sub parse_value_or_column_into($$$)
{
    my ($lx, $r, $type)= @_;

    my $token= $lx->{token};
    lexer_shift($lx);

    if (looking_at($lx, '.')) {
        $r->{type}= 'column';
        $r->{arg}=  parse_column($lx, [ $token ]);
    }
    else {
        $r->{type}=  $type;
        $r->{token}= $token;
    }
}

sub parse_expr($;$$);
sub parse_select_stmt($);
sub parse_funcsep($$$);
sub parse_expr_post($$$$);

use constant ACTION_AMBIGUOUS => undef;
use constant ACTION_REDUCE    => -1;
use constant ACTION_SHIFT     => +1;

sub plural($;$$)
{
    my ($cnt, $sg, $pl)= @_;
    return $cnt == 1 ? (defined $sg ? $sg : '') : (defined $pl ? $pl : 's');
}

sub parse_limit_expr($)
{
    my ($lx)= @_;
    return unless
        my $limit= parse_limit_num($lx);
    my $r= create_Expr ($lx);
    $r->{type}= 'limit';
    $r->{arg}= $limit;
    lock_hash %$r;
    return $r;
}

sub parse_char_unit($)
{
    my ($lx)= @_;
    my $r= create($lx, 'CharUnit', qw(name));
    $r->{name}= expect($lx, ['CHARACTERS', 'CODE_UNITS', 'OCTETS'], SHIFT);
    lock_hash %$r;
    return $r;
}

sub parse_list_delim($$)
{
    my ($lx, $func)= @_;
    return unless
        expect($lx, '(', SHIFT)
    and my $list= parse_list([], $lx, $func, ',', ')')
    and expect($lx, ')', SHIFT);
    return $list;
}

sub parse_type_post_inner($)
{
    my ($lx)= @_;

    my $functor= undef;
    my @arg= ();
    parse_choice ($lx,
        -default => sub {
            if (my $spec= find_ref(%type_spec, $lx->{token}{kind})) {
                if ($spec->{value_list}) {
                    $functor= 'basewlist',
                    push @arg, lexer_shift($lx);
                    return unless
                        my $value_list= parse_list_delim($lx, \&parse_expr);
                    push @arg, @$value_list;
                }
                else {
                    $functor= 'base';
                    push @arg, lexer_shift($lx);
                }
            }
        },

        'UNSIGNED' => 'SIGNED',
        'SIGNED' => sub {
            $functor= 'property';
            push @arg, 'sign', lexer_shift($lx);
        },
        'DROP SIGN' => sub {
            $functor= 'property';
            push @arg, 'sign', '';
            lexer_shift($lx);
        },

        'ZEROFILL' => sub {
            $functor= 'property';
            push @arg, 'zerofill', lexer_shift($lx);
        },

        'DROP ZEROFILL' => sub {
            $functor= 'property';
            push @arg, 'zerofill', '';
            lexer_shift($lx);
        },

        'ASCII' => sub {
            my $cs= create($lx, 'CharSet', qw(token));
            $cs->{token}= ident_new($lx, 'latin1');
            $functor= 'property';
            push @arg, 'charset', $cs;
            lexer_shift($lx);
        },
        'UNICODE' => sub {
            my $cs= create($lx, 'CharSet', qw(token));
            $cs->{token}= ident_new($lx, 'ucs2');
            $functor= 'property';
            push @arg, 'charset', $cs;
            lexer_shift($lx);
        },
        'CHARACTER SET' => sub {
            lexer_shift($lx);
            return unless
                my $arg= parse_charset($lx);
            $functor= 'property';
            push @arg, 'charset', $arg;
        },
        'DROP CHARACTER SET' => sub {
            $functor= 'property';
            push @arg, 'charset', '';
            lexer_shift($lx);
        },

        'COLLATE' => sub {
            lexer_shift($lx);
            return unless
                my $arg= parse_collate($lx);
            $functor= 'property';
            push @arg, 'collate', $arg;
        },
        'DROP COLLATE' => sub {
            $functor= 'property';
            push @arg, 'collate', '';
            lexer_shift($lx);
        },

        'WITH LOCAL TIME ZONE' => 'WITH TIME ZONE',
        'WITHOUT TIME ZONE' => 'WITH TIME ZONE',
        'WITH TIME ZONE' => sub {
            $functor= 'property';
            push @arg, 'timezone', lexer_shift($lx);
        },

        'DROP TIME ZONE' => sub {
            $functor= 'property';
            push @arg, 'timezone', '';
            lexer_shift($lx);
        },

        '(' => sub {
            lexer_shift($lx);
            return unless
                my $list= parse_list ([], $lx, \&parse_limit_expr, ',', ')');

            parse_choice($lx,
                'K' => 'G',
                'M' => 'G',
                'G' => sub {
                     if (scalar(@$list) > 1) {
                         $lx->{error}= "At most one value in () expected, but found ".scalar($list);
                         return;
                     }

                     $functor= 'largelength';
                     push @arg, $list->[0];

                     push @arg, lexer_shift($lx);

                     if (looking_at($lx, ')')) {
                         push @arg, '';
                     }
                     else {
                         return unless
                             my $unit= parse_char_unit($lx);

                         push @arg, $unit;
                     }
                },

                'ident' => sub {
                     if (scalar(@$list) > 1) {
                         $lx->{error}= "At most one value in () expected, but found ".scalar($list);
                         return;
                     }

                     $functor= 'largelength';
                     push @arg, '';

                },

                -default => sub {
                    if (scalar(@$list) > 2) {
                        $lx->{error}= "At most two values in () expected, but found ".scalar($list);
                        return;
                    }

                    $functor= 'length';
                    push @arg, @$list;
                }
            );
            return if $lx->{error};
            return unless expect($lx, ')', SHIFT);
        },
    );

    return ($functor, \@arg);
}

sub parse_type_post($$);
sub parse_type_post($$)
{
    my ($lx, $base)= @_;
    my $r= create($lx, 'TypePost', qw(base functor arg));
    $r->{base}= $base;

    ($r->{functor}, $r->{arg})= parse_type_post_inner($lx);
    return
        if $lx->{error};

    return $base
        unless defined $r->{functor};

    return parse_type_post ($lx, $r);
}

sub parse_type($)
{
    my ($lx)= @_;
    my $r= create($lx, 'Type', qw(base token));

    if (looking_at($lx, ['interpol', 'interpolType'])) {
        $r->{type}= 'interpol';
        $r->{token}= $lx->{token};
        lexer_shift($lx);
    }
    else {
        unless ($type_spec{$lx->{token}{kind}}) {
            $lx->{error}= 'Expected type name, but found '.token_describe($lx->{token});
            return;
        }
        $r->{type}= 'base';
        $r->{base}= $lx->{token}{kind};
    }

    lock_hash %$r;
    return parse_type_post ($lx, $r);
}

sub parse_type_list($) # without enclosing (...)
{
    my ($lx)= @_;
    return unless
        my $arg= parse_list ([], $lx, \&parse_type, ',', ')');

    my $r= create ($lx, ['TypeList','explicit'], qw(arg));
    $r->{arg}= $arg;
    lock_hash %$r;
    return $r;
}

sub parse_type_list_delim($) # with enclosing (...)
{
    my ($lx)= @_;

    return parse_choice($lx,
        '(' => sub {
            lexer_shift($lx);
            return unless
                my $r= parse_type_list ($lx)
            and expect ($lx, ')', SHIFT);
            return $r;
        },

        'interpol' => sub { # Perl array reference:
            my $r= create ($lx, ['TypeList','interpol'], qw(token));
            $r->{token}= $lx->{token};
            lexer_shift($lx);
            lock_hash %$r;
            return $r;
        },
    );
}

sub parse_on_action($)
{
    my ($lx)= @_;
    return looking_at($lx, ['RESTRICT', 'CASCADE', 'SET NULL', 'SET DEFAULT', 'NO ACTION'], SHIFT);
}

sub parse_references($)
{
    my ($lx)= @_;
    my $r= create($lx, 'References', qw(table column match on_delete on_update));

    lexer_shift($lx);

    return unless
        $r->{table}= parse_table($lx)
    and $r->{column}= parse_list_delim($lx, \&parse_column_name);

    if (looking_at($lx, 'MATCH', SHIFT)) {
        $r->{match}= expect ($lx, ['FULL','PARTIAL','SINGLE'], SHIFT);
    }

    parse_try_list([], $lx, sub {
        parse_choice($lx,
            'ON DELETE' => sub {
                lexer_shift($lx);
                return unless
                    $r->{on_delete}= parse_on_action($lx);
            },
            'ON UPDATE' => sub {
                lexer_shift($lx);
                return unless
                    $r->{on_update}= parse_on_action($lx);
            },
            -default => sub {}
        );
    });
    return if $lx->{error};

    lock_hash %$r;
    return $r;
}

sub parse_column_spec_post_inner($)
{
    my ($lx)= @_;
    my $functor= undef;
    my @arg= ();

    my $constraint= undef;
    if (looking_at($lx, 'CONSTRAINT', SHIFT)) {
        return unless
            $constraint= parse_constraint($lx);
    }

    parse_choice($lx,
        -default => sub {
            if ($constraint) {
                $lx->{error}= 'Constraint expected';
            }
            else {
                my ($func, $arg)= parse_type_post_inner($lx); # inherit column type post
                if ($func) {
                    $functor= "type_$func";
                    @arg= @$arg;
                }
            }
        },
        'NOT NULL' => sub {
            $functor= 'property';
            push @arg, $constraint, 'notnull', lexer_shift($lx);
        },
        'NULL' => sub {
            $functor= 'property';
            push @arg, $constraint, 'notnull', '';
            lexer_shift($lx);
        },

        'AUTO_INCREMENT' => sub {
            $functor= 'property';
            push @arg, $constraint, 'autoinc', lexer_shift($lx);
        },
        'DROP AUTO_INCREMENT' => sub {
            $functor= 'property';
            push @arg, $constraint, 'autoinc', '';
            lexer_shift($lx);
        },

        'UNIQUE' => sub {
            $functor= 'property';
            push @arg, $constraint, 'unique', lexer_shift($lx);
        },
        'DROP UNIQUE' => sub {
            $functor= 'property';
            push @arg, $constraint, 'unique', '';
            lexer_shift($lx);
        },

        'PRIMARY KEY' => sub {
            $functor= 'property';
            push @arg, $constraint, 'primary', lexer_shift($lx);
        },
        'DROP PRIMARY KEY' => sub {
            $functor= 'property';
            push @arg, $constraint, 'primary', '';
            lexer_shift($lx);
        },

        'KEY' => sub {
            $functor= 'property';
            push @arg, $constraint, 'key', lexer_shift($lx);
        },
        'DROP KEY' => sub {
            $functor= 'property';
            push @arg, $constraint, 'key', '';
            lexer_shift($lx);
        },

        'DEFAULT' => sub {
            lexer_shift($lx);
            return unless
                my $val= parse_expr($lx);
            $functor= 'property';
            push @arg, $constraint, 'default', $val;
        },
        'DROP DEFAULT' => sub {
            lexer_shift($lx);
            $functor= 'property';
            push @arg, $constraint, 'default', '';
        },

        'CHECK' => sub {
            lexer_shift($lx);
            return unless
                my $val= parse_expr($lx);
            $functor= 'property';
            push @arg, $constraint, 'check', $val;
        },
        'DROP CHECK' => sub {
            lexer_shift($lx);
            $functor= 'property';
            push @arg, $constraint, 'check', '';
        },

        ($read_dialect{mysql} ?
            (
                'COMMENT' => sub {
                    lexer_shift($lx);
                    return unless
                        my $val= parse_expr($lx);
                    $functor= 'property';
                    push @arg, $constraint, 'comment', $val;
                },
                'DROP COMMENT' => sub {
                    lexer_shift($lx);
                    $functor= 'property';
                    push @arg, $constraint, 'comment', '';
                },
                'COLUMN_FORMAT' => sub {
                    lexer_shift($lx);
                    $functor= 'property';
                    push @arg, $constraint, 'column_format',
                               expect($lx, ['FIXED','DYNAMIC','DEFAULT'], SHIFT);
                },
                'STORAGE' => sub {
                    lexer_shift($lx);
                    $functor= 'property';
                    push @arg, $constraint, 'storage',
                               expect($lx, ['DISK','MEMORY','DEFAULT'], SHIFT);
                }
            )
        :   ()
        ),

        'REFERENCES' => sub {
            return unless
                my $ref= parse_references($lx);
            $functor= 'property';
            push @arg, $constraint, 'references', $ref;
        },
        'DROP REFERENCES' => sub {
            lexer_shift($lx);
            $functor= 'property';
            push @arg, $constraint, 'references', '';
        },
    );

    return ($functor, \@arg);
}

sub parse_column_spec_post($$);
sub parse_column_spec_post($$)
{
    my ($lx, $base)= @_;

    my $r= create($lx, 'ColumnSpecPost', qw(base functor arg));
    $r->{base}= $base;
    $r->{arg}= [];

    ($r->{functor}, $r->{arg})= parse_column_spec_post_inner($lx);
    return
        if $lx->{error};

    return $base
        unless defined $r->{functor};

    return parse_column_spec_post ($lx, $r);
}

sub parse_column_spec($)
{
    my ($lx)= @_;

    my $r= create($lx, 'ColumnSpec', qw(datatype name token));

    parse_choice($lx,
        'interpolColumnSpec' => 'interpol',
        'interpol' => sub {
            $r->{type}= 'interpol';
            $r->{token}= $lx->{token};
            lexer_shift($lx);
        },

        -default => sub {
            $r->{type}= 'base';
            return unless
               $r->{datatype}= parse_type($lx);
        }
    );
    return if $lx->{error};

    lock_hash %$r;
    return parse_column_spec_post($lx, $r);

}

sub parse_expr_list($) # without enclosing (...)
{
    my ($lx)= @_;
    if (looking_at($lx, [@SELECT_INITIAL,'interpolStmt'])) {
        return unless
            my $q= parse_select_stmt($lx);

        my $r= create_Expr ($lx);
        $r->{type}= 'subquery';
        $r->{arg}=  $q;
        return $r;
    }
    else {
        my $r= create ($lx, ['ExprList','explicit'], qw(arg));

        return unless
            my $arg= parse_list ([], $lx, \&parse_expr, ',', ')');

        $r->{arg}= $arg;
        lock_hash %$r;
        return $r;
    }
}

sub parse_expr_list_delim($) # with enclosing (...)
{
    my ($lx)= @_;

    return parse_choice($lx,
        '(' => sub {
            lexer_shift($lx);
            return unless
                my $r= parse_expr_list ($lx)
            and expect ($lx, ')', SHIFT);
            return $r;
        },

        'interpol' => sub { # Perl array reference:
            my $r= create ($lx, ['ExprList','interpol'], qw(token));
            $r->{token}= $lx->{token};
            lexer_shift($lx);
            lock_hash %$r;
            return $r;
        },
    );
}

sub get_rhs($$)
{
    my ($left, $arg_i)= @_;
    return $left->{rhs_map}{$arg_i} || $left->{rhs};
}

sub parse_thing($$;$$)
{
    my ($lx, $thing_name, $left, $right_mark)= @_;
    return switch ($thing_name,
        'expr' => sub {
            return parse_expr ($lx, $left, $right_mark)
        },
        'type' => sub {
            return parse_type ($lx);
        },
        'string_expr' => sub {
            return parse_expr ($lx, $left, 'string')
        },
        'expr_list' => sub {
            return parse_expr_list_delim($lx);
        },
        'type_list' => sub {
            return parse_type_list_delim($lx);
        },
    );
}

sub parse_funcsep($$$)
{
    my ($lx, $r, $pattern)= @_;
    for my $e (@$pattern) {
        if (!ref($e)) {
            return unless
                expect($lx, $e, SHIFT);
            push @{ $r->{arg} }, $e; # no ref()
        }
        elsif (ref($e) eq 'SCALAR') {
            return unless
                my $arg= parse_thing($lx, $$e); # will return a ref()
            push @{ $r->{arg} }, $arg;
        }
        elsif (ref($e) eq 'ARRAY') {
            if (looking_at($lx, $e->[0])) {
                return unless
                    parse_funcsep($lx, $r, $e);
            }
        }
        else {
            die "Unrecognised pattern piece, ref()=".ref($e);
        }
    }
    return $r;
}

sub parse_check($)
{
    my ($lx)= @_;
    my $r= create ($lx, 'Check', qw(expr));

    my $cond= parse_expr_post($lx, undef, undef, create($lx, 'ExprEmpty'));
    return unless $cond;

    $r->{expr}= $cond;
    return $r;
}

sub parse_when_post($)
{
    my ($lx)= @_;

    return unless
        looking_at($lx, 'WHEN', SHIFT);  # no error if false (-> parse_try_list)

    my $cond;

    my $functor= find_functor(\%functor_suffix, $lx->{token}{kind});
    if ($functor && $functor->{allow_when}) {
        $cond= parse_expr_post($lx, undef, undef, create($lx, 'ExprEmpty'));
    }
    else {
        $cond= parse_expr($lx);
    }

    return unless
        $cond
    and expect($lx, 'THEN', SHIFT)
    and my $expr= parse_expr($lx);

    $cond->{maybe_check}= 1; # allow Check interpolation if this is an Expr

    return [ $cond, $expr ];
}

sub parse_when($)
{
    my ($lx)= @_;

    return unless
        looking_at($lx, 'WHEN', SHIFT)   # no error if false (-> parse_try_list)
    and my $cond= parse_expr($lx)
    and expect($lx, 'THEN', SHIFT)
    and my $expr= parse_expr($lx);

    return [ $cond, $expr ];
}

sub shift_or_reduce_pure($$$)
# $right_mark is either 0/undef, 1, or 'string', see parse_expr().
{
    my ($left, $right, $right_mark)= @_;

    # hack for 'IN':
    return ACTION_REDUCE
        if ($right_mark || '') eq 'string' &&
           $right->{value} eq 'IN';

    # currently, this is very simple, because we don't use precedences:
    return ACTION_SHIFT
        unless $left;

    # special rule to allow sequencing even for operators without precedence:
    return ACTION_REDUCE
        if $left->{value} eq $right->{value} &&
           $left->{read_type} eq 'infix()';

    # parse with precedences?
    if ($do_prec) {
        # if both have a precedence:
        if ($left->{prec} && $right->{prec}) {
            return ACTION_REDUCE
                if $left->{prec} > $right->{prec};

            return ACTION_SHIFT
                if $left->{prec} < $right->{prec};

            # if both have an associativity and the associativity is the same:
            if ($left->{assoc} && $right->{assoc} &&
                $left->{assoc} == $right->{assoc})
            {
                if ($left->{assoc} == ASSOC_LEFT && $right_mark) {
                    return ACTION_REDUCE;
                }
                else {
                    return ACTION_SHIFT;
                }
            }
        }
    }
    else {
        # no precedences at all:
        # For infix23 and infix3, we need to reduce, instead of failing:
        if (defined $left->{value2}) {
            return ACTION_REDUCE;
        }
    }

    # otherwise: ambiguous
    return ACTION_AMBIGUOUS;
}

sub shift_or_reduce($$$$)
{
    my ($lx, $left, $right, $right_mark)= @_;
    my $result= shift_or_reduce_pure ($left, $right, $right_mark);
    unless ($result) {
        $lx->{error}= "Use of operators '$left->{value}' vs. '$right->{value}' ".
                      "requires parentheses.";
    }
    return $result;
}

sub find_functor($$)
{
    my ($map, $kind)= @_;

    return unless
        my $functor= find_ref(%$map, $kind);

    if (my $accept= $functor->{accept}) {
        for my $a (@$accept) {
            if ($read_dialect{$a}) {
                return $functor;
            }
        }
        return;
    }

    return $functor;
}

sub set_expr_functor($$@)
{
    my ($r, $functor, @arg)= @_;
    my_confess if $r->{arg};

    $r->{type}=    $functor->{type};
    $r->{functor}= $functor;
    $r->{arg}=     [ @arg ];
}

sub parse_expr_post($$$$)
# $right_mark is either 0/undef, 1, or 'string', see parse_expr().
{
    my ($lx, $left, $right_mark, $arg1)= @_;

    # infix:
    my $kind= $lx->{token}{kind};

    if (my $right= find_functor(\%functor_suffix, $kind)) {
        return unless
            my $action= shift_or_reduce($lx, $left, $right, $right_mark);

        if ($action == ACTION_SHIFT) {
            lexer_shift ($lx);

            my $r= create_Expr ($lx);
            set_expr_functor ($r, $right, $arg1);

            switch ($right->{read_type},
                'infix2' => sub {
                    # parse second arg:
                    return unless
                        my $arg2= parse_thing ($lx, get_rhs($right,0), $right, 1);
                    push @{ $r->{arg} }, $arg2;
                },
                'infix()' => sub {
                    # parse sequence:
                    my $i=0;
                    do {
                        return unless
                            my $argi= parse_thing ($lx, get_rhs($right,$i++), $right, 1);
                        push @{ $r->{arg} }, $argi;
                    } while (looking_at($lx, $kind, SHIFT));             # same operator?
                },
                'infix23' => sub {
                    # parse second arg:
                    return unless
                        my $arg2= parse_thing ($lx, get_rhs($right,0), $right, 1);
                    push @{ $r->{arg} }, $arg2;

                    # maybe parse third arg:
                    if (looking_at ($lx, $right->{value2}, SHIFT)) {
                        return unless
                            my $arg3= parse_thing ($lx, get_rhs($right,1), $right, 1);
                        push @{ $r->{arg} }, $arg3;
                    }
                },
                'infix3' => sub {
                    # parse second arg:
                    return unless
                        my $arg2= parse_thing ($lx, get_rhs($right,0), $right, 1)
                    and expect ($lx, $right->{value2}, SHIFT)
                    and my $arg3= parse_thing ($lx, get_rhs($right,1), $right, 1); # descend

                    push @{ $r->{arg} }, $arg2, $arg3;
                },
                'suffix' => sub {
                    # nothing more to do
                }
            );
            return if $lx->{error};

            lock_keys %$r; # {maybe_check} may be modified if we parse WHEN clauses.

            return parse_expr_post ($lx, $left, $right_mark, $r); # descend
        }
    }

    return $arg1;
}

sub parse_expr($;$$)
# $right_mark is either 0/undef, 1, or 'string'.
# 'string' is a hack for POSITION(a IN b) and keeps parse_expr
# from shifting IN.  It's one of these typical design complications
# in SQL grammar that prevents you from writing a straight-forward
# recursive parser.  If $right_mark eq 'string', then $functor
# is undef.  Otherwise $functor is defined if $right_mark is true.
{
    my ($lx, $functor, $right_mark)= @_;
    my $r= create_Expr ($lx);

    parse_choice($lx,
        '.' => sub {
            lexer_shift($lx);
            $r->{type}= 'column';
            $r->{arg}=  parse_column ($lx);
        },

        'interpolColumn' => 'ident',
        'interpolTable'  => 'ident',
        '*'              => 'ident',
        'ident' => sub {
            $r->{type}= 'column';
            $r->{arg}=  parse_column ($lx);
        },

        'interpolExpr' => sub {
            $r->{type}= 'interpol';
            $r->{token}= $lx->{token};
            lexer_shift($lx);
        },

        'interpol' => sub {
            parse_value_or_column_into ($lx, $r, 'interpol');
        },

        'TRUE' => '?',
        'FALSE' => '?',
        'NULL' => '?',
        'UNKNOWN' => '?',
        'DEFAULT' => '?',
        '?' => sub {
            $r->{type}=  'interpol';
            $r->{token}= $lx->{token};
            lexer_shift($lx);

            # special care for functors like MySQL's DEFAULT(...).  Since
            # there's both DEFAULT and DEFAULT(...), we need to check.  We
            # use find_functor() in order to support read_dialect properly.
            if (looking_at($lx, '(', SHIFT) and
                my $functor= find_functor(\%functor_special, $r->{token}{kind}))
            {
                switch ($functor->{read_type},
                    'funcall1col' => sub {
                        return unless
                            my $arg= parse_column_name($lx)
                        and expect ($lx, ')', SHIFT);
                        set_expr_functor ($r, $functor, $arg);
                    }
                );
            }
        },

        'CASE' => sub {
            lexer_shift($lx);
            $r->{type}= 'case';
            if (looking_at($lx, ['WHEN','ELSE','END'])) { # without 'switchval'
                return unless
                    $r->{arg}= parse_try_list([], $lx, \&parse_when);
            }
            else { # with switchval
                return unless
                    $r->{switchval}= parse_expr($lx)
                and $r->{arg}= parse_try_list([], $lx, \&parse_when_post);
            }

            if (looking_at($lx, 'ELSE', SHIFT)) {
                return unless
                    $r->{otherwise}= parse_expr($lx);
            }

            return unless
                expect($lx, 'END', SHIFT);
        },

        'ALL' => 'SOME',
        'ANY' => 'SOME',
        'SOME' => sub {
            if (!$functor || !$functor->{comparison} || !$right_mark) {
                $lx->{error}= "$lx->{token}{kind} can only be used directly after a comparison.";
                return;
            }
            my $functor2= find_functor(\%functor_special, $lx->{token}{kind});
            unless ($functor2) {
                $lx->{error}= "Unexpected $lx->{token}{kind} in expression.";
                return;
            }
            lexer_shift($lx);

            return unless
                expect($lx, '(', SHIFT)
            and my $q= parse_select_stmt ($lx)
            and expect($lx, ')', SHIFT);

            my $r2= create_Expr($lx);
            $r2->{type}= 'subquery';
            $r2->{arg}=  $q;

            set_expr_functor ($r, $functor2, $r2);
        },

        '(' => sub {
            lexer_shift($lx);
            if (looking_at($lx, [@SELECT_INITIAL,'interpolStmt'])) {
                return unless
                    my $q= parse_select_stmt ($lx);
                $r->{type}= 'subquery';
                $r->{arg}=  $q;
            }
            else {
                return unless
                    my $arg= parse_expr($lx);
                $r->{type}= '()';
                $r->{arg}= $arg;
            }
            return unless
                expect($lx, ')', SHIFT);
        },

        -default => sub {
            my $functor2= find_functor(\%functor_prefix, $lx->{token}{kind});
            if (!$functor2 && $lx->{token}{type} eq 'keyword') {      # generic funcall
                $functor2= make_op($lx->{token}{kind}, 'funcall');
            }

            # prefix / funcall:
            if ($functor2) {
                set_expr_functor ($r, $functor2);
                lexer_shift($lx);

                switch ($functor2->{read_type},
                    'prefix' => sub {
                        my $arg;
                        if (looking_at($lx, '(', NO_SHIFT)) {
                            return unless
                                $r->{arg}= parse_list_delim ($lx, \&parse_expr);
                        }
                        else {
                            return unless
                                my $arg= parse_thing ($lx, get_rhs($functor2,0), $functor2, 0);
                            $r->{arg}= [ $arg ];
                        }
                    },
                    'funcall' => sub {
                        return unless
                            $r->{arg}= parse_list_delim ($lx, \&parse_expr);
                    },
                    'funcall1col' => sub {
                        return unless
                            expect ($lx, '(', SHIFT)
                        and my $arg1= parse_column_name($lx)
                        and expect ($lx, ')', SHIFT);
                        $r->{arg}= [ $arg1 ];
                    },
                    'funcsep' => sub {
                        return unless
                            expect ($lx, '(', SHIFT)
                        and parse_funcsep ($lx, $r, $functor2->{rhs});
                    },
                );
                return if $lx->{error};
            }
            # error:
            elsif (! $lx->{error}) {
                $lx->{error}= "Unexpected ".token_describe($lx->{token})." in expression";
            }

            return;
        },
    );
    return if $lx->{error};

    die unless $r;
    lock_keys %$r; # {arg} may be modified when parsing sequenced infix operators
                   # and {maybe_check} may be modified when parsing WHEN clauses

    # And now parse the suffix:
    return parse_expr_post ($lx, $functor, $right_mark, $r);
}

sub parse_limit_num($) # Simply returns the single token if it is appropriate.
{
    my ($lx)= @_;
    return parse_choice($lx,
        'interpolExpr' => 'interpol',
        '?'            => 'interpol',
        'interpol' => sub {
            my $r= $lx->{token};
            lexer_shift($lx);
            return $r;
        },
    );
}

sub parse_expr_as($)
{
    my ($lx)= @_;
    my $r= create ($lx, 'ExprAs', qw(expr as));

    return unless
        $r->{expr}= parse_expr($lx);

    if (looking_at($lx, 'AS', SHIFT)) {
        return unless
            $r->{as}= parse_column_name($lx);
    }

    lock_hash %$r;
    return $r;
}

sub parse_order($)
{
    my ($lx)= @_;
    my $r= create ($lx, 'Order', qw(type expr token desc));
    $r->{desc}= 0;

    parse_choice($lx,
        -default => sub {
            $r->{type}= 'expr';
            return unless
                $r->{expr}= parse_expr($lx);
        },

        'interpolOrder' => 'interpol',
        'interpol' => sub {
            if ($lx->{token}{type} eq 'string') {
                # Strings are still expressions, not column names.  There is no
                # other way of forcing Perl interpolation to String type, so
                # we assume a string here.
                $r->{type}= 'expr';
                return unless
                    $r->{expr}= parse_expr($lx);
            }
            else {
                $r->{type}= 'interpol';
                $r->{token}= $lx->{token};
                lexer_shift($lx);
            }
        },
    );
    return if $lx->{error};

    parse_choice($lx,
        -default => sub {}, # no error
        'ASC'    => sub { lexer_shift($lx); $r->{desc}= 0; },
        'DESC'   => sub { lexer_shift($lx); $r->{desc}= 1; },
    );

    lock_hash %$r;
    return $r;
}

sub parse_join($)
{
    my ($lx)= @_;
    my $r= create ($lx, 'Join', qw(token table qual on using natural));

    #print STDERR "parse join: ".token_describe($lx->{token})."\n";
    parse_choice($lx,
        'interpolJoin' => 'interpol',
        'interpol' => sub {
            $r->{type}=  'interpol',
            $r->{token}= $lx->{token};
            lexer_shift($lx);
        },

        -default => sub {
            my $shifted= 0;

            my $want_condition= 1;
            if (looking_at($lx, 'NATURAL', SHIFT)) {
                $r->{natural}= 1;
                $shifted= 1;
                $want_condition= 0;
            }

            parse_choice($lx,
                -default => sub {
                    $r->{type}= 'INNER';
                },

                'INNER' => sub{
                    $r->{type}= 'INNER';
                    lexer_shift($lx);
                    $shifted= 1;
                },

                'UNION' => 'CROSS',
                'CROSS' => sub {
                    if ($r->{natural}) {
                        $lx->{error}= "NATURAL cannot be used with CROSS or UNION JOIN";
                        return;
                    }

                    $r->{type}= lexer_shift($lx);
                    $want_condition= 0;
                    $shifted= 1;
                },

                'LEFT'  => 'FULL',
                'RIGHT' => 'FULL',
                'FULL' => sub {
                    $r->{type}= lexer_shift($lx);
                    looking_at($lx, 'OUTER', SHIFT);
                    $shifted= 1;
                },
            );
            return if $lx->{error};

            unless (looking_at ($lx, 'JOIN', SHIFT)) {
                if ($shifted) {
                    $lx->{error}= "Expected JOIN, but found ".token_describe($lx->{token});
                }
                $r= undef;
                return;
            }

            return unless
                $r->{table}= parse_list([], $lx, \&parse_table_as, ',');

            if ($want_condition) {
                parse_choice($lx,
                    'ON' => sub {
                        lexer_shift($lx);
                        $r->{on}= parse_expr($lx);
                    },
                    'USING' => sub {
                        lexer_shift($lx);
                        return unless
                            $r->{using}= parse_list_delim ($lx, \&parse_column_name);
                    },
                );
            }
        }
    );
    return if $lx->{error};
    return unless $r;

    lock_hash %$r;
    return $r;
}

sub push_option($$$)
{
    my ($lx, $list, $words)= @_;
    if (my $x= looking_at($lx, $words, SHIFT)) {
        push @$list, $x;
        return $x;
    }
    return 0;
}

sub push_option_list($$$)
{
    my ($lx, $list, $words)= @_;
    while (push_option($lx, $list, $words)) {}
}

sub parse_where($) # WHERE is supposed to haveing been parsed already here
{
    my ($lx)= @_;
    # FIXME: MISSING:
    #    - WHERE CURRENT OF (i.e., cursor support)
    return parse_expr($lx);
}

sub parse_select($)
{
    my ($lx)= @_;
    my $r= create ($lx, ['Stmt','Select'],
        qw(
            opt_front
            opt_back
            expr_list
            from
            join
            where
            group_by
            group_by_with_rollup
            having
            order_by
            limit_cnt
            limit_offset
        )
    );

    return unless expect($lx, 'SELECT', SHIFT);

    # Missing:
    #   PostgresQL:
    #     - DISTINCT **ON** <expr>
    #     - WITH
    #     - WINDOW
    #     - FETCH
    #     - FOR UPDATE|SHARE **OF** ( <Table> , ... )
    #
    # All:
    #     - UNION
    #     - INTERSECT
    #     - EXCEPT
    #     - FETCH [ FIRST | NEXT ] count [ ROW | ROWS ] ONLY  (same as LIMIT in SQL:2008)

    $r->{opt_front}= [];
    push_option ($lx, $r->{opt_front}, [
        'DISTINCT', 'ALL',
        ($read_dialect{mysql} ?
            ('DISTINCTROW')
        :   ()
        )
    ]);

    push_option_list ($lx, $r->{opt_front}, [
        ($read_dialect{mysql} ?
            (
                'HIGH_PRIORITY', 'STRAIGHT_JOIN',
                'SQL_SMALL_RESULT', 'SQL_BIG_RESULT', 'SQL_BUFFER_RESULT',
                'SQL_CACHE', 'SQL_NO_CACHE', 'SQL_CALC_FOUND_ROWS'
            )
        :   ()
        )
    ]);

    return unless
        $r->{expr_list}= parse_list([], $lx, \&parse_expr_as, ',');

    if (looking_at($lx, 'FROM', SHIFT)) {
        return unless
            $r->{from}= parse_list([], $lx, \&parse_table_as, ',')
        and $r->{join}= parse_try_list([], $lx, \&parse_join);

        if (looking_at($lx, 'WHERE', SHIFT)) {
            return unless
                $r->{where}= parse_where ($lx);
        }
        if (looking_at($lx, 'GROUP BY', SHIFT)) {
            return unless
                $r->{group_by}= parse_list([], $lx, \&parse_order, ',');

            $r->{group_by_with_rollup}= looking_at($lx, 'WITH ROLLUP', SHIFT);
        }
        if (looking_at($lx, 'HAVING', SHIFT)) {
            return unless
                $r->{having}= parse_expr ($lx);
        }
        if (looking_at($lx, 'ORDER BY', SHIFT)) {
            return unless
                $r->{order_by}= parse_list([], $lx, \&parse_order, ',');
        }

        if (looking_at($lx, 'LIMIT', SHIFT)) {
            unless (looking_at($lx, 'ALL', SHIFT)) {
                my $first_num= parse_limit_num ($lx);
                if (looking_at($lx, ',', SHIFT)) {
                    $r->{limit_offset}= $first_num;
                    $r->{limit_cnt}=    parse_limit_num($lx);
                }
                else {
                    $r->{limit_cnt}= $first_num;
                }
            }
        }
        if (!$r->{limit_offset} &&
            looking_at ($lx, 'OFFSET', SHIFT))
        {
            $r->{limit_offset}= parse_limit_num ($lx);
        }

        $r->{opt_back}=  [];
        push_option_list ($lx, $r->{opt_back}, [
            ($read_dialect{mysql} || $read_dialect{postgresql} ?
                ('FOR UPDATE')
            :   ()
            ),
            ($read_dialect{mysql} ?
                (
                    'LOCK IN SHARE MODE'  # FIXME: normalise: PostgreSQL: FOR SHARE
                )
            :   ()
            ),
            ($read_dialect{postgresql} ?
                (
                    'FOR SHARE',          # FIXME: normalise: MySQL: LOCK IN SHARE MODE
                    'NOWAIT'
                )
            :   ()
            ),
        ]);
    }

    lock_hash %$r;
    return $r;
}

sub parse_insert($)
{
    my ($lx)= @_;
    my $r= create ($lx, ['Stmt','Insert'],
        qw(
            opt_front
            into
            column
            default_values
            value
            value_interpol
            set
            select
            duplicate_update
        )
    );

    return unless expect($lx, 'INSERT', SHIFT);

    # PostgreSQL:
    #    - RETURNING ...

    $r->{opt_front}= [];
    push_option_list ($lx, $r->{opt_front}, [
        ($read_dialect{mysql} ?
            (
                'IGNORE',
                'LOW_PRIORITY',
                'HIGH_PRIORITY',
                'DELAYED',
            )
        :   ()
        )
    ]);

    looking_at($lx, 'INTO', SHIFT); # optional in MySQL

    return unless
        $r->{into}= parse_table($lx);

    if (looking_at($lx, '(')) {
        return unless
            $r->{column}= parse_list_delim($lx, \&parse_column_name);
    }

    parse_choice($lx,
        'DEFAULT VALUES' => sub {
            lexer_shift($lx);
            $r->{default_values}= 1;
        },

        'VALUE' => 'VALUES',
        'VALUES' => sub {
            lexer_shift($lx);
            $r->{value}= parse_list([], $lx, \&parse_expr_list_delim, ',');
        },

        'SET' => sub {
            # MySQL extension, but will be normalised to VALUES clause, so we
            # always accept this even with !$read_dialect{mysql}.
            if ($r->{column}) {
                $lx->{error}= "Either column list or 'SET' expected, but found both.";
                return;
            }
            lexer_shift($lx);
            $r->{set}= parse_list([], $lx, \&parse_expr, ',');
        },

        (map { $_ => 'interpolStmt' } @SELECT_INITIAL),
        'interpol' => 'interpolStmt',
        'interpolStmt' => sub {
            $r->{select}= parse_select_stmt($lx);
        },
    );
    return if $lx->{error};

    if ($read_dialect{mysql} &&
        looking_at ($lx, 'ON DUPLICATE KEY UPDATE', SHIFT))
    {
        return unless
            $r->{duplicate_update}= parse_list([], $lx, \&parse_expr, ',');
    }

    lock_hash %$r;
    return $r;
}

sub parse_update($)
{
    my ($lx)= @_;
    my $r= create ($lx, ['Stmt','Update'],
        qw(
            opt_front
            table
            set
            from
            join
            where
            order_by
            limit_cnt
            limit_offset
        )
    );

    return unless expect($lx, 'UPDATE', SHIFT);

    # PostgreSQL:
    #    - RETURNING ...

    $r->{opt_front}= [];
    push_option_list ($lx, $r->{opt_front}, [
        ($read_dialect{mysql} ?
            (
                'IGNORE',
                'LOW_PRIORITY',
            )
        :   ()
        ),
        ($read_dialect{postgresql} ?
            (
                'ONLY',
            )
        :   ()
        )
    ]);

    return unless
        $r->{table}= parse_list([], $lx, \&parse_table_as, ',')
    and expect($lx, 'SET', SHIFT)
    and $r->{set}= parse_list([], $lx, \&parse_expr, ',');

    if (looking_at($lx, 'FROM', SHIFT)) {
        return unless
            $r->{from}= parse_list([], $lx, \&parse_table_as, ',');
    }
    return unless
        $r->{join}= parse_try_list([], $lx, \&parse_join);

    if (looking_at($lx, 'WHERE', SHIFT)) {
        return unless
            $r->{where}= parse_where ($lx);
    }
    if (looking_at($lx, 'ORDER BY', SHIFT)) {
        return unless
            $r->{order_by}= parse_list([], $lx, \&parse_order, ',');
    }
    if (looking_at($lx, 'LIMIT', SHIFT)) {
        $r->{limit_cnt}= parse_limit_num($lx);
    }

    lock_hash %$r;
    return $r;
}

sub parse_delete($)
{
    my ($lx)= @_;
    my $r= create ($lx, ['Stmt','Delete'],
        qw(
            opt_front
            from
            from_opt_front
            join
            using
            where
            order_by
            limit_cnt
            limit_offset
        )
    );

    return unless expect($lx, 'DELETE', SHIFT);

    # PostgreSQL:
    #    - RETURNING ...

    $r->{opt_front}= [];
    push_option_list ($lx, $r->{opt_front}, [
        ($read_dialect{mysql} ?
            (
                'IGNORE',
                'LOW_PRIORITY',
                'QUICK'
            )
        :   ()
        )
    ]);

    return unless expect($lx, 'FROM', SHIFT);

    $r->{from_opt_front}= [];
    push_option ($lx, $r->{from_opt_front}, [
        ($read_dialect{postgresql} ?
            ('ONLY')
        :   ()
        )
    ]);

    return unless
        $r->{from}= parse_list([], $lx, \&parse_table_as, ',');

    if (looking_at($lx, 'USING', SHIFT)) {
        return unless
            $r->{using}= parse_list([], $lx, \&parse_table_as, ',');
    }

    return unless
        $r->{join}= parse_try_list([], $lx, \&parse_join);

    if (looking_at($lx, 'WHERE', SHIFT)) {
        return unless
            $r->{where}= parse_where ($lx);
    }
    if (looking_at($lx, 'ORDER BY', SHIFT)) {
        return unless
            $r->{order_by}= parse_list([], $lx, \&parse_order, ',');
    }
    if (looking_at($lx, 'LIMIT', SHIFT)) {
        $r->{limit_cnt}= parse_limit_num($lx);
    }

    lock_hash %$r;
    return $r;
}

sub keyword($$)
{
    my ($lx, $keyword)= @_;
    return
        unless $keyword;

    return $keyword
        if ref($keyword);
        
    my $r= create($lx, 'Keyword', qw(keyword));
    $r->{keyword}= $keyword;
    lock_hash %$r;
    return $r;
}

sub parse_index_option($)
{
    my ($lx)= @_;
    my $r= create($lx, 'IndexOption', qw(arg));

    parse_choice($lx,
        -default => sub {
            $r= undef;
        },

        # MySQL does not like it here, but only accepts it in front of the
        # column list, which is against the manual's description.
        #'USING' => sub {
        #    lexer_shift($lx);
        #    return unless
        #        my $t= expect($lx, ['BTREE','HASH','RTREE'], SHIFT);
        #    $r->{type}= 'using';
        #    $r->{arg}=  $t;
        #},
    );
    return unless $r;
    return if $lx->{error};

    lock_hash %$r;
    return $r;
}

sub parse_index_type ($)
{
    my ($lx)= @_;
    if (looking_at($lx, 'USING', SHIFT)) {
        return expect($lx, ['BTREE','HASH','RTREE'], SHIFT);
    }
    return;
}

sub parse_table_constraint($)
{
    my ($lx)= @_;
    my $r= create($lx, "TableConstraint", qw(constraint index_type column index_option reference));
    $r->{index_option}= [];

    if (looking_at($lx, 'CONSTRAINT', SHIFT)) {
        return unless
            $r->{constraint}= parse_constraint($lx);
    }

    parse_choice($lx,
        'PRIMARY KEY' => sub {
            lexer_shift($lx);
            $r->{type}=  'primary_key';
            $r->{index_type}= parse_index_type($lx);
            return unless
                $r->{column}= parse_list_delim($lx, \&parse_column_index)
            and $r->{index_option}= parse_try_list([], $lx, \&parse_index_option);
        },
        'UNIQUE' => sub {
            lexer_shift($lx);
            $r->{type}= 'unique';
            $r->{index_type}= parse_index_type($lx);
            return unless
                $r->{column}= parse_list_delim($lx, \&parse_column_index)
            and $r->{index_option}= parse_try_list([], $lx, \&parse_index_option);
        },
        'FULLTEXT' => sub {
            lexer_shift($lx);
            $r->{type}= 'fulltext';
            $r->{index_type}= parse_index_type($lx);
            return unless
                $r->{column}= parse_list_delim($lx, \&parse_column_index)
            and $r->{index_option}= parse_try_list([], $lx, \&parse_index_option);
        },
        'SPATIAL' => sub {
            lexer_shift($lx);
            $r->{type}= 'spatial';
            $r->{index_type}= parse_index_type($lx);
            return unless
                $r->{column}= parse_list_delim($lx, \&parse_column_index)
            and $r->{index_option}= parse_try_list([], $lx, \&parse_index_option);
        },
        'FOREIGN KEY' => sub {
            lexer_shift($lx);
            $r->{type}= 'foreign_key';
            $r->{index_type}= parse_index_type($lx);
            return unless
                $r->{column}= parse_list_delim($lx, \&parse_column_name)
            and $r->{reference}= parse_references($lx);
        },
        # 'CHECK' => sub {
        # },
        ($read_dialect{mysql} ?
            (
                'INDEX' => sub {
                    lexer_shift($lx);
                    $r->{type}= 'index';
                    # FIXME: mysql allows an index name here
                    return unless
                        $r->{column}= parse_list_delim($lx, \&parse_column_index);
                    $r->{index_option}= parse_try_list([], $lx, \&parse_index_option);
                }
            )
        :   ()
        ),
    );
    return if $lx->{error};

    lock_hash %$r;
    return $r;
}

sub parse_table_option1($$$$)
{
    my ($lx, $r, $name, $parse)= @_;
    $r->{type}= 'literal';
    $r->{name}= $name;
    lexer_shift($lx);
    looking_at($lx, '=', SHIFT); # optional =
    return unless
        $r->{value}= $parse->($lx);
    while (looking_at($lx, ',', SHIFT)) {} # optional ,
    return $r;
}

sub parse_on_commit_action($)
{
    my ($lx)= @_;
    return keyword ($lx,
        expect($lx,
            [
                'PRESERVE ROWS',
                'DELETE ROWS',
                ($read_dialect{postgresql} ?
                    (
                        'DROP'
                    )
                :   ()
                )
            ],
            SHIFT
        )
    );
}

sub parse_table_option($)
{
    my ($lx)= @_;
    my $r= create($lx, 'TableOption', qw(name value token));

    parse_choice($lx,
        -default => sub {
            $r= undef;
        },

        ($read_dialect{mysql} ?
            (
                'ENGINE' => sub {
                    return parse_table_option1($lx, $r, 'ENGINE', \&parse_engine);
                },
        
                'CHARACTER SET' => 'DEFAULT CHARACTER SET',
                'DEFAULT CHARACTER SET' => sub {
                    return parse_table_option1($lx, $r, 'DEFAULT CHARACTER SET', \&parse_charset);
                },

                'COLLATE' => 'DEFAULT COLLATE',
                'DEFAULT COLLATE' => sub {
                    return parse_table_option1($lx, $r, 'DEFAULT COLLATE', \&parse_collate);
                },

                'AUTO_INCREMENT' => sub {
                    return parse_table_option1($lx, $r, 'AUTO_INCREMENT', \&parse_expr);
                },

                'COMMENT' => sub {
                    return parse_table_option1($lx, $r, 'COMMENT', \&parse_expr);
                },
            )
        :   ()
        ),

        'ON COMMIT' => sub {
            return parse_table_option1($lx, $r, 'ON COMMIT', \&parse_on_commit_action);
        },

        'interpolTableOption' => 'interpol',
        'interpol' => sub {
            $r->{type}= 'interpol';
            $r->{token}= $lx->{token};
            lexer_shift($lx);
            while (looking_at($lx, ',', SHIFT)) {} # optional ,
            return $r;
        },
    );
    return unless $r;
    return if $lx->{error};
    lock_hash %$r;
    return $r;
}

sub parse_column_def($)
{
    my ($lx)= @_;
    my $r= create($lx, 'ColumnDef', qw(name column_spec));
    return unless
        $r->{name}=        parse_column_name($lx)
    and $r->{column_spec}= parse_column_spec($lx);
    lock_hash %$r;
    return $r;
}

sub parse_column_def_or_option($)
{
    my ($lx)= @_;
    return parse_choice($lx,
        'interpol' => 'ident',
        'ident' => sub {
            return parse_column_def($lx);
        },
        -default => sub {
            return parse_table_constraint($lx);
        },
    );
}

sub parse_create_table($)
{
    my ($lx)= @_;
    return unless
        expect($lx, \@CREATE_TABLE_INITIAL);

    my $r= create($lx, ['Stmt','CreateTable'],
                  qw(subtype if_not_exists table column_def tabconstr tableopt select));
    $r->{subtype}= lexer_shift($lx);

    if ($read_dialect{mysql} &&
        looking_at($lx, 'IF NOT EXISTS', SHIFT))
    {
        $r->{if_not_exists}= 1;
    }

    return unless
        $r->{table}= parse_table($lx);

    $r->{column_def}= [];
    $r->{tabconstr}=  [];
    if (looking_at($lx, '(')) {
        return unless
            my $spec= parse_list_delim($lx, \&parse_column_def_or_option);

        $r->{column_def}= [ grep { $_->{kind} eq 'ColumnDef' } @$spec ];
        $r->{tabconstr}=  [ grep { $_->{kind} ne 'ColumnDef' } @$spec ];
    }

    return unless
        $r->{tableopt}= parse_try_list([], $lx, \&parse_table_option);

    if (looking_at($lx, 'AS', SHIFT) ||
        looking_at($lx, \@SELECT_INITIAL))
    {
        return unless
            $r->{select}= parse_select($lx);
    }

    unless (scalar(@{ $r->{column_def} }) || $r->{select}) {
        $lx->{error}= 'Either query or at least one column expected';
        return;
    }

    lock_hash %$r;
    return $r;
}

sub parse_drop_table($)
{
    my ($lx)= @_;
    return unless
        expect($lx, \@DROP_TABLE_INITIAL);

    my $r= create($lx, ['Stmt','DropTable'],
                  qw(subtype if_exists table cascade));
    $r->{subtype}= lexer_shift($lx);

    if ($read_dialect{mysql} &&
        looking_at($lx, 'IF EXISTS', SHIFT))
    {
        $r->{if_exists}= 1;
    }

    return unless
        $r->{table}= parse_list([], $lx, \&parse_table, ',');

    $r->{cascade}= looking_at($lx, ['RESTRICT','CASCADE'], SHIFT);

    lock_hash %$r;
    return $r;
}

sub parse_column_pos_perhaps($)
{
    my ($lx)= @_;
    return parse_choice($lx,
        -default => sub {
            return;
        },
        'FIRST' => sub {
            return lexer_shift($lx);
        },
        'AFTER' => sub {
            lexer_shift($lx);
            return ('AFTER', parse_column_name($lx));
        },
    );
}

sub parse_alter_table($)
{
    my ($lx)= @_;
    return unless
        expect($lx, \@ALTER_TABLE_INITIAL);

    my $r= create($lx, ['Stmt','AlterTable'],
                  qw(subtype functor subfunctor arg online ignore table only));
    $r->{subtype}= lexer_shift($lx);
    $r->{arg}=     [];

    return unless
        $r->{table}= parse_table($lx);

    $r->{only}= looking_at($lx, 'ONLY', SHIFT);

    parse_choice($lx,
        'DROP CONSTRAINT' => sub {
            $r->{functor}= lexer_shift($lx);
            return unless
                my $constraint= parse_constraint($lx);
            push @{ $r->{arg} }, $constraint, looking_at($lx, ['RESTRICT','CASCADE'], SHIFT);
        },

        'DROP COLUMN' => sub {
            $r->{functor}= lexer_shift($lx);
            return unless
                my $column= parse_column_name($lx);
            push @{ $r->{arg} }, $column, looking_at($lx, ['RESTRICT','CASCADE'], SHIFT);
        },

        'RENAME COLUMN' => sub {
            $r->{functor}= lexer_shift($lx);

            return unless
                my $column= parse_column_name($lx)
            and expect($lx, 'TO', SHIFT)
            and my $column2= parse_column_name($lx);

            push @{ $r->{arg} }, $column, 'TO', $column2;
        },

        'DROP PRIMARY KEY' => sub {
            $r->{functor}= lexer_shift($lx);
        },

        'ALTER COLUMN' => sub {
            $r->{functor}= lexer_shift($lx);
            push @{ $r->{arg} }, parse_column_name($lx);
            return if $lx->{error};

            parse_choice($lx,
                'DROP DEFAULT'  => 'SET NOT NULL',
                'DROP NOT NULL' => 'SET NOT NULL',
                'SET NOT NULL'  => sub {
                    push @{ $r->{arg} }, lexer_shift($lx);
                },

                'SET DEFAULT' => sub {
                    push @{ $r->{arg} }, lexer_shift($lx);
                    push @{ $r->{arg} }, parse_expr($lx);
                },

                ($read_dialect{postgresql} ?
                    (
                        'TYPE' => sub {
                            push @{ $r->{arg} }, lexer_shift($lx);
                            push @{ $r->{arg} }, parse_type($lx);
                            return if $lx->{error};
                            if (my $x= looking_at($lx, 'USING', SHIFT)) {
                                push @{ $r->{arg} }, $x, parse_expr($lx);
                            }
                        }
                    )
                :   ()
                ),
            );
        },

        'RENAME TO' => sub {
            $r->{functor}= lexer_shift($lx);
            push @{ $r->{arg} }, parse_table($lx);
        },

        'ADD COLUMN' => sub {
            $r->{functor}= lexer_shift($lx);
            if (looking_at($lx, '(', SHIFT)) {
                push @{ $r->{arg} }, parse_list([], $lx, \&parse_column_def, ',');
                return if $lx->{error};
                expect($lx, ')', SHIFT);
            }
            else {
                return unless
                    my $col1= parse_column_name($lx)
                and my $spec= parse_column_spec($lx);
                push @{ $r->{arg} }, $col1, $spec, parse_column_pos_perhaps($lx);
            }
        },

        'ADD' => sub {
            $r->{functor}= lexer_shift($lx);
            push @{ $r->{arg} }, parse_table_constraint($lx);
        },

        ($read_dialect{mysql} ?
            (
                'MODIFY COLUMN' => sub {
                    $r->{functor}= lexer_shift($lx);
                    return unless
                        my $col1= parse_column_name($lx)
                    and my $spec= parse_column_spec($lx);
                    push @{ $r->{arg} }, $col1, $spec, parse_column_pos_perhaps($lx);
                },
                'CHANGE COLUMN' => sub {
                    $r->{functor}= lexer_shift($lx);
                    return unless
                        my $col1= parse_column_name($lx)
                    and my $col2= parse_column_name($lx)
                    and my $spec= parse_column_spec($lx);
                    push @{ $r->{arg} }, $col1, $col2, $spec, parse_column_pos_perhaps($lx);
                },
                'DROP FOREIGN KEY' => sub { # standard SQL: DROP CONSTRAINT
                    $r->{functor}= lexer_shift($lx);
                    return unless
                        my $constraint= parse_constraint($lx);
                    push @{ $r->{arg} }, $constraint;
                },
                'DROP INDEX' => sub {
                    $r->{functor}= lexer_shift($lx);
                    return unless
                        my $index= parse_index($lx);
                    push @{ $r->{arg} }, $index;
                },
            )
        :   ()
        ),
    );
    return if $lx->{error};

    lock_hash %$r;
    return $r;
}

sub parse_stmt_interpol($)
{
    my ($lx)= @_;

    # Some interpols will never be good statements, so issue an error as early
    # as possible (i.e., at compile time instead of at runtime):
    if ($lx->{token}{type} eq 'num' ||
        $lx->{token}{type} eq 'string')
    {
        $lx->{error}= "Expected 'Stmt', but found $lx->{token}{type}";
        return;
    }

    if (! $lx->{token}{type}) {
        $lx->{error}= "Expected 'Stmt', but found $lx->{token}{kind}";
        return;
    }

    if ($lx->{token}{perltype} eq 'hash') {
        $lx->{error}= "Expected scalar or array, but found $lx->{token}{perltype}.";
        return;
    }

    # But some may be:
    my $r= create ($lx, ['Stmt','Interpol'], qw(token));
    $r->{token}= $lx->{token};
    lexer_shift($lx);

    lock_hash %$r;
    return $r;
}

sub parse_select_stmt($)
{
    my ($lx)= @_;
    return parse_choice($lx,
        'SELECT'   => sub { parse_select ($lx) },

        'interpolStmt' => 'interpol',
        'interpol' => sub { parse_stmt_interpol ($lx) },
    );
}

sub parse_stmt($)
{
    my ($lx)= @_;
    return parse_choice($lx,
        'SELECT'   => sub { parse_select ($lx) },
        'INSERT'   => sub { parse_insert ($lx) },
        'UPDATE'   => sub { parse_update ($lx) },
        'DELETE'   => sub { parse_delete ($lx) },

        (map { $_ => 'CREATE TABLE' } @CREATE_TABLE_INITIAL),
        'CREATE TABLE' => sub { parse_create_table($lx) },

        (map { $_ => 'DROP TABLE' } @DROP_TABLE_INITIAL),
        'DROP TABLE' => sub { parse_drop_table($lx) },

        (map { $_ => 'ALTER TABLE' } @ALTER_TABLE_INITIAL),
        'ALTER TABLE' => sub { parse_alter_table($lx) },

        'interpolStmt' => 'interpol',
        'interpol' => sub { parse_stmt_interpol ($lx) },
    );
}

######################################################################
# Perl generation:


## First: creating a list of strings.
#
# The str_ family implements a simple concatenator for strings.  The goal
# is to generate a list of literal strings and Perl code generating strings,
# separated by commas.  For appending such things to the list, there is
# str_append_str() and str_append_perl(), resp.  E.g.:
#
#    my $s= str_new();
#    str_append_str  ($s, "a");
#    str_append_perl ($s, "b");
#
# This would result in the following string:
#
#    'a',b
#
# Appending the comma separator is done automatically.
#
# Further, we need to keep track of the line number.  So there is a function
# str_target_line() for setting the target line number for the next string
# or raw perl code that is appended.  Appending the necessary newline
# characters is done automatically by the str_ functions.
#
# Finally, we need to generate substrings by joining them.  This is done
# with the str_append_join() and str_append_end() functions.  E.g.
#
#    my $s= str_new();
#    str_append_str  ($s, 'a');
#    str_append_join ($s, sep => ':');
#    str_append_perl ($s, 'b');
#    str_target_line ($s, 2);
#    str_append_str  ($s, 'c');
#    str_append_end  ($s);
#    str_append_perl ($s, 'd');
#
# This results in the following string in $s:
#
#    'a',join(':',b,
#    'c'),d
#
# Another possible sub-list structure is a map, which can be added with
# str_append_map() ... str_append_en() functions.  E.g.:
#
#    str_append_str  ($s, 'a');
#    str_append_map  ($s, '$_." DESC"');
#    str_append_perl ($s, 'b');
#    str_append_str  ($s, 'c');
#    str_append_end  ($s);
#    str_append_perl ($s, 'd');
#
# This results in:
#
#    'a',(map{$_." DESC"} b,'c'),d
#
# A str_append_min1() ... str_append_end() block checks that there
# is at least one result in the enclosed list.  This, together with
# _max1_if_scalar, are slightly inefficient and should later be eliminated
# if possible.
#
# str_get_string() returns the current string as composed so far.  If the
# string is empty, an empty list () is returned instead, because the
# empty string is not a valid syntactic empty list in Perl, so it causes
# problems, e.g. after map:
#
#     (map {...} -->HERE<--)
#
# If we insert an empty string -->HERE<--, then we get a syntax error.
#
# The implementation of the str_ family is very straightforward: we have a
# current state that is updated and a string that is appended to accordingly.
sub str_new($)
{
    my ($line_start)= @_;
    my $text= [];
    my $s= {
        buff        => '',
        need_comma  => 0,
        line_is     => 1,
        line_target => 1,
        line_start  => $line_start,
        end_str     => [],  # final str to push, if defined
    };
    lock_keys %$s; # poor-man's bless()
    return $s;
}

sub str_append_raw($$)
{
    my ($s, $text)= @_;
    $s->{buff}.= $text;
    $s->{line_is}+= ($text =~ tr/\n//);
}

sub str_sync_line($)
{
    my ($s)= @_;
    while ($s->{line_is} < $s->{line_target}) {
        str_append_raw ($s, "\n");
    }
}
sub str_target_line($$)
{
    my ($s, $n)= @_;
    my_confess "undefined line number" unless defined $n;
    $s->{line_target}= $n;
}

sub str_append_comma($)
{
    my ($s)= @_;
    if ($s->{need_comma}) {
        str_append_raw ($s, COMMA_STR);
        $s->{need_comma}= 0;
    }
}

sub str_append_perl($$)
{
    my ($s, $perl)= @_;
    if ($perl ne '') {
        str_append_comma($s);
        str_sync_line ($s);
        str_append_raw ($s, $perl);
        $s->{need_comma}= 1;
    }
}

sub str_append_str($$)
{
    my ($s, $contents)= @_;
    str_append_perl ($s, quote_perl($contents));
}

sub str_append_join($%)
{
    my ($s, %opt)= @_;
    $opt{prefix}||=  '';
    $opt{suffix}||=  '';
    $opt{sep}||=     '';

    str_append_comma($s);
    str_sync_line  ($s);
    if ($opt{joinfunc}) {
        # special case: ignore all other settings
        str_append_raw ($s, "$opt{joinfunc}(");
        $s->{need_comma}= 0;
        push @{ $s->{end_str} }, undef;
    }
    elsif ($opt{prefix} eq '' &&
           $opt{suffix} eq '' &&
           (
               $opt{never_empty} ||
               (defined $opt{result0} && $opt{result0} eq '')
           ))
    {
        # simple case 1
        str_append_raw ($s, 'join(');
        str_append_str ($s, $opt{sep});
        $s->{need_comma}= 1;
        push @{ $s->{end_str} }, undef;
    }
    elsif ($opt{sep} eq '' &&
           (
               $opt{never_empty} ||
               (defined $opt{result0} && $opt{result0} eq $opt{prefix}.$opt{suffix})
           ))
    {
        # simple case 2
        str_append_raw ($s, 'join(');
        str_append_str ($s, '');

        if($opt{prefix} ne '') {
            str_append_str ($s, $opt{prefix});
        }

        push @{ $s->{end_str} }, $opt{suffix} || undef;
    }
    else {
        # complex case:
        str_append_raw ($s, __PACKAGE__.'::joinlist(');
        str_append_perl ($s, $s->{line_target} + $s->{line_start});
            # Unfortunately, Perl's caller() is often imprecise for the
            # generated code, and I couldn't find a cause for that to avoid
            # that.  So the original line number is passed long for
            # nicer error messages if necessary.
        str_append_comma($s);
        str_append_str ($s,  $opt{result0});
        str_append_comma($s);
        str_append_str ($s,  $opt{prefix});
        str_append_comma($s);
        str_append_str ($s,  $opt{sep});
        str_append_comma($s);
        str_append_str ($s,  $opt{suffix});
        $s->{need_comma}= 1;
        push @{ $s->{end_str} }, undef;
    }
}

sub str_append_map($$)
{
    my ($s,$code)= @_;
    str_append_comma($s);
    str_sync_line  ($s);
    str_append_raw ($s, "(map{ $code } ");
    $s->{need_comma}= 0;
    push @{ $s->{end_str} }, undef;
}

sub str_append_funcall_begin($$$)
{
    my ($s, $func, $in_list)= @_;
    str_append_comma($s);
    str_sync_line  ($s);
    if ($in_list) {
        str_append_raw ($s, "(map { $func(");
    }
    else {
        str_append_raw ($s, "$func(");
    }
    $s->{need_comma}= 0;
    push @{ $s->{end_str} }, undef;
}

sub str_append_funcall_end($$)
{
    my ($s, $in_list)= @_;
    if ($in_list) {
        str_append_perl ($s, '$_');
        str_append_raw ($s, ') }');
        $s->{need_comma}= 0;
    }
}

sub str_append_funcall($$$)
{
    my ($s, $code, $in_list)= @_;
    str_append_funcall_begin ($s, $code, $in_list);
    str_append_funcall_end   ($s, $in_list);
}

sub str_append_end($)
# Terminator for:
#   str_append_map
#   str_append_funcall
#   str_append_join
{
    my ($s)= @_;
    my $end_str= pop @{ $s->{end_str} };
    if (defined $end_str) {
        str_append_str($s, $end_str);
    }
    str_append_raw ($s, ')');
    $s->{need_comma}= 1;
}

sub str_get_string($)
{
    my ($s)= @_;
    return '()' if $s->{buff} eq '';
    return $s->{buff};
}

# Now start appending more complex things:

sub str_append_thing($$$$);

sub str_append_list($$$;%)
# If you know the list is non-empty, please specify never_empty => 1
# so str_append_join() can optimise.
{
    my ($str, $list, $parens, %opt)= @_;
    local $SIG{__DIE__}= \&my_confess;

    # set line to first element (if any):
    if (scalar(@$list)) {
        str_target_line ($str, $list->[0]{line});
    }

    # joining, delimiters, result if empty:
    str_append_join($str,
        sep      => defined $opt{sep} ? $opt{sep} : COMMA_STR,  # waiting for Perl 5.10: //
        prefix   => $opt{prefix},
        suffix   => $opt{suffix},
        result0  => $opt{result0},
    );

    # map?
    if (my $x= $opt{map}) {
        str_append_comma ($str);
        str_sync_line    ($str);
        str_append_raw   ($str, "map{$x} ");
        $str->{need_comma}= 0;
    };

    # the list:
    for my $l (@$list) {
        str_append_thing ($str, $l, IN_LIST, $parens);
    }

    # end:
    str_append_end($str);
}

sub interpol_set_context ($$);

sub perl_val($$$)
{
    my ($token, $ctxt, $allow)= @_;

    my_confess "Expected ".(english_or \&quote_perl, $allow).", but found '$token->{kind}'"
        if $allow &&
           scalar(grep { $token->{kind} eq $_ } flatten($allow)) == 0;

    return switch($token->{kind},
        'ident'    => sub { quote_perl($token->{value}) },
        '*'        => sub { __PACKAGE__.'::ASTERISK'    },
        '?'        => sub { __PACKAGE__.'::QUESTION'    },
        'NULL'     => sub { __PACKAGE__.'::NULL'        },
        'TRUE'     => sub { __PACKAGE__.'::TRUE'        },
        'FALSE'    => sub { __PACKAGE__.'::FALSE'       },
        'UNKNOWN'  => sub { __PACKAGE__.'::UNKNOWN'     },
        'DEFAULT'  => sub { __PACKAGE__.'::DEFAULT'     },
        -default => sub {
            if ($token->{kind} =~ /^interpol/) {
                return interpol_set_context ($token->{value}, $ctxt);
            }
            else {
                my_confess "No idea how to print thing in Perl: ".token_describe($token);
            }
        }
    );
}

sub perl_val_list($$$)
{
    my ($token, $ctxt, $allow)= @_;
    my $s= perl_val($token, $ctxt, $allow);

    if ($token->{perltype} eq 'hash') {
        return "sort keys $s";
    }
    else {
        return $s;
    }
}

sub token_pos($)
{
    my ($token)= @_;
    return "$token->{lx}{file}:".($token->{line} + $token->{lx}{line_start});
}

sub lx_pos($)
{
    my ($lx)= @_;
    return "$lx->{file}:".($lx->{line} + $lx->{line_start});
}

sub croak_unless_scalar($)
{
    my ($token)= @_;
    die token_pos($token).": ".
        "Error: Scalar context, embedded Perl must not be syntactic array or hash.\n"
        if $token->{perltype} eq 'array' || $token->{perltype} eq 'hash';
}

sub str_append_typed($$$$$%)
{
    my ($str, $callback, $ctxt, $thing, $in_list, %opt)= @_;
    my $q_val= perl_val ($thing->{token}, $ctxt, undef);

    if (!$in_list ||
        $thing->{token}{perltype} eq 'scalar')
    {
        croak_unless_scalar ($thing->{token});
        str_append_perl ($str, __PACKAGE__."::${callback}($q_val)");
    }
    elsif ($thing->{token}{perltype} eq 'hash') {
        if ($opt{hash}) {
            str_append_perl ($str, __PACKAGE__."::${callback}_hash($q_val)");
        }
        elsif ($opt{hashkeys}) {
            str_append_map  ($str, __PACKAGE__."::${callback}(\$_)");
            str_append_perl ($str, "sort keys $q_val");
            str_append_end  ($str);
        }
        else {
            die token_pos($thing->{token}).": Error: Hashes are not allowed here.\n";
        }
    }
    else {
        str_append_map  ($str, __PACKAGE__."::${callback}(\$_)");
        str_append_perl ($str, $q_val);
        str_append_end  ($str);
    }
}

sub is_multicol($);
sub is_multicol($)
{
    my ($thing) = @_;
    return switch ($thing->{kind},
        'ExprAs' => sub{
            return is_multicol($thing->{expr});
        },
        'Expr' => sub {
            if ($thing->{type} eq 'column') {
                return is_multicol($thing->{arg});
            }
            return 0;
        },
        'Column' => sub {
            return is_multicol($thing->{ident_chain}[-1]);
        },
        '*' => sub {
            return 1;
        },
        'interpol' => sub {
            return $thing->{perltype} ne 'scalar';
        },
        -default => sub {
            return 0;
        },
    );
}

# Contexts for the different sql{...} interpolation blocks:
my %ident_context= (
    'Column' => {
        1 => [ 'Column' ],
        2 => [ 'Table', 'none' ],
    },
);

sub str_append_ident_chain($$$@)
{
    my ($str, $in_list, $family, @token)= @_;
    my $func= lc($family);

    my $ctxt= $ident_context{$family}{scalar @token} ||
              (scalar(@token) == 1 ?
                  [ $family ]
              :   [ map 'none', 1..scalar(@token) ]
              );

    my $n= scalar(@token);
    my @non_scalar_i= grep { $token[$_]{perltype} ne 'scalar' } 0..$n-1;

    if (!$in_list ||
        scalar(@non_scalar_i) == 0)
    {
        for my $a (@token) { croak_unless_scalar ($a); }
        my $q_vals= join(",",
                        map
                        { perl_val($token[$_], $ctxt->[$_], undef) }
                        0..$n-1
                    );
        str_append_perl ($str, __PACKAGE__."::${func}${n}($q_vals)");
    }
    elsif (scalar(@non_scalar_i) == 1) {
        str_append_map ($str,
            __PACKAGE__."::${func}${n}(".
                join(",",
                    map {
                        ($token[$_]{perltype} eq 'scalar' ?
                            perl_val($token[$_], $ctxt->[$_], undef)
                        :   '$_'
                        )
                    }
                    0..$n-1
                ).
            ")"
        );
        my ($i)= @non_scalar_i;
        str_append_perl ($str, perl_val_list($token[$i], $ctxt->[$i], undef));
        str_append_end  ($str);
    }
    else {
        my $f_ident= "${func}${n}_".join('', map{ $_->{perltype} eq 'scalar' ? 1 : 'n' } @token);
        str_append_perl ($str,
            __PACKAGE__."::$f_ident(".
                join(",",
                    map {
                        ($token[$_]{perltype} eq 'scalar' ?
                            perl_val($token[$_], $ctxt->[$_], undef)
                        :   '['.perl_val_list($token[$_], $ctxt->[$_], undef).']'
                        )
                    }
                    0..$n-1
                ).
            ")"
        );
    }
}

sub str_append_limit ($$$)
{
    my ($str, $limit_cnt, $limit_offset)= @_;

    if (defined $limit_cnt || defined $limit_offset) {
        my $limit_cnt_str= 'undef';
        if ($limit_cnt) {
            $limit_cnt_str= perl_val($limit_cnt, 'Expr', ['interpol', 'interpolExpr', '?']);
        }

        my $limit_offset_str= 'undef';
        if ($limit_offset) {
            $limit_offset_str= perl_val($limit_offset, 'Expr', ['interpol', 'interpolExpr', '?']);
        }

        str_append_perl ($str, __PACKAGE__."::limit($limit_cnt_str, $limit_offset_str)");
    }
}

sub str_append_parens($$$)
{
    my ($str, $thing, $in_list)= @_;
    if ($in_list) {
        str_append_map ($str, "\"(\$_)\"");
        str_append_thing ($str, $thing, $in_list, NO_PARENS);
        str_append_end ($str);
    }
    else {
        str_append_join  ($str, prefix => '(', suffix => ')', never_empty => 1);
        str_append_thing ($str, $thing, $in_list, NO_PARENS);
        str_append_end   ($str);
    }
}

sub str_append_table_key($$$)
{
    my ($str, $thing, $type)= @_;
    str_append_join ($str, sep => ' ');
    if (my $x= $thing->{constraint}) {
        str_append_str   ($str, 'CONSTRAINT');
        str_append_thing ($str, $x, NOT_IN_LIST, NO_PARENS);
    }
    str_append_str  ($str, $type);
    if (my $x= $thing->{index_type}) {
        str_append_str ($str, "USING $x");
    }
    str_append_list ($str, $thing->{column}, NO_PARENS, prefix=>'(', suffix=>')');
    for my $o (@{ $thing->{index_option} }) {
        str_append_thing ($str, $o, IN_LIST, NO_PARENS);
    }
    if (my $x= $thing->{reference}) {
        str_append_thing ($str, $x, NOT_IN_LIST, NO_PARENS);
    }
    str_append_end ($str);
}

# str_append_thing() converts a recursive representation of the parsed SQL
# structure into a Perl string that generates a list of either string
# representations of the SQL structure (in good SQL syntax), or blessed
# objects of the correct type.
#
# The result of this function is then used to wrap and bless the string
# or objects appropriately according to which kind of SQL structure the
# string contains (statement, expressions, column, etc.).
#
# In detail, str_append_thing() appends pieces of Perl code to $str, that
# each represent a small piece of the SQL command.
#
# Each invocation of str_append_thing appends code to $str that generates
# exactly the amount of objects that are represented.  This might seem
# obvious, but since $str is actually a comma separated list, this
# requirement means that if multiple pieces are pushed for a single
# thing, then a join(...) must enclose and group these.  E.g.
# the code that generates a SELECT statement from scratch appends
# several pieces of code to $str, and to make only one string, a
# join() is generated.
#
sub str_append_thing($$$$)
{
    my ($str, $thing, $in_list, $parens)= @_;
    local $SIG{__DIE__}= \&my_confess;

    # simple things to append:
    unless (defined $thing) {
        str_append_perl ($str, 'undef');
        return;
    }
    unless (ref $thing) {
        str_append_str ($str, $thing);
        return;
    }
    if (ref($thing) eq 'ARRAY') {
        str_append_list ($str, $thing, NO_PARENS, prefix => '(', suffix => ')');
        return;
    }

    # normal structure:
    str_target_line ($str, $thing->{line});

    switch($thing->{kind},
        'Stmt' => sub {
            switch($thing->{type},
                'Select' => sub {
                    # find out type name depending on number of columns:
                    my $type_name = 'SelectStmt';
                    if (scalar(@{ $thing->{expr_list} }) == 1) {
                        unless (is_multicol($thing->{expr_list}[0])) {
                            $type_name = 'SelectStmtSingle';
                        }
                    }

                    # generate:
                    str_append_funcall ($str, __PACKAGE__.'::'.$type_name.'->obj', $in_list);
                    str_append_join ($str, never_empty => 1);

                    str_append_list ($str, $thing->{expr_list}, NO_PARENS,
                        prefix => join(' ', 'SELECT',
                                            @{ $thing->{opt_front} }
                                  ).' '
                    );

                    if (my $x= $thing->{from}) {
                        str_append_list ($str, $x, NO_PARENS, prefix => ' FROM ');

                        if (my $x= $thing->{join}) {
                            if (@$x) {
                                str_append_map ($str, '" $_" ');
                                for my $xi (@$x) {
                                    str_append_thing ($str, $xi, IN_LIST, NO_PARENS);
                                }
                                str_append_end ($str);
                            }
                        }
                        if (my $x= $thing->{where}) {
                            str_target_line ($str, $x->{line});
                            str_append_str   ($str, ' WHERE ');
                            str_append_thing ($str, $x, NOT_IN_LIST, NO_PARENS);
                        }
                        if (my $x= $thing->{group_by}) {
                            my $suffix= '';
                            if ($thing->{group_by_with_rollup}) {
                                $suffix= ' WITH ROLLUP';
                            }
                            str_append_list ($str, $x, NO_PARENS,
                                prefix  => ' GROUP BY ',
                                suffix  => $suffix,
                                result0 => '',
                            );
                        }
                        if (my $x= $thing->{having}) {
                            str_target_line ($str, $x->{line});
                            str_append_str   ($str, ' HAVING ');
                            str_append_thing ($str, $x, NOT_IN_LIST, NO_PARENS);
                        }
                        if (my $x= $thing->{order_by}) {
                            str_append_list ($str, $x, NO_PARENS,
                                prefix  => ' ORDER BY ',
                                result0 => ''
                            );
                        }
                        str_append_limit ($str, $thing->{limit_cnt}, $thing->{limit_offset});

                        str_append_str ($str, join('', map " $_", @{ $thing->{opt_back} }));
                    }

                    str_append_end ($str);
                    str_append_end ($str);
                },
                'Delete' => sub {
                    str_append_funcall ($str, __PACKAGE__.'::Stmt->obj', $in_list);
                    str_append_join ($str, never_empty => 1);

                    str_append_list ($str, $thing->{from}, NO_PARENS,
                        prefix =>
                            join(' ',
                                'DELETE',
                                @{ $thing->{opt_front} },
                                'FROM',
                                @{ $thing->{from_opt_front} },
                            ).' '
                    );

                    if (my $x= $thing->{using}) {
                        str_append_list ($str, $x, NO_PARENS,
                            prefix => ' USING ',
                            result0 => ''
                        );
                    }

                    if (my $x= $thing->{join}) {
                        if (@$x) {
                            str_append_map ($str, '" $_" ');
                            for my $xi (@$x) {
                                str_append_thing ($str, $xi, IN_LIST, NO_PARENS);
                            }
                            str_append_end ($str);
                        }
                    }
                    if (my $x= $thing->{where}) {
                        str_target_line ($str, $x->{line});
                        str_append_str   ($str, ' WHERE ');
                        str_append_thing ($str, $x, NOT_IN_LIST, NO_PARENS);
                    }
                    if (my $x= $thing->{order_by}) {
                        str_append_list ($str, $x, NO_PARENS,
                            prefix  => ' ORDER BY ',
                            result0 => ''
                        );
                    }
                    str_append_limit ($str, $thing->{limit_cnt}, $thing->{limit_offset});

                    str_append_end ($str);
                    str_append_end ($str);
                },
                'Insert' => sub {
                    str_append_funcall ($str, __PACKAGE__.'::Stmt->obj', $in_list);
                    str_append_join ($str, never_empty => 1);

                    str_append_str ($str,
                        join(' ',
                            'INSERT',
                            @{ $thing->{opt_front} },
                            'INTO',
                        ).' '
                    );

                    str_append_thing ($str, $thing->{into}, NOT_IN_LIST, NO_PARENS);

                    if (my $col= $thing->{column}) {
                        str_append_list ($str, $col, NO_PARENS, prefix => ' (', suffix => ')');
                    }
                                                
                    if (my $val= $thing->{value}) {
                        str_append_str  ($str, ' VALUES ');
                        str_append_list ($str, $val, NO_PARENS);
                    }
                    elsif (my $set= $thing->{set}) {
                        str_append_funcall ($str, __PACKAGE__."::set2values", NOT_IN_LIST);
                        for my $l (@$set) {
                            str_append_thing ($str, $l, IN_LIST, NO_PARENS);
                        }
                        str_append_end ($str);
                    }
                    elsif (my $sel= $thing->{select}) {
                        str_append_str   ($str, ' ');
                        str_append_thing ($str, $sel, NOT_IN_LIST, NO_PARENS);
                    }
                    elsif ($thing->{default_values}) {
                        str_append_str ($str, ' DEFAULT VALUES');
                    }
                    else {
                        die;
                    }

                    if (my $x= $thing->{duplicate_update}) {
                        str_append_str  ($str, ' ON DUPLICATE KEY UPDATE ');
                        str_append_list ($str, $x, NO_PARENS, map => __PACKAGE__.'::assign($_)');
                    }

                    str_append_end ($str);
                    str_append_end ($str);
                },
                'Update' => sub {
                    str_append_funcall ($str, __PACKAGE__.'::Stmt->obj', $in_list);
                    str_append_join ($str, never_empty => 1);

                    str_append_list ($str, $thing->{table}, NO_PARENS,
                        prefix => join(' ', 'UPDATE',
                                            @{ $thing->{opt_front} }
                                  ).' '
                    );

                    if (my $x= $thing->{from}) {
                        str_append_list ($str, $x, NO_PARENS,
                            prefix => ' FROM ',
                            result0 => ''
                        );
                    }
                    if (my $x= $thing->{join}) {
                        if (@$x) {
                            str_append_map ($str, '" $_" ');
                            for my $xi (@$x) {
                                str_append_thing ($str, $xi, IN_LIST, NO_PARENS);
                            }
                            str_append_end ($str);
                        }
                    }
                    if (my $x= $thing->{set}) {
                        str_append_list ($str, $x, NO_PARENS,
                            prefix => ' SET ',
                            result0 => ''  # this is an error.
                        );
                    }
                    if (my $x= $thing->{where}) {
                        str_target_line ($str, $x->{line});
                        str_append_str   ($str, ' WHERE ');
                        str_append_thing ($str, $x, NOT_IN_LIST, NO_PARENS);
                    }
                    if (my $x= $thing->{order_by}) {
                        str_append_list ($str, $x, NO_PARENS,
                            prefix  => ' ORDER BY ',
                            result0 => ''
                        );
                    }
                    str_append_limit ($str, $thing->{limit_cnt}, $thing->{limit_offset});

                    str_append_end ($str);
                    str_append_end ($str);
                },
                'CreateTable' => sub {
                    str_append_funcall ($str, __PACKAGE__.'::Stmt->obj', $in_list);
                    str_append_join ($str, never_empty => 1);

                    str_append_str ($str, "$thing->{subtype} ");
                    if ($thing->{if_not_exists}) {
                        str_append_str ($str, 'IF NOT EXISTS ');
                    }
                    str_append_thing ($str, $thing->{table}, NOT_IN_LIST, NO_PARENS);

                    my @tabspec= (
                        @{ $thing->{column_def} },
                        @{ $thing->{tabconstr} }
                    );
                    str_append_list ($str, \@tabspec, NO_PARENS,
                        result0 => '',
                        prefix  => ' (',
                        suffix  => ')'
                    );

                    str_append_list ($str, $thing->{tableopt}, NO_PARENS,
                        result0 => '',
                        prefix  => ' ',
                        sep     => ' ',
                    );

                    if (my $x= $thing->{select}) {
                        str_append_str   ($str, ' AS ');
                        str_append_thing ($str, $x, NOT_IN_LIST, NO_PARENS);
                    }

                    str_append_end ($str);
                    str_append_end ($str);
                },
                'DropTable' => sub {
                    str_append_funcall ($str, __PACKAGE__.'::Stmt->obj', $in_list);
                    str_append_join ($str, never_empty => 1);

                    str_append_str ($str, "$thing->{subtype} ");
                    if ($thing->{if_exists}) {
                        str_append_str ($str, 'IF EXISTS ');
                    }
                    str_append_list ($str, $thing->{table}, NO_PARENS);

                    if (my $x= $thing->{cascade}) {
                        str_append_str ($str, " $x");
                    }
                    str_append_end ($str);
                    str_append_end ($str);
                },
                'AlterTable' => sub {
                    str_append_funcall ($str, __PACKAGE__.'::Stmt->obj', $in_list);
                    str_append_join ($str, never_empty => 1);

                    str_append_str ($str, "$thing->{subtype} ");
                    if ($thing->{only}) {
                        str_append_str ($str, 'ONLY ');
                    }
                    str_append_thing ($str, $thing->{table}, NOT_IN_LIST, NO_PARENS);

                    str_append_join ($str, sep => ' ', prefix => ' ');
                    for my $l ($thing->{functor}, @{ $thing->{arg} }) {
                        str_append_thing ($str, $l, NOT_IN_LIST, NO_PARENS);
                    }
                    str_append_end ($str);

                    str_append_end ($str);
                    str_append_end ($str);
                },
                'Interpol' => sub {
                    str_append_typed ($str, 'stmt', 'Stmt', $thing, $in_list);
                },
            );
        },

        'TableOption' => sub {
            switch ($thing->{type},
               'interpol' => sub {
                    str_append_typed ($str, 'tableopt', 'TableOption', $thing, $in_list);
               },
               'literal' => sub {
                    str_append_join  ($str, sep => ' ');
                    str_append_str   ($str, $thing->{name});
                    str_append_thing ($str, $thing->{value}, NOT_IN_LIST, NO_PARENS);
                    str_append_end   ($str);
               }
            );
        },

        'Keyword' => sub {
            str_append_str ($str, $thing->{keyword});
        },

        'Join' => sub {
            if ($thing->{type} eq 'interpol') {
                str_append_typed ($str, 'joinclause', 'Join', $thing, $in_list);
            }
            else {
                str_append_join ($str, result0 => '');

                if ($thing->{natural}) {
                    if ($thing->{type} eq 'INNER') {
                        str_append_str ($str, "NATURAL JOIN ");
                    }
                    else {
                        str_append_str ($str, "NATURAL $thing->{type} JOIN ");
                    }
                }
                else {
                    str_append_str ($str, "$thing->{type} JOIN ");
                }

                str_append_list ($str, $thing->{table}, NO_PARENS);

                if (my $on= $thing->{on}) {
                    str_append_str ($str, ' ON ');
                    str_append_thing ($str, $on, NOT_IN_LIST, NO_PARENS);
                }
                elsif (my $using= $thing->{using}) {
                    str_append_str  ($str, ' USING (');
                    str_append_list ($str, $using, NO_PARENS);
                    str_append_str  ($str, ')');
                };

                str_append_end ($str);
            }
        },

        'Table' => 'Column',
        'CharSet' => 'Column',
        'Collate' => 'Column',
        'Index' => 'Column',
        'Constraint' => 'Column',
        'Transliteration' => 'Column',
        'Transcoding' => 'Column',
        'Engine' => 'Column',
        'Column' => sub {
            str_append_ident_chain ($str, $in_list, $thing->{kind}, @{ $thing->{ident_chain} });
        },

        'TableAs' => sub {
            if (my $x= $thing->{as}) {
                # Oracle does not allows AS in table aliases.  But this module
                # does not allow leaving it out.  To avoid generating what
                # this module cannot read back in the default case, check for
                # the write dialect.
                if ($write_dialect eq 'oracle') {
                    str_append_join  ($str, sep => ' ', never_empty => 1);
                }
                else {
                    str_append_join  ($str, sep => ' AS ', never_empty => 1);
                }
                str_append_thing ($str, $thing->{table}, NOT_IN_LIST, NO_PARENS);
                str_append_thing ($str, $x, NOT_IN_LIST, NO_PARENS);
                str_append_end   ($str);
            }
            else {
                str_append_thing ($str, $thing->{table}, $in_list, NO_PARENS);
            }
        },

        'ExprAs' => sub {
            if (my $x= $thing->{as}) {
                str_append_join  ($str, sep => ' AS ', never_empty => 1);
                str_append_thing ($str, $thing->{expr}, NOT_IN_LIST, NO_PARENS);
                str_append_thing ($str, $x, NOT_IN_LIST, NO_PARENS);
                str_append_end   ($str);
            }
            else {
                str_append_thing ($str, $thing->{expr}, $in_list, $parens);
            }
        },
        'Order' => sub {
            switch($thing->{type},
                'interpol' => sub {
                    if ($thing->{desc}) {
                        str_append_typed ($str, 'desc', 'Order', $thing, $in_list, hashkeys => 1);
                    }
                    else {
                        str_append_typed ($str, 'asc', 'Order', $thing, $in_list, hashkeys => 1);
                    }
                },
                'expr' => sub {
                    if ($thing->{desc}) {
                        str_append_map   ($str, __PACKAGE__.'::desc($_)');
                        str_append_thing ($str, $thing->{expr}, $in_list, NO_PARENS);
                        str_append_end   ($str);
                    }
                    else {
                        str_append_thing ($str, $thing->{expr}, $in_list, NO_PARENS);
                    }
                },
            );
        },
        'TypeList' => sub {
            switch($thing->{type},
                'interpol' => sub {
                    str_append_typed ($str, 'typelist', 'Type', $thing, $in_list);
                },

                'explicit' => sub {
                    str_append_list ($str, $thing->{arg}, NO_PARENS, prefix => '(', suffix => ')');
                        # may not be empty!
                },
            );
        },
        'Type' => sub {
            switch ($thing->{type},
                'interpol' => sub {
                    str_append_typed ($str, 'type', 'Type', $thing, $in_list);
                },
                'base' => sub {
                    str_append_perl ($str, __PACKAGE__.'::Type->new()');
                },
            );
        },
        'TypePost' => sub {
            return str_append_parens ($str, $thing, NOT_IN_LIST)
                if $parens;

            str_append_funcall_begin ($str, __PACKAGE__.'::type_'.$thing->{functor}, $in_list);
            for my $arg (@{ $thing->{arg} }) {
                str_append_thing ($str, $arg, NOT_IN_LIST, NO_PARENS);
            }
            str_append_funcall_end ($str, $in_list);
            str_append_thing ($str, $thing->{base}, $in_list, NO_PARENS);
            str_append_end ($str);
        },
        'ColumnDef' => sub {
            str_append_join  ($str, sep => ' ');
            str_append_thing ($str, $thing->{name},        NOT_IN_LIST, NO_PARENS);
            str_append_thing ($str, $thing->{column_spec}, NOT_IN_LIST, NO_PARENS);
            str_append_end   ($str);
        },

        'ColumnSpec' => sub {
            switch ($thing->{type},
                'interpol' => sub {
                    str_append_typed ($str, 'colspec', 'ColumnSpec', $thing, $in_list);
                },
                'base' => sub {
                    str_append_funcall ($str, __PACKAGE__.'::ColumnSpec->new', $in_list);
                    str_append_thing ($str, $thing->{datatype}, $in_list, NO_PARENS);
                    str_append_end ($str);
                }
            );
        },
        'ColumnSpecPost' => sub {
            return str_append_parens ($str, $thing, NOT_IN_LIST)
                if $parens;

            str_append_funcall_begin ($str, __PACKAGE__.'::colspec_'.$thing->{functor}, $in_list);
            for my $arg (@{ $thing->{arg} }) {
                str_append_thing ($str, $arg, NOT_IN_LIST, NO_PARENS);
            }
            str_append_funcall_end ($str, $in_list);
            str_append_thing ($str, $thing->{base}, $in_list, NO_PARENS);
            str_append_end ($str);
        },

        'TableConstraint' => sub {
            switch($thing->{type},
                'primary_key' => sub {
                    str_append_table_key ($str, $thing, 'PRIMARY KEY');
                },
                'unique' => sub {
                    str_append_table_key ($str, $thing, 'UNIQUE');
                },
                'fulltext' => sub {
                    str_append_table_key ($str, $thing, 'FULLTEXT');
                },
                'spatial' => sub {
                    str_append_table_key ($str, $thing, 'SPATIAL');
                },
                'index' => sub {
                    str_append_table_key ($str, $thing, 'INDEX');
                },
                'foreign_key' => sub {
                    str_append_table_key ($str, $thing, 'FOREIGN KEY');
                },
            );
        },

        'IndexOption' => sub {
            switch($thing->{type},
                'using' => sub {
                    str_append_str ($str, "USING $thing->{arg}");
                }
            );
        },

        'References' => sub {
            # table column match on_delete on_update));
            str_append_join  ($str, sep => ' ',
                prefix => 'REFERENCES ',
                suffix =>
                    join('', map { " $_" }
                        ($thing->{match} ?
                            ('MATCH', $thing->{match})
                        :   ()
                        ),
                        ($thing->{on_delete} ?
                            ('ON DELETE', $thing->{on_delete})
                        :   ()
                        ),
                        ($thing->{on_update} ?
                            ('ON UPDATE', $thing->{on_update})
                        :   ()
                        ),
                    )
            );
            str_append_thing ($str, $thing->{table}, NOT_IN_LIST, NO_PARENS);
            str_append_list  ($str, $thing->{column}, NO_PARENS,
                 prefix => '(', suffix => ')', result0 => '');
            str_append_end   ($str);
        },

        'CharUnit' => sub {
            str_append_str ($str, $thing->{name});
        },

        'ExprList' => sub {
            switch($thing->{type},
                'interpol' => sub {
                    str_append_typed ($str, 'exprlist', 'Expr', $thing, $in_list);
                },

                'explicit' => sub {
                    str_append_list ($str, $thing->{arg}, NO_PARENS, prefix => '(', suffix => ')');
                        # may not be empty!
                },
            );
        },
        'ExprEmpty' => sub {
            # Append an empty string.  Must have an operand here, otherwise
            # parameters might get mixed up.
            str_append_str($str, '');
        },
        'Check' => sub {
            str_append_join  ($str, joinfunc => __PACKAGE__.'::Check->obj');
            str_append_thing ($str, $thing->{expr}, NOT_IN_LIST, NO_PARENS);
            str_append_end   ($str);
        },
        'Expr' => sub {
            switch($thing->{type},
                'limit' => sub {
                    my $limit_cnt_str= perl_val($thing->{arg}, 'Expr',
                                             ['interpol', 'interpolExpr', '?']);
                    str_append_perl ($str, __PACKAGE__."::limit_number($limit_cnt_str)");
                },
                'interpol' => sub {
                    my $func= $thing->{maybe_check} ?
                                   'expr_or_check'
                              : ($thing->{token}{type} eq 'num' ||
                                 $thing->{token}{type} eq 'string' ||
                                 !$parens) ?
                                   'expr'
                              :    'exprparen';
                    str_append_typed ($str, $func, 'Expr', $thing, $in_list, hash => 1);
                },
                'column' => sub {
                    str_append_thing ($str, $thing->{arg}, $in_list, NO_PARENS);
                },
                '()' => sub {
                    str_append_thing ($str, $thing->{arg}, $in_list, PARENS);
                },
                'subquery' => sub {
                    str_append_funcall ($str, __PACKAGE__.'::subquery', $in_list);
                    str_append_thing ($str, $thing->{arg}, $in_list, NO_PARENS);
                    str_append_end   ($str);
                },
                'prefix1' => sub {
                    $in_list= NOT_IN_LIST; # just to be sure
                    return str_append_parens ($str, $thing, NOT_IN_LIST)
                        if $parens;
                    die 'Expected exactly 1 argument' unless scalar(@{ $thing->{arg} }) == 1;

                    str_append_join ($str,
                        prefix => "$thing->{functor}{value} ",
                        never_empty => 1
                    );
                    str_append_thing ($str, $thing->{arg}[0], NOT_IN_LIST, PARENS);
                    str_append_end ($str);
                },
                'prefixn' => sub {
                    $parens= NO_PARENS; # just to be sure
                    die 'Expected exactly 1 argument' unless scalar(@{ $thing->{arg} }) == 1;

                    if ($in_list) {
                        str_append_map ($str, "'$thing->{functor}{value} '.(\$_)");
                    }
                    else {
                        str_append_join ($str,
                            prefix => "$thing->{functor}{value} ",
                            never_empty => 1
                        );
                    }
                    str_append_thing ($str, $thing->{arg}[0], $in_list, PARENS);
                    str_append_end ($str);
                },

                'infix2' => sub {
                    $in_list= NOT_IN_LIST; # just to be sure
                    return str_append_parens ($str, $thing, NOT_IN_LIST)
                        if $parens;

                    my $f= $thing->{functor};
                    str_append_join  ($str, joinfunc => __PACKAGE__.'::Infix->obj');
                    str_append_str   ($str, $thing->{functor}{value});
                    str_append_thing ($str, $thing->{arg}[0], NOT_IN_LIST, PARENS);
                    str_append_thing ($str, $thing->{arg}[1], NOT_IN_LIST, PARENS);
                    str_append_end   ($str);
                },

                'infix23' => 'infix3',
                'infix3' => sub {
                    $in_list= NOT_IN_LIST; # just to be sure
                    return str_append_parens ($str, $thing, NOT_IN_LIST)
                        if $parens;

                    my $f= $thing->{functor};
                    str_append_join  ($str, never_empty => 1);
                    str_append_thing ($str, $thing->{arg}[0], NOT_IN_LIST, PARENS);
                    str_append_str   ($str, " $thing->{functor}{value} ");
                    str_append_thing ($str, $thing->{arg}[1], NOT_IN_LIST, PARENS);
                    if (scalar(@{ $thing->{arg} }) == 3) {
                        str_append_str   ($str, " $thing->{functor}{value2} ");
                        str_append_thing ($str, $thing->{arg}[2], NOT_IN_LIST, PARENS);
                    }
                    str_append_end   ($str);
                },

                # prefix and suffix allow bitwise application:
                # Currently not supported via _prefix() and _suffix() helper
                # functions, but may be later.  (Needs only a little rewrite
                # here.  The helper functions don't need to be changed.)
                'prefix()' => 'prefix',
                'suffix' => 'prefix',
                'prefix' => sub {
                    if ($thing->{type} eq 'prefix()') { # for AND() and OR() as functors
                        $in_list = NOT_IN_LIST;
                    }
                    my $f= $thing->{functor};
                    my $fk= $functor_kind{$f->{type} || ''}
                            or die "Expected $thing->{type} to be mapped by \%functor_kind";
                    if ($in_list) {
                        my $qt= quote_perl($f->{value});
                        str_append_map ($str, __PACKAGE__."::_".$fk."($qt,".($parens?1:0).",\$_)");
                        for my $l (@{ $thing->{arg} }) {
                            str_append_thing ($str, $l, IN_LIST, PARENS);
                        }
                        str_append_end ($str);
                    }
                    else {
                        str_append_funcall($str, __PACKAGE__."::_".$fk, NOT_IN_LIST);
                        str_append_thing ($str, $f->{value}, IN_LIST, NO_PARENS);
                        str_append_thing ($str, $parens?1:0, IN_LIST, NO_PARENS);
                        for my $l (@{ $thing->{arg} }) {
                            str_append_thing ($str, $l, IN_LIST, PARENS);
                        }
                        str_append_end ($str);
                    }
                },

                # funcall and infix use args inline if they are in list context.
                # They are handled by _prefix() and _suffix() helper functions in order
                # to allow dialect conversion:
                'funcall' => 'infix()',
                'infix()' => sub {
                    $in_list= NOT_IN_LIST; # just to be sure
                    my $f= $thing->{functor};
                    my $fk= $functor_kind{$f->{type} || ''}
                            or die 'Expected $thing->{type} to be mapped by %functor_kind';

                    str_append_funcall($str, __PACKAGE__."::_".$fk, NOT_IN_LIST);
                    str_append_thing ($str, $f->{value}, IN_LIST, NO_PARENS);
                    str_append_thing ($str, $parens?1:0, IN_LIST, NO_PARENS);
                    for my $l (@{ $thing->{arg} }) {
                        str_append_thing ($str, $l, IN_LIST, PARENS);
                    }
                    str_append_end ($str);
                },

                'funcsep' => sub {
                    $in_list= NOT_IN_LIST; # just to be sure
                    str_append_join ($str, never_empty => 1, sep => ' ');
                    str_append_str  ($str, "$thing->{functor}{value}(");
                    for my $t (@{ $thing->{arg} }) {
                        str_append_thing ($str, $t, NOT_IN_LIST, NO_PARENS);
                    }
                    str_append_end  ($str);
                },

                'case' => sub {
                    $in_list= NOT_IN_LIST; # just to be sure

                    # FIXME (maybe): we add parens here, so if there are no
                    # when-then pairs at all and only the else part is printed,
                    # it will get parens, too, no matter what.  That's ok,
                    # since it's a non-standard, marginal special case.
                    return str_append_parens ($str, $thing, NOT_IN_LIST)
                        if $parens;

                    my $sw= $thing->{switchval};
                    if ($sw) {
                        str_append_funcall ($str, __PACKAGE__."::caseswitch", NOT_IN_LIST);
                        str_append_thing ($str, $sw, NOT_IN_LIST, NO_PARENS);
                    }
                    else {
                        str_append_funcall ($str, __PACKAGE__."::casecond", NOT_IN_LIST);
                    }

                    if (my $e= $thing->{otherwise}) {
                        str_append_thing ($str, $e, NOT_IN_LIST, NO_PARENS);
                    }
                    else {
                        str_append_str ($str, 'NULL');
                    }

                    for my $wh (@{ $thing->{arg} }) {
                        if (ref($wh) eq 'ARRAY') {
                            my ($when,$expr)= @$wh;
                            str_append_funcall ($str, __PACKAGE__.'::whenthen', NOT_IN_LIST);
                            str_append_thing ($str, $when, NOT_IN_LIST, NO_PARENS);
                            str_append_thing ($str, $expr, NOT_IN_LIST, NO_PARENS);
                            str_append_end ($str);
                        }
                        else {
                            die 'expected array';
                        }
                    }

                    str_append_end ($str);
                },
            );
        },

        'ColumnName' => sub {
            switch ($thing->{type},
                'interpol' => 'ident',
                'ident' => sub {
                    str_append_typed ($str, 'colname', 'none', $thing, $in_list, hashkeys => 1);
                }
            );
        },

        'ColumnIndex' => sub {
            if (defined $thing->{length} || $thing->{desc}) {
                str_append_join  ($str, sep => ' ');
                str_append_thing ($str, $thing->{name}, NOT_IN_LIST, NO_PARENS);
                if (defined $thing->{length}) {
                    str_append_join  ($str, prefix => '(', suffix => ')');
                    str_append_thing ($str, $thing->{length}, NOT_IN_LIST, NO_PARENS);
                    str_append_end   ($str);
                }
                if ($thing->{desc}) {
                    str_append_str ($str, 'DESC');
                }
                str_append_end   ($str);
            }
            else {
                str_append_thing ($str, $thing->{name}, $in_list, $parens);
            }
        },

        'TableName' => sub {
            switch ($thing->{type},
                'interpol' => 'ident',
                'ident' => sub {
                    str_append_typed ($str, 'tabname', 'none', $thing, $in_list, hashkeys => 1);
                }
            );
        },

        'Fetch' => 'Do',
        'Do' => sub {
            str_append_thing ($str, $thing->{stmt}, $in_list, $parens);
        },
    );
}

sub to_perl($$\@)
{
    my ($line_start, $kind, $things)= @_;
    my $str= str_new($line_start);
    for my $thing (@$things) {
        str_append_thing ($str, $thing, IN_LIST, NO_PARENS);
    }
    my $text= str_get_string($str);
    return "do{".__PACKAGE__."::_max1_if_scalar map{".__PACKAGE__."::${kind}->obj(\$_)} $text}",
}

######################################################################
# Top-level parser interface:

sub lx_die_perhaps($;$)
{
    my $lx= shift;

    # if a test value is given, check that it is defined:
    if (scalar(@_)) {
        my ($check_val)= @_;
        unless (defined $check_val) {
            $lx->{error}||= 'Unknown error';
        }
    }

    # if an error is set, then die:
    if ($lx->{error}) {
        die lx_pos($lx).": Error: $lx->{error}\n";
    }
}


sub parse_1_or_list($$$;$)
{
    my ($lx, $parse_elem, $list_sep, $end)= @_;
    my $r= parse_list([], $lx, $parse_elem, $list_sep, $end);
    lx_die_perhaps($lx, $r);
    return @$r;
}

sub parse_0_try_list($$)
{
    my ($lx, $parse_elem)= @_;
    my $r= parse_try_list([], $lx, $parse_elem);
    lx_die_perhaps($lx, $r);
    return @$r;
}

sub parse_stmt_list($)
{
    parse_1_or_list ($_[0], \&parse_stmt,  ';', ['}',')',']']);
}

sub parse_do_stmt($)
{
    my ($lx) = @_;
    map {
        my $stmt = $_;
        my $r = create($lx, 'Do', qw(stmt));
        $r->{stmt} = $stmt;
        $r;
    }
    parse_stmt_list($lx);
}

sub parse_fetch_stmt($)
{
    my ($lx) = @_;
    map {
        my $stmt = $_;
        my $r = create($lx, 'Fetch', qw(stmt));
        $r->{stmt} = $stmt;
        $r;
    }
    parse_stmt_list($lx);
}

my %top_parse= (
    # pure parse actions:
    'Stmt'            => \&parse_stmt_list,

    'Join'            => sub { parse_0_try_list($_[0], \&parse_join)                 },
    'TableOption'     => sub { parse_0_try_list($_[0], \&parse_table_option)         },

    'Expr'            => sub { parse_1_or_list ($_[0], \&parse_expr,            ',') },
    'Check'           => sub { parse_1_or_list ($_[0], \&parse_check,           ',') },
    'Type'            => sub { parse_1_or_list ($_[0], \&parse_type,            ',') },
    'Column'          => sub { parse_1_or_list ($_[0], \&parse_column,          ',') },
    'Table'           => sub { parse_1_or_list ($_[0], \&parse_table,           ',') },
    'Index'           => sub { parse_1_or_list ($_[0], \&parse_index,           ',') },
    'CharSet'         => sub { parse_1_or_list ($_[0], \&parse_charset,         ',') },
    'Collate'         => sub { parse_1_or_list ($_[0], \&parse_collate,         ',') },
    'Constraint'      => sub { parse_1_or_list ($_[0], \&parse_constraint,      ',') },
    'Transliteration' => sub { parse_1_or_list ($_[0], \&parse_transliteration, ',') },
    'Transcoding'     => sub { parse_1_or_list ($_[0], \&parse_transcoding,     ',') },
    'Order'           => sub { parse_1_or_list ($_[0], \&parse_order,           ',') },
    'ColumnSpec'      => sub { parse_1_or_list ($_[0], \&parse_column_spec,     ',') },

    # parse & execute actions:
    'Do'              => sub { parse_do_stmt   ($_[0]) },
    'Fetch'           => sub { parse_fetch_stmt($_[0]) },
);
my $top_parse_re=  '(?:'.join('|', sort { length($b) <=> length($a) } '',     keys %top_parse).')';
my $top_parse_re2= '(?:'.join('|', sort { length($b) <=> length($a) } 'none', keys %top_parse).')';

sub interpol_set_context ($$)
{
    my ($text, $ctxt)= @_;
    $text=~ s/(\Q${\SQL_MARK}\E$top_parse_re)(?::$top_parse_re2)?(\s*\{)/$1:$ctxt$2/gs;
    return $text;
}

sub good_interpol_type($)
{
    my ($type)= @_;
    return !!$top_parse{$type};
}

sub mark_sql()
{
    # Step 1:
    # This function will get the text without comments, strings, etc.,
    # and replace the initial SQL marking the start of SQL syntax by
    # our special SQL_MARK.  Then, the unprocessed text will be
    # processed by replace_sql().
    s/\b\Q$sql_marker\E($top_parse_re\s*\{)/${\SQL_MARK}$1/gs;

    # Step 2:
    # Unmark false positives.  The above finds false matches in
    # variables:
    #
    #    $sql{...}
    #
    # We cannot(?) do this in one go, as we'd need a variable-width
    # negative look-behind regexp, which Perl does not have.  This
    # is because there can be arbitrary white space between $ and
    # a variable name.
    s/([\$\@\%]\s*)\Q${\SQL_MARK}\E/$1$sql_marker/gs;

    # Note that there are still false positives, which are really hard
    # to find unless we start parsing Perl completely:
    #
    #   ${ sql{blah} }
}

sub parse($$)
{
    my ($kind, $str)= @_;
    my $lx= lexer_new ($str, "<string>", 0);
    my $func= $top_parse{$kind};
    return undef unless $func;
    return () if looking_at($lx, '<EOF>');
    my @thing= $func->($lx);
    expect($lx, '<EOF>', SHIFT);
    lx_die_perhaps ($lx);
    return to_perl(1, $kind, @thing);
}

sub replace_sql()
{
    my ($module, $file, $line)= caller(4); # find our from where we were invoked

    mark_sql();
    #print STDERR "DEBUG: BEFORE: $_\n";

    pos($_)= 0;
    REPLACEMENT: while (/(\Q${\SQL_MARK}\E($top_parse_re)(?::($top_parse_re2))?\s*\{)/gs) {
        # prepare lexer:
        my $ctxt=     $3 || 'Stmt';
        my $speckind= $2;
        my $kind=     $speckind || $ctxt;
        my $start=    pos($_) - length($1);
        my $prefix=   substr($_, 0, $start);
        my $line_rel= ($prefix =~ tr/\n//);
        my $lx=       lexer_new ($_, $file, $line + $line_rel);

        # select parser:
        my $func= $top_parse{$kind};
        unless ($func) {
            die "$file:".($line+$line_rel+1).
                  ": Error: Plain ${sql_marker}${speckind}{...} is illegal, because the ".
                  "surrounding block must not return an object.\n\tPlease use ".
                  (english_or map "${sql_marker}${_}{...}", keys %top_parse)." to disambiguate.\n";
            last REPLACEMENT;
        }

        # parse (including closing brace):
        my @thing= $func->($lx);
        expect ($lx, '}', SHIFT);
        lx_die_perhaps ($lx);

        my $end= $lx->{token}{pos};
        my_confess unless defined $end && $start < $end;

        # Make Perl code:
        # Represent the parse result as a list in Perl (if it's only
        # one element, the parens don't hurt).  Each thing is
        # handled individually by to_perl():
        my $perl= to_perl($line + $line_rel, $kind, @thing);

        # replace:
        print STDERR "$file:".($line+$line_rel+1).': DEBUG: '.__PACKAGE__." replacement: $perl\n"
            if $debug;

        my $old_text= substr($_, $start, $end-$start, $perl); # extract and replace text
            # pos($_) is now undef, which is ok, we will
            # rescan the text anyway.

        # Insert newlines at the end that have been dropped so that the line
        # count does not change and Perl's error messages are useful:
        my $line_cnt_old= ($old_text =~ tr/\n//);
        my $line_cnt_new= ($perl     =~ tr/\n//);
        my_confess "More newlines than before" #.": \n###\n$old_text\n###$perl\n###\n"
            if $line_cnt_new > $line_cnt_old;

        if (my $line_cnt_less= $line_cnt_old - $line_cnt_new) {
            substr($_, $start + length($perl), 0, "\n" x $line_cnt_less);
        }

        # rescan everything in order to recurse into embedded sql{...}:
        pos($_)= 0;
    }
    pos($_)= undef;

    #print STDERR "DEBUG: AFTER: $_\n";
};

FILTER_ONLY
    # code_no_comments => \&mark_sql,    # This is way to slow.
    all  => \&replace_sql;

######################################################################
# Functions used in generated code:

# Obj:
{
    package SQL::Yapp::Obj;

    use strict;
    use warnings;
    use Carp qw(croak);

    sub op($) { return ''; }

    ######################################################################
    # stringify: simply return second entry in array, the string:
    use overload '""' => 'value',
                 cmp  => sub { "$_[0]" cmp "$_[1]" };

    sub type_error($$)
    {
        my ($x, $want)= @_;
        my $r= ref($x);
        $r=~ s/^SQL::Yapp:://;
        croak "Error: Expected $want, but found ".$r;
    }

    sub asc($)              { $_[0]->type_error('Asc');             }
    sub assign($)           { $_[0]->type_error('assignment');      }
    sub charset($)          { $_[0]->type_error('CharSet');         }
    sub constraint($)       { $_[0]->type_error('Constraint');      }
    sub charset1($)         { $_[0]->type_error('CharSet');         }
    sub collate1($)         { $_[0]->type_error('Collate');         }
    sub colname($)          { $_[0]->type_error('ColumnName');      }
    sub colspec($)          { $_[0]->type_error('ColumnSpec');      }
    sub column1($)          { $_[0]->type_error('Column');          }
    sub column1_single($)   { $_[0]->type_error('Column');          }
    sub constraint1($)      { $_[0]->type_error('Constraint');      }
    sub desc($)             { $_[0]->type_error('Desc');            }
    sub engine1($)          { $_[0]->type_error('Engine');          }
    sub expr($)             { $_[0]->type_error('Expr');            }
    sub expr_or_check($)    { $_[0]->type_error('Expr or Check');   }
    sub check($)            { $_[0]->type_error('Check');           }
    sub exprparen($)        { $_[0]->type_error('Expr');            }
    sub index1($)           { $_[0]->type_error('Index');           }
    sub joinclause($)       { $_[0]->type_error('JOIN clause');     }
    sub limit_number($)     { $_[0]->type_error('number or ?');     }
    sub stmt($)             { $_[0]->type_error('Stmt');            }
    sub subquery($)         { $_[0]->type_error('subquery');        }
    sub table1($)           { $_[0]->type_error('Table');           }
    sub tabname($)          { $_[0]->type_error('TableName');       }
    sub tableopt($)         { $_[0]->type_error('TableOption');     }
    sub transcoding($)      { $_[0]->type_error('Transcoding');     }
    sub transliteration1($) { $_[0]->type_error('Transliteration'); }
    sub type($)             { $_[0]->type_error('Type');            }

    sub do($)               { $_[0]->type_error('Do');              }
    sub fetch($)            { $_[0]->type_error('Fetch');           }
}

# Obj1:
{
    package SQL::Yapp::Obj1;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj);
    use Scalar::Util qw(blessed);

    sub obj($$)
    {
        my ($class,$x)= @_;
        return $x
            if blessed($x) && $x->isa(__PACKAGE__);
        return bless([$x], $class);
    }

    sub value($) { return $_[0][0]; }
}

###############
# Asterisk:
{
    package SQL::Yapp::Asterisk;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj);

    sub obj($)
    {
        my ($class)= @_;
        return bless([], $class);
    }

    sub value($)          { return '*'; }

    sub column1($)        { return $_[0]; }
    sub column1_single($) { return $_[0]; }
    sub expr($)           { return $_[0]; }
    sub expr_or_check($)  { return $_[0]; }

    sub asterisk($)       { return $_[0]; }
}

# Question:
{
    package SQL::Yapp::Question;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj);

    sub obj($)
    {
        my ($class)= @_;
        return bless([], $class);
    }

    sub value($)         { return '?' }

    sub limit_number($)  { return $_[0]; }
    sub exprparen($)     { return $_[0]; }
    sub expr($)          { return $_[0]; }
    sub expr_or_check($) { return $_[0]; }
    sub asc($)           { return $_[0]; }
    sub desc($)          { return SQL::Yapp::Desc->obj($_[0]); }
}

# ExprSpecial:
{
    package SQL::Yapp::ExprSpecial;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);

    sub exprparen($)     { return $_[0]; }
    sub expr($)          { return $_[0]; }
    sub expr_or_check($) { return $_[0]; }
    sub asc($)           { return $_[0]; }
    sub desc($)          { return SQL::Yapp::Desc->obj($_[0]); }
}

# Stmt:
{
    package SQL::Yapp::Stmt;

    use strict;
    use warnings;
    use Carp qw(croak);
    use base qw(SQL::Yapp::Obj1);

    sub subquery($)      { $_[0]->type_error('SELECT statement'); }
    sub exprparen($)     { $_[0]->subquery(); }
    sub expr($)          { $_[0]->subquery(); }
    sub expr_or_check($) { $_[0]->subquery(); }

    sub stmt($)          { return $_[0]; }

    sub do($)
    {
        my ($stmt) = @_;
        my $dbh = SQL::Yapp::get_dbh();
        $dbh->do($stmt);
        return; # return no statements so that _max1_if_scalar is ok with void context
    }
}

# SelectStmt:
{
    package SQL::Yapp::SelectStmt;

    use strict;
    use warnings;
    use Carp qw(croak);
    use base qw(SQL::Yapp::Stmt);

    sub subquery($)      { return '('.($_[0]->value).')'; }

    sub fetch($)
    {
        my ($stmt) = @_;
        my $dbh = SQL::Yapp::get_dbh();
        my $sth = $dbh->prepare($stmt);
        my $aref = $dbh->selectall_arrayref($sth, { Slice => {} });
        return unless $aref;
        return @$aref;
    }
}

# SelectStmtSingle:
{
    package SQL::Yapp::SelectStmtSingle;

    use strict;
    use warnings;
    use Carp qw(croak);
    use base qw(SQL::Yapp::SelectStmt);

    sub fetch($)
    {
        my ($stmt) = @_;
        my $dbh = SQL::Yapp::get_dbh();
        my $sth = $dbh->prepare($stmt);
        return unless $sth->execute;
        my @r= ();
        while (my $a= $sth->fetchrow_arrayref) {
            die unless scalar(@$a) == 1;
            push @r, $a->[0];
        }
        return @r;
    }
}

# Do:
# This is a bit different, since the obj() method will actually execute the statement.
{
    package SQL::Yapp::Do;

    use strict;
    use warnings;
    use Carp qw(confess);

    sub obj($$)
    {
        my ($class, $stmt) = @_;
        return $stmt->do;
    }
}

# Fetch:
# This is a bit different, since the obj() method will actually execute the statement.
{
    package SQL::Yapp::Fetch;

    use strict;
    use warnings;

    sub obj($$)
    {
        my ($class, $stmt) = @_;
        return $stmt->fetch;
    }
}

# ColumnName:
{
    package SQL::Yapp::ColumnName;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);

    sub colname($) { return $_[0]; }
}

# TableName:
{
    package SQL::Yapp::TableName;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);

    sub tabname($) { return $_[0]; }
}

# Column:
{
    package SQL::Yapp::Column;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);

    sub column1($)       { return $_[0]; }
    sub exprparen($)     { return $_[0]; }
    sub expr($)          { return $_[0]; }
    sub expr_or_check($) { return $_[0]; }
    sub asc($)           { return $_[0]; }
    sub desc($)          { return SQL::Yapp::Desc->obj($_[0]); }
}

# Table:
{
    package SQL::Yapp::Table;
    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);
    sub table1($) { return $_[0]; }
}

# CharSet:
{
    package SQL::Yapp::CharSet;
    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);
    sub charset1($) { return $_[0]; }
}

# Collate:
{
    package SQL::Yapp::Collate;
    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);
    sub collate1($) { return $_[0]; }
}

# Constraint:
{
    package SQL::Yapp::Constraint;
    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);
    sub constraint1($) { return $_[0]; }
}

# Index:
{
    package SQL::Yapp::Index;
    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);
    sub index1($) { return $_[0]; }
}

# Transliteration:
{
    package SQL::Yapp::Transliteration;
    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);
    sub transliteration($) { return $_[0]; }
}

# Transcoding:
{
    package SQL::Yapp::Transcoding;
    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);
    sub transcoding($) { return $_[0]; }
}

# TableOption:
{
    package SQL::Yapp::TableOption;
    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);
    sub tableopt($) { return $_[0]; }
}

# Engine:
{
    package SQL::Yapp::Engine;
    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);
    sub engine1($) { return $_[0]; }
}


# Join:
{
    package SQL::Yapp::Join;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);

    sub joinclause($) { return $_[0]; }
}

# Check:
{
    package SQL::Yapp::Check;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);

    sub check($)         { return $_[0]; }
    sub expr_or_check($) { return $_[0]; }

    sub obj($$)
    {
        if (ref($_[1]) eq $_[0]) {
            return $_[1];
        }
        elsif (ref($_[1])) {
            bless($_[1], $_[0]);
        }
        else {
            $_[0]->SUPER::obj($_[1]);
        }
    }
}

# Expr:
{
    package SQL::Yapp::Expr;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);

    sub exprparen($)     { return '('.($_[0]->value).')'; }
    sub expr($)          { return $_[0]; }
    sub expr_or_check($) { return $_[0]; }
    sub asc($)           { return $_[0]; }
    sub desc($)          { return SQL::Yapp::Desc->obj($_[0]); }
}

# Infix:
{
    package SQL::Yapp::Infix;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Expr);
    use Carp qw(croak);

    sub obj($$$$)
    {
        my ($class, $op, $a1, $a2)= @_;
        return bless(["$a1 $op $a2", $op, $a1, $a2], $class);
    }

    sub op($)     { return $_[0][1]; }
    sub arg1($)   { return $_[0][2]; }
    sub arg2($)   { return $_[0][3]; }

    sub assign($)
    {
        my ($self)= @_;
        if ($self->op() eq '=') { # we're not checking everything, just whether it's an assignment
            return $self;
        }
        croak "Assignment expected, but found top-level operator '".($self->op)."'.";
    }
}

# Order:
{
    package SQL::Yapp::Order;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj1);
    use Scalar::Util qw(blessed);

    sub obj($$)
    {
        my ($class,$x)= @_;
        return $x
            if blessed($x) && $x->isa('SQL::Yapp::Obj');
        return bless([$x], 'SQL::Yapp::Asc'); # not Order, but Asc.
    }
}

# Asc:
{
    package SQL::Yapp::Asc;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Order);

    sub asc($)  { return $_[0]; }
    sub desc($) { return SQL::Yapp::Desc->obj($_[0]); }
}

# Desc:
{
    package SQL::Yapp::Desc;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Order);

    sub obj($$)
    {
        my ($class, $orig)= @_;
        return bless(["$orig DESC",$orig],$class);
    }

    sub orig($) { return $_[0][1]; }

    sub asc($)  { return $_[0]; }
    sub desc($) { return &orig; }
}

# Type:
{
    package SQL::Yapp::Type;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj);
    use Hash::Util qw(lock_keys);
    use Carp qw(croak);

    sub set_base($$$)
    {
        my ($self, $base, $spec)= @_;

        # set new spec:
        $self->{base}= $base;
        $self->{spec}= $spec;

        # filter options by new spec:
        for my $o (keys %{ $self->{option} }) {
            unless ($spec->{$o}) {
                delete $self->{option}{$o};
            }
        }

        return $self;
    }

    sub set_property($$$)
    {
        my ($self, $key, $value)= @_;
        my %a= %$self;
        croak "No $key for $self->{base} allowed." unless $self->{spec}{$key};
        $self->{option}{$key}= $value;
        return $self;
    }

    sub new($)
    {
        my $r= bless({ base => undef, spec => undef, option => {} }, $_[0]);
        lock_keys %$r;
        return $r;
    }

    sub obj($$)
    {
        return $_[1];
    }

    sub clone($)
    {
        my ($self)= @_;
        my $r= bless({
                   %$self,
                   # no need to make a deep copy of 'spec', because it is never changed.
                   option => { %{ $self->{option} } },
               }, __PACKAGE__);
        lock_keys %$r;
        return $r;
    }

    sub type($)
    {
        return $_[0]->clone(); # make a copy before trying to modify this
    }

    sub colspec($)
    {
        return SQL::Yapp::ColumnSpec->new($_[0]); # make a copy producing a ColumnSpec
    }

    sub value($)
    {
        my ($self)= @_;
        return '<error: no base type>' unless $self->{base};
        my @r= ($self->{base});
        if ($self->{spec}{prec1} && defined $self->{option}{prec1}) {
            my $len_str= '';
            $len_str.= $self->{option}{prec1};
            if ($self->{spec}{prec2} && defined $self->{option}{prec2}) {
                $len_str.= ', '.$self->{option}{prec2};
            }
            else {
                if ($self->{spec}{prec_mul} && $self->{option}{prec_mul}) {
                    $len_str.= ' '.$self->{option}{prec_mul};
                }
                if ($self->{spec}{prec_unit} && $self->{option}{prec_unit}) {
                    $len_str.= ' '.$self->{option}{prec_unit};
                }
            }
            push @r, '('.$len_str.')';
        }
        if (my $value_list= $self->{spec}{value_list} && $self->{option}{value_list}) {
            push @r, '('.join(', ',@$value_list).')';
        }
        if (my $x= $self->{spec}{charset} && $self->{option}{charset}) {
            push @r, 'CHARACTER SET', $x;
        }
        if (my $x= $self->{spec}{collate} && $self->{option}{collate}) {
            push @r, 'COLLATE', $x;
        }
        for my $key ('sign', 'zerofill', 'timezone') {
            if (my $x= $self->{spec}{$key} && $self->{option}{$key}) {
                push @r, $x;
            }
        }

        return join(' ', @r);
    }
}


# ColumnSpec:
{
    package SQL::Yapp::ColumnSpec;

    use strict;
    use warnings;
    use base qw(SQL::Yapp::Obj);
    use Hash::Util qw(lock_keys);
    use Carp qw(croak);

    sub new($$)
    {
        my ($class, $type)= @_;
        my $r= bless({ datatype => $type->clone(), name => {}, option => {} }, $class);
        lock_keys %$r;
        return $r;
    }

    sub obj($$)
    {
        return $_[1];
    }

    sub clone($)
    {
        my ($self)= @_;
        my $r= bless({
                   datatype => $self->{datatype}->clone(),
                   name   => { %{ $self->{name}   } },
                   option => { %{ $self->{option} } },
               }, __PACKAGE__);
        lock_keys %$r;
        return $r;
    }

    sub colspec($)
    {
        return $_[0]->clone(); # make a copy before trying to modify this
    }

    sub name($$)
    {
        my ($self, $key)= @_;
        if (my $x= $self->{name}{$key}) {
            return ('CONSTRAINT', $x);
        }
        return;
    }

    sub value($)
    {
        my ($self)= @_;
        my @r= ($self->{datatype});

        for my $key ('notnull', 'autoinc', 'unique', 'primary', 'key') {
            if (my $x= $self->{option}{$key}) {
                push @r, $self->name($key), $x;
            }
        }

        for my $key ('default', 'column_format', 'storage') {
            if (my $x= $self->{option}{$key}) {
                push @r, $self->name($key), uc($key), $x;
            }
        }

        for my $key ('check') {
            if (my $x= $self->{option}{$key}) {
                push @r, $self->name($key), uc($key), '('.$x.')';
            }
        }

        for my $key ('references') {
            if (my $x= $self->{option}{$key}) {
                push @r, $self->name($key), $x;
            }
        }

        return join(' ', @r);
    }
}


# Special Constants:
sub ASTERISK { SQL::Yapp::Asterisk->obj(); }
sub QUESTION { SQL::Yapp::Question->obj(); }
sub NULL     { SQL::Yapp::ExprSpecial->obj('NULL'); }
sub TRUE     { SQL::Yapp::ExprSpecial->obj('TRUE'); }
sub FALSE    { SQL::Yapp::ExprSpecial->obj('FALSE'); }
sub UNKNOWN  { SQL::Yapp::ExprSpecial->obj('UNKNOWN'); }
sub DEFAULT  { SQL::Yapp::ExprSpecial->obj('DEFAULT'); }


# Wrapped DBI methods:
sub croak_no_ref($)
{
    my ($self)= @_;
    croak "Error: Wrong type argument from interpolated code:\n".
        "\tExpected scalar, but found ".my_dumper($self);
}

########################################
# Generators:

# These functions are used to typecheck interpolated Perl code's
# result values and to generate objects on the fly if that's possible.
# Usually on-the-fly generation coerces basic Perl types to a blessed
# object, but it would also be feasible to coerce objects to objects.
# Some 'generator' functions don't generate at all, but simply type
# check.
#
# Note: often these functions are invoked in string context, which
# means that directly after their invocation, the string cast operator
# is invoked.  However, there's no easy way to prevent object creation
# in that case, because there is no such thing as 'wantstring'
# (would-be analog to 'wantarray').  So these functions must always
# return a blessed reference.

sub _functor($$@)
{
    my ($functor, $parens, @arg)= @_;

    # possibly translate the functor to a different SQL dialect:
    if (my $dialect= $functor->{dialect}) {
        if (my $f2= find_ref(%$dialect, $write_dialect)) {
            $functor= $f2;
        }
    }

    # print it:
    my $name= $functor->{value};

    # prefix and suffix are not handled here, because they behave
    # differently: they assume exactly one argument are applied
    # point-wise.  They cannot be switched (ok, we might switch
    # between prefix and suffix, but that's not supported yet).
    my $s= switch ($functor->{type},
        'infix()' => sub {
            (scalar(@arg) ?
               join(" $name ", @arg)
            : defined($functor->{result0}) ?
               get_quote_val->($functor->{result0})
            :  die "Error: Functor $functor->{value} used with 0 args, but requires at least one."
            );
        },
        'funcall' => sub {
            $parens= 0;
            "$name(".join(", ", @arg).")";
        },
        'prefix' => sub {
            die "Error: Exactly one argument expected for operator $functor->{value},\n".
                "\tfound (".join(",", @arg).")"
                unless scalar(@arg) == 1;
            "$name $arg[0]"
        },
        'suffix' => sub {
            die "Error: exactly one argument expected, found @arg" unless scalar(@arg) == 1;
            "$arg[0] $name"
        },
    );
    return $parens ? "($s)" : $s;
}

sub _prefix($$@)
{
    my ($name, $parens)= splice @_,0,2;
    return _functor($functor_prefix{$name} || { value => $name, type => 'funcall' } , $parens, @_);
}

sub _suffix($$@)
{
    my ($name, $parens)= splice @_,0,2;
    return _functor($functor_suffix{$name}, $parens, @_);
}

sub _max1_if_scalar(@)
{
    # void context:
    unless (defined wantarray) {
        return if scalar(@_) == 0; # allow void context with no params (e.g. after Do)
        croak 'Error: NYI: void context is currently not supported for SQL blocks.';
    }

    # list context:
    return @_ if wantarray;

    # scalar context:
    croak 'Error: Multiple results cannot be assigned to scalar'
        if scalar(@_) > 1;
    return $_[0];
}

sub min1(@)
{
    croak 'Error: Expected at least one element, but found an empty list'
        if scalar(@_) == 0;
    return @_;
}

sub min1default($@)
{
    return @_ if scalar(@_) == 1;
    shift;
    return @_;
}

sub joinlist($$$$$@)
{
    if (scalar(@_) == 5) {
        return $_[1] if defined $_[1];
        my ($module, $file, $line)= caller;
        croak "$file:$_[0]: Error: Expected at least one element, but found an empty list";
    }
    return $_[2].join ($_[3], @_[5..$#_]).$_[4];
}

sub assign($) # check that the result is an assignment, i.e.:`a` = <expr>
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->assign();
    }
    else {
        croak "Assignment expected, but found non-reference.";
    }
}

sub set2values(@)
{
    croak "At least one value expected" if scalar(@_) == 0;
    return
        ' ('.
        join(',', map { assign($_)->arg1() } @_).
        ') VALUES ('.
        join(',', map { $_->arg2() } @_).
        ')';
}

sub exprlist($)
{
    my ($x)= @_;
    croak "Array reference expected for expression list"
       unless ref($x) eq 'ARRAY';
    croak "At least one element expected in expression list"
       unless scalar(@$x) >= 1;
    return '('.join(', ', map { expr($_) } @$x).')';
}

####################
# Type

sub type($)
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->type();
    }
    else {
        croak "Type expected, but found non-reference (user types are not supported yet).";
    }
}

# These have $self at the end because it's easier to generate code like that.
sub type_base($$)
{
    my $self= pop @_;
    my ($base)= @_;
    croak "Unrecognised base type '$base'" unless
        my $spec= find_ref(%type_spec, $base);
    die unless $self;
    return $self->set_base($base, $spec);
}

sub type_basewlist($@)
{
    my $self= pop @_;
    my ($base, @value)= @_;
    croak "Unrecognised base type '$base'" unless
        my $spec= find_ref(%type_spec, $base);
    die unless $self;
    $self->set_base($base, $spec);
    $self->set_property('value_list', \@value);
    return $self;
}

sub type_length($$;$)
{
    my $self= pop @_;
    my ($prec1, $prec2)= @_;
    $self->set_property('prec1', $prec1);
    $self->set_property('prec2', $prec2) if defined $prec2;
    return $self;
}

sub type_largelength($$$;$)
{
    my $self= pop @_;
    my ($coeff, $mul, $unit)= @_;
    $self->set_property('prec1',      $coeff);
    $self->set_property('prec_mul',   $mul)  if defined $mul;
    $self->set_property('prec_unit',  $unit) if defined $unit;
    return $self;
}

sub type_property($$$)
{
    my $self= pop @_;
    my ($key,$value)= @_;
    $self->set_property($key,$value);
    return $self;
}

####################
# ColumnSpec

sub colspec($)
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->colspec();
    }
    else {
        croak "ColumnSpec expected, but found non-reference (user types are not supported yet).";
    }
}

sub colspec_property($$$$)
{
    my $self= pop @_;
    my ($name, $key, $value)= @_;
    $self->{name}{$key}=   $name;
    $self->{option}{$key}= $value;
    return $self;
}

sub colspec_type_base($$)
{
    my $self= pop @_;
    my ($base)= @_;
    type_base($base, $self->{datatype});
    return $self;
}

sub colspec_type_property($$$)
{
    my $self= pop @_;
    my ($key, $value)= @_;
    type_property($key, $value, $self->{datatype});
    return $self;
}

sub colspec_type_basewlist($@)
{
    my $self= pop @_;
    my ($base, @value)= @_;
    type_basewlist($base, @value, $self->{datatype});
    return $self;
}

sub colspec_type_length($$;$)
{
    my $self= pop @_;
    my ($prec1, $prec2)= @_;
    type_length($prec1, $prec2, $self->{datatype});
    return $self;
}

sub colspec_type_largelength($$$;$)
{
    my $self= pop @_;
    my ($coeff, $mul, $unit)= @_;
    type_largelength($coeff, $mul, $unit, $self->{datatype});
    return $self;
}

####################
# identifier interpolation, column and table:

sub tabname($)
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->tabname;
    }
    elsif (defined $x) {
        return SQL::Yapp::TableName->obj(get_quote_id->($xlat_table->($x)));
    }
    else {
        croak "Error: Cannot use undef/NULL as a table name";
    }
}

# Schema-qualified names:
sub schemaname1($$$)
{
    my ($class,$xlat,$x)= @_;
    if (defined $x) {
        return $class->obj(get_quote_id->($xlat->($x)));
    }
    else {
        croak "Error: Cannot use undef/NULL as a table name";
    }
}

sub schemaname2($$$$)
{
    my ($class,$xlat,$x,$y)= @_;

    if (ref($x)) { croak_no_ref($x); }
    if (ref($y)) { croak_no_ref($y); }
    croak "Error: Cannot use undef/NULL as an identifier"
        unless defined $y;

    return $class->obj(
               get_quote_id->(
                   undef,
                   (defined $x ? $xlat_schema->($x) : undef),
                   $xlat->($y)));
}

sub schemaname3($$$$$)
{
    my ($class,$xlat,$x,$y,$z)= @_;
    if (ref($x)) { croak_no_ref($x); }
    if (ref($y)) { croak_no_ref($y); }
    if (ref($z)) { croak_no_ref($z); }
    croak "Error: Cannot use undef/NULL as an identifier"
        unless defined $z;

    return $class->obj(
               get_quote_id->(
                   (defined $x ? $xlat_catalog->($x) : undef),
                   (defined $y ? $xlat_schema->($y)  : undef),
                   $xlat->($z)));
}


# Table:
sub table1($)
{
    my ($x)= @_;
    return ref($x) ? $x->table1 : schemaname1('SQL::Yapp::Table', $xlat_table, $x);
}

sub table2($$)
{
    my ($x,$y)= @_;
    return schemaname2('SQL::Yapp::Table', $xlat_table, $x, $y);
}

sub table3($$$)
{
    my ($x,$y,$z)= @_;
    return schemaname3('SQL::Yapp::Table', $xlat_table, $x, $y, $z);
}


# Index:
sub index1($)
{
    my ($x)= @_;
    return ref($x) ? $x->index1 : schemaname1('SQL::Yapp::Index', $xlat_index, $x);
}

sub index2($$)
{
    my ($x,$y)= @_;
    return schemaname2('SQL::Yapp::Index', $xlat_index, $x, $y);
}

sub index3($$$)
{
    my ($x,$y,$z)= @_;
    return schemaname3('SQL::Yapp::Index', $xlat_index, $x, $y, $z);
}


# CharSet:
sub charset1($)
{
    my ($x)= @_;
    return ref($x) ? $x->charset1 : schemaname1('SQL::Yapp::CharSet', $xlat_charset, $x);
}

sub charset2($$)
{
    my ($x,$y)= @_;
    return schemaname2('SQL::Yapp::CharSet', $xlat_charset, $x, $y);
}

sub charset3($$$)
{
    my ($x,$y,$z)= @_;
    return schemaname3('SQL::Yapp::CharSet', $xlat_charset, $x, $y, $z);
}


# Collate:
sub collate1($)
{
    my ($x)= @_;
    return ref($x) ? $x->collate1 : schemaname1('SQL::Yapp::Collate', $xlat_collate, $x);
}

sub collate2($$)
{
    my ($x,$y)= @_;
    return schemaname2('SQL::Yapp::Collate', $xlat_collate, $x, $y);
}

sub collate3($$$)
{
    my ($x,$y,$z)= @_;
    return schemaname3('SQL::Yapp::Collate', $xlat_collate, $x, $y, $z);
}


# Constraint:
sub constraint1($)
{
    my ($x)= @_;
    return ref($x) ? $x->constraint1 : schemaname1('SQL::Yapp::Constraint', $xlat_constraint, $x);
}

sub constraint2($$)
{
    my ($x,$y)= @_;
    return schemaname2('SQL::Yapp::Constraint', $xlat_constraint, $x, $y);
}

sub constraint3($$$)
{
    my ($x,$y,$z)= @_;
    return schemaname3('SQL::Yapp::Constraint', $xlat_constraint, $x, $y, $z);
}


# Transliteration:
sub transliteration1($)
{
    my ($x)= @_;
    return ref($x) ? $x->transliteration1 : schemaname1('SQL::Yapp::Transliteration', $xlat_transliteration, $x);
}

sub transliteration2($$)
{
    my ($x,$y)= @_;
    return schemaname2('SQL::Yapp::Transliteration', $xlat_transliteration, $x, $y);
}

sub transliteration3($$$)
{
    my ($x,$y,$z)= @_;
    return schemaname3('SQL::Yapp::Transliteration', $xlat_transliteration, $x, $y, $z);
}


# Transcoding:
sub transcoding1($)
{
    my ($x)= @_;
    return ref($x) ? $x->transcoding1 : schemaname1('SQL::Yapp::Transcoding', $xlat_transcoding, $x);
}

sub transcoding2($$)
{
    my ($x,$y)= @_;
    return schemaname2('SQL::Yapp::Transcoding', $xlat_transcoding, $x, $y);
}

sub transcoding3($$$)
{
    my ($x,$y,$z)= @_;
    return schemaname3('SQL::Yapp::Transcoding', $xlat_transcoding, $x, $y, $z);
}


# Engine:
sub engine1($)
{
    my ($x)= @_;
    return ref($x) ? $x->engine1 : schemaname1('SQL::Yapp::Engine', $xlat_engine, $x);
}

sub engine2($$)
{
    my ($x,$y)= @_;
    return schemaname2('SQL::Yapp::Engine', $xlat_engine, $x, $y);
}

sub engine3($$$)
{
    my ($x,$y,$z)= @_;
    return schemaname3('SQL::Yapp::Engine', $xlat_engine, $x, $y, $z);
}


# Columns:
sub colname($)
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->colname;
    }
    elsif (defined $x) {
        return SQL::Yapp::ColumnName->obj(get_quote_id->($xlat_column->($x)));
    }
    else {
        croak "Error: Cannot use undef/NULL as a column name";
    }
}

sub column1($)
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->column1;
    }
    elsif (defined $x) {
        return SQL::Yapp::Column->obj(get_quote_id->($xlat_column->($x)));
    }
    else {
        croak "Error: Cannot use undef/NULL as an identifier";
    }
}

sub column1_single($) #internal
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->column1_single;
    }
    elsif (defined $x) {
        return get_quote_id->($xlat_column->($x));
    }
    else {
        croak "Error: Cannot use undef/NULL as an identifier";
    }
}

sub column2($$)
{
    my ($x,$y)= @_;
    return SQL::Yapp::Column->obj(table1($x).'.'.column1_single($y));
}

sub column3($$$)
{
    my ($x,$y,$z)= @_;
    return SQL::Yapp::Column->obj(table2($x,$y).'.'.column1_single($z));
}

sub column4($$$$)
{
    my ($w,$x,$y,$z)= @_;
    return SQL::Yapp::Column->obj(table3($w,$x,$y).'.'.column1_single($z));
}

# Generated with mkidentn.pl:
sub table1_n($)         { map { table1        ($_   )                       } @{ $_[0] }  }
sub table2_1n($$)       { map { table2        ($_[0], $_   )                } @{ $_[1] }  }
sub table2_n1($$)       { map { table2        ($_   , $_[1])                } @{ $_[0] }  }
sub table2_nn($$)       { map { table2_1n     ($_   , $_[1])                } @{ $_[0] }  }
sub table3_11n($$$)     { map { table3        ($_[0], $_[1], $_   )         } @{ $_[2] }  }
sub table3_1n1($$$)     { map { table3        ($_[0], $_   , $_[2])         } @{ $_[1] }  }
sub table3_1nn($$$)     { map { table3_11n    ($_[0], $_   , $_[2])         } @{ $_[1] }  }
sub table3_n11($$$)     { map { table3        ($_   , $_[1], $_[2])         } @{ $_[0] }  }
sub table3_n1n($$$)     { map { table3_11n    ($_   , $_[1], $_[2])         } @{ $_[0] }  }
sub table3_nn1($$$)     { map { table3_1n1    ($_   , $_[1], $_[2])         } @{ $_[0] }  }
sub table3_nnn($$$)     { map { table3_1nn    ($_   , $_[1], $_[2])         } @{ $_[0] }  }

sub column1_n($)        { map { column1       ($_   )                       } @{ $_[0] }  }
sub column2_1n($$)      { map { column2       ($_[0], $_   )                } @{ $_[1] }  }
sub column2_n1($$)      { map { column2       ($_   , $_[1])                } @{ $_[0] }  }
sub column2_nn($$)      { map { column2_1n    ($_   , $_[1])                } @{ $_[0] }  }
sub column3_11n($$$)    { map { column3       ($_[0], $_[1], $_   )         } @{ $_[2] }  }
sub column3_1n1($$$)    { map { column3       ($_[0], $_   , $_[2])         } @{ $_[1] }  }
sub column3_1nn($$$)    { map { column3_11n   ($_[0], $_   , $_[2])         } @{ $_[1] }  }
sub column3_n11($$$)    { map { column3       ($_   , $_[1], $_[2])         } @{ $_[0] }  }
sub column3_n1n($$$)    { map { column3_11n   ($_   , $_[1], $_[2])         } @{ $_[0] }  }
sub column3_nn1($$$)    { map { column3_1n1   ($_   , $_[1], $_[2])         } @{ $_[0] }  }
sub column3_nnn($$$)    { map { column3_1nn   ($_   , $_[1], $_[2])         } @{ $_[0] }  }
sub column4_111n($$$$)  { map { column4       ($_[0], $_[1], $_[2], $_   )  } @{ $_[3] }  }
sub column4_11n1($$$$)  { map { column4       ($_[0], $_[1], $_   , $_[3])  } @{ $_[2] }  }
sub column4_11nn($$$$)  { map { column4_111n  ($_[0], $_[1], $_   , $_[3])  } @{ $_[2] }  }
sub column4_1n11($$$$)  { map { column4       ($_[0], $_   , $_[2], $_[3])  } @{ $_[1] }  }
sub column4_1n1n($$$$)  { map { column4_111n  ($_[0], $_   , $_[2], $_[3])  } @{ $_[1] }  }
sub column4_1nn1($$$$)  { map { column4_11n1  ($_[0], $_   , $_[2], $_[3])  } @{ $_[1] }  }
sub column4_1nnn($$$$)  { map { column4_11nn  ($_[0], $_   , $_[2], $_[3])  } @{ $_[1] }  }
sub column4_n111($$$$)  { map { column4       ($_   , $_[1], $_[2], $_[3])  } @{ $_[0] }  }
sub column4_n11n($$$$)  { map { column4_111n  ($_   , $_[1], $_[2], $_[3])  } @{ $_[0] }  }
sub column4_n1n1($$$$)  { map { column4_11n1  ($_   , $_[1], $_[2], $_[3])  } @{ $_[0] }  }
sub column4_n1nn($$$$)  { map { column4_11nn  ($_   , $_[1], $_[2], $_[3])  } @{ $_[0] }  }
sub column4_nn11($$$$)  { map { column4_1n11  ($_   , $_[1], $_[2], $_[3])  } @{ $_[0] }  }
sub column4_nn1n($$$$)  { map { column4_1n1n  ($_   , $_[1], $_[2], $_[3])  } @{ $_[0] }  }
sub column4_nnn1($$$$)  { map { column4_1nn1  ($_   , $_[1], $_[2], $_[3])  } @{ $_[0] }  }
sub column4_nnnn($$$$)  { map { column4_1nnn  ($_   , $_[1], $_[2], $_[3])  } @{ $_[0] }  }

####################
# stmt interpolation:

sub stmt($)
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->stmt;
    }
    else {
        croak "Error: Expected 'Stmt' object, but found: ".my_dumper($x);
    }
}

sub subquery($)
{
    my ($x1)= @_;
    my $x= SQL::Yapp::Stmt->obj($x1);
    return $x->subquery;
}

####################
# expr interpolation:

sub exprparen($)
{
    my ($x)= @_;
    if (ref($x)) {
        die Dumper($x) if ref($x) eq 'HASH';
        die Dumper($x) if ref($x) eq 'ARRAY';
        die Dumper($x) if ref($x) eq 'CODE';
        die Dumper($x) if ref($x) eq 'SCALAR';
        return $x->exprparen;
    }
    else {
        return SQL::Yapp::Expr->obj(get_quote_val->($x)); # raw perl scalar: quote as value, no parens
    }
}

sub expr($)
{
    my ($x)= @_;
    if (ref($x)) {
        confess 'Error: Trying to invoke $x->expr() on unblessed reference $x ".
                "(maybe missing nested sqlExpr{...} inside a block, or ".
                "additional () around {} interpolation?)'
            unless blessed($x);
        return $x->expr;
    }
    else {
        return SQL::Yapp::Expr->obj(get_quote_val->($x)); # raw perl scalar: quote as value
    }
}

sub expr_or_check($)
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->expr_or_check;
    }
    else {
        return SQL::Yapp::Expr->obj(get_quote_val->($x)); # raw perl scalar: quote as value
    }
}

sub exprparen_hash(\%)
{
    my ($x)= @_;
    return map {
        my $n= $_;
        my $e= $x->{$n};
        (blessed($e) && $e->isa('SQL::Yapp::Check') ?
            '('.get_quote_id->($n).' '.$e->check.')'
        :   '('.get_quote_id->($n).' = '.exprparen($e).')'
        )
    }
    sort keys %$x;
}

sub expr_hash(\%)
{
    my ($x)= @_;
    return map {
        my $n= $_;
        my $e= $x->{$n};
        (blessed($e) && $e->isa('SQL::Yapp::Check') ?
            '('.get_quote_id->($n).' '.$e->check.')'
        :   SQL::Yapp::Infix->obj('=', get_quote_id->($n), exprparen($e))
        )
    }
    sort keys %$x;
}

####################
# order interpolation:

sub asc($)
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->asc;
    }
    elsif (defined $x) {
        return column1($x);
    }
    else {
        return NULL;
    }
}

sub desc($)
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->desc;
    }
    elsif (defined $x) {
        return SQL::Yapp::Desc->obj(column1($x));
    }
    else {
        return NULL;
    }
}

####################
# table option:

sub tableopt($)
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->tableopt;
    }
    else {
        croak "Error: Expected 'TableOption' object, but found: ".my_dumper($x);
    }
}

####################
# join interpolation:

sub joinclause($)
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->joinclause;
    }
    else {
        croak "Error: Expected 'Join' object, but found: ".my_dumper($x);
    }
}

####################
# limit interpolation:

sub limit_number($)
{
    my ($x)= @_;
    if (ref($x)) {
        return $x->limit_number;
    }
    elsif (looks_like_number $x) {
        return $x;
    }
    else {
        croak "Error: Expected number or ?, but found: ".my_dumper($x);
    }
}

sub limit($$)
{
    my ($cnt, $offset)= @_;

    # FIXME: if dialect is 'std' (or maybe 'std2008'), produce OFFSET/FETCH
    #        clause (SQL-2008).
    if (defined $cnt) {
        if (defined $offset) {
            return " LIMIT ".limit_number($cnt)." OFFSET ".limit_number($offset);
        }
        else {
            return " LIMIT ".limit_number($cnt);
        }
    }
    else {
        if (defined $offset) {
            if ($write_dialect eq 'postgresql') {
                return " LIMIT ALL OFFSET ".limit_number($offset);
            }
            else {
                return " LIMIT ${\LARGE_LIMIT_CNT} OFFSET ".limit_number($offset);
            }
        }
        else {
            return '';
        }
    }
}

####################
# case:

sub whenthen($$)
{
    my ($expr, $then)= @_;
    return 'WHEN '.$expr.' THEN '.$then;
}

sub caseswitch($$@)
{
   #my ($switchval, $default, @whenthen)
   if (scalar(@_) == 2) { # @whenthen is empty => always use default
       return $_[1];      # return default
   }
   return
      join(' ',
          'CASE',
          $_[0],
          @_[2..$#_],     # @whenthen
          'ELSE',         # always generate default, it's easier.
          $_[1],
          'END'
     );
}

sub casecond($@)
{
   #my ($default, @whenthen)
   if (scalar(@_) == 1) { # @whenthen is empty => always use default
       return $_[0];      # return default
   }
   return
      join(' ',
          'CASE',
          @_[1..$#_],     # @whenthen
          'ELSE',         # always generate default, it's easier.
          $_[0],
          'END'
     );
}

1;

######################################################################
######################################################################
######################################################################

__END__

=head1 NAME

SQL::Yapp - SQL syntax in Perl with compile-time syntax checks

=head1 SYNOPSIS

    use SQL::Yapp
        qw(
            dbh
            get_dbh
            quote
            quote_identifier
            check_identifier
            xlat_catalog
            xlat_scheme
            xlat_table
            xlat_column
            xlat_charset
            xlat_collate
            xlat_constraint
            xlat_index
            xlat_transcoding
            xlat_transliteration
            ASTERISK
            QUESTION
            NULL
            TRUE
            FALSE
            UNKNOWN
            DEFAULT
        ),
        marker => 'sql';

In the use clause, you usually pass a function returning a DBI handle:

    my $dbh;
    use SQL::Yapp dbh => sub { $dbh };

The handle must be initialised before any SQL expression
can be evaluated.  There are other ways to use the module, see
the chapter L<"Initialisation"> below.

    $dbh= DBI->connect(...);

You can use SQL syntax natively in Perl now, without worrying about
quotation or SQL injections.  The SQL objects can be used directly in
DBI calls:

    my $first_name = "Peter";
    my $dbq= $dbh->prepare(sql{
        SELECT surname FROM customer WHERE first_name = $first_name
    });
    $dbq->execute();

You can directly 'do' or 'prepare/execute/fetchall_hashref' with the
same syntax, as the module knows your DBI handle.  The previous code
does about the same as:

    my $first_name = "Peter";
    sqlDo{
        SELECT surname FROM customer WHERE first_name = $first_name
    };

The following code uses DBI:

    my $sth = $dbh->prepare(sql{ SELECT * FROM user });
    $sth->execute;
    my $res = $q->fetchall_arrayref($sth, {});
    for my $user (@$res) {
        ...
    }

This can be abbreviated to:

    for my $user (sqlFetch{ SELECT * FROM user }) {
        ...
    }                

The interpolated SQL looks much like a C<do{...}> block.  Depending on
context, different quotation for interpolated Perl strings is used.
Here's an example for a column name:

    my $column= 'surname';
    my $q= sql{
        SELECT customer.$column FROM customer WHERE first_name = 'John'
    };

Perl code can be used everywhere by using {...} inside SQL code:

    my $sur= 1;
    my @row= sqlFetch{
        SELECT .{ $sur ? 'surname' : 'first_name' } FROM customer
    };

Arrays of values are expanded in lists:

    my @val= ( 1, 2, 3 );
    my ($row)= sqlFetch{
        SELECT @val
    };

Arrays of column names are expanded in lists:

    my @col= ( 'surname', 'first_name' );
    my @row= sqlFetch{
        SELECT .@col FROM customer
    };

Table names, too:

    my @tab= ( 'friends', 'enemies' );
    my @row= sqlFetch{
        SELECT @tab.surname FROM @tab
    };

Even multiple expansion is possible:

    my @row= sqlFetch{
        SELECT @tab.@col FROM @tab
    };

Embedding is fully recursive: you can have SQL in Perl in SQL in Perl...

    my $dbq= $dbh->prepare(sql{
        SELECT surname FROM customer
        WHERE
           {$sur ?
               sql{ surname    LIKE '%foo%' }
           :   sql{ first_name LIKE '%bar%' }
           }
    });

SQL structures of different kinds can be parsed and stored in Perl
handles and used in other SQL structures:

    $expr= sqlExpr{         (b * 6) = COALESCE(c, d)        };
    $chk1= sqlCheck{        > 6                             };
    $chk2= sqlCheck{        IS NOT NULL                     };
    $tab=  sqlTable{        bar                             };
    $col=  sqlColumn{       $tab.name                       };
    $join= sqlJoin{         LEFT JOIN foo ON $col == foo.id };
    @ordr= sqlOrder{        a, b DESC                       };

    $stmt= sqlStmt{         SELECT $col
                            FROM $tab
                            Join $join
                            WHERE $expr
                            ORDER BY @ordr    };

    $type= sqlType{         INT(10) };
    $spec= sqlColumnSpec {  $type NOT NULL DEFAULT 17 };
    @to=   sqlTableOption{  ENGINE innodb
                            DEFAULT CHARACTER SET utf8
                         };
    $stm2= sqlStmt{         CREATE TABLE foo ( col1 $spec ) @to };

To parse a statement and then execute it and possibly fetch all rows,
there are additional forms.  For large queries, these may not be
suited; for small queries, they come in handy.  One form is to fetch,
one to simply execute:

Obvious single column fetches are returned as a list of scalars:

    my @name = sqlFetch{ SELECT name FROM user };

In particular, single column and single row selects work as expected:

    my $count = sqlFetch{ SELECT COUNT(*) FROM user };

Otherwise, a list of hashes is returned:

    my @result = sqlFetch{ SELECT * FROM user };

To simply execute, use:

    sqlDo{ DROP TABLE users };

Hash interpolation in SET clauses is supported:

    my %new_value= (
        first_name => 'John',
        surname    => 'Doe'
    );
    sqlDo{
        UPDATE customer SET %new_value
        WHERE age >= 18
    };

Array interpolation in SET clauses is also supported:

    my @new_value= (
        sqlExpr{ first_name = ?      },
        sqlExpr{ surname    = 'Doe'  }
    );
    sqlDo{
        UPDATE customer SET @new_value
        WHERE age >= 18
    };

=head1 DESCRIPTION

The purpose of this module is to provide a means to make SQL
injections totally impossible, and to provide an easy, native SQL
interface in Perl.  These two goals go hand in hand: by embedding a
full SQL parser in the Perl compiler, forcing proper quotation is
easy.

This package also provides basic compile-time syntax checking of SQL.

Currently, the major goals are security and ease of use, rather than
completeness or efficiency.  We'll add more SQL syntax over time to
make this more and more complete.  So for some things, you'll still
need the raw DBI interface.


=head2 Initialisation

This package needs a way to quote identifiers and values for proper
SQL output.  One way of providing this is by a DBI handle:

    my $dbh;
    use SQL::Yapp dbh => sub { $dbh };

In libraries, where you only what to parse SQL, you do not need to
specify the DBI handle, but you may simply use:

    use SQL::Yapp;

This enables the compile-time SQL parser for the given file.  You only
need to specify the the DBI handle if you want to stringify the parsed
SQL objects.  The SQL parser works without it.

You can set and change the link later, too:

    SQL::Yapp::dbh { $dbh };

The current DB handle can be queried using the C<get_dbh> function:

    my $dbh = SQL::Yapp::get_dbh()
    $dbh->prepare(...);

By settings a DBI handle, the library auto-implements the two required
quotation functions, one for values and one for identifiers.  Instead
of passing the DBI handle reference, you can alternatively implement
your own quotation functions:

    use SQL::Yapp;
    my $dbh;

    SQL::Yapp::quote            { $dbh->quote($_[0])         };
    SQL::Yapp::quote_identifier { $dbh->quote_identifier(@_) };

This make this package independent from the DBI module.  You can also
define these functions directly in the package invocation:

    my $dbh;
    use SQL::Yapp
       quote            => sub { $dbh->quote($_[0])         },
       quote_identifier => sub { $dbh->quote_identifier(@_) };

Additional to auto-setting the quote functions, setting the DB handle
enables the special execution forms C<sqlDo{...}> and
C<sqlFetch{...}>, which are only supported if the DB handle is set.

A fancy package option is 'marker', which defines to which string the
package reacts in your Perl script.  The default is 'sql', so sql{...}
encloses SQL blocks.  You might want to use something different:

    use SQL::Yapp marker => 'qqq';

Now, your SQL commands need to be embedded in qqq{...} instead.  The
prefix is used for other kinds of embedding, too, e.g. qqqExpr{...}.

You cannot dynamically change the marker, but only set it in the
package initialisation, because it is needed at compile time.

The following functions are importable from SQL::Yapp:

    dbh
    get_dbh
    quote
    quote_identifier
    check_identifier
    xlat_catalog
    xlat_schema
    xlat_table
    xlat_column
    xlat_charset
    xlat_collate
    xlat_constraint
    xlat_index
    xlat_transcoding
    xlat_transliteration

You may pass these names in the use clause to import them just like in
the initialisation of any other module:

    use SQL::Yapp qw(quote_identifier);

You may also mix this with initialisation described above:

    use SQL::Yapp qw(quote_identifier), marker => 'qqq';

All the exported functions get/set parameters of the library and their
values can be set in the use clause already just like in the above
examples.  The C<xlat_*> function family is described in Section
L<"Identifier Name Translation">.

The function C<check_identifier> is described in Section L<"Identifier Checking">.

Another set of initialisation options selects the accepted dialect
and the normalisation mode.  The options are:

    read_dialect  => [ 'dialect' , ... ],
    write_dialect => 'dialect',
    dialect       => 'dialect'

The C<dialect> option is an abbreviation for using C<read_dialect> and
C<write_dialect> with the same value.

The C<read_dialect> defines from which SQL dialect to accept
incompatible extensions (compatible extensions are always accepted and
normalised).

The C<write_dialect> defines for which dialect to produce output.
Note different quotation methods are automatically handled by the DBI
driver, so for that, no change to C<write_dialect> are necessary.  But
this option is about more non-trivial, additional syntax changes.
Currently the following dialects are known:

    'mysql'
    'postgresql'
    'oracle'
    'std'
    'generic'

C<'generic'> means to try to please everyone while C<'std'> means to
try to please no-one, i.e., to stick to the standard. :-)

The C<read_dialect> option must be given in initialisation, because
they must be known at compile time.  The C<write_dialect> option may
be set before SQL expressions are evaluated (and thus stringified into
SQL syntax).

For information, what normalisation is done, please refer to Section
L<"Normalisation">.

Finally, there's the C<debug> boolean option, which, when set to 1,
will dump the compiled code to STDERR.  This is for developers.

To summarise: the following configuration options exist:

    marker
    dbh
    quote
    quote_identifier
    check_identifier
    xlat_catalog
    xlat_schema
    xlat_table
    xlat_column
    xlat_charset
    xlat_collate
    xlat_constraint
    xlat_index
    xlat_transcoding
    xlat_transliteration
    catalog_prefix
    schema_prefix
    table_prefix
    column_prefix
    constraint_prefix
    read_dialect
    write_dialect
    dialect
    debug

For the C<_prefix> options, also see Section
L<"Identifier Name Translation">.

For programs that do not know in advance how to connect to SQL, it is
also infeasible to set dbh in the use clause.  The SQL
parser/preprocessor of the library still works, so you can do without
problems:

    use SQL::Yapp;

    sub get_select()
    {
        return sql{ SELECT * FROM mydb };
    }

Without setting the DB handle, the expressions the preprocessor
generates cannot be stringified and executed, because the library does
not know how to quote properly.


=head2 Basic Syntax and Usage

The embedded SQL syntax is based on normal SQL syntax, with
interpolations of Perl values made easy.  In Perl, an SQL expression
is enclosed in an sql{...} block, like so:

   my $query= sql{SELECT foo FROM bar};

The result is a list of blessed references, enclosed in a do{...}
block.

The above C<$query> automagically stringifies to SQL syntax when
embedded in a string, e.g.:

   "$query"

will return a string suitable for DBI interface.  So you can use
this with DBI as follows:

    my $dbq= $dbh->prepare(sql{SELECT foo FROM bar});

B<Note again>: the result of sql{...} is a I<list>.  So if you have
multiple statements in your sql{...} block, you get multiple results.
This way, the structure embeds nicely into Perl using Perl native
concepts:

    my @query= sql{SELECT foo FROM bar ; SELECT foz FROM baz};

In this example, C<@query> has 2 elements, each an SQL select
statement object.  It is effectively the same as:

    my @query= (sql{SELECT foo FROM bar}, sql{SELECT foz FROM baz});

In scalar context, it is B<wrong> to try to assign multiple values:

    my $query= sql{SELECT foo FROM bar ; SELECT foz FROM baz};
        # ERROR: cannot assign multiple results to scalar

The SQL::Yapp syntax is a bit different from standard SQL syntax.
The most important thing is that table and column names can only be
lower case, unless escaped with ``, and that keywords must be upper
case, and that all literal values and comments use Perl syntax instead
of SQL syntax.

As already mentioned, an C<sql{...}> block expands to a
C<do{...}> block.  This is important in some places and was mainly
implemented this way because of the similar look of C<sql{...}> and
C<do{...}>.  It has some consequences:

Firstly, you cannot directly index the result but must put parentheses
around the block do to that:

    my $second= (sqlExpr{ 1, 2, 3})[1];

Secondly, you can use C<sql{...}> in places where you might otherwise
get a surprising effect if we had used parentheses for enclosing, e.g.:

    my @q= map sql{ SELECT .$_ FROM tab }, @col;

With parens, C<map (...), @col> would produce a syntax error, but
C<map do{...}, @col> is fine.


=head2 Tokens

=over

=item UPPER_CASE

SQL keywords and function names:

    SELECT, FROM, MAX, SUM, ...

=item lower_case

Names: tables, columns, variables, you name it:

     client_address, surname, ...

=item CamelCase

Type names that may precede Perl interpolations to indicate the
intended item they store.  Usually, such a type is inferred from
context, but sometimes they are needed:

     SELECT Column $a FROM ...

=item Other Identifier

Any other identifier with mixed case (or no letters at all) will raise
a syntax error.

=item backquoted string: E<96>...E<96>

Quoted name, no escape characters allowed, may not contain newlines.
Needed for names (tables, columns, etc.) that are not all lowercase.

=item Numbers

Numbers basically use Perl syntax: C<99>, C<0xff>, C<077>, C<0b11>,
C<0.9e-9>

=item Strings

Again, these use Perl syntax.  Singly and doubly quoted strings are
supported.  Backquoted strings are not directly supported, because
they are used for identifiers already and are needed by SQL directly.
You can use {`...`} instead, however.

=over

=item E<39>blahE<39>

Singly quoted string.

=item E<34>blahE<34>

Doubly quoted string.

=back

=item Symbols

These SQL syntax elements act like keywords, but are symbolic:

  (, ), {, }, ...

=item Comments

The syntax is the same as in Perl:

  # this is a comment

=back

=head2 Deliberate Restrictions

=over

=item *

Identifiers containing C<$> or C<#> characters must be quoted with
C<`...`>.  This is because C<$> and C<#> interfere with Perl syntax.

=item *

In an ExprAs object, 'AS' is mandatory, just like in good SQL
programming practice:

=over

=item Bad here (but works in plain SQL)

    SELECT a b FROM c;

=item Good

    SELECT a AS b FROM c;

=back

=item *

Table and column names may not contain newline characters.

=back


=head2 Differences

As mentioned above, strings, numbers and comments follow Perl syntax.
This change was done for more elegent embedding of SQL into Perl.  It
also helps syntax highlighting...  E.g., you can naturally use string
interpolations, e.g.:

    my $x= "'test";  # most be quoted properly to work!
    my $y= sql{
        SELECT "difficult: $x"
    };

=head2 Extensions

=over

=item *

Numbers may contain C<_> just like in Perl, e.g. C<1_000_000>.

=item *

There are binary numbers: 0b11 == 3.

=item *

LIMIT clauses are parsed in both MySQL and PostgreSQL format
and always generated in PostgreSQL format, i.e.:

    sql{SELECT ... LIMIT 5, 2}

will stringify as:

    SELECT ... LIMIT 2 OFFSET 5

=back

=head2 Missing Error Checking

In some places, this package does not fully check your SQL code
at compile time, usually for two reasons: (a) to make the code
of the preprocessor easiler, (b) to keep the number of possible
syntax structures and object types low for the user.

=over

=item Column/Row Functions In  Expressions

Expressions allow more or less types depending on where they
are used.  The SQL grammar distinguishes them accordingly,
but we do not.  E.g. C<count(*)> cannot use in SQL in
a WHERE clause, but we don't check that but leave it to
your data base server.

=back

I am sure there's more that could be documented here.


=head2 Immediate Execution

SQL commands can be immediately prepared and executed, and possibly
fetched.  This is a similar simplification as with DBI's
C<selectall_arrayref()> etc. functionality.  This module introduces
two blocks for that: C<sqlDo{}> and C<sqlFetch{}>.

With C<sqlDo{}>, any statements can be just executed, without any
return value:

    my %newentry = (...);
    sqlDo{
        INSERT INTO table SET %newentry
    };

With sqlFetch, all rows can be immediately retrieved.  There are two
possible conversions for each row: hash or scalar.  A hash conversion
is selected by default, making this like fetching all rows using
fetchrow_hashref() when using DBI.  E.g., to read a whole table, you
could use:

    my @table = sqlFetch{ SELECT * FROM table };

No C<prepare()> or C<execute()> is necessary, so this makes for very
concise code.  If only one column is selected, then each row is returned
as a scalar, instead of as a hashref:

    my @id = sqlFetch{ SELECT id FROM table };

The distinction is made automatically.  There is currently no way to
force one or another row conversion.  The scalar conversion is
selected only if the query clearly returns only one column, which
needs to be visible without looking deeply into any embedded Perl
interpolations.

=over

=item

Scalar conversion is used if a single column is explicitly given in SQL:

  SELECT a FROM ...

=item

Scalar conversion is used if a singleton expression is found:

  SELECT COUNT(*) FROM ...

=item

Scalar conversion is used if a sub-query is found:

  SELECT (SELECT 5) FROM ...

=item

Scalar conversion is used if a scalar Perl interpolation is found:

  SELECT .$a FROM ...
  SELECT table.$a FROM ...
  SELECT ."$a" FROM ...
  SELECT 5
  SELECT "5"

etc.

=back

In any other case, hashref row conversion is used.

=over

=item

Hashref conversion is used if an asterisk is found:

  SELECT * FROM

=item

Hashref conversion is used if a non-scalar Perl interpolation is found:

  SELECT .@a FROM

=item

Hashref conversion is used if a complex and/or intransparent (to this
module) Perl interpolation is found, regardless of the actual number
of columns selected:

  SELECT {$a} FROM

In this case, a human sees only one column, but C<{}> is intransparent to this
SQL module, so it assumes a non-trivial case.

=back

The distinction of whether hash or scalar conversion is used is purely
syntactical and statically done at compile time, regardless of the actual columns
returned by using complex embedded Perl code.

If the returned list is evaluated in scalar context, then, as usual,
the module assumes that exactly one result is wanted.  A multi-line result
will cause an error.  Allowing scalar context is especially handy when
retrieving a single value from the data base:

    my $count = sqlFetch{ SELECT COUNT(*) FROM table };

Due to C<COUNT(*)> being the only column specification, scalar row
conversion is selected.  And since $count is scalar, C<sqlFetch> is
evaluated in scalar context, and returns the single row.  Together,
the behaviour is what is probably expected here.


=head2 Perl Interpolation

The basic construct for embedding Perl code in SQL is with braced
code blocks:

    sql{
        SELECT foo FROM bar WHERE
            { get_where_clause() }
    }

Interpolation of Perl is triggered by C<$>, C<@>, C<%>, C<"..."> and
C<{...}> in embedded SQL.  The syntax of such expressions is just like
in Perl.  All but C<{...}> behave just like Perl; C<{...}> is not an
anonymous hash, but equivalent to a C<do{...}> block in Perl.
Inside C<"..."> strings, you can also use Perl interpolation.

E.g. the following forms are the same:

    my $greeting= 'Hello World';
    my $s1= sql{ SELECT {$greeting} };    # general {...} interpolation
    my $s2= sql{ SELECT $greeting   };    # direct $ interpolation
    my $s3= sql{ SELECT "$greeting" };    # direct string interpolation

When parsing SQL expressions (i.e., values), it is unclear whether a
string or a column is used.  In that case, a string is used.  If you
mean to interpolate a column name, use a single dot in front of your
interpolation (this single dot is special syntax, and the final SQL
string will not contain that dot, but be proper SQL syntax):

    my $s1= sql{ SELECT blah.$x };        # unambiguous: $x is a column name
    my $s2= sql{ SELECT $x.blah };        # unambiguous: $x is a table name
    my $s3= sql{ SELECT "$x" };           # unambiguous: "..." is always a string
    my $s4= sql{ SELECT $x };             # ambiguous: could be string or column,
                                          #   => we resolve this as a string.
    my $s5= sql{ SELECT .$x };            # unambiguous: $x is a column name
                                          #   (the dot is special syntax)
    my $s6= sql{ SELECT ."foo$x" };       # unambiguous: "foo$x" is a column name

For the complete description of the syntax, see L<< "<Perl>" >>.

It is impossible to interpolate raw SQL in a string with this module,
since everything is parsed and thus syntax-checked.  That's the whole
point: we want guarantees that SQL injections are impossible, so we
won't jeopardise this by letting arbitrary raw strings to be injected.

However, this module allows fully recursive embedding, i.e., it allows
the use of sql{ ... } within the embedded Perl code.  Like so:

    sql{
        SELECT foo FROM bar WHERE
            {$type eq 'a' ?
                sql{foo >= 2}
            :   sql{foo <= 1}
            }
    }

All sql{...} blocks inside the embedded Perl code will not parse a statement
list, but an expression, because the {...} is inside the 'WHERE' clause.  This
means that sql{...} is context-dependent.

On top-level, sql{...} it is equivalent to sqlStmt{...}.  In the
example above, it is equivalent to sqlExpr{...}, because it is inside
a WHERE clause, where expressions are expected.  You can construct
SQL expressions, too, by changing the default:

    my $expr1= sqlExpr{ foo >= 2 };
    my $expr2= sqlExpr{ foo <= 1 };
    sql{
        SELECT foo FROM bar WHERE
            {$type eq 'a' ?
                $expr1
            :   $expr2
            }
    }

Note: Type checking of interpolations will be done at run-time.
So the following only fails at run-time, not compile time:

In the above example, this module has no way of knowing: (a) that
the ?: operator yields inconsistent kinds of SQL things, (b) that
the embedded Perl expression may return sqlStmt.  So the case that
sqlStmt is returned only fails at run-time.

    my $q= sql{
        SELECT foo FROM bar WHERE
        {$is_large ?
            sqlStmt{UPDATE foz SET x=5 WHERE name=''}
        :   sqlExpr{test > 5}
        }
    };

Actually, this means that you have the same dynamic type checking
that Perl has.  The above only fails when C<$is_large> is true.
And the following is, maybe surprisingly, correct
(both for for true and false values of C<$is_large>):

    my $q= sql{
        SELECT foo FROM bar WHERE
        {$is_large ?
            sqlStmt{SELECT foz FROM baz}
        :   sqlExpr{test > 5}
        }
    };

This is correct, because a select statement can be used as a value,
and thus in a where clause.

The default interpretation of sql{...} inside interpolations may be
wrong for complex Perl code.  The default the local context where the
interpolation starts, so after WHERE, the default is Expr:

  my $q= sql{
     SELECT foo FROM bar WHERE
     {
         my $subquery= sql{
             SELECT foz FROM baz   # <--- SYNTAX ERROR, because sql{...} is
         };                        #      parsed as sqlExpr{...} here, since
                                   #      the Perl interpolation follows
                                   #      WHERE.  You probably want to use
                                   #      sqlStmt{...} here.
         ...
     }
  };

Depending on context, embedded Perl is evaluated in scalar or in list
context.  Inside SQL lists, the embedded block will be evaluated in
list context:

    my $q= sql{
        SELECT { code1 }
    };

code1 will be evaluated in list context, and each result
will be one value of the SELECT statement.

Furthermore, arguments of some binary operators, namely C<+>, C<*>,
C<AND>, C<OR>, C<XOR>, C<||>, and arguments to any function are
evaluated in list context.  Each element of the list becoming one
operand:

    my @a= (1,2,3);
    my $q= sql{
        SELECT 0 + @a
    }

This selects C<0+1+2+3>.

Finally, in the above positions, many unary operators, namely C<->,
C<NOT>, and any operator starting with C<IS ...>, will 'pass-through'
list context, and are evaluated point wise.  E.g.:

    my $q=sql{
        SELECT 0 AND NOT(@a)
    };

This will become C<0 AND (NOT 1) AND (NOT 2) AND (NOT 3)>.

In all other situations, values are evaluated in scalar context.
Here's an example of scalar context:

    my $q= sql{
        SELECT name AS { code2 }
    };

Here, code2 will be evaluated in scalar context, because only
one single identifier can be used in the AS clause.

Some list interpolations allow syntactic hashes and then do something
special with them.  This means that hashes usually behave differently
in list context depending on whether you write them as
C<%a> or C<{ %a }>.
The former may have special meaning to embedded SQL (see below),
while the latter has Perl meaning, listing the hash as a list,
interleaving keys and values.

Note that in contrast to Perl, syntactic arrays are not allowed in
scalar context.  E.g. the following code is B<wrong>:

    my @a= ...
    my $q= sql{
        SELECT name FROM customer WHERE @a  # <--- ERROR
    };

This is to prevent bugs.  In plain Perl, @a would evaluate to the
number of elements in @a, but in embedded SQL, this is an error.  If
you really mean it, use C<{ @a }> instead or C<${\scalar(@a)}>.

In the same way as syntactic arrays, syntactic hashes are not allowed
in scalar context.  If you think you must use them for some reason,
use C<${\scalar(%a)}>.


=head3 Statement Interpolation

In statements or statement lists, embedded Perl code must be a
blessed 'sqlStmt' object.  E.g.:

    my $q= sql{
        SELECT foo FROM bar
    };
    my $q2= sql{
        $q
    };

The above code is effectively the same as:

    my $q2= $q;

Less trivially, you can interpolate statements as subqueries, too.

Multiple interpolation works, too:

    my @q= sql{
        SELECT foo FROM bar ;
        SELECT foz FROM baz
    };
    my @q2= sql{
        @q
    };

Again, this is effectively the same as:

    my @q2= @q;

For the syntax of statements, see L<< "<Stmt>" >>.


=head3 Join Interpolation

E.g. in a C<SELECT> statement, you can use a Join clause
you keep in a variable:

    my $join= sqlJoin{ NATURAL INNER JOIN foo };
    sql{ SELECT name FROM bar Join $join WHERE ... };

For the syntax of join clauses, see L<< "<Join>" >>.

Join interpolation only accepts Join objects, nothing else, so they
must have been constructed with C<sqlJoin{...}>.  You may use
lists:

    my @join= (
        sqlJoin{ NATURAL INNER JOIN foo },
        sqlJoin{ LEFT JOIN baz USING (a) }
    );
    sql{ SELECT name FROM bar Join @join WHERE ... };

Be advised to use the typecast C<Join> before Join interpolations,
because there is no single keyword to start the block of JOIN clauses
in an SQL statement, so you might run into ambiguities.  Using
Join makes the situation unambiguous to the parser.


=head3 Expression Interpolation

For the syntax of expressions, see L<< "<Expr>" >>.

In expressions or expression lists, embedded Perl code looks like
the following:

   my $q= sql{
       SELECT { code3 }
   };

It may may return the following types of objects:

=over

=item plain number, plain strings

These will be assumed to be constant values in SQL.  Therefore,
these will be quoted using the quote() function.

=item sqlExpr objects

Such objects will be interpolated as a complex tree, so you can
create and reuse them:

    my $expr= sqlExpr{ age + 5 };
    my $q= sql{
        SELECT $expr FROM customer
    };

=back

In expression lists, the Perl code may return multiple values
that will be passed as multiple things in SQL.  Each element
may be one of the above items and handled accordingly.

=head4 Array Interpolation in Expressions

Functions allow interpolation of arrays for their parameters:

    CONCAT(@a,@b,'test')

The operators C<+>, C<*>, C<AND>, C<OR>, C<XOR>, and C<||> allow
interpolation of arrays:

    5 * @a

With C<@a=(1,2,3)> will translate to something like:

    5 * 1 * 2 * 3

If you want to multiply nothing else but the values in C<@a>, simply
use an empty list to construct the syntactic context needed for the
operator:

    {} * @a

This expands to:

    1 * 2 * 3

This interpolation is especially handy for constructing C<WHERE>
clauses with the C<AND> operator, e.g.:

    WHERE {} AND %cond

With C<< %cond=( a => 1, b => 2, c => 3 ) >>, this expands to:

    WHERE a = 1 AND b = 2 AND c = 3

All of these functions also work with zero parameters, i.e., C<{}*{}>
and C<{}AND{}> will expand to C<1>, while C<{}+{}> and C<{}OR{}> will
expand to C<0>.

For C<AND> and C<OR>, this module provides convenience prefix versions,
because they are relatively frequent in WHERE clauses.  These prefix
versions expand to normal infix notation, so the following produce
equivalent SQL code:

    WHERE {} AND %cond

and

    WHERE AND %cond

It is handy to construct a list of conditions using this form:

    SELECT age FROM members
    WHERE AND {
        ($opt{name}   ? sql{ name   == $opt{name}   } : ()),
        ($opt{colour} ? sql{ colour == $opt{colour} } : ())
    }

Such prefixing abbreviations are not supported for symbolic operators
+ and -, because they are predefined prefix operators and have had a
different context in previous versions of this module.  For *, we do
not provide such a special form for symmetry with +.

As usual, unary operators that support interpolation can be combined
with this:

    WHERE AND NOT { 1, 2, 3 }

expands to

    WHERE (NOT 1) AND (NOT 2) AND (NOT 3)

Also note that unary operators followed by ( parse as a function
call.  This means that in list context, a unary prefix operator
can actually be invoked with several arguments.  These will be
applied point-wise, just like in Perl interpolation.  So what
may intuitively look very similar, is not so internally, but still
does the same thing:

    WHERE AND NOT (1,2,3)    # NOT has multiple arguments, which are
                             # applied point-wise, because NOT
                             # is in list context (from the AND)

and

    WHERE AND NOT {1,2,3}    # NOT has a single argument, a Perl
                             # interpolation that returns multiple
                             # values.

Both do the same:

    WHERE (NOT 1) AND (NOT 2) AND (NOT 3)

The following is an error, because NOT only takes on argument:

    WHERE NOT (1,2,3)        # NOT is in scalar context and thus cannot
                             # take multiple arguments.


=head4 Hash Interpolation in Expressions

As alreay indicated, if hash interpolation is used in expression list
context, such hashes are turned into lists of equations.  The hash
keys will be quoted with quote_identifier(), the hash values may be
one of the things described above.  Each key-value pair will expand
to an expression:

   `key` = value

This kind of interpolation is especially handy together with operators
like C<AND> and C<+> which allow list context expansion, as described
in the previous section.  For example:

    my %cond= ( age => 50, surname => 'Doe' );
    my $q= sql{
        SELECT ... WHERE {} AND %cond
    };

Will expand to something like:

    SELECT ... WHERE `age` = 50 AND `surname` = 'Doe'

Hash interpolations of this kind can also be used in C<SET> clauses.

As described in the previous section, C<AND> and C<OR> can also be used
as prefix operators, which is handy in interpolations like these.

    my $q= sql{
        SELECT ... WHERE AND %cond
    };

=head4 Interpolation of Unary Operators

A pair of parenthesis C<(...)>, the prefix operators except C<+>
(i.e., C<-> and C<NOT>) and all suffix operators (e.g. C<IS NOT NULL>)
will expand point-wise:

    my @col= ( 'name', 'age' );
    my $q= sql{
        SELECT ... WHERE {} AND (.@col IS NOT NULL)
    };

It will expand to something like:

    SELECT .. WHERE `name` IS NOT NULL AND `age` IS NOT NULL

This behaviour is just like that of C<DESC> and C<ASC> in the
C<ORDER BY> operations, see L<"Interpolation in ASC/DESC clause">.

Because C<+> is also a list-context infix operator, and because its
purpose as prefix operator is very limited, it was felt that it is too
confusing to let it operate point-wise.  So the following is an
B<error>:

    my @val= (1,2,3);
    my $q= sql{ SELECT +@val };  # <--- currently an ERROR

However, the infix operator

    my @val= (1,2,3);
    my $q= sql{ SELECT {} + @val };

will expand to:

    SELECT 1 + 2 + 3;

=head3 Check Interpolation

In C<WHEN> clauses, incomplete expressions can be used.  These can
be stored in a Check object:

    my $check1= sqlCheck{ > 50 };

They may be used later in a C<WHEN> clause:

    my $expr= sqlExpr{CASE a WHEN $check1 THEN 1 ELSE 2 END};

This will become:

    CASE `a` WHEN > 50 THEN 1 ELSE 2 END

Check objects can be used also in hash tables for interpolation
in expressions:

    my %cond= (
        surname    => 'Doe',
        age        => sqlCheck{ > 50 },
        firstname  => sqlCheck{ IS NULL }
    );
    my $q= sql{SELECT * FROM people WHERE {} AND %cond};

This will expand like this:

    SELECT * FROM `people`
    WHERE `age` > 50 AND `firstname` IS NULL AND `surname` = 'Doe'


=head3 Expression List Interpolation

Sometimes, lists of expression occur, e.g. the C<IN> operator or the
C<INSERT ... VALUES> statement.  In these cases, you may interpolate
array references.  The following two SQL statements are the same:

    my $a= [1,2];
    my $q= sql{
        SELECT 5 IN (@$a) ;
        SELECT 5 IN $a
    };

In scalar context above, this is not that useful, because for C<$a>
you have the equivalent form C<(@$a)>, but in list context, it is
useful:

    my @a= ([1,2], [2,3]);
    my $q= sql{
        INSERT INTO t (x,y) VALUES @a
    };

This expands to:

    INSERT INTO t (`x`, `y`) VALUES (1,2), (2,3)

Please note that SQL needs at least one element after C<VALUES>,
so if C<@a> in the above case happens to be an empty list, you will
get a runtime error.

Also note that Perl reference syntax (i.e., a backslash) does not
trigger Perl interpolation, so the following is B<wrong>:

    my @a= (1,2);
    my $q= sql{
        SELECT 5 IN \@a   # <--- ERROR: \@a is no Perl interpolation
    };


=head3 Expression Interpolation and AS clause

If an AS clause follows an expression interpolation, the expression
will be evaluated in scalar context, i.e, there may be maximally one
expression, not a list.  E.g. the following is B<wrong>:

    my @col= ('x', 'y');
    my $q=sql{
        SELECT .@col AS name    # <--- ERROR: @col not allowed with AS
    };

It makes no sense to apply C<AS name> to both elements of C<@col>, so
it is not allowed.  Without C<AS>, the clause does support array interpolation,
of course:

    my $q=sql{
        SELECT .@col      # <--- OK, will become: SELECT `x`, `y`
    };

=head3 Type Interpolation

Types can be stored in Perl variables:

    my $t1= sqlType{ VARCHAR(50) };

Types can be easily extended:

    my $t2= sqlType{ $t1 CHARACTER SET utf8 };

This is equivalent to:

    my $t2= sqlType{ VARCHAR(50) CHARACTER SET utf8 };

You can also remove specifiers, i.e., do the opposite of extending
them, with a syntax special to this module starting with C<DROP>:

    my $t1b= sqlType{ $t2 DROP CHARACTER SET };

This makes C<$t1b> the same type as C<$t1>.

To allow modification of types already constructed and stored as a
Perl object, type attributes or base types can be changed by simply
listing them after the base type or interpolation.  Any new value
overrides the old value, e.g. to change the size:

    my $t3= sqlType{ $t1 (100) };

This is equivalent to:

    my $t3= sqlType{ VARCHAR(100) };

You can even change the base type, keeping all other attributes if
they are sensible.  Any attributes not appropriate for the new base
type will be removed:

    my $t4= sqlType{ $t2 DECIMAL };

This is equivalent to:

    my $t4= sqlType{ DECIMAL(50) };

The character set attribute has silently been removed.  If you change
the base type again, it will not reappear magically.

    my $t5= sqlType{ $t4 CHAR };

This is equivalent to:

    my $t5= sqlType{ CHAR(50) };

Note how the character set was removed.

In list context, modifications made to an array Perl interpolation
will affect all the elements:

    my @t1= sqlType{ CHAR(50), VARCHAR(60) };
    my @t2= sqlType{ @t1 (100) };

This is equivalent to:

    my @t2= sqlType{ CHAR(100), VARCHAR(100) };

See also L<< "<Type>" >>.


=head3 ColumnSpec Interpolation

ColumnSpec interpolation is very similar to Type Interpolation,
i.e., just like types, you can modify ColumnSpec objects by
simply suffixing constraints or type attributes or base types.

See also L<< "<ColumnSpec>" >>.


=head3 Table Interpolation

Table objects represent fully qualified table specifications and may
include catalog, schema and table name information.

For the syntax of table specifications, see L<< "<Table>" >>.

The interpolation of Tables is simple: either it is a Table object
generated with C<sqlTable{...}> or it is a simple string.  In list
context, a list of such values may be used.

    my @tab= ( 'foo', 'bar' );
    my $q= sql{
        SELECT name, id FROM @tab
    };

Schemas and catalogs are supported.  For them to work, your data base
needs to support them as well.  The full input syntax for a table
specification is:

    [ [ catalog . ] schema . ] table

These three components will always be passed to quote_identifier()
together as three parameters, suitable for DBI.  As mentioned, and
sqlTable object may hold a complete table specification:

    my $tabspec= sqlTable{ cata.schem.tab };
    my $q= sql{
        SELECT name FROM $tabspec
    };

A table specification can be used to qualify a column name, of course:

    my $q= sql{
        SELECT $tabspec.name FROM ...
    };

The following is B<wrong>, because a table specification cannot be
qualified further:

    my $q= sql{
        SELECT name FROM $tabspec.other  # <--- ERROR!
    };

=head3 Column Interpolation

Column objects are used in expressions.  They are fully qualified
column specifications and may include table, schema, catalog, and
column information.

For the syntax of column specifications, see L<< "<Column>" >>.

The are two types of Column interpolations: one element vs. multi
element.

For one element Columns, embedded Perl code may return sqlColumn{...}
objects or strings:

    my @col= ('name', sqlColumn{age});
    my $q= sql{
        SELECT .@col
    };

The above prefixed C<.> is syntactic sugar.  More generally, you
can esplicitly request expansiong of C<@col> as Column objects:

    my $q= sql{
        SELECT Column @col
    };

For multi element Columns, only strings or C<sqlExpr{*}> (in Perl,
there is the constant C<SQL::Yapp::ASTERISK> for this) are allowed
in an interpolation, be cause a column specification cannot be
qualified further:

    my $q= sql{
        SELECT mytable.@col   # <-- none of @col may be sqlColumn
    };

In a list context, multiple column specifications are allowed, as
already shown in the previous examples.  Each part of the column
specification may be a list and will be expanded multiply:

    my $q= sql{
        SELECT @tab.@col
    };

This will expand to the following:

    SELECT $tab[0].$col[0], ... , $tab[0].$col[n],
           $tab[1].$col[0], ... , $tab[1].$col[n],
           ..., $tab[m].$col[n]

For syntactic hashes in list context, each hash's keys will be
used, e.g.:

    my %col= ( 'surname' => 1, 'first_name' => 2 );
    my $q= sql{
        SELECT .%col
    };

The keys of C<%col> will be sorted using standard Perl C<sort>
function, so this will expand to:

    SELECT `first_name`, `surname`

The sorting is done so that in multi-place hash interpolation, the result
columns will have a deterministic order:

    my $q= sql{
        SELECT %tab.%col   # table name and column names will be sorted
    };


=head3 GROUP BY / ORDER BY Interpolation

For the syntax of Order clauses, see L<< "<Order>" >>.

In any place where a list of order clauses can be listed inside a
C<GROUP BY> or C<ORDER BY> clause, the whole clause is dropped if
the list is empty:

    my @a= ();
    my $q= sql{
        SELECT foo FROM bar GROUP BY @a;
    };

This will expand so something like:

    SELECT foo FROM bar

Perl interpolation of strings, except C<"..."> interpolation,
generates column names instead of plain strings in order position.  To
force interpretation as a string, use C<"..."> interpolation.  This is
different from Expr, which defaults to string interpretation and needs
you to use a single dot to force column name interpretation.  Compare
the following examples:

    my $a= 'a';
    print sqlOrder{ $a }."\n";      # $a is a column name
    print sqlOrder{ .$a }."\n";     # $a is a column name
    print sqlOrder{ "$a" }."\n";    # $a is a string
    print sqlExpr{ $a }."\n";       # $a is a string
    print sqlExpr{ .$a }."\n";      # $a is a column name
    print sqlExpr{ "$a" }."\n";     # $a is a string

So this produces the following output (the quotation depends on used
DB):

    `a`
    `a`
    'a'
    'a'
    `a`
    'a'

I.e., C<sqlOrder> (just like C<sqlColumn>) produces an identifier,
while C<sqlExpr> produces a string literal.

Also note that hash interpolation behaves the same as for
C<sqlColumn>, namely on the hash keys.  The hash keys will be
sorted using Perl's C<sort> function:

    my %a= ( a => 1, b => 1 );
    my $q= sql{
        SELECT a, b FROM t ORDER BY %a
    };

This will become:

    SELECT `a`, `b` FROM t ORDER BY `a`, `b`

For C<GROUP BY>, this can also be used:

    my %a= ( a => 1, b => 1 );
    my $q= sql{
        SELECT a, b, c FROM t GROUP BY %a
    };


=head4 Interpolation In ASC/DESC Clause

If an C<ASC>/C<DESC> keyword follows a list interpolation, it is used
for each of the elements of the list.  For example:

    my @col= ('x', 'y');
    my $q=sql{
        SELECT ... ORDER BY @col DESC
    };

This is valid (if you fill in valid code for C<...>) and similar to:

    my $q=sql{
        SELECT ... ORDER BY x DESC, y DESC
    };

This even works if the elements are themselves Order objects that
carried an C<ASC> or C<DESC> modifier: the direction will either
be kept (in case of an additional C<ASC>) or swapped (in case of
an additional C<DESC>):

    my @order= sqlOrder{ a DESC, b ASC };
    my $q= sql{
        SELECT ... GROUP BY @order ORDER BY @order DESC
    };

This will expand to something like:

    SELECT ... GROUP BY a DESC, b ORDER BY a, b DESC

(A suffixed C<ASC> is not printed since it is the default.)


=head3 LIMIT Interpolation

Perl code in LIMIT clauses may return a number or C<undef>.
Specifying an offset but no count limit is not directly supported, so
we will generate a very large count limit in that case, hoping that
the data base server can handle that.  Example:

    sql{ SELECT ... LIMIT 10, {undef} }

This will stringify as:

    SELECT ... LIMIT 18446744073709551615 OFFSET 10

Note that LIMIT clauses are not standardized.

=over

=item MySQL

    LIMIT cnt
    LIMIT offset, cnt
    LIMIT cnt OFFSET offset    "for PostgreSQL compatibility"

=item PostgreSQL

    LIMIT cnt
    LIMIT cnt OFFSET offset
    LIMIT ALL
    LIMIT ALL OFFSET offset
    OFFSET offset

=back

We support all of MySQL and all of PostgreSQL as input syntax and will
always produce:

    LIMIT cnt OFFSET offset

So this is automatically made compatible for the two data base types.

However, this is not enough to support all kinds of data bases.  Other
syntaxes include:

=over

=item Oracle

    ... WHERE rownum >= offset && rownum < (cnt + offset)

This is not automatically generated from C<LIMIT ...>, but you can
write it manually yourself, of course, because C<rownum> is a normal
identifier.

=item MS

    SELECT TOP cnt ...

This is not yet supported.

=back


=head2 Identifier Name Translation

This package allows you to modify all identifiers before they are
quoted.  This allows you, e.g., to set a common prefix for all
table names.  The following functions modification handlers:

    xlat_catalog
    xlat_schema
    xlat_table
    xlat_column
    xlat_charset
    xlat_collate
    xlat_constraint
    xlat_index
    xlat_trancoding
    xlat_transliteration

For example:

    SQL::Yapp::xlat_table { 'foo_'.$_[0] }

Would prefix all table names with C<foo_>.  I mean every table name,
mind you.  Because the library knows about the whole SQL structure and
parses everything, the quotation works throughout: for literal as well
as all Perl interpolations.  For example:

    my $q= sql{
        SELECT name FROM customer
    };

This would be expanded (depending on how quote_identifier() quotes)
similar to:

    SELECT `name` from `foo_customer`;

The same is achieved with the following:

    my $table= 'customer';
    my $q= sql{
        SELECT name FROM $table
    };

Note that the package cannot distinguish aliases and real table names,
so the following is modified more than you might expect (which usually
does not hurt, but you should know):

    my $q= sql{
        SELECT c.name FROM customer AS c
    };

This results in:

    SELECT `foo_c`.`name` FROM `foo_customer` as `foo_c`

You can specify such modifications in the use statement already:

    use SQL::Yapp xlat_table => sub { 'foo_'.$_[0] };

Simple prefixing can be achieved by convenience options for columns,
tables, schemas, and catalogs, so you don't need to use C<xlat_>
options, but can write more readably:

    use SQL::Yapp table_prefix => 'foo_';

The following convenience options exist:

    catalog_prefix
    schema_prefix
    table_prefix
    column_prefix
    constraint_prefix

These convenience options simply define the corresponding C<xlat_>
function appropriately.


=head2 Identifier Checking

You might want to check for typos in column and table names at
compile-time.  This can be done in a very general way by using
the C<check_identifier> callback function.  You can set it as
follows:

   sub my_check_identifier($$$$;$)
   {
       my ($kind, $catalog, $schema, $ident1, $ident2)= @_;
       ...
   }

   use SQL::Yapp
       check_identifier => \&my_check_identifier,
       ...;

It is important to set the C<check_identifier> function as
early as in the C<use> statement, because it is invoked at compile-time.
Setting it afterwards is possible, but only allows run-time checks
(which must be explicitly enabled, see below).  You can set the
function later by invoking:

    SQL::Yapp::check_identifier { ... };

For columns, the function will be invoked with five parameters,
namely:

   $check_identifier->('Column', $catalog, $schema, $table, $column)

The C<$catalog> and C<$schema> will be C<undef> if unspecified.  For
unqualified columns (i.e., without explicit table name), the $table
parameter will be either C<undef>, if no possible table is known, or
$table will be an array reference with all tables that might contain
the column.

If the column is C<*>, this function will not be invoked.

For identifiers other than columns, the functions will be invoked with
only four parameters, the first being the kind of identifier (in the
same syntax as the name after the C<sql...{...}>, e.g., C<Table>,
C<Index>, C<Constraint>, C<CharSet>, etc.)  followed by the
schema-qualified identifier, again using C<undef> for unqualified
parts:

   $check_identifier->($kind, $catalog, $schema, $identifier);

For example, for a table:

   $check_identifier->('Table', $catalog, $schema, $table_name);

By default, only compile-time checks are performed.  You can request
run-time checks, too, so that all identifiers are checked, including
those interpolated from Perl code, which is not seen at compile-time,
of course.  Run-time checks are enabled by setting the
C<runtime_check> flag to one, either early:

   use SQL::Yapp
       runtime_check => 1,
       ...;

or later:

   SQL::Yapp::runtime_check(1);

Both involved functions can also be imported:

   use SQL::Yapp
       ...,
       qw(check_identifier runtime_check ...);

Note that the package does not (yet) understand the SQL syntax good
enough to infer possible tables for columns, so we never pass an array
ref.  But be prepared for it to avoid being surprised in a later
version of the library.


=head2 Normalisation

We currently don't do very much to normalise the SQL syntax so that it
works for multiple data bases no matter how you write your query.
What we do is listed in this section.

=over

=item LIMIT Normalisation

Since LIMIT clauses are non-standard, they are normalised as
described in L<"LIMIT Interpolation">.

=item DELETE Normalisation

MySQL allows you to specify C<DELETE> statements with a different
syntax, listing some tables before C<FROM> and some after it.  This
syntax is rejected.  You are forced to write this with a C<USING>
clause.  This is normalisation by forcing good upon the user.

Unsupported MySQL Extension (from the MySQL documentation):

    DELETE t1, t2 FROM t1 INNER JOIN t2 INNER JOIN t3
    WHERE t1.id=t2.id AND t2.id=t3.id;

The following is the supported equivalent.  Also note the use of
C<CROSS JOIN> instead, as C<INNER JOIN> requires an C<ON> clause.
Plus, you need to use parentheses:

    DELETE FROM t1, t2 USING t1 CROSS JOIN t2 CROSS JOIN t3
    WHERE (t1.id=t2.id) AND (t2.id=t3.id);

=item CASE Normalisation

A CASE expression with zero WHEN clauses will be normalised to its
default value.

Also, the default value will always be printed (if missing, C<ELSE
NULL> will be generated).

Example:

    my @e= sqlExpr{
        CASE a WHEN 1 THEN 0 ELSE 5 END,
        CASE a WHEN 1 THEN 0 END,
        CASE a ELSE 5 END,
        CASE a END
    };

Some of these are syntax errors in plain SQL, but we accept them, and
generate the following code, resp.:

    CASE `a` WHEN 1 THEN 0 ELSE 5 END,
    CASE `a` WHEN 1 THEN 0 ELSE NULL END,
    5
    NULL

=item INSERT ... SET Normalisation

MySQL has an extension in the C<INSERT> statement that allows the use
of C<SET> instead of C<VALUES>.  I personally find this much more
natural and more easy to read and maintain than the normal syntax
where column names are separated from their respective values.

For this reason, this syntax is allowed although there is a portable
alternative.  If you pass a single hash table to the SET clause, it
will be normalised to the standard form, e.g.:

    my %a= ( a => 5, b => 6 );
    my $q= sql{
        INSERT INTO t SET %a
    };

will be normalised to (the column order may be different, depending
on Perl's mood of enumerating the hash table):

    INSERT INTO `t` (`a`,`b`) VALUES (5,6);

You can do all kinds of fancy things and the transformation will still
work:

    my @q= sql{
        INSERT INTO t SET a = 5, b = 6 ;
        INSERT INTO t SET %{{ a => 5, b => 6 }} ;
        INSERT INTO t SET %a, c = 7
    }

Even more fancy things work:

    my $cola=  sqlColumn{ a };
    my $colc=  sqlColumn{ c };
    my $exprb= sqlExpr{ b = 6 };
    my $exprc= sqlExpr{ $colc = 7 };
    my $q= sql{
        INSERT INTO t SET $cola = 5, $exprb, $exprc;
    }

In short, you can freely use C<INSERT ... SET> even for data base
servers that only support C<INSERT ... VALUES>.

=item Operator/Function Normalisation

=over

=item *

C<POW()> and C<**> will be normalised to C<POWER>.

=item *

C<||> will be normalised to C<CONCAT> if
C<< write_dialect == 'mysql' >>.  And vice versa: C<CONCAT>
will be translated to C<||> in any dialect but mysql.

Note: There is no way concatenation can be normalised so that it works
automatically in all common SQL dialects.  One way to make mysql more
conformant is to switch the server to ANSI mode.

=item *

MySQL and has an extension to parse C<&>, C<|>, and C<^> as bit
operations like C.  In Oracle, on the other hand, there is C<BITAND>,
but with a slightly different semantics.  To ease porting, the C
operators are converted to C<BITAND>, C<BITOR>, C<BITXOR> for Oracle,
and vice versa for MySQL.  You need a bit of more work (function
definitions) for this to work in Oracle, however, but it is a start.

=back

=back

=head2 Manual Parsing

Sometimes you may want to parse SQL structures at run time, not
at compile time.  There is a function C<parse> to do this.  Its
invocation is straight-forward:

    my $perl= SQL::Yapp::parse('ColumnSpec', 'VARCHAR(50) NOT NULL');

The result of this function is a string with Perl code (this is
what the compiler needs, so this is what you get here).  To create
an object, you need to evaluate this:

    my $obj= eval($perl);

This C<$obj> behaves exactly like a structure created at compile time,
e.g. the following creates the same object:

    my $obj2= sqlColumnSpec{VARCHAR(50) NOT NULL};

Neither for parse() nor for eval() you will need the DBI link (the dbh
module option).  Only if you stringify the object, you will need it.

=head2 List of SQL Structures

=over

=item sqlExpr{...}

An expression.  You can use it wherever expressions are used in SQL:

    my $test= sqlExpr{a == 5};
    sql{... WHERE $test ...}

See also L<< "<Expr>" >> and L<"Expression Interpolation">.

=item sqlCheck{...}

A check, i.e., a predicate.  Can be any boolean suffix to an
expression, which may be used inside a C<WHEN> clause:

    my $check1= sqlCheck{IS NULL};
    my $check2= sqlCheck{== 5};
    sqlExpr{CASE a WHEN $check1 THEN 1 WHEN $check2 THEN 2 ELSE 3 END};

See also L<< "<Check>" >> and L<"Check Interpolation">.

=item sqlColumn{...}

A column specification.  This may be a complex column name containing
a table name.

See also L<< "<Column>" >> and L<"Column Interpolation">.

=item sqlTable{...}

A table specification

See also L<< "<Table>" >> and L<"Table Interpolation">.

=item sqlCharSet{...}

A character set.

See also L<< "<CharSet>" >>.

=item sqlCollate{...}

A collation.

See also L<< "<Collate>" >>.

=item sqlIndex{...}

An index name.

See also L<< "<Index>" >>.

=item sqlTableOption{...}

An option for CREATE TABLE.

See also L<< "<TableOption>" >>.

=item sqlTransliteration{...}

A transliteration name.

See also L<< "<Transliteration>" >>.

=item sqlTranscoding{...}

A transcoding name.

See also L<< "<Transcoding>" >>.

=item sqlStmt{...}

A complete SQL statement.

See also L<< "<Stmt>" >> and L<"Statement Interpolation">.

=item sqlType{...}

A type (for CREATE ... or ALTER ...).

See also L<< "<Type>" >> and L<"Type Interpolation">.

=item sqlJoin{...}

A join clause to be used in C<SELECT> statements and many
others.

See also L<< "<Join>" >> and L<"Join Interpolation">.


=item sqlOrder{...}

An order specification for GROUP BY and ORDER BY clauses.  Essentially
an expression whose Perl string interpolations default to column names
and which are optionally suffixed with ASC or DESC.

See also L<< "<Order>" >> and L<"GROUP BY / ORDER BY Interpolation">.

=item sqlDo{...}

Like sqlStmt, but then executes the statement via the DB handle.  Nothing
is returned.  This can thus be evaluated in void context.

See also L<< "<Stmt>" >> and L<"Immediate Execution">.

=item sqlFetch{...}

Like sqlStmt, but then executes the statement via the DB handle and
returns the rows as a list, each row convertd as a hashref or, for
obvious one-column selects, to a scalar.

See also L<< "<Stmt>" >> and L<"Immediate Execution">.

=back


=head1 SYNTAX

In the following sections, the supported syntax is listed
in detail.  A BNF variant is used to represent the syntax,
and most people will probably find it intuitiv without
further explanation.  Still, here are some explanations.

The C<::=> operator is left out.  Instead, the previous headline
defines what is currently defined.

Upper case identifiers are literal keyword terminals:

  SELECT

CamelCase identifiers in quotes are literal typecast keyword
terminals:

  'Join'

Symbols in quotes are literal symbolic terminals:

  '('

CamelCase identifiers (and maybe a little more) in pointed brackets
are non-terminals and refer to other rules:

  <Join>
  <SELECT Stmt>

Plain English text in pointed brackets is a terminal that is informally
explained by that text:

  <a number in Perl syntax>

Optional parts:

  [ ... ]

Optional parts that, depending on other syntax elements or other
constraints, may even be forbidden, and need further clarification to
fully describe the syntax:

  [ ... ]?

Alternatives:

  A | B | C

Grouping, for example together with a list of alternatives:

  A ( B | C )

Literal parenthesis also form groups:

  '(' ... ')'

Sequences that contain one item A or more:

  A ...

Sequences with comma separator that contain once item A or more times:

  A , ...

Note that this grammar allows redundant commas or other separators in
all lists except after the last element.  Lists delimited with
parentheses even allow redundant commas after the last element before
the closing parenthesis.  Such lists are rectified and printed in
proper SQL syntax.  This is such a common typo, especially in CREATE
TABLE statements, that it was felt it should be tolerated.


=head2 <SELECT Stmt>

   SELECT
       [ ALL | DISTINCT | DISTINCTROW ]
       [ <MyPreOption> , ... ]
       ( <ExprAs> , ... )
       [ FROM ( <Table> , ... )
           [ <Join> ... ]
           [ WHERE Expr ]
           [ GROUP BY ( <Order> , ... ) [ WITH ROLLUP ] ]
           [ HAVING Expr ]
           [ ORDER BY ( <Order> , ... ) ]
           [ LIMIT ( <Count> | ALL | <Offset> , <Count> ) ]
           [ OFFSET <Offset> ]?
           [ FOR ( UPDATE | SHARE ) ]
           [ ( <PostgresPostOption> | <MyPostOption> ) , ... ]
       ]

=over

=item <Offset>

=item <Count>

 <Integer> | '?'

See also L<"Limit Interpolation">.

=item <ExprAs>

 <Expr> [ AS <ColumnName> ]

=item <MyPreOption>

   HIGH_PRIORITY | STRAIGHT_JOIN
 | SQL_SMALL_RESULT | SQL_BIG_RESULT | SQL_BUFFER_RESULT
 | SQL_CACHE | SQL_NO_CACHE | SQL_CALC_FOUND_ROWS

=item <MyPostOption>

   LOCK IN SHARE MODE

=item <PostgresPostOption>

   NOWAIT

=back

The C<OFFSET> clause is forbidden if C<Offset> was parsed before in
the C<LIMIT> clause.

See also
L<< "<ColumnName>" >>,
L<< "<Expr>" >>,
L<< "<Integer>" >>,
L<< "<Join>" >>,
L<< "<Order>" >>,
L<"LIMIT Interpolation">.


=head2 <INSERT Stmt>

    INSERT [ ( LOW_PRIORITY | HIGH_PRIORITY | DELAYED | IGNORE ) , ... ]
        [ INTO ] <Table> [ '(' <ColumnName> , ... ')' ]
        (
          DEFAULT VALUES
        | ( VALUES | VALUE ) ( <ExprList> , ... )
        | SET ( <ColumnName> '=' <Expr> , ... )
        | <SELECT Stmt>
        )
        [ ON DUPLICATE KEY UPDATE ( <ColumnName> '=' <Expr> , ... ) ]

This is a blend of MySQL and PostgreSQL syntax in order to support
both syntaxes.  C<LOW_PRIORITY>, C<HIGH_PRIORITY>, C<DELAYED>,
C<IGNORE>, C<SET> and C<ON DUPLICATE KEY UPDATE> are MySQL only.

See also
L<< "<ColumnName>" >>,
L<< "<Expr>" >>,
L<< "<ExprList>" >>,
L<< "<SELECT Stmt>" >>,
L<< "<Table>" >>,
L<"INSERT ... SET Normalisation">,
L<"Expression List Interpolation">.


=head2 <UPDATE Stmt>

    UPDATE
        [ ( LOW_PRIORITY | IGNORE | ONLY ) , ... ]
        ( <TableAs> , ... )
        SET ( <Column> '=' <Expr> , ... )
        [ FROM ( <Table> , ... ) ]
        [ WHERE <Expr> ]
        [ ORDER BY <Order> ]
        [ LIMIT <Count> ]

This is a blend of MySQL and PostgreSQL syntaxes in order to support
both.  MySQL allows multiple tables to be updated in one statement and
does not support the FROM clause, while PostgreSQL allows only one
table but supports FROM.  No normalisation is provided (any attempt
would be messy), so you must use the appropriate syntax for your DB.

C<ONLY> is for PostgreSQL only, while C<IGNORE>, C<LIMIT>, and
C<ORDER BY> are MySQL.

See also
L<< "<Column>" >>,
L<< "<Count>" >>,
L<< "<Expr>" >>,
L<< "<Order>" >>,
L<< "<TableAs>" >>.


=head2 <DELETE Stmt>

    DELETE [ IGNORE ]
        FROM [ ONLY ] ( <Table> , ... )
        [ USING ( <Table> , ... ) ]
        [ WHERE <Expr> ]
        [ ORDER BY <Order> ]
        [ LIMIT <Count> ]

This is a blend of MySQL and PostgreSQL syntaxes in order to support
both syntaxes. C<ONLY> is for PostgreSQL only, while C<IGNORE>,
C<LIMIT>, and C<ORDER BY> are MySQL.

See also
L<< "<Count>" >>,
L<< "<Expr>" >>,
L<< "<Order>" >>,
L<< "<Table>" >>.


=head2 <CREATE TABLE Stmt>

    CREATE [ LOCAL | GLOBAL ] [ TEMPORARY ] TABLE <Table>
    [
      '(' ( <ColumnName> <ColumnSpec> | <TableConstraint> ) , ... ')'
    ]
    [ <TableOption> ... ]
    [ AS <SELECT Stmt> ]

See also
L<< "<ColumnSpec>" >>,
L<< "<Table>" >>,
L<< "<TableConstraint>" >>,
L<< "<TableOption>" >>.


=head3 <ColumnSpec>

    <Type> [ <ColumnAttr> ... ]

=over

=item <ColumnAttr>

   <TypeAttr>
 | <ColumnConstraint>


=item <ColumnConstraint>

 [ CONSTRAINT <Constraint> ]
 (
     <References>
 |   NULL               | NOT NULL
 |   PRIMARY KEY        | DROP PRIMARY KEY
 |   KEY                | DROP KEY
 |   UNIQUE             | DROP UNIQUE
 |   AUTO_INCREMENT     | DROP AUTO_INCREMENT
 |   DEFAULT <Expr>     | DROP DEFAULT
 |   CHECK '(' Expr ')' | DROP CHECK
 |   COMMENT <Expr>     | DROP COMMENT
 |   COLUMN_FORMAT ( FIXED | DYNAMIC | DEFAULT )
 |   STORAGE       ( DISK  | MEMORY  | DEFAULT )
 )

The non-standard negative forms C<DROP ...> can be used in
modification of existing ColumnSpec objects to remove the
corresponding constraint.

The constraints C<AUTO_INCREMENT>, C<COMMENT>, C<COLUMN_FORMAT>, and
C<STORAGE> are MySQL extensions.

=item <References>

 REFERENCES <Table> '(' <ColumnName> , ... ')'
 [ MATCH ( SIMPLE | PARTIAL | FULL ) ]
 [ ON DELETE <OnAction> ]
 [ ON UPDATE <OnAction> ]

=item <OnAction>

 RESTRICT | CASCADE | SET NULL | SET DEFAULT | NO ACTION

=back

See also
L<< "<Type>" >>,
L<< "<TypeAttr>" >>.

=head3 <TableConstraint>

 [ CONSTRAINT <Constraint> ]
 (
     PRIMARY KEY '(' <ColumnIndex> , ... ')' [ <IndexOption> ... ]
 |   UNIQUE      '(' <ColumnIndex> , ... ')' [ <IndexOption> ... ]
 |   FULLTEXT    '(' <ColumnIndex> , ... ')' [ <IndexOption> ... ]
 |   SPATIAL     '(' <ColumnIndex> , ... ')' [ <IndexOption> ... ]
 |   INDEX       '(' <ColumnIndex> , ... ')' [ <IndexOption> ... ]
 |   FOREIGN KEY '(' <ColumnName>  , ... ')' <References>
 |   CHECK       '(' <Expr> ')'
 )

=head3 <ColumnIndex>

 <ColumnName> [ '(' <Count> ')' ] [ ASC | DESC ]

=head3 <IndexOption>

 USING ( BTREE | HASH | RTREE )

=head3 <TableOption>

   ENGINE                <Engine>
 | DEFAULT CHARACTER SET <CharSet>
 | DEFAULT COLLATE       <Collate>
 | AUTO_INCREMENT        <Expr>
 | COMMENT               <Expr>
 | ON COMMIT ( PRESERVE ROWS | DELETE ROWS | DROP )
 | [ 'TableOption' ] <Perl>


=head2 <ALTER TABLE Stmt>

  ALTER [ ONLINE | OFFLINE ] [IGNORE] TABLE [ONLY] <Table>
  ( <AlterTableOption> , ... )

See also
L<< "<Table>" >>.

=over

=item <AlterTableOption>

   RENAME TO         <Table>
 | ADD    <TableConstraint>
 | ADD    COLUMN     '(' <ColumnName> <ColumnSpec> , ... ')'
 | ADD    COLUMN     <ColumnName>              <ColumnSpec> [ <ColumnPos> ]
 | MODIFY COLUMN     <ColumnName>              <ColumnSpec> [ <ColumnPos> ]
 | CHANGE COLUMN     <ColumnName> <ColumnName> <ColumnSpec> [ <ColumnPos> ]
 | ALTER  COLUMN     <ColumnName> <AlterColumn>
 | DROP   COLUMN     <ColumnName> [ RESTRICT | CASCADE ]
 | RENAME COLUMN     <ColumnName> TO <ColumnName>
 | DROP   CONSTRAINT <Constraint> [ RESTRICT | CASCADE ]
 | DROP   PRIMARY KEY

MODIFY and CHANGE are MySQL extensions, which does not know about some
of the ALTER COLUMN stuff, which PostgreSQL uses.  It is almost
impossible to specify something useful that's understood by both DB
systems, it seems.

Other MySQL extensions: <ColumnPos>, multi-column syntax.

Other PostgreSQL extensions: TYPE and a few other things this
module does not yet support.

=item <ColumnPos>

 FIRST | AFTER <ColumnName>

=item <AlterColumn>

   SET DEFAULT <Expr> | DROP DEFAULT
 | TYPE <Type> [ USING <Expr> ]
 | SET NOT NULL | DROP NOT NULL

=back


=head2 <DROP TABLE Stmt>

  DROP [ TEMPORARY ] TABLE ( <Table> , ... ) [ RESTRICT | CASCADE ]

See also
L<< "<Table>" >>.


=head2 <Stmt>

The alternatives are described under in the following sections:

=over

=item L<< "<SELECT Stmt>" >>

=item L<< "<INSERT Stmt>" >>

=item L<< "<UPDATE Stmt>" >>

=item L<< "<DELETE Stmt>" >>

=item L<< "<CREATE TABLE Stmt>" >>

=item L<< "<ALTOR TABLE Stmt>" >>

=item L<< "<DROP TABLE Stmt>" >>

=back

See also L<"Statement Interpolation">.


=head2 <Join>

    CROSS                   JOIN ( <TableAs> , ... )
    UNION                   JOIN ( <TableAs> , ... )

    NATURAL       [ INNER ] JOIN ( <TableAs> , ... )
    NATURAL LEFT  [ OUTER ] JOIN ( <TableAs> , ... )
    NATURAL RIGHT [ OUTER ] JOIN ( <TableAs> , ... )
    NATURAL FULL  [ OUTER ] JOIN ( <TableAs> , ... )

                  [ INNER ] JOIN ( <TableAs> , ... ) <LinkCond>
            LEFT  [ OUTER ] JOIN ( <TableAs> , ... ) <LinkCond>
            RIGHT [ OUTER ] JOIN ( <TableAs> , ... ) <LinkCond>
            FULL  [ OUTER ] JOIN ( <TableAs> , ... ) <LinkCond>

                           'Join' <Perl>

=over

=item <LinkCond>

   ON <Expr>
 | USING '(' <Column> , ... ')'

=item <TableAs>

 <Table> [ AS <TableName> ]

=back

See also
L<< "<Column>" >>,
L<< "<Expr>" >>,
L<< "<Perl>" >>,
L<< "<Table>" >>,
L<< "<TableName>" >>,
L<"Join Interpolation">.

Note that C<< <Join> >> is always parsed in list context.

When producing SQL, this package always qualifies a JOIN with exactly
one of C<CROSS>, C<UNION>, C<INNER>, C<LEFT>, C<RIGHT>, and C<FULL>,
with the exception than instead of C<NATURAL INNER JOIN>, the
specification C<NATURAL JOIN> is printed for further compatibility
(e.g. with MySQL).

Note that MySQL, C<INNER JOIN> and C<CROSS JOIN> are not
distinguished, but in standard SQL, they are.  This module forces you
to write more portable SQL: use C<INNER JOIN> if there is an C<ON>
clause, and C<CROSS JOIN> if not.

=head2 <Order>

    ( <Column>
    | <Expr>
    | [ 'Order' ] <Perl> )
    [ ASC | DESC ]

Note that a string returned from a Perl interpolation is parsed as a
column name in <Order> position, but a plain string is parsed as a
plain string.

See also
L<< "<Column>" >>,
L<< "<Expr>" >>,
L<< "<Perl>" >>,
L<"GROUP BY / ORDER BY Interpolation">.


=head2 <Keyword>

   <a sequence of upper case characters, numbers, underscores>

Whether a keyword is a reserved word or not can be looked up on the
SQL standard.  Basically, if it marks up statements or special syntax
like infix operators, it is reserved, e.g. SELECT or ESCAPE.


=head2 <Identifier>

   <a sequence of lower case characters, numbers, underscores>
 | '`' <a sequence of any characters except newline and `> '`'
 | <Perl>

See also
L<< "<Perl>" >>,
L<"Identifier Name Translation">.


=head2 <TableName>

   <Identifier>
 | <Perl>

See also
L<< "<Identifier>" >>,
L<< "<Perl>" >>,
L<"Identifier Name Translation">.


=head2 <Table>

   [ [ <Identifier> '.' ] <Identifier> '.' ] <TableName>
 | [ 'Table' ] <Perl>

Table specifications are constructed by maximally three components,
the last of which is the table name, the last-but-first is the schema,
the last-but-second is the catalog.  All but the table name are
optional.

See also
L<< "<Identifier>" >>,
L<< "<Perl>" >>,
L<< "<TableName>" >>,
L<"Table Interpolation">,
L<"Identifier Name Translation">.


=head2 <ColumnName>

   <Identifier>
 | <Perl>

See also
L<< "<Identifier>" >>,
L<< "<Perl>" >>,
L<"Identifier Name Translation">.


=head2 <Column>

   [ <Table> '.' ] ( <ColumnName> | '*' )
 | [ 'Column' ] <Perl>

See also
L<< "<Identifier>" >>,
L<< "<Perl>" >>,
L<< "<Table>" >>,
L<"Column Interpolation">,
L<"Identifier Name Translation">.


=head2 <Perl>

For the exact syntax, check your Perl manual, but to get the idea, the
following items are examples for valid Perl interpolations:

   <Integer>
   <String>
   <Variable>
   { ...PerlCode... }

=over

=item <Integer>

 99
 0xff
 077
 0b111
 ...

=item <String>

 'string'
 "string"
 "string with $var"
 "string with \n escape"
 ...

=item <Variable>

 $var
 $var[1]
 $var{1}
 $var->{boo}
 $var->{boo}[0]('test')
 @var
 @var[1..2]
 %var
 ...

=back

L<Text::Balanced|Text::Balanced>::extract_variable() is used for
extraction of the sigil tokens,
L<Text::Balanced|Text::Balanced>::extract_delimited() is used for
extracting the strings, and
L<Text::Balanced|Text::Balanced>::extract_codeblock() is used for
extracting Perl code enclosed in braces.

The package distinguishes the different interpolation forms in
context, e.g. might handle hashes differently from arrays, or produce
error message for inappropriate literals but not for others.  For this
reason, Perl casts are handled as well:

   ${ ...PerlCode... }
   @{ ...PerlCode... }
   %{ ...PerlCode... }

Decimal numbers are not modified but parsed as strings so that
arbitrarily large numbers are supported as literals.

See also L<"Perl Interpolation">.


=head2 <Expr>

   '?'
 | NULL
 | TRUE
 | FALSE
 | UNKNOWN
 | DEFAULT
 | <Column>
 | [ 'Expr' ] <Perl>
 | '(' <Expr> ')'
 | <SubQuery>
 | <Functor> '(' [ <Expr> , ... ] ')'
 | <ExprSpecialFunc>
 | <Prefix> <Expr>
 | <Expr> <Suffix>
 | <Expr> <Infix> <Expr>
 | <ExprCase>

=over

=item <Functor>

 <an unknown, non-reserved <Keyword> >

See below for more information.

=back

See also
L<< "<Column>" >>,
L<< "<ExprCase>" >>,
L<< "<ExprSpecialFunc>" >>,
L<< "<Infix>" >>,
L<< "<Keyword>" >>,
L<< "<Perl>" >>,
L<< "<Prefix>" >>,
L<< "<SubQuery>" >>,
L<< "<Suffix>" >>,
L<"Expression Interpolation">.

As mentioned already, literal constant values have Perl syntax, and
Perl interpolations are allowed at any place.

SQL has a few special literals that are always recognised although
they may be semantically or even syntactically misplaced.  SQL will
tell you, this package does not check this.

In order to support all the functions and operators of any SQL dialect
that might be used, expression syntax in general does not follow Perl,
but SQL syntax.  Otherwise, it would be necessary to translate Perl to
the SQL dialect in use, but this package is not mainly meant to
normalise SQL, but to embed whatever dialect you are using into Perl,
making injections impossible, and thus making SQL usage safe.  See
L<"Normalisation">.

So this package tries to parse SQL expressions with as little
knowledge as possible.  This means sacrificing early error detection,
of course: many syntax errors in expressions will only be found by the
SQL server.  We only parse as much as to ensure easy and safe Perl
code interpolation.

However, this package assigns B<no precedence> to any of the operators,
meaning you have to B<use parenthesis>.  This was done for two reasons:
(1) to find bugs, (2) to handle C<=> uniformly in C<UPDATE...SET> and
C<SELECT> statements: in the former, C<=> has very low precedence and
is an assignment operator, while in the latter C<=> has medium
priority and is an equality operator.  We would like to handle the two
uniformly so that you can write:

    my $x= sqlExpr{ a = 5 };
    my $q= sql{
        SELECT $x
    };
    my $q2= sql{
        UPDATE tab1 SET $x
    };

This is especially interesting for handling hash interpolation
uniformly in these two cases.  It was felt that the exact precedence
order of SQL is a mystery to many Perl programmers anyway (as is the
precedence of the operators in Perl itself C<:-P>), so using parens
wasn't felt too high a price to pay.  (There's a hack to enable some
precedence parsing for the most common operators, but that's kept a
secret until enough people complain.)

Known known associative and commutative operators may be used in
sequence without parenthesis.

    1  +  2  +  3      # OK: associative and commutative
    1  -  2  -  3      # ERROR: not associative
    1  +  2  -  3      # ERROR: mixing is never allowed
    1 AND 2 AND 3      # OK: associative and commutative
    1 AND 2 OR  3      # ERROR: mixing
    1  <  2  <  3      # ERROR: not associative

To make life easier for Perl programmers, the C<==> and C<!=>
operators are recognised as aliasses for C<=> and C<< <> >>, resp.
There are B<no aliasses> for C<&&> and C<||>, because C<||> has a
special meaning in standard SQL, namely string concatenation.

Any unrecognised keywords and symbols have a default behaviour when
parsing embedded SQL: they are functors:

    CONCAT(A,B,@C,$D)

See also L<"Expression Interpolation">

Missing: PostgreSQL ROW(<Expr> , ...) or simply (<Exp> , ...) values.
The former works, because ROW is an unknown keyword and thus is
treated like a function call, which actually produces the right result
here, although it's a constructor term.

Missing: <Column>.<Field> This is tricky because the package doesn't
really understand identifier chains, so it treats the last component
as a column name, the second-to-last as a table name, etc.  Specifying
a field name will disturb and counting and the result will be wrong.
(Often, you won't notice, but it will be wrong regardless.)

=head3 <Prefix>

   +
 | -
 | NOT
 | ANY | SOME | ALL
 | AND | OR

C<ANY>, C<SOME>, and C<ALL> must follow a comparison operator and must
precede a subquery.

C<AND>, C<OR> as prefix operators are extensions for easy Perl
interpolation.

See also L<"Interpolation of Unary Operators">.


=head3 <Infix>

   '+' | '-'
 | '*' | '/'
 | AND | OR | XOR
 | '=' | '<>' | '<=' | '>=' | '<' | '>' | '==' | '!='
 | OVERLAPS
 | IS DISTINCT FROM
 | '||'
 | '^' | '**'

C<==> and C<!=> are normalised to C<=> and C<< <> >>, resp.

The following are extensions of MySQL: C<^>, C<XOR>.

The following is an extension of Oracle: C<**>.

See also L<"Array Interpolation in Expressions">.


=head3 <Suffix>

   IS [NOT] [ NULL | TRUE | FALSE | UNKNOWN | NORMALIZED ]
 | IS [NOT] A SET
 | IS [NOT] OF '(' <Type> , ... ')'
 | [NOT] BETWEEN [ SYMMETRIC | ASYMMETRIC ] <Expr> AND <Expr>
 | [NOT] [ LIKE | CLIKE | SIMILAR TO ] <Expr> [ ESCAPE <Expr> ]
 | [NOT] IN <ExprList>
 | [NOT] IN <SubQuery>

You can use C<NORMALISED> as an alias for C<NORMALIZED>.  It will
be normalised. :-)

See also L<"Interpolation of Unary Operators">,
L<< "<Expr>" >>,
L<< "<ExprList>" >>,
L<< "<SubQuery>" >>,
L<< "<Type>" >>.


=head3 <ExprSpecialFunc>

   CAST        '(' <Expr> AS <Type> ')'
 | TREAT       '(' <Expr> AS <Type> ')'
 | TRANSLATE   '(' <Expr> AS <Transliteration> ')'
 | POSITION    '(' <Expr> IN <Expr> [ USING <CharUnit> ] ')'
 | SUBSTRING   '(' <Expr> FROM <Expr> [ FOR <Expr> ] [ USING <CharUnit> ] ')'
 | CHAR_LENGTH '(' <Expr> [ USING <CharUnit> ] ')'
 | OVERLAY     '(' <Expr> PLACING <Expr> FROM <Expr> [ FOR <Expr> |
                   [ USING <CharUnit> ] ')'
 | CONVERT     '(' <Expr> USING <Transcoding> ')'
 | EXTRACT     '(' <Expr> FROM <Expr> ')'
 | UNNEST      '(' <Expr> ')' [ WITH ORDINALITY ]

See also
L<< "<CharUnit>" >>,
L<< "<Expr>" >>,
L<< "<Transcoding>" >>,
L<< "<Transliteration>" >>,
L<< "<Type>" >>.

Instead of CHAR_LENGTH, you can also use CHARACTER_LENGTH.


=head3 <ExprCase>

   CASE
     (
       [ <WhenExpr> , ... ]
     | <Expr> [ <WhenCase> , ... ]
     )
     [ ELSE <Expr> ]
     END

Note that in contrast to standard SQL, zero WHEN...THEN... pairs are
excepted.  If there are indeed zero, the whole CASE...END block is
reduced to the ELSE expression.

See also
L<< "<Expr>" >>,
L<< "<WhenCase>" >>,
L<< "<WhenExpr>" >>.


=head3 <WhenExpr>

    WHEN <Expr> THEN <Expr>

See also
L<< "<Expr>" >>.


=head3 <WhenCase>

    <WhenExpr>
  | WHEN <Check> THEN <Expr>

See also
L<< "<WhenExpr>" >>,
L<< "<Expr>" >>,
L<< "<Check>" >>.


=head3 <Check>

  | <Suffix>
  | <Infix> <Expr>
  | [ 'Check' ] <Perl>

Only operators returning boolean results are allowed here.

See also
L<< "<Expr>" >>,
L<< "<Infix>" >>,
L<< "<Suffix>" >>.


=head3 <ExprList>

   '(' <Expr> , ... ')'
 | <Perl>

See also
L<< "<Expr>" >>,
L<< "<Perl>" >>,
L<"Expression List Interpolation">.


=head3 <SubQuery>

    '(' <SELECT Stmt> ')'
  | '(' [ 'Stmt' ] <Perl> ')'

See also
L<< "<SELECT Stmt>" >>,
L<< "<Perl>" >>.


=head2 <Type>

     <BaseType>        [ <TypeAttr> ... ]
   | [ 'Type' ] <Perl> [ <TypeAttr> ... ]
   | <Type> ARRAY    [ '[' <Integer> ']' ]
   | <Type> MULTISET

=over

=item <TypeAttr>

     <BaseType>
   | <Precision>
   | <IntAttr>
   | <LargeLength>
   | <CharSetAttr>
   | <CollateAttr>
   | <WithTimeZone>
   | [ 'Type' ] <Perl>

So in contrast to SQL, attributes and even base types can be mixed and
given in any order after an initial base type or Perl interpolation.
The order will be normalised when printing SQL, of course.  The reason
why this change was made is that it allows the modification of types
stored in Perl.  See L<"Type Interpolation">.

Not all combination of type attributes are accepted.  What's accepted
depends on the read-dialect used.  Check your SQL manual for details.

=item <BaseType>

   INT | BIGINT | SMALLINT | TINYINT | MEDIUMINT | NUMERIC
 | DECIMAL | NUMBER | FLOAT | REAL | DOUBLE PRECISION
 | CHAR | VARCHAR | CLOB | TEXT | TINYTEXT | MEDIUMTEXT | LONGTEXT
 | NCHAR | NCHAR VARYING | NCLOB
 | BIT | BIT VARYING
 | BYTE | BINARY | VARBINARY | BLOB | TINYBLOB | MEDIUMBLOB | LONGBLOB
 | DATE | DATETIME | YEAR | TIME | TIMESTAMP | MONEY | BYTEA | UUID
 | POINT | LINE | LSEG | BOX | PATH | POLYGON | CIRCLE |
 | IRDR | INET | MACADDR
 | ENUM '(' <Expr> , ... ')'
 | SET  '(' <Expr> , ... ')'

Many of these types depend on the selected read-dialect and are not
standard SQL.

=item <Precision>

 '(' <Integer> [ ',' <Integer> ] ')'

=item <LargeLength>

 '(' <Integer> [ <IntMul> ] [ <CharUnit> ] ')

=item <IntMul>

 K | M | G

=item <IntAttr>

   SIGNED | UNSIGNED | DROP SIGN
 | ZEROFILL          | DROP ZEROFILL

The C<DROP ...> extensions can be used to remove the corresponding
type attribute completely when modifying types.

=item <WithTimeZone>

   WITH [LOCAL] TIME ZONE
 | WITHOUT TIME ZONE
 | DROP TIME ZONE

C<DROP TIME ZONE> is an extension so you can remove the type attribute
completely when modifying types.

=item <CharSetAttr>

   CHARACTER SET <CharSet>
 | DROP CHARACTER SET

C<DROP CHARACTER SET> is an extension so you can remove the type attribute
completely when modifying types.

Aliases:

   ASCII   = CHARACTER SET latin1
 | UNICODE = CHARACTER SET ucs2

=item <CollateAttr>

   COLLATE <Collate>
 | NO COLLATE

C<NO COLLATE> is an extension so you can remove the type attribute
completely when modifying types.

=back

Aliases (will be normalised to main form):

   DEC                 = DECIMAL
   FIXED               = DECIMAL
   INTEGER             = INT
   CHARACTER           = CHAR
   CHAR VARYING        = VARCHAR
   CHAR LARGE OBJECT   = CLOB
   NATIONAL CHAR       = NCHAR
   VARNCHAR            = NCHAR VARYING
   CHAR BYTE           = BINARY
   BINARY VARYING      = VARBINARY
   NCHAR LARGE OBJECT  = NCLOB
   BINARY LARGE OBJECT = BLOB
   BOOL                = BOOLEAN
   VARBIT              = BIT VARYING
   []                  = ARRAY
   [ <Integer> ]       = ARRAY [ <Integer> ]

The following are extensions and not standard SQL:

MySQL extensions: TINYINT, MEDIUMINT, *INT types with <Length>,
UNSIGNED, SIGNED, ZEROFILL, BIT, BINARY, VARBINARY, TEXT,
TINYTEXT, MEDIUMTEXT, LONGTEXT, TINYBLOB, MEDIUMBLOB, LONGBLOB,
ENUM, SET

Postgres extensions: MONEY, BYTEA, UUID, IRDR, INET, MACADDR, POINT,
LINE, LSEG, BOX, PATH, POLYGON, CIRCLE

Missing PostgreSQL: INTERVAL, XML, ENUM (CREATE TYPE).

=head2 <ColumnSpec>

     <Type>
   | [ 'ColumnSpec' ] <Perl>
   | <ColumnSpec> ( <ColumnSpecAttr> ... )

=over

=item <ColumnSpecAttr>

   NULL | NOT NULL
 | DEFAULT <Expr>
 | AUTO_INCREMENT | NO AUTO_INCREMENT
 | UNIQUE [KEY] | [ NOT UNIQUE | NO UNIQUE KEY ]
 | PRIMARY | NOT PRIMARY
 | KEY | NO KEY
 | COMMENT <Expr>
 | COLUMN_FORMAT [ FIXED | DYNAMIC | DEFAULT ]
 | STORAGE [ DISK | MEMORY | DEFAULT ]

Many of these are MySQL extensions.

=back

=head2 <CharUnit>

   CHARACTERS
 | CODE_UNITS
 | OCTETS


=head2 <Engine>

   <Identifier>


=head2 <CharSet>

   [ [ <Identifier> '.' ] <Identifier> '.' ] <Identifier>
 | [ 'CharSet' ] <Perl>


=head2 <Collate>

   [ [ <Identifier> '.' ] <Identifier> '.' ] <Identifier>
 | [ 'Collate' ] <Perl>


=head2 <Index>

   [ [ <Identifier> '.' ] <Identifier> '.' ] <Identifier>
 | [ 'Index' ] <Perl>


=head2 <Constraint>

   [ [ <Identifier> '.' ] <Identifier> '.' ] <Identifier>
 | [ 'Constraint' ] <Perl>


=head2 <Transliteration>

   [ [ <Identifier> '.' ] <Identifier> '.' ] <Identifier>
 | [ 'Transliteration' ] <Perl>


=head2 <Transcoding>

   [ [ <Identifier> '.' ] <Identifier> '.' ] <Identifier>
 | [ 'Transcoding' ] <Perl>


=head1 IMPLEMENTATION

This module is implemented with the L<Filter::Simple|Filter::Simple>
package.

The lexer uses the L<Text::Balanced|Text::Balanced> package for
extracting embedded Perl.

The parser for SQL statements is a hand-written recursive descent
parser.  The lexer shifts C<pos()> along as it scans the text, so the
interface is well-suited for L<Text::Balanced|Text::Balanced>.  The
author particularly likes pattern matching with C<m/\G.../gc>.


=head1 SEE ALSO

This module uses or is related to L<Filter::Simple|Filter::Simple>,
L<Text::Balanced|Text::Balanced>, and L<DBI|DBI>.

There is a similar, smaller module that also uses source filtering:
L<SQL::Interpolate::Filter|SQL::Interpolate::Filter>.  Similar to this
module, it is activated by quotelike syntax, and it also uses the
'sql' prefix.  (This is a coincidence, but then, what other prefix
would you naturally use?)  It is somewhat different from our approach,
as it replaces variable names with bind places and does not really
parse the complete SQL syntax, so it only handles values, not, say,
column names, join clauses, etc..  It also only parses complete
statements -- the parser cannot be requested to parse a single
expression only.

A similar idea but without source filtering can be found in
L<SQL::Interpolate|SQL::Interpolate> (with the older name
L<SQL::Interp|SQL::Interp>).

Another module that uses source filtering is
L<SQL::PreProc|SQL::PreProc>.  It uses a different approach and allows
using SQL statements directly in source code, without special markup
around it.  This leads to a different programming paradigm and looks
very different from plain DBI usage.

Another source filter is L<Filter::SQL|Filter::SQL>, which, like
L<SQL::PreProc|SQL::PreProc> embeds statements directly into Perl
without special markup.

Different approaches for making SQL usage safe are found in
L<SQL::Abstract|SQL::Abstract> and L<SQL::DB|SQL::DB>, which provide
SQL queries with a Perl-style interface, so the queries don't look
like SQL anymore, but are also safe to use without possibility of SQL
injections.


=head1 BUGS

Source filters are usually fragile, meaning that you I<can> write Perl
code that breaks the filter.  To do it properly, it would be necessary
to plug into the Perl parser itself.  For example, currently,
C<${sql{a}}> (for C<$sql{a}>) will trigger filtering.  (And even
C<$sql{a}> needed a hack to make it work.)

Moreover, unfortunately, it was unfeasible to use Filter::Simple in
C<code_no_comments> mode, because that filter is way to slow.  This
means that C<sql{...}> is also considered inside comments and strings.

The supported syntax is currently mainly based on MySQL, and while I
also looked at PostgreSQL and the SQL-2003 specs sometimes, I am
pretty sure that a lot of useful stuff is missing for many DBs.
Please don't hesitate to tell me what you're using so I can add it.

Finally, the resulting Perl code could be optimised more.  This is
on my TODO list.

There are some pretty bad problems when C<sql{...}> is used inside
comments.  This may lead to syntax errors, because line breaks might
be introduced.  A more understanding parser I experimented with was
too slow to be used in practice.  This needs more work.  Sorry!


=head2 Missing Syntax

C<UNION> is missing.

C<WITH ... SELECT> is not yet implemented.

The MySQL C<REPLACE> command is currently not supported; it is an
extension.  You can use C<DELETE>+C<INSERT> instead, which is more
portable anyway.  The C<REPLACE> command will nevertheless be added
later.

Several other SQL commands are also missing.


=head1 AUTHOR

Henrik Theiling <cpan@theiling.de>


=head1 COPYRIGHT AND LICENSE

Copyright by Henrik Theiling <cpan@theiling.de>

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

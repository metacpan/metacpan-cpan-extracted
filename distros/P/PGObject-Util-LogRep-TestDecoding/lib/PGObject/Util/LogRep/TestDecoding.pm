package PGObject::Util::LogRep::TestDecoding;

use 5.034;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';
use Parse::RecDescent;
use Moo;
use Types::Standard qw(Maybe ArrayRef Str Bool Int);
use namespace::autoclean;

=head1 NAME

PGObject::Util::LogRep::TestDecoding - Parse Pg's test_decoding messages

=head1 VERSION

Version 0.1.4

=cut

our $VERSION = '0.1.4';


=head1 SYNOPSIS

    use PGObject::util::LogRep::TestDecoding qw(parse_msg);

    my $msg = parse_msg($repmsg); # procedural interace
    # tells you the operation, transaction status etc.

    # or the OO interface which gives more functionality

    my $decoder = PGObject::util::LogRep::TestDecoding->new(
        schema=> ['myschema'], txn_status => 0
    );
    handle_message($decoder->parse($repmsg)) if $decoder->matches($repmsg);

=head1 DESCRIPTION

This module provides parse capabiltiies for the test_decoding plugin for
PostgreSQL's logical replication.  The test_decoding plugin does not recognize
or handle publications and simply replicates everything.

Messages follow formats like:

  table public.data: INSERT: id[integer]:3 data[text]:'5'

or for begin or commit messages:

  BEGIN 529
  COMMIT 529

Transactions are always processed sequentially in the test decoding stack.

This module can be combined with C<AnyEvent::PGRecvLogical> to create programs
which process PostgreSQL's logical replication streams.

Note that PostgreSQL's logical replication sends out transactions in commit
order and this module assumes that it will process most messages if transaction
information is important (which it might not be for some applications).

=head1 EXPORT

=over

=item parse_msg # single message / non-OO parser

=back

=cut

BEGIN { our @EXPORT_OK = ('parse_msg'); }

=head1 ATTRIBUTES/ACCESSORS

These are for the OO interface only.  These are read-ony after the object is
created but can be set in the constructor.  If you need to change them. create
a new object instead.

=head2 schema Maybe[ArrayRef[Str]]

Undef or an arrayref of schalars.  If it is set, then matches returns true if
the message matches any table in any schema mentioned.

=cut

has schema => (is => 'ro', isa => Maybe[ArrayRef[Str]]);

=head2 txn_status Bool

Whether to report transactoin status.

=cut

has txn_status => (is => 'ro', isa => Bool);

=head2 tables Maybe[ArrayRef[Str]]

A list of fully qualified tablenames to match against.  Note that this filter
operates along with the schema filter and if either matches, the match is
met.

=cut

has tables => (is => 'ro', isa => Maybe[ArrayRef[Str]]);

=head2 current_txn (calculated)

Logical replication sends messages out for transactions in commit order.
Assuming the transaction numbers have been requested, this will produce the
transaction number of the most recent BEGIN statement.  Note that this
information is only available when certain options are passed so it may return
C<undef>.

=cut

has current_txn => (is => 'rw', writer => '_set_current_txn');

=head1 GRAMMAR

Test_decoding lines come in two basic formats:  transaction control lines and
DML lines.  The former have a syntax like C<BEGIN 123> (or COMMIT).

The DML records have a longer and more complex.  They have a format begins with
the word "table" followed by a fully qualified tablename, then an operation,
then a column list in name[type]:value format.  Identifiers can be SQL escaped.
So can literals.

Since transactions are handled sequentially in commit order, the DML records do
not carry transaction identifiers in them.

=cut


my $grammar = <<'_ENDGRAMMAR' ;
           { my $retval = {}; 1; }
    record : dmlrec | txnrec
           { $retval; }
    txnrec : txncmd txnid(?)
           { $retval->{"txn_cmd"} = $item[1]; $retval; } 
           { $retval->{"type"} = "txn"; $retval; }
    dmlrec : header operation ":" col(s)
           { $retval->{"type"} = "dml"; $retval; }
           { $retval->{"operation"} = $item{operation}; $retval }
    header : "table " schema "." tablename ": "
    col : column(s)
    schema : sqlident
           { $retval->{"schema"} = $item[1]; $retval; }
    tablename : sqlident
           { $retval->{"tablename"} = $item[1]; $retval; }
    column : /\s?/ colname "[" coltype "]" ":" value
           { $retval->{row_data}->{$item{"colname"}} = $item{"value"} }
    colname : sqlident
    coltype : schemaq(?) sqlident array(?)
    schemaq : sqlident '.'
    array   : '[]'
    value   : literal
    sqlident : /[a-zA-Z0-9()_ ]+/ | /"([^"]|"")+"/
    literal : /\w+/ | /'([^']|'')+'/
    txnid : /\d+/
           { $retval->{txnid} = $item[1]; $retval; }
    txncmd : "BEGIN" | "COMMIT"
    operation : "INSERT" | "UPDATE" | "DELETE"
_ENDGRAMMAR



=head1 SUBROUTINES/METHODS

=head2 output

The Parsing routines return a consistent payload in the form of a hashref with
one of two formats depending on the message type.  Both forms have a "type"
field which is set to "txn" or "dml" depending on the record type.

=head3 txn messages

The txn message output has three fields:

=over

=item type = txn

=item txnid 

Integer, may be omitted if data not available

=item txncmd

Either BEGIN or COMMIT

=back

Examples:

  { type   => "txn",
    txncmd => "BEGIN',
    txnid  => 50123 }

  { type   => "txn",
    txncmd => "COMMIT',
    txnid  => 50123 }

Or if transaction numbers are not available"

  { type   => "txn",
    txncmd => "BEGIN' }

=head3 dml messages

The dml lessages have a number of fields:

=over

=item type = "dml"

=item schema

Namespace of the table

=item tablename 

Name of the table

=item row_data

A hashref of name => value.

=item operation

One of INSERT, UPDATE, or DELETE

=back

Examples:

  { type      => 'dml',
    tablename => 'sometable',
    schema    => 'public',
    row_data  => { id => 1, key => 'test', value => 123 },
    operation => 'INSERT' }

  { type      => 'dml',
    tablename => 'sometable',
    schema    => 'public',
    row_data  => { id => 1, key => 'test', value => 123 },
    operation => 'DELETE' }


=head2 parse (OOP interface)

In the OOP interface, the parse function parses the message and returns the
output.

=cut

sub _unescape {
    my ($val, $escape) = @_;
    return unless defined $val;
    return $val unless $val =~ /^$escape/;
    $val =~ s/(^$escape|$escape$)//g;
    $val =~ s/$escape{2}/$escape/g;
    return $val;
}

sub parse_msg {
    my ($msg) = @_;
    my $parser = new Parse::RecDescent ($grammar);
    my $parsed =  $parser->record($msg) || return;
    return $parsed if $parsed->{type} eq 'txn';
    for (qw(schema tablename)){
        $parsed->{$_} = _unescape($parsed->{$_}, '"');
    }
    my $rowdata = $parsed->{row_data};
    delete $parsed->{row_data};
    for (keys %{$rowdata}) {
        my $key = _unescape($_, '"');
        $parsed->{row_data}->{$key} = $rowdata->{$_} eq 'null' ? undef :
                                        _unescape($rowdata->{$_}, q('));
    }
    return $parsed;
}

sub parse {
    my ($self, $msg) = @_;
    my $parsed = parse_msg($msg) || warn "Invalid message $msg";
    if ($parsed->{type} eq 'txn') {
        $self->_set_current_txn($parsed->{txnid});
    }
    return $parsed;
}

=head2 matches (OOP Interface)

Evaluates whether the schema AND tablename match rules are met.  If the
message
is a txn message it will then be processed (and possibly affect the txnid
state).

Note that only txn messages are parsed here.

=cut

sub matches {
    my ($self, $msg) = @_;
    if ($msg =~ /^table /){
        if ($self->schema){
            for my $ns (@{$self->schema}){
                return 1 if $msg =~ /^table $ns\./;
            }
            for my $tn (@{$self->tables}){
                return 1 if $msg =~ /^table $tn:/;
            }
        }
    } else {
        $self->parse($msg);
        return 0;
    }
}

=head2 parse_msg

parse_msg parses the message provided and returns a hashref as detailed above.

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-util-logrep-testdecoding at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-util-LogRep-TestDecoding>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::util::LogRep::TestDecoding


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-util-LogRep-TestDecoding>

When submitting a bug, lease try to include the message that causes it.

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/PGObject-util-LogRep-TestDecoding>

=item * Search CPAN

L<https://metacpan.org/release/PGObject-util-LogRep-TestDecoding>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Chris Travers.

This program is released under the following license:

  BSD2


=cut

1; # End of PGObject::util::LogRep::TestDecoding

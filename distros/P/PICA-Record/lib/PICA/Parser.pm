package PICA::Parser;
{
  $PICA::Parser::VERSION = '0.585';
}
#ABSTRACT: Parse PICA+ data
use strict;

use base qw(Exporter);

use Carp qw(croak);
our @EXPORT_OK = qw(parsefile parsedata);
our @CARP_NOT = qw(PICA::PlainParser PICA::XMLParser);

require PICA::PlainParser;
require PICA::XMLParser;


sub new {
    my $class = "PICA::Parser";
    if (scalar(@_) % 2) { # odd
        $class = shift;
        $class = ref $class || $class;
    }
    my %params = @_;

    my $self = bless {
        defaultparams => {},
        xmlparser => undef,
        plainparser => undef
    }, $class;

    %{ $self->{defaultparams} } = %params if %params;

    return $self;
}


sub parsefile {
    my $self = shift;
    my ($arg, $parser);

    if (ref($self) eq 'PICA::Parser') { # called as a method
        $arg = shift;
        my %params = @_;
        if (ref(\$arg) eq 'SCALAR' and ($arg =~ /.xml$/i or $arg =~ /.xml.gz$/i)) {
            $params{Format} = "XML";
        }
        $parser = $self->_getparser( %params );
        croak("Missing argument to parsefile") unless defined $arg;
        $parser->parsefile( $arg );
        $self;
    } else { # called as a function
        $arg = ($self eq 'PICA::Parser') ? shift : $self;
        croak("Missing argument to parsefile") unless defined $arg;
        $parser = PICA::Parser->new( @_ );
        $parser->parsefile( $arg );
        $parser;
    }
}


sub parsedata {
    my $self = shift;
    my ( $data, $parser );

    if (ref($self) eq 'PICA::Parser') { # called as a method
        $data = shift;
        my %params = @_;
        $parser = $self->_getparser( %params );
        $parser->parsedata( $data );
        $self;
    } else { # called as a function
        $data = ($self eq 'PICA::Parser') ? shift : $self;
        $parser = PICA::Parser->new( @_ );
        $parser->parsedata( $data );
        $parser;
    }
}


sub records {
    my $self = shift;
    return () unless ref $self;

    return $self->{plainparser}->records() if $self->{plainparser};
    return $self->{xmlparser}->records() if $self->{xmlparser};

    return ();
}


sub counter {
    my $self = shift;
    return undef if !ref $self;

    my $counter = 0;
    $counter += $self->{plainparser}->counter() if $self->{plainparser};
    $counter += $self->{xmlparser}->counter() if $self->{xmlparser};
    return $counter;
}


sub enable_binmode_encoding {
    my $fh = shift;
    foreach my $layer ( PerlIO::get_layers( $fh ) ) {
        return if $layer =~ /^encoding|^utf8/;
    }
    binmode ($fh, ':utf8');
}


sub _getparser {
    my $self = shift;
    my %params = @_;
    delete $params{Proceed} if defined $params{Proceed};

    my $parser;

    # join parameters
    my %unionparams = ();
    my %defaultparams = %{ $self->{defaultparams} };
    my $key;
    foreach $key (keys %defaultparams) {
        $unionparams{$key} = $defaultparams{$key}
    }
    foreach $key (keys %params) {
        $unionparams{$key} = $params{$key}
    }
    # remove format parameter
    delete $params{Format} if defined $params{Format};

    # XMLParser
    if ( defined $unionparams{Format} and $unionparams{Format} =~ /^xml$/i ) {
        if ( !$self->{xmlparser} or %params ) {
            #require PICA::XMLParser; 
            #if ($self->{xmlparser} && 
            $self->{xmlparser} = PICA::XMLParser->new( %unionparams );
        }
        $parser = $self->{xmlparser};
    } else { # PlainParser
        if ( !$self->{plainparser} or %params ) {
            #require PICA::PlainParser; 
            $self->{plainparser} = PICA::PlainParser->new( %unionparams );
        }
        $parser = $self->{plainparser};
    }

    return $parser;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PICA::Parser - Parse PICA+ data

=head1 VERSION

version 0.585

=head1 SYNOPSIS

  use PICA::Parser;

  PICA::Parser->parsefile( $filename_or_handle ,
      Field => \&field_handler,
      Record => \&record_handler
  );

  PICA::Parser->parsedata( $string_or_function ,
      Field => \&field_handler,
      Record => \&record_handler,
      Limit => 5
  );

  $parser = PICA::Parser->new(
      Record => \&record_handler,
      Proceed => 1
  );
  $parser->parsefile( $filename );
  $parser->parsedata( $picadata );
  print $parser->counter() . " records read.\n";

You can also export C<parsedata> and C<parsefile>:

  use PICA::Parser qw(parsefile);

  parsefile( $filename, Record => sub {
      my $record = shift;
      print $record->string . "\n";
  });

Both function return the parser, so you can use
constructs like

  my @records = parsefile($filename)->records();

To parse just one record you can use the special method
writerecord which can be exported by PICA::Record:

  use PICA::Record qw(writerecord);
  my $record = writerecord( $file );

Another method is to limit the parser to one record:

  my ($record) = PICA::Parser->parsefile( $file, Limit => 1 )->records();

A PICA::Parser may emit some error messages to STDOUT 
but ignore most errors. If you want broken fields not to be 
ignored, add an error handler with FieldError:

  my $parser = PICA::Parser->new(
      FieldError => sub { my $msg = shift; return $msg; } 
  );

Broken record then will be passed to another error handler.
To suppress all error messages and just ignore records with errors:

  my $parser = PICA::Parser->new(
      FieldError => sub { return; },
      RecordError => sub { return; } 
  }

=head1 DESCRIPTION

This module can be used to parse normalized PICA+ and PICA+ XML.
The conrete parsers are implemented in L<PICA::PlainParser> and 
L<PICA::XMLParser>.

=head1 CONSTRUCTOR

=head2 new ( [ %params ] )

Creates a Parser to store common parameters (see below). These 
parameters will be used as default when calling C<parsefile> or
C<parsedata>. Note that you do not have to use the constructor to 
use C<PICA::Parser>. These two methods do the same:

  PICA::Parser->new( %params )->parsefile( $file );
  PICA::Parser->parsefile( $file, %params );

And for parsing plain data:

  PICA::Parser->new( %params )->parsedata( $data );
  PICA::Parser->parsedata( $data, %params );

Common parameters that are passed to the specific parser are:

=over

=item Field

Reference to a handler function for parsed PICA+ fields. 
The function is passed a L<PICA::Field> object and it should
return it back to the parser. You can use this function as a
simple filter by returning a modified field. If undef is 
returned, the field will be skipped. If a non L<PICA::Field> 
value is returned, the return value is used as error message
and the record is marked as broken.

=item Record

Reference to a handler function for parsed PICA+ records. The
function is passed a L<PICA::Record>. If the function returns
a record then this record will be stored in an array that is
passed to C<Collection>. You can use this method as a filter
by returning either a (modified) record or undef or an integer.
If another defined value is returned, it is used as error message
(broken record) and the record error handler is called.

=item Offset

Skip a given number of records. Default is zero.

=item Limit

Stop after a given number of records. Non positive numbers equal to unlimited.

=item FieldError

This handler is called with character data of a line and error message 
when an input line could not be parsed into a L<PICA::Field> object. 
By default such lines produce an error message on STDOUT but will be 
ignored. You can provide an error handler that either fixed the line by
returning a PICA::Field, or returns undef to ignore the error or return
true to mark the whole record as broken, so the RecordError handler will
be called afterwards.

=item RecordError

This handler is called with a record object or undef and an error message
when a broken record was parsed. By default only empty records are marked
as broken.

=item Proceed

By default the internal counters are reset and all read records are
forgotten before each call of C<parsefile> and C<parsedata>. 
If you set the C<Proceed> parameter to a true value, the same parser
will be reused without reseting counters and read record.

=back

Error handling is only implemented in L<PICA::PlainParser> by now!

=head1 METHODS

=head2 parsefile ( $filename-or-handle [, %params ] )

Parses pica data from a file, specified by a filename or filehandle.
The default parser is L<PICA::PlainParser>. If the filename extension 
is C<.xml> or C<.xml.gz> or the C<Format> parameter set to C<xml> then
L<PICA::XMLParser> is used instead. 

  PICA::Parser->parsefile( "data.picaplus", Field => \&field_handler );
  PICA::Parser->parsefile( \*STDIN, Field => \&field_handler, Format='XML' );
  PICA::Parser->parsefile( "data.xml", Record => sub { ... } );

See the constructor C<new> for a description of parameters.

=head2 parsedata ( $data [, %params ] )

Parses data from a string, array reference, function, or L<PICA::Record>
object and returns the C<PICA::Parser> that was used. See C<parsefile>
and the C<parsedata> method of L<PICA::PlainParser> and L<PICA::XMLParser>
for a description of parameters. By default L<PICA::PlainParser> is used
unless there the C<Format> parameter set to C<xml>.

  PICA::Parser->parsedata( $picastring, Field => \&field_handler );
  PICA::Parser->parsedata( \@picalines, Field => \&field_handler );

  # called as a function
  my @records = parsedata( $picastring )->records();

See the constructor C<new> for a description of parameters.

=head2 records ( )

Get an array of the read records (as returned by the record handler which
can thus be used as a filter). If no record handler was specified, records
will be collected unmodified. For large record sets it is recommended not
to collect the records but directly use them with a record handler.

=head2 counter ( )

Get the number of read records so far. Please note that the number
of records as returned by the C<records> method may be lower because
you may have filtered out some records.

=head1 INTERNAL METHODS

=head2 enable_binmode_encoding ( $handle )

Enable :utf8 layer for a given filehandle unless it or some other 
encoding has already been enabled. You should not need this method.

=head2 _getparser ( [ %params] )

Internal method to get a new parser of the internal parser of this object.
By default, gives a L<PICA:PlainParser> unless you specify the C<Format>
parameter. Single parameters override the default parameters specified at
the constructor (except the the C<Proceed> parameter).

=head1 TODO

Better logging needs to be added, for instance a status message every n records.
This may be implemented with multiple (piped?) handlers per record. Error handling
of broken records should also be improved.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Verbundzentrale Goettingen (VZG) and Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

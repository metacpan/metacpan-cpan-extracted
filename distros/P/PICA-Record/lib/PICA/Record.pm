package PICA::Record;
{
  $PICA::Record::VERSION = '0.585';
}
#ABSTRACT: Perl module for handling PICA+ records
use strict;
use utf8;
use 5.10.0;

use base qw(Exporter);
our @EXPORT = qw(readpicarecord writepicarecord);
our @EXPORT_OK = qw(picarecord pgrep pmap);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

our $XMLNAMESPACE = 'info:srw/schema/5/picaXML-v1.0';

our @CARP_NOT = qw(PICA::Field PICA::Parser);

use POSIX qw(strftime);
use PICA::Field;
use PICA::Parser;
use Scalar::Util qw(looks_like_number);
use URI::Escape;
use XML::Writer;
use Encode;
use PerlIO;
use Carp qw(croak confess);

use overload 
    'bool' => sub { ! $_[0]->empty },
    '""'   => sub { $_[0]->string };

use sort 'stable';


# private method to append a field
my $append_field = sub {
    my ($self, $field) = @_;
    # confess('append_failed') unless ref($field) eq 'PICA::Field';
    if ( $field->tag eq '003@' ) {
        $self->{_ppn} = $field->sf('0');
        if ( $self->field('003@') ) {
            $self->update( '003@', $field );
            return 0;
        }
    }
    # TODO: limit occ and iln, epn
    return 0 if $field->empty;

    push(@{ $self->{_fields} }, $field);
    return 1;
};

# private method to compile and cache a regular expression
my %field_regex;
my $get_regex = sub {
    my $reg = shift;

    return $reg if ref($reg) eq 'Regexp';

    my $regex = $field_regex{ $reg };

    if (!defined $regex) {
        # Compile & stash
        $regex = qr/^$reg$/;
        $field_regex{ $reg } = $regex;
    }

    return $regex;
};



sub new {
    my $class = shift; # if $_[0] and UNIVERSAL::isa( $_[0], 'PICA::Record'
    # shift if defined $_[0] and $_[0] eq $class; # called as function

    $class = $class || ref($class); # Handle cloning
    my $self = bless {
        _fields => [],
        _ppn => undef
    }, $class;

    return $self unless @_;

    my $first = $_[0];

    if (defined $first) {

        if ($#_ == 0 and ref(\$first) eq 'SCALAR') {
            my @lines = split("\n", $first);
            my @l2 = split("\x1E", $first);
            if (@l2 > @lines) { # normalized
                @lines = @l2;
            }

            foreach my $line (@lines) {
                $line =~ s/^\x1D//;         # start of record
                next if $line =~ /^\s*$/;   # skip empty lines

                my $field = PICA::Field->parse($line);
                $append_field->( $self, $field ) if $field;
            }
        } elsif (ref($first) eq 'GLOB' or eval { $first->isa('IO::Handle') }) {
            PICA::Parser->parsefile( $first, Limit => 1, Field => sub {
                $append_field->( $self, shift ); 
                return;
            });
        } else {
            $self->append( @_ );
        }
    } else {
        croak('Undefined parameter in PICA::Record->new');
    }

    return $self;
} # new()


sub copy {
    my $self = shift;
    return PICA::Record->new( $self );
}


sub field {
    my $self = shift;
    my $limit = looks_like_number($_[0]) ? shift : 0;
    my @specs = @_;

    my $test = ref($specs[-1]) eq 'CODE' ? pop @specs : undef;
    @specs = (".*") if $test and not @specs;

    return unless @specs;
    my @list = ();

    for my $tag ( @specs ) {
        my $regex = $get_regex->($tag);

        for my $maybe ( $self->fields ) {
            if ( $maybe->tag() =~ $regex ) {
                local $_ = $maybe;
                if ( not $test or $test->($maybe) ) {
                    return $maybe unless wantarray;
                    push( @list, $maybe );
                    if ($limit > 0) {
                        return @list unless --$limit;
                    }
                }
            }
        }
    }

    return @list;
} # field()

# Shortcut
*f = \&field;


sub subfield {
    my $self = shift;
    my $limit = looks_like_number($_[0]) ? shift : 0;
    return unless defined $_[0];

    my @list = ();

    while (@_) {
        my $tag = shift;
        my $subfield;
    
        croak "Not a field or full pattern: $tag" 
            unless $tag =~ /^([^\$_]{3,})([\$_]([^\$_]+))?/;
        if (defined $2) {
            ($tag, $subfield) = ($1, $3);
        } else {
            $subfield = shift;
        }

        croak("Missing subfield for $tag") 
            unless defined $subfield;

        my $tag_regex = $get_regex->($tag);
        for my $f ( $self->fields ) {
            if ( $f->tag() =~ $tag_regex ) {
                my @s = $f->subfield($subfield);
                if (@s) {
                    return shift @s unless wantarray;
                    if ($limit > 0) {
                        if (scalar @s >= $limit) {
                            push @list, @s[0..($limit-1)];
                            return @list;
                        }
                        $limit -= scalar @s;
                    }
                    push( @list, @s );
                }
            }
        }
    }

    return $list[0] unless wantarray;
    return @list;
} # subfield()

# Shortcut
*sf = \&subfield;


sub values {
    my $self = shift;
    my @values = $self->subfield( @_ );
    return @values;
}


sub fields() {
    my $self = shift;
    croak("You called all_fields() but you probably want field()") if @_;
    return @{$self->{_fields}};
}


sub size {
    my $self = shift;
    return 1 * @{$self->{_fields}};
}


sub occurrence {
    my $self = shift;
    return unless $self->{_fields}->[0];
    return $self->{_fields}->[0]->occurrence;
}

sub occ {
    return shift->occurrence;
}


sub main {
    my $self = shift;
    my @fields = $self->field("0...(/..)?");

    return PICA::Record->new(@fields);
}


sub holdings {
    my ($self, $iln) = @_;

    my %holdings = ();
    my @fields = ();
    my $prevtag;
    my $curiln = '';
    my @pending;
  
    foreach my $f (@{$self->{_fields}}) {
        next if $f->tag =~ /^0/;

        if ($f->tag eq '101@' and defined $f->sf('a')) {
            $curiln = $f->sf('a');
            $holdings{$curiln} //= [ ];
            if (@pending) {
                push @{ $holdings{$curiln} }, @pending;
                @pending = ();
            }
            push @{ $holdings{$curiln} }, $f;
        } elsif( $curiln eq '' ) {
            push @pending, $f;
        } else {
            push @{ $holdings{$curiln} }, $f;
        }

        push @fields, $f;
        $prevtag = $f->tag;
    }

    push @{ $holdings{$curiln} }, @pending if @pending;

    if ($iln) {
        %holdings = ($iln => $holdings{$iln});
        %holdings = () unless $holdings{$iln};
    }

    foreach my $iln (keys %holdings) {
        @{$holdings{$iln}} = sort {
            my ($ta,$tb) = ($a->tag, $b->tag);
            $ta =~ s{^(2...)/(..)$}{2$2$1};
            $tb =~ s{^(2...)/(..)$}{2$2$1};
            $ta cmp $tb;
        } @{$holdings{$iln}};
    }

    my @h =  sort { ($a->iln // '0') <=> ($b->iln // '0') } 
            map { PICA::Record->new( @$_ ) } CORE::values(%holdings);

    return $iln ? $h[0] : @h;
}


sub items {
  my $self = shift;

  my @copies = ();
  my @fields = ();
  my $prevocc;

  foreach my $f (@{$self->{_fields}}) {
      next unless $f->tag =~ /^[^0]/;

      if ($f->tag =~ /^1/) {
          $prevocc = undef;
          push @copies, PICA::Record->new(@fields) if (@fields);
          @fields = ();
      } else {
          next unless $f->tag =~ /^2...\/(..)/;

          if (!($prevocc && $prevocc eq $1)) {
              $prevocc = $1;
              push @copies, PICA::Record->new(@fields) if (@fields);
              @fields = ();
          }

          push @fields, $f;
      }
  }
  push @copies, PICA::Record->new(@fields) if (@fields);
  return @copies;
}


sub empty {
    my $self = shift;
    foreach my $field (@{$self->{_fields}}) {
        return 0 if !$field->empty;
    }
    return 1;
}


sub ppn {
    my $self = shift;
    if ( @_ ) {
        my $ppn = shift;
        if (defined $ppn) { 
            $append_field->( $self, PICA::Field->new('003@', '0' => $ppn) ) 
        } else {
            $self->remove('003@');
        }
    }
    return $self->{_ppn};
}


sub epn {
    my $self = shift;
    #for(my $i=0; $i<@_; $i++) {
    #    # TODO: add EPNs
    #}
    return $self->subfield('203@/..$0');
}


sub iln {
    # TODO: set ILN with this method and check uniqueness
    my $self = shift;
    return $self->subfield('101@$a');
}


sub append {
    my $self = shift;
    # TODO: this method can be simplified by use of ->new (see appendif)

    my $c = 0;

    while (@_) {
        # Append a field (whithout creating a copy)
        while (@_ and UNIVERSAL::isa($_[0],'PICA::Field') ) {
            $c += $append_field->( $self, shift );
        }
        # Append a whole record (copy all its fields)
        while (@_ and UNIVERSAL::isa($_[0],'PICA::Record')) {
            my $record = shift;
            for my $field ( $record->fields ) {
                $c += $append_field->( $self, $field->copy );
            }
        }
        if (@_) {
            my @params = (shift); # tag
            while (@_ and defined $_[0] and length($_[0]) == 1) {
                push @params, shift; # subfield
                push @params, shift; # value
            }
            $c += $append_field->( $self, PICA::Field->new( @params ) ) if @params > 1;
        }
    }

#use Data::Dumper;
#print Dumper(\@_)."\n";
#        local $Carp::CarpLevel = 1;


    return $c;
}


sub appendif {
    my $self = shift;
    my $append = PICA::Record->new( @_ );
    for my $field ( $append->fields ) {
        $field = $field->purged();
        $append_field->( $self, $field ) if $field;
    }
    $self;
}


sub update {
    my $self = shift;
    my $tag = shift;

    croak("Not a valid tag: $tag")
        unless PICA::Field::parse_pp_tag( $tag );

    my $replace;

    return unless @_; # ignore

    if ( not defined $_[0] ) {
        $replace = shift;
    } elsif ( UNIVERSAL::isa( $_[0], 'PICA::Field' ) or ref($_[0]) eq 'CODE' ) {
        $replace = shift;
    } else {
        $replace = PICA::Field->new($tag, @_);
    } 

    my $regex = $get_regex->($tag);

    for my $field ( $self->fields ) {
        if ( $field->tag() =~ $regex ) {
            my $rep = $replace;
            if ( UNIVERSAL::isa( $replace, 'CODE' ) ) {
                $rep = $rep->( $field );
                $rep = undef unless UNIVERSAL::isa( $rep, 'PICA::Field' );
            }
            if (defined $rep) {
                $self->{_ppn} = $rep->sf('0') if $rep->tag eq '003@';
                $field->replace( $rep );
            } 
            return unless ref($replace) eq 'CODE';
        }
    }
}


sub remove {
    my $self = shift;
    my @specs = @_;

    return 0 if !@specs;
    my $c = 0;

    for my $tag ( @specs ) {
        my $regex = $get_regex->($tag);

        my $i=0;
        for my $maybe ( $self->fields ) {
            if ( $maybe->tag() =~ $regex ) {
                $self->{_ppn} = undef if $maybe->tag() eq '003@';
                splice( @{$self->{_fields}}, $i, 1);
                $c++;
            } else {
                $i++;
            }
        }
    } # for $tag

    return $c;
}


sub sort {
    my $self = shift;

    my $main     = $self->main;
    my @holdings = $self->holdings;

    @{$self->{_fields}} = sort { $a->tag cmp $b->tag } @{$main->{_fields}};

    foreach my $h ( @holdings ) {
        push @{$self->{_fields}}, @{$h->{_fields}};
    }

    $self;
}


sub add_headers {
    my ($self, %params) = @_;

    my $eln = $params{eln};
    croak("add_headers needs an ELN") unless defined $eln;

    my $status = $params{status};
    croak("add_headers needs status") unless defined $status;

    my @timestamp = defined $params{timestamp} ? @{$params{timestamp}} : localtime;
    # TODO: Test timestamp

    my $hdate = strftime ("$eln:%d-%m-%g", @timestamp);
    my $htime = strftime ("%H:%M:%S", @timestamp);

    # Pica3: 000K - Unicode-Kennzeichen
    $self->append( "001U", '0' => 'utf8' );

    # PICA3: 0200 - Kennung und Datum der Ersterfassung
    # http://www.gbv.de/vgm/info/mitglieder/02Verbund/01Erschliessung/02Richtlinien/01KatRicht/0200.pdf
    $self->append( "001A", '0' => $hdate );

    # PICA3: 0200 - Kennung und Datum der letzten Aenderung
    # http://www.gbv.de/vgm/info/mitglieder/02Verbund/01Erschliessung/02Richtlinien/01KatRicht/0210.pdf
    $self->append( "001B", '0' => $hdate, 't' => $htime );

    # PICA3: 0230 - Kennung und Datum der Statusaenderung
    # http://www.gbv.de/vgm/info/mitglieder/02Verbund/01Erschliessung/02Richtlinien/01KatRicht/0230.pdf
    $self->append( "001D", '0' => $hdate );

    # PCIA3: 0500 - Bibliographische Gattung und Status
    # http://www.gbv.de/vgm/info/mitglieder/02Verbund/01Erschliessung/02Richtlinien/01KatRicht/0500.pdf
    $self->append( "002@", '0' => $status );
}


sub string {
    my ($self, %args) = @_;

    $args{endfield} = "\n" unless defined($args{endfield});

    my @lines = ();
    for my $field ( @{$self->{_fields}} ) {
        push( @lines, $field->string(%args) );
    }
    return join('', @lines);
}


sub normalized() {
    my $self = shift;
    my $prefix = shift;
    $prefix = "" if (!$prefix);

    my @lines = ();
    for my $field ( @{$self->{_fields}} ) {
        push( @lines, $field->normalized() );
    }

    return "\x1D\x0A" . $prefix . join( "", @lines );
}


sub xml {
    my $self = shift;
    my $writer = $_[0];
    my ($string, $sref);

    # write to a string
    if (not UNIVERSAL::isa( $writer, 'XML::Writer' )) {
        my %params = @_;
        if (not defined $params{OUTPUT}) {
            $sref = \$string;
            $params{OUTPUT} = $sref;
        }
        $writer = PICA::Writer::xmlwriter( %params );
    }

    if ( UNIVERSAL::isa( $writer, 'XML::Writer::Namespaces' ) ) {
        $writer->startTag( [$PICA::Record::XMLNAMESPACE, 'record'] );
    } else {
        $writer->startTag( 'record' );
    }
    for my $field ( @{$self->{_fields}} ) {
        $field->xml( $writer );
    }
    $writer->endTag();

    return defined $sref ? $$sref : undef;
}


sub html  {
    my $self = shift;
    my %options = @_;

    my @html = ("<div class='record'>\n");
    for my $field ( @{$self->{_fields}} ) {
        push @html, $field->html( %options );
    }
    push @html, "</div>";

    return join("", @html) . "\n";
}


sub write {
    my $record = shift;
    my $writer = PICA::Writer->new( @_ );
    return $writer unless $writer;
    $writer->write( $record )->end;
}



sub pgrep (&@) {
    my $block  = shift;
    my $record = (@_ == 1 and UNIVERSAL::isa( $_[0],'PICA::Record' )) 
               ? $_[0] : PICA::Record->new( @_ );
    my @fields;

    for my $f ( $record->fields ) {
        local $_ = $f;
        push @fields, $f if $block->();
    }

    return PICA::Record->new( @fields );
}


sub pmap (&@) {
    my $block  = shift;
    my $record = (@_ == 1 and UNIVERSAL::isa( $_[0],'PICA::Record' )) 
               ? $_[0] : PICA::Record->new( @_ );
    my @fields;

    for my $f ( $record->fields ) {
        local $_ = $f;
        my @r = $block->();
        if (@r == 1 and UNIVERSAL::isa( $_[0],'PICA::Field' )) {
            push @fields, $r[0];
        } else {
            push @fields, PICA::Field->new( @r );
        }
    }

    return PICA::Record->new( @fields );
}


sub readpicarecord {
    my ($file, %options) = @_;
    if ( wantarray and defined $options{Limit} ) {
        return PICA::Parser->parsefile( $file, %options )->records();
    }
    $options{Limit} = 1;
    my ($record) = PICA::Parser->parsefile( $file, %options )->records();
    return undef unless $record and not $record->empty;
    return $record;
}


*writepicarecord = *write;


sub picarecord {
    return PICA::Record->new( @_ );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PICA::Record - Perl module for handling PICA+ records

=head1 VERSION

version 0.585

=head1 SYNOPSIS

To get a deeper insight to the API have a look at the documentation,
the examples (directory C<examples>) and tests (directory C<t>). Here
are some additional two-liners:

  # create a field
  my $field = PICA::Field->new(
    "028A", "9" => "117060275", "d" => "Martin", "a" => "Schrettinger" );

  # create a record and add some fields (note that fields can be repeated)
  my $record = PICA::Record->new();
  $record->append( '044C', 'a' => "Perl", '044C', 'a' => "Programming", );

  # read all records from a file
  my @records = PICA::Parser->new->parsefile( $filename )->records();

  # read one record from a file
  my $record = readpicarecord( $filename );

  # read one record from a string
  my ($record) =  PICA::Parser->parsedata( $picadata, Limit => 1)->records();

  # get two fields of a record
  my ($f1, $f2) = $record->field( 2, "028B/.." );

  # extract some subfield values
  my ($given, $surname) = ($record->sf(1,'028A$d'), $record->sf(1,'028A$a'));

  # read records from a STDIN and print to STDOUT of field 003@ exists
  PICA::Parser->new->parsefile( \STDIN, Record => sub {
      my $record = shift;
      print $record if $record->field('003@');
      return;
  });

  # print record in normalized format and in HTML
  print $record->normalized;
  print $record->html;

  # write some records in XML to a file
  my $writer = PICA::Writer->new( $filename, format => 'xml' );
  $writer->write( @records );

=head1 DESCRIPTION

PICA::Record is a module for handling PICA+ records as Perl objects.

=head2 Clients and examples

This module includes and installs the scripts C<parsepica>, C<picaimport>,
and C<winibw2pica>. They provide most functionality on the command line 
without having to deal with Perl code. Have a look at the documentation of
this scripts! More examples are included in the examples directory - maybe
the application you need it already included, so have a look!

=head2 On character encoding

Character encoding is an issue of permanent confusion both in library 
databases and in Perl. PICA::Record treats character encoding the 
following way: Internally all strings are stored as Perl strings. If you
directly read from or write to a file that you specify by filename only,
the file will be opened with binmode utf8, so the content will be decoded
or encoded in UTF-8 Unicode encoding.

If you read from or write to a handle (for instance a file that you
have already opened), binmode utf8 will also be enabled unless you
have already specified another encoding layer:

  open FILE, "<$filename";
  $record = readpicarecord( \*FILE1 ); # implies binmode FILE, ":utf8"

  open FILE, "<$filename";
  binmode FILE,':encoding(iso-8859-1)';
  $record = readpicarecord( \*FILE ); # does not imply binmode FILE, ":utf8"

If you read or write from Perl strings, UTF-8 is never implied. This means
you must explicitely enable utf8 on your strings. As long as you read and
write PICA record data from files and other sources or stores you should not
need to do anything, but if you modify records in your scripts, use utf8.

If you download PICA+ records with the WinIBW3 client software, you may first
need to convert the records to valid PICA+ syntax. For this reason this module
contains the script C<winibw2pica>.

=head1 INTRODUCTION

=head2 What is PICA+?

B<PICA+> is the internal data format of the Local Library System (LBS) and
the Central Library System (CBS) of OCLC, formerly PICA. Similar library
formats are the MAchine Readable Cataloging format (MARC) and the
Maschinelles Austauschformat für Bibliotheken (MAB). In addition to
PICA+ in CBS there is the cataloging format Pica3 which can losslessly
be convert to PICA+ and vice versa.

=head2 What is PICA::Record?

B<PICA::Record> is a Perl package that provides an API for PICA+ record
handling. The package contains a parser interface module L<PICA::Parser>
to parse PICA+ (L<PICA::PlainParser>) and PICA XML (L<PICA::XMLParser>).
Corresponding modules exist to write data (L<PICA::Writer> and
L<PICA::XMLWriter>). PICA+ data is handled in records (L<PICA::Record>)
that contain fields (L<PICA::Field>). To fetch records from databases
via SRU or Z39.50 there is the interface L<PICA::Source> and to access
a record store via CWS webcat interface there is L<PICA::Store>.

You can use PICA::Record for instance to:

=over 4

=item *

convert between PICA+ and PicaXML

=item *

download records in native format via SRU or Z39.50

=item *

process PICA+ records that you have downloaded with WinIBW 

=item *

store PICA+ records in a database

=back

=head1 CONSTRUCTORS

=head2 new ( [ ...data... | $filehandle ] )

Base constructor for the class. A single string will be parsed line by 
line into L<PICA::Field> objects, empty lines and start record markers will 
be skipped. More then one or non scalar parameters will be passed to 
C<append> so you can use the constructor in the same way:

  my $record = PICA::Record->new('037A','a' => 'My note');

If no data is given then it just returns a completely empty record. To load
PICA records from a file, see L<PICA::Parser>, to load records from a SRU
or Z39.50 server, see L<PICA::Source>. 

If you provide a file handle or L<IO::Handle>, the first record is read from
it. Each of the following four lines has the same result:

  $record = PICA::Record->new( IO::Handle->new("< $filename") );
  ($record) = PICA::Parser->parsefile( $filename, Limit => 1 )->records(),
  open (F, "<:utf8", $plainpicafile); $record = PICA::Record->new( \*F ); close F;
  $record = readpicarecord( $filename );

=head2 copy

Returns a clone of a record by copying all fields.

  $newrecord = $record->copy;

=head1 ACCESSOR METHODS

=head2 field ( [ $limit, ] { $field }+ [ $filter ] ) or f ( ... )

Returns a list of C<PICA::Field> objects with tags that
match the field specifier, or in scalar context, just
the first matching Field.

You may specify multiple tags and use regular expressions.

  my $field  = $record->field("021A","021C");
  my $field  = $record->field("009P/03");
  my @fields = $record->field("02..");
  my @fields = $record->field( qr/^02..$/ );
  my @fields = $record->field("039[B-E]");

If the first parameter is an integer, it is used as a limitation
of response size, for instance two get only two fields:

  my ($f1, $f2) = $record->field( 2, "028B/.." );

The last parameter can be a function to filter returned fields
in the same way as a field handler of L<PICA::Parser>. For instance
you can filter out all fields with a given subfield:

  my @fields = $record->field( "021A", sub { $_ if $_->sf('a'); } );

=head2 subfield ( [ $limit, ] { [ $field, $subfield ] | $fullspec }+ ) or sf ( ... )

Shortcut method to get subfield values. Returns a list of subfield values 
that match or in scalar context, just the first matching subfield or undef.
Fields and subfields can be specified in several ways. You may use wildcards
in the field specifications.

These are equivalent (in scalar context):

  my $title = $pica->field('021A')->subfield('a');
  my $title = $pica->subfield('021A','a');

You may also specify both field and subfield seperated by '$'
(don't forget to quote the dollar sign) or '_'.

  my $title = $pica->subfield('021A$a');
  my $title = $pica->subfield("021A\$a");
  my $title = $pica->subfield("021A$a"); # $ not escaped
  my $title = $pica->subfield("021A_a"); # _ instead of $

You may also use wildcards like in the C<field()> method of PICA::Record
and the C<subfield()> method of L<PICA::Field>:

  my @values = $pica->subfield('005A', '0a');    # 005A$0 and 005A$a
  my @values = $pica->subfield('005[AIJ]', '0'); # 005A$0, 005I$0, and 005J$0

If the first parameter is an integer, it is used as a limitation
of response size, for instance two get only two fields:

  my ($f1, $f2) = $record->subfield( 2, '028B/..$a' );

Zero or negative limit values are ignored.

=head2 values ( [ $limit ] { [ $field, $subfield ] | $fullspec }+ )

Same as C<subfield> but always returns an array.

=head2 fields

Returns an array of all the fields in the record. The array contains 
a C<PICA::Field> object for each field in the record. An empty array 
is returns if the record is empty.

=head2 size

Returns the number of fields in this record.

=head2 occurrence  or  occ

Returns the occurrence of the first field of this record. 
This is only useful if the first field has an occurrence.

=head2 main

Get the main record (level 0, all tags starting with '0').

=head2 holdings ( [ $iln ] )

Get a list of local records (holdings, level 1 and 2) or the local record with
given ILN. Returns an array of L<PICA::Record> objects or a single holding.
This method also sorts level 1 and level 2 fields.

=head2 items

Get an array of L<PICA::Record> objects with fields of each copy/item
included in the record. Copy records are located at level 2 (tags starting
with '2') and differ by tag occurrence.

=head2 empty

Return true if the record is empty (no fields or all fields empty).

=head1 ACCESSOR AND MODIFCATION METHODS

=head2 ppn ( [ $ppn ] )

Get or set the identifier (PPN) of this record (field 003@, subfield 0).
This is equivalent to C<$self-E<gt>subfield('003@$0')> and always returns a 
scalar or undef. Pass C<undef> to remove the PPN.

=head2 epn ( [ $epn[s] ] )

Get zero or more EPNs (item numbers) of this record, which is field 203@/.., subfield 0.
Returns the first EPN (or undef) in scalar context or a list in array context. Each copy 
record (get them with method items) should have only one EPN.

=head2 iln

Get zero or more ILNs (internal library numbers) of this record, which is field 101@$a.
Returns the first ILN (or undef) in scalar context or a list in array context. 
Each holdings record is identified by its ILN.

=head1 MODIFICATION METHODS

=head2 append ( ...fields or records... )

Appends one or more fields to the end of the record. Parameters can be
L<PICA::Field> objects or parameters that are passed to C<PICA::Field-E<gt>new>.

    my $field = PICA::Field->new( '037A','a' => 'My note' );
    $record->append( $field );

is equivalent to

    $record->append('037A','a' => 'My note');

You can also append multiple fields with one call:

    my $field = PICA::Field->new('037A','a' => 'First note');
    $record->append( $field, '037A','a' => 'Second note' );

    $record->append(
        '037A', 'a' => '1st note',
        '037A', 'a' => '2nd note',
    );

Please note that passed L<PICA::Field> objects are not be copied but 
directly used:

    my $field = PICA::Field->new('037A','a' => 'My note');
    $record->append( $field );
    $field->update( 'a' => 'Your note' ); # Also changes $record's field!

You can avoid this by cloning fields or by using the appendif method:

    $record->append( $field->copy() );
    $record->appendif( $field );

You can also append copies of all fields of another record:

    $record->append( $record2 );

The append method returns the number of fields appended.

=head2 appendif ( ...fields or records... )

Optionally appends one or more fields to the end of the record. Parameters can
be L<PICA::Field> objects or parameters that are passed to C<PICA::Field-E<gt>new>.

In contrast to the append method this method always copies values, it ignores
empty subfields and empty fields (that are fields without subfields or with
empty subfields only), and it returns the resulting PICA::Record object.

For instance this command will not add a field if C<$country> is undef or C<"">:

  $r->appendif( "119@", "a" => $country );

=head2 update ( $tag, ( $field | @fieldspec | $coderef ) )

Replace a field. You must pass a tag and a field. If you pass a code reference,
the code will be called for each field and the field is replaced by the result
unless the result is C<undef>.

Please do not use this to replace repeatbale fields because they would all be
set to the same values.

=head2 remove ( $tag(s) )

Delete fields specified by tags and returns the number of deleted fields. 
You can also use wildcards, and compiled regular expressions as tag selectors.

=head2 sort

Sort the fields of this records. Respects level 0, 1, and 2.

=head2 add_headers ( [ %options ] )

Add header fields to a L<PICA::Record>. You must specify two named parameters
(C<eln> and C<status>). This method is experimental. There is no test whether 
the header fields already exist. This method may be removed in a later release.

=head1 SERIALIZATION METHODS

=head2 string ( [ %options ] )

Returns a string representation of the record for printing.
See also L<PICA::Writer> for printing to a file or file handle.

=head2 normalized ( [ $prefix ] )

Returns record as a normalized string. Optionally adds prefix data at the beginning.

    print $record->normalized();
    print $record->normalized("##TitleSequenceNumber 1\n");

See also L<PICA::Writer> for printing to a file or file handle.

=head2 xml ( [ $xmlwriter | %params ] )

Write the record to an L<XML::Writer> or return an XML string of the record.
If you pass an existing XML::Writer object, the record will be written with it
and nothing is returned. Otherwise the passed parameters are used to create a
new XML writer. Unless you specify an XML writer or an OUTPUT parameter, the
resulting XML is returned as string. By default the PICA-XML namespaces with
namespace prefix 'pica' is included. In addition to XML::Writer this methods
knows the 'header' parameter that first adds the XML declaration and the 'xslt'
parameter that adds an XSLT stylesheet.

=head2 html ( [ %options ] )

Returns a HTML representation of the record for browser display. See also
the C<pica2html.xsl> script to generate a more elaborated HTML view from
PICA-XML.

=head2 write ( [ $output ] [ format => $format ] [ %options ] )

Write a single record to a file or stream and end the output. You can pass
the same parameters as known to the constructor of L<PICA::Writer>. Returns
the PICA::Writer object that was used to write the record. Use can check the
status of the writer with a simple boolean check.

=head1 FUNCTIONS

The functions readpicarecord and writepicarecord are exported by default.
On request you can also export the function picarecord which is a shortcut
for the constructor PICA::Record->new and the functions pgrep and pmap.
To export all functions, import the module via:

  use PICA::Record qw(:all);

=head2 pgrep { COND } $record

Evaluates the COND for each field of C<$record> (locally setting $_ to each field)
and returns a new PICA::Record containing only those fields that match. Instead of
a PICA::Record field you can also pass any values that will be passed to the record
constructor. An example:

  # all fields that contain a subfield 'a' which starts with '2'
  pgrep { $_ =~ /^2/ if ($_ = $_->sf('a')); } $record;

  # all fields that contain a subfield '0' in level 0
  pgrep { defined $_->sf('0') } $record->main;

=head2 pmap { COND } $record

Evaluates the COND for each field of C<$record> (locally setting $_ to each field),
treats the return value as L<PICA::Field> (optionally passed to its constructir),
and returns a new record build if this fields. Instead of a PICA::Record field you
can also pass any values that will be passed to the record constructor. 

=head2 readpicarecord ( $filename [, %options ] )

Read a single record from a file. Returns a non-empty PICA::Record
object or undef. Shortcut for:

  PICA::Parser->parsefile( $filename, Limit => 1 )->records();

In array context you can use this method as shortcut to read multiple
records if you specify a C<Limit> parameter. use C<Limit=&gt;0> to read
all records from a file. The following statements are equivalent:

  @records = readpicarecord( $filename, Limit => 0 );
  @records = PICA::Parser->parsefile( $filename )->records()

=head2 writepicarecord ( $record, [ $output ] [ format => $format ] [ %options ] )

Write a single record to a file or stream. Shortcut for

  $record->write( [ $output ] [ format => $format ] [ %options ] )

as described above - see the constructor of L<PICA::Writer> for more details.
Returns the PICA::Writer object that was used to write the record - you can use
a simple if to check whether an error occurred.

=head2 picarecord ( ... )

Shortcut for PICA::Record->new( ... )

=head1 SEE ALSO

At CPAN there are the modules L<MARC::Record>, L<MARC>, and L<MARC::XML> 
for MARC records and L<Encode::MAB2> for MAB records. The deprecated module
L<Net::Z3950::Record> also had a subclass L<Net::Z3950::Record::MAB> for MAB 
records. You should now better use L<Net::Z3950::ZOOM> which is also needed
if you query Z39.50 servers with L<PICA::Source>.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Verbundzentrale Goettingen (VZG) and Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

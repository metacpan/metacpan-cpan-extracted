#Copyright 2007-8 Arthur S Goldstein
#TESTING PHASE

package Parse::Stallion::CSV;
use Carp;
use strict;
use warnings;
use Parse::Stallion;
#use Data::Dumper;

our $VERSION='0.5';
#Copied somewhat from rfc1480
# see for reference: http://tools.ietf.org/html/rfc4180

my %with_header_csv_rules = (
   file => AND(
      'header',
       'CRLF',
       'record',
       MULTIPLE(AND('CRLF', 'record')),
       OPTIONAL('CRLF')
     ,
     EVALUATION(sub {
#use Data::Dumper;print STDERR "withhead params are ".Dumper(\@_)."\n";
       return {header => $_[0]->{header}, records => $_[0]->{record}};
     }
    )),

   header => AND('name', MULTIPLE(AND('COMMA', 'name')),
     EVALUATION(sub {return $_[0]->{name}}))
    ,

   record => AND('field', MULTIPLE(AND('COMMA', 'field')),
     EVALUATION(sub {
#use Data::Dumper;print STDERR "record params are ".Dumper(\@_)."\n";
       return $_[0]->{field}}))
    ,

   name => AND('field'),

   field => OR('escaped', 'non_escaped'),

   escaped => AND('DQUOTE', 'inner_escaped', 'DQUOTE',
      EVALUATION(sub {
#use Data::Dumper;print STDERR "escaped params are ".Dumper(\@_)."\n";
       return $_[0]->{inner_escaped}})
    ),

   ie_choices=>OR('TEXTDATA','COMMA','CRLF','DDQUOTE'),

   inner_escaped =>
     MULTIPLE('ie_choices'
      ,
      EVALUATION(sub {
#use Data::Dumper;print STDERR "ie params are ".Dumper(\@_)."\n";
        my $param = shift;
        return join('', @{$param->{'ie_choices'}});
        }
    )),

   DDQUOTE => AND('DQUOTE','DQUOTE',
      EVALUATION(sub {return '"'})
   ),

   non_escaped => AND('TEXTDATA'),

   COMMA => LEAF(qr/\x2C/),

#   CR => LEAF(qr/\x0D/),

   DQUOTE => LEAF(qr/\x22/),

#   LF => LEAF(qr/\x0A/),

   #CRLF => AND('CR','LF'),
   CRLF => LEAF(qr/\n/)
#    evaluation =>
#     sub {
#      my $param = shift;
##      print STDERR "Parsm to crlf are ".Dumper($param)."\n";
#      return "\n";
#    }
   ,

   TEXTDATA => LEAF(qr/[\x20-\x21\x23-\x2B\x2D-\x7E]+/)
   ,

);

sub new {
  my $self = shift;
  my $parameters = shift;
  return  new Parse::Stallion(
    \%with_header_csv_rules, {start_rule=>'file'});
}


1;

__END__

=head1 NAME

Parse::Stallion::CSV - Comma Separated Values

=head1 SYNOPSIS

  This is primarily for demonstrating Parse::Stallion.

  use Parse::Stallion::CSV;

  my $csv_stallion = new Parse::Stallion::CSV;

  my $input_string = 'header1,header2,header3'."\n";
  $input_string .= 'field_1_1,field_1_2,field_1_3'."\n";
  $input_string .=
   '"field_2_1 3 words",field_2_2 3 words,\"field3_2 x\"'."\n";

  my $result = eval {$csv_stallion->
   parse_and_evaluate({parse_this=>$input_string})};

  if ($@) {
    if ($csv_stallion->parse_failed) {#parse failed};
  }
  # $result should contain reference to a hase same as
   {'header' => [ 'header1', 'header2', 'header3' ],
    'records' => [
     [ 'field_1_1', 'field_1_2', 'field_1_3' ],
     [ 'field_2_1 3 words', 'field_2_2 3 words', '"field3_2 x"' ]
    ]
   };

=head1 DESCRIPTION

Reads a comma separated value string, returning a reference
to a hash containing the headers and the data.

The source of the grammar from the RFC and the implementation follow to
demonstrate how one can use Parse::Stallion.

=head2 GRAMMAR SOURCE

The grammar used here is based on RFC 4180, see for
example http://tools.ietf.org/html/rfc41801.
The grammar represented by an ABNF grammar:

   file = [header CRLF] record *(CRLF record) [CRLF]

   header = name *(COMMA name)

   record = field *(COMMA field)

   name = field

   field = (escaped / non-escaped)

   escaped = DQUOTE *(TEXTDATA / COMMA / CR / LF / 2DQUOTE) DQUOTE

   non-escaped = *TEXTDATA

   COMMA = %x2C

   CR = %x0D

   DQUOTE =  %x22

   LF = %x0A

   CRLF = CR LF

   TEXTDATA =  %x20-21 / %x23-2B / %x2D-7E

=cut

package MsOffice::Word::Surgeon::Utils;
use strict;
use warnings;
use Carp::Clan  qw(^MsOffice::Word::Surgeon); # will import carp, croak, etc.
use Exporter    qw/import/;

our @EXPORT = qw/maybe_preserve_spaces is_at_run_level decode_entities encode_entities/;

our $VERSION = '2.05';

sub maybe_preserve_spaces {
  my ($txt) = @_;
  return $txt =~ /^\s/ || $txt =~ /\s$/ ? ' xml:space="preserve"' : '';
}

sub is_at_run_level {
  my ($xml) = @_;
  return $xml =~ m[</w:(?:r|del|ins)>$];
}

# Cheap version for encoding/decoding XML Entities.
# We just need 4 of them, so no need for a module with complete support.
my %entities        = (quot => '"', amp => '&', 'lt' => '<', gt => '>');
my $entity_names    = join "|", keys %entities;
my $entity_chars    = "[" . join("", values %entities) . "]";
my %entity_for_char = reverse %entities;

sub decode_entities { $_[0] =~ s{&($entity_names);}{$entities{$1}               }eg; }
sub encode_entities { $_[0] =~ s{($entity_chars)}  {'&'.$entity_for_char{$1}.';'}eg; }

1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Surgeon::Utils - utility functions for MsOffice::Word::Surgeon

=head1 SYNOPSIS

  use MsOffice::Word::Surgeon::Utils qw(maybe_preserve_spaces);
  my $attr = maybe_preserve_spaces($some_text);


=head1 DESCRIPTION

Functions in this module are used internally by L<MsOffice::Word::Surgeon>.

=head1 FUNCTIONS

=head2 maybe_preserve_spaces

  my $attr = maybe_preserve_spaces($some_text);

Returns the XML attribute to be inserted into C<< <w:t> >> nodes and 
C<< <w:delText> >> nodes when the literal text within the node starts
or ends with a space -- in that case the XML should contain the 
attribute C<<  xml:space="preserve" >>

=head2 is_at_run_level

   if (is_at_run_level($xml)) {...}

Returns true if the given XML fragment ends with a C<< </w:r> >>,
C<< </w:del> >> or C<< </w:ins> >> node.

=head2 decode_entities

  decode_entities($string)

Decodes XML entities within the supplied string (in-place decoding).

=head2 encode_entities

  encode_entities($string)

Encodes XML entities within the supplied string (in-place encoding).

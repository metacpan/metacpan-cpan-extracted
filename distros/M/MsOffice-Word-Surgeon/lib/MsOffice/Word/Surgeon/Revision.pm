package MsOffice::Word::Surgeon::Revision;
use 5.24.0;
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;
use POSIX                          qw(strftime);
use MsOffice::Word::Surgeon::Carp;
use MsOffice::Word::Surgeon::Utils qw(maybe_preserve_spaces encode_entities);
use namespace::clean -except => 'meta';

our $VERSION = '2.09';

subtype 'Date_ISO',
  as      'Str',
  where   {/\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2})?Z?/},
  message {"$_ is not a date in ISO format yyyy-mm-ddThh:mm:ss"};

#======================================================================
# ATTRIBUTES
#======================================================================

has 'rev_id'      => (is => 'ro', isa => 'Num', required => 1);
has 'to_delete'   => (is => 'ro', isa => 'Str');
has 'to_insert'   => (is => 'ro', isa => 'Str');
has 'author'      => (is => 'ro', isa => 'Str', default => 'Word::Surgeon');
has 'date'        => (is => 'ro', isa => 'Date_ISO', default =>
                        sub {strftime "%Y-%m-%dT%H:%M:%SZ", localtime});
has 'run'         => (is => 'ro', isa => 'MsOffice::Word::Surgeon::Run');
has 'xml_before'  => (is => 'ro', isa => 'Str');


#======================================================================
# INSTANCE CONSTRUCTION
#======================================================================

sub BUILD {
  my $self = shift;

  $self->to_delete || $self->to_insert
    or croak "attempt to create a Revision object without 'to_delete' nor 'to_insert' args";
}


#======================================================================
# METHODS
#======================================================================

sub as_xml {
  my ($self) = @_;

  my $rev_id    = $self->rev_id;
  my $date      = $self->date;
  my $author    = $self->author; encode_entities($author);
  my $props     = $self->run && $self->run->props ? "<w:rPr>" . $self->run->props . "</w:rPr>"
                                                  : "";

  my $xml       = "";

  if (my $to_delete = $self->to_delete) {
    my $space_attr = maybe_preserve_spaces($to_delete);
    encode_entities($to_delete);
    $xml .= qq{<w:del w:id="$rev_id" w:author="$author" w:date="$date">}
            . qq{<w:r>$props}
                 . qq{<w:delText$space_attr>$to_delete</w:delText>}
            . qq{</w:r>}
          . qq{</w:del>};
  }
  if (my $to_insert = $self->to_insert) {
    my $space_attr = maybe_preserve_spaces($to_insert);
    encode_entities($to_insert);
    $xml .= qq{<w:ins w:id="$rev_id" w:author="$author" w:date="$date">}
            . qq{<w:r>$props}
              . ($self->xml_before // '')
              . qq{<w:t$space_attr>$to_insert</w:t>}
            . qq{</w:r>}
          . qq{</w:ins>};
  }

  return $xml;
}

1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Surgeon::Revision - generate XML markup for MsWord revisions

=head1 DESCRIPTION

This class implements the XML markup generation algorithm
for the method L<MsOffice::Word::Surgeon/new_revision>.
See that method for a description of the API.

=head1 INTERNALS

The constructor requires an integer C<rev_id> argument.
The C<rev_id> is fed by the surgeon object which generates a fresh value at each call.
This is inserted as C<w:id> attribute to the
C<< <w:del> >> and C<< <w:ins> >> nodes -- but I don't really know why, 
since it doesn't seem to be used for any purpose by MsWord.

=head1 COPYRIGHT AND LICENSE

Copyright 2019-2024 by Laurent Dami.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

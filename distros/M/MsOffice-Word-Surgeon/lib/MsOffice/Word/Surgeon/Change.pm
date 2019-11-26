package MsOffice::Word::Surgeon::Change;
use feature 'state';
use Moose;
use Moose::Util::TypeConstraints;
use Carp                           qw(croak);
use POSIX                          qw(strftime);
use MsOffice::Word::Surgeon::Utils qw(maybe_preserve_spaces);
use namespace::clean -except => 'meta';

subtype 'Date_ISO',
  as      'Str',
  where   {/\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2})?Z?/},
  message {"$_ is not a date in ISO format yyyy-mm-ddThh:mm:ss"};


has 'to_delete'   => (is => 'ro', isa => 'Str');
has 'to_insert'   => (is => 'ro', isa => 'Str');
has 'author'      => (is => 'ro', isa => 'Str'               );
has 'date'        => (is => 'ro', isa => 'Date_ISO', default =>
                        sub {strftime "%Y-%m-%dT%H:%M:%SZ", localtime});
has 'run'         => (is => 'ro', isa => 'MsOffice::Word::Surgeon::Run');
has 'xml_before'  => (is => 'ro', isa => 'Str');

our $VERSION = '1.0';

sub BUILD {
  my $self = shift;

  $self->to_delete || $self->to_insert
    or croak "attempt to create a Change object without 'to_delete' nor 'to_insert' args";
}


sub as_xml {
  my ($self) = @_;

  state $rev_id = 0;
  $rev_id++;

  my $date      = $self->date;
  my $author    = $self->author;
  my $props     = $self->run && $self->run->props
                  ? "<w:rPr>" . $self->run->props . "</w:rPr>"
                  : "";
  my $xml = "";

  if ($self->to_delete) {
    my $space_attr = maybe_preserve_spaces($self->to_delete);
    $xml .= qq{<w:del w:id="$rev_id" w:author="$author" w:date="$date">}
            . qq{<w:r>$props}
                 . qq{<w:delText$space_attr>}.$self->to_delete.qq{</w:delText>}
            . qq{</w:r>}
          . qq{</w:del>};
  }
  if ($self->to_insert) {
    my $space_attr = maybe_preserve_spaces($self->to_insert);
    $xml .= qq{<w:ins w:id="$rev_id" w:author="$author" w:date="$date">}
            . qq{<w:r>$props}
              . ($self->xml_before // '')
              . qq{<w:t$space_attr>}.$self->to_insert.qq{</w:t>}
            . qq{</w:r>}
          . qq{</w:ins>};
  }

  return $xml;
}

1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Surgeon::Change - generate XML markup for MsWord tracked changes

=head1 DESCRIPTION

This class implements the XML markup generation algorithm
for the method L<MsOffice::Word::Surgeon/change> .
See that method for a description of the API.

=head1 INTERNALS

Each call generates a fresh revision id, inserted as C<w:id> attribute to the
C<< <w:del> >> and C<< <w:ins> >> nodes -- but it doesn't seem to be used for
any purpose by MsWord.


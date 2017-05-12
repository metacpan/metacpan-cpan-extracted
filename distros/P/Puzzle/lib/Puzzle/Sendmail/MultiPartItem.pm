=head1 NOME

Puzzle::Sendmail::MultiPartItem - Modulo di invio mail all'utente

=head1 SINTASSI

use lib '/home/ecp/lib';
use ECP::Sendmail::MultiPartItem;

$smail = new ECP::Sendmail::MultiPartItem ( db=>$db );


=head1 DESCRIZIONE


=cut


package Puzzle::Sendmail::MultiPartItem;

our $VERSION = '0.02';

use MIME::QuotedPrint;

use Params::Validate qw(:types);
use base 'Class::Container';

__PACKAGE__->valid_params(
  id      			=> { parse  => 'string', type => SCALAR|UNDEF},
  contentId 			=> { parse  => 'string', type => SCALAR, default => ''},
  contentType 			=> { parse  => 'string', type => SCALAR, default => 'text/plain'},
  body 			=> { parse  => 'string', type => SCALAR},
  contentTransferEncoding 			=> { parse  => 'string', type => SCALAR, default => 'quoted-printable'},
  contentDisposition 			=> { parse  => 'string', type => SCALAR|UNDEF},
);

# all new valid_params are read&write methods
use HTML::Mason::MethodMaker(
	read_write		=> [
	[ id 			=> __PACKAGE__->validation_spec->{'id'} ],
	[ contentId 			=> __PACKAGE__->validation_spec->{'contentId'} ],
	[ contentType 			=> __PACKAGE__->validation_spec->{'contentType'} ],
	[ body 			=> __PACKAGE__->validation_spec->{'body'} ],
	[ contentTransferEncoding 			=> __PACKAGE__->validation_spec->{'contentTransferEncoding'} ],
	[ contentDisposition 			=> __PACKAGE__->validation_spec->{'contentDisposition'} ],
	]
);

sub toString {
	my $self = shift;
	my $ret;
	my $boundary = '====' . $self->id . time() . $self->id . '====';
	my $body		= encode_qp $self->body;
	$ret .=<<EOF;
Content-Type: $self->{contentType};charset="iso-8859-1"
Content-Transfer-Encoding: $self->{contentTransferEncoding}
Content-ID: <$self->{contentId}>
EOF

$ret .= "Content-Disposition: $self->{contentDisposition}\n"
	if ($self->contentDisposition);

$ret .= "\n$body";
return $ret;
}
                           
# ---------------------------- BEGIN POD ----------------------------------


=head1 AUTORE

Emiliano Bruni, bruni@micso.it

=cut	
	
# ----------------------------- END POD -----------------------------------

1;

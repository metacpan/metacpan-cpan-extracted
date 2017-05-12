=head1 NOME

Puzzle::Sendmail - Modulo di invio mail all'utente

=head1 SINTASSI

$smail = new ECP::Sendmail::Sendmail ( email => 'bruni@micso.it');

$smail->addMultiPartItem(0,$body_css,'text/css',$css_id);
$smail->addMultiPartItem(1,$body_plain,'text/plain');
$smail->addMultiPartItem(1,$body_html,'text/html');

$smail->subject('Mail Subject');
$smail->send();



=head1 DESCRIZIONE


=cut


package Puzzle::Sendmail;

our $VERSION = '0.02';

use Params::Validate qw(:types);
use base 'Class::Container';

use Puzzle::Sendmail::MultiPartItem;
use Mail::Sendmail;

use HTML::Mason::MethodMaker(
  read_write    => [
    [ body     	=> { parse  => 'string', type => SCALAR} ],
    [ subject  	=> { parse  => 'string', type => SCALAR} ],
    [ to				=> { parse  => 'string', type => SCALAR} ],
  ]
);

sub begin_mail {
	my $self	= shift;
	$self->{mpId} = 0;
	delete $self->{mpi};
	delete $self->{mail};
}

sub addMultiPartItem {
	my $self							= shift;
	my $level							= shift;
	my ($body,$contentType,$contentId,
		$contentTransferEncoding, $contentDisposition)	= @_;
	$contentType = 'text/plain' unless ($contentType);
	$contentTransferEncoding = 'quoted-printable' unless ($contentTransferEncoding);
	# $self->{mpId} contiene un incrementale del numero di MultiPartItem
	# aggiunti a questa istanza di sendmail
	my $mp								= new Puzzle::Sendmail::MultiPartItem(
												id			=> $self->{mpId}++,
												contentType => $contentType,
												contentId	=> $contentId,
												body		=> $body,
												contentTransferEncoding => $contentTransferEncoding,
												contentDisposition => $contentDisposition
												);
	push @{$self->{mpi}->[$level]},$mp;	
}
	
	
sub end_mail {
	my $self = shift;
	${$self->{mail}}{subject} = $self->subject;
	${$self->{mail}}{to} 			= $self->to;
	${$self->{mail}}{smtp}  	= $self->container->cfg->mail->{server};
  ${$self->{mail}}{from}  	= $self->container->cfg->mail->{from};
	$self->builtMail;
	return sendmail(%{$self->{mail}}) or die $self->error;
}

sub error {
	my $self = shift;
	return $Mail::Sendmail::error;
}

sub log {
	my $self = shift;
	return $Mail::Sendmail::log;
}

sub property {
	my $self = shift;
	my $key = shift;
	if (@_) {
		my ($value) = @_;
		${$self->{mail}}{$key} = $value;
	}
	return ${$self->{mail}}{$key};
}

sub builtMail {
	# genera il mail
	my $self = shift;
	my $body;
	my @boundary;
	# Consideriamo, per ora, due livelli
	$boundary[0] = '====0' . time() .  '0====';
	${$self->{mail}}{'Content-Type'} = "multipart/related; " .
				"type=\"multipart/alternative\"; boundary=\"$boundary[0]\"";
	$body .= "--" . $boundary[0] . "\n";
	$boundary[1] = '====1' . time() .  '1====';
	$body .= "Content-type: "  .
				"multipart/alternative; boundary=\"$boundary[1]\"\n\n";
	foreach my $lev1 (@{$self->{mpi}->[1]}) {
		$body .= "--" . $boundary[1] . "\n";
		$body .= $lev1->toString;
	}
	$body .= "--" . $boundary[1] . "--\n\n";
	foreach my $lev0 (@{$self->{mpi}->[0]}) {
		$body .= "--" . $boundary[0] . "\n";
		$body .= $lev0->toString;
	}
	$body .= "--" . $boundary[0] . "--\n\n";
	${$self->{mail}}{message} = $body;
}

# ---------------------------- BEGIN POD ----------------------------------


=head1 AUTORE

Emiliano Bruni, bruni@micso.it

=cut	
	
# ----------------------------- END POD -----------------------------------

1;

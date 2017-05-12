package RDF::Crypt::Role::DoesEncrypt;

use 5.010;
use Any::Moose 'Role';

use Crypt::OpenSSL::Bignum qw[];
use Crypt::OpenSSL::RSA qw[];
use Encode qw(encode);
use File::Slurp qw[slurp];
use Mail::Message qw[];
use Mail::Transport::Send qw[];
use Mail::Transport::Sendmail qw[];
use Mail::Transport::SMTP qw[];
use RDF::TrineX::Functions -shortcuts;

use namespace::clean;

BEGIN {
	$RDF::Crypt::Role::DoesEncrypt::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::Role::DoesEncrypt::VERSION   = '0.002';
}

requires 'encrypt_bytes';

sub encrypt_text
{
	my ($self, $text) = @_;
	$self->encrypt_bytes(
		encode('utf-8', $text),
	);
}

sub encrypt_model
{
	my ($self, $model, %opts) = @_;
	$model = rdf_parse(
		$model,
		%opts,
	);
	$self->encrypt_text(
		rdf_string($model, as => 'RDFXML'),
	);
}

sub send_model_by_email
{
	my ($self, $model, $mailopts, $rdfopts) = @_;
	
	confess("This object was not constructed from a WebID")
		unless $self->webid && $self->webid_model;

	my $transport;
	$transport = Mail::Transport::SMTP->new(%{$mailopts->{smtp}})
		if $mailopts->{smtp};
	$transport = Mail::Transport::Sendmail->new(%{$mailopts->{sendmail}})
		if $mailopts->{sendmail};
	$transport ||= Mail::Transport::Send->new;
	
	confess("No method for sending mail.")
		unless defined $transport;

	my @results = 
		map  { substr($_, 7) }
		grep { /^mailto:.+\@.+$/i }
		map  { $_->{mbox}->value }
		RDF::Query
			-> new(sprintf 'SELECT ?mbox { <%s> foaf:mbox ?mbox } ORDER BY ASC(?mbox)', $self->webid)
			-> execute($self->webid_model)
			-> get_all;
	
	confess("No valid e-mail address found for WebID <@{[ $self->webid ]}>")
		unless @results;
	
	my $crypto = $self->encrypt_model($model, %{ $rdfopts || +{} });
	my $default_from =
		   $RDF::Crypt::SENDER
		|| $ENV{EMAIL_ADDRESS}
		|| ((getlogin||getpwuid($<)||"anonymous").'@'.Sys::Hostname::hostname);

	my %headers = %{ $mailopts->{headers} || +{} };

	my $msg = Mail::Message->build(
		To            => $results[0],
		From          => ($mailopts->{from} || $default_from),
		Subject       => ($mailopts->{subject} || 'Encrypted data'),
		'X-Mailer'    => sprintf('%s/%s', __PACKAGE__, __PACKAGE__->VERSION),
		attach        => Mail::Message::Body::Lines->new(
			data          => ["This data has been encrypted for:\n", $self->webid."\n"],
			mime_type     => 'text/plain',
			disposition   => 'inline',
		),
		attach        => Mail::Message::Body::Lines->new(
			data          => ["$crypto\n"],
			mime_type     => 'application/prs.rdf-xml-crypt;version=0',
			disposition   => 'attachment; filename="'.($mailopts->{filename}||'data.rdf-crypt').'"',
		),
		%headers
	);
	
	return unless $msg->send($transport);
	return $msg->messageId;
}

1;

__END__

=head1 NAME

RDF::Crypt::Role::DoesEncrypt - scrambling methods

=head1 DESCRIPTION

=head2 Object Methods

=over

=item C<< encrypt_model($model) >>

Returns an encrypted serialisation of the data.

The encryption works by serialising the data as RDF/XML, then
encrypting it with C<encrypt_text>.

=item C<< send_model_by_email($model, \%opts) >>

This method only works on objects that were constructed using C<new_from_webid>.
Encrypts the model for the holder of the WebID, and sends it to an address
specified in the WebID profile using foaf:mbox.

Options:

=over

=item * B<sendmail> - hashref of options for L<Mail::Transport::Sendmail>. The
mere presence of this hashref will trigger L<Mail::Transport::Sendmail> to
be used as the delivery method.

=item * B<smtp> - hashref of options for L<Mail::Transport::SMTP>. The
mere presence of this hashref will trigger L<Mail::Transport::SMTP> to
be used as the delivery method.

=item * B<from> - email address for the message to come from.

=item * B<subject> - message subject.

=item * B<filename> - filename for encrypted attachment.

=item * B<headers> - hashref of additional mail headers.

=back

Returns a the message's Message-ID, or undef if unsuccessful.

=item C<< encrypt_text($str) >>

Encrypts a literal string which may or may not have anything
to do with RDF.

The return value is a base64-encoded string. The base64-decoded value consists
of: (1) an initialisation vector, sixteen bytes shorter than the size of the
key; (2) a 16-bit big-endian signed integer indicating the length of padding
which was added to the payload of the message during encryption; (3) the payload,
encrypted using cipher-block chaining with OAEP, with block length sixteen bytes
shorter than the key size. These three parts are concatenated together in that
order.

=back

=head2 Required Methods

This role does not implement these methods, but requires classes to
implement them instead:

=over

=item C<< encrypt_bytes($str) >>

Scrambles an octet string.

=back

=head1 SEE ALSO

L<RDF::Crypt>,
L<RDF::Crypt::Encrypter>,
L<RDF::Crypt::Decrypter>.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010, 2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


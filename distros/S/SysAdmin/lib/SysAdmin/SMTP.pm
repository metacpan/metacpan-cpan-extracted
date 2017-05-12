
package SysAdmin::SMTP;
use Moose;

our $VERSION = 0.05;

extends 'SysAdmin';
use MIME::Lite;
use Net::SMTP;

has 'server' => (isa => 'Str', is => 'rw', required => 1, default => "localhost");

__PACKAGE__->meta->make_immutable;

sub sendEmail {
	my $self = shift;
	
	my $smtp_server = $self->server();
	
	my %attr = @_;
	
	if (ref($attr{'to'}) ne 'ARRAY') {
		Carp::croak SysAdmin::SMTP::_error("to");
	}
	
	my $from_address = $attr{'from'};
	my @email_recipients = @{$attr{'to'}};
	my $subject = $attr{'subject'};
	my $message_body = $attr{'body'};
	
	my $email_recipients = join ",", @email_recipients;

	my $mime_type_attach = "text/html";

	my $msg = MIME::Lite->new (
	From => $from_address,
	To => $email_recipients,
	Subject => $subject,
	Type =>'multipart/alternative') or die "Error creating multipart container: $!\n";
                                                                   
	$msg->attach (
	Type => 'text/html;charset=ISO-8859-1',
	Encoding => 'quoted-printable',
	Data => $message_body) or die "Error adding the text message part: $!\n";

	my $smtp = Net::SMTP->new($smtp_server, Debug   => 0);
	die "Couldn\'t connect to server" unless $smtp;

	$smtp->mail( $from_address );
	$smtp->to( @email_recipients  );

	$smtp->data();
	$smtp->datasend($msg->as_string);
	$smtp->dataend();
	$smtp->quit;
}

sub _error {

	my ($error) = @_;
	
	my $error_to_return = undef;
	
	if($error eq "to"){

		$error_to_return = <<END;

## WARNING ##

The "to" variable is not defined properly!

Either define as an array reference using brackets [] like:

my \$email_recipients = ["test\@test.com"];

- or - 

Verify that in the object declaration, NO double quotes where used on the
\$email_recipients variable.

\$smtp_object\-\>sendEmail("TO" => \$email_recipients);

END
	
	}
	
	return $error_to_return . "Error";

}

sub clear {
	my $self = shift;
	$self->server(0);
}

1;
__END__

=head1 NAME

SysAdmin::SMTP - Perl Net::SMTP class wrapper module.

=head1 SYNOPSIS

	use SysAdmin::SMTP;
	
	my $smtp_object = new SysAdmin::SMTP(server => "localhost");
	
	my $from_address = qq("Test User" <test_user\@test.com>);
	my $subject = "Test Subject";
	my $message_body = "Test Message";
	my $email_recipients = ["test_receiver\@test.com"];
	
	$smtp_object->sendEmail(from    => $from_address,
                            to      => $email_recipients,
                            subject => $subject,
                            body    => $message_body);
	

=head1 DESCRIPTION

This is a sub class of SysAdmin. It was created to harness Perl Objects and keep
code abstraction to a minimum.

SysAdmin::SMTP uses Net::SMTP, MIME::Lite to send emails.

=head1 METHODS

=head2 C<new()>

	my $smtp_object = new SysAdmin::SMTP(server => "localhost");
	
Declare the SysAdmin::SMTP object instance. Takes the SMTP server as the only
variable to use.

=head2 C<sendEmail()>

	my $from_address = qq("Test User" <test_user\@test.com>);
	my $subject = "Test Subject";
	my $message_body = "Test Message";
	my $email_recipients = ["test_receiver\@test.com"];
	
	$smtp_object->sendEmail(from    => $from_address,
                            to      => $email_recipients,
                            subject => $subject,
                            body    => $message_body);
														

=head1 SEE ALSO

Net::SMTP - Simple Mail Transfer Protocol Client

MIME::Lite - low-calorie MIME generator 

=head1 AUTHOR

Miguel A. Rivera

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

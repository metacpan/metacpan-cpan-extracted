package Net::SMS::CDYNE::Response;

use Any::Moose;

has 'response_code' => (
    is => 'ro',
    isa => 'Maybe[Int]',
);

sub success {
    my ($self) = @_;

    my $response_code = $self->response_code;
    return 0 if ! $response_code || index($response_code, '2') != 0;

    my $sms_error = $self->sms_error;
    return 0 unless $sms_error;

    return 0 unless $sms_error eq 'NoError';
    
    return 1;
}

sub sms_error { shift->{SMSError} }
sub queued { (shift->{Queued} || '') eq 'true' }
sub sent { (shift->{Sent} || '') eq 'true' }
sub message_id { shift->{MessageID} }
sub cancelled { (shift->{Cancelled} || '') eq 'true' }

__PACKAGE__->meta->make_immutable;

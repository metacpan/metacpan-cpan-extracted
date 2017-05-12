package Net::Server::Mail::ESMTP::SIZE;

use strict;
use base qw(Net::Server::Mail::ESMTP::Extension);
use vars qw($VERSION);
$VERSION     = '0.02';

sub init {
    my ($self, $parent) = @_;
    $self->{parent} = $parent;
    return $self;
}

sub reply {
    return (['DATA' =>  \&reply_mail_body], 
            ['MAIL' =>  \&reply_mail_from]);
}

sub option {
    return (['MAIL', 'SIZE' => \&option_mail_size]);
}

sub option_mail_size {
    my ($self, $command, $mail_from, $option, $value) = @_;

    if (lc($option) eq 'size'){
        if ($value <= $self->{'_size_extension'}){
            $self->{'_size_option_result'} = [ 200, 'OK' ];
	} else {
            $self->{'_size_option_result'} = [ '552', 'message size exceeds fixed maximium message size' ];
	}
    }
}

sub reply_mail_from {
    my ($self, $command, $last, $code, $message) = @_;

    if (defined ($self->{'_size_option_result'})){
        return @{ $self->{'_size_option_result'} };
    }
}

sub reply_mail_body {
    my ($self, $command, $last, $code, $message) = @_;
    if (length($self->{'_data'}) <= $self->{'_size_extension'}){
        return ($code, $message);
    } else { 
        return (552, 'Message too big!');
    }
}

sub keyword {
    return 'SIZE';
}

sub set_size {
    my ($self, $size) = @_;
    $self->{'_size_extension'} = $size;
}

*Net::Server::Mail::ESMTP::set_size  = \&set_size;

sub parameter {
    my ($self) = @_;
    return $self->{'parent'}->{'_size_extension'};
}

1;

#################### main pod documentation begin ###################

=head1 NAME

Net::Server::Mail::ESMTP::SIZE - add support for the SIZE ESMTP extension to Net::Server::Mail 

=head1 SYNOPSIS

    use Net::Server::Mail::ESMTP;

    my @local_domains = qw(example.com example.org);
    my $server = new IO::Socket::INET Listen => 1, LocalPort => 25;

    my $conn;
    while($conn = $server->accept)
    {
        my $esmtp = new Net::Server::Mail::ESMTP socket => $conn;
        # activate some extensions
        $esmtp->register('Net::Server::Mail::ESMTP::SIZE');
        $esmtp->set_size(10_000_000); #10 Milion bytes
        $esmtp->process();
        $conn->close()
    }

=head1 DESCRIPTION

Add the ESMTP SIZE extension to Net::Server::Mail::ESMTP. I stubbed this extension
when I wrote Test::SMTP and thought it would be nice to finish it off.

=head1 METHODS

=over

=item set_size($size)

Establishes the size threshold for rejecting messages.

=back

=head1 USAGE

Register the plugin in the ESMTP object, and then call set_size on the object instance

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com
    http://www.pplusdomain.net

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Net::Server::Mail, Net::Server::Mail::ESMTP

=cut

#################### main pod documentation end ###################


1;

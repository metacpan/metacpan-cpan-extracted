package Mojo::SMTP::Client::Exception;
use Mojo::Base 'Mojo::Exception';

package Mojo::SMTP::Client::Exception::Stream;
use Mojo::Base 'Mojo::SMTP::Client::Exception';

package Mojo::SMTP::Client::Exception::Response;
use Mojo::Base 'Mojo::SMTP::Client::Exception';
has 'code';
sub throw { die shift->new->code(shift)->trace(2)->_detect(@_) }

1;

__END__

=pod

=head1 NAME

Mojo::SMTP::Client::Exception - base class for Mojo::SMTP::Client exceptions

=head1 DESCRIPTION

C<Mojo::SMTP::Client::Exception> is a base class for C<Mojo::SMTP::Client> exceptions.
It inherits all events, attributes and methods from L<Mojo::Exception>

=head1 Mojo::SMTP::Client::Exception::Stream

Mojo::SMTP::Client::Exception::Stream - stream exceptions for Mojo::SMTP::Client.

=head1 DESCRIPTION

C<Mojo::SMTP::Client::Exception::Stream> is a class for stream exceptions inside C<Mojo::SMTP::Client>.
It inherits all events, attributes and methods from L<Mojo::SMTP::Client::Exception>.

=head1 Mojo::SMTP::Client::Exception::Response

Mojo::SMTP::Client::Exception::Response - response exceptions for Mojo::SMTP::Client.

=head1 DESCRIPTION

C<Mojo::SMTP::Client::Exception::Response> is a class for response exceptions inside C<Mojo::SMTP::Client>.
It inherits all events, attributes and methods from L<Mojo::SMTP::Client::Exception>.

=head1 ATTRIBUTES

C<Mojo::SMTP::Client::Exception::Response> implements the following new attributes

=head2 code

	my $resp_code = $e->code;
	$e->code($resp_code);

Response code

=head1 METHODS

C<Mojo::SMTP::Client::Exception::Response> redefines the following methods

=head2 throw

	Mojo::SMTP::Client::Exception::Response->throw($resp_code, $msg);
	Mojo::SMTP::Client::Exception::Response->throw($resp_code, $msg, $files);

Throw exception with stacktrace. First argument should contain response code.

=head1 SEE ALSO

L<Mojo::SMTP::Client>, L<Mojo::SMTP::Client::Response>, L<Mojo::Exception>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Net::Amazon::S3::Authorization;
$Net::Amazon::S3::Authorization::VERSION = '0.97';
use Moose 0.85;

# ABSTRACT: Authorization context base class

sub aws_access_key_id {
}

sub aws_secret_access_key {
}

sub aws_session_token {
}

sub authorization_headers {
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Authorization - Authorization context base class

=head1 VERSION

version 0.97

=head1 DESCRIPTION

Authorization context provides an access to authorization informations

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

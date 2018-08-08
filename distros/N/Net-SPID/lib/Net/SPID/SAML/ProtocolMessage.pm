package Net::SPID::SAML::ProtocolMessage;
$Net::SPID::SAML::ProtocolMessage::VERSION = '0.15';
use Moo;

has '_spid' => (is => 'ro', required => 1, weak_ref => 1);  # Net::SPID::SAML

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::ProtocolMessage

=head1 VERSION

version 0.15

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

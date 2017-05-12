package Prosody;
BEGIN {
  $Prosody::AUTHORITY = 'cpan:GETTY';
}
{
  $Prosody::VERSION = '0.007';
}
# ABSTRACT: Library for things around the prosody XMPP server

use Moose;

1;


__END__
=pod

=head1 NAME

Prosody - Library for things around the prosody XMPP server

=head1 VERSION

version 0.007

=head1 DESCRIPTION

This namespace should be used for libaries made for use with L<prosody XMPP server|http://prosody.im/> or plugins of it.

So far I concentrate on implementing the access to the mod_storage_sql database, and will do more general features in future releases.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software & Prosody Distribution Authors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


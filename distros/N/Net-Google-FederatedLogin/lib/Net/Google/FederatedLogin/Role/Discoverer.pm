package Net::Google::FederatedLogin::Role::Discoverer;
{
  $Net::Google::FederatedLogin::Role::Discoverer::VERSION = '0.8.0';
}
# ABSTRACT: something that can find the OpenID endpoint

use Moose::Role;

requires 'perform_discovery';

has ua => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    required    => 1,
);

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Net::Google::FederatedLogin::Role::Discoverer - something that can find the OpenID endpoint

=head1 VERSION

version 0.8.0

=head1 AUTHOR

Glenn Fowler <cebjyre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Glenn Fowler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

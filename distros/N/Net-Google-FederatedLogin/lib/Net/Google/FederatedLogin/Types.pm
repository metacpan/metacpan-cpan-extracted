package Net::Google::FederatedLogin::Types;
{
  $Net::Google::FederatedLogin::Types::VERSION = '0.8.0';
}
# ABSTRACT: Types for Net-Google-FederatedLogin.

use Moose::Util::TypeConstraints;
use Net::Google::FederatedLogin::Extension;

subtype 'Extension_List',
    as 'HashRef[Net::Google::FederatedLogin::Extension]';

coerce 'Extension_List',
    from 'ArrayRef',
    via {my $ret = {map {($_->{uri} => Net::Google::FederatedLogin::Extension->new($_))} @$_};};

no Moose::Util::TypeConstraints;
1;

__END__

=pod

=head1 NAME

Net::Google::FederatedLogin::Types - Types for Net-Google-FederatedLogin.

=head1 VERSION

version 0.8.0

=head1 AUTHOR

Glenn Fowler <cebjyre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Glenn Fowler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

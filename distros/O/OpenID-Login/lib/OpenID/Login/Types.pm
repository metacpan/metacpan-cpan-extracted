package OpenID::Login::Types;
{
  $OpenID::Login::Types::VERSION = '0.1.2';
}

# ABSTRACT: Types for Net-OpenIdLogin.

use Moose::Util::TypeConstraints;
use OpenID::Login::Extension;

subtype 'Extension_List', as 'HashRef[OpenID::Login::Extension]';

coerce 'Extension_List', from 'ArrayRef', via {
    my $ret = { map { ( $_->{uri} => OpenID::Login::Extension->new($_) ) } @$_ };
};

no Moose::Util::TypeConstraints;
1;



=pod

=head1 NAME

OpenID::Login::Types - Types for Net-OpenIdLogin.

=head1 VERSION

version 0.1.2

=head1 AUTHOR

Holger Eiboeck <realholgi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Holger Eiboeck.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


use v5.16;
use warnings;

package Net::Minecraft::Role::LoginResult {

  # ABSTRACT: Generic Login result role


  use Moo::Role;

  requires 'is_success';
};
BEGIN {
  $Net::Minecraft::Role::LoginResult::AUTHORITY = 'cpan:KENTNL';
}
{
  $Net::Minecraft::Role::LoginResult::VERSION = '0.002000';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Minecraft::Role::LoginResult - Generic Login result role

=head1 VERSION

version 0.002000

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::Minecraft::Role::LoginResult",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

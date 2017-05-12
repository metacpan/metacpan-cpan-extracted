package Role::HasMessage;
{
  $Role::HasMessage::VERSION = '0.006';
}
use Moose::Role;
# ABSTRACT: a thing with a message method


requires 'message';

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Role::HasMessage - a thing with a message method

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This is another extremely simple role.  A class that includes
Role::HasMessage is promising to provide a C<message> method that
returns a string summarizing the message or event represented by the object.
It does I<not> provide any actual behavior.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

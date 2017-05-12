package Net::Launchpad::Role::Person;
BEGIN {
  $Net::Launchpad::Role::Person::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Role::Person::VERSION = '2.101';
use Moose::Role;
use Function::Parameters;

with 'Net::Launchpad::Role::Common';

# ABSTRACT: Person roles

method gpg_keys {
    return $self->collection('gpg_keys');
}

method irc_nicks {
    return $self->collection('irc_nicknames');
}

method ppas {
    return $self->collection('ppas');
}

method ssh_keys {
    return $self->collection('sshkeys');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Role::Person - Person roles

=head1 VERSION

version 2.101

=head1 METHODS

=head2 gpg_keys

Returns list a gpg keys registered

=head2 irc_nicks

Returns list of irc nicks

=head2 ppas

Returns list of ppas associated

=head2 ssh_keys

Returns list of public ssh keys

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Net::Launchpad::Role::Query::Person;
BEGIN {
  $Net::Launchpad::Role::Query::Person::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Role::Query::Person::VERSION = '2.101';
# ABSTRACT: Person/People query role

use Moose::Role;
use Function::Parameters;
use Data::Dumper::Concise;

with 'Net::Launchpad::Role::Query';


method find (Str $text) {
    my $params = {
        'ws.op' => 'find',
        text    => $text
    };
    return $self->resource($params);
}



method find_person (Str $text, Str $created_after = undef, Str $created_before = undef) {
    my $params = {
        'ws.op' => 'findPerson',
        text    => $text
    };
    return $self->resource($params);
}


method find_team (Str $text) {
    my $params = {
        'ws.op' => 'findTeam',
        text => $text
    };
    return $self->resource($params);
}



method get_by_email (Str $email) {
    my $params = {
        'ws.op' => 'getByEmail',
        email   => $email
    };
    return $self->resource($params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Role::Query::Person - Person/People query role

=head1 VERSION

version 2.101

=head1 METHODS

=head2 find

Return all non-merged Persons and Teams whose name, displayname or email address match C<text>.

Note: C<Text matching is performed only against the beginning of an email address.>

B<Params>

=head2 find_person

Return all non-merged Persons with at least one email address whose name, displayname or email address match C<text>.

B<Params>

=head2 find_team

Return all Teams whose name, displayname or email address match <text>.

Note: C<Text matching is performed only against the beginning of an email address.>

B<Params>

=head2 get_by_email

Return the person with the given email address.

B<Params>

=for :list * C<Str text>

=for :list * C<Str text>
* C<Str created_before>
* C<Str created_after>

=for :list * C<Str text>

=for :list * C<Str email>

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

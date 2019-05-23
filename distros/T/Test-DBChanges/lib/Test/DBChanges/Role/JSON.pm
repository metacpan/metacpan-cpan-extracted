package Test::DBChanges::Role::JSON;
use Moo::Role;
use JSON::MaybeXS ();
use namespace::autoclean;

our $VERSION = '1.0.0'; # VERSION
# ABSTRACT: decode data that's recorded as JSON


sub decode_recorded_data {
    my ($self, $recoded_data) = @_;

    return JSON::MaybeXS::decode_json($recoded_data);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DBChanges::Role::JSON - decode data that's recorded as JSON

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION

Classes that store changes as JSON should consume this role.

=for Pod::Coverage decode_recorded_data

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

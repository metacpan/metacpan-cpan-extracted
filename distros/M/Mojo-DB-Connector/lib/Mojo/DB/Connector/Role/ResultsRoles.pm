package Mojo::DB::Connector::Role::ResultsRoles;
use Mojo::Base -role;

requires 'new_connection';

has results_roles => sub { [] };

around new_connection => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_)
        unless my @roles = @{ $self->results_roles };

    my $connection = $self->$orig(@_);
    $connection->with_roles('Mojo::DB::Role::ResultsRoles');
    push @{$connection->results_roles}, @roles;

    return $connection;
};

1;
__END__

=encoding utf-8

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojo-DB-Connector"><img src="https://travis-ci.org/srchulo/Mojo-DB-Connector.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojo-DB-Connector?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojo-DB-Connector/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 NAME

L<Mojo::DB::Connector::Role::ResultsRoles> - Apply roles to Mojo database results from Mojo::DB::Connector connections

=head1 SYNOPSIS

  use Mojo::DB::Connector;

  my $connector = Mojo::DB::Connector->new->with_roles('+ResultsRoles');
  push @{ $connector->results_roles }, 'Mojo::DB::Results::Role::Something';

  # elsewhere...
  my $results = $connector->new_connection('my_database')->db->query(...);
  # $results does Mojo::DB::Results::Role::Something

=head1 DESCRIPTION

L<Mojo::DB::Connector::Role::ResultsRoles> allows roles to be applied to the results objects
returned by connections acquired from L<Mojo::DB::Connector>.

L<Mojo::DB::Connector::Role::ResultsRoles> is a wrapper around L<Mojo::DB::Role::ResultsRoles> to make sure
that connections returned by L<Mojo::DB::Connector> do L<Mojo::DB::Role::ResultsRoles> and use the roles
specified in L</results_roles>.

=head1 ATTRIBUTES

=head2 results_roles

  my $roles  = $connector->results_roles;
  $connector = $connector->results_roles(\@roles);

Array reference of roles to compose into results objects. This only affects connection objects (L<Mojo::mysql>, L<Mojo::Pg>)
created by subsequent calls to L<Mojo::DB::Connector/new_connection>.

Note that this is compatible with L<Mojo::DB::Connector::Role::Cache>.

=head1 SEE ALSO

=over 4

=item

L<Mojo::DB::Connector>

=item

L<Mojo::DB::Role::ResultsRoles>

=item

L<Mojo::DB::Connector::Role::Cache>

=back

=head1 LICENSE

This software is copyright (c) 2020 by Adam Hopkins.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=cut

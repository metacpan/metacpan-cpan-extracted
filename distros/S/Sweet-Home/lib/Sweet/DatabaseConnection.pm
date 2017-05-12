package Sweet::DatabaseConnection;
use latest;
use Moose;

use MooseX::AttributeShortcuts;

use namespace::autoclean;

has connection_attributes => (
    is      => 'lazy',
    isa     => 'HashRef',
);

sub _build_connection_attributes {
    return {
        PrintError  => 1,
    }
}

has datasource => (
    is      => 'lazy',
    isa     => 'Str',
);

has username => (
    is      => 'lazy',
    isa     => 'Str',
);

has password => (
    is      => 'lazy',
    isa     => 'Str',
);

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Sweet::DatabaseConnection

=head1 SYNOPSIS

    package My::DatabaseConnection;
    use Moose;

    extends 'Sweet::DatabaseConnection';

    with 'Sweet::Config';

=head1 ATTRIBUTES

=head2 connection_attributes

You may want to override it in a child class, for example to connect to Oracle, with

    sub _build_connection_attributes {
        return {
            PrintError  => 1,
            ora_charset => 'AL32UTF8',
        }
    }

=head2 datasource

=head2 password

=head2 username

=cut


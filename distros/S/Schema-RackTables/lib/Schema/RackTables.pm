package Schema::RackTables;

use utf8;
use strict;
use warnings;

use Carp;
use File::Basename;
use File::Spec::Functions;
use JSON::XS;
use Moo;


our $VERSION = "1.01";

use constant {
    REF_DB_PATH => catfile(dirname($INC{"Schema/RackTables.pm"}),
                        "RackTables", "versions.json")
};


has version         => ( is => "ro" );
has schema          => ( is => "ro" );
has schema_version  => ( is => "ro" );


my $ref_db = decode_json(do {
    open my $fh, "<", REF_DB_PATH or die "Can't read '", REF_DB_PATH, "': $!\n";
    local $/; <$fh>
});

my %schema_for = map { $_->{version} => $_->{schema} } @{$ref_db->{versions}};


#
# list_versions
# -------------
sub list_versions {
    return map { $_->{version} } @{$ref_db->{versions}}
}


#
# BUILDARGS
# ---------
sub BUILDARGS {
    my ($class, @args) = @_;
    my %param;

    if (@args == 1) {
        croak "Single parameters to new() must be a hash reference"
            unless ref $args[0] eq "HASH";
        %param = %{$args[0]};
    }
    else {
        croak "The new() method expects a hash reference or a key/value list"
            unless @args % 2 == 0;
        %param = @args;
    }

    # default to latest version if none requested
    $param{version} //= "latest";
    $param{version} = $ref_db->{versions}[-1]{version}
        if $param{version} eq "latest";

    # validate input version; RackTables only has x.y.z for now
    if ($param{version} =~ /^([0-9]+\.[0-9]+\.[0-9]+)$/) {
        $param{version} = $1;
    }
    else {
        croak "invalid version '$param{version}'";
    }

    # find the schema version corresponding to the request software version
    $param{schema_version} = $schema_for{ $param{version} }
        or croak "invalid version '$param{version}'";

    # load the corresponding schema and instanciate it
    if ($param{schema_version} =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)$/) {
        # convoluted way to fetch the version so that $module isn't tainted
        my $vn = "$1\_$2\_$3";
        my $module = "$class\::$vn";
        eval "require $module" or die $@;
        $param{schema} = $module;
    }
    else {
        die "invalid schema version '$param{schema_version}'\n"
    }

    return \%param
}


__PACKAGE__

__END__

=encoding UTF-8

=head1 NAME

Schema::RackTables - Inventory of the database schemas of RackTables

=head1 SYNOPSIS

    use Schema::RackTables;

    my $app = Schema::RackTables->new(version => "0.17.11");
    my $schema = $app->schema->connect("dbi:...", "...", "...");

=head1 DESCRIPTION

This module is an inventory of the database schemas of the web application
L<RackTables|http://racktables.org/>. Following L<Schema::Bugzilla>'s
principles, it provides access to the database schema of each known version
of the software, from 0.14.4 up to 0.20.11.

=head1 RATIONALE

The idea behind the C<Schema> family of distributions is to give access
to the database schema of each version of the software. This can be useful
to compare the different versions, generate documentation, or make an
API that can handle all versions. A schema version is defined as the
version of the first release that uses it.


=head1 METHODS

=head2 new

Creates and returns a new object. Expects an parameter C<version>.
If not given, will default to the latest known version.

B<Example:>

    my $app = Schema::RackTables->new(version => "0.17.11");

=head2 list_versions

Returns the list of known versions.

B<Example:>

    my @versions = Schema::RackTables->list_versions();


=head1 ATTRIBUTES

=head2 version

The version of the software, as given to C<new>.

=head2 schema_version

The version of the schema corresponding to this version of the software.

=head2 schema

The name of the L<DBIx::Class> schema.


=head1 SUPPORT

The source code is available on Git Hub:
L<https://github.com/maddingue/Schema-RackTables/>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENT

Upon an idea by Emmanuel Seyman

=head1 AUTHOR

Sébastien Aperghis-Tramoni (saper@cpan.org)


package Silki::Schema;
{
  $Silki::Schema::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Carp;
use DBI;
use Fey::ORM::Schema;
use Fey::DBIManager::Source;
use Fey::Loader;
use Silki::Config;
use Silki::I18N;

if ($Silki::Schema::TestSchema) {
    has_schema($Silki::Schema::TestSchema);

    require DBD::Mock;

    my $source = Fey::DBIManager::Source->new( dsn => 'dbi:Mock:' );

    $source->dbh()->{HandleError} = sub { Carp::confess(shift); };

    __PACKAGE__->DBIManager()->add_source($source);
}
else {
    my $connection = Silki::Config->instance()->database_connection();

    my $source = Fey::DBIManager::Source->new(
        %{$connection},
        post_connect => \&_set_dbh_attributes,
    );

    my $schema = Fey::Loader->new( dbh => $source->dbh() )->make_schema();

    has_schema $schema;

    __PACKAGE__->DBIManager()->add_source($source);
}

sub _set_dbh_attributes {
    my $dbh = shift;

    $dbh->{pg_enable_utf8} = 1;

    # In an ideal world, this would cause all non-binary data to be marked as
    # utf-8. See https://rt.cpan.org/Public/Bug/Display.html?id=40199 for
    # details.
    $dbh->do(q{SET CLIENT_ENCODING TO 'UTF8'});

    $dbh->do('SET TIME ZONE UTC');

    $dbh->{HandleError} = sub { Carp::confess(shift) };

    return;
}

sub LoadAllClasses {
    my $class = shift;

    for my $table ( $class->Schema()->tables() ) {
        my $class = 'Silki::Schema::' . $table->name();

        ( my $path = $class ) =~ s{::}{/}g;

        eval "use $class";
        die $@ if $@ && $@ !~ /\Qcan't locate $path/i;
    }
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents the Silki schema

__END__
=pod

=head1 NAME

Silki::Schema - Represents the Silki schema

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut


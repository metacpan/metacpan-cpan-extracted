package Mojolicious::Command::generate::dbicdump;
use Mojo::Base 'Mojolicious::Command';

use DBIx::Class::Schema::Loader qw/make_schema_at/;

has description => "Generate DBIx::Class schema using settings from your app.conf\n";
has usage       => "Usage: $0 generate dbicdump\n";

our $VERSION = '0.1.1';

sub run {
# ----------------------------------------------------------------------------

    my ($self, @args) = @_;

    die "This must be run as part of an existing app"
        unless $ENV{MOJO_APP};

    my $config = $self->app->config;

    # Commandline overrides
    $self->_options( \@args,
        'd|debug'      => \my $debug,
        'dsn=s'        => \my $dsn,
        'dbic=s'       => \(my $dbic = $config->{db}{dbic} ),
        'username=s'   => \my $username,
        'password=s'   => \my $password,
    );

    die 'Expected config value missing: e.g. $config->{db}{dbic} = MyApp::Schema'
        unless ref $config->{db} and $config->{db}{dbic};

    # Build dsn
    unless ($dsn) {
        $dsn = sprintf("dbi:%s:database=%s;host=%s;port=%s;",
                        $config->{db}{driver} || 'mysql',
                        $config->{db}{database},
                        $config->{db}{hostname} || 'localhost',
                        $config->{db}{port} || '3306',
        );
    }

    print "$DBIx::Class::Schema::Loader::VERSION\n" if $debug;

    my $options = {
        debug          => $debug,
        dump_directory => $self->app->home->lib_dir,
        components     => [qw/ InflateColumn::DateTime /],
        use_moose      => 1,
        overwrite_modifications => 1,
        generate_pod   => 0,
        col_collision_map => 'column_%s',
    };

    make_schema_at(
        $dbic, $options,
        [ $dsn, $username, $password, ]
    );
}


return "The coffee made me do it!";
__END__

=head1 NAME

Mojolicious::Command::generate::dbicdump - dbicdump your Mojo app schema

=head1 SYNOPSIS

    # Run with an existing mojolicious app.
    # $app->config->{db}{/database username password/}

    ./my_mojo_app.pl generate dbicdump


=head1 INSTALL

    perl Makefile.PL
    make && make install


=head1 SUPPORT

Please report any bugs, feature request or patches to either:
L<http://search.cpan.org/dist/Mojolicious-Command-generate-dbicdump/>
L<https://github.com/coffeemonster/mojolicious-command-generate-dbicdump/>


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alister West, alister at L<http://alisterwest.com>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 CHANGES

0.1.1   2012-08-31
        - CPANified module

=cut

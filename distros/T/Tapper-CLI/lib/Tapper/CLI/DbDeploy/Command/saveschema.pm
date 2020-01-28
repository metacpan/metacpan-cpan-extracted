package Tapper::CLI::DbDeploy::Command::saveschema;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::DbDeploy::Command::saveschema::VERSION = '5.0.6';
use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Tapper::Model 'model';
use Tapper::CLI::DbDeploy;
use Tapper::Config;
use Data::Dumper;

sub opt_spec {
        return (
                [ "verbose",      "some more informational output"       ],
                [ "really",       "Really do something."                 ],
                [ "db=s",         "STRING, one of: ReportsDB, TestrunDB" ],
                [ "env=s",        "STRING, default=development; one of: live, development, test" ],
                [ "upgradedir=s", "STRING, directory here upgradefiles are stored" ],
               );
}

sub abstract {
        'Save an initial database schema if no previous schema exists'
}

sub usage_desc
{
        my ($self, $opt, $args) = @_;
        my $allowed_opts = join ' ', map { '--'.$_ } $self->_allowed_opts();
        "tapper-db-deploy saveschema --db=DBNAME  [ --verbose | --env=s ]*";
}

sub _allowed_opts {
        my ($self, $opt, $args) = @_;
        my @allowed_opts = map { $_->[0] } $self->opt_spec();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

        #         print "opt  = ", Dumper($opt);
        #         print "args = ", Dumper($args);

        my $ok = 1;
        if (not $opt->{db})
        {
                say "Missing argument --db\n";
                $ok = 0;
        }
        elsif (not $opt->{db} = 'TestrunDB')
        {
                say "Wrong DB name '".$opt->{db}."' (must be TestrunDB)";
                $ok = 0;
        }

        return $ok if $ok;
        die $self->usage->text;
}

sub run
{
        my ($self, $opt, $args) = @_;

        unless ($opt->{really}) {
                say "You nearly never want to call me -- only if no previous schema exists.";
                say "You probably want to call: tapper-db-deploy makeschemadiffs ...";
                say "Or use option --really if you know what you do";
                exit 1;
        }

        local $DBIx::Class::Schema::Versioned::DBICV_DEBUG = 1;

        Tapper::Config::_switch_context($opt->{env});

        my $db         = $opt->{db};
        my $upgradedir = $opt->{upgradedir};
        model($db)->upgrade_directory($upgradedir) if $upgradedir;
        model($db)->create_ddl_dir([qw/MySQL SQLite PostgreSQL/],
                                   undef,
                                   ($upgradedir || model($db)->upgrade_directory)
                                  );
}

# perl -Ilib bin/tapper-db-deploy saveschema --db=TestrunDB

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::DbDeploy::Command::saveschema

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

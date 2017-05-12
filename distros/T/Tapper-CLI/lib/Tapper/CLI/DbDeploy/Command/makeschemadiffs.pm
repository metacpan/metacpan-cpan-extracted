package Tapper::CLI::DbDeploy::Command::makeschemadiffs;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::DbDeploy::Command::makeschemadiffs::VERSION = '5.0.5';
use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';
use Tapper::Model 'model';
use Tapper::CLI::DbDeploy;
use Tapper::Config;
use Data::Dumper;
use File::ShareDir 'module_dir';
use Tapper::Schema; # for module_dir

sub opt_spec {
        return (
                [ "verbose",        "some more informational output"       ],
                [ "db=s",           "STRING, one of: ReportsDB, TestrunDB" ],
                [ "env=s",          "STRING, default=development; one of: live, development, test" ],
                [ "fromversion=s",  "STRING, the version against we make the diff" ],
                [ "upgradedir=s",   "STRING, directory here upgradefiles are stored, default=./upgrades/" ],
               );
}

sub abstract {
        'Save schema diff files for later upgrade'
}

sub usage_desc
{
        my ($self, $opt, $args) = @_;
        my $allowed_opts = join ' ', map { '--'.$_ } $self->_allowed_opts($opt, $args);
        "tapper-db-deploy makeschemadiffs --db=DBNAME  [ --verbose | --env=s ]*";
}

sub _allowed_opts {
        my ($self, $opt, $args) = @_;
        my @allowed_opts = map { $_->[0] } $self->opt_spec();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

        # print "self = ", Dumper($self);
        # print "opt  = ", Dumper($opt);
        # print "args = ", Dumper($args);

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
        if (not $opt->{fromversion})
        {
                say "Missing argument --fromversion\n";
                $ok = 0;
        }

        return $ok if $ok;
        die $self->usage->text;
}

sub run
{
        my ($self, $opt, $args) = @_;

        local $DBIx::Class::Schema::Versioned::DBICV_DEBUG = 1;

        Tapper::Config::_switch_context($opt->{env});

        my $db          = $opt->{db};
        my $fromversion = $opt->{fromversion};
        my $upgradedir  = $opt->{upgradedir} || module_dir('Tapper::Schema');
        model($db)->upgrade_directory($upgradedir) if $upgradedir;
        model($db)->create_ddl_dir([qw/MySQL SQLite PostgreSQL/],
                                   undef,
                                   ($upgradedir || model($db)->upgrade_directory),
                                   $fromversion
                                  );
}


# perl -Ilib bin/tapper-db-deploy makeschemadiffs --db=TestrunDB
# perl -Ilib bin/tapper-db-deploy makeschemadiffs --upgradedir=$HOME/local/projects/Tapper/src/Tapper-Schema/upgrades/ --db=TestrunDB --fromversion=2.010009

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::DbDeploy::Command::makeschemadiffs

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

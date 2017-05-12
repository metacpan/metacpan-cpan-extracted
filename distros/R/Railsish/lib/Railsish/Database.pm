package Railsish::Database;
our $VERSION = '0.21';

# ABSTRACT: Talks to database

# use Any::Moose;
use Moose;
use KiokuDB;
use Railsish::CoreHelpers;
use YAML::Any qw(LoadFile);

has 'config' => (
    is  => "ro",
    isa => "HashRef",
    lazy_build => 1,
    required => 1
);

has 'dsn' => (
    isa => "Str",
    is  => "rw",
    lazy_build => 1
);

has 'kioku' => (
    is => "rw",
    lazy_build => 1
);

sub _build_config {
    my $self = shift;
    my $file = app_root(config => "database.yml");

    die "config/database.yml does not exist\n"
	unless -f $file;

    my $all_config = LoadFile($file);
    my $mode = railsish_mode;
    return $all_config->{$mode};
}

sub _build_dsn {
    my $self = shift;
    my $dsn = $ENV{RAILSISH_TEST_DSN} || $self->config->{dsn};
    return $dsn;
}

sub _build_kioku {
    my $self = shift;
    my $config = $self->config;

    my $dir = KiokuDB->connect(
	$self->dsn,
	create => 1,
	user => $config->{user},
	password => $config->{password}
    );

    # To avoid SQL-01004 error on MSSQL (String right truncation)
    if ($self->dsn =~ /SQL Server/) {
        $dir->backend->storage->dbh->{LongReadLen} = 512 * 1024
    }

    return $dir;
}

sub search {
    my ($self, %args) = @_;
    my $kioku = $self->kioku;
    my $kioku_scope = $kioku->new_scope;

    if (ref($kioku->backend) eq "KiokuDB::Backend::Hash") {
	# With CLASS, it'll never find anything.
	# Hash backend should only be used when testing, so this should be enough for now.
	delete $args{CLASS};
    }
    return $kioku->search(\%args);
}

sub lookup {
    my ($self, @ids) = @_;
    my $kioku = $self->kioku;
    my $kioku_scope = $kioku->new_scope;

    return $kioku->lookup(@ids);
}

sub store {
    my ($self, $obj) = @_;
    my $kioku = $self->kioku;
    my $kioku_scope = $kioku->new_scope;

    $kioku->store($obj);
}

sub object_to_id {
    my ($self, $obj) = @_;
    my $kioku = $self->kioku;
    my $kioku_scope = $kioku->new_scope;
    return $kioku->object_to_id($obj);
}

sub delete {
    my ($self, $obj) = @_;
    my $kioku = $self->kioku;
    $kioku->delete($obj);
}

__PACKAGE__->meta->make_immutable;


__END__
=head1 NAME

Railsish::Database - Talks to database

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License


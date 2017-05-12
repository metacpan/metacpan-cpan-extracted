package Monorail::MigrationScript::Writer;
$Monorail::MigrationScript::Writer::VERSION = '0.4';
use Moose;
use Text::MicroTemplate::DataSection qw(render_mt);
use Text::MicroTemplate qw(encoded_string);
use File::Path qw(make_path);

use namespace::autoclean;

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has basedir => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has dependencies => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has diff => (
    is       => 'ro',
    isa      => 'Monorail::Diff',
    required => 1,
);

has filename => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_filename'
);

has out_filehandle => (
    is      => 'ro',
    isa     => 'FileHandle',
    lazy    => 1,
    builder => '_build_out_filehandle',
);



__PACKAGE__->meta->make_immutable;

=head1 SYNOPSIS

    my $script = Monorail::MigrationScript::Writer->new(
        name    => $name,
        basedir => $self->basedir,
        diff    => $diff
    );

    $script->write_file;


=cut


sub write_file {
    my ($self) = @_;

    my $dependencies    = join('  ', @{$self->dependencies});
    my $upgrade_changes = $self->diff->upgrade_changes;

    my $downgrade_changes = $self->diff->downgrade_changes;

    my $perl = render_mt('migration_script', {
        depends    => encoded_string($dependencies),
        up_steps   => [map { encoded_string($_) } @$upgrade_changes],
        down_steps => [map { encoded_string($_) } @$downgrade_changes],
    });

    my $filename = $self->filename;
    my $fh       = $self->out_filehandle;

    print $fh $perl;
    close($fh) || die "Couldn't close $filename: $!\n";
}


sub _build_filename {
    my ($self) = @_;

    return sprintf("%s/%s.pl", $self->basedir, $self->name);
}

sub _build_out_filehandle {
    my ($self) = @_;

    my $filename = $self->filename;

    make_path($self->basedir);

    open(my $fh, '>', $filename) || die "Couldn't open $filename: $!\n";

    return $fh;
}




1;
__DATA__

@@ migration_script
#!perl
? local $_ = $_[0];

use Moose;

with 'Monorail::Role::Migration';

__PACKAGE__->meta->make_immutable;


sub dependencies {
    return [qw/<?= $_->{depends} ?>/];
}

sub upgrade_steps {
    return [
? foreach my $change (@{$_->{up_steps}}) {
<?= $change ?>,
? }
        # Monorail::Change::RunPerl->new(function => \&upgrade_extras),
    ];
}

sub upgrade_extras {
    my ($dbix) = @_;
    # $dbix gives you access to your DBIx::Class schema if you need to add
    # data do extra work, etc....
    #
    # For example:
    #
    #  $self->dbix->tnx_do(sub {
    #      $self->dbix->resultset('foo')->create(\%stuff)
    #  });
}

sub downgrade_steps {
    return [
? foreach my $change (@{$_->{down_steps}}) {
<?= $change ?>,
? }
        # Monorail::Change::RunPerl->new(function => \&downgrade_extras),
    ];
}

sub downgrade_extras {
    my ($dbix) = @_;
    # Same drill as upgrade_extras - you know what to do!
}

1;

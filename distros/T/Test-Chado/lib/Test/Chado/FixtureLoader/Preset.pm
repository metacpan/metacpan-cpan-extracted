package Test::Chado::FixtureLoader::Preset;
{
  $Test::Chado::FixtureLoader::Preset::VERSION = 'v4.1.1';
}
use Moo;
use Test::Chado;
use File::ShareDir qw/module_dir module_file/;
use DBIx::Class::Fixtures;
use Archive::Tar;
use Types::Standard qw/Str/;
use File::Temp;
use File::Spec::Functions;
use File::Find::Rule;
use File::Basename;

has 'namespace' => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => 'test-chado'
);

sub load_fixtures {
    my ($self) = @_;
    my $staging_temp = File::Temp->newdir;

    my $preset = module_file( 'Test::Chado', 'preset.tar.bz2' );
    my $archive = Archive::Tar->new($preset);
    $archive->setcwd($staging_temp);
    $archive->extract;

    my $fixture = DBIx::Class::Fixtures->new(
        {   config_dir =>
                catdir( module_dir('Test::Chado'), 'fixture_config' )
        }
    );
    for my $config_file ( sort $fixture->available_config_sets ) {
        my $fixture_dir = catdir( $staging_temp, 'fixtures',
            ( ( split /\./, $config_file ) )[0] );
        $fixture->populate(
            {   directory => $fixture_dir,
                no_deploy => 1,
                schema    => $self->dynamic_schema
            }
        );
    }
}

sub load_custom_fixtures {
    my ( $self, $preset ) = @_;

    die "could not find $preset file\n" if !-e $preset;

    my $staging_temp = File::Temp->newdir;
    my $archive      = Archive::Tar->new($preset);
    $archive->setcwd($staging_temp);
    $archive->extract;

    my $config_dir = catdir( $staging_temp, 'config' );
    my $fixture = DBIx::Class::Fixtures->new( { config_dir => $config_dir } );

    my @all_configs = map { basename $_}
        File::Find::Rule->file->name(qr/\.json$/)->in($config_dir);

    for my $config_file (@all_configs) {
        my $fixture_dir = catdir( $staging_temp, 'fixtures',
            ( ( split /\./, $config_file ) )[0] );
        $fixture->populate(
            {   directory => $fixture_dir,
                no_deploy => 1,
                schema    => $self->dynamic_schema
            }
        );
    }
}

with 'Test::Chado::Role::Helper::WithBcs';

1;

__END__

=pod

=head1 NAME

Test::Chado::FixtureLoader::Preset

=head1 VERSION

version v4.1.1

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

#!/usr/bin/perl -w

use strict;
use DBIx::Class::Fixtures;
use Test::Chado::FixtureLoader::FlatFile;
use Test::Chado::Factory::DBManager;
use Path::Class;
use Archive::Tar;
use File::Find::Rule;
use File::Temp;
use FindBin qw/$Bin/;
use feature qw/say/;
use File::Path qw/make_path remove_tree/;

my $dbmanager = Test::Chado::Factory::DBManager->get_instance('sqlite');
my $loader
    = Test::Chado::FixtureLoader::FlatFile->new( dbmanager => $dbmanager );

# load schema and then fixtures from flat files
$dbmanager->deploy_schema;
$loader->load_fixtures;

my $schema      = $loader->schema;
my $share_dir   = Path::Class::Dir->new($Bin)->parent->subdir('share');
my $config_dir  = $share_dir->subdir('fixture_config');
my $tmp_dir = File::Temp->newdir;
my $fixture_dir = Path::Class::Dir->new($tmp_dir)->subdir('fixtures');

my $fixture
    = DBIx::Class::Fixtures->new( { config_dir => $config_dir->stringify } );

my @dirs;
for my $config_file ( sort { $a <=> $b } $fixture->available_config_sets ) {
    my $config_name = ( ( split /\./, $config_file ) )[0];
    my $dump_dir = $fixture_dir->subdir($config_name);
    say "dumping from config file $config_file in $fixture_dir";

    $fixture->dump(
        {   config    => $config_file,
            schema    => $schema,
            directory => $dump_dir
        }
    );
    push @dirs, $fixture_dir;
}

my @files_to_archive;
my $archive      = Archive::Tar->new;
for my $file ( File::Find::Rule->file->in($fixture_dir) ) {
    ( my $strip_file = $file ) =~ s/^$tmp_dir\///;
    my $data = Path::Class::File->new($file)->slurp;
    $archive->add_data( $strip_file, $data );
}
$archive->write( $share_dir->file('preset.tar.bz2'), COMPRESS_BZIP );

=head1 NAME

prepare_fixtures.pl - Generate preset fixtures for chado database


=head1 SYNOPSIS

perl -Iblib/lib maint/prepare_fixture.pl


=head1 REQUIRED ARGUMENTS

B<-Iblib/lib> flag

=head1 BUGS AND LIMITATIONS

No bugs have been reported . Please report any bugs
or feature requests to B<Siddhartha Basu>

=head1 AUTHOR

I<Siddhartha Basu> B<siddhartha-basu@northwestern.edu>

=head1 LICENCE AND COPYRIGHT

        Copyright(c) B <2010>, Siddhartha Basu C
        <<siddhartha-basu @northwestern . edu >> . All rights reserved .

	This module is free software; you can redistribute it and/or
	modify it under the same terms as Perl itself. See L<perlartistic>.


#!/usr/bin/perl

use strict;
use warnings;
use v5.24;

use Archive::Tar;
use Clone qw(clone);
use Mojo::UserAgent;
use Mojo::File qw(curfile path);
use Mojo::IOLoop;
use DBI;

my $base_url  = 'https://download.znuny.org/releases/';
my $ua        = Mojo::UserAgent->new;
my $local_dir = '/tmp';

my $znuny_versions = 
    $ua->get( $base_url )
        ->res
        ->dom
        ->find('a')
        ->grep( sub {
            $_->attr('href') =~ m{\Aznuny-[0-9]+\..*\.tar\.gz\z}xms;
        });

my $db_file   = curfile->sibling( '.znuny_modules.sqlite' );
my $db_exists = -e $db_file;
my $dbh       = DBI->connect( "DBI:SQLite:$db_file" ) or die DBI->errstr();

if ( !$db_exists ) {
    $dbh->do( 'CREATE TABLE modules (modname VARCHAR(255), znuny VARCHAR(10), modtype VARCHAR(4), PRIMARY KEY (modname, znuny) )' );
}

my $sth = $dbh->prepare( 'SELECT DISTINCT znuny FROM modules' );
$sth->execute;

my %znuny_versions;
while ( my ($znuny) = $sth->fetchrow_array ) {
    $znuny_versions{$znuny} = 1;
}

my $insert_sth = $dbh->prepare( 'INSERT INTO modules (modname, znuny, modtype) VALUES (?,?,?)' );

my @promises;

$znuny_versions->each( sub {
    my $file = $_->attr('href');

    my ($major,$minor,$patch) = $file =~ m{ \A znuny - (\d+) \. (\d+) \. (\d+) \.tar\.gz  }xms;

    return if !(defined $major and defined $minor);

    my $znuny = join '.', $major, $minor, $patch;
    return if $znuny_versions{$znuny};

    print STDERR "Try to get $file\n";

    my $local_path = path( $local_dir, $file );
    my $promise = $ua->get_p( $base_url . $file );

    $promise->then( sub {
        my ($tx) = @_;

        say "handling $file...";

        $tx->res->content->asset->move_to( $local_path );
        my $tar              = Archive::Tar->new( $local_path, 1 );
        my @files_in_archive = $tar->list_files;
        my @modules          = grep{ m{ \.pm \z }xms }@files_in_archive;

        my $version = '';

        MODULE:
        for my $module ( @modules ) {
            next MODULE if $module =~ m{/scripts/};

            my ($znuny,$modfile) = $module =~ m{ \A znuny-(\d+\.\d+\.\d+)/(.*) }xms;

            next MODULE if !$modfile;

            my $is_cpan = $modfile =~ m{cpan-lib}xms;

            my $key = $is_cpan ? 'cpan' : 'core';

            next MODULE if !$modfile;

            (my $modulename = $modfile) =~ s{/}{::}g;

            next MODULE if !$modulename;

            $modulename =~ s{\.pm}{}g;
            $modulename =~ s{Kernel::cpan-lib::}{}g if $is_cpan;

            $version = $znuny;

            next MODULE if !$znuny;
            next MODULE if !$modulename;

            $insert_sth->execute( $modulename, $znuny, $key );
        }
    });

    push @promises, $promise;
});

Mojo::IOLoop->start if !Mojo::IOLoop->is_running;

if ( @promises ) {
    my $wait_promise = Mojo::Promise->all( @promises );
    $wait_promise->then( sub { $wait_promise->resolve(1); } )->wait;
}

my $versions_sth = $dbh->prepare( 'SELECT COUNT( DISTINCT znuny ) FROM modules' );
$versions_sth->execute;
my $versions_count;
while (my $count = $versions_sth->fetchrow_array ) {
    $versions_count = $count;
}

print STDERR "# Versions: $versions_count\n";

my %global;
my $global_sth = $dbh->prepare( 'SELECT modname, modtype, COUNT(znuny) AS versions FROM modules GROUP BY modname HAVING versions = ' . $versions_count ) or die $dbh->errstr;
$global_sth->execute( ) or die $dbh->errstr;

while ( my ($name,$type,$count) = $global_sth->fetchrow_array ) {
    $global{$type}->{$name} = 1;
}

my %hash;
my $local_sth = $dbh->prepare( 'SELECT modname, modtype, znuny FROM modules' );
$local_sth->execute;

while ( my ($name,$type,$znuny) = $local_sth->fetchrow_array ) {
    next if $global{$type}->{$name};

    $hash{$znuny}->{$type}->{$name} = 1;
}

$Data::Dumper::Sortkeys = 1;


my $dist_ini_content = curfile->dirname->child(qw/.. dist.ini/)->slurp;

my ($dist_version)  = $dist_ini_content =~ m{version \s* = \s* (.*?)\n}xms;
my ($dist_author)   = $dist_ini_content =~ m{author \s* = \s* (.*?)\n}xms;
my ($dist_license)  = $dist_ini_content =~ m{license \s* = \s* (.*?)\n}xms;
my ($dist_c_holder) = $dist_ini_content =~ m{copyright_holder \s* = \s* (.*?)\n}xms;
my ($dist_c_year)   = $dist_ini_content =~ m{copyright_year \s* = \s* (.*?)\n}xms;
my $license_class   = 'Software::License::' . $dist_license;
eval "require $license_class;";

my $license_obj = $license_class->new({ holder => $dist_c_holder, year => $dist_c_year });

my $dist_copyright = $license_obj->notice;

if ( open my $fh, '>', 'corelist' ) {
    print $fh q~package Module::Znuny::CoreList;

# ABSTRACT: what modules shipped with versions of Znuny (>= 2.3.x)

use strict;
use warnings;
use 5.008;

~;

    print $fh "\n\n";

    print $fh "our \$VERSION = $dist_version;\n\n";

    $Data::Dumper::Indent = 0;

    my $global_dump = Data::Dumper->Dump( [\%global], ['global'] );
    $global_dump =~ s{\$global}{my \$global};
    print $fh $global_dump;

    print $fh "\n";

    my $modules_dump = Data::Dumper->Dump( [\%hash], ['modules'] );
    $modules_dump =~ s{\$modules}{my \$modules};
    print $fh $modules_dump;

    print $fh "\n\n";

    print $fh q#sub shipped {
    my ($class,$version,$module) = @_;

    return if !$version;
    return if $version !~ m{ \A [0-9]+\.[0-9]\.(?:[0-9]+|x) \z }xms;

    $version =~ s{\.}{\.}g;
    $version =~ s{x}{.*};

    my $version_re = qr{ \A $version \z }xms;

    my @versions_with_module;

    ZnunyVERSION:
    for my $znuny_version ( sort keys %{$modules} ) {
        next unless $znuny_version =~ $version_re;

        if ( $modules->{$znuny_version}->{core}->{$module} ||
             $modules->{$znuny_version}->{cpan}->{$module} ||
             $global->{core}->{$module} ||
             $global->{cpan}->{$module} ) {
            push @versions_with_module, $znuny_version;
        }
    }

    return @versions_with_module;
}

sub modules {
    my ($class,$version) = @_;

    return if !$version;
    return if $version !~ m{ \A [0-9]+\.[0-9]\.(?:[0-9]+|x) \z }xms;

    $version =~ s{\.}{\.}g;
    $version =~ s{x}{.*};

    my $version_re = qr{ \A $version \z }xms;
    my %modules_in_znuny;

    ZnunyVERSION:
    for my $znuny_version ( keys %{$modules} ) {
        next unless $znuny_version =~ $version_re;

        my $hashref = $modules->{$znuny_version}->{core};
        my @modulenames = keys %{$hashref || {}};

        @modules_in_znuny{@modulenames} = (1) x @modulenames;
    }

    if ( $version =~ m{x} || exists $modules->{$version} ) {
        my @global_modules = keys %{ $global->{core} };
        @modules_in_znuny{@global_modules} = (1) x @global_modules;
    }

    return sort keys %modules_in_znuny;
}

sub cpan_modules {
    my ($class,$version) = @_;

    return if !$version || $version !~ m{ \A [0-9]+\.[0-9]\.(?:[0-9]+|x) \z }xms;

    $version =~ s{\.}{\.}g;
    $version =~ s{x}{.*};

    my $version_re = qr{ \A $version \z }xms;

    my %modules_in_znuny;

    VERSION:
    for my $znuny_version ( keys %{ $modules } ) {
        next VERSION unless $znuny_version =~ $version_re;

        my $hashref = $modules->{$znuny_version}->{cpan};
        my @modulenames = keys %{$hashref || {}};

        @modules_in_znuny{@modulenames} = (1) x @modulenames;
    }

    if ( $version =~ m{x} || exists $modules->{$version} ) {
        my @global_modules = keys %{ $global->{cpan} };
        @modules_in_znuny{@global_modules} = (1) x @global_modules;
    }

    return sort keys %modules_in_znuny;
}

1;

__END__

=for Pod::Coverage modules shipped cpan_modules

#;

    open my $pod_fh, '>', curfile->dirname->child( qw/.. lib Module Znuny CoreList.pod/ )->to_string;
print $pod_fh qq~# PODNAME: Module::Znuny::CoreList

~;

print $pod_fh q~=head1 SYNOPSIS

 use Module::Znuny::CoreList;

 my @znuny_versions = Module::Znuny::CoreList->shipped(
    '6.0.x',
    'Kernel::System::DB',
 );

 # returns (6.0.31, 6.0.32, ...)

 my @modules = Module::Znuny::CoreList->modules( '6.0.32' );
 my @modules = Module::Znuny::CoreList->modules( '6.1.x' );

 # methods to check for CPAN modules shipped with Znuny

 my @cpan_modules = Module::Znuny::CoreList->cpan_modules( '6.0.x' );

 my @znuny_versions = Module::Znuny::CoreList->shipped(
    '6.0.x',
    'CGI',
 );

~;

print $pod_fh qq~
=head1 AUTHOR

$dist_author

=head1 COPYRIGHT AND LICENSE

$dist_copyright
~;

}

#!/usr/bin/perl

use strict;
use warnings;
use v5.24;

use Archive::Tar;
use Data::Dumper;
use Mojo::UserAgent;
use Mojo::File qw(curfile path);
use Mojo::IOLoop;
use Mojo::Loader qw(data_section);
use Mojo::Template;
use DBI;
use Time::Piece;

use experimental 'signatures';

my $base_url  = 'https://download.znuny.org/releases/';
my $ua        = Mojo::UserAgent->new;
my $local_dir = '/tmp';

my $znuny_versions = get_all_versions( $ua, $base_url );
my $dbh            = get_dbh();
my $versions_in_db = get_znuny_versions_in_db( $dbh );

my $new_versions = handle_new_versions( $znuny_versions, $versions_in_db, $dbh );
my $count        = print_nr_of_versions_in_db( $dbh );

exit if !$new_versions->@*;

my $dist_info = update_dist_ini();
create_module( $count, $dist_info );
update_changes( $dist_info->{version}, $new_versions );


sub update_dist_ini {
    my $dist_ini = curfile->dirname->child(qw/.. dist.ini/);
    my $content  = $dist_ini->slurp;

    $content =~ s{version\s*=\s*(?<major>\d+\.)\K(?<minor>\d+)}{sprintf "%02d", $1+1}xmse;
    my $version = $+{major} . sprintf( "%02d", $+{minor} + 1 );

    $dist_ini->spurt( $content );

    my ($dist_author)   = $content =~ m{author \s* = \s* (.*?)\n}xms;
    my ($dist_license)  = $content =~ m{license \s* = \s* (.*?)\n}xms;
    my ($dist_c_holder) = $content =~ m{copyright_holder \s* = \s* (.*?)\n}xms;
    my ($dist_c_year)   = $content =~ m{copyright_year \s* = \s* (.*?)\n}xms;
    my $license_class   = 'Software::License::' . $dist_license;
    eval "require $license_class;";

    my $license_obj = $license_class->new({ holder => $dist_c_holder, year => $dist_c_year });
    my $dist_copyright = $license_obj->notice;

    my %info = (
        version   => $version,
        author    => $dist_author,
        copyright => $dist_copyright,
    );

    return \%info;
}

sub update_changes ( $version, $new ) {
    my $changes = curfile->dirname->child(qw/.. Changes/);
    my $content = $changes->slurp;

    my $today             = localtime;
    my $date              = $today->ymd . ' ' . $today->hms;
    my $list_new_versions = join "\n", map { "  * Added Znuny version " . $_ } $new->@*;
    my $new_version       = $version . "    " . $date . "\n\n" . $list_new_versions;

    $content =~ s{^=+\K}{\n\n$new_version}xms;

    $changes->spurt( $content );
}

sub get_all_versions( $ua, $url ) {
    my $znuny_versions =
        $ua->get( $base_url )
            ->res
            ->dom
            ->find('a')
            ->grep( sub {
                $_->attr('href') =~ m{\Aznuny-[0-9]+\..*\.tar\.gz\z}xms;
            });

    return $znuny_versions;
}

sub get_dbh {
    my $db_file   = curfile->sibling( '.znuny_modules.sqlite' );
    my $db_exists = -e $db_file;
    my $dbh       = DBI->connect( "DBI:SQLite:$db_file" ) or die DBI->errstr();

    if ( !$db_exists ) {
        $dbh->do( 'CREATE TABLE modules (modname VARCHAR(255), znuny VARCHAR(10), modtype VARCHAR(4), PRIMARY KEY (modname, znuny) )' );
    }

    return $dbh;
}

sub get_znuny_versions_in_db ( $dbh ) {
    my $sth = $dbh->prepare( 'SELECT DISTINCT znuny FROM modules' );
    $sth->execute;

    my %znuny_versions;
    while ( my ($znuny) = $sth->fetchrow_array ) {
        $znuny_versions{$znuny} = 1;
    }

    return \%znuny_versions;
}

sub handle_new_versions ( $all_versions, $db_versions, $dbh ) {
    my $insert_sth = $dbh->prepare( 'INSERT INTO modules (modname, znuny, modtype) VALUES (?,?,?)' );

    my @new_versions;
    my @promises;

    $all_versions->each( sub {
        my $file = $_->attr('href');

        my ($major,$minor,$patch) = $file =~ m{ \A znuny - (\d+) \. (\d+) \. (\d+) \.tar\.gz  }xms;

        return if !(defined $major and defined $minor);

        my $znuny = join '.', $major, $minor, $patch;
        return if $db_versions->{$znuny};

        push @new_versions, $znuny;

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

    return \@new_versions;
}

sub print_nr_of_versions_in_db( $dbh ) {
    my $versions_sth = $dbh->prepare( 'SELECT COUNT( DISTINCT znuny ) FROM modules' );
    $versions_sth->execute;

    my $versions_count;
    while (my $count = $versions_sth->fetchrow_array ) {
        $versions_count = $count;
    }

    print STDERR "# Versions: $versions_count\n";

    return $versions_count;
}

sub _build_module_info ( $versions_count ) {
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

    return \%global, \%hash;
}

sub create_module ( $nr_versions, $dist_info ) {
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent = 0;

    my ($global, $hash) = _build_module_info( $nr_versions );

    my $global_dump = Data::Dumper->Dump( [$global], ['global'] );
    $global_dump =~ s{\$global}{my \$global};

    my $modules_dump = Data::Dumper->Dump( [$hash], ['modules'] );
    $modules_dump =~ s{\$modules}{my \$modules};

    my $base_dir = curfile->dirname->child(qw/.. lib Module Znuny/);
    my $mt       = Mojo::Template->new->vars(1);

    # create module code
    my $module_code = $mt->render(
        data_section( __PACKAGE__, 'module.txt' ),
        {
            global  => $global_dump,
            modules => $modules_dump,
            end     => '__END__',
        }
    );

    # save to file
    $base_dir->child(qw/CoreList.pm/)->spurt(
        $module_code
    );

    # create documentation
    my $documentation = $mt->render(
        data_section( __PACKAGE__, 'documentation.txt' ),
        {
            dist_author    => $dist_info->{author},
            dist_copyright => $dist_info->{copyright},
        }
    );

    # save to file
    $base_dir->child(qw/CoreList.pod/)->spurt(
        $documentation
    );
}

__DATA__
@@ module.txt
package Module::Znuny::CoreList;

# ABSTRACT: what modules shipped with versions of Znuny (>= 6.0.30)

use strict;
use warnings;
use 5.008;

# VERSION

<%= $global %>
<%= $modules %>

sub shipped {
    my ($class,$version,$module) = @_;

    my $version_re = $class->_version_re( $version );
    return if !$version_re;

    return if !$module;

    my @versions_with_module;

    ZNUNYVERSION_SHIPPED:
    for my $znuny_version ( sort keys %{$modules} ) {
        next ZNUNYVERSION_SHIPPED unless $znuny_version =~ $version_re;

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

    my $version_re = $class->_version_re( $version );
    return if !$version_re;

    my %modules_in_znuny;

    ZNUNYVERSION_MODULE:
    for my $znuny_version ( keys %{$modules} ) {
        next ZNUNYVERSION_MODULE unless $znuny_version =~ $version_re;

        my $hashref = $modules->{$znuny_version}->{core};
        my @modulenames = keys %{$hashref || {}};

        @modules_in_znuny{@modulenames} = (1) x @modulenames;
    }

    if ( $version =~ m{x} || exists $modules->{$version} ) {
        my @global_modules = keys %{ $global->{core} };
        @modules_in_znuny{@global_modules} = (1) x @global_modules;
    }

    my @modules = sort keys %modules_in_znuny;
    return @modules;
}

sub cpan_modules {
    my ($class,$version) = @_;

    my $version_re = $class->_version_re( $version );
    return if !$version_re;

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

    my @modules = sort keys %modules_in_znuny;
    return @modules;
}

sub _version_re {
    my ($class,$version) = @_;

    return if !$version || $version !~ m{ \A [0-9]+\.[0-9]\.(?:[0-9]+|x) \z }xms;

    $version =~ s{\.}{\.}g;
    $version =~ s{x}{.*};

    my $version_re = qr{ \A $version \z }xms;

    return $version_re;
}

1;

<%= $end %>

=for Pod::Coverage modules shipped cpan_modules

@@ documentation.txt
# PODNAME: Module::Znuny::CoreList

=head1 SYNOPSIS

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

=head1 METHODS

=head2 modules

returns a list of Core modules shipped with a given Znuny version

=head2 shipped

returns a list of Znuny versions that ships a given module

=head2 cpan_modules

returns a list of CPAN modules that are shipped with a given Znuny version

=head1 AUTHOR

<%= $dist_author %>

=head1 COPYRIGHT AND LICENSE

<%= $dist_copyright %>

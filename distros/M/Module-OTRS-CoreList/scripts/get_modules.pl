#!/usr/bin/perl

use strict;
use warnings;

use Archive::Tar;
use Clone qw(clone);
use Data::Dumper;
use FindBin ();
use File::Basename;
use File::Spec;
use File::Temp;
use Net::FTP;
use DBI;

my $ftp_host  = 'ftp.otrs.org';
my $local_dir = File::Temp::tempdir();
my @dirs      = qw(pub otrs);

my $ftp = Net::FTP->new( $ftp_host, Debug => 0 );
$ftp->login();

for my $dir ( @dirs ) {
    $ftp->cwd( $dir );
}

my @files   = $ftp->ls;
my @tar_gz  = grep{ m{ \.tar\.gz \z }xms }@files;
my @no_beta = grep{ !m{ -beta }xms }@tar_gz;

my $db_file   = File::Spec->catfile( dirname( __FILE__ ), '.otrs_modules.sqlite' );
my $db_exists = -e $db_file;
my $dbh       = DBI->connect( "DBI:SQLite:$db_file" ) or die DBI->errstr();

if ( !$db_exists ) {
    $dbh->do( 'CREATE TABLE modules (modname VARCHAR(255), otrs VARCHAR(10), modtype VARCHAR(4), PRIMARY KEY (modname, otrs) )' ); 
}

my $sth = $dbh->prepare( 'SELECT DISTINCT otrs FROM modules' );
$sth->execute;

my %otrs_versions;
while ( my ($otrs) = $sth->fetchrow_array ) {
    $otrs_versions{$otrs} = 1;
}

my $insert_sth = $dbh->prepare( 'INSERT INTO modules (modname, otrs, modtype) VALUES (?,?,?)' );

FILE:
for my $file ( @no_beta ) {
    my ($major,$minor,$patch) = $file =~ m{ \A otrs - (\d+) \. (\d+) \. (\d+) \.tar\.gz  }xms;
    
    next FILE if !(defined $major and defined $minor);
    
    next FILE if $major < 2;
    next FILE if $major == 2 and $minor < 3;

    my $otrs = join '.', $major, $minor, $patch;
    next FILE if $otrs_versions{$otrs};
    
    print STDERR "Try to get $file\n";
    
    my $local_path = File::Spec->catfile( $local_dir, $file );
    
    $ftp->binary;
    $ftp->get( $file, $local_path );
    
    my $tar              = Archive::Tar->new( $local_path, 1 );
    my @files_in_archive = $tar->list_files;
    my @modules          = grep{ m{ \.pm \z }xms }@files_in_archive;
    
    my $version = '';
    
    MODULE:
    for my $module ( @modules ) {
        next MODULE if $module =~ m{/scripts/};
    
        my ($otrs,$modfile) = $module =~ m{ \A otrs-(\d+\.\d+\.\d+)/(.*) }xms;

        next MODULE if !$modfile;

        my $is_cpan = $modfile =~ m{cpan-lib}xms;
        
        my $key = $is_cpan ? 'cpan' : 'core';

        next MODULE if !$modfile;
        
        (my $modulename = $modfile) =~ s{/}{::}g;

        next MODULE if !$modulename;

        $modulename =~ s{\.pm}{}g;
        $modulename =~ s{Kernel::cpan-lib::}{}g if $is_cpan;
        
        $version = $otrs;

        next MODULE if !$otrs;
        next MODULE if !$modulename;

        $insert_sth->execute( $modulename, $otrs, $key );
    }
}

my $versions_sth = $dbh->prepare( 'SELECT COUNT( DISTINCT otrs ) FROM modules' );
$versions_sth->execute;
my $versions_count;
while (my $count = $versions_sth->fetchrow_array ) {
    $versions_count = $count;
}

print STDERR "# Versions: $versions_count\n";

my %global;
my $global_sth = $dbh->prepare( 'SELECT modname, modtype, COUNT(otrs) AS versions FROM modules GROUP BY modname HAVING versions = ' . $versions_count ) or die $dbh->errstr;
$global_sth->execute( ) or die $dbh->errstr;

while ( my ($name,$type,$count) = $global_sth->fetchrow_array ) {
    $global{$type}->{$name} = 1;
}

my %hash;
my $local_sth = $dbh->prepare( 'SELECT modname, modtype, otrs FROM modules' );
$local_sth->execute;

while ( my ($name,$type,$otrs) = $local_sth->fetchrow_array ) {
    next if $global{$type}->{$name};

    $hash{$otrs}->{$type}->{$name} = 1;
}

$Data::Dumper::Sortkeys = 1;


my $dist_ini_content = do{ local (@ARGV,$/) = File::Spec->catfile( dirname( __FILE__ ), '..', 'dist.ini' ); <> };

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
    print $fh q~package Module::OTRS::CoreList;

# ABSTRACT: what modules shipped with versions of OTRS (>= 2.3.x) 

use strict;
use warnings;

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

    OTRSVERSION:
    for my $otrs_version ( sort keys %{$modules} ) {
        next unless $otrs_version =~ $version_re;

        if ( $modules->{$otrs_version}->{core}->{$module} ||
             $modules->{$otrs_version}->{cpan}->{$module} ||
             $global->{core}->{$module} ||
             $global->{cpan}->{$module} ) {
            push @versions_with_module, $otrs_version;
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
    my %modules_in_otrs;

    OTRSVERSION:
    for my $otrs_version ( keys %{$modules} ) {
        next unless $otrs_version =~ $version_re;

        my $hashref = $modules->{$otrs_version}->{core};
        my @modulenames = keys %{$hashref || {}};

        @modules_in_otrs{@modulenames} = (1) x @modulenames;
    }

    if ( $version =~ m{x} || exists $modules->{$version} ) {
        my @global_modules = keys %{ $global->{core} };
        @modules_in_otrs{@global_modules} = (1) x @global_modules;
    }

    return sort keys %modules_in_otrs;
}

sub cpan_modules {
    my ($class,$version) = @_;

    return if !$version || $version !~ m{ \A [0-9]+\.[0-9]\.(?:[0-9]+|x) \z }xms;

    $version =~ s{\.}{\.}g;
    $version =~ s{x}{.*};

    my $version_re = qr{ \A $version \z }xms;

    my %modules_in_otrs;

    OTRSVERSION:
    for my $otrs_version ( keys %{ $modules } ) {
        next unless $otrs_version =~ $version_re;

        my $hashref = $modules->{$otrs_version}->{cpan};
        my @modulenames = keys %{$hashref || {}};

        @modules_in_otrs{@modulenames} = (1) x @modulenames;
    }

    if ( $version =~ m{x} || exists $modules->{$version} ) {
        my @global_modules = keys %{ $global->{cpan} };
        @modules_in_otrs{@global_modules} = (1) x @global_modules;
    }

    return sort keys %modules_in_otrs;
}

1;

__END__

=for Pod::Coverage modules shipped cpan_modules

#;

    open my $pod_fh, '>', $FindBin::Bin . '/../lib/Module/OTRS/CoreList.pod';
print $pod_fh qq~# PODNAME: Module::OTRS::CoreList

=head1 NAME

Module::OTRS::CoreList - what modules shipped with versions of OTRS (>= 2.3.x)

=head1 VERSION

version $dist_version

~;

print $pod_fh q~=head1 SYNOPSIS

 use Module::OTRS::CoreList;

 my @otrs_versions = Module::OTRS::CoreList->shipped(
    '2.4.x',
    'Kernel::System::DB',
 );
 
 # returns (2.4.0, 2.4.1, 2.4.2,...)
 
 my @modules = Module::OTRS::CoreList->modules( '2.4.8' );
 my @modules = Module::OTRS::CoreList->modules( '2.4.x' );
 
 # methods to check for CPAN modules shipped with OTRS
 
 my @cpan_modules = Module::OTRS::CoreList->cpan_modules( '2.4.x' );

 my @otrs_versions = Module::OTRS::CoreList->shipped(
    '3.0.x',
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

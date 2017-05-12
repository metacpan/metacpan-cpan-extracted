package Package::Builder;
require      Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(extractArchive isReservedDir isDocFile isConfigFile substituteAliasDir getChangeLogs checkVersionFormat checkReleaseFormat getParameterFromConfig getSpecTemplate);    # Symbols to be exported by default
use warnings;
use strict;

use Cwd;
use Text::Template;
use Archive::Tar;
use File::stat;
use File::Path;
use Getopt::Long;
use File::Find;
use File::Basename;
use File::Spec;

use Package::Utils;
=head1 NAME

Package::Builder - The great new Package::Builder!

=head1 VERSION

Version 5.01

=cut

our $VERSION = '5.03';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Package::Builder;

    my $foo = Package::Builder->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=cut

our %user_infos  = getUserMap();
our %group_infos = getGroupMap();

our @reserved_dirs = (
    '^\/bin$',    '^\/sbin$',       '^\/dev$',      '^\/home$',
    '^\/lib$',    '^\/media$',      '^\/mnt$',      '^\/proc$',
    '^\/srv$',    '^\/tmp$',        '^\/var\/log$', '^\/var\/lib$',
    '^\/var$',    '^\/boot$',       '^\/etc$',      '^\/etc\/rc.d',
    '^\/initrd$', '^\/lost+found$', '^\/root$',     '^\/selinux$',
    '^\/sys$',    '^\/usr$',        '\/usr\/sbin$', '\/usr\/bin$'
);

our @config_pattern = (
    "config", "conf",, "etc",
    "initrd", "\.conf", "\.properties", "\.cnf",
    "\.ini",  "\.xml"
);
our @doc_pattern =
  ( "doc", "\.txt", "README", "LICENCE", "LICENSE", "TODO", "\.html", "\.tex" );

my %dirAlias = (
    "/usr/sbin"    => "%{_sbindir}",
    "/usr/bin"     => "%{_bindir}",
    "/usr/lib"     => "%{_libdir}",
    "/usr/libexec" => "%{_libexecdir}",
    "/usr/share"   => "%{_datadir}",
    "/var"         => "%{_var}"
);

our $macrosFile = $ENV{'HOME'} . "/.rpmmacros";

our $topdir          = getParameterFromConfig( "_topdir", "/usr/src/redhat" );
our $specDir         = $topdir . "/SPECS";
our $srcDir          = $topdir . "/SOURCES";
our $archiveRootPath = "/tmp/myrpm";

=head1 FUNCTIONS

=head2 extractArchive

=cut
sub extractArchive {
	my $archive = shift;
	my $root_dir = shift;
	my $uid = shift;
	my $gid = shift;

    # Create temporary dir
    my $snap_dir = "$archiveRootPath/$$";
    my $tmp_dir  = "$snap_dir/$root_dir";
    eval { mkpath($tmp_dir) };
    if ($@) {
        print STDERR "\n * Couldn't create $tmp_dir: $@";
	return undef;
    }
    my $cwdir = getcwd;
    chdir $tmp_dir;

    my $compressed_archive = ( $archive =~ /.+?\.(?:tar\.gz|tgz)$/i );
    my $arch_obj = Archive::Tar->new( $archive, $compressed_archive );
    $arch_obj->extract();

    if ( defined $uid && defined $gid ) {
    #change uid if necessary
    $uid = getUserId($uid);
    $gid = getGroupId($gid);
    find(
        sub {
            chown $uid, $gid, $_;
        },
        $tmp_dir
    );
    }
    chdir $cwdir;

    return $snap_dir;
}
=head2 isReservedDir

=cut
sub isReservedDir {
    my $dir = shift;
    foreach my $rdir (@reserved_dirs) {
        return 1 if ( $dir =~ /$rdir/ );
    }
    return 0;
}

=head2 isDocFile

=cut
sub isDocFile {
    my $file = shift;
    foreach my $dpat (@doc_pattern) {
        return 1 if ( $file =~ /$dpat/ );
    }
    return 0;
}

=head2 isConfigFile

=cut
sub isConfigFile {
    my $file = shift;
    foreach my $cpat (@config_pattern) {
        return 1 if ( $file =~ /$cpat/ );
    }
    return 0;
}

=head2 substituteAliasDir

=cut
sub substituteAliasDir {
    my $path = shift;

    #my $not_found=1;
    foreach my $subpath ( keys %dirAlias ) {

        #break unless ($not_found);
        if ( $path =~ /^$subpath/ ) {
            my $alias = $dirAlias{$subpath};
            $path =~ s/^$subpath/$alias/;
            return $path;
        }
    }
    return $path;
}


=head2 getChangeLogs

=cut
sub getChangeLogs {
    my $specFile = shift;
    return '' unless ( -f $specFile );
    my @lines                = getFileContents($specFile);
    my @changeLogs           = ();
    my $changeLogHeaderFound = 0;
    foreach (@lines) {
        push @changeLogs, $_ if $changeLogHeaderFound == 1;
        $changeLogHeaderFound = 1 if /^%changelog/;
    }
    return join( '', @changeLogs );
}

=head2 checkVersionFormat

=cut
sub checkVersionFormat {
	my $ret=undef;
	my $version=shift;
  	$ret=1 unless ( $version =~ /^[0-9][0-9\.]*$/ );
	return $ret;
}

=head2 checkReleaseFormat

=cut
sub checkReleaseFormat {
	my $ret=undef;
	my $release=shift;
  	$ret=1 unless ( $release =~ /^[1-9][0-9]*$/ );
	return $ret;
}

=head2 getParameterFromConfig
Retrieve value from files (like .rpmmacros)
=cut
sub getParameterFromConfig {
    my $parameter = shift;

    my $res    = shift;
    my $opened = 1;
    open( MACROS, $macrosFile ) || ( $opened = 0 );
    if ($opened) {
        while (<MACROS>) {
            if (m/^\%$parameter\s+(.*)$/) {
                $res = $1;
            }
        }

        close(MACROS);
    }
    return $res;
}

=head2 getSpecTemplate

=cut
sub getSpecTemplate {
############################
    # THE TEMPLATE
############################
    my $defaultSpecTemplate = 'Summary: 		<$summary> 
Name:			<$name>
Version: 		<$version>
Release:	   	<$release>	
License: 		GPL
URL: 			<$vendor_url>
Source0: 		%{name}-%{version}.tar.gz
Group: 			System/Administration
Vendor:			<$vendor>
Packager:		<$packager>
#Arch: 			<$archi>
<if (@reqs == 0 ) {$OUT.="AutoReqProv: 		no"; } >
BuildRoot: 		%{_tmppath}/%{name}-%{version}-root
< foreach $req (@reqs) { $OUT.= "Requires: $req\n"; }>
%description 
<$description>

< if (@defConfFiles != 0) { 
$OUT.="%package config
Summary: Configuration for $name
Group: System/Administration

%description config
Configuration files for $name
$description";
} >
<if (@defDocFiles != 0) {
$OUT.="%package doc
Summary: Documentation for $name
Group: System/Administration

%description doc
Documentation files for $name
$description"; 
} >
%prep
#%setup -q 
#-n %{name}-%{version}
%setup -c -q

%build
<$build_code>
%install
rm -Rf %{buildroot}
mkdir -p %{buildroot}/usr/lib/debug

#Directory installation
< foreach $i (@instDirs) {
	$comment=$$i{comment};
	$file=$$i{file};
	$mode=$$i{mode};
	$path=$$i{path};
	$OUT.= "#Uncomment if needed - consider as a reserved dir\n#" if ($comment);
	$OUT.="%{__install} -d -m $mode $file %{buildroot}$path\n";

}>
#Files installation
< foreach $i (@instFiles) {
	$file=$$i{file};
	$mode=$$i{mode};
	$path=$$i{path};
        $OUT.= "%{__mkdir_p} `dirname %{buildroot}$path` || true\n";
	$OUT.= "%{__install} -m $mode $file %{buildroot}$path\n";
}>
%pre
< if (@groups == 0 ) {
	$OUT.="# No group Creation";
} else {
	$OUT.="# Group creation"; 
	foreach $i (@groups) {
		$gid=$$i{gid};
		$gname=$$i{name};
		$OUT.="\ngroupadd -g $gid $gname || true";
	}
}
if (@users == 0 ) {
	$OUT.="\n# No User Creation";
} else {
	$OUT.="\n# User creation"; 
	foreach $i (@users) {
		$uname=$$i{name};
		$gid=$$i{gid};
		$shell=$$i{shell};
		$home=$$i{home};
		$comment=$$i{comment};
		$uid=$$i{uid};
		$is_init=$$i{init};

		$OUT.="\nUSER_NEW=0";
		$OUT.="\nadduser -u $uid -g $gid -s $shell -d $home -c \"$comment\" $uname && USER_NEW=1 || true";
		if ($is_init) {	
			$OUT.="\nif [ \"\$USER_NEW\" -eq \"1\" ]; then";
			$OUT.="\n\t# Changing password for non priviliged user";
			$OUT.="\n\techo $uname | passwd --stdin $uname";
			$OUT.="\nfi";
		}
	}
}>

< $OUT.="\n$pre_code";>

%post< foreach $i (keys %symbolic_links) {
	$link=$i;
	$pointee=$symbolic_links{$i};
	$OUT.="\n#Symbolic link $i - $pointee";
	$OUT.="\ncd `dirname $i`";
        $OUT.="\nrm -fv `basename $i`";
        $OUT.="\nln -fvs $pointee `basename $i`";
	$OUT.="\ncd -"; 
}>
<$post_code>
%preun
<$preun_code>
%postun
<$postun_code>
%clean
rm -Rf %{buildroot}

#Regular file and dir list
%files
< foreach $i (@listOfFiles) { 
	$mode=$$i{mode};
	$path=$$i{r_path};
	$comment=$$i{comment};
	$uid=$$i{uid};
	$gid=$$i{gid};
	$OUT.="#Uncomment if needed !\n#" if (defined $comment);
	$OUT.="%attr($mode $uid, $gid) ";
	$OUT.="%dir " if ($$i{isDir});
 	$OUT.="$path\n"; 
}>
< if ( @listOfConfFiles != 0 ) { $OUT.="#Configuration file list"; }>
< if ( $multiple_packages && @listOfConfFiles != 0 ) { $OUT.= "%files config"; }>
< foreach $i (@listOfConfFiles) { $OUT.="%attr($$i{mode} $$i{uid}, $$i{gid}) %config $$i{path}\n"; }>
< if ( @listOfDocFiles != 0 ) { $OUT.= "#Documentation file list"; }>
< if ( $multiple_packages && @listOfDocFiles != 0 ) { $OUT.= "%files doc"; }>
< foreach $i (@listOfDocFiles) { $OUT.= "%doc $$i{path}\n"; }>
%changelog
* <$date> <$packager> <$name>-<$version>-<$release>
- <$ChangeLog>
-  Generated version.

<$OldChangeLogs>';

    my $fileName = shift;
    my $res      = $defaultSpecTemplate;
    if ( $fileName ne "" ) {
        my $opened = 1;
        open( TEMPLATE, "$fileName" ) || ( $opened = 0 );

        if ($opened) {
            $res = "";
            while (<TEMPLATE>) {
                $res .= $_;
            }
            close(TEMPLATE);
        }
    }
    return $res;
}


=head1 AUTHOR

Jean-Marie RENOUARD, C<< <jmrenouard at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-package-builder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Package-Builder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Package::Builder


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Package-Builder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Package-Builder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Package-Builder>

=item * Search CPAN

L<http://search.cpan.org/dist/Package-Builder>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007 Jean-Marie RENOUARD, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Package::Builder

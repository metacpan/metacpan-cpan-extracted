package Sumu::Perl::Modules;

# ABSTRACT: Sumu Perl Modules : List all installed Perl Modules

=head1 NAME

    Sumu Perl Modules

=head1 VERSION

version 0.4.4

=head2 SYNOPSIS

    Usage:
    
        my $module = $c->param('module');
            
            chomp $module;
        
        my $modules = Sumu::Perl::Modules->new();

        my ($mod, $dirs, $files) = $modules->_dirs(current_user => $current_user, module => "$module");

        my ($mod, $out) = $modules->_doc( module => $module );


=head2 DESCRIPTION

    List all installed Perl Modules on your system

=head2 For Developer Only

    Being tested in:

        Ubuntu 22.04 (WSL):

            Dist:

                Folder/Path:
                
                    ~/p/perl/Sumu-Perl-Modules

                GitLab Repo: 
                
                    http://ns44:40225/ns21u2204/sumu-perl-modules-dist-zilla

            UI: 

                Folder/Path:
                
                    ~/p/perl/Perl-Modules-Companion

                GitLab Repo:
                
                    http://ns44:40225/ns21u2204/sumu-perl-modules-companion


        Rocky Linux 9 (Hyper-V):

            Dist:

            UI:

=head2 Strictures

    Enable strict and warnings

=cut

use strict;
use warnings;

=head2 our VERSION

    our $VERSION = '0.4.4'

    This version number is updated automatically!

=cut

our $VERSION = '0.4.4';


=head2 Internals

    Exporter

=cut    

use parent qw(Exporter); 
require Exporter; 
our @ISA = ("Exporter"); 

our @EXPORT_OK = qw(
    NAME 
    new
    _extutils 
    _dirs 
    _doc
); 

=head2 sub NAME

    Returns NAME: 
    
        The name of the app/module

=cut

sub NAME { my $self = shift; my $NAME = "Sumu Perl Modules"; return $NAME; }


=head2 Sub new

    Bless the classes 

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}


=head2 Required Modules

    Eporter
    
    ExtUtils::Installed

    Pod::Html;

=cut

use ExtUtils::Installed;

my $inst = ExtUtils::Installed->new();

use Pod::Html;


=head2 Sub _extutils

    Returns List of modules as a table

        including version number and number of dirs/files under given module

    Usage:

        my $modules_list = $modules->_extutils( module => $"module" );

=cut

sub _extutils {

    my $c = shift;

    my @modules = $inst->modules();

    my $out;

    my $mods; 
    my $serial = '0';
    $mods .= qq{};
    for (@modules) {
        #
        chomp;
        #
        my $module_version = $inst->version("$_");
        #
        my $module_files = $inst->files("$_");
        #
        my $mod_dirs = $inst->directories("$_");
        #
        my $mod_packlist = $inst->packlist("$_"); # shows hash error 

        $serial++ if $_;

        $mods .= qq{<tr> 
            <td>$serial</td> 
            <td> <a href="_dirs/$_" title="$_">$_</a> </td> 
            <td>$module_version</td> 
            <td>$module_files</td> 
            <td>$mod_dirs</td> 
        </tr>
        };
    }
    $mods .= qq{};

    return "$mods";

}
# end 


=head2 Sub _dirs 

    Show/Get Dirs in a given module 

    Returns an ordered list

    Usage:

        my ($module, $dirs, $files) = $modules->_dirs( module => "$module");

=cut

sub _dirs  {

    my %in = (
        current_user => '',
        module => '',
        @_,
    );

    #
    my $current_user = $in{current_user};

    my $module = $in{module};
    chomp $module; 

    $module =~ s!\\!\/!g;

    #
    my @mod_dirs = $inst->directories("$module");

    # files 
    my @mod_files = $inst->files("$module");

    my $dirs; 
    $dirs .= qq{<ol>};
    for (@mod_dirs) {
        chomp;
        next if $_ =~ /man3$/;
        #
        my $cust_filename = $_;
        $cust_filename =~ s!^\/home\/$current_user!!g;
        #
        $dirs .= qq{<li> $cust_filename </li>};
    }
    $dirs .= qq{</ol>};

    my $files;
    $files .= qq{<ol>};
    for (@mod_files) {
        chomp;
        next if $_ =~ /\.3$/;
        #
        my $cust_filename = $_;
        $cust_filename =~ s!^\/home\/$current_user!!g;
        #
        $files .= qq{<li> <a href="_doc/$_" title="$cust_filename">$cust_filename</a> </li>};
    }
    $files .= qq{</ol>};

    #
    return ($module, $dirs, $files);

}
# end _dirs


=head2 Sub _doc

    Show Doc for a given module 

        Returns results from command

            perldoc Module

            as text with a line break (<br>) appended to end of each line
    Usage:

        my ($total_lines, $out) = $modules->_doc( module => "$module" );

=cut

sub _doc {

    my %in = (
        module => '',
        @_,
    );

    #
    my $out;
    #
    my $total_lines;

    #
    my $module = $in{module};
        chomp $module;

    $module =~ s!\\!\/!g;
    
    my @doc = `perldoc "$module"`;

    $total_lines = scalar @doc;

    for (@doc) {
        $_ =~ s!\<!&lt;!g;
        $_ =~ s!\>!&gt;!g;
        $out .= qq{$_<br>};
    }

    if ($total_lines < 9 ) {
        @doc = `pod2html "$module"`;
    }

    for (@doc) {
        $out .= qq{$_ };
    }

    $total_lines = scalar @doc;

    return ($total_lines, $out);

    #

}
# end _doc 


=head2 Sub _inc

    List all directories in the @INC

    Returns an ordered list

        with link to given URL

            default is '/_inc_dir'

                see sub _inc_dir 

=cut

sub _inc {

    my %in = (
        url => '/_inc_dir',
        @_,
    );

    chomp $in{_inc_dir};

    my $out;

    $out .= qq{<ol>};
    
    for (@INC) {
        # link text
        my @name = split(/\//, $_);
        # link 
        $out .= qq{<li>}; 
        $out .= qq{<a href="$in{_inc_dir}/$_" };
        $out .= qq{title="$name[$#name]">};
        $out .= qq{$name[$#name]};
        $out .= qq{</a>};
        $out .= qq{</li> };
    }

    $out .= qq{</ol>}; 

    return "$out";

}
# end sub _inc


=head2 Sub _inc_dir 

    Do stuff with a given directory path from the @INC

    Show files and subdirectories in the given dir.

    Given directory should be an absolute path 

    Usage:

        my $out = $modules->_inc_dir( dir => "")

=cut

sub _inc_dir {
	#
	my %in = (
        inc_dir => '',
        @_,
    );

	my $out;
	$out .= qq{};

	my @directoreis;
	my @files;

	my $dir = $in{inc_dir};
	chomp $dir;

	if (-d "$dir") {
		if ( opendir (my $DIR, "$dir") ) {
			#
			my @dir = readdir($DIR);
			#
			while ( my $item = <@dir> ) {
				#Directories
				push(@directoreis, "$dir/$item") if (-d "$dir/$item");
				# Files
				push(@files, "$dir/$item") if (-f "$dir/$item");
			}
			#
		} else {
			$out = qq{Unable to open dir};
		}
	} else {
		$out = qq{Not a Dir};
	}
	#

	#
	$out .= qq{<article class="container"><h2>Files</h2>};
	for (@files) {
		my @file = split(/\//, $_);
		$out .= qq{<a href="/_doc/$_" title="$file[$#file]">$file[$#file]</a> };
	}
	$out .= qq{</article>};

	#
	$out .= qq{<article class="container"><h2>Directories</h2>};
	for (@directoreis) {
		#
		my @d_name = split(/\//, $_);
		$out .= qq{<a href="/_inc/$_" title="$d_name[$#d_name]">$d_name[$#d_name]</a> };
	}
	$out .= qq{</article>};

	return "$out";

}
# end _inc_dir



1;

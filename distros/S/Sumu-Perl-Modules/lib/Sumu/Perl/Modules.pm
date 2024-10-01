package Sumu::Perl::Modules;

# ABSTRACT: Perl Modules

=head1 NAME

    Perl Modules

=head1 VERSION

version 0.3.7

=head2 DESC

    List all installed Perl Modules on your system
    
=cut

=head2 Strictures

    Enable strict and warnings

=cut

use strict;
#use warnings;

=head2 our VERSION

    our $VERSION = '0.3.7'

=cut

our $VERSION = '0.3.7';

=head2 Internals

    Exporter

=cut    

use parent qw(Exporter); 
require Exporter; 
our @ISA = ("Exporter"); 

our @EXPORT_OK = qw(
    NAME 
    _extutils 
    _dirs 
    _doc
); 

=head3 sub NAME

    Returns NAME: 
    
        The name of the app/module

=cut

sub NAME { my $self = shift; my $NAME = "Sumu Perl Modules"; return $NAME; }


=head3 Sub new

    Bless the classes 

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}


=head3 Required Modules

    ExtUtils::Installed

=cut

use ExtUtils::Installed;

my $inst = ExtUtils::Installed->new();


=head3 Sub _extutils

    Returns List of modules 

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
            <td> $mod_dirs </td> 
        </tr>
        };
    }
    $mods .= qq{};

    return $mods;

}
# end 


=head3 Sub _dirs 

    Show/Get Dirs in a given module 

    Returns an ordered list

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
# end 


=head3 Sub _doc

    Show Doc for a given module 

    Module includes path 

    Returns an ordered list 

=cut

sub _doc {

    my %in = (
        module => '',
        @_,
    );
    
    #
    my $module = $in{module};
        chomp $module;

    $module =~ s!\\!\/!g;
    
    my @doc = `perldoc $module`;

    my $out;

    for (@doc) {
        $_ =~ s!\<!&lt;!g;
        $_ =~ s!\>!&gt;!g;
        $out .= qq{$_<br>};
    }

    return ($module, $out);

    #

}
# end _doc 


1;

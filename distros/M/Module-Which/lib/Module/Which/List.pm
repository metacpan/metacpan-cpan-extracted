
package Module::Which::List;
$Module::Which::List::VERSION = '0.05';
use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(list_pm_files);

use File::Glob qw(bsd_glob);
#use File::Spec::Functions qw(abs2rel);
require File::Spec::Unix;
use File::Find qw(find);

# returns a list with no duplicates
sub uniq {
    my %h;
    return grep { ! $h{$_}++ } @_;
}


# my @files = _plain_list_files('File/*', @INC);
sub _plain_list_files {
    my $glob = shift;
    my @INC = @_;
    my @files;
    #push @files, bsd_glob("$_/$glob") for @INC;
    for my $base (@INC) {
        #print "bsd_glob($_/$glob)\n";
        push @files, 
             map { { path => $_, rpath => File::Spec::Unix->abs2rel($_, $base), base => $base } }
             grep { -e } bsd_glob("$base/$glob")
    }

    return @files if wantarray;
    return \@files;
}

# my @files = _deep_list_files('Data/**.pm', @INC)
sub _deep_list_files {
    my $glob = shift;
    my @INC = @_;

    #print "deep_list_files: ...\n";

    my $root = $glob;
    $root =~ s/\*\*\.pm$//;

    my $base;
    my @files;

    my $wanted = sub {
        if (/\.pm$/) {
            push @files, { path => $_, rpath => File::Spec::Unix->abs2rel($_, $base), base => $base };
        }
    };

    for (@INC) {
        $base = $_;
        if (-e "$base/$root" && -d "$base/$root") {
            find({ wanted => $wanted, no_chdir => 1 }, "$base/$root");
        }
    }

    return @files if wantarray;
    return \@files;

}

sub list_files {
    my $glob = shift;
    my %options = @_;
    my @include;
    @include = ($options{include}) ? @{$options{include}} : @INC;
    @include = uniq @include 
        if exists $options{uniq} ? $options{uniq} : 1; # FIXME: need documentation !!!!
    #print "include: @include\n";
    my @files;
    if ($glob =~ /\*\*\.pm$/) {
        return _deep_list_files($glob, @include);
    } else {
        return _plain_list_files($glob, @include);
    }
}

sub file_to_pm {
    my $rpath = shift;
    $rpath =~ s|\.pm$||;
    $rpath =~ s|/|::|g;
    return $rpath;
}

sub list_pm_files {
    my $pm_glob = shift;
    my %options = @_;

    my $glob = $pm_glob;
    $glob =~ s|::$|::*| unless $options{recurse};
    $glob =~ s|::$|::**| if $options{recurse};
    $glob =~ s|::|/|g;
    $glob =~ s|$|.pm|;
    #print "glob: $glob\n";

    my @pm_files = list_files($glob, @_);
    
    my @pm;
    for (@pm_files) {
        push @pm, { 
             pm => file_to_pm($_->{rpath}), 
             path => $_->{path}, 
             base => $_->{base} 
        };
    }

    return @pm if wantarray;
    return \@pm;

}

1;

__END__

=head1 NAME

Module::Which::List - Lists C<.pm> files under specified library paths

=head1 SYNOPSIS

  use Module::Which::List qw(list_pm_files);

  my @files = list_pm_files('XML::', 'lib1/', 'lib2/');
  # return all modules XML::* installed under 'lib1/' and 'lib2/'

  my @files = list_pm_files('Data::Dumper'); # uses @INC

=head1 DESCRITION

Yes, I know: it is a mess down below. But release early, release often
(before my breath disappears).


    pm_glob => 'File::Which'
    pm_root => 'File::Which::'


    list_files($pm_glob, { recurse => '0|1', include => \@INC })

        prefixes - take a look at Module::List
        pod      - take a look at Module::List

    list_files('Module::Which')

    => [ { pm => 'Module::Which', path => '/usr/lib/perl5/site_perl/5.8/Module/Which.pm' } ]

    list_files('Module::')

    => [ 
        { pm => 'Module::Build', path => '/usr/lib/perl5/site_perl/5.8/Module/Build.pm' } 
        { pm => 'Module::Find', path => '/usr/lib/perl5/site_perl/5.8/Module/Find.pm' }, 
        { pm => 'Module::Which', path => '/usr/lib/perl5/site_perl/5.8/Module/Which.pm' } 
       ]

=head1 BUGS

This documentation, in such a status, is a bug.

Please report bugs via CPAN RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Which>.

=head1 AUTHOR

Adriano R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Adriano R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

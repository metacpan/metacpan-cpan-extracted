###########################################
package Module::Rename;
###########################################

use strict;
use warnings;
use File::Find;
use File::Basename;
use File::Spec qw( splitdir );
use Sysadm::Install qw(:all);
use Log::Log4perl qw(:easy);
use File::Spec::Functions qw( abs2rel splitdir );

our $VERSION = "0.04";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        name_old           => undef,
        name_new           => undef,
        dir_exclude        => ['blib'],
        dir_ignore         => ['CVS'],
        wipe_empty_subdirs => 0,
        use_git            => 0,
        %options,
    };

    if( $self->{use_git} ) {
        $self->{ git_bin } = bin_find( "git" );
        if( !defined $self->{ git_bin } ) {
            die "No git executable found";
        }
        push @{ $self->{dir_exclude} }, ".git";
    }

    $self->{dir_exclude_hash} = { map { $_ => 1 } @{$self->{dir_exclude}} };
    $self->{dir_ignore_hash}  = { map { $_ => 1 } @{$self->{dir_ignore}} };

    ($self->{look_for}   = $self->{name_old}) =~ s#::#/#g;
    ($self->{replace_by} = $self->{name_new}) =~ s#::#/#g;

    ($self->{pmfile}  = $self->{name_old}) =~ s#.*::##g;
     $self->{pmfile} .= ".pm";

    ($self->{new_pmfile}  = $self->{name_new}) =~ s#.*::##g;
     $self->{new_pmfile} .= ".pm";

    bless $self, $class;
}

###########################################
sub longest_common_path {
###########################################
    my( $self, $file1, $file2 ) = @_;

    my @common = ();

    my @dirs1 = splitdir( dirname $file1 );
    my @dirs2 = splitdir( dirname $file2 );

    for my $dir1_part ( @dirs1 ) {
        my $dir2_part = shift @dirs2;
        if( $dir1_part eq $dir2_part ) {
            push @common, $dir1_part;
        } else {
            last;
        }
    }

    return File::Spec->catfile( @common );
}

###########################################
sub move {
###########################################
    my($self, $old_path, $new_path) = @_;

    if( $old_path ne $new_path ) {
        if ($self->{use_git} and !-d $old_path) {
              # make sure we launch the git command inside the git workspace
            my $common = $self->longest_common_path( $old_path, $new_path );
            cd $common;
            tap("git", "mv", 
               abs2rel( $old_path, $common ),
               abs2rel( $new_path, $common ),
            );
            cdback;
        } else {
            mv $old_path, $new_path;
        }
    }
}

###########################################
sub find_and_rename {
###########################################
    my($self, $start_dir) = @_;

    my @files = ();
    my %empty_subdirs = ();

    find(sub {
        if(-d and $self->dir_empty($_)) {
            INFO "$File::Find::name is an empty subdir";
            $empty_subdirs{$File::Find::name}++;
        }
        if(-d and exists $self->{dir_exclude_hash}->{$_}) {
            $File::Find::prune = 1;
            return;
        }
        return unless -f $_;
        push @files, $File::Find::name if 
                $File::Find::name =~ /$self->{look_for}/ or
                $_ eq $self->{pmfile};
        $self->file_process($_, $File::Find::name);
    }, $start_dir);
    
    for my $file (@files) {

        my $newfile = $file;

        if($file =~ /$self->{look_for}/) {
            $newfile =~ s/$self->{look_for}/$self->{replace_by}/;
        } else {
                # We found a module file outside the regular
                # dir structure, just replace it within this directory
            $newfile =~ s/$self->{pmfile}/$self->{new_pmfile}/;
        }

        INFO "mv $file $newfile";
        my $dir = dirname($newfile);
        mkd $dir unless -d $dir;
        $self->move($file, $newfile);
    }

    (my $dashed_look_for   = $self->{name_old}) =~ s#::#-#g;
    (my $dashed_replace_by = $self->{name_new}) =~ s#::#-#g;

        # Rename any top directory files like Foo-Bar-0.01
    my @rename_candidates = ($start_dir);
    find(sub {
        if(/$dashed_look_for/) {
            push @rename_candidates, $File::Find::name;
        }
    }, $start_dir);
    for my $item (@rename_candidates) {
        (my $newitem = $item) =~ s/$dashed_look_for/$dashed_replace_by/;
        $self->move($item, $newitem);
    }

        # Even the start_dir could have to be modified.
    $start_dir =~ s/$dashed_look_for/$dashed_replace_by/;

        # Update empty_subdirs with the latest name changes
    %empty_subdirs = map { s/$dashed_look_for/$dashed_replace_by/; $_; }
        %empty_subdirs;

    if( $self->{wipe_empty_subdirs} ) {
        my @dirs = ();
            # Delete all empty dirs
        find(sub { 
            if( exists $self->{dir_exclude_hash}->{$_} ) {
                $File::Find::prune = 1;
            }

            if(-d and $self->dir_empty($_) and
               ! exists $empty_subdirs{$File::Find::name}
            ) {
                WARN "$File::Find::name is empty and can go away";
                push @dirs, $File::Find::name;
            }
        }, $start_dir);
        for my $dir ( @dirs ) {
            rmf $dir;
        }
    }
}

###########################################
sub dir_empty {
###########################################
    my($self, $dir) = @_;

    opendir DIR, $dir or LOGDIE "Cannot open dir $dir";
    my @items = grep { $_ ne "." and $_ ne ".." } readdir DIR;
    closedir DIR;

    @items = grep { ! exists $self->{dir_ignore_hash}->{$_} } @items;
    
    return ! scalar @items;
}

###########################################
sub file_process {
###########################################
    my($self, $file, $path) = @_;

    my $out = "";

    open FILE, "<$file" or LOGDIE "Can't open $file ($!)";
    while(<FILE>) {
        DEBUG "Looking for /$self->{name_old}/";
        s/($self->{name_old})\b/$self->rep($1,$self->{name_new})/ge;
        DEBUG "Looking for /$self->{look_for}/";
        s/($self->{look_for})\b/$self->rep($1,$self->{replace_by})/ge;
        $out .= $_;
    }
    close FILE;

    blurt $out, $file;
}

###########################################
sub rep {
###########################################
    my($self, $found, $replace) = @_;

    INFO "$File::Find::name ($.): $found => $replace";
    return $replace;
}

1;

__END__

=head1 NAME

Module::Rename - Utility functions for renaming a module distribution

=head1 SYNOPSIS

    ########
    # Shell:
    ########
    $ module-rename Old::Name New::Name Old-Name-Distro

    #######
    # Perl:
    #######
    use Module::Rename;

    my $ren = Module::Rename->new(
        name_old           => "Old::Name",
        name_new           => "New::Name",
    );

    $ren->find_and_rename($start_dir);

=head1 DESCRIPTION

Have you ever created a module distribution, only to realize later that
the module hierarchary needed to be changed? All of a sudden, 
C<Cool::Frobnicator> didn't sound cool anymore, but needed to be
C<Util::Frobnicator> instead?

Going through a module's distribution, changing all package names,
variable names, and move the directories around can be a tedious task. 
C<Module::Rename> comes with a script C<module-rename> which takes care of 
all this:

    $ ls
    Cool-Frobnicator-0.01/

    $ module-rename Cool::Frobnicator Util::Frobnicator Cool-Frobnicator-0.01
    Cool-Frobnicator-0.01/lib/Cool is empty and can go away.

Done. The directory hierarchy has changed:

    $ ls -R
    Util-Frobnicator-0.01/
    ...
    Util-Frobnicator-0.01/lib/Util/Frobnicator.pm

... and so has the content of all files:

    $ grep "package" Util-Frobnicator-0.01/lib/Util/Frobnicator.pm
    package Util::Frobnicator;

=head2 Things to Keep in Mind

=over 4

=item *

C<module-rename> will rename files and replace their content, so make
sure that you have a backup copy in case something goes horribly wrong.

=item *

After changing the module hierarchy, some directories might be empty,
like the C<lib/Cool> directory above. In this case, a warning will be issued:

    Cool-Frobnicator-0.01/lib/Cool is empty and can go away.

and the 'empty' directory gets deleted (even if a CVS subdirectory is in 
there).

=back

=head1 API

=over 4

=item C<my $renamer = Module::Rename-E<gt>new(...)>

The renamer's constructor takes the following parameters:

=over 4

=item C<name_old>

Old module name.

=item C<name_new>

New module name.

=item C<dir_exclude>

Reference to an array with directories to exclude from traversing.
Preset to 

    dir_exclude => ['blib']

but can be overridden.

=item C<dir_ignore>

Reference to an array with entries to be ignored in 'empty' directories.
Even with these entries being present, a directory will be considered
empty and swept away.

Preset to 

        dir_ignore => ['CVS'],

but can be overridden.

=item C<wipe_empty_subdirs>

If set to a true value, 'empty' (see above) subdirectories will be deleted after
all renaming and restructuring is done. Defaults to true.

=back

=item C<$renamer-E<gt>find_and_rename($start_dir)>

Start searching and replacing in C<$start_dir> and recurse into it.

=back

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>

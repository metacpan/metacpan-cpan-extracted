# Term/Clui/FileSelect.pm
#########################################################################
#        This Perl module is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This module is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

package Term::Clui::FileSelect;
our $VERSION = '1.75';
import Term::Clui(':DEFAULT','back_up');
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(select_file);
@EXPORT_OK = qw();

use 5.006;
no strict; no warnings;

my $home = $ENV{HOME} || $ENV{LOGDIR} || (getpwuid($>))[7];
$home =~ s#([^/])$#$1/#;

sub select_file {   my %option = @_;
	if (!defined $option{'-Path'}) { $option{'-Path'}=$option{'-initialdir'}; }
	if (!defined $option{'-FPat'}) { $option{'-FPat'}=$option{'-filter'}; }
	if (!defined $option{'-ShowAll'}) {
		$option{'-ShowAll'} = $option{'-dotfiles'};
	}
	if ($option{'-Directory'}) { $option{'-Chdir'}=1; $option{'-SelDir'}=1; }
	my $multichoice = 0;
	if (wantarray && !$option{'-Chdir'} && !$option{'-Create'}) {
		$option{'-DisableShowAll'} = 1;
		$multichoice = 1;
	} elsif (!defined $option{'-Chdir'}) {
		$option{'-Chdir'} = 1;
	}

	if ($option{'-Path'} && -d $option{'-Path'}) {
		$dir=$option{'-Path'};
		if ($dir =~ m#[^/]$#) { $dir .= '/'; }
	} else {
		$dir = $home;
	}
	if ($option{'-TopDir'}) {
		if (!-d $option{'-TopDir'}) { delete $option{'-TopDir'};
		} elsif ($option{'-TopDir'} =~ m#[^/]$#) { $option{'-TopDir'} .= '/';
		}
		if (index $dir, $option{'-TopDir'}) { $dir = $option{'-TopDir'}; }
	}

	my ($new, $file, @allfiles, @files, @dirs, @pre, @post, %seen, $isnew);
	my @dotfiles;

	while () {
		if (! opendir (D, $dir)) { warn "can't opendir $dir: $!\n"; return 0; }
		if ($option{'-SelDir'}) { @pre = ('./'); } else { @pre = (); }
		@post = ();
		@allfiles = sort grep(!/^\.\.?$/, readdir D); closedir D;
		@dotfiles = grep(/^\./, @allfiles);
		if ($option{'-ShowAll'}) {
			if (@dotfiles && !$option{'-DisableShowAll'}) {
				@post='Hide DotFiles';
			}
		} else {
			@allfiles = grep(!/^\./, @allfiles);
			if (@dotfiles && !$option{'-DisableShowAll'}) {
				@post='Show DotFiles';
			}
		}
		# split @allfiles into @files and @dirs for option processing ...
		@dirs  = grep(-d "$dir/$_" && -r "$dir/$_", @allfiles);
		if ($option{'-Directory'}) {
			@files = ();
		} elsif ($option{'-FPat'}) {
			@files = grep(!-d $_, glob("$dir/$option{'-FPat'}"));
			my $length = 1 + length $dir;
			foreach (@files) { $_ = substr $_, $length; }
		} else {
			@files = grep(!-d "$dir/$_", @allfiles);
		}
		if ($option{'-Chdir'}) {
			foreach (@dirs) { s#$#/#; }
			if ($option{'-TopDir'}) {
				my $up = $dir; $up =~ s#[^/]+/?$##;   # find parent directory
				if (-1 < index $up, $option{'-TopDir'}) { unshift @pre, '../'; }
				# must check for symlinks to outside the TopDir ...
			} else { unshift @pre, '../';
			}
		} elsif (!$option{'-SelDir'}) {
			@dirs = ();
		}
		if ($option{'-Create'})     { unshift @post, 'Create New File'; }
		if ($option{'-TextFile'})   { @files = grep(-T "$dir/$_", @files); }
		if ($option{'-Owned'})      { @files = grep(-o "$dir/$_", @files); }
		if ($option{'-Executable'}) { @files = grep(-x "$dir/$_", @files); }
		if ($option{'-Writeable'})  { @files = grep(-w "$dir/$_", @files); }
		if ($option{'-Readable'})   { @files = grep(-r "$dir/$_", @files); }
		@allfiles = (@pre, (sort @dirs,@files), @post); # reconstitute @allfiles

		my $title;
		if ($option{'-Title'}) { $title = "$option{'-Title'} in $dir"
		} else { $title = "in directory $dir ?";
		}
		if ($option{'-File'}) { &set_default($title, $option{'-File'}) }
		$Term::Clui::SpeakMode{'dot'} = 1;
		if ($multichoice) {
			my @new = &choose ($title, @allfiles);
			$Term::Clui::SpeakMode{'dot'} = 0;
			return () unless @new;
			foreach (@new) { $_="$dir$_"; }
			return @new;
		}
		$new = &choose ($title, @allfiles);
		$Term::Clui::SpeakMode{'dot'} = 0;

		if ($option{'-ShowAll'} && $new eq 'Hide DotFiles') {
			delete $option{'-ShowAll'}; redo;
		} elsif (!$option{'-ShowAll'} && $new eq 'Show DotFiles') {
			$option{'-ShowAll'} = 1; redo;
		}
		if ($new eq "Create New File") {
			$new = &ask ("new file name ?");  # validating this is a chore ...
			if (! $new) { next; }
			if ($new =~ m#^/#) { $file = $new; } else { $file = "$dir$new"; }
			$file =~ s#/+#/#g;  # simplify //// down to /
			while ($file =~ m#./\.\./#) { $file =~ s#[^/]*/\.\./##; }  # zap /../
			$file =~ s#/[^/]*/\.\.$##;  # and /.. at end
			if ($option{'-TopDir'}) {  # check against escape from TopDir
				if (index $file, $option{'-TopDir'}) {
					$dir = $option{'-TopDir'}; next;
				}
			}
			if (-d $file) {  # pre-existing directory ?
				if ($option{'-SelDir'}) { return $file;
				} else {
					$dir=$file; if ($dir =~ m#[^/]$#) { $dir.='/'; } next;
				}
			}
			$file =~ m#^(.*/)([^/]+)$#;
			if (-e $file) { $dir = $1; $option{'-File'} = $2; next; } # exists ?
			# must check for creatability (e.g. dir exists and is writeable)
			if (-d $1 && -w $1) { return $file; }
			if (!-d $1) { &sorry ("directory $1 does not exist."); next; }
			&sorry ("directory $1 is not writeable."); next;
		}
		return undef unless $new;
		if ($new eq './' && $option{'-SelDir'}) { return $dir; }
		if ($new =~ m#^/#) { $file = $new; # abs filename
		} else { $file = "$dir$new";       # rel filename (slash always at end)
		}
		if ($new eq '../') { $dir =~ s#[^/]+/?$##; &back_up(); next;
		} elsif ($new eq './') {
			if ($option{'-SelDir'}) { return $dir; } $file = $dir;
		} elsif ($file =~ m#/$#) { $dir = $file; &back_up(); next;
		} elsif (-f $file) { return $file;
		}
	}
}
1;

__END__

=pod

=head1 NAME

Term::Clui::FileSelect - Perl module to ask the user to select a file.

=head1 SYNOPSIS

 use Term::Clui;
 use Term::Clui::FileSelect;
 $file = &select_file(-Readable=>1, -TopDir=>"/home", -FPat=>"*.html");
 @files = &select_file(-Chdir=>0, -Path=>$ENV{PWD}, -FPat=>"*.mp3");
 chdir &select_file(-Directory=>1, -Path=>$ENV{PWD});

=head1 DESCRIPTION

This module asks the user to select a file from the filesystem.
It uses the Command-line user-interface Term::Clui to dialogue with the user.
It offers I<Rescan> and I<ShowAll> buttons.
To ease the re-learning burden for the programmer,
the options are modelled on those of Tk::FileDialog
and of Tk::SimpleFileSelect,
but various new options are introduced, namely I<-TopDir>, I<-TextFile>,
I<-Readable>, I<-Writeable>, I<-Executable>, I<-Owned> and I<-Directory>

Multiple choice is possible in a limited circumstance;
when I<file_select> is invoked in a list context, with -Chdir=>0
and without -Create.  It is currently not possible
to select multiple files lying in different directories.

=head1 SUBROUTINES

=over 3

=item I<select_file>( %options );

=back

=head1 OPTIONS

=over 3

=item I<-Chdir>

Enable the user to change directories. The default is 1.
If it is set to 0, and I<select_file> is invoked in a list context,
and I<-Create> is not set, then the user can select multiple files.

=item I<-Create>

Enable the user to specify a file that does not exist. The default is 0.

=item I<-ShowAll> or I<-dotfiles>

Determines whether hidden files (.*) are displayed.  The default is 0.

=item I<-DisableShowAll>

Disables the ability of the user to change the
status of the ShowAll flag. The default is 0
(i.e. the user is by default allowed to change the status).

=item I<-SelDir>

If True, enables selection of a directory rather than a file.
The default is 0.
To I<enforce> selection of a directory, use the I<-Directory> option.

=item I<-FPat> or I<-filter>

Sets the default file selection pattern, in glob format, e.g. I<*.html>.
Only files matching this pattern will be displayed.
If you want multiple patterns, you can use formats like
I<*.[ch]> or
I<{*.cgi,*.pl}> - see I<File::Glob> for more details.
The default is "*".

=item I<-File>

The file selected, or the default file.
The default default is whatever the user selected last time in this directory.

=item I<-Path> or I<-initialdir>

The path of the selected file, or the initial path.
The default is $ENV{HOME}.

=item I<-Title>

The Title of the dialog box.
If I<-Title> is specified,
then Clui::FileSelect dynamically appends "in I</where/ever>" to it.
If I<-Title> is not specified,
Clui::FileSelect displays "in directory I</where/ever>".

=item I<-TopDir>

Restricts the user to remain within a directory or its subdirectories.
The default is "/".
This option, and the following, are not offered by Tk::FileDialog.

=item I<-TextFile>

Only text files will be displayed. The default is 0.

=item I<-Readable>

Only readable files will be displayed. The default is 0.

=item I<-Writeable>

Only writeable files will be displayed. The default is 0.

=item I<-Executable>

Only executable files will be displayed.
The default is 0.

=item I<-Owned>

Only files owned by the current user will be displayed.
This is useful if the user is being asked to choose a file for a I<chmod>
or I<chgrp> operation, for example.
The default is 0.

=item I<-Directory>

Only directories will be displayed.
The default is 0.

=back

=head1 BUGS

Three problem filenames will, if present in your file-system, cause confusion.
They are I<Create New File>, I<Show DotFiles> and I<Hide DotFiles>

=head1 AUTHOR

Original author:

Peter J Billam www.pjb.com.au/comp/contact.html

Current maintainer:

Graham Ollis

=head1 CREDITS

Based on an old Perl4 library, I<filemgr.pl>,
with the options modelled after I<Tk::FileDialog> and I<Tk::SimpleFileSelect>.

=head1 SEE ALSO

http://www.pjb.com.au/ ,
http://search.cpan.org/~pjb ,
File::Glob ,
Term::Clui ,
Tk::FileDialog ,
Tk::SimpleFileSelect ,
perl(1) .

=cut


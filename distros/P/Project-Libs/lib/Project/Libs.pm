package Project::Libs;
use 5.008001;
use strict;
use warnings;
use Cwd;
use FindBin;
use FindBin::libs;

our $VERSION = '0.02';

my @PROJECT_ROOT_FILES = qw(
    .git
    .gitmodules
    Makefile.PL
    Build.PL
);

sub import {
    my ($class, %args) = @_;
    my $current_dir = getcwd;

    my $lib_dirs           = delete $args{lib_dirs}           || [];
    my $project_root_files = delete $args{project_root_files} || [];

    push @PROJECT_ROOT_FILES, @$project_root_files;
    my @inc = find_inc($FindBin::Bin, $lib_dirs, ());

    if (scalar @inc) {
        my $inc = join ' ', @inc;
        eval "use lib qw($inc)";
    }

    chdir $current_dir;
}

sub find_inc {
    my ($current_dir, $lib_dirs, @inc) = @_;
    return @inc if $current_dir eq '/';
    chdir $current_dir;

    my $glob_expanded_lib_dirs = [ map { glob($_) } @$lib_dirs ];
    my @found = grep { -e File::Spec->catfile($current_dir, $_)} @$glob_expanded_lib_dirs;
    push @inc, map { File::Spec->catfile($current_dir, $_)} @found;

    my @root_files = grep { -e $_ } @PROJECT_ROOT_FILES;
    if (!@root_files) {
        chdir '..';
        $current_dir = getcwd;
        return find_inc($current_dir, $lib_dirs, @inc);
    }

    for my $file (@root_files) {
        if ($file eq '.gitmodules') {
            push @inc, find_git_submodules(
                $current_dir,
                File::Spec->catfile($current_dir, '.gitmodules'),
            )
        }
    }

    @inc;
}

sub find_git_submodules {
    my ($current_dir, $gitsubmodule) = @_;
    open my $fh, "< $gitsubmodule" or die $!;
    my $content = do { local $/ = undef; <$fh> };
    close $fh;
    my @submodules = ($content =~ /\[submodule "([^"]+)"\]/g);
    map { File::Spec->catfile($current_dir, "$_/lib") } @submodules;
}

!!1;

__END__

=head1 NAME

Project::Libs - Add module directories of a project into @INC
automatically

=head1 SYNOPSIS

    # the simplest way
    use Project::Libs;

    # add more other dirs into @INC
    use Project::Libs lib_dirs => [qw(extlib vendor modules/*/lib)];

    # add more other marks locate on a project root
    use Project::Libs project_root_files => [qw(README Changes)];

=head1 DESCRIPTION

Project::Libs automatically adds directories that may contain modules
which a project depends on.

Imagin there's such a project as below: CPAN-standard file arrangement
and using git as a SCM (`modules' directory contains git submodules
and that's written in `.gitmodules').

    |_ PROJECT_ROOT
       |_ .git
       |_ .gitmodules
       |_ Makefile.PL
       |_ lib/
       |_ t/
          |_ lib/
          |_ compile.t
          |_ basic.t
       |_ script/
          |_ server.pl
          |_ create.pl
       |_ extlib/
       |_ modules/
          |_ Foo
             |_ lib/
          |_ Bar
             |_ lib/
          |_ ...

You may bother writing such code as below in all the script located in
t/*, script/*, or other to add module path into @INC.

    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use lib glob "$FindBin::Bin/../modules/*/lib";

To `use Project::Libs' helps you doing that.

In this case, after loading this module, the directories below are
added into @INC:

=over 4

=item * lib

=item * extlib

=item * t/lib

=item * modules/Foo/lib

=item * modules/Bar/lib

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

package Mojo::File::Share;
use Mojo::Base -strict;
use Carp ();
use Exporter 'import';
use File::ShareDir ();
use File::Spec ();
use Mojo::File 'path';

our $VERSION = '0.02';

our @EXPORT_OK = qw(dist_dir dist_file);

sub dist_dir {
    my $dist = shift // _get_caller_dist();
    my $inc  = _get_inc_from_dist($dist);
    my $path = _get_path_from_inc($inc);

    if ($path and
        -d $path->dirname->sibling('lib') and
        -d -r $path->dirname->sibling('share')) {
        return $path->dirname->sibling('share')->realpath;
    } elsif (-e path('lib', $inc) and -d -r path('share')) {
        return path('share')->realpath;
    } else {
        return path(File::ShareDir::dist_dir($dist))->realpath;
    }
}

sub dist_file {
    my $dist_file = dist_dir(@_ > 1 ? shift : _get_caller_dist())->child(@_)->realpath;

    -f $dist_file or Carp::croak "File '$dist_file': No such file";
    -r $dist_file or Carp::croak "File '$dist_file': No read permission";

    return $dist_file;
}

sub _get_caller_dist {
    my ($package) = caller(1);
    $package =~ s/::/-/g;
    return $package;
}

sub _get_inc_from_dist {
    my ($dist) = @_;

    my $file_separator = File::Spec->catfile('', '');
    (my $inc = $dist) =~ s!(-|::)!$file_separator!g;

    return "$inc.pm";
}

sub _get_path_from_inc {
    my ($inc) = @_;

    my $path = $INC{$inc} // '';
    $path =~ s/$inc$//;

    return path($path);
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::File::Share - Better local share directory support with Mojo::File

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojo-File-Share"><img src="https://travis-ci.org/srchulo/Mojo-File-Share.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojo-File-Share?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojo-File-Share/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 SYNOPSIS

  package Foo::Bar;
  use Mojo::File::Share qw(dist_dir dist_file);

  # defaults to using calling package to determine dist_dir
  my $dist_dir = dist_dir();
  my $collection = $dist_dir->list_tree; # is a Mojo::File

  # same as above, but specifies dist explicitly
  my $dist_dir = dist_dir('Foo-Bar');

  # with one argument, calling package is used for dist
  my $file = dist_file('file.txt');
  say $file->slurp; # is a Mojo::File

  # same as above, but specifies dist explicitly
  my $file = dist_file('Foo-Bar', 'file.txt');

  # use path so there is only one arg and default dist is used
  my $file = dist_file(path('path', 'to', 'file.txt'));

  # or specify dist and path is not necessary
  my $file = dist_file('Foo-Bar', 'path', 'to', 'file.txt');

=head1 DESCRIPTION

L<Mojo::File::Share> is a dropin replacement for L<File::ShareDir> based on L<File::Share>. L<Mojo::File::Share> has
three main differences from L<File::Share>:

=over 4

=item

L</dist_dir> and L</dist_file> both return L<Mojo::File> objects.

=item

L</dist_dir> and L</dist_file> have been enhanced even more to understand when the developer's
local C<./share/> directory should be used.

L<File::Share> checks C<%INC> to determine if the dist has been C<use>d or C<require>d, and then it checks for the
C<share> directory relative to the dist's C<.pm> file location. This is good for a lot of local development, but it
is not good for using in tests if you want to access the C<share> directory but haven't loaded the dist.
L<Mojo::File::Share> does the above check, and then if that doesn't work, it checks the current working
directory for the existence of C<lib/$path_to_dist.pm> and the existence of a C<share> directory, and
returns that C<share> directory if both conditions are true. This removes the need a lot of the time to
do something like this in your tests:

  $File::ShareDir::DIST_SHARE{'Foo-Bar'} = path('share')->realpath;

=item

If no dist is provided to L</dist_dir> or L</dist_file>, L<Mojo::File::Share> will default to using
the calling package as the dist.

=back

NOTE: C<module_dist> and C<module_file> are not supported.

=head1 FUNCTIONS

=head2 dist_dir

  # defaults to using calling package to determine dist_dir
  # package Foo::Bar becomes dist Foo-Bar
  my $dist_dir = dist_dir();
  my $collection = $dist_dir->list_tree; # is a Mojo::File

  # specify dist explicitly
  my $dist_dir = dist_dir('Foo-Bar');

The L</dist_dir> function takes a single parameter of the name of an installed (CPAN or otherwise) distribution, and locates either
the local share directory, if one exists, or the shared data directory created at install time for it. If no distribution is provided,
L</dist_dir> will use the package of the caller to determine the name of the distribution.

Returns the directory as a L<Mojo::File> returned by L<Mojo::File/realpath>, or dies if it cannot be located or is not readable.

See L</DESCRIPTION> for an explanation on how L</dist_dir> works better for local development and local distributions.

=head2 dist_file

  # with one argument, calling package is used for dist
  my $file = dist_file('file.txt');
  say $file->slurp; # is a Mojo::File

  # same as above, but specifies dist explicitly
  my $file = dist_file('Foo-Bar', 'file.txt');

  # use path so there is only one arg and default dist is used
  my $file = dist_file(path('path', 'to', 'file.txt'));

  # or specify dist and path is not necessary
  my $file = dist_file('Foo-Bar', 'path', 'to', 'file.txt');

The L</dist_file> function takes one more more parameters. If one parameter is provided, the distribution will be determined
using the caller's package name. Then the provided argument will be used to find a file within the C<share> directory
for that distribution. When you want to pass multiple arguments for the file path and you want to have the distribution
determined by L</dist_file>, use L<Mojo::File/path> to wrap multiple arguments into one:

  # use path so there is only one arg and default dist based on the calling package is used
  my $file = dist_file(path('path', 'to', 'file.txt'));

If more than one argument is provided to L</dist_file>, the first argument is the distribution and the remainder
will be passed to L<Mojo::File/child> on the L<Mojo::File> directory returned by L</dist_dir>:

  my $file = dist_file('Foo-Bar', 'path', 'to', 'file.txt');

Returns the file as a L<Mojo::File> returned by L<Mojo::File/realpath>, or dies if it cannot be located or is not readable.

See L</DESCRIPTION> for an explanation on how L</dist_file> works better for local development and local distributions.

=head1 LICENSE

Copyright (C) srchulo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

srchulo E<lt>srchulo@cpan.orgE<gt>

=cut

package Orze::Drivers;

use strict;
use warnings;

use File::Path;
use File::Basename;

use Carp;

=head1 NAME

Orze::Drivers - Superclass of all Orze::Drivers::

=head1 SYNOPSIS

  package Orze::Drivers::Foo;

  use strict;
  use warnings;
  use base qw( Orze::Drivers );
  use Text::Foo;

  sub process {
      # do some cool stuff
  }

=cut

=head2 new

Create the driver object, using the C<$page> tree and the C<$variables>
hash.

=cut

sub new {
    my ($name, $page, $variables) = @_;

    my $self = {};
    bless $self, $name;

    $self->{name} = $name;
    $self->{page} = $page;
    $self->{variables}  = $variables;

    return $self;
}

=head2 process

You need to overload this method in order to do the real processing of
the page data.

sub process {
    croak "You really should subclass this package !!!!";
}

=head2 input

Get the full path of a file in the C<data/> folder, according the
current C<outputdir> value.

=cut

sub input {
    my $self = shift;
    my $path = $self->cleanpath("data/", @_);
    return $path;
}

=head2 output

Get the full path of a file in the C<www/> folder, according the
current C<outputdir> value.

=cut

sub output {
    my $self = shift;
    my $path = $self->cleanpath("www/", @_);
    return $path;
}

=head2 paths

Give the tuple C<(input($file), output($file))>.

=cut

sub paths {
    my $self = shift;
    return ($self->input(@_), $self->output(@_));
}

=head2 cache

Build the name of a file in the cache directory. The path depends on the
current driver and on the page's name.

=cut

# '

sub cache {
    my $self = shift;
    my $name = $self->{name};
    $name =~ s/::/-/g;
    my $path = $self->cleanpath("cache/" . $name . "/", @_);
    my ($file, $base, $ext) = fileparse($path);
    mkpath($base);
    return $path;
}

=head2 cleanpath($base, $file, $extension)

Given a base name and a filename, returns a cleaned path by removing
".." and leading "/". Take care of the outputir.

=cut

sub cleanpath {
    my ($self, $base, @name) = @_;
    my $name = join(".", grep {$_} @name);
    my $path = $self->{page}->att('path');
    my $outputdir = $self->{page}->att('outputdir');

    $name =~ s!\.\./!!g;
    $name =~ s!^/!!;
    $name = $base . $outputdir . $path . $name;

    return $name;
}

=head2 warning

Display a warning message during the processing, giving information on
the current page and the current driver.

=cut

sub warning {
    my ($self, @message) = @_;

    my $name = $self->{name};
    my $path = $self->{page}->att('path');
    my $page_name = $self->{page}->att('name');

    warn
        $name . " warning for " .
        $path . $page_name . ": ",
        @message, "\n";
}

=head2 root

Give the relative path needed to reach the root of the website from the
current page.

=cut

sub root {
    my ($self) = @_;

    my $path = $self->{page}->att('path');
    my $deep = $path;
    $deep =~ s![^/]!!g;
    $deep = length $deep;

    my $root = "../" x $deep;

    return $root;
}

1;


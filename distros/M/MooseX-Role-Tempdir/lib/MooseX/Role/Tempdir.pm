package MooseX::Role::Tempdir;
$MooseX::Role::Tempdir::VERSION = '0.101';
use MooseX::Role::Parameterized;
use File::Temp qw//;
#ABSTRACT: Moose role providing temporary directory attributes



parameter 'dirs' => (
  isa => 'ArrayRef[Str]|HashRef[HashRef]',
  default => sub { [ 'tmpdir' ] },
);

parameter 'tmpdir_opts' => (
  isa => 'HashRef',
  default => sub { {} },
);

role {
  my $self = shift;
  my $dirs = $self->dirs;
  my $global_opts = $self->tmpdir_opts;
  if (ref $dirs eq 'ARRAY') {
    for my $dir (@$dirs) {
      has $dir => (
        is => 'ro',
        isa => 'File::Temp::Dir',
        lazy => 1,
        default => sub {
          return File::Temp->newdir(%$global_opts);
        },
      );
    }
  }
  else {
    for my $dir (keys %$dirs) {
      has $dir => (
        is => 'ro',
        isa => 'File::Temp::Dir',
        lazy => 1,
        default => sub {
          return File::Temp->newdir(%$global_opts, %{$dirs->{$dir}});
        },
      )
    }
  }
};

1; # End of MooseX::Role::Tempdir

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Role::Tempdir - Moose role providing temporary directory attributes

=head1 VERSION

version 0.101

=head1 SYNOPSIS

By default, a single 'tmpdir' attribute is provided. It is recursively removed
when the object goes out of scope:

    package My::Awesome::Package;
    use Moose;
    with 'MooseX::Role::Tempdir';

    ...

    package main;
    my $thing = My::Awesome::Package->new;
    open(my $fh, '>', $thing->tmpdir."/somefile") or die "problem: $!";

You can also use parameters for more directory attributes and/or options:

    with 'MooseX::Role::Tempdir' => {
      dirs => [ qw/tmpdir workdir fundir/ ],
      tmpdir_opts => { DIR => '/my/alternate/tmp' },
    };

    ...

    open(my $fh, '>', $thing->fundir."/somefile") or die "problem: $!";

Or be even more explicit:

    with 'MooseX::Role::Tempdir' => {
      dirs => {
        tmpdir => { TEMPLATE => 'fooXXXXX' },
        permadir => { DIR => '/some/other/dir', CLEANUP => 0 },
      },
      tmpdir_opts => { DIR => '/default/dir' },
    }

    ...

    open(my $fh, '>', $thing->nameddir."/somefile") or die "problem: $!";

=head1 ATTRIBUTES

For each C<dir> parameter (by default, only C<tmpdir>), a temporary directory
attribute is lazily created using L<File::Temp/newdir>. The default options to
C<newdir> will apply, unless overriden by further parameters. This means the
directory and its contents will be removed when the object using this role goes
out of scope.

=head1 PARAMETERS

Parameters may be given to this role as described in
L<MooseX::Role::Parameterized::Tutorial>.

=head2 "dirs"

A C<dirs> parameter may be an array or hash reference. An array reference will
create a temporary directory attribute for each value in the array. A hash
reference creates an attribute for each key, and its value must be a hash
reference of temporary directory options (see L<File::Temp/newdir>).

=head2 "tmpdir_opts"

This parameter sets temporary directory options for all attributes, unless
overridden for a specific directory as described above (with a C<dirs>
hashref).

=head1 AUTHOR

Brad Barden <b at 13os.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Brad Barden.

This is free software, licensed under:

  The ISC License

=cut

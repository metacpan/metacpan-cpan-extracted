package Path::Class::Versioned;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class;
use MooseX::Params::Validate;

use List::Util 'max';

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

# this is a basic type for objects
# that overload stringification, it
# is not perfect cause Perl's overload
# is not perfect, so if you hit an
# edge case, please send a bug report.
subtype 'Path::Class::Versioned::Stringifyable'
    => as 'Object'
    => where {
        require overload;
        overload::Method($_, '""')
    };

# Accept strings, or objects which
# we can stringify, and one undefined
# value (our version number placeholder)
subtype 'Path::Class::Versioned::NamePattern'
    => as 'ArrayRef[Str | Undef | Path::Class::Versioned::Stringifyable]'
    => where {
        (grep { not(defined $_) } @{$_[0]}) == 1
    }
    => message {
        "Your name pattern must be made up of "
        . "strings, stringifyable objects and "
        . "exactly *one* undef value"
    };

## the attributes ...

has 'name_pattern'   => (is => 'ro', isa => 'Path::Class::Versioned::NamePattern', required => 1);
has 'version_format' => (is => 'ro', isa => 'Str', default => sub { '%d' });

has '_compiled_name_pattern' => (
    is      => 'ro',
    isa     => 'RegexpRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $name_pattern = join "" => (map { defined $_ ? $_ : '(\d+)' } @{ $self->name_pattern });
        qr/$name_pattern/;
    },
);

has 'parent' => (
    is      => 'ro',
    isa     => 'Path::Class::Dir',
    coerce  => 1,
    default => sub { Path::Class::Dir->new }
);

# the methods ...

sub next_file {
    my $self = shift;
    $self->parent->file($self->next_name(file => 1));
}

sub next_dir {
    my $self = shift;
    $self->parent->subdir($self->next_name(dir => 1));
}

sub next_name {
    my ($self, $is_dir, $is_file) = validated_list(\@_,
        dir  => { isa => 'Bool', optional => 1 },
        file => { isa => 'Bool', optional => 1, default => 1 }
    );

    my $name_extractor = $is_dir
        ? sub { (shift)->relative($self->parent)->stringify }
        : sub { (shift)->basename                           };

    my $name_pattern = $self->_compiled_name_pattern;
    my $max_version  = max(
        map {
            ($name_extractor->($_) =~ /$name_pattern/)
        } grep {
            ($is_dir ? (-d $_) : (-f $_))
        } $self->parent->children
    );

    $max_version = 0 unless defined $max_version;

    my $next_version = sprintf $self->version_format, ($max_version + 1);

    join "" => (map { defined $_ ? $_ : $next_version } @{ $self->name_pattern });
}

no Moose; 1;

__END__

=pod

=head1 NAME

Path::Class::Versioned - A simple module for managing versioned file names

=head1 SYNOPSIS

  use Path::Class::Versioned;

  # typical usage for files ...

  my $v = Path::Class::Versioned->new(
      name_pattern => [ 'MyBackups-v', undef, '.zip' ],
      parent       => [ $FindBin::Bin, 'backups' ] # coerced into Path::Class::Dir
  );

  # create the next filename in the
  # sequence as specified by the
  # name pattern above.
  my $next_file_name = $v->next_name; # defaults to files ...

  # create an instance of Path::Class::File
  # that represents that next file name
  my $file = $v->next_file;

  # typical usage for directories ...

  my $v = Path::Class::Versioned->new(
      name_pattern => [ 'MyBackupDirectory-v', undef ],
      parent       => Path::Class::Dir->new() # will use current dir
  );

  # just like the file example, but
  # tell it to match against directories
  # instead of files
  my $next_dir_name = $v->next_name(dir => 1);

  # create an instance of Path::Class::Dir
  # that represents that next directory name
  my $subdir = $v->next_dir;

=head1 DESCRIPTION

C'mon, you know you have done this too, so why bother writing it over
and over again, just use this module.

This module aims to provide a simple, yet sophisticated way of creating
and managing versioned files by name. It is a poor substitute for using
a real VCS (version control system) or some more sophisticated versioning
module that utilizes diffs, etc. However, there are some times when you
just don't need that level of control, and just need to back stuff up
in a simple way, so here it is.

=head1 ATTRIBUTES

These attributes should be set through the constructor, all are required
except for the C<version_format> which will default to just printing the
number.

=over 4

=item B<name_pattern>

This is expected to be an ArrayRef made up of strings, stringify-able objects
and I<exactly> B<one> C<undef> value. The C<undef> value will serve as the
placeholder for the version number. Here are some example formats and the
names they create.

For a simple sequentially named file set, with no extra version formatting
you might do something like this:

  [ 'Foo-v', undef, '.txt' ]
  # Foo-v1.txt, Foo-v2.txt, etc ...

For a simple date-stamped directory set with a I<version_format> of C<%02d>
you might do something like this:

  [ 'Baz-', $datetime, '-v', undef ]
   # Baz-2008-05-12-v01/, Baz-2008-05-12-v02/

It is assumed that your C<$datetime> instance already has the formatter set
to produce the specified string. Something like this has the benefit of making
it very simple to create dated files/directories, but not have to worry about
overwriting something in the same day.

=item B<version_format>

This is a format string which will be passed to C<sprintf> in order to
format the version number. It defaults to just returning the number itself.

=item B<parent>

This is a L<Path::Class::Dir> object representing the parent directory, it
is the contents of this directory which will be inspected to determine the
next name to be created.

Alternately you can specify an ArrayRef of strings, or a string itself and
those will be coerced into a L<Path::Class::Dir> object. We use the type
created by the L<MooseX::Types::Path::Class> module, please refer that for
more details.

=back

=head1 METHODS

=over 4

=item B<next_name (dir => Bool, file => Bool)>

Returns the next file name (if the C<file> boolean argument is true) or
the next directory name (if the C<dir> boolean argument is true). It defaults
to the a file name.

=item B<next_file>

Returns a L<Path::Class::File> object for the value of C<next_name(file => 1)>.

=item B<next_dir>

Returns a L<Path::Class::Dir> object for the value of C<next_name(dir => 1)>.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 ACKNOWLEDGEMENTS

NO ONE IS INNOCENT! Here are the names of those who are especially guilty.

=over 4

=item Thanks to perigrin for holding back the snide comments when I suggested this module.

=item Thanks to rjbs for the module name (although he may deny any involvment).

=back

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


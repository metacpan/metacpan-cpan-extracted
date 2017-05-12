package Remember::Anything::AsPath;

use 5.010;

use strict;
use warnings;
use Carp;
use Sereal::Encoder;

our $VERSION = '0.05';

sub new {
    my ($class, %args) = @_;

    my $tree_depth = int(($args{tree_depth} // 2) + 1);
    croak 'tree depth must be at least 1' if $tree_depth < 1;

    my $digest_sub = $args{digest_sub} // do {
        eval { require Digest::SHA }
            || croak "pass 'digest_sub' which returns path friendly chars  as attribute "
                   . "or install 'Digest::SHA' module to use default digest function";
        Digest::SHA->import('sha1_hex');
        \&sha1_hex;
    };

    my $part_length = int(length($digest_sub->(1)) / ($args{tree_depth} // 3) + 1);
    my $encoder     = Sereal::Encoder->new({ canonical => 1 });
    $args{_path_parts_of} = sub {
        unpack "(A$part_length)*", $digest_sub->( $encoder->encode(\@_) );
    };

    $args{out_dir} ||= '.';
    $args{out_dir} =~ s{[\/\\]$}{}; # remove trailing slash or backslash
    croak 'out dir does not exist' unless -d $args{out_dir};

    return bless \%args, $class;
}

sub seen {
    my $self = shift;
    return (-f join '/', $self->{out_dir}, $self->{_path_parts_of}->(@_)) // 0;
}

sub remember {
    my $self = shift;

    my @path_parts = $self->{_path_parts_of}->(@_);

    my $full_path = join '/', $self->{out_dir}, @path_parts;
    return if -f $full_path;

    my $cur_path = $self->{out_dir};
    for my $path_part (@path_parts[0 .. $#path_parts - 1]) {
        $cur_path .= "/$path_part";
        eval { mkdir $cur_path unless -d $cur_path }
    }

    open my $fh, '>', $full_path;
    close $fh;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Remember::Anything::AsPath - remember objects seen by a specific created id in a folder structure

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Remember::Anything::AsPath;

  my $book = {
      url   => 'www.books.de/3',
      name  => 'I <3 perl',
      price => 999,
  };

  my $brain = Remember::Anything::AsPath->new(
      tree_depth => $some_int # 1, only file directly, 2 one folder then file ....
                              # default is 2
      digest_sub => sub {
          # return pathfriendly checksum of string
          # on default this is sha1_hex
      },
      out_dir => 'where/to/start/with/tree' # default '.'
  );

  # remember $book object in
  $brain->remember($book);

  if ($brain->seen($another_book) {
      # discard? ...
  }
  else {
      # save
      push @books, $another_book;
  }

=head1 DESCRIPTION

Remember $anything in a tree of folders and empty files.

=head1 METHODS

=head2 remember

  $brain->remember($anything);

Remember $antything in the filesystem. $anything will be hashed and saved
in a tree of folders and one empty file.

Example for tree_depth of 2:

$anything -> $hashed_id -> out_dir/$id_part_1/$id_part_2/$id_part_3

=head2 seen

  $brain->seen($anything);

Checks if there is an existing file path for the hashed id of $anything.
If $anything has been remembered before it will return 1, otherwise 0.

=head1 ACKNOWLEDGEMENTS

ac0vs dirty and beautiful way of avoiding a database.

=head1 LICENSE

This is released under the Artistic License.

=head1 AUTHOR

spebern <bernhard@specht.net>

=cut

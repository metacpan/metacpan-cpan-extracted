package Parse::CPAN::Authors;
use strict;
use IO::Zlib;
use Parse::CPAN::Authors::Author;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( mailrc data ));
use vars qw($VERSION);
$VERSION = '2.27';

sub new {
    my $class    = shift;
    my $filename = shift;
    my $self     = {};
    bless $self, $class;

    $filename = '01mailrc.txt.gz' if not defined $filename;

    if ( $filename =~ /^alias / ) {
        $self->mailrc($filename);
    } elsif ( $filename =~ /\.gz/ ) {
        my $fh = IO::Zlib->new( $filename, "rb" );
        die "Failed to read $filename: $!" unless $fh;
        $self->mailrc( join '', <$fh> );
        $fh->close;
    } else {
        open( IN, $filename ) || die "Failed to read $filename: $!";
        $self->mailrc( join '', <IN> );
        close(IN);
    }

    $self->_parse;

    return $self;
}

sub _parse {
    my $self = shift;
    my $data;

    foreach my $line ( split "\n", $self->mailrc ) {
        my ( $alias, $pauseid, $long ) = split ' ', $line, 3;
        $long =~ s/^"//;
        $long =~ s/"$//;
        my ($name, $email) = $long =~ /(.*) <(.+)>$/;
        my $a = Parse::CPAN::Authors::Author->new;
        $a->pauseid($pauseid);
        $a->name($name);
        $a->email($email);
        $data->{$pauseid} = $a;
    }
    $self->data($data);
}

sub author {
    my ( $self, $pauseid ) = @_;
    return $self->data->{$pauseid};
}

sub authors {
    my ($self) = @_;
    return values %{ $self->data };
}

1;

__END__

=head1 NAME

Parse::CPAN::Authors - Parse 01mailrc.txt.gz

=head1 SYNOPSIS

  use Parse::CPAN::Authors;

  # must have downloaded
  my $p = Parse::CPAN::Authors->new("01mailrc.txt.gz");
  # either a filename as above or pass in the contents of the file
  my $p = Parse::CPAN::Authors->new($mailrc_contents);

  my $author = $p->author('LBROCARD');
  # $a is a Parse::CPAN::Authors::Author object
  # ... objects are returned by Parse::CPAN::Authors
  print $author->email, "\n";   # leon@astray.com
  print $author->name, "\n";    # Leon Brocard
  print $author->pauseid, "\n"; # LBROCARD

  # all the author objects
  my @authors = $p->authors;

=head1 DESCRIPTION

The Comprehensive Perl Archive Network (CPAN) is a very useful
collection of Perl code. It has several indices of the files that it
hosts, including a file named "01mailrc.txt.gz" in the "authors"
directory. This file contains lots of useful information on CPAN
authors and this module provides a simple interface to the data
contained within.

Note that this module does not concern itself with downloading this
file. You should do this yourself.

=head1 METHODS

=head2 new()

The new() method is the constructor. It takes either the path to the
01mailrc.txt.gz file or its contents. It defaults to loading the file
from the current directory. You must download it yourself.

  # must have downloaded
  my $p = Parse::CPAN::Authors->new("01mailrc.txt.gz");
  # either a filename as above or pass in the contents of the file
  my $p = Parse::CPAN::Authors->new($mailrc_contents);

=head2 author()

The author() method returns a Parse::CPAN::Authors::Author object
representing a user:

  my $author = $p->author('LBROCARD');

=head2 authors()

The authors() method returns a list of Parse::CPAN::Authors::Author
objects, for each author on CPAN:

  my @authors = $p->authors;

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2004, Leon Brocard

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.

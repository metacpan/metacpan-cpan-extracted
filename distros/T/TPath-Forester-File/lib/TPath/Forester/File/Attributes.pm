package TPath::Forester::File::Attributes;
{
  $TPath::Forester::File::Attributes::VERSION = '0.003';
}

# ABSTRACT: the basic attributes of L<TPath::Forester::File::Node> objects


use v5.10;
use Moose::Role;
use MooseX::MethodAttributes::Role;


sub text : Attr {
    my ( undef, $ctx ) = @_;
    my $n = $ctx->n;
    return $n->text || undef;
}


sub txt : Attr { goto &T }


sub T : Attr {
    my ( undef, $ctx ) = @_;
    my $n = $ctx->n;
    return $n->is_text || undef;
}


sub bin : Attr {
    my ( $self, $ctx ) = @_;
    return $self->f($ctx) && !$self->z($ctx) && $self->B($ctx)
      || undef;
}


sub B : Attr {
    my ( undef, $ctx ) = @_;
    my $n = $ctx->n;
    return $n->is_binary || undef;
}


sub oid : Attr {
    my ( undef, $ctx ) = @_;
    return $ctx->n->uid;
}


sub gid : Attr {
    my ( undef, $ctx ) = @_;
    return $ctx->n->gid;
}

sub fexists : Attr(exists) { goto &e }

sub e : Attr {
    my ( undef, $ctx ) = @_;
    $ctx->n->real || undef;
}

sub s : Attr {
    my ( undef, $ctx ) = @_;
    return $ctx->n->size;
}

sub empty : Attr { goto &z }

sub z : Attr {
    my ( undef, $ctx ) = @_;
    return $ctx->n->is_empty || undef;
}

sub file : Attr { goto &f }

sub f : Attr {
    my ( undef, $ctx ) = @_;
    return $ctx->n->is_file || undef;
}

sub dir : Attr { goto &d }

sub d : Attr {
    my ( undef, $ctx ) = @_;
    return $ctx->n->is_directory || undef;
}

sub link : Attr { goto &l }

sub l : Attr {
    my ( undef, $ctx ) = @_;
    return $ctx->n->is_link || undef;
}

sub r : Attr {
    my ( undef, $ctx ) = @_;
    return $ctx->n->can_read || undef;
}

sub w : Attr {
    my ( undef, $ctx ) = @_;
    return $ctx->n->can_write || undef;
}

sub x : Attr {
    my ( undef, $ctx ) = @_;
    return $ctx->n->can_execute || undef;
}


sub user : Attr {
    my ( undef, $ctx ) = @_;
    return $ctx->n->user;
}


sub group : Attr {
    my ( undef, $ctx ) = @_;
    return $ctx->n->group;
}


sub lines : Attr {
    my ( undef, $ctx ) = @_;
    return [ $ctx->n->lines ];
}


sub exec : Attr {
    my ( undef, $ctx, $expr ) = @_;
    my $f = $ctx->n . '';
    $expr =~ s/\b_\b/$f/eg;
    my $ret = `$expr` || undef;
    return $ret;
}


sub kb : Attr {
    my ( undef, undef, $n ) = @_;
    return 1024 * $n;
}


sub mb : Attr {
    my ( undef, undef, $n ) = @_;
    return 1024 * 1024 * $n;
}


sub gb : Attr {
    my ( undef, undef, $n ) = @_;
    return 1024 * 1024 * 1024 * $n;
}


sub me : Attr { $< }


sub name : Attr { $_[1]->n->name }


sub encoding : Attr {
    my ( undef, $ctx ) = @_;
    $ctx->n->encoding;
}

sub enc : Attr {
    goto &encoding;
}


sub broken : Attr {
    $_[1]->n->broken || undef;
}


sub ext : Attr {
    my ( undef, $ctx, $ext ) = @_;
    return undef unless $ext;
    $ext = '.' . $ext;
    my $n = $ctx->n->name;
    my $i = index $n, $ext;
    return undef unless $i > 0;
    return $i + length $ext == length $n ? 1 : undef;
}

1;

__END__

=pod

=head1 NAME

TPath::Forester::File::Attributes - the basic attributes of L<TPath::Forester::File::Node> objects

=head1 VERSION

version 0.003

=head1 DESCRIPTION

C<TPath::Forester::File::Attributes> provides the attributes available to all L<TPath::Forester::File> foresters.

=head2 C<@text>

The actual text of the file, if it is a text file, or C<undef>.

=head2 C<@txt>

An alias for C<@txt>.

=head2 C<@T>

Whether the file is a text file according to C<TPath::Forester::File::Node::is_text()>.

=head2 C<@bin>

Like C<@B> but true only for files, not directories.

=head2 C<@B>

Equivalent to the C<-B> file test operator. True for binary files, empty
files, and directories.

=head2 C<@oid>

File owner id. This would be called C<@uid>, but that attribute name is already taken
by the standard attribute library.

=head2 C<@gid>

File group id.

=head2 C<@user>

Returns the name corresponding to the file's uid.

  //*[@user = 'foo']  # find all foo's files

=head2 C<@group>

Returns the name corresponding to the file's gid.

  //*[@group = 'research']  # find all the files belonging to the research group

=head2 C<@lines>

The lines in the file returned as an array reference. If the file is not a text file,
this will be an empty array.

=head2 C<@exec('rm -rf _')>

Executes the command parameter, replacing C<_> with the context file. For example, the
following will remove all text files from a directory:

  //@txt[@exec('rm -rf _')]

Anything printed to STDOUT is captured and returned as the value of the attribute, the
empty string being returned as C<undef>.

=head2 C<@kb(2)>

Converts a number to a number of kilobytes. This saves doing the conversion oneself, so
you can write expressions like

  //@f[@size > @kb(12)]

instead of

  //@f[@size > 12 * 1024]

or

  //@f[@size > 12288]

There is a slight efficiency cost in using C<@kb>, as the conversion will be done for
every file tested.

=head2 C<@mb(2)>

Converts a number to a number of megabytes. This saves doing the conversion oneself, so
you can write expressions like

  //@f[@size > @mb(12)]

instead of

  //@f[@size > 12 * 1024 * 1024]

or

  //@f[@size > 12582912]

There is a slight efficiency cost in using C<@mb>, as the conversion will be done for
every file tested.

=head2 C<@gb(2)>

Converts a number to a number of gigabytes. This saves doing the conversion oneself, so
you can write expressions like

  //@f[@size > @gb(12)]

instead of

  //@f[@size > 12 * 1024 * 1024 * 1024]

or

  //@f[@size > 12884901888]

There is a slight efficiency cost in using C<@gb>, as the conversion will be done for
every file tested.

=head2 C<@me>

The real user id of the currently running process; i.e., C<<$<>>.

=head1 ATTRIBUTES

=head2 C<@broken>

True if C<stat> returns the empty list for this file.

=head2 C<@ext('txt')>

True if the file has the given extension. The following are equivalent

  //@ext('txt')
  //~\.txt$~
  //*[@name =| '.txt']

The latter is second shorter but also more cryptic. In its implementation
C<@ext> is more like the last expression, but it applies the test on
selection rather than filtering.

=head1 C<@name>

The file (or directory) name.

=head1 C<@encoding>, C<@enc>

Encoding detected, if any.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Mojo::Path::Role::Relative;
use Mojo::Base -role;
use Mojo::File;

our $VERSION = '0.01';

# https://github.com/mojolicious/mojo/issues/573

requires qw{clone leading_slash new parts to_string trailing_slash};

sub is_subpath_of {
    my ($self, $base) = @_;
    $base = $self->new($base) unless ref($base);
    return 0 if @$base > @$self;

    my $sp = [@{$self}];
    my $bp = $base->parts;

    for (my $i = 0; $i < @$bp; ++$i) {
        $i = @$bp && next if $bp->[$i] ne $sp->[0];
        shift @$sp;
    }

    return !!(@$self != @$sp);
}

sub to_rel {
    my ($self, $base) = @_;
    my $x = Mojo::File->new("$self");
    return $self->new($x->to_rel("$base")->to_string);
}

sub to_subpath_of {
    my ($self, $base) = @_; 
    my $clone = $self->clone;
    return $clone unless $self->is_subpath_of($base);
    $base = $self->new($base) unless ref($base);

    my $bp = $base->parts;
    
    for (my $i = 0; $i < @$bp; ++$i) {
        $i = @$bp && next if ($bp->[$i] ne $clone->parts->[0]);
        shift @{$clone->{parts}};
    }

    return $clone->leading_slash(0);
}

1;


=encoding utf8

=begin html

<a href="https://travis-ci.com/kiwiroy/mojo-path-role-relative">
  <img src="https://travis-ci.com/kiwiroy/mojo-path-role-relative.svg?branch=master">
</a>

=end html

=head1 NAME

Mojo::Path::Role::Relative - Relative operations on a Mojo::Path

=head1 SYNOPSIS

  $path = Mojo::Path->with_roles('+Relative')->new('/foo/bar/baz/data.json');
  $base = Mojo::Path->new('/foo/bar');
  # 1
  $path->is_subpath_of($base);
  # "baz/data.json"
  $path->to_subpath_of($base);
  # "baz/data.json"
  $path->to_rel($base);

=head1 DESCRIPTION

L<Mojo::URL/"to_rel"> was deprecated sometime ago. A suggestion was made to move
the functionality to L<Mojo::Path>. This is an implementation of that suggestion
as a L<role|Role:Riny>.

=head1 METHODS

This role adds the following methods to L<Mojo::Path> when composed.

=head2 is_subpath_of

=head2 to_rel

=head2 to_subpath_of



=head1 AUTHOR

kiwiroy - Roy Storey <kiwiroy@cpan.org>

=head1 LICENSE

This library is free software and may be distributed under the same terms as
perl itself.

=cut

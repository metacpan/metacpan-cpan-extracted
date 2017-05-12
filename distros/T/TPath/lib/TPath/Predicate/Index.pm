package TPath::Predicate::Index;
$TPath::Predicate::Index::VERSION = '1.007';
# ABSTRACT: implements the C<[0]> in C<//a/b[0]>


use Moose;
use Scalar::Util qw(refaddr);


with 'TPath::Predicate';


has idx => ( is => 'ro', isa => 'Int', required => 1 );

has f => (is => 'ro', does => 'TPath::Forester', required => 1);

# needed for lazy specification of algorithm
has _anywhere => (is=>'rw', isa => 'Bool', default => 0);

has algorithm => (
    is      => 'ro',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $i    = $self->idx;
        if ( $self->f->one_based ) {
            die '[0] predicate used in path expecting 1-based indices'
              if $i == 0;
            $i-- if $i > 0;
        }
        return sub {
            return shift->[$i] // ();
          }
          if $self->outer or !$self->_anywhere;
        return sub {
            my $c = shift;
            my ( $index, %tally, @ret );
            for my $ctx (@$c) {
                $index //= $ctx->i;
                my $p = $index->parent( $ctx->n );
                $p = defined $p ? refaddr $p : -1;
                next if $tally{$p};
                $tally{$p} = 1;
                push @ret, $ctx;
            }
            return @ret;
          }
          if $i == 0;
        return sub {
            my $c = shift;
            my ( $index, %tally, @parents );
            for my $ctx (@$c) {
                $index //= $ctx->i;
                my $p = $index->parent( $ctx->n );
                $p = defined $p ? refaddr $p : -1;
                my $ar;
                unless ( $ar = $tally{$p} ) {
                    push @parents, $p;
                    $ar = $tally{$p} = [];
                }
                push @$ar, $ctx;
            }
            my @ret;
            for my $p (@parents) {
                my $ctx = $tally{$p}[$i];
                push @ret, $ctx if $ctx;
            }
            return @ret;
          }
          if $i < 0;
        return sub {
            my $c = shift;
            my ( $index, %tally, @ret );
            for my $ctx (@$c) {
                $index //= $ctx->i;
                my $p = $index->parent( $ctx->n );
                $p = defined $p ? refaddr $p : -1;
                $tally{$p} //= 0;
                push @ret, $ctx if $tally{$p}++ == $i;
            }
            return @ret;
        };
    },
);

sub filter {
    my ( $self, $c ) = @_;
    return $self->algorithm->($c);
}

sub to_string {
    $_[0]->idx;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Predicate::Index - implements the C<[0]> in C<//a/b[0]>

=head1 VERSION

version 1.007

=head1 DESCRIPTION

The object that selects the correct member of collection based on its index.

=head1 ATTRIBUTES

=head2 idx

The index of the item selected.

=head1 ROLES

L<TPath::Predicate>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

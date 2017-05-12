package TPath::Forester::File;
{
  $TPath::Forester::File::VERSION = '0.003';
}

# ABSTRACT: L<TPath::Forester> that understands file systems

$TPath::Forester::File::VERSION ||= .001; # Dist::Zilla will automatically update this
                                                                                
use v5.12;
use Moose;
use Moose::Exporter;
use namespace::autoclean;

use Module::Load::Conditional qw(can_load);
use TPath::Forester::File::Node;
use TPath::Forester::File::Index;

with
  'TPath::Forester' => { -excludes => [qw(wrap index)] },
  'TPath::Forester::File::Attributes';

Moose::Exporter->setup_import_methods( as_is => [ tff => \&tff ], );


sub children { my ( $self, $n ) = @_; @{ $n->children } }


sub tag { my ( $self, $n ) = @_; $n->name }

#sub id { my ( $self, $n )   = @_; $n->attribute('id') }


has encoding_detector => ( is => 'ro', isa => 'CodeRef' );

around BUILDARGS => sub {
    my ( $orig, $class, %params ) = @_;
    unless ( exists $params{encoding_detector} ) {
        state $can =
          can_load( modules => { 'Encode::Detect::Detector' => undef } );
        if ($can) {
            require Encode::Detect::Detector;
            state $detector = Encode::Detect::Detector->new;
            $params{encoding_detector} = sub {
                my $n = shift;
                return unless $n;
                my $data = $n->octets;
                return unless $data;
                $detector->handle($data);
                $detector->eof;
                my $cs = $detector->getresult;
                $detector->reset;
                return $cs;
            };
        }
    }
    unless ( defined $params{encoding_detector} ) {
        $params{encoding_detector} = sub { return };
    }
    $class->$orig(%params);
};

sub BUILD { $_[0]->_node_type('TPath::Forester::File::Node') }

has roots => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    writer  => '_roots'
);


sub clean { shift->_roots( {} ) }

# coercion mechanism that turns strings into TPath::Forester::Ref::Node objects
sub wrap {
    my ( $self, $n ) = @_;
    return $n if blessed($n) && $n->isa('TPath::Forester::Ref::Node');
    if ( -e $n ) {
        $n = Cwd::realpath($n);

        # for now we ignore the volume
        my ( $volume, $directories, $file ) = File::Spec->splitpath($n);
        if ($file) {
            my $p = $self->wrap($directories);
            return $p->_find_child($file);
        }
        else {
            my $root = $self->roots->{$volume};
            unless ($root) {
                $root = TPath::Forester::File::Node->new(
                    name              => File::Spec->rootdir,
                    real              => 1,
                    parent            => undef,
                    volume            => $volume,
                    encoding_detector => $self->encoding_detector,
                );
                $self->roots->{$volume} = $root;
            }
            return $root;
        }
    }
    else {
        return TPath::Forester::File::Node->new(
            name              => $n,
            real              => 0,
            encoding_detector => $self->encoding_detector,
            parent            => undef
        );
    }
}


sub tff() { state $singleton = TPath::Forester::File->new }

sub index {
    my $self = shift;
    state $idx = TPath::Forester::File::Index->new(
        f         => $self,
        root      => File::Spec->rootdir,
        node_type => $self->node_type
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

TPath::Forester::File - L<TPath::Forester> that understands file systems

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 encoding_detector

A code reference that when given a L<TPath::Forester::File::Node> will return a
guess as to its encoding, or some false value if it cannot hazard a guess. If
no value is set for this attribute, the forester will attempt to construct one
using L<Encode::Detect::Detector>. If this proves impossible, it will provide
a detector that never guesses. If you wish the latter -- just go with the system's
default encoding -- set C<encoding_detector> to C<undef>.

B<Note>, if you have a non-trivial encoding detector and you wish to access a file's
text, you will end up reading the file's contents twice. If you want to save this
expense and take your chances with the encoding, explicity set C<encoding_detector> to
C<undef>.

=head1 METHODS

=head2 children

A file's children are the files it contains, if any. Links are regarded as having no children
even if they are directory links.

=head2 tag

A file's "tag" is its name.

=head2 clean

C<clean> purges all cached information about the
file system. Because nodes only know their parents through weak references, if
you clean the cache, all ancestor nodes which are not themselves descendants of
some other node whose reference is still retained will be garbage collected.

This method is useful because to reduce file system thrash file meta-data is cached
aggressively. To facilitate wrapping, this caching is done in the forester itself
rather than the index. But this means that as the file system changes its cached
representation can grow out of sync. So if you know or fear files have changed,
you will want to clean the forester.

=head1 FUNCTIONS

=head2 tfr

Returns singleton C<TPath::Forester::File>. This function has an empty prototype, so
it may be used like a scalar.

  # collect all the text files under the first argument
  my @files = tff->path('//@txt')->select(shift);

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

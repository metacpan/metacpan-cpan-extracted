package Rose::DBx::Object::Indexed::Indexer;

use warnings;
use strict;
use base qw( Rose::Object );
use Carp;
use Class::C3;
use SWISH::Prog;
use SWISH::Prog::Config;
use SWISH::Prog::Doc;
use SWISH::Prog::Utils;

use Rose::Object::MakeMethods::Generic (
    'scalar --get_set_init' => 'config',
    'scalar --get_set_init' => 'invindex',
    'scalar --get_set_init' => 'swish_indexer',
    'scalar --get_set_init' => 'indexer_class',
    'scalar --get_set_init' => 'prune',
    'scalar --get_set_init' => 'force_load',
    'scalar --get_set_init' => 'tree_opts',
    'scalar'                => 'xml_root_element',
    'scalar --get_set_init' => 'max_depth',
    'scalar --get_set_init' => 'debug',
);

our $VERSION = '0.009';

=head1 NAME

Rose::DBx::Object::Indexed::Indexer - Indexer base class

=head1 SYNOPSIS

 # from a Rose::DBx::Object::Indexed object
 my $thing = MyThing->new( id => 123 )->load;
 $thing->write_index('insert');
 
 # standalone
 my $indexer = MyThing->init_indexer;
 while (my $thing = $thing_iterator->next) {
    $indexer->insert($thing);
 }

=head1 DESCRIPTION

Rose::DBx::Object::Indexed::Indexer uses SWISH::Prog to create
and maintain full-text indexes of Rose::DB::Object instances.

This class is typically accessed via Rose::DBx::Object::Indexed instances.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

=head2 init_invindex

Should return either a path to the index directory or a SWISH::Prog::InvIndex
object. The default is a no-op, which will tell the indexer to
generate a default SWISH::Prog::InvIndex object.

=cut

sub init_invindex { }

=head2 init_config

Should return a SWISH::Prog::Config instance. The default is a new Config instance.

=cut

sub init_config {
    return SWISH::Prog::Config->new;
}

=head2 init_indexer_class

The default is SWISH::Prog::Native::Indexer.

=cut

sub init_indexer_class {'SWISH::Prog::Native::Indexer'}

=head2 init

Just calls next::method().

=cut

sub init {
    my $self = shift;
    $self->next::method(@_);
    return $self;
}

=head2 init_swish_indexer

Loads and returns an instance of indexer_class().

=cut

sub init_swish_indexer {
    my $self  = shift;
    my $class = $self->indexer_class;

    eval "require $class";

    my $indexer = $class->new(
        config   => $self->config,
        invindex => $self->invindex,
        @_
    );
    return $indexer;
}

=head2 init_prune

Should return a hash ref of relationship names to skip in serialize_object().

The default is an empty hash ref (skip nothing).

=cut

sub init_prune { {} }

=head2 init_tree_opts

Should return array ref of key/value pairs to pass into the as_tree()
method in Rose::DB::Object::Helpers. Default is an empty array.

=cut

sub init_tree_opts { [] }

=head2 get_primary_key( I<rdbo_obj> )

Should return the primary key to be used as the "URL" of the indexed "document".
The default return value is primary_key_uri_escaped() from the Rose::DBx::Object::MoreHelpers
class.

=cut

sub get_primary_key {
    $_[1]->primary_key_uri_escaped;
}

=head2 init_max_depth

Used by serialize_object(). The default value is 1.

=cut

sub init_max_depth {1}

=head2 init_force_load

Used by serialize_object(). The default value is 1 (which is B<not>
the default value in as_tree()).

=cut

sub init_force_load {1}

=head2 init_debug

Some messages on stderr if true. Default is false.

=cut

sub init_debug {0}

=head2 serialize_object( I<rdbo_object> )

Returns I<rdbo_object> as a hash ref, using the as_tree() Helper method.

=cut

sub serialize_object {
    my $self = shift;
    my $obj  = shift;
    unless ( defined $obj and ref $obj ) {
        croak
            "must load or pass a RDBO object before calling serialize_object";
    }
    my $prune = $self->prune;
    my $hash  = $obj->as_tree(
        force_load => $self->force_load,
        max_depth  => $self->max_depth,
        prune      => sub {
            my ( $rel_meta, $object, $depth ) = @_;

            if ( $self->debug ) {
                warn sprintf(
                    "eval prune for rel %s for object %s at depth %s\n",
                    $rel_meta->name, $object, $depth );
            }

            return exists $prune->{ $rel_meta->name };
        },
        @{ $self->tree_opts },

    );
    return $hash;
}

=head2 xml_root_element( [I<tagname>] )

Get/set the root tag name to use when serializing to XML. Default
is to use the return value of get_xml_root_element().

=head2 get_xml_root_element( I<rdbo_obj> )

Returns the name of the element to use as the top-level XML tag,
by default the RDBO class name, XML-escaped.

=cut

sub get_xml_root_element {
    my $el = $_[1]->meta->class;
    $el =~ s/\W/_/g;
    return $el;
}

=head2 to_xml( I<hash>, I<rdbo_obj> [, I<strip_plurals>] )

Returns I<hash> as XML, using xml_root_element() as the top-level tag.

=cut

sub to_xml {
    my $self = shift;
    my $hash = shift or croak "hash ref required";
    my $obj  = shift or croak "RDBO object required";
    my $root = $self->xml_root_element || $self->get_xml_root_element($obj);
    return SWISH::Prog::Utils->perl_to_xml( $hash, $root, @_ );
}

=head2 make_doc( I<rdbo_obj> )

Returns a SWISH::Prog::Doc instance for I<rdbo_obj>.

=cut

sub make_doc {
    my $self = shift;
    my $obj  = shift or croak "RDBO object required";
    my $xml  = $self->to_xml( $self->serialize_object($obj), $obj );
    return SWISH::Prog::Doc->new(
        content => $xml,
        url     => $self->get_primary_key($obj),
        modtime => time(),
        parser  => 'XML*',
        type    => 'application/x-rdbo-indexed',    # TODO ??
    );
}

=head2 run( I<rdbo_obj> [, I<action>] )

The main method. Serializes I<rdbo_obj> and hands it to the swish_indexer()
process() method.

=cut

sub run {
    my $self    = shift;
    my $obj     = shift or croak "RDBO object required";
    my $action  = shift;
    my $indexer = $self->swish_indexer;

    # the very first time we run we must seed the index
    # with a dummy "document" so that we can pass the -u
    # option in both insert() and update().
    # the -u option to the native swish-e indexer means
    # that the index *as a whole* should be updated,
    # not just a particular "document".
    if ( !-s $indexer->invindex->path->file('swish.xml') ) {
        $self->__seed_index();
    }
    my $doc = $self->make_doc($obj);
    $doc->action($action) if $action;
    $indexer->process($doc);
}

sub __seed_index {
    my $self  = shift;
    my $dummy = SWISH::Prog::Doc->new(
        content => "000dummy000",     # assume no one ever searches for this..
        url     => "000-dummy-000",
        modtime => time(),
        parser  => 'TXT*',
        type => 'application/x-rdbo-indexed',    # TODO ??
    );

    # must init a new indexer since it will write the swish.xml file
    # only when it is destroyed.
    my $indexer = $self->init_swish_indexer();
    my $opts    = $indexer->opts;
    $indexer->opts('');
    $indexer->process($dummy);
    $indexer->opts($opts);

}

=head2 insert( I<rdbo_obj> )

Calls run() with the appropriate arguments.

=cut

sub insert {
    my $self = shift;
    my $obj = shift or croak "RDBO object required";
    $self->swish_indexer->opts('-u');    # TODO header should be enough
    $self->run($obj);    # no action. the default is to 'Index' (add)
}

=head2 update( I<rdbo_obj> )

Calls run() with the appropriate arguments.

=cut

sub update {
    my $self = shift;
    my $obj = shift or croak "RDBO object required";
    $self->swish_indexer->opts('-u');    # TODO header should be enough
    $self->run( $obj, 'Update' );
}

=head2 delete( I<rdbo_obj> )

Calls run() with the appropriate arguments.

=cut

sub delete {
    my $self = shift;
    my $obj = shift or croak "RDBO object required";
    $self->swish_indexer->opts('-r');
    $self->run( $obj, 'Remove' );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-dbx-object-indexed@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut



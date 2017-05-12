package SWISH::Prog::KSx::Indexer;
use strict;
use warnings;

our $VERSION = '0.21';

use base qw( SWISH::Prog::Indexer );
use SWISH::Prog::KSx::InvIndex;

use KinoSearch::Index::Indexer;
use KinoSearch::Plan::Schema;
use KinoSearch::Plan::FullTextType;
use KinoSearch::Plan::StringType;
use KinoSearch::Analysis::PolyAnalyzer;

use Carp;
use SWISH::3 qw( :constants );
use Scalar::Util qw( blessed );
use Data::Dump qw( dump );
use Search::Tools::UTF8;
use Path::Class::File::Lockable;

=head1 NAME

SWISH::Prog::KSx::Indexer - Swish3 KinoSearch indexer

=head1 SYNOPSIS

 use SWISH::Prog::KSx::Indexer;
 my $indexer = SWISH::Prog::KSx::Indexer->new(
    config      => SWISH::Prog::Config->new(),
    invindex    => SWISH::Prog::KSx::InvIndex->new(),
    
 );

=head1 DESCRIPTION

SWISH::Prog::KSx::Indexer is a KinoSearch-based indexer
class for Swish3.

=head1 METHODS

Only new and overridden methods are documented here. See
the L<SWISH::Prog::Indexer> documentation.

=head2 init

Implements basic object set up. Called internally by new().
If you override this method, be sure to call SUPER::init(@_) or the
equivalent.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->{invindex} ||= SWISH::Prog::KSx::InvIndex->new;

    if ( $self->{invindex} && !blessed( $self->{invindex} ) ) {
        $self->{invindex}
            = SWISH::Prog::KSx::InvIndex->new( path => $self->{invindex} );
    }

    unless ( $self->invindex->isa('SWISH::Prog::KSx::InvIndex') ) {
        croak ref($self)
            . " requires SWISH::Prog::Xapian::InvIndex-derived object";
    }

    # config resolution order
    # 1. default config via SWISH::3->new

    # TODO can pass s3 in?
    $self->{s3} ||= SWISH::3->new(
        handler => sub {
            $self->_handler(@_);
        }
    );

    #SWISH::3->describe( $self->{s3} );

    # 2. any existing header file.
    my $swish_3_index
        = $self->invindex->path->file( SWISH_HEADER_FILE() )->stringify;

    if ( -r $swish_3_index ) {
        $self->{s3}->config->add($swish_3_index);
    }

    # 3. via 'config' param passed to this method
    if ( exists $self->{config} ) {

        # this utility method defined in base SWISH::Prog::Indexer class.
        $self->_verify_swish3_config();
    }

    # 4. always turn off tokenizer, preferring KS do it
    $self->{s3}->analyzer->set_tokenize(0);

    my $config = $self->{s3}->config;
    my $lang = $config->get_index->get( SWISH_INDEX_STEMMER_LANG() ) || 'en';
    $self->{_lang} = $lang;    # cache for finish()
    my $schema = KinoSearch::Schema->new();
    my $analyzer
        = KinoSearch::Analysis::PolyAnalyzer->new( language => $lang, );

    # build the KS fields, which are a merger of MetaNames+PropertyNames
    my %fields;

    my $built_in_props = SWISH_DOC_PROP_MAP();

    my $metanames = $config->get_metanames;
    for my $name ( @{ $metanames->keys } ) {
        my $mn    = $metanames->get($name);
        my $alias = $mn->alias_for;
        $fields{$name}->{is_meta}       = 1;
        $fields{$name}->{is_meta_alias} = $alias;
        $fields{$name}->{bias}          = $mn->bias;
        if ( exists $built_in_props->{$name} ) {
            $fields{$name}->{is_prop}  = 1;
            $fields{$name}->{sortable} = 1;
        }
    }

    my $properties = $config->get_properties;
    for my $name ( @{ $properties->keys } ) {
        if ( exists $built_in_props->{$name} ) {
            croak
                "$name is a built-in PropertyName and should not be defined in config";
        }
        my $property = $properties->get($name);
        my $alias    = $property->alias_for;
        $fields{$name}->{is_prop}       = 1;
        $fields{$name}->{is_prop_alias} = $alias;
        if ( $property->sort ) {
            $fields{$name}->{sortable} = 1;
        }
    }

    $self->{_fields} = \%fields;

    my $property_only = KinoSearch::Plan::StringType->new( sortable => 1, );
    my $store_no_sort = KinoSearch::Plan::StringType->new(
        sortable => 0,
        stored   => 1,
    );

    for my $name ( keys %fields ) {
        my $field = $fields{$name};
        my $key   = $name;

        # if a field is purely an alias, skip it.
        if (    defined $field->{is_meta_alias}
            and defined $field->{is_prop_alias} )
        {
            $field->{store_as}->{ $field->{is_meta_alias} } = 1;
            $field->{store_as}->{ $field->{is_prop_alias} } = 1;
            next;
        }

        if ( $field->{is_meta} and !$field->{is_prop} ) {
            if ( defined $field->{is_meta_alias} ) {
                $key = $field->{is_meta_alias};
                $field->{store_as}->{$key} = 1;
                next;
            }

            #warn "spec meta $name";
            $schema->spec_field(
                name => $name,
                type => KinoSearch::Plan::FullTextType->new(
                    analyzer => $analyzer,
                    stored   => 0,
                    boost    => $field->{bias} || 1.0,
                ),
            );
        }

        # this is the trickiest case, because the field
        # is both prop+meta and could be an alias for one
        # and a real for the other.
        # NOTE we have already eliminated (above) the case where
        # the field is an alias for both.
        elsif ( $field->{is_meta} and $field->{is_prop} ) {
            if ( defined $field->{is_meta_alias} ) {
                $key = $field->{is_meta_alias};
                $field->{store_as}->{$key} = 1;
            }
            elsif ( defined $field->{is_prop_alias} ) {
                $key = $field->{is_prop_alias};
                $field->{store_as}->{$key} = 1;
            }

            #warn "spec meta+prop $name";
            $schema->spec_field(
                name => $name,
                type => KinoSearch::Plan::FullTextType->new(
                    analyzer      => $analyzer,
                    highlightable => 1,
                    sortable      => $field->{sortable},
                    boost         => $field->{bias} || 1.0,
                ),
            );
        }
        elsif (!$field->{is_meta}
            and $field->{is_prop}
            and !$field->{sortable} )
        {
            if ( defined $field->{is_prop_alias} ) {
                $key = $field->{is_prop_alias};
                $field->{store_as}->{$key} = 1;
                next;
            }

            #warn "spec prop !sort $name";
            $schema->spec_field(
                name => $name,
                type => $store_no_sort
            );
        }
        elsif (!$field->{is_meta}
            and $field->{is_prop}
            and $field->{sortable} )
        {
            if ( defined $field->{is_prop_alias} ) {
                $key = $field->{is_prop_alias};
                $field->{store_as}->{$key} = 1;
                next;
            }

            #warn "spec prop sort $name";
            $schema->spec_field(
                name => $name,
                type => $property_only
            );
        }
        $field->{store_as}->{$name} = 1;
    }

    for my $name ( keys %$built_in_props ) {
        if ( exists $fields{$name} ) {
            my $field = $fields{$name};

            #carp "found $name in built-in props: " . dump($field);

            # in theory this should never happen.
            if ( !$field->{is_prop} ) {
                croak
                    "$name is a built-in PropertyName but not defined as a PropertyName in config";
            }
        }

        # default property
        else {
            $schema->spec_field( name => $name, type => $property_only );
        }
    }

    #dump( \%fields );

    # TODO can pass ks in?
    $self->{ks} ||= KinoSearch::Index::Indexer->new(
        schema => $schema,
        index  => $self->invindex->path,
        create => 1,
    );

    # cache our objects in case we later
    # need to create any fields on-the-fly
    $self->{__ks}->{analyzer} = $analyzer;
    $self->{__ks}->{schema}   = $schema;

    return $self;
}

sub _add_new_field {
    my ( $self, $metaname ) = @_;
    my $fields = $self->{_fields};
    my $alias  = $metaname->alias_for;
    my $name   = $metaname->name;
    if ( !exists $fields->{$name} ) {
        $fields->{$name} = {};
    }
    my $field = $fields->{$name};
    $field->{is_meta}           = 1;
    $field->{is_meta_alias}     = $alias;
    $field->{bias}              = $metaname->bias;
    $field->{store_as}->{$name} = 1;

    # a newly defined MetaName matching an already-defined PropertyName
    if ( $field->{is_prop} ) {
        $self->{__ks}->{schema}->spec_field(
            name => $name,
            type => KinoSearch::Plan::FullTextType->new(
                analyzer      => $self->{__ks}->{analyzer},
                highlightable => 1,
                sortable      => $field->{sortable},
                boost         => $field->{bias} || 1.0,
            ),
        );
    }

    # just a new MetaName
    else {

        $self->{__ks}->{schema}->spec_field(
            name => $name,
            type => KinoSearch::Plan::FullTextType->new(
                analyzer => $self->{__ks}->{analyzer},
                stored   => 0,
                boost    => $field->{bias} || 1.0,
            ),
        );

    }

    #warn "Added new field $name: " . dump( $field );

    return $field;
}

=head2 process( I<doc> )

Overrides base method to parse the I<doc> (a SWISH::Prog::Doc object)
with the SWISH::3 parse_buffer() method.

=cut

sub process {
    my $self = shift;
    my $doc  = $self->SUPER::process(@_);
    $self->{s3}->parse_buffer("$doc");
    return $doc;
}

my $doc_prop_map = SWISH_DOC_PROP_MAP();

sub _handler {
    my ( $self, $data ) = @_;
    my $config     = $data->config;
    my $conf_props = $config->get_properties;
    my $conf_metas = $config->get_metanames;

    # will hold all the parsed text, keyed by field name
    my %doc;

    # Swish built-in fields first
    for my $propname ( keys %$doc_prop_map ) {
        my $attr = $doc_prop_map->{$propname};
        $doc{$propname} = [ $data->doc->$attr ];
    }

    # fields parsed from document
    my $props = $data->properties;
    my $metas = $data->metanames;

    # field def cache
    my $fields = $self->{_fields};

    # may need to add newly-discovered fields from $metas
    # that were added via UndefinedMetaTags e.g.
    for my $mname ( keys %$metas ) {
        if ( !exists $fields->{$mname} ) {

            #warn "New field: $mname\n";
            $self->_add_new_field( $conf_metas->get($mname) );
        }
    }

    #dump $fields;
    #dump $props;
    #dump $metas;
    for my $fname ( sort keys %$fields ) {
        my $field = $self->{_fields}->{$fname};
        next if $field->{is_prop_alias};
        next if $field->{is_meta_alias};

        my @keys = keys %{ $field->{store_as} };

        for my $key (@keys) {

            # prefer properties over metanames because
            # properties have verbatim flag, which affects
            # the stored whitespace.

            if ( $field->{is_prop} and !exists $doc_prop_map->{$fname} ) {
                push( @{ $doc{$key} }, @{ $props->{$fname} } );
            }
            elsif ( $field->{is_meta} ) {
                push( @{ $doc{$key} }, @{ $metas->{$fname} } );
            }
            else {
                croak "field '$fname' is neither a PropertyName nor MetaName";
            }
        }
    }

    # serialize the doc with our tokenpos_bump char
    for my $k ( keys %doc ) {
        $doc{$k} = to_utf8( join( "\003", @{ $doc{$k} } ) );
    }

    $self->debug and carp dump \%doc;

    # make sure we delete any existing doc with same URI
    $self->{ks}->delete_by_term(
        field => 'swishdocpath',
        term  => $doc{swishdocpath}
    );

    $self->{ks}->add_doc( \%doc );
}

=head2 finish

Calls commit() on the internal KinoSearch::Indexer object,
writes the C<swish.xml> header file and calls the superclass finish()
method.

=cut

my @chars = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 );

sub finish {
    my $self = shift;

    return 0 if $self->{_is_finished};

    # get a lock on our header file till
    # this entire transaction is complete.
    # Note that we trust the KS locking feature
    # to have prevented any other process
    # from getting a lock on the invindex itself,
    # but we want to make sure nothing interrupts
    # us from writing our own header after calling ->commit().
    my $invindex  = $self->invindex->path;
    my $header    = $invindex->file( SWISH_HEADER_FILE() )->stringify;
    my $lock_file = Path::Class::File::Lockable->new($header);
    if ( $lock_file->locked ) {
        croak "Lock file found on $header -- cannot commit indexing changes";
    }
    $lock_file->lock;

    # commit our changes
    $self->{ks}->commit();

    # get total doc count
    my $polyreader
        = KinoSearch::Index::PolyReader->open( index => "$invindex", );
    my $doc_count = $polyreader->doc_count();

    # write header
    my $index = $self->{s3}->config->get_index;

    # poor man's uuid
    my $uuid = join( "", @chars[ map { rand @chars } ( 1 .. 24 ) ] );

    $index->set( SWISH_INDEX_NAME(),         "$invindex" );
    $index->set( SWISH_INDEX_FORMAT(),       'KSx' );
    $index->set( SWISH_INDEX_STEMMER_LANG(), $self->{_lang} );
    $index->set( "DocCount",                 $doc_count );
    $index->set( "UUID",                     $uuid );

    $self->{s3}->config->write($header);

    # transaction complete
    $lock_file->unlock;

    $self->debug and carp "wrote $header with $uuid";

    $self->{s3} = undef;    # invalidate this indexer

    $self->SUPER::finish(@_);

    $self->{_is_finished} = 1;

    return $doc_count;
}

=head2 get_ks

Returns the internal KinoSearch::Index::Indexer object.

=cut

sub get_ks {
    return shift->{ks};
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog-ksx at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog-KSx>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog::KSx


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-KSx>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog-KSx>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog-KSx>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog-KSx/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


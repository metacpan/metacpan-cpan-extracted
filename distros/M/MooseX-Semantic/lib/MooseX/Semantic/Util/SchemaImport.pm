package MooseX::Semantic::Util::SchemaImport;
use Data::Dumper;
use File::Path qw/ make_path /;
use File::Slurp;
use File::Temp qw/ tempfile tempdir /;
use Module::Load;
use Moose::Meta::Class;
use Moose;
use RDF::Query;
use RDF::Trine::Namespace qw(rdfs);
use RDF::Trine;
use Try::Tiny;

use MooseX::Semantic::Meta::Attribute::Trait;
use MooseX::Semantic::Types qw(TrineResource ArrayOfTrineResources UriStr TrineModel);

sub initialize_one_class_from_model {
    my ($factory_cls, %opts) = @_;
    my $model = $factory_cls->_get_model_for_opts( %opts );
    my $uri = $opts{uri};
    my $cls_to_load = $opts{type_map}->{$uri};
    $cls_to_load->meta->make_mutable;

    my @attributes;
    my $query_str = "
    PREFIX rdfs: <$rdfs>
    SELECT ?attr ?range WHERE { 
        ?attr rdfs:domain $uri . 
        ?attr rdfs:range ?range . 
        ?attr rdfs:label ?label .
        # ?attr ?prop ?obj . 
    }";
    my $query = RDF::Query->new( $query_str );
    my $iter = $query->execute($model);
    while (my $row = $iter->next) {
        # warn Dumper $row->{range};
        my $type;
        # TODO better type resolution, should at least calculate RDFS subtype entailments for range/domain
        if ($row->{range}->uri eq $rdfs->Literal->uri ) {
            # TODO or nothing TODO
            $type = 'Str';
        }
        else {
            # TODO map RDF 'maxOccurences' and 'minOccurences' to Moose
            # 'required' and ArrayRef or not ArrayRef
            if ($opts{type_map}->{ $row->{range} }){
                $type = sprintf 'ArrayRef[%s]', $opts{type_map}->{ $row->{range} };
            }
            else {
                $type = ArrayOfTrineResources;
            }
        }
        # TODO should be configurable probably
        my $attr_name = $row->{label} || $factory_cls->_get_short_name_from_url( $row->{attr} );
        # warn Dumper $attr_name;
        my $attribute = Moose::Meta::Attribute->new(
            $attr_name => (
                is => 'rw',
                isa => $type,
            )
        );
        MooseX::Semantic::Meta::Attribute::Trait->meta->apply($attribute);
        $attribute->uri( $row->{attr} );
        $cls_to_load->meta->add_attribute( $attribute );
        # warn sprintf 'Installed attribute for "%s" (%s)', $attr_name, $row->{attr} ;
    }
    $cls_to_load->meta->make_immutable;
}

sub initialize_classes_from_model {
    my ($factory_cls, %opts ) = @_;
    my $base_uri = $opts{base_uri};
    my %type_map = %{ $opts{type_map} || {} };


    # initialize classes - if they don't exist, create them
    while ( my ($uri, $cls_to_load) = each %type_map ) {
        try {
            load $cls_to_load;
        } catch {
            Moose::Meta::Class->initialize($cls_to_load)->superclasses("Moose::Object");
        };
        $opts{uri} = $uri;
        $factory_cls->initialize_one_class_from_model( %opts );
    }
}

# TODO
sub _get_short_name_from_url {
    my ($cls, $uri) = @_;
    $uri = UriStr->coerce( $uri );
    my ($last_segment) = ($uri =~ m!([^/#]+)$!);
    return $last_segment;
}

sub _get_model_for_opts {
    my ($factory_cls, %opts) = @_;
    my $model = $opts{model};
    my $parser = 'RDF::Trine::Parser';
    if ($opts{model_format}) {
        $parser = RDF::Trine::Parser->new( $opts{model_format} )
    }
    unless ($model) {
        $model = RDF::Trine::Model->temporary_model;
        if ($opts{model_uri}) {
            $parser->parse_url_into_model($opts{model_uri}, $model);
        }
        elsif ($opts{model_file}) {
            $parser->parse_file_into_model($opts{base_uri}, $opts{model_file}, $model);
        }
        elsif ($opts{model_string}) {
            $parser->parse_into_model( $opts{base_uri}, $opts{model_string}, $model);
        }
        else {
            die "Need model to import classes from!";
        }
    }
    return $model;
}

__PACKAGE__->meta->make_immutable;
1;

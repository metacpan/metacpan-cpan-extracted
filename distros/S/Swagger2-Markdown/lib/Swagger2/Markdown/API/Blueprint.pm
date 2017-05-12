package Swagger2::Markdown::API::Blueprint;

use strict;
use warnings;

use Template::Stash;

$Template::Stash::LIST_OPS->{ request_headers } = sub {
    my $list = shift;
    my $headers = [ grep { $_->{in} eq 'header' } @$list ];
    return @{ $headers } ? $headers : undef;
};

$Template::Stash::LIST_OPS->{ path_and_query_params } = sub {
    my $list = shift;
    my $params = [ grep { $_->{in} =~ /path|query/ } @$list ];
    return @{ $params } ? $params : undef;
};

$Template::Stash::LIST_OPS->{ query_params } = sub {
    my $list = shift;
    my $params = [ map { $_->{name} } grep { $_->{in} =~ /query/ } @$list ];
    return @{ $params } ? $params : undef;
};

$Template::Stash::LIST_OPS->{ none_path_and_query_params } = sub {
    my $list = shift;
    my $params = [ grep { $_->{in} !~ /path|query/ } @$list ];
    return @{ $params } ? $params : undef;
};

$Template::Stash::HASH_OPS->{ sort_methods_by_group } = sub {
    my $hash = shift;

    return sort {
        ( $hash->{$a}{"x-api-blueprint"}{group} // '' )
            cmp ( $hash->{$b}{"x-api-blueprint"}{group} // '' )
        || $a cmp $b
    } keys %{ $hash };
};

sub template {
    my ( $args ) = @_;

    my $template = _blueprint();
    return \$template;
}

1;

# vim: ft=tt2;ts=4:sw=4:et

sub _blueprint {

    return << 'EndOfBlueprint';
[%-
    USE Dumper;
-%]

[%- BLOCK resource_section -%]
    [%- IF group; prefix = '##'; ELSE; prefix = '#'; END -%]
	[%-
		IF query_params;
			qpath = path _ '{?' _ query_params.join(',') _ '}';
		ELSE;
			qpath = path;
		END;
	-%]
    [%- SWITCH o.resource_section -%]
        [%- CASE 'uri' -%]
[% prefix %] [% qpath _ "\n" -%]
        [%- CASE 'name_uri' -%]
[% prefix %] [% summary %] [[% e.basePath _ qpath -%]][% "\n" -%]
        [%- CASE 'method_uri' -%]
[% prefix %] [% method | upper %] [% e.basePath _ qpath -%][% "\n" -%]
        [%- CASE 'name_method_uri' -%]
[% prefix %] [% summary %] [[% method | upper %] [% e.basePath _ qpath -%]][% "\n" -%]
        [%- CASE -%]
[% IF method.defined %][% prefix %] [% method | upper %] [% e.basePath _ qpath %][% "\n" %][% END -%]
    [%- END -%]
[%- END -%]

[%- BLOCK action_section -%]
    [%- IF group; prefix = '###'; ELSE; prefix = '##'; END -%]
    [%- SWITCH o.action_section -%]
        [%- CASE 'method' -%]
[% prefix %] [% method | upper; "\n" -%]
        [%- CASE 'name_method' -%]
[% prefix %] [% summary %] [[% method | upper -%]][% "\n" -%]
        [%- CASE 'name_method_uri' -%]
[% prefix %] [% summary %] [[% method | upper %] [% e.basePath _ path %]][% "\n" -%]
        [%- CASE -%]
[% IF method.defined %][% prefix %] [% method | upper %] [% e.basePath _ path %][% "\n" %][% END -%]
    [%- END -%]
[%- END -%]

[%-
    BLOCK definition_type;
        IF o.data_structures;
            IF schema.type == 'array';
                'array';
                FOREACH item IN ref.items;
                    '[' _ item.value.split( "/" ).-1 _ ']';
                END;
            ELSIF schema.type == 'object';
                ref_key = '$ref';
                IF ref.$ref_key;
                    definition = ref.$ref_key;
                    definition.split( "/" ).-1;
                ELSE;
                    schema.type;
                END;
            ELSE;
                FOREACH t IN schema.type;
                    t.defined ? t : 'null';
                    LAST;
                END;
            END;
        ELSE;
            schema.type;
        END;
    END;
-%]

[%-
    BLOCK definition;
        example = "x-example";
        h = schema.properties;
        FOREACH property IN h.keys.sort;
            "$indent+ $property";
            IF h.$property.$example.defined;
                IF h.$property.type == 'boolean';
                    h.$property.$example ? ": true" : ": false";
                ELSE;
                    ": `${h.$property.$example}`";
                END;
            END;
            ref_key = '$ref';

            " (";
            INCLUDE definition_type
                schema = h.$property
                ref = h.$property;
            ")";

            IF h.$property.description;
                IF h.$property.description.match( '^\n' );
                    "\n\n$indent    ";
                    h.$property.description.remove( '^\n' );
                ELSE;
                    " - ${h.$property.description}";
                END;
            END;
            "\n";
            # recursion
            IF h.$property.type == 'object';
                INCLUDE definition
                    schema = h.$property
                    indent = "$indent    "
                ;
            END;
        END;
    END;
-%]

[%-
    BLOCK parameters;
        FOREACH param IN params;
            IF loop.first;
                "\n+ Parameters\n\n";
            END;
            example = 'x-example';
            "    + ${param.name}";
            IF param.$example.defined;
                IF param.type == 'boolean';
                    param.$example ? ": true" : ": false";
                ELSE;
                    ": `${param.$example}`";
                END;
            END;
            " (${param.type}";
            IF NOT param.required; ', optional'; END;
            ")";
            IF param.description.match( '^\n' );
                "\n\n        ";
                param.description.remove( '^\n' );
                "\n";
            ELSE;
                " - ${param.description}\n";
            END;
            IF param.default.defined;
                "        + Default: ";
                IF param.type == 'boolean';
                    param.default ? "true" : "false";
                ELSE;
                    "`${param.default}`";
                END;
                "\n";
            END;
        END;
    END;
-%]

[%- BLOCK response_section -%]
    [%- FOREACH response IN e.paths.$path.$method.responses.keys.sort -%]
        [%- "\n+ Response " _ response -%]
        [%- IF e.paths.$path.$method.produces -%]
            [%- %] ([% e.paths.$path.$method.produces.0 %])
        [%- ELSIF e.produces -%]
            [%- %] ([% e.produces.0 %])
        [%- END %]
        [%- IF
            o.attributes
            AND e.paths.$path.$method.responses.$response.schema
        -%]
            [%-
                "\n\n    + Attributes (";

                INCLUDE definition_type
                    schema = e.paths.$path.$method.responses.$response.schema
                    ref = c.paths.$path.$method.responses.$response.schema
                ;

                ")\n";

                IF e.paths.$path.$method.responses.$response.schema.type == 'object';
                    IF o.data_structures;
                        INCLUDE definition
                            schema = c.paths.$path.$method.responses.$response.schema
                            indent = "        ";
                        ;
                        "\n";
                    ELSE;
                        INCLUDE definition
                            schema = e.paths.$path.$method.responses.$response.schema
                            indent = "        ";
                        ;
                        "\n";
                    END;
                END;
            -%]
        [%- END -%]
        [%- IF e.paths.$path.$method.responses.$response.headers -%]
            [%- "\n\n    + Headers\n" -%]
            [%- FOREACH header IN e.paths.$path.$method.responses.$response.headers.keys.sort -%]
                [%- "\n            " _ header %]: [% e.paths.$path.$method.responses.$response.headers.$header.type; -%]
            [%- END -%]
            [%- body = "\n\n    + Body" -%]
            [%- body_padding = '        ' -%]
        [%- ELSIF o.attributes -%]
            [%- body = "    + Body" -%]
            [%- body_padding = '        ' -%]
        [%- ELSE -%]
            [%- body = '' -%]
            [%- body_padding = '    ' -%]
        [%- END -%]
        [%- IF e.paths.$path.$method.responses.$response.schema.example -%]
            [%-
                body;
                "\n\n";
                # indent correctly
                e.paths.$path.$method.responses.$response.schema.example.replace(
                    "(?m)^([ ])*",body_padding _ '    $1'
                );
                "\n\n"
            -%]
        [%- ELSE -%]
            [%- "\n" -%]
        [%- END -%]
    [%- END -%]
[%- END -%]

[%- BLOCK request_section -%]
    [%- IF e.paths.$path.$method.parameters.none_path_and_query_params -%]
        [%- "\n+ Request " -%]
        [%- IF e.paths.$path.$method.consumes -%]
            [%- %]([% e.paths.$path.$method.consumes.0 %])
            [%- IF e.paths.$path.$method.parameters.request_headers -%]
                [%- "\n\n    + Headers" -%]
                [%- FOREACH header IN e.paths.$path.$method.parameters.request_headers -%]
                    [%- "\n\n" %]            [% header.name %]: [% header.type %][% "\n" -%]
                [%- END -%]
            [%- END -%]
        [%- END %]
        [%- FOREACH param IN e.paths.$path.$method.parameters -%]
            [%- IF param.schema -%]
                [%- IF param.schema.example -%]
                    [%- "\n\n        " -%]
                    [%- param.schema.example; "\n" -%]
                    [%- LAST -%]
                [%- ELSE -%]
                    [%- "\n" -%]
                [%- END -%]
            [%- END -%]
        [%- END -%]
    [%- END -%]
[%- END -%]

[%- BLOCK method_section -%]
    [%- FOREACH method IN e.paths.$path.sort_methods_by_group -%]
        [%- IF method == api_blueprint; NEXT; END -%]
        [%- summary = e.paths.$path.$method.summary -%]
        [%- IF o.simple -%]
            [%- PROCESS resource_section
				query_params = e.paths.$path.$method.parameters.query_params
			-%]
        [%- ELSE -%]
            [%- PROCESS action_section -%]
        [%- END -%]
        [%- IF e.paths.$path.$method.description.defined -%]
            [%- e.paths.$path.$method.description -%]
        [%- END -%]
        [%- PROCESS parameters
            params = e.paths.$path.$method.parameters.path_and_query_params
        -%]
        [%- PROCESS request_section -%]
        [%- PROCESS response_section -%]
    [%- END -%]
[%- END -%]
FORMAT: 1A

# [% e.info.title %]
[% e.info.description -%]

[% FOREACH path IN e.paths.keys.sort -%]
    [%- api_blueprint = 'x-api-blueprint' -%]
    [%- IF e.paths.$path.$api_blueprint.defined -%]
        [%- summary = e.paths.$path.$api_blueprint.summary -%]
        [%- group = e.paths.$path.$api_blueprint.group -%]
        [%- IF group -%]
            [%- "\n" IF NOT loop.first -%]
            [%- IF group != e.paths.${ loop.prev }.$api_blueprint.group -%]
                [%- "# Group " _ group _ "\n" -%]
                [%- e.paths.$path.$api_blueprint.description -%]
                [%- IF e.paths.$path.keys.size == 1; NEXT; ELSE; "\n"; END -%]
            [%- END -%]
        [%- END -%]
    [%- END -%]
    [%- PROCESS resource_section 
		query_params = e.paths.$path.get.parameters.query_params
	-%]
    [%- IF e.paths.$path.$api_blueprint.defined -%]
        [%- IF group -%]
            [%- e.paths.$path.$api_blueprint.group_description _ "\n" -%]
        [%- ELSE -%]
            [%- e.paths.$path.$api_blueprint.description _ "\n" -%]
        [%- END -%]
    [%- END -%]
    [%- PROCESS method_section -%]
[%- END -%]
[%- IF o.data_structures -%]
    [%- "# Data Structures\n\n" -%]
    [%- FOREACH definition IN c.definitions.keys.sort -%]
        [%-
            "## " _ definition;
            " (";
            INCLUDE definition_type
                schema = c.definitions.$definition
            ;
            ")";
            "\n"
        -%]
        [%- 
            INCLUDE definition
                schema = c.definitions.$definition
                indent = "";
            ;
            "\n";
        -%]
    [%- END -%]
[%- END -%]
[%-# Dumper.dump( o ) -%]
[%-# Dumper.dump( e ) -%]
[%-# Dumper.dump( c ) -%]
[%-# Dumper.dump( d ) -%]
EndOfBlueprint

}

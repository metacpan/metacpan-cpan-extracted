-- Wraf DBI Interface V01
-- $Id: rdf.sql,v 1.6 2000/12/04 09:43:46 aigan Exp $


DROP SEQUENCE node_id_seq;
DROP SEQUENCE uri_id_seq;
DROP TABLE node;
DROP TABLE type;
DROP TABLE distr;
DROP TABLE uri;

CREATE SEQUENCE node_id_seq;
CREATE SEQUENCE uri_id_seq;

CREATE TABLE uri
(

    -- This URI could be an alias for the 'real' URI.  If refid and
    -- refpart is defined, this URI represents an implicit resource
    -- embedded in the node.

    string               text PRIMARY KEY,
    id			 int4 NOT NULL,
    refid		 int4,
    refpart		 text,
    hasalias		 bool NOT NULL, -- look for 'aliasfor'
    UNIQUE ( id )
);

CREATE TABLE node
(
    -- All embeded statements comes from the same model and is
    -- considered to be facts.  Data from diffrent models will be
    -- stored as additional node entries for the same uri.

    id			 int4 PRIMARY KEY,
    uri			 int4 NOT NULL, 
    iscontainer		 bool NOT NULL,  -- look for member nodes
    isprefix		 bool NOT NULL,

    label		 text,
    -- The label can only be a system (C) label. Other labels in
    -- diffrent languages has to be connected to this uri by one or
    -- more statements

    aliasfor		 int4, -- uri ref; set target 'hasalias'

    model		 int4 NOT NULL, -- uri
    -- Use arcs for stating the namespace of a model.  The default NS
    -- is the model uri.


    -- arc -- (pred)
    --
    -- The distr says that each uri represented by subj has this
    -- statement. If the subj is a model: all statements has the
    -- arc. If is's a container: all member has the arc.  If it's a
    -- prefix: all contained URIs has the arc.  If the subj is more
    -- than one of those things, distribute over all. But it shouldn't
    -- happen.

    -- Model is always used, as the status for implicit properties.
    -- It will be used for literals, in the sense that there is an
    -- implicit 'value' statement for the literal uri.  Fact is always
    -- true unless the node is an arc that's only reified.

    pred		 int4, -- uri  'pred' defines arc exsistence
    distr		 bool, -- distr over subj container or prefix
    subj		 int4, -- uri
    obj			 int4, -- uri
    fact		 bool,


   -- member
   --
   -- The node is member of a container.
   -- With member defined, the pred, distr and obj will be undefined
   -- and the subj is the containter.  The arc is implicit.

    member               int4, -- uri

    -- literal -- (isliteral)    
    --
    -- If the blob is not null, the value should be a text version of
    -- the content. Maby an abstract. Something searchable. Not more
    -- than say 6 KB.  The value vill be the 'abstract' property of
    -- the literal. The value is the blob content. The size property
    -- will be defined and specify the size of the blob.

    -- The node type will specify the value encoding. The value can
    -- have other metadata, as defined for the specific encoding
    -- type.  The value may also be absent, as undefined for both
    -- value and blob.  In this case, there will probably be a
    -- property of the literal, pointing to a representation of the
    -- value, as a part, view, encoding or other aspect of the
    -- represented content.

    -- The maximum size of a record is 8192 bytes, not counitn the content of a blob
    -- http://paranormal.se/doc/postgresql-6.5.1/postgres/largeobjects17433.htm
    -- VACUUM ANALYZE must be run to collect them periodically
    -- $sth->{pg_oid_status} after $sth->execute()

    isliteral            bool NOT NULL,
    lang		 int4, -- uri
    value		 text,
    blob		 oid,


    UNIQUE ( uri, model )
);
CREATE INDEX node_alias_idx ON node ( aliasfor );
CREATE INDEX node_pred_idx ON node ( pred );
CREATE INDEX node_subj_idx ON node ( subj );
CREATE INDEX node_obj_idx ON node ( obj );
CREATE INDEX node_model_idx ON node ( model );
CREATE INDEX node_value_idx ON node ( value );
CREATE INDEX node_predsubj ON node ( pred, subj );
CREATE INDEX node_predobj ON node ( pred, obj );


CREATE TABLE type
(

    -- This is a specialiced arc stating the type of the node.  The
    -- internal cache will complement the types stated here with the
    -- indirect types concluded from the class heiarcy.  The types
    -- indicated by the node booleans is also represented here unless
    -- they are implicit (as often is the case for literals).

    -- This table complements the node table.  A search for all
    -- properties of a resource will have to search both tables.  Type
    -- statements should go here instead of in the node table.  This
    -- is intended as an optimisation, since the type of an resource
    -- is almost always requested.  Much more so than any other
    -- atributes of the resource.  This should also save a lot of
    -- space.

    id			 int4 UNIQUE, -- only used if URI known
    node		 int4 NOT NULL,
    type		 int4 NOT NULL,
    model		 int4 NOT NULL,
    fact		 bool,       -- deprecated
    PRIMARY KEY ( node, type, model )
);
CREATE INDEX type_node_idx ON type ( node );
CREATE INDEX type_model_idx ON type ( model );


CREATE TABLE distr
(

    -- This table is a redundant lookup table for getting the extra
    -- distributed arcs for a specific subject.  Every added resource
    -- should check if it is the target for a distributed arc based on
    -- model, container or prefix.  Removed resources vill also be
    -- removed from this table. Every added distributed arc will
    -- initiate a search for resources that will be added to this
    -- table.

    subj		 int4, -- ordinary resource
    arc			 int4, -- distributed arc
    PRIMARY KEY (subj, arc)
);
CREATE INDEX distr_subj_idx ON distr ( subj );


grant all on node_id_seq, uri_id_seq, uri, node, type, distr to public;

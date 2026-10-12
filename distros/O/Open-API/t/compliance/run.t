#!perl
use 5.008003;   # this distribution's floor: no defined-or below 5.10
use strict;
use warnings;
use Test::More;
use File::Raw::JSON qw(file_json_decode file_json_encode);
use File::Basename qw(dirname);
use Open::API;
use Open::API::Client;   # _request_url: the encode half of every style

# Four descriptions in the vendored if-then-else.json use U+2192 (->), so the
# test names built from them are wide and TAP's handles are byte handles by
# default: "Wide character in print". The vendored files are an oracle and are
# not edited, so the encoding is declared here instead. `:utf8` rather than
# `:encoding(UTF-8)` because it needs no Encode, which matters at this
# distribution's 5.8.3 floor.
{
    my $b = Test::More->builder;
    binmode($_, ':utf8')
        for $b->output, $b->failure_output, $b->todo_output;
}

# A compliance matrix for Swagger 2.0 and OpenAPI 3.0 and 3.1, walked object by
# object.
#
# There is no official executable conformance suite for OpenAPI - unlike JSON
# Schema or XML, nothing is published that can be fetched and run - so this
# catalogue is authored from the specification rather than vendored. Every
# case names the requirement it is testing so a reader can check the claim
# against the document instead of trusting this file.
#
# The contract is the one t/xmlconf/run.t uses in File::Raw::XML:
#
#   * a case that meets the requirement passes;
#   * a case that does not, and is NOT in expected-fail.txt, FAILS - a gap
#     must never be silent;
#   * a case that does not, and IS listed, passes with its reason echoed;
#   * a case that is listed and now MEETS the requirement is a FAILURE too,
#     naming itself, so the list only ever shrinks.
#
# That last rule is what stops the list becoming a place gaps go to be
# forgotten. expected-fail.txt carries one id per line with the reason.
#
# `run` returns true when the implementation meets the requirement. It must
# not die: a case that throws is reported as a failure with the exception,
# because an unexpected croak is itself non-compliance.

my $DIR  = dirname(__FILE__);
my $FAIL = "$DIR/expected-fail.txt";

# ---- helpers ----------------------------------------------------------------

sub doc {
    my (%o) = @_;
    my %d = (
        openapi => delete $o{openapi} || '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => delete $o{paths} || {},
    );
    $d{$_} = $o{$_} for keys %o;
    return \%d;
}

# one GET operation at /t, with whatever the case wants layered on
sub op_doc {
    my (%o) = @_;
    my $method = delete $o{method} || 'get';
    my $path   = delete $o{path}   || '/t';
    # document-level keys must not end up inside the operation object, or a
    # case testing `components` or a 3.0 `openapi` fails for a reason that has
    # nothing to do with the requirement it names
    my %top;
    for my $k (qw(openapi components servers security tags webhooks
                  jsonSchemaDialect externalDocs)) {
        $top{$k} = delete $o{$k} if exists $o{$k};
    }
    my %op = (operationId => 'op', responses => { 200 => { description => 'ok' } }, %o);
    return doc(paths => { $path => { $method => \%op } }, %top);
}

# OA_COMPLIANCE_WHY=1 reports the croak behind every refused document, with the
# case id: a croaks()-shaped case passes whatever the REASON, and a document
# refused for the wrong reason reads exactly like compliance.
our $CURRENT_CASE = '';
sub api   { my ($s, %o) = @_;
            my $a = eval { Open::API->new(spec => $s, %o) };
            my $e = $@;
            if (!$a && $ENV{OA_COMPLIANCE_WHY}) {
                my $m = $e; $m =~ s/\s+at \S+ line \d+\.?\s*$//s; $m =~ s/\s+/ /g;
                diag("why $CURRENT_CASE: $m");
            }
            return ($a, $e) }
sub loads { my ($a) = api(shift); return $a ? 1 : 0 }
sub croaks{ my ($a, $e) = api(shift); return $a ? 0 : 1 }

sub req {
    my ($a, %args) = @_;
    my $id = delete $args{op} || 'op';
    return $a->validate_request($id => \%args);
}

my $JSON = { 'content-type' => 'application/json' };

sub json_body_op {
    my ($schema, %o) = @_;
    return op_doc(
        method      => 'post',
        requestBody => { required => 1,
                         content  => { 'application/json' => { schema => $schema } } },
        %o,
    );
}

# ---- the official JSON Schema Test Suite, run through this pipeline ----------
#
# t/compliance/jsonschema/ holds four files copied verbatim from the
# JSON-Schema-Test-Suite (draft2020-12). See the README there for provenance,
# the licence, and why these four.
#
# The point is NOT to test JSON::Schema::Fast, which is what validates them.
# It is that Open::API REWRITES schemas before anything compiles - components
# refs to $defs, readOnly/writeOnly projected per direction, discriminator
# expanded and appended to allOf, a whole 3.0 document converted - and every one
# of those rewrites touches $ref or a composition keyword. These vectors travel
# the entire pipeline and say whether the schema still means what it meant.

my $JSS_DIR = "$DIR/jsonschema";
my $JSS_SKIPPED = 0;
my $JSS_REF_SKIPPED = 0;
my $JSS_30_SKIPPED = 0;
my $JSS_30_REFSIB  = 0;
my $JSS_20_SKIPPED = 0;   # not expressible as a 2.0 (draft-04 subset) schema
my $JSS_20_REFSIB  = 0;   # $ref with assertion siblings: draft-04 ignores them

# Is this schema expressible in 2.0's Schema Object? Structural, not a regex:
# 2.0 lists its fields, and draft-04 has no boolean schemas, no type arrays,
# boolean (not numeric) exclusive bounds, and a non-empty `required`.
sub d4_expressible {
    my ($s) = @_;
    return 0 unless ref $s eq 'HASH';
    for my $k (qw(oneOf anyOf not patternProperties dependencies additionalItems)) {
        return 0 if exists $s->{$k};
    }
    return 0 if ref $s->{type} eq 'ARRAY';
    for my $k (qw(exclusiveMinimum exclusiveMaximum)) {
        next unless exists $s->{$k};
        return 0 unless oa_bool_like($s->{$k});
    }
    return 0 if ref $s->{required} eq 'ARRAY' && !@{ $s->{required} };
    if (exists $s->{properties}) {
        return 0 unless ref $s->{properties} eq 'HASH';
        for (values %{ $s->{properties} }) { return 0 unless d4_expressible($_) }
    }
    if (exists $s->{additionalProperties} && ref $s->{additionalProperties}) {
        return 0 unless d4_expressible($s->{additionalProperties});
    }
    if (exists $s->{items}) {
        my $it = $s->{items};
        if (ref $it eq 'ARRAY') { for (@$it) { return 0 unless d4_expressible($_) } }
        else                    { return 0 unless d4_expressible($it) }
    }
    if (exists $s->{allOf}) {
        return 0 unless ref $s->{allOf} eq 'ARRAY';
        for (@{ $s->{allOf} }) { return 0 unless d4_expressible($_) }
    }
    return 1;
}

# a decoded JSON boolean (File::Raw::JSON's blessed Boolean), never a number
sub oa_bool_like {
    my ($v) = @_;
    return 0 unless ref $v;
    return 1 if ref $v eq 'SCALAR';
    return (ref($v) =~ /Bool/i) ? 1 : 0;
}

# 2020-12 keywords a 3.0 document cannot carry. A schema using one is not
# expressible in that dialect, so the 3.0 twin below skips it.
my $JSS_2020_ONLY = qr/"(?:\$defs|prefixItems|const|contentEncoding
                        |contentMediaType|dependentSchemas|dependentRequired
                        |if|then|else|unevaluatedItems
                        |unevaluatedProperties)"/x;

# 3.0 DELIBERATELY ignores assertions sitting beside a $ref, and this build
# strips them for that reason. The suite is 2020-12, where they apply, so the
# two dialects disagree on purpose and the twin cannot ask them to match.
# Currently matches nothing - every such group in the vendored files also
# carries $defs, so the rule above catches it first - but it encodes the real
# difference, and the vendored files can be updated from upstream.
my $JSS_REF_SIBLING = qr/"(?:maxItems|minItems|maxLength|minLength|maximum
                           |minimum|pattern|required|enum)"/x;

# Every vendored file, and the rewrite in this distribution it speaks to. The
# list is the argument for each file being here: a vendored suite that is not
# exercising something this code does to schemas is just re-testing JSF.
my @JSS_FILES = (
    [ 'allOf'            => 'discriminator is expanded and APPENDED to allOf' ],
    [ 'anyOf'            => '3.0 nullable beside a $ref becomes anyOf' ],
    [ 'oneOf'            => 'discriminator selects among oneOf branches' ],
    [ 'ref'              => 'component refs are rewritten into $defs' ],
    [ 'defs'             => 'components.schemas IS the compiled $defs' ],
    [ 'if-then-else'     => 'discriminator expands INTO if/then' ],
    [ 'required'         => 'readOnly/writeOnly projection rewrites required' ],
    [ 'properties'       => 'discriminator injects a guard property' ],
    [ 'type'             => '3.0 nullable becomes a type union' ],
    [ 'enum'             => '3.0 nullable adds a null enum member' ],
    [ 'prefixItems'      => '3.0 tuple items becomes prefixItems' ],
    [ 'items'            => '...and the trailing items schema with it' ],
    [ 'exclusiveMinimum' => '3.0 boolean bounds become numeric' ],
    [ 'exclusiveMaximum' => '3.0 boolean bounds become numeric' ],
    [ 'content'          => '3.0 format byte/binary becomes contentEncoding' ],
);

sub jss_slug {
    my ($s) = @_;
    $s = lc $s;
    $s =~ s/[^a-z0-9]+/-/g;
    $s =~ s/^-|-$//g;
    $s = substr($s, 0, 44) if length $s > 44;
    return $s;
}

sub jsonschema_cases {
    my @out;
    return @out unless -d $JSS_DIR;
    for my $fe (@JSS_FILES) {
        my ($file, $why) = @$fe;
        my $path = "$JSS_DIR/$file.json";
        next unless -f $path;
        my $txt = do {
            open my $fh, '<:raw', $path or next;
            local $/; <$fh>;
        };
        my $groups = eval { file_json_decode($txt) };
        next unless ref $groups eq 'ARRAY';
        for my $g (@$groups) {
            my $schema = $g->{schema};
            my $js = eval { file_json_encode($schema) };
            next unless defined $js;
            # THE SKIP RULE, stated rather than discovered: these describe
            # schema identity and resolution scope, which an OpenAPI document
            # has no way to express - it has one namespace, components.schemas.
            if ($js =~ /"\$(?:id|anchor|dynamicRef|dynamicAnchor|recursiveRef)"/
                || $js =~ m{"\$ref"\s*:\s*"(?!\#)}
                || !ref $schema) {
                $JSS_SKIPPED++;
                next;
            }
            # A schema containing a ROOT-ANCHORED pointer into itself
            # (`#/$defs/x`, `#/properties/foo`, `#/prefixItems/0`) is run
            # inline but not as a component. In the suite the schema IS the
            # resource root, so those resolve; as a component it sits at
            # #/components/schemas/S and the same pointer means the DOCUMENT
            # root, where this build keeps components.schemas. Refusing that is
            # correct, not a bug - the properly spelled
            # `#/components/schemas/S/$defs/x` binds, and was checked by hand -
            # so the group is simply not expressible in this placement. It is
            # the suite's own "naive replacement of $ref is not correct".
            my $self_ptr = $js =~ m{"\$ref"\s*:\s*"\#/} ? 1 : 0;
            my $gslug = jss_slug($g->{description});
            for my $t (@{ $g->{tests} || [] }) {
                my $want = $t->{valid} ? 1 : 0;
                my $body = eval { file_json_encode($t->{data}) };
                next unless defined $body;
                my $tslug = jss_slug($t->{description});
                push @out, {
                    id => "jsonschema/$file/$gslug/$tslug",
                    section => "JSON Schema 2020-12 Test Suite (vendored): $why",
                    requirement => "$g->{description}: $t->{description} is "
                                 . ($want ? 'valid' : 'invalid'),
                    run => sub {
                        my ($a) = api(json_body_op($schema));
                        return 0 unless $a;
                        my ($ok) = req($a, header => $JSON, body => $body);
                        return ((!!$ok) == (!!$want)) ? 1 : 0;
                    },
                };
                # ...and again with the schema behind a component $ref, which
                # is the placement that actually exercises the $defs rewrite.
                # Inline, the schema is handed to the validator untouched.
                next if $self_ptr;
                push @out, {
                    id => "jsonschemaref/$file/$gslug/$tslug",
                    section => "JSON Schema 2020-12 Test Suite (vendored), "
                             . "behind a component \$ref: $why",
                    requirement => "$g->{description}: $t->{description} is "
                                 . ($want ? 'valid' : 'invalid')
                                 . ', with the schema reached through components',
                    run => sub {
                        my ($a) = api(doc(
                            components => { schemas => { S => $schema } },
                            paths => { '/t' => { post => {
                                operationId => 'op',
                                requestBody => { required => \1, content => {
                                    'application/json' => { schema =>
                                        { '$ref' => '#/components/schemas/S' } } } },
                                responses => { 200 => { description => 'ok' } } } } }));
                        return 0 unless $a;
                        my ($ok) = req($a, header => $JSON, body => $body);
                        return ((!!$ok) == (!!$want)) ? 1 : 0;
                    },
                };
            }
            $JSS_REF_SKIPPED++ if $self_ptr;

            # ---- the 2.0 placements ---------------------------------------
            #
            # The same schema as a 2.0 body parameter against a 3.1
            # requestBody (jsonschema20), and behind `#/definitions/S`
            # (jsonschema20ref), which is the placement that exercises the
            # 2.0 $ref rewrite as jsonschemaref exercises the $defs one. A
            # 2.0 Schema Object is a draft-04 SUBSET, so beyond the 2020-12
            # skip the group must be expressible in draft-04 as 2.0 lists it:
            # no oneOf/anyOf/not/patternProperties/dependencies/
            # additionalItems, no type array (2.0 refuses it, which is its
            # own authored case), no numeric exclusive bound, no empty
            # required, no boolean where draft-04 has only a schema. The twin
            # proves the pre-pass and the 3.0 pass preserve a schema's
            # MEANING; it cannot see a 2.0 SPELLING, which the authored
            # swagger/schema/* cases are for.
            if ($js =~ $JSS_2020_ONLY || !d4_expressible($schema)) {
                $JSS_20_SKIPPED++;
            }
            elsif ($js =~ /"\$ref"/ && $js =~ $JSS_REF_SIBLING) {
                $JSS_20_REFSIB++;
            }
            else {
                for my $t (@{ $g->{tests} || [] }) {
                    my $body = eval { file_json_encode($t->{data}) };
                    next unless defined $body;
                    my $tslug = jss_slug($t->{description});
                    push @out, {
                        id => "jsonschema20/$file/$gslug/$tslug",
                        section => "JSON Schema 2020-12 Test Suite (vendored), "
                                 . "2.0 and 3.1 twin: $why",
                        requirement => "$g->{description}: $t->{description} gets "
                                     . 'the same verdict as a 2.0 body parameter and a 3.1 requestBody',
                        run => sub {
                            my ($a31) = api(json_body_op($schema));
                            my ($a20) = api(body20($schema));
                            return 0 unless $a31 && $a20;
                            my ($o31) = req($a31, header => $JSON, body => $body);
                            my ($o20) = req($a20, header => $JSON, body => $body);
                            return ((!!$o31) == (!!$o20)) ? 1 : 0;
                        },
                    };
                    next if $self_ptr;
                    push @out, {
                        id => "jsonschema20ref/$file/$gslug/$tslug",
                        section => "JSON Schema 2020-12 Test Suite (vendored), "
                                 . "2.0 behind #/definitions/: $why",
                        requirement => "$g->{description}: $t->{description} gets "
                                     . 'the same verdict reached through definitions',
                        run => sub {
                            my ($a31) = api(json_body_op($schema));
                            my ($a20) = api(doc20(
                                definitions => { S => $schema },
                                consumes    => [ 'application/json' ],
                                paths => { '/t' => { post => {
                                    operationId => 'op',
                                    parameters  => [ { name => 'body', in => 'body', required => \1,
                                                       schema => { '$ref' => '#/definitions/S' } } ],
                                    responses   => { 200 => { description => 'ok' } } } } }));
                            return 0 unless $a31 && $a20;
                            my ($o31) = req($a31, header => $JSON, body => $body);
                            my ($o20) = req($a20, header => $JSON, body => $body);
                            return ((!!$o31) == (!!$o20)) ? 1 : 0;
                        },
                    };
                }
            }

            # ---- the 3.0 twin -------------------------------------------
            #
            # The files admitted above on 3.0-conversion grounds (type, enum,
            # items, the exclusive bounds, content) are 2020-12 vectors: the
            # suite cannot supply a 3.0 SPELLING, so it cannot check the
            # conversion by verdict. What it CAN check is that converting does
            # not change what a schema means. The same schema is put in a 3.0
            # document and a 3.1 one and the two are required to AGREE - in a
            # 3.0 document the converter walks every schema, so a rewrite that
            # corrupts one shows up as the twins parting company.
            if ($js =~ $JSS_2020_ONLY)   { $JSS_30_SKIPPED++; next }
            if ($js =~ /"\$ref"/ && $js =~ $JSS_REF_SIBLING) {
                $JSS_30_REFSIB++; next;
            }
            for my $t (@{ $g->{tests} || [] }) {
                my $body = eval { file_json_encode($t->{data}) };
                next unless defined $body;
                push @out, {
                    id => "jsonschema30/$file/$gslug/" . jss_slug($t->{description}),
                    section => "JSON Schema 2020-12 Test Suite (vendored), "
                             . "3.0 and 3.1 twin: $why",
                    requirement => "$g->{description}: $t->{description} gets "
                                 . 'the same verdict in 3.0 and in 3.1',
                    run => sub {
                        my $mk = sub {
                            my ($ver) = @_;
                            my ($x) = api(json_body_op($schema, openapi => $ver));
                            return $x;
                        };
                        my $a31 = $mk->('3.1.0');
                        my $a30 = $mk->('3.0.3');
                        return 0 unless $a31 && $a30;
                        my ($o31) = req($a31, header => $JSON, body => $body);
                        my ($o30) = req($a30, header => $JSON, body => $body);
                        return ((!!$o31) == (!!$o30)) ? 1 : 0;
                    },
                };
            }
        }
    }
    return @out;
}

# ---- request-body helpers ----------------------------------------------------

my $BODY_SCHEMA = { type => 'object', required => ['a'],
                    properties => { a => { type => 'string' },
                                    b => { type => 'string' } } };

# ($body, $content_type) the client would send for an operation declaring
# exactly $ctype
sub body_for {
    my ($ctype) = @_;
    my ($a) = api(op_doc(method => 'post', requestBody => { required => \1,
        content => { $ctype => { schema => $BODY_SCHEMA } } }));
    return (undef, undef) unless $a;
    my $c = eval { Open::API::Client->new(api => $a, base_url => 'http://h.test') };
    return (undef, undef) unless $c;
    my ($b, $ct) = eval { $c->_request_body('op', { body => { a => 'x', b => 'y' } }) };
    return ($b, $ct, $a);
}

# what the client writes, the server must accept and decode to the same values
sub body_round_trip {
    my ($ctype) = @_;
    my ($b, $ct, $a) = body_for($ctype);
    return 0 unless defined $b && defined $ct && $a;
    my ($ok, $res) = $a->validate_request(op =>
        { header => { 'content-type' => $ct }, body => $b });
    return 0 unless $ok;
    return eq_deeply_ish($res->{body}, { a => 'x', b => 'y' });
}

# ---- the specification's own Style Examples table ---------------------------
#
# Everything else in this file is authored from the prose. This block is not:
# it is the "Style Examples" table transcribed from the specification, which is
# the closest thing OpenAPI has to published test vectors. The parameter is
# named `color` there and the name is load-bearing for `form` and `deepObject`,
# where it appears in the serialization, so it is kept.
#
#   string -> "blue"
#   array  -> ["blue","black","brown"]
#   object -> { "R": 100, "G": 200, "B": 150 }
#
# ONE CELL IS NOT TRANSCRIBED, deliberately. The table gives label/explode=false
# as `.blue.black.brown` and `.R.100.G.200.B.150` - dot-separated, identical to
# its own explode=true row. That contradicts the normative definition beside it:
# the style table defines label as "Label style parameters defined by RFC6570
# section 3.2.5", and RFC 6570 section 3.2.5 is unambiguous -
#
#     {.list}   .red,green,blue
#     {.list*}  .red.green.blue
#
# - non-exploded label separates with COMMAS, and only the exploded form uses
# dots. An example table cannot overrule the normative reference it cites, so
# those two cells are encoded per RFC 6570 and flagged here. Transcribing them
# verbatim would have asserted that `.blue,black,brown` is wrong, which would
# have broken t/37-style.t and put this library at odds with every RFC 6570
# implementation. The grammar wins.

my $SE_STR = { type => 'string' };
my $SE_ARR = { type => 'array', items => { type => 'string' } };
my $SE_OBJ = { type => 'object', properties => { R => { type => 'integer' },
                                                 G => { type => 'integer' },
                                                 B => { type => 'integer' } } };
my %SE_SCHEMA = (empty => $SE_STR, string => $SE_STR,
                 array => $SE_ARR,  object => $SE_OBJ);
my %SE_WANT   = (empty  => '',
                 string => 'blue',
                 array  => [ 'blue', 'black', 'brown' ],
                 object => { R => 100, G => 200, B => 150 });

# style, explode, in, { kind => the serialized form }. A kind the table marks
# n/a is simply absent.
my @SE_TABLE = (
 [ 'matrix', 0, 'path',
   { empty  => ';color',
     string => ';color=blue',
     array  => ';color=blue,black,brown',
     object => ';color=R,100,G,200,B,150' } ],
 [ 'matrix', 1, 'path',
   { empty  => ';color',
     string => ';color=blue',
     array  => ';color=blue;color=black;color=brown',
     object => ';R=100;G=200;B=150' } ],
 [ 'label', 0, 'path',
   { empty  => '.',
     string => '.blue',
     array  => '.blue,black,brown',            # RFC 6570, not the table
     object => '.R,100,G,200,B,150' } ],       # RFC 6570, not the table
 [ 'label', 1, 'path',
   { empty  => '.',
     string => '.blue',
     array  => '.blue.black.brown',
     object => '.R=100.G=200.B=150' } ],
 [ 'form', 0, 'query',
   { empty  => 'color=',
     string => 'color=blue',
     array  => 'color=blue,black,brown',
     object => 'color=R,100,G,200,B,150' } ],
 [ 'form', 1, 'query',
   { empty  => 'color=',
     string => 'color=blue',
     array  => 'color=blue&color=black&color=brown',
     object => 'R=100&G=200&B=150' } ],
 [ 'simple', 0, 'path',
   { string => 'blue',
     array  => 'blue,black,brown',
     object => 'R,100,G,200,B,150' } ],
 [ 'simple', 1, 'path',
   { string => 'blue',
     array  => 'blue,black,brown',
     object => 'R=100,G=200,B=150' } ],
 [ 'simple', 0, 'header',
   { string => 'blue',
     array  => 'blue,black,brown',
     object => 'R,100,G,200,B,150' } ],
 [ 'simple', 1, 'header',
   { string => 'blue',
     array  => 'blue,black,brown',
     object => 'R=100,G=200,B=150' } ],
 [ 'spaceDelimited', 0, 'query',
   { array  => 'color=blue%20black%20brown',
     object => 'color=R%20100%20G%20200%20B%20150' } ],
 [ 'pipeDelimited', 0, 'query',
   { array  => 'color=blue|black|brown',
     object => 'color=R|100|G|200|B|150' } ],
 [ 'deepObject', 1, 'query',
   { object => 'color[R]=100&color[G]=200&color[B]=150' } ],
);

# decode one serialized form through the real request path
sub se_got {
    my ($in, $style, $explode, $schema, $raw) = @_;
    my %p = (name => 'color', in => $in, schema => $schema,
             style => $style, explode => ($explode ? \1 : \0));
    my ($path, %args);
    if ($in eq 'path') {
        $p{required} = \1;
        $path = '/t/{color}';
        $args{path} = { color => $raw };
    }
    elsif ($in eq 'query')  { $path = '/t'; $args{query}  = $raw }
    else                    { $path = '/t'; $args{header} = { color => $raw } }
    my ($a) = api(doc(paths => { $path => { get => {
        operationId => 'op',
        parameters  => [ \%p ],
        responses   => { 200 => { description => 'ok' } } } } }));
    return (0, 'document refused') unless $a;
    my ($ok, $res) = $a->validate_request(op => \%args);
    return (0, 'request refused') unless $ok;
    return (1, $res->{$in}{color});
}

# The same table, read the OTHER way: what the CLIENT must put on the wire.
#
# A style is a two-sided contract and only the reading half was pinned. The
# encode half was almost entirely unimplemented - `style` was ignored, and an
# arrayref or hashref in a path segment reached SvPV and went out as
# `ARRAY(0x...)` - so these vectors are transcribed from the same table.
#
# Object rows are NOT compared byte for byte. Perl randomises hash order, so a
# serialized object has to be put in some deterministic order or the URL
# changes between runs; the order chosen here is sorted, which is not the R,G,B
# the table happens to print. Object members carry no meaningful order, so the
# round-trip cases below are what pin them: encode, then decode, and require
# the value back.
sub se_client {
    my ($in, $style, $explode, $schema, $value) = @_;
    my %p = (name => 'color', in => $in, schema => $schema,
             style => $style, explode => ($explode ? \1 : \0));
    my $path = '/t';
    if ($in eq 'path') { $p{required} = \1; $path = '/t/{color}' }
    my ($a) = api(doc(paths => { $path => { get => {
        operationId => 'op',
        parameters  => [ \%p ],
        responses   => { 200 => { description => 'ok' } } } } }));
    return (0, 'document refused') unless $a;
    my $c = eval { Open::API::Client->new(api => $a, base_url => 'http://h.test') };
    return (0, 'client refused') unless $c;
    my $u = eval { $c->_request_url('op', { color => $value }) };
    return (0, "url croaked: $@") unless defined $u;
    $u =~ s{^http://h\.test}{};
    return (1, $u, $a);
}

sub se_client_cases {
    my @out;
    for my $row (@SE_TABLE) {
        my ($style, $explode, $in, $cells) = @$row;
        next if $in eq 'header';          # headers are not part of a URL
        for my $kind (qw(string array)) { # object order is not byte-comparable
            next unless exists $cells->{$kind};
            my ($want, $schema) = ($cells->{$kind}, $SE_SCHEMA{$kind});
            my $value = $SE_WANT{$kind};
            # the table prints the SEGMENT for a path style and the QUERY piece
            # for a query style; rebuild the same shape from the URL
            my $expect = $in eq 'path' ? "/t/$want" : "/t?$want";
            push @out, {
                id => sprintf('client/%s-%s-%s', $style,
                              $explode ? 'explode' : 'noexplode', $kind),
                section => 'Style Examples (Parameter Object), encoding',
                requirement => "$style, explode=$explode, $kind serializes to $want",
                run => sub {
                    my ($ok, $got) = se_client($in, $style, $explode, $schema, $value);
                    return 0 unless $ok;
                    return $got eq $expect ? 1 : 0;
                },
            };
        }
    }
    return @out;
}

# encode, then decode, and require the ORIGINAL value back. This is the case
# that pins objects, and the one that would catch the two halves drifting
# apart - a delimiter changed on one side only still passes both byte tests.
sub se_roundtrip_cases {
    my @out;
    for my $row (@SE_TABLE) {
        my ($style, $explode, $in, $cells) = @$row;
        next if $in eq 'header';
        for my $kind (qw(string array object)) {
            next unless exists $cells->{$kind};
            my ($schema, $value) = ($SE_SCHEMA{$kind}, $SE_WANT{$kind});
            push @out, {
                id => sprintf('roundtrip/%s-%s-%s', $style,
                              $explode ? 'explode' : 'noexplode', $kind),
                section => 'Style Examples (Parameter Object), round trip',
                requirement => "$style, explode=$explode: what the client writes, the server reads back",
                run => sub {
                    my ($ok, $u, $a) = se_client($in, $style, $explode, $schema, $value);
                    return 0 unless $ok;
                    my ($good, $res);
                    if ($in eq 'path') {
                        my ($seg) = $u =~ m{^/t/(.*)$};
                        ($good, $res) = $a->validate_request(op =>
                            { path => { color => defined $seg ? $seg : '' } });
                    } else {
                        my ($q) = $u =~ m{\?(.*)$};
                        ($good, $res) = $a->validate_request(op =>
                            { query => defined $q ? $q : '' });
                    }
                    return 0 unless $good;
                    return eq_deeply_ish($res->{$in}{color}, $value);
                },
            };
        }
    }
    return @out;
}

sub se_cases {
    my @out;
    for my $row (@SE_TABLE) {
        my ($style, $explode, $in, $cells) = @$row;
        for my $kind (qw(empty string array object)) {
            next unless exists $cells->{$kind};
            my ($raw, $want) = ($cells->{$kind}, $SE_WANT{$kind});
            my $schema = $SE_SCHEMA{$kind};
            push @out, {
                id => sprintf('style/%s-%s-%s%s', $style,
                              $explode ? 'explode' : 'noexplode', $kind,
                              $in eq 'header' ? '-header' : ''),
                section => 'Style Examples (Parameter Object)',
                requirement => "$style, explode=$explode, $kind: $raw",
                run => sub {
                    my ($ok, $got) = se_got($in, $style, $explode, $schema, $raw);
                    return 0 unless $ok;
                    return eq_deeply_ish($got, $want);
                },
            };
        }
    }
    return @out;
}

# is_deeply without the test: structures compare by shape, scalars stringwise
# (so an integer decoded as "100" matches 100, which is the same value)
sub eq_deeply_ish {
    my ($got, $want) = @_;
    if (ref $want eq 'ARRAY') {
        return 0 unless ref $got eq 'ARRAY' && @$got == @$want;
        for my $i (0 .. $#$want) {
            return 0 unless eq_deeply_ish($got->[$i], $want->[$i]);
        }
        return 1;
    }
    if (ref $want eq 'HASH') {
        return 0 unless ref $got eq 'HASH';
        return 0 unless keys(%$got) == keys(%$want);
        for my $k (keys %$want) {
            return 0 unless exists $got->{$k};
            return 0 unless eq_deeply_ish($got->{$k}, $want->{$k});
        }
        return 1;
    }
    return 0 if ref $got;
    return 0 unless defined $got && defined $want;
    return $got eq $want ? 1 : 0;
}

# ---- Swagger 2.0 helpers -----------------------------------------------------
#
# 2.0 spells the root differently - `swagger: "2.0"` instead of `openapi`, the
# definition sections at the root instead of under components - so it has its
# own builders. The hoist list in op_doc20 is the 2.0 root alphabet, minus the
# two names (`parameters`, `responses`) an Operation Object also carries; the
# root forms of those are passed as root_parameters and root_responses. An
# operation-level consumes/produces/schemes/security is op_consumes and so on.
# The op_doc trap applies here too: a root key left inside the operation tests
# the wrong object.

sub doc20 {
    my (%o) = @_;
    my %d = (
        swagger => '2.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => delete $o{paths} || {},
    );
    $d{$_} = $o{$_} for keys %o;
    return \%d;
}

sub op_doc20 {
    my (%o) = @_;
    my $method = delete $o{method} || 'get';
    my $path   = delete $o{path}   || '/t';
    my %top;
    for my $k (qw(host basePath schemes consumes produces definitions
                  securityDefinitions security tags externalDocs)) {
        $top{$k} = delete $o{$k} if exists $o{$k};
    }
    $top{parameters} = delete $o{root_parameters} if exists $o{root_parameters};
    $top{responses}  = delete $o{root_responses}  if exists $o{root_responses};
    my %op = (operationId => 'op', responses => { 200 => { description => 'ok' } });
    for my $k (qw(consumes produces schemes security)) {
        $op{$k} = delete $o{"op_$k"} if exists $o{"op_$k"};
    }
    %op = (%op, %o);
    return doc20(paths => { $path => { $method => \%op } }, %top);
}

# a POST whose one body parameter carries $schema: the 2.0 twin of json_body_op
sub body20 {
    my ($schema, %o) = @_;
    my $consumes = exists $o{consumes} ? delete $o{consumes} : [ 'application/json' ];
    return op_doc20(
        method     => 'post',
        consumes   => $consumes,
        parameters => [ { name => 'body', in => 'body', required => \1,
                          schema => $schema } ],
        %o,
    );
}

# a formData operation: @fields are 2.0 formData Parameter Objects
sub form20 {
    my ($fields, %o) = @_;
    my $consumes = exists $o{consumes} ? delete $o{consumes}
                                       : [ 'application/x-www-form-urlencoded' ];
    return op_doc20(method => 'post', consumes => $consumes,
                    parameters => [ map { { in => 'formData', %$_ } } @$fields ],
                    %o);
}

my $FORM = { 'content-type' => 'application/x-www-form-urlencoded' };

# the loaded document, or the croak - for the cases that must check WHICH croak,
# because a document refused for the wrong reason reads exactly like compliance
sub api_err { my ($a, $e) = api(@_); return $a ? '' : ($e || 'refused') }

# deep equality that understands the document's booleans: File::Raw::JSON
# yields a blessed Boolean and the fixtures use \1 / \0, and both must compare
# by truth, not by address (eq_deeply_ish refuses every scalar reference)
sub deep_eq {
    my ($x, $y) = @_;
    return 0 if defined $x != defined $y;
    return 1 unless defined $x;
    my ($rx, $ry) = (ref $x, ref $y);
    if ($rx eq 'HASH' || $ry eq 'HASH') {
        return 0 unless $rx eq 'HASH' && $ry eq 'HASH';
        return 0 unless keys(%$x) == keys(%$y);
        for my $k (keys %$x) {
            return 0 unless exists $y->{$k};
            return 0 unless deep_eq($x->{$k}, $y->{$k});
        }
        return 1;
    }
    if ($rx eq 'ARRAY' || $ry eq 'ARRAY') {
        return 0 unless $rx eq 'ARRAY' && $ry eq 'ARRAY' && @$x == @$y;
        for my $i (0 .. $#$x) { return 0 unless deep_eq($x->[$i], $y->[$i]) }
        return 1;
    }
    if ($rx || $ry) {
        # a boolean of either spelling: compare truth
        my $tx = $rx ? (($rx eq 'SCALAR' || $rx eq 'REF') ? !!$$x : !!$x) : !!$x;
        my $ty = $ry ? (($ry eq 'SCALAR' || $ry eq 'REF') ? !!$$y : !!$y) : !!$y;
        return $tx == $ty ? 1 : 0;
    }
    return $x eq $y ? 1 : 0;
}

# every string anywhere in a structure, through $cb
sub walk_strings {
    my ($v, $cb) = @_;
    if (ref $v eq 'HASH')     { walk_strings($_, $cb) for values %$v }
    elsif (ref $v eq 'ARRAY') { walk_strings($_, $cb) for @$v }
    elsif (!ref $v && defined $v) { $cb->($v) }
}

# a 2.0-shaped reference anywhere a $ref KEY holds one. Only $ref values: a
# string spelled like a pointer inside `default`, `example` or `enum` is user
# data the rewrite must NOT touch (swagger/reference/position-aware pins that).
sub has_2_0_ref {
    my ($v) = @_;
    if (ref $v eq 'HASH') {
        for my $k (keys %$v) {
            if ($k eq '$ref' && !ref $v->{$k} && defined $v->{$k}) {
                return 1 if $v->{$k} =~ m{^\#/(?:definitions|parameters|responses)/};
                next;
            }
            next if $k eq 'default' || $k eq 'example' || $k eq 'examples' || $k eq 'enum';
            return 1 if has_2_0_ref($v->{$k});
        }
        return 0;
    }
    if (ref $v eq 'ARRAY') { for (@$v) { return 1 if has_2_0_ref($_) } }
    return 0;
}

# The official 2.0 example documents, vendored in t/compliance/swagger2/ (see
# the README there). Each must load, route every operation to itself,
# synthesize every response into a body that validates against its own schema
# (the t/27 property: the mock walks the normalised document), come out
# unchanged when its normalised form is fed back through new(), and carry no
# #/definitions/-style reference anywhere in ->spec, since the mock's generic
# pointer resolver would follow one and the compiler would not.
my $SW2_DIR = "$DIR/swagger2";

# does any response in the document carry a schema under its content?
sub has_response_schema {
    my ($spec) = @_;
    for my $item (values %{ $spec->{paths} || {} }) {
        next unless ref $item eq 'HASH';
        for my $op (values %$item) {
            next unless ref $op eq 'HASH' && ref $op->{responses} eq 'HASH';
            for my $r (values %{ $op->{responses} }) {
                next unless ref $r eq 'HASH' && ref $r->{content} eq 'HASH';
                for my $mt (values %{ $r->{content} }) {
                    return 1 if ref $mt eq 'HASH' && $mt->{schema};
                }
            }
        }
    }
    return 0;
}

sub swagger2_doc_cases {
    my @out;
    for my $path (sort glob("$SW2_DIR/*.json")) {
        my ($name) = $path =~ m{([^/]+)\.json$};
        my $sec = 'the official 2.0 example documents (vendored)';
        push @out,
        { id => "swagger2/$name/loads", section => $sec,
          requirement => "$name.json loads",
          run => sub { loads($path) } },
        { id => "swagger2/$name/routes", section => $sec,
          requirement => "$name.json: every operation routes to itself",
          run => sub {
              my ($a) = api($path);
              return 0 unless $a;
              my $n = 0;
              for my $op (@{ $a->operations }) {
                  my $p = $op->{path};
                  $p =~ s/\{[^}]+\}/1/g;
                  my ($id) = $a->match(uc $op->{method} => $p);
                  return 0 unless defined $id && $id eq $op->{operationId};
                  $n++;
              }
              return $n ? 1 : 0;
          } },
        { id => "swagger2/$name/synthesizes", section => $sec,
          requirement => "$name.json: every synthesized response validates against its own schema",
          run => sub {
              my ($a) = api($path);
              return 0 unless $a;
              my $checked = 0;
              for my $op (@{ $a->operations }) {
                  my $id   = $op->{operationId};
                  my $info = $a->operation_info($id);
                  my @codes = (undef,
                      map { $_->{status} =~ /^\d+$/ ? $_->{status} : () }
                          grep { $_->{validated} } @{ $info->{responses} });
                  my %seen;
                  for my $code (@codes) {
                      next if defined $code && $seen{$code}++;
                      my $trip = $a->synthesize($id, defined $code ? { code => $code } : ());
                      my $errs = $a->check_response($id, $trip, {});
                      return 0 if ref $errs eq 'ARRAY' && @$errs;
                  }
                  $checked += $a->response_coverage($id)->{checked};
              }
              # a document that declares no response schema at all (the
              # api-with-examples document) has nothing a body can be checked
              # against; synthesizing every response without error is then
              # the whole requirement, and the count guard would only say so
              return ($checked > 0 || !has_response_schema($a->spec)) ? 1 : 0;
          } },
        { id => "swagger2/$name/idempotent", section => $sec,
          requirement => "$name.json: new(spec => ->spec) yields the same document",
          run => sub {
              my ($a) = api($path);
              return 0 unless $a;
              my ($b) = api($a->spec);
              return 0 unless $b;
              return deep_eq($a->spec, $b->spec);
          } },
        { id => "swagger2/$name/no-definitions-left", section => $sec,
          requirement => "$name.json: no #/definitions/, #/parameters/ or #/responses/ reference survives in ->spec",
          run => sub {
              my ($a) = api($path);
              return 0 unless $a;
              return has_2_0_ref($a->spec) ? 0 : 1;
          } };
    }
    return @out;
}

# ---- 2.0 collectionFormat, the vectors ------------------------------------------
#
# 2.0 publishes no Style Examples table. What it publishes is the definition
# of each collectionFormat, with a spelling beside it (Parameter Object,
# collectionFormat): csv `foo,bar`, ssv `foo bar`, tsv `foo\tbar`, pipes
# `foo|bar`, multi `foo=bar&foo=baz`. Those spellings are the vectors here,
# applied to the three-value array the 3.x table uses. On the wire a space is
# %20 and a tab %09 in a URL and literal in a header; a pipe travels literally,
# as the 3.x pipeDelimited row has it.

my %CF_SEP = (csv => ',', ssv => ' ', tsv => "\t", pipes => '|');
my @CF_IN  = qw(query path header formData);
my @CF_VAL = ('blue', 'black', 'brown');

# the VALUE as it travels in a URL (a space is %20, a tab %09, a pipe literal)
sub cf_url_value {
    my ($fmt) = @_;
    my $s = join($CF_SEP{$fmt}, @CF_VAL);
    $s =~ s/ /%20/g; $s =~ s/\t/%09/g;
    return $s;
}

# the keyed piece of a query string or a form body: `color=<value>`, or the
# repeated keys multi means
sub cf_url_piece {
    my ($fmt) = @_;
    return join('&', map { "color=$_" } @CF_VAL) if $fmt eq 'multi';
    return 'color=' . cf_url_value($fmt);
}

sub cf_param {
    my ($in, $fmt) = @_;
    my %p = (name => 'color', in => $in, type => 'array', items => { type => 'string' });
    $p{collectionFormat} = $fmt if $fmt;
    $p{required} = \1 if $in eq 'path';
    return \%p;
}

sub cf_doc {
    my ($in, $fmt) = @_;
    return form20([ cf_param($in, $fmt) ]) if $in eq 'formData';
    return op_doc20(path => '/t/{color}', parameters => [ cf_param($in, $fmt) ])
        if $in eq 'path';
    return op_doc20(parameters => [ cf_param($in, $fmt) ]);
}

# the wire form, as the server receives it for each location
sub cf_wire {
    my ($in, $fmt) = @_;
    my $piece = cf_url_piece($fmt);
    return (query  => $piece)                              if $in eq 'query';
    return (header => $FORM, body => $piece)               if $in eq 'formData';
    return (path   => { color => ($fmt eq 'multi' ? '' : cf_url_value($fmt)) })
        if $in eq 'path';
    return (header => { color => join($CF_SEP{$fmt}, @CF_VAL) });   # literal
}

sub cf_slot { my ($in) = @_; return $in eq 'formData' ? 'body' : $in }

sub cf20_cases {
    my @out;
    for my $in (@CF_IN) {
        for my $fmt (qw(csv ssv tsv pipes multi)) {
            my $legal = $fmt ne 'multi' || $in eq 'query' || $in eq 'formData';
            if (!$legal) {
                push @out, {
                    id => "swagger/parameter/collectionFormat-multi-refused-$in",
                    section => 'Parameter Object, collectionFormat',
                    requirement => "multi \"is valid only for parameters in query or formData\": refused in $in",
                    run => sub { croaks(cf_doc($in, 'multi')) },
                };
                next;
            }
            push @out, {
                id => "swagger/parameter/collectionFormat-$fmt-$in",
                section => 'Parameter Object, collectionFormat',
                requirement => "$fmt in $in decodes to the array",
                run => sub {
                    my ($a) = api(cf_doc($in, $fmt));
                    return 0 unless $a;
                    my ($ok, $res) = req($a, cf_wire($in, $fmt));
                    return 0 unless $ok;
                    return eq_deeply_ish($res->{cf_slot($in)}{color}, \@CF_VAL);
                },
            };
        }
    }
    # the default IS csv, and csv is NOT exploded: 3.x's query default is the
    # reverse (form + explode: true), so a converter that leaves the default
    # implicit reads `a=1&a=2` as the array and `a=1,2` as one string
    push @out, {
        id => 'swagger/parameter/csv-default-query',
        section => 'Parameter Object, collectionFormat',
        requirement => 'an array query parameter with no collectionFormat is csv: comma separated, not repeated keys',
        run => sub {
            my ($a) = api(cf_doc('query', undef));
            return 0 unless $a;
            my ($ok, $res) = req($a, query => 'color=blue,black,brown');
            return 0 unless $ok && eq_deeply_ish($res->{query}{color}, \@CF_VAL);
            my ($ok2, $res2) = req($a, query => 'color=blue&color=black');
            return 1 unless $ok2;
            return eq_deeply_ish($res2->{query}{color}, [ 'blue', 'black' ]) ? 0 : 1;
        },
    };
    return @out;
}

# what the CLIENT writes for each format, query and path (a header has no
# inspection point and formData bytes are pinned by the round trip only)
sub cf20_client_cases {
    my @out;
    for my $in (qw(query path)) {
        for my $fmt (qw(csv ssv tsv pipes multi)) {
            next if $fmt eq 'multi' && $in ne 'query';
            my $piece  = $in eq 'path' ? cf_url_value($fmt) : cf_url_piece($fmt);
            my $expect = $in eq 'path' ? "/t/$piece" : "/t?$piece";
            push @out, {
                id => "swagger/client/collectionFormat-$fmt-$in",
                section => 'Parameter Object, collectionFormat, encoding',
                requirement => "the client writes $fmt in $in as $piece",
                run => sub {
                    my ($a) = api(cf_doc($in, $fmt));
                    return 0 unless $a;
                    my $c = eval { Open::API::Client->new(api => $a, base_url => 'http://h.test') };
                    return 0 unless $c;
                    my $u = eval { $c->_request_url('op', { color => \@CF_VAL }) };
                    return 0 unless defined $u;
                    $u =~ s{^http://h\.test}{};
                    return $u eq $expect ? 1 : 0;
                },
            };
        }
    }
    return @out;
}

# encode with the client, decode with the server, require the array back: the
# case that catches the two halves drifting, where both byte cases stay green
sub cf20_roundtrip_cases {
    my @out;
    for my $in (qw(query path formData)) {
        for my $fmt (qw(csv ssv tsv pipes multi)) {
            next if $fmt eq 'multi' && $in eq 'path';
            push @out, {
                id => "swagger/roundtrip/collectionFormat-$fmt-$in",
                section => 'Parameter Object, collectionFormat, round trip',
                requirement => "$fmt in $in: what the client writes, the server reads back",
                run => sub {
                    my ($a) = api(cf_doc($in, $fmt));
                    return 0 unless $a;
                    my $c = eval { Open::API::Client->new(api => $a, base_url => 'http://h.test') };
                    return 0 unless $c;
                    my ($good, $res);
                    if ($in eq 'formData') {
                        my ($b, $ct) = eval { $c->_request_body('op', { body => { color => \@CF_VAL } }) };
                        return 0 unless defined $b && defined $ct;
                        ($good, $res) = $a->validate_request(op =>
                            { header => { 'content-type' => $ct }, body => $b });
                    } else {
                        my $u = eval { $c->_request_url('op', { color => \@CF_VAL }) };
                        return 0 unless defined $u;
                        if ($in eq 'path') {
                            my ($seg) = $u =~ m{^http://h\.test/t/(.*)$};
                            ($good, $res) = $a->validate_request(op =>
                                { path => { color => defined $seg ? $seg : '' } });
                        } else {
                            my ($q) = $u =~ m{\?(.*)$};
                            ($good, $res) = $a->validate_request(op =>
                                { query => defined $q ? $q : '' });
                        }
                    }
                    return 0 unless $good;
                    return eq_deeply_ish($res->{cf_slot($in)}{color}, \@CF_VAL);
                },
            };
        }
    }
    # nested Items: each level carries its own delimiter
    my $nested = { name => 'm', in => 'query', type => 'array', collectionFormat => 'csv',
                   items => { type => 'array', collectionFormat => 'pipes',
                              items => { type => 'integer' } } };
    push @out, {
        id => 'swagger/roundtrip/items-nested',
        section => 'Items Object, collectionFormat, round trip',
        requirement => 'a nested array round-trips with csv outside and pipes inside',
        run => sub {
            my ($a) = api(op_doc20(parameters => [ $nested ]));
            return 0 unless $a;
            my $c = eval { Open::API::Client->new(api => $a, base_url => 'http://h.test') };
            return 0 unless $c;
            my $u = eval { $c->_request_url('op', { m => [ [1, 2], [3, 4] ] }) };
            return 0 unless defined $u;
            my ($q) = $u =~ m{\?(.*)$};
            my ($good, $res) = $a->validate_request(op => { query => defined $q ? $q : '' });
            return 0 unless $good;
            return eq_deeply_ish($res->{query}{m}, [ [1, 2], [3, 4] ]);
        },
    };
    return @out;
}

# ---- the catalogue ----------------------------------------------------------
#
# id            a stable name; expected-fail.txt keys on it
# section       where the requirement lives in the specification
# requirement   what the specification asks for, in its own terms
# run           true when this build meets it

my @CASES = (

se_cases(),
se_client_cases(),
se_roundtrip_cases(),
jsonschema_cases(),
swagger2_doc_cases(),
cf20_cases(),
cf20_client_cases(),
cf20_roundtrip_cases(),

# ---------------------------------------------------------------- OpenAPI Object
{ id => 'openapi/version-3.0', section => '4.1 OpenAPI Object',
  requirement => 'a 3.0.x document is accepted',
  run => sub { loads(doc(openapi => '3.0.3')) } },

{ id => 'openapi/version-3.1', section => '4.1 OpenAPI Object',
  requirement => 'a 3.1.x document is accepted',
  run => sub { loads(doc(openapi => '3.1.0')) } },

{ id => 'openapi/version-refused', section => '4.1 OpenAPI Object',
  requirement => 'a version this implementation does not support is refused',
  run => sub { croaks(doc(openapi => '2.0')) } },

{ id => 'openapi/info-required', section => '4.1 OpenAPI Object',
  requirement => 'info is REQUIRED; a document without it is not a valid document',
  run => sub {
      my $d = doc(); delete $d->{info};
      return croaks($d);
  } },

{ id => 'openapi/jsonSchemaDialect', section => '4.1 OpenAPI Object',
  requirement => 'jsonSchemaDialect declares the dialect for schemas in the document',
  run => sub {
      # Honouring the dialect means acting on it. A document declaring a
      # dialect this build cannot validate against must not silently validate
      # as 2020-12 - either it is refused, or the declaration is reported
      # somewhere a caller can act on. Probed, not asserted, so this flips on
      # its own the day either becomes true.
      my $d = doc(jsonSchemaDialect => 'https://example.test/not-2020-12');
      my ($a, $err) = api($d);
      return 1 if !$a && $err;                      # refused: honest
      return 0 unless $a;
      my $m = eval { $a->can('json_schema_dialect') } ? 1 : 0;
      return $m;                                    # reported: also honest
  } },

{ id => 'openapi/webhooks-accepted', section => '4.1 OpenAPI Object',
  requirement => 'a 3.1 document may carry webhooks',
  run => sub {
      loads(doc(webhooks => { w => { post => { operationId => 'w',
            responses => { 200 => { description => 'ok' } } } } }));
  } },

{ id => 'openapi/webhooks-not-routed', section => '4.1 OpenAPI Object',
  requirement => 'webhooks describe requests the API SENDS, so they are not server routes',
  run => sub {
      my ($a) = api(doc(webhooks => { w => { post => { operationId => 'w',
            responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      return scalar(@{ $a->operations }) == 0;
  } },

{ id => 'openapi/webhooks-normalised', section => '4.1 OpenAPI Object',
  requirement => 'a 3.0 schema inside a webhook is converted like any other',
  run => sub {
      my ($a) = api(doc(openapi => '3.0.3',
          webhooks => { w => { post => { operationId => 'w',
              requestBody => { content => { 'application/json' => {
                  schema => { type => 'string', nullable => 1 } } } },
              responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      my $s = $a->spec->{webhooks}{w}{post}{requestBody}{content}{'application/json'}{schema};
      return ref $s->{type} eq 'ARRAY' ? 1 : 0;
  } },

{ id => 'openapi/servers', section => '4.1 / 4.4 Server Object',
  requirement => 'servers declares the base URL(s); a path prefix belongs to routing',
  run => sub {
      # The capability is opt-in: honouring a prefix re-routes an application
      # that already mounts so PATH_INFO arrives without it, and that shows up
      # as a silent 404, so it is not the default. The case turns it on,
      # because what is being asked is whether the implementation CAN meet the
      # requirement, not what it does when told not to.
      my ($a) = api(doc(servers => [ { url => 'https://h.test/api/v1' } ],
                        paths => { '/pets' => { get => { operationId => 'p',
                            responses => { 200 => { description => 'ok' } } } } }),
                    servers => 1);
      return 0 unless $a;
      my ($id) = $a->match(GET => '/api/v1/pets');
      return defined $id ? 1 : 0;
  } },

{ id => 'openapi/server-variables', section => '4.4 Server Object',
  requirement => 'a templated server URL is expanded from its variables',
  run => sub {
      # Expansion is observable through routing: with {host}/v1 expanded, a
      # request under /v1 reaches the operation.
      my ($a) = api(doc(
          servers => [ { url => 'https://{host}/v1',
                         variables => { host => { default => 'h.test' } } } ],
          paths   => { '/pets' => { get => { operationId => 'p',
              responses => { 200 => { description => 'ok' } } } } }),
          servers => 1);          # same opt-in as openapi/servers
      return 0 unless $a;
      my ($id) = $a->match(GET => '/v1/pets');
      return defined $id ? 1 : 0;
  } },

{ id => 'openapi/tags', section => '4.1 OpenAPI Object',
  requirement => 'root tags are carried for consumers',
  run => sub {
      my ($a) = api(doc(tags => [ { name => 'pets' } ]));
      return 0 unless $a;
      return ref $a->spec->{tags} eq 'ARRAY' ? 1 : 0;
  } },

# ------------------------------------------------------------------- Path Item
{ id => 'pathitem/ref', section => '4.5 Path Item Object',
  requirement => 'a $ref may stand in for a Path Item',
  run => sub {
      my ($a) = api(doc(
          paths => { '/p' => { '$ref' => '#/components/pathItems/T' } },
          components => { pathItems => { T => { get => { operationId => 'pt',
              responses => { 200 => { description => 'ok' } } } } } }));
      return 0 unless $a;
      my ($id) = $a->match(GET => '/p');
      return defined $id && $id eq 'pt' ? 1 : 0;
  } },

{ id => 'pathitem/ref-unresolvable', section => '4.5 / 4.3 Reference Object',
  requirement => 'a $ref that cannot be resolved is an error, not a dropped route',
  run => sub {
      croaks(doc(paths => { '/p' => { '$ref' => '#/components/pathItems/Ghost' } },
                 components => {}));
  } },

(map {
    my $m = $_;
    { id => "pathitem/method-$m", section => '4.5 Path Item Object',
      requirement => "the $m operation is routed",
      run => sub {
          my ($a) = api(doc(paths => { '/t' => { $m => { operationId => 'op',
              responses => { 200 => { description => 'ok' } } } } }));
          return 0 unless $a;
          my ($id) = $a->match(uc($m) => '/t');
          return defined $id ? 1 : 0;
      } };
} qw(get put post delete options head patch trace)),

{ id => 'pathitem/parameters-merged', section => '4.5 Path Item Object',
  requirement => 'path-item parameters apply to every operation on that path',
  run => sub {
      my ($a) = api(doc(paths => { '/t' => {
          parameters => [ { name => 'q', in => 'query', required => 1,
                            schema => { type => 'string' } } ],
          get => { operationId => 'op', responses => { 200 => { description => 'ok' } } },
      } }));
      return 0 unless $a;
      my ($ok) = req($a);
      return $ok ? 0 : 1;      # the inherited required parameter must be enforced
  } },

{ id => 'pathitem/operation-overrides', section => '4.5 Path Item Object',
  requirement => 'an operation parameter overrides a path-item one of the same name and location',
  run => sub {
      my ($a) = api(doc(paths => { '/t' => {
          parameters => [ { name => 'q', in => 'query', required => 1,
                            schema => { type => 'string' } } ],
          get => { operationId => 'op',
                   parameters => [ { name => 'q', in => 'query', required => 0,
                                     schema => { type => 'string' } } ],
                   responses => { 200 => { description => 'ok' } } },
      } }));
      return 0 unless $a;
      my ($ok) = req($a);
      return $ok ? 1 : 0;      # the override made it optional
  } },

# ------------------------------------------------------------------- Operation
{ id => 'operation/operationId-optional', section => '4.6 Operation Object',
  requirement => 'operationId is OPTIONAL; a document without one is still valid',
  run => sub {
      loads(doc(paths => { '/t' => { get => {
          responses => { 200 => { description => 'ok' } } } } }));
  } },

{ id => 'operation/deprecated', section => '4.6 Operation Object',
  requirement => 'deprecated is reported to consumers',
  run => sub {
      my ($a) = api(op_doc(deprecated => 1));
      return 0 unless $a;
      my $d = eval { $a->operation_doc('op') } or return 0;
      return $d->{deprecated} ? 1 : 0;
  } },

{ id => 'operation/callbacks', section => '4.6 / 4.14 Callback Object',
  requirement => 'a callback value is a Path Item, so its schemas are normalised like any other',
  run => sub {
      # "carried for consumers" would pass trivially - unknown keys are copied
      # verbatim - and report compliance where there is none. The requirement
      # that bites is that a 3.0 schema INSIDE a callback is converted, which
      # is what makes ->spec one dialect throughout.
      my ($a) = api(doc(openapi => '3.0.3', paths => { '/t' => { get => {
          operationId => 'op',
          callbacks => { onEvent => { '{$request.body#/cb}' => { post => {
              operationId  => 'cb',
              requestBody  => { content => { 'application/json' => {
                  schema => { type => 'string', nullable => 1 } } } },
              responses    => { 200 => { description => 'ok' } } } } } },
          responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      my $s = eval { $a->spec->{paths}{'/t'}{get}{callbacks}{onEvent}
                       {'{$request.body#/cb}'}{post}{requestBody}
                       {content}{'application/json'}{schema} } or return 0;
      return ref $s->{type} eq 'ARRAY' ? 1 : 0;
  } },

# ------------------------------------------------------------------- Parameter
(map {
    my $in = $_;
    { id => "parameter/in-$in", section => '4.10 Parameter Object',
      requirement => "a parameter in $in is validated",
      run => sub {
          my %p = (name => 'v', in => $in, schema => { type => 'integer' });
          $p{required} = 1 if $in eq 'path';
          my $path = $in eq 'path' ? '/t/{v}' : '/t';
          my ($a) = api(doc(paths => { $path => { get => { operationId => 'op',
              parameters => [ \%p ],
              responses => { 200 => { description => 'ok' } } } } }));
          return 0 unless $a;
          my %args = $in eq 'path'   ? (path   => { v => 'abc' })
                   : $in eq 'query'  ? (query  => 'v=abc')
                   : $in eq 'header' ? (header => { v => 'abc' })
                   :                   (header => { cookie => 'v=abc' });
          my ($ok) = req($a, %args);
          return $ok ? 0 : 1;     # 'abc' must fail an integer schema
      } };
} qw(path query header cookie)),

{ id => 'parameter/allowEmptyValue', section => '4.10 Parameter Object',
  requirement => 'allowEmptyValue permits an empty value for a query parameter',
  run => sub {
      # `?v=` against a schema that rejects the empty string: with
      # allowEmptyValue honoured the parameter is treated as present-but-
      # empty and permitted; without it the empty string reaches the schema.
      my ($a) = api(doc(paths => { '/t' => { get => { operationId => 'op',
          parameters => [ { name => 'v', in => 'query', allowEmptyValue => 1,
                            schema => { type => 'string', minLength => 1 } } ],
          responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      my ($ok) = req($a, query => 'v=');
      return $ok ? 1 : 0;
  } },

{ id => 'parameter/allowReserved', section => '4.10 Parameter Object',
  requirement => 'allowReserved lets reserved characters through unencoded',
  run => sub {
      # allowReserved is a CLIENT-side serialization rule: reserved characters
      # MAY be sent without percent-encoding. A server decodes `a%2Fb` and
      # `a/b` to the same value either way, so there is nothing here for a
      # validator to do - and the client builds its URL entirely inside C
      # (oa_cli_url), with no XSUB exposing it, so the requirement cannot be
      # observed without standing up a real server. What IS observable is
      # that the flag does not corrupt the server side: a reserved character
      # arrives intact whichever spelling the client chose.
      my ($a) = api(doc(paths => { '/t' => { get => { operationId => 'op',
          parameters => [ { name => 'v', in => 'query', allowReserved => 1,
                            schema => { type => 'string' } } ],
          responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      # A CLIENT-side rule: the reserved set MAY go on the wire unencoded. A
      # server decodes `a%2Fb` and `a/b` to the same value, so nothing on the
      # validating side can show this - the URL the client builds is the only
      # evidence, and _request_url exposes it without firing a request.
      return 0 unless $a;
      return 0 unless eval { require Open::API::Client; 1 };
      my $c = eval {
          Open::API::Client->new(api => $a, base_url => 'https://h.test') };
      return 0 unless $c && $c->can('_request_url');
      my $url = eval { $c->_request_url('op', { v => 'a/b' }) };
      return defined $url && $url =~ m{[?&]v=a/b(?:&|$)} ? 1 : 0;
  } },

{ id => 'parameter/deprecated', section => '4.10 Parameter Object',
  requirement => 'a deprecated parameter is reported to consumers',
  run => sub {
      my ($a) = api(doc(paths => { '/t' => { get => { operationId => 'op',
          parameters => [ { name => 'v', in => 'query', deprecated => 1,
                            schema => { type => 'string' } } ],
          responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      my $i = eval { $a->operation_info('op') } or return 0;
      my ($p) = grep { $_->{name} eq 'v' } @{ $i->{parameters} || [] };
      return $p && $p->{deprecated} ? 1 : 0;
  } },

{ id => 'parameter/content', section => '4.10 Parameter Object',
  requirement => 'a parameter may use content instead of schema',
  run => sub {
      my ($a) = api(doc(paths => { '/t' => { get => { operationId => 'op',
          parameters => [ { name => 'v', in => 'query', content => {
              'application/json' => { schema => { type => 'object',
                  required => ['a'], properties => { a => { type => 'string' } } } } } } ],
          responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      my ($bad) = req($a, query => 'v=%7B%7D');           # {} lacks `a`
      return $bad ? 0 : 1;
  } },

# ---- style / explode, per location
(map {
    my ($id, $in, $style, $explode, $raw, $want) = @$_;
    { id => "parameter/style-$id", section => '4.10.5 Style Values',
      requirement => "$in style $style" . (defined $explode ? " explode=$explode" : '')
                   . " splits a list",
      run => sub {
          my %p = (name => 'v', in => $in, style => $style,
                   schema => { type => 'array', items => { type => 'string' } });
          $p{required} = 1 if $in eq 'path';
          $p{explode}  = $explode if defined $explode;
          my $path = $in eq 'path' ? '/t/{v}' : '/t';
          my ($a) = api(doc(paths => { $path => { get => { operationId => 'op',
              parameters => [ \%p ],
              responses => { 200 => { description => 'ok' } } } } }));
          return 0 unless $a;
          my %args = $in eq 'path'   ? (path   => { v => $raw })
                   : $in eq 'query'  ? (query  => "v=$raw")
                   : $in eq 'header' ? (header => { v => $raw })
                   :                   (header => { cookie => "v=$raw" });
          my ($ok, $res) = req($a, %args);
          return 0 unless $ok;
          my $g = $res->{$in}{v};
          return 0 unless ref $g eq 'ARRAY';
          return "@$g" eq "@$want" ? 1 : 0;
      } };
} (
    [ 'path-simple',      'path',   'simple',         undef, 'a,b',     ['a','b'] ],
    [ 'path-label',       'path',   'label',          1,     '.a.b',    ['a','b'] ],
    [ 'path-matrix',      'path',   'matrix',         1,     ';v=a;v=b',['a','b'] ],
    [ 'query-form',       'query',  'form',           0,     'a,b',     ['a','b'] ],
    [ 'query-space',      'query',  'spaceDelimited', 0,     'a%20b',   ['a','b'] ],
    [ 'query-pipe',       'query',  'pipeDelimited',  0,     'a%7Cb',   ['a','b'] ],
    [ 'header-simple',    'header', 'simple',         undef, 'a,b',     ['a','b'] ],
    [ 'cookie-form',      'cookie', 'form',           0,     'a,b',     ['a','b'] ],
)),

{ id => 'parameter/style-deepObject', section => '4.10.5 Style Values',
  requirement => 'deepObject collects name[key]=value into an object',
  run => sub {
      my ($a) = api(doc(paths => { '/t' => { get => { operationId => 'op',
          parameters => [ { name => 'v', in => 'query', style => 'deepObject',
                            explode => 1, schema => { type => 'object' } } ],
          responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      my ($ok, $res) = req($a, query => 'v[a]=1&v[b]=2');
      return 0 unless $ok;
      my $g = $res->{query}{v};
      return 0 unless ref $g eq 'HASH';
      return defined $g->{a} && $g->{a} eq '1'
          && defined $g->{b} && $g->{b} eq '2' ? 1 : 0;
  } },

{ id => 'parameter/escaped-delimiter', section => '4.10.5 Style Values',
  requirement => 'a percent-encoded delimiter belongs to the value, not the list',
  run => sub {
      my ($a) = api(doc(paths => { '/t' => { get => { operationId => 'op',
          parameters => [ { name => 'v', in => 'query', style => 'form',
                            explode => 0,
                            schema => { type => 'array', items => { type => 'string' } } } ],
          responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      my ($ok, $res) = req($a, query => 'v=a%2Cb');
      return 0 unless $ok;
      my $g = $res->{query}{v};
      return ref $g eq 'ARRAY' && @$g == 1 && $g->[0] eq 'a,b' ? 1 : 0;
  } },

{ id => 'parameter/array-via-ref', section => '4.10 Parameter Object',
  requirement => 'an array schema reached through a $ref is still an array',
  run => sub {
      my ($a) = api(doc(
          paths => { '/t' => { get => { operationId => 'op',
              parameters => [ { name => 'v', in => 'query',
                                schema => { '$ref' => '#/components/schemas/L' } } ],
              responses => { 200 => { description => 'ok' } } } } },
          components => { schemas => { L => { type => 'array',
                                              items => { type => 'string' } } } }));
      return 0 unless $a;
      my ($ok, $res) = req($a, query => 'v=a&v=b');
      return 0 unless $ok;
      return ref $res->{query}{v} eq 'ARRAY' ? 1 : 0;
  } },

# ----------------------------------------------------------------- Request Body
{ id => 'requestbody/json', section => '4.11 Request Body Object',
  requirement => 'an application/json body is validated against its schema',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object', required => ['a'],
                                   properties => { a => { type => 'string' } } }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => {});
      return $ok ? 0 : 1;
  } },

{ id => 'requestbody/required', section => '4.11 Request Body Object',
  requirement => 'a required body that is absent is refused',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object' }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON);
      return $ok ? 0 : 1;
  } },

{ id => 'requestbody/json-suffix', section => '4.11 / RFC 6839',
  requirement => 'a +json suffixed media type is JSON and its schema applies',
  run => sub {
      my ($a) = api(op_doc(method => 'post',
          requestBody => { required => 1, content => { 'application/vnd.api+json' => {
              schema => { type => 'object', required => ['a'],
                          properties => { a => { type => 'string' } } } } } }));
      return 0 unless $a;
      my ($ok) = req($a, header => { 'content-type' => 'application/vnd.api+json' },
                          body => '{}');
      return $ok ? 0 : 1;
  } },

{ id => 'requestbody/media-type-case', section => '4.11 / RFC 7231',
  requirement => 'a media type is matched case-insensitively',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object' }));
      return 0 unless $a;
      my ($ok) = req($a, header => { 'content-type' => 'Application/JSON' }, body => {});
      return $ok ? 1 : 0;
  } },

{ id => 'requestbody/urlencoded', section => '4.11 Request Body Object',
  requirement => 'an application/x-www-form-urlencoded body is validated against its schema',
  run => sub {
      my ($a) = api(op_doc(method => 'post',
          requestBody => { required => 1,
            content => { 'application/x-www-form-urlencoded' => {
              schema => { type => 'object', required => ['a'],
                          properties => { a => { type => 'string' } } } } } }));
      return 0 unless $a;
      my ($ok) = req($a,
          header => { 'content-type' => 'application/x-www-form-urlencoded' },
          body   => 'nope=1');
      return $ok ? 0 : 1;
  } },

{ id => 'requestbody/multipart', section => '4.11 Request Body Object',
  requirement => 'a multipart/form-data body is validated against its schema',
  run => sub {
      my ($a) = api(op_doc(method => 'post',
          requestBody => { required => 1,
            content => { 'multipart/form-data' => {
              schema => { type => 'object', required => ['a'],
                          properties => { a => { type => 'string' } } } } } }));
      return 0 unless $a;
      my ($ok) = req($a,
          header => { 'content-type' => 'multipart/form-data; boundary=xx' },
          body   => "--xx\r\nContent-Disposition: form-data; name=\"nope\"\r\n\r\n1\r\n--xx--\r\n");
      return $ok ? 0 : 1;
  } },

{ id => 'requestbody/wildcard', section => '4.11 Request Body Object',
  requirement => 'a */* content entry matches any request media type',
  run => sub {
      my ($a) = api(op_doc(method => 'post',
          requestBody => { required => 1,
            content => { '*/*' => { schema => { type => 'object' } } } }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => {});
      return $ok ? 1 : 0;
  } },

{ id => 'mediatype/encoding', section => '4.13 Encoding Object',
  requirement => 'encoding describes how each property of a form body is serialized',
  run => sub {
      # An encoding entry declaring a JSON part means that property is a
      # document, not a string. Observable as the body being refused when the
      # part does not match the property's schema.
      my ($a) = api(op_doc(method => 'post',
          requestBody => { required => 1,
            content => { 'application/x-www-form-urlencoded' => {
              schema   => { type => 'object', required => ['a'],
                            properties => { a => { type => 'object',
                                required => ['n'],
                                properties => { n => { type => 'string' } } } } },
              encoding => { a => { contentType => 'application/json' } } } } }));
      return 0 unless $a;
      # The discriminating body: `a` carries a JSON document that SATISFIES
      # the property's schema. Honoured, the encoding decodes it and the body
      # passes; ignored, `a` stays the string {"n":"x"} and fails `type:
      # object`. The earlier spelling sent `{}`, which fails either way - it
      # could not tell the two apart, and would have gone green the moment
      # form bodies started being decoded at all, for the wrong reason.
      my ($ok) = req($a,
          header => { 'content-type' => 'application/x-www-form-urlencoded' },
          body   => 'a=%7B%22n%22%3A%22x%22%7D');    # a={"n":"x"}
      return $ok ? 1 : 0;
  } },

# -------------------------------------------------------------------- Responses
{ id => 'responses/exact-status', section => '4.7 Responses Object',
  requirement => 'a response schema is selected by its exact status',
  run => sub {
      my ($a) = api(op_doc(responses => { 200 => { description => 'ok',
          content => { 'application/json' => { schema => { type => 'object' } } } } }));
      return 0 unless $a;
      my $i = eval { $a->operation_info('op') } or return 0;
      return scalar(grep { $_->{status} eq '200' && $_->{validated} }
                    @{ $i->{responses} }) ? 1 : 0;
  } },

{ id => 'responses/range', section => '4.7 Responses Object',
  requirement => 'a range key (2XX) covers the statuses in that class',
  run => sub {
      my ($a) = api(op_doc(responses => { '2XX' => { description => 'ok',
          content => { 'application/json' => { schema => { type => 'object' } } } } }));
      return 0 unless $a;
      my $i = eval { $a->operation_info('op') } or return 0;
      return scalar(grep { $_->{status} eq '2XX' } @{ $i->{responses} }) ? 1 : 0;
  } },

{ id => 'response/headers', section => '4.12 Response Object',
  requirement => 'a declared response header is checked',
  run => sub {
      my ($a) = api(op_doc(responses => { 200 => { description => 'ok',
          headers => { 'X-R' => { required => 1, schema => { type => 'integer' } } },
          content => { 'application/json' => { schema => { type => 'object' } } } } }));
      return 0 unless $a;
      # a compiled header row is the observable; the behaviour is pinned by t/36
      return eval { $a->operation_info('op') } ? 1 : 0;
  } },

{ id => 'response/links', section => '4.12 / 4.15 Link Object',
  requirement => 'links describe related operations and are carried for consumers',
  run => sub {
      my ($a) = api(op_doc(responses => { 200 => { description => 'ok',
          links => { self => { operationId => 'op' } } } }));
      return 0 unless $a;
      return ref $a->spec->{paths}{'/t'}{get}{responses}{200}{links} eq 'HASH' ? 1 : 0;
  } },

# ------------------------------------------------------------- Reference Object
{ id => 'reference/parameter', section => '4.3 Reference Object',
  requirement => 'a $ref may stand in for a Parameter Object',
  run => sub {
      my ($a) = api(doc(
          paths => { '/t' => { get => { operationId => 'op',
              parameters => [ { '$ref' => '#/components/parameters/V' } ],
              responses => { 200 => { description => 'ok' } } } } },
          components => { parameters => { V => { name => 'v', in => 'query',
              required => 1, schema => { type => 'string' } } } }));
      return 0 unless $a;
      my ($ok) = req($a);
      return $ok ? 0 : 1;      # the referenced parameter is required
  } },

{ id => 'reference/requestBody', section => '4.3 Reference Object',
  requirement => 'a $ref may stand in for a Request Body Object',
  run => sub {
      my ($a) = api(doc(
          paths => { '/t' => { post => { operationId => 'op',
              requestBody => { '$ref' => '#/components/requestBodies/B' },
              responses => { 200 => { description => 'ok' } } } } },
          components => { requestBodies => { B => { required => 1,
              content => { 'application/json' => { schema => { type => 'object',
                  required => ['a'], properties => { a => { type => 'string' } } } } } } } }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => {});
      return $ok ? 0 : 1;
  } },

{ id => 'reference/response', section => '4.3 Reference Object',
  requirement => 'a $ref may stand in for a Response Object',
  run => sub {
      my ($a) = api(doc(
          paths => { '/t' => { get => { operationId => 'op',
              responses => { 200 => { '$ref' => '#/components/responses/R' } } } } },
          components => { responses => { R => { description => 'ok',
              content => { 'application/json' => { schema => { type => 'object' } } } } } }));
      return 0 unless $a;
      my $i = eval { $a->operation_info('op') } or return 0;
      return scalar(grep { $_->{validated} } @{ $i->{responses} }) ? 1 : 0;
  } },

{ id => 'reference/header', section => '4.3 Reference Object',
  requirement => 'a $ref may stand in for a Header Object',
  run => sub {
      my ($a) = api(doc(
          paths => { '/t' => { get => { operationId => 'op',
              responses => { 200 => { description => 'ok',
                  headers => { 'X-T' => { '$ref' => '#/components/headers/T' } } } } } } },
          components => { headers => { T => { required => 1,
              schema => { type => 'string' } } } }));
      return 0 unless $a;
      my $h = $a->spec->{paths}{'/t'}{get}{responses}{200}{headers}{'X-T'};
      return !exists $h->{'$ref'} && $h->{schema} ? 1 : 0;
  } },

{ id => 'reference/example', section => '4.3 / 4.16 Example Object',
  requirement => 'a $ref may stand in for an Example Object',
  run => sub {
      my ($a) = api(doc(
          paths => { '/t' => { get => { operationId => 'op',
              responses => { 200 => { description => 'ok',
                  content => { 'application/json' => {
                      schema   => { type => 'object' },
                      examples => { one => { '$ref' => '#/components/examples/E' } } } } } } } } },
          components => { examples => { E => { value => { a => 1 } } } }));
      return 0 unless $a;
      my $e = $a->spec->{paths}{'/t'}{get}{responses}{200}
                  {content}{'application/json'}{examples}{one};
      return !exists $e->{'$ref'} && exists $e->{value} ? 1 : 0;
  } },

{ id => 'reference/securityScheme', section => '4.3 Reference Object',
  requirement => 'a $ref may stand in for a Security Scheme Object',
  run => sub {
      loads(doc(
          components => { securitySchemes => {
              K    => { '$ref' => '#/components/securitySchemes/Real' },
              Real => { type => 'apiKey', name => 'k', in => 'header' } } },
          security => [ { K => [] } ]));
  } },

{ id => 'reference/unresolvable-body', section => '4.3 Reference Object',
  requirement => 'an unresolvable $ref is an error, not a dropped constraint',
  run => sub {
      croaks(doc(paths => { '/t' => { post => { operationId => 'op',
          requestBody => { '$ref' => '#/components/requestBodies/Ghost' },
          responses => { 200 => { description => 'ok' } } } } }, components => {}));
  } },

{ id => 'reference/siblings-3.1', section => '4.3 Reference Object',
  requirement => 'in 3.1 summary and description may sit beside a $ref',
  run => sub {
      loads(doc(
          paths => { '/t' => { get => { operationId => 'op',
              parameters => [ { '$ref' => '#/components/parameters/V',
                                description => 'overridden' } ],
              responses => { 200 => { description => 'ok' } } } } },
          components => { parameters => { V => { name => 'v', in => 'query',
              schema => { type => 'string' } } } }));
  } },

# --------------------------------------------------------------- Schema Object
{ id => 'schema/readOnly-request', section => '4.8.24 / JSON Schema',
  requirement => 'a readOnly property should not be sent in a request',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object',
          properties => { id => { type => 'integer', readOnly => 1 },
                          n  => { type => 'string' } } }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => { n => 'x', id => 1 });
      return $ok ? 0 : 1;
  } },

{ id => 'schema/readOnly-required', section => '4.8.24 Schema Object',
  requirement => 'a required readOnly property takes effect on responses only',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object', required => ['id','n'],
          properties => { id => { type => 'integer', readOnly => 1 },
                          n  => { type => 'string' } } }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => { n => 'x' });
      return $ok ? 1 : 0;
  } },

{ id => 'schema/writeOnly-request', section => '4.8.24 Schema Object',
  requirement => 'a writeOnly property IS allowed in a request',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object',
          properties => { s => { type => 'string', writeOnly => 1 },
                          n => { type => 'string' } } }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => { n => 'x', s => 'secret' });
      return $ok ? 1 : 0;
  } },

{ id => 'schema/discriminator', section => '4.8.25 Discriminator Object',
  requirement => 'a discriminator selects the branch named by its property',
  run => sub {
      my ($a) = api(json_body_op({ '$ref' => '#/components/schemas/P' },
          components => { schemas => {
              P => { oneOf => [ { '$ref' => '#/components/schemas/D' } ],
                     discriminator => { propertyName => 'kind' } },
              D => { type => 'object', required => ['kind','bark'],
                     properties => { kind => { type => 'string' },
                                     bark => { type => 'string' } } } } }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => { kind => 'D' });   # bark missing
      return $ok ? 0 : 1;
  } },

{ id => 'schema/nullable-3.0', section => '4.8 (3.0) Schema Object',
  requirement => 'a 3.0 nullable schema accepts null',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object',
          properties => { n => { type => 'string', nullable => 1 } } },
          openapi => '3.0.3'));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => { n => undef });
      return $ok ? 1 : 0;
  } },

# ------------------------------------------------------------ Security Schemes
(map {
    my ($id, $scheme, $ok_expected) = @$_;
    { id => "security/$id", section => '4.27 Security Scheme Object',
      requirement => "a $id security scheme is supported",
      run => sub {
          my $got = loads(doc(components => { securitySchemes => { S => $scheme } },
                              security => [ { S => [] } ]));
          return $got == $ok_expected ? 1 : 0;
      } };
} (
    [ 'apiKey',        { type => 'apiKey', name => 'k', in => 'header' },      1 ],
    [ 'http-basic',    { type => 'http', scheme => 'basic' },                  1 ],
    [ 'http-bearer',   { type => 'http', scheme => 'bearer' },                 1 ],
    [ 'http-digest',   { type => 'http', scheme => 'digest' },                 1 ],
    [ 'oauth2',        { type => 'oauth2', flows => {} },                      1 ],
    [ 'openIdConnect', { type => 'openIdConnect',
                         openIdConnectUrl => 'https://h.test/.well-known' },   1 ],
    [ 'mutualTLS',     { type => 'mutualTLS' },                                1 ],
)),

{ id => 'security/optional', section => '4.28 Security Requirement Object',
  requirement => 'an empty Security Requirement makes security optional',
  run => sub {
      loads(doc(components => { securitySchemes => {
                    K => { type => 'apiKey', name => 'k', in => 'header' } } },
                security => [ { K => [] }, {} ]));
  } },

# ---- Security Scheme structure ----------------------------------------------
#
# The compiler reads a scheme's `type` and, for apiKey, its `name`/`in`. What
# it does NOT read is whether the rest of the object is well formed, and the
# specification makes several of those REQUIRED. A document that is invalid
# should not compile: accepting it means the gateway trusts a declaration
# nobody checked.
#
# NOT tested here, deliberately: whether the library COMPARES scopes. The
# specification says a requirement's value is the list of scopes required, not
# who enforces them - handing them to the application's checker is a defensible
# reading, and a case asserting otherwise would be testing my preference.

{ id => 'security/oauth2-flows-required', section => '4.27 Security Scheme Object',
  requirement => 'flows is REQUIRED for an oauth2 scheme',
  run => sub {
      croaks(doc(components => { securitySchemes => {
                     S => { type => 'oauth2' } } },              # no flows
                 security => [ { S => [] } ]));
  } },

{ id => 'security/oauth2-flow-scopes', section => '4.29 OAuth Flow Object',
  requirement => 'scopes is REQUIRED within an OAuth flow',
  run => sub {
      croaks(doc(components => { securitySchemes => { S => {
                     type => 'oauth2',
                     flows => { clientCredentials => {
                         tokenUrl => 'https://h.test/token' } } } } },  # no scopes
                 security => [ { S => [] } ]));
  } },

{ id => 'security/oauth2-authcode-urls', section => '4.29 OAuth Flow Object',
  requirement => 'authorizationCode requires both authorizationUrl and tokenUrl',
  run => sub {
      croaks(doc(components => { securitySchemes => { S => {
                     type => 'oauth2',
                     flows => { authorizationCode => {
                         authorizationUrl => 'https://h.test/auth',
                         scopes => {} } } } } },                 # no tokenUrl
                 security => [ { S => [] } ]));
  } },

{ id => 'security/openIdConnect-url', section => '4.27 Security Scheme Object',
  requirement => 'openIdConnectUrl is REQUIRED for an openIdConnect scheme',
  run => sub {
      croaks(doc(components => { securitySchemes => {
                     S => { type => 'openIdConnect' } } },       # no URL
                 security => [ { S => [] } ]));
  } },

{ id => 'security/scopes-empty-for-non-oauth2', section => '4.28 Security Requirement',
  requirement => 'under 3.0 a scheme that is not oauth2 or openIdConnect MUST have an empty scope list',
  run => sub {
      croaks(doc(openapi => '3.0.3',
                 components => { securitySchemes => {
                     K => { type => 'apiKey', name => 'k', in => 'header' } } },
                 security => [ { K => [ 'read' ] } ]));          # not empty
  } },

{ id => 'security/roles-allowed-for-non-oauth2', section => '4.28 Security Requirement',
  requirement => '3.1 relaxed that: the array MAY carry role names for any scheme type',
  run => sub {
      loads(doc(components => { securitySchemes => {
                    K => { type => 'apiKey', name => 'k', in => 'header' } } },
                security => [ { K => [ 'read' ] } ]));
  } },

{ id => 'security/unknown-scheme', section => '4.28 Security Requirement',
  requirement => 'a requirement naming a scheme that is not declared is an error',
  run => sub {
      croaks(doc(components => { securitySchemes => {
                     K => { type => 'apiKey', name => 'k', in => 'header' } } },
                 security => [ { Nope => [] } ]));
  } },

{ id => 'security/scopes-reach-checker', section => '4.28 Security Requirement',
  requirement => 'the declared scopes are given to the security check',
  run => sub {
      my ($a) = api(doc(
          components => { securitySchemes => { S => { type => 'oauth2',
              flows => { clientCredentials => { tokenUrl => 'https://h.test/t',
                                                scopes => { read => 'r' } } } } } },
          paths => { '/t' => { get => { operationId => 'op',
              security  => [ { S => [ 'read', 'write' ] } ],
              responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      my @got;
      $a->check_op_security('op', { HTTP_AUTHORIZATION => 'Bearer t' },
                            { S => sub { @got = @{ $_[3] || [] }; 1 } });
      return "@got" eq 'read write' ? 1 : 0;
  } },

# ---- Media Type and Encoding -------------------------------------------------

{ id => 'mediatype/example-xor-examples', section => '4.12 Media Type Object',
  requirement => 'example and examples are mutually exclusive',
  run => sub {
      croaks(op_doc(method => 'post',
          requestBody => { required => 1, content => { 'application/json' => {
              schema   => { type => 'object' },
              example  => { a => 1 },
              examples => { one => { value => { a => 1 } } } } } }));
  } },

{ id => 'mediatype/encoding-explode', section => '4.13 Encoding Object',
  requirement => 'an encoding style and explode govern how a form property is serialized',
  run => sub {
      # `a` is a list serialized with explode: the form carries repeat keys.
      # Without encoding honoured for style, a=1&a=2 still collapses per the
      # schema alone, so the discriminating case is explode => false, where
      # ONE comma-separated value must become a list.
      my ($a) = api(op_doc(method => 'post',
          requestBody => { required => 1, content => {
            'application/x-www-form-urlencoded' => {
              schema   => { type => 'object', properties => {
                             a => { type => 'array',
                                    items => { type => 'string' } } } },
              encoding => { a => { style => 'form', explode => \0 } } } } }));
      return 0 unless $a;
      my ($ok, $res) = req($a,
          header => { 'content-type' => 'application/x-www-form-urlencoded' },
          body   => 'a=x,y');
      return 0 unless $ok;
      my $v = $res->{body}{a};
      return ref $v eq 'ARRAY' && @$v == 2 ? 1 : 0;
  } },

{ id => 'mediatype/encoding-headers', section => '4.13 Encoding Object',
  requirement => 'an encoding may declare headers for a multipart part',
  run => sub {
      my ($a) = api(op_doc(method => 'post',
          requestBody => { required => 1, content => { 'multipart/form-data' => {
              schema   => { type => 'object',
                            properties => { a => { type => 'string' } } },
              encoding => { a => { headers => { 'X-P' => {
                              required => 1,
                              schema => { type => 'string' } } } } } } } }));
      return 0 unless $a;
      # a part MISSING its required encoding header must be refused
      my $B = join '', map { "$_\r\n" }
          '--xx', 'Content-Disposition: form-data; name="a"', '', 'v', '--xx--';
      my ($ok) = req($a,
          header => { 'content-type' => 'multipart/form-data; boundary=xx' },
          body   => $B);
      return $ok ? 0 : 1;
  } },

# ---- Responses ---------------------------------------------------------------

{ id => 'response/description-required', section => '4.11 Response Object',
  requirement => 'description is REQUIRED on a Response Object',
  run => sub {
      croaks(op_doc(responses => { 200 => {} }));               # no description
  } },

{ id => 'responses/default-selected', section => '4.7 Responses Object',
  requirement => 'the default response is used when no status or range matches',
  run => sub {
      my ($a) = api(op_doc(responses => { default => { description => 'any',
          content => { 'application/json' => { schema => {
              type => 'object', required => ['ok'],
              properties => { ok => { type => 'boolean' } } } } } } }));
      return 0 unless $a;
      my $errs = $a->check_response('op',
          [ 418, [ 'Content-Type' => 'application/json' ], [ '{"wrong":1}' ] ]);
      return (ref $errs eq 'ARRAY' && @$errs) ? 1 : 0;
  } },

(map {
    my ($cls, $status) = @$_;
    { id => "responses/range-$cls", section => '4.7 Responses Object',
      requirement => "a $cls range covers status $status",
      run => sub {
          # the range is SELECTED and APPLIED, not merely compiled: a body
          # that violates the schema must produce errors
          my ($a) = api(op_doc(responses => { $cls => { description => 'r',
              content => { 'application/json' => { schema => {
                  type => 'object', required => ['ok'],
                  properties => { ok => { type => 'boolean' } } } } } } }));
          return 0 unless $a;
          my $errs = $a->check_response('op',
              [ $status, [ 'Content-Type' => 'application/json' ],
                [ '{"wrong":1}' ] ]);
          return (ref $errs eq 'ARRAY' && @$errs) ? 1 : 0;
      } };
} ( [ '1XX', 102 ], [ '2XX', 200 ], [ '3XX', 302 ],
    [ '4XX', 404 ], [ '5XX', 503 ] )),

# ---- Info, License, Contact, Tag ---------------------------------------------

{ id => 'info/title-required', section => '4.2 Info Object',
  requirement => 'title is REQUIRED',
  run => sub { croaks(doc(info => { version => '1.0.0' })) } },

{ id => 'info/version-required', section => '4.2 Info Object',
  requirement => 'version is REQUIRED',
  run => sub { croaks(doc(info => { title => 'T' })) } },

{ id => 'info/license-name-required', section => '4.4 License Object',
  requirement => 'name is REQUIRED on a License Object',
  run => sub {
      croaks(doc(info => { title => 'T', version => '1.0.0',
                           license => { url => 'https://h.test/l' } }));
  } },

{ id => 'info/license-identifier-xor-url', section => '4.4 License Object',
  requirement => '3.1: identifier and url are mutually exclusive',
  run => sub {
      croaks(doc(info => { title => 'T', version => '1.0.0',
                           license => { name => 'MIT', identifier => 'MIT',
                                        url => 'https://h.test/l' } }));
  } },

{ id => 'tag/name-required', section => '4.6 Tag Object',
  requirement => 'name is REQUIRED on a Tag Object',
  run => sub { croaks(doc(tags => [ { description => 'no name' } ])) } },

# ---- servers at other levels -------------------------------------------------

{ id => 'pathitem/servers', section => '4.5 Path Item Object',
  requirement => 'a Path Item may declare its own servers',
  run => sub {
      my ($a) = api(doc(paths => { '/pets' => {
              servers => [ { url => 'https://h.test/api' } ],
              get => { operationId => 'p',
                       responses => { 200 => { description => 'ok' } } } } }),
                    servers => 1);
      return 0 unless $a;
      my ($id) = $a->match(GET => '/api/pets');
      return defined $id ? 1 : 0;
  } },

{ id => 'operation/servers', section => '4.6 Operation Object',
  requirement => 'an Operation may declare its own servers',
  run => sub {
      my ($a) = api(doc(paths => { '/pets' => { get => {
              operationId => 'p',
              servers => [ { url => 'https://h.test/api' } ],
              responses => { 200 => { description => 'ok' } } } } }),
                    servers => 1);
      return 0 unless $a;
      my ($id) = $a->match(GET => '/api/pets');
      return defined $id ? 1 : 0;
  } },

# ---- path templating ---------------------------------------------------------

{ id => 'pathitem/template-uniqueness', section => '4.5 Paths Object',
  requirement => 'two paths differing only in template variable names are the same path',
  run => sub {
      croaks(doc(paths => {
          '/t/{a}' => { get => { operationId => 'x',
                                 responses => { 200 => { description => 'ok' } } } },
          '/t/{b}' => { get => { operationId => 'y',
                                 responses => { 200 => { description => 'ok' } } } },
      }));
  } },

# ---- Link and Callback runtime expressions -----------------------------------

{ id => 'link/operationId-resolves', section => '4.15 Link Object',
  requirement => 'a Link naming an operationId must name one that exists',
  run => sub {
      croaks(op_doc(responses => { 200 => { description => 'ok',
          links => { self => { operationId => 'no_such_operation' } } } }));
  } },

# WITHDRAWN: a case asserting that a callback key which is not a runtime
# expression is refused. The specification describes those keys as runtime
# expressions, but I could not satisfy myself it makes a malformed key a
# document error in those words - and a catalogue must not contain
# requirements its author cannot point at in the text. Restore it with a
# citation if one exists.

# ---- Link Object -------------------------------------------------------------

{ id => 'link/operationRef-xor-operationId', section => '4.15 Link Object',
  requirement => 'operationRef is mutually exclusive of operationId',
  run => sub {
      croaks(op_doc(responses => { 200 => { description => 'ok',
          links => { self => { operationId  => 'op',
                               operationRef => '#/paths/~1t/get' } } } }));
  } },

{ id => 'link/runtime-expressions-accepted', section => '4.15 / Runtime Expressions',
  requirement => 'a Link may carry runtime expressions, and a document using them loads',
  run => sub {
      # This library does not EVALUATE runtime expressions - nothing follows a
      # link - so the requirement that bites is the other one: it must not
      # refuse a document that uses them.
      loads(doc(paths => { '/t/{id}' => { get => {
          operationId => 'op',
          parameters  => [ { name => 'id', in => 'path', required => 1,
                             schema => { type => 'string' } } ],
          responses   => { 200 => { description => 'ok',
              links => { next => {
                  operationId => 'op',
                  parameters  => { id => '$response.body#/nextId',
                                   tok => '$request.header.X-Token' },
                  requestBody => '$request.body#/payload' } } } } } } }));
  } },

{ id => 'link/ref-to-components', section => '4.3 / 4.15 Link Object',
  requirement => 'a $ref may stand in for a Link Object',
  run => sub {
      my ($a) = api(doc(
          paths => { '/t' => { get => { operationId => 'op',
              responses => { 200 => { description => 'ok',
                  links => { self => { '$ref' => '#/components/links/Self' } } } } } } },
          components => { links => { Self => { operationId => 'op' } } }));
      return 0 unless $a;
      my $l = $a->spec->{paths}{'/t'}{get}{responses}{200}{links}{self};
      return !exists $l->{'$ref'} && ($l->{operationId} || '') eq 'op' ? 1 : 0;
  } },

# ---- Tag Object --------------------------------------------------------------

{ id => 'tag/names-unique', section => '4.6 Tag Object',
  requirement => 'each tag name in the list MUST be unique',
  run => sub {
      croaks(doc(tags => [ { name => 'pets' }, { name => 'pets' } ]));
  } },

{ id => 'tag/externalDocs-url', section => '4.7 External Documentation Object',
  requirement => 'url is REQUIRED on an External Documentation Object',
  run => sub {
      croaks(doc(tags => [ { name => 'pets',
                             externalDocs => { description => 'no url' } } ]));
  } },

# ---- Example, Media Type, Encoding -------------------------------------------

{ id => 'mediatype/example-value-xor-externalValue', section => '4.16 Example Object',
  requirement => 'value and externalValue are mutually exclusive',
  run => sub {
      croaks(op_doc(method => 'post',
          requestBody => { required => 1, content => { 'application/json' => {
              schema   => { type => 'object' },
              examples => { one => { value => { a => 1 },
                                     externalValue => 'https://h.test/e' } } } } }));
  } },

{ id => 'mediatype/encoding-headers-ignored-off-multipart', section => '4.13 Encoding Object',
  requirement => 'encoding headers SHALL be ignored when the body is not multipart',
  run => sub {
      # the same declaration that refuses a multipart part must NOT refuse a
      # urlencoded body, which carries no parts to hold headers
      my ($a) = api(op_doc(method => 'post',
          requestBody => { required => 1, content => {
            'application/x-www-form-urlencoded' => {
              schema   => { type => 'object',
                            properties => { a => { type => 'string' } } },
              encoding => { a => { headers => { 'X-P' => {
                              required => 1,
                              schema => { type => 'string' } } } } } } } }));
      return 0 unless $a;
      my ($ok) = req($a,
          header => { 'content-type' => 'application/x-www-form-urlencoded' },
          body   => 'a=v');
      return $ok ? 1 : 0;
  } },

# ---- Parameter ---------------------------------------------------------------

{ id => 'parameter/example-xor-examples', section => '4.10 Parameter Object',
  requirement => 'example and examples are mutually exclusive on a parameter',
  run => sub {
      croaks(doc(paths => { '/t' => { get => { operationId => 'op',
          parameters => [ { name => 'v', in => 'query',
                            schema   => { type => 'string' },
                            example  => 'a',
                            examples => { one => { value => 'a' } } } ],
          responses => { 200 => { description => 'ok' } } } } }));
  } },

{ id => 'parameter/content-one-entry', section => '4.10 Parameter Object',
  requirement => 'a parameter content map MUST contain only one entry',
  run => sub {
      croaks(doc(paths => { '/t' => { get => { operationId => 'op',
          parameters => [ { name => 'v', in => 'query', content => {
              'application/json' => { schema => { type => 'object' } },
              'application/xml'  => { schema => { type => 'object' } } } } ],
          responses => { 200 => { description => 'ok' } } } } }));
  } },

{ id => 'parameter/header-object-no-name-in', section => '4.14 Header Object',
  requirement => 'a Header Object MUST NOT specify name or in',
  run => sub {
      croaks(op_doc(responses => { 200 => { description => 'ok',
          headers => { 'X-H' => { name => 'X-H', in => 'header',
                                  schema => { type => 'string' } } } } }));
  } },

# ---- Paths, Components, Server Variables -------------------------------------

{ id => 'pathitem/path-starts-with-slash', section => '4.5 Paths Object',
  requirement => 'a path field name MUST begin with a forward slash',
  run => sub {
      croaks(doc(paths => { 'nope' => { get => { operationId => 'op',
          responses => { 200 => { description => 'ok' } } } } }));
  } },

{ id => 'components/key-pattern', section => '4.9 Components Object',
  requirement => 'component keys MUST match ^[a-zA-Z0-9\.\-_]+$',
  run => sub {
      croaks(doc(components => { schemas => {
          'not a valid key!' => { type => 'string' } } }));
  } },

{ id => 'openapi/server-variable-default-required', section => '4.5 Server Variable',
  requirement => 'default is REQUIRED on a Server Variable',
  run => sub {
      croaks(doc(servers => [ { url => 'https://{host}/v1',
                                variables => { host => { enum => ['h.test'] } } } ]));
  } },

{ id => 'openapi/server-variable-default-in-enum', section => '4.5 Server Variable',
  requirement => 'when enum is given, default MUST be one of its values',
  run => sub {
      croaks(doc(servers => [ { url => 'https://{host}/v1',
                                variables => { host => {
                                    enum => [ 'a.test', 'b.test' ],
                                    default => 'nowhere.test' } } } ]));
  } },

# ---- Callback Object ---------------------------------------------------------

{ id => 'callback/accepted', section => '4.17 Callback Object',
  requirement => 'an operation MAY carry callbacks, a map of runtime expression to Path Item',
  run => sub {
      loads(op_doc(method => 'post', callbacks => {
          onData => { '{$request.body#/callbackUrl}' => {
              post => { operationId => 'cb',
                        responses => { 200 => { description => 'ok' } } } } } }));
  } },

{ id => 'callback/not-routed', section => '4.17 Callback Object',
  requirement => 'a callback describes a request the API SENDS, so it is not a server route',
  run => sub {
      my ($a) = api(op_doc(method => 'post', callbacks => {
          onData => { '{$request.body#/callbackUrl}' => {
              post => { operationId => 'cb',
                        responses => { 200 => { description => 'ok' } } } } } }));
      return 0 unless $a;
      # the operation at /t is the only route; the callback adds none
      return scalar(@{ $a->operations }) == 1;
  } },

{ id => 'callback/pathitem-normalised', section => '4.17 Callback Object',
  requirement => 'a 3.0 schema inside a callback is converted like any other',
  run => sub {
      my ($a) = api(op_doc(openapi => '3.0.3', method => 'post', callbacks => {
          onData => { '{$request.body#/callbackUrl}' => {
              post => { operationId => 'cb',
                  requestBody => { content => { 'application/json' => {
                      schema => { type => 'string', nullable => 1 } } } },
                  responses => { 200 => { description => 'ok' } } } } } }));
      return 0 unless $a;
      my $s = $a->spec->{paths}{'/t'}{post}{callbacks}{onData}
                  {'{$request.body#/callbackUrl}'}{post}
                  {requestBody}{content}{'application/json'}{schema};
      return 0 unless ref $s eq 'HASH';
      # nullable is a 3.0 spelling; after conversion the type is a union
      return (ref $s->{type} eq 'ARRAY'
              && grep { $_ eq 'null' } @{ $s->{type} }) ? 1 : 0;
  } },

{ id => 'callback/ref-to-components', section => '4.17 Callback Object',
  requirement => 'a $ref may stand in for a Callback Object',
  run => sub {
      loads(op_doc(method => 'post',
          callbacks  => { onData => { '$ref' => '#/components/callbacks/C' } },
          components => { callbacks => { C => {
              '{$request.body#/callbackUrl}' => {
                  post => { operationId => 'cb',
                            responses => { 200 => { description => 'ok' } } } } } } }));
  } },

# ---- XML Object --------------------------------------------------------------

{ id => 'xml/accepted', section => '4.26 XML Object',
  requirement => 'a schema MAY carry an xml object',
  run => sub {
      loads(json_body_op({ type => 'object',
          xml => { name => 'thing', namespace => 'https://x.test/ns',
                   prefix => 't', attribute => 0, wrapped => 0 },
          properties => { a => { type => 'string' } } }));
  } },

{ id => 'xml/namespace-absolute', section => '4.26 XML Object',
  requirement => 'the xml namespace MUST be in the form of an absolute URI',
  run => sub {
      croaks(json_body_op({ type => 'object',
          xml => { name => 'thing', namespace => '/relative/ns' },
          properties => { a => { type => 'string' } } }));
  } },

{ id => 'xml/annotation-only', section => '4.26 XML Object',
  requirement => 'xml is an annotation and MUST NOT affect JSON validation',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object',
          required   => ['a'],
          xml        => { name => 'thing', attribute => 1, wrapped => 1 },
          properties => { a => { type => 'string', xml => { attribute => 1 } } } }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => '{"a":"v"}');
      return $ok ? 1 : 0;
  } },

# ---- Discriminator Object ----------------------------------------------------

{ id => 'discriminator/propertyName-required', section => '4.25 Discriminator Object',
  requirement => 'propertyName is REQUIRED on a Discriminator Object',
  run => sub {
      croaks(json_body_op({
          oneOf => [ { type => 'object', properties => { a => { type => 'string' } } },
                     { type => 'object', properties => { b => { type => 'string' } } } ],
          discriminator => { mapping => { x => '#/components/schemas/A' } } }));
  } },

{ id => 'discriminator/requires-composite', section => '4.25 Discriminator Object',
  # The spec says "legal only when using one of the composite keywords", but
  # its OWN inheritance example carries none of them and finds the children by
  # their allOf $ref back to the base. So the requirement encoded here is the
  # one both readings agree on: a discriminator that selects NOTHING.
  requirement => 'a discriminator beside no composite keyword, that nothing inherits from, is refused',
  run => sub {
      croaks(json_body_op({ type => 'object',
          properties    => { petType => { type => 'string' } },
          discriminator => { propertyName => 'petType' } }));
  } },

{ id => 'discriminator/branch-constraints-bind', section => '4.25 Discriminator Object',
  requirement => 'the mapped branch is applied, so its own required fields are enforced',
  run => sub {
      my ($a) = api(json_body_op(
          { oneOf => [ { '$ref' => '#/components/schemas/Dog' },
                       { '$ref' => '#/components/schemas/Cat' } ],
            discriminator => { propertyName => 'petType',
                               mapping => { dog => '#/components/schemas/Dog',
                                            cat => '#/components/schemas/Cat' } } },
          components => { schemas => {
              Dog => { type => 'object', required => [ 'petType', 'bark' ],
                       properties => { petType => { type => 'string' },
                                       bark    => { type => 'string' } } },
              Cat => { type => 'object', required => [ 'petType', 'meow' ],
                       properties => { petType => { type => 'string' },
                                       meow    => { type => 'string' } } } } }));
      return 0 unless $a;
      # says dog, but carries the cat property: the dog branch requires bark
      my ($ok) = req($a, header => $JSON, body => '{"petType":"dog","meow":"m"}');
      return $ok ? 0 : 1;
  } },

{ id => 'discriminator/unknown-value-refused', section => '4.25 Discriminator Object',
  requirement => 'a discriminating value with no mapping does not select a branch',
  run => sub {
      my ($a) = api(json_body_op(
          { oneOf => [ { '$ref' => '#/components/schemas/Dog' },
                       { '$ref' => '#/components/schemas/Cat' } ],
            discriminator => { propertyName => 'petType',
                               mapping => { dog => '#/components/schemas/Dog',
                                            cat => '#/components/schemas/Cat' } } },
          components => { schemas => {
              Dog => { type => 'object', required => [ 'petType' ],
                       properties => { petType => { type => 'string' } } },
              Cat => { type => 'object', required => [ 'petType' ],
                       properties => { petType => { type => 'string' } } } } }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => '{"petType":"lizard"}');
      return $ok ? 0 : 1;
  } },

# ---- Encoding Object ---------------------------------------------------------

{ id => 'encoding/only-on-form-media', section => '4.16 Encoding Object',
  requirement => 'encoding MAY only be used where the media type is multipart or x-www-form-urlencoded',
  run => sub {
      croaks(op_doc(method => 'post', requestBody => { content => {
          'application/json' => {
              schema   => { type => 'object',
                            properties => { a => { type => 'string' } } },
              encoding => { a => { contentType => 'text/plain' } } } } }));
  } },

{ id => 'encoding/property-must-exist', section => '4.16 Encoding Object',
  requirement => 'an encoding key MUST exist as a property in the schema',
  run => sub {
      croaks(op_doc(method => 'post', requestBody => { content => {
          'application/x-www-form-urlencoded' => {
              schema   => { type => 'object',
                            properties => { a => { type => 'string' } } },
              encoding => { nosuch => { contentType => 'text/plain' } } } } }));
  } },

# ---- Example Object ----------------------------------------------------------

{ id => 'example/ref-to-components', section => '4.15 Example Object',
  requirement => 'a $ref may stand in for an Example Object',
  run => sub {
      loads(op_doc(method => 'post',
          requestBody => { content => { 'application/json' => {
              schema   => { type => 'string' },
              examples => { one => { '$ref' => '#/components/examples/E' } } } } },
          components  => { examples => { E => { summary => 's', value => 'v' } } }));
  } },

{ id => 'example/value-xor-externalValue', section => '4.15 Example Object',
  requirement => 'value and externalValue are mutually exclusive, in any position',
  run => sub {
      croaks(op_doc(method => 'post',
          requestBody => { content => { 'application/json' => {
              schema   => { type => 'string' },
              examples => { one => { value => 'v',
                                     externalValue => 'https://x.test/e' } } } } }));
  } },

# ---- Header Object -----------------------------------------------------------

{ id => 'header/style-simple-only', section => '4.14 Header Object',
  requirement => 'a header is serialized with style simple; another style is not legal',
  run => sub {
      croaks(op_doc(responses => { 200 => { description => 'ok',
          headers => { 'X-H' => { style  => 'form',
                                  schema => { type => 'string' } } } } }));
  } },

{ id => 'header/ref-to-components', section => '4.14 Header Object',
  requirement => 'a $ref may stand in for a Header Object',
  run => sub {
      loads(op_doc(responses => { 200 => { description => 'ok',
              headers => { 'X-H' => { '$ref' => '#/components/headers/H' } } } },
          components => { headers => { H => { schema => { type => 'string' } } } }));
  } },

# ---- Contact, Server, External Documentation ---------------------------------

{ id => 'info/contact-email-format', section => '4.3 Contact Object',
  requirement => 'contact email MUST be in the format of an email address',
  run => sub {
      my $d = doc();
      $d->{info}{contact} = { name => 'C', email => 'not-an-email' };
      croaks($d);
  } },

{ id => 'info/contact-url-format', section => '4.3 Contact Object',
  requirement => 'contact url MUST be in the format of a URL',
  run => sub {
      my $d = doc();
      $d->{info}{contact} = { name => 'C', url => 'not a url' };
      croaks($d);
  } },

{ id => 'openapi/server-url-required', section => '4.5 Server Object',
  requirement => 'url is REQUIRED on a Server Object',
  run => sub { croaks(doc(servers => [ { description => 'no url here' } ])) } },

{ id => 'openapi/externalDocs-url-required', section => '4.12 External Documentation',
  requirement => 'url is REQUIRED on External Documentation, at the root too',
  run => sub { croaks(doc(externalDocs => { description => 'no url' })) } },

{ id => 'operation/externalDocs-url-required', section => '4.12 External Documentation',
  requirement => 'url is REQUIRED on External Documentation, on an operation too',
  run => sub {
      # built by hand: op_doc hoists externalDocs to the document root, which
      # is the case above, not this one
      croaks(doc(paths => { '/t' => { get => {
          operationId  => 'op',
          externalDocs => { description => 'no url' },
          responses    => { 200 => { description => 'ok' } } } } }));
  } },

# ---- Components --------------------------------------------------------------

{ id => 'components/key-pattern-every-map', section => '4.9 Components Object',
  requirement => 'the component key pattern applies to every typed map, not only schemas',
  run => sub {
      croaks(doc(components => { securitySchemes => {
          'not a valid key!' => { type => 'apiKey', name => 'k', in => 'header' } } }));
  } },

{ id => 'components/pathItems-accepted', section => '4.9 Components Object',
  requirement => '3.1 adds components.pathItems',
  run => sub {
      loads(doc(components => { pathItems => { P => {
          get => { operationId => 'p',
                   responses => { 200 => { description => 'ok' } } } } } }));
  } },

# ---- depth in the objects that had only their core requirement pinned --------

{ id => 'encoding/style-splits-a-property', section => '4.16 Encoding Object',
  requirement => 'an encoding style applies to its property in a urlencoded body',
  run => sub {
      my ($a) = api(op_doc(method => 'post', requestBody => { required => \1,
          content => { 'application/x-www-form-urlencoded' => {
              schema   => { type => 'object', properties => {
                  tags => { type => 'array', items => { type => 'string' } } } },
              encoding => { tags => { style => 'form', explode => \0 } } } } }));
      return 0 unless $a;
      my ($ok, $res) = req($a,
          header => { 'content-type' => 'application/x-www-form-urlencoded' },
          body   => 'tags=a,b');
      return 0 unless $ok;
      return eq_deeply_ish($res->{body}{tags}, [ 'a', 'b' ]);
  } },

{ id => 'encoding/allowReserved-off-multipart', section => '4.16 Encoding Object',
  requirement => 'allowReserved is a urlencoded concern and does not refuse a multipart body',
  run => sub {
      my ($a) = api(op_doc(method => 'post', requestBody => { required => \1,
          content => { 'multipart/form-data' => {
              schema   => { type => 'object',
                            properties => { a => { type => 'string' } } },
              encoding => { a => { allowReserved => \1 } } } } }));
      return $a ? 1 : 0;
  } },

{ id => 'example/summary-and-description', section => '4.15 Example Object',
  requirement => 'an Example may carry summary and description beside its value',
  run => sub {
      loads(op_doc(method => 'post', requestBody => { content => {
          'application/json' => { schema => { type => 'string' },
              examples => { one => { summary => 's', description => 'd',
                                     value => 'v' } } } } }));
  } },

{ id => 'example/externalValue-alone', section => '4.15 Example Object',
  requirement => 'externalValue is legal on its own',
  run => sub {
      loads(op_doc(method => 'post', requestBody => { content => {
          'application/json' => { schema => { type => 'string' },
              examples => { one => {
                  externalValue => 'https://x.test/e.json' } } } } }));
  } },

{ id => 'header/required-request-header', section => '4.10 Parameter Object',
  requirement => 'a required header parameter that is absent is refused',
  run => sub {
      my ($a) = api(op_doc(parameters => [ { name => 'X-H', in => 'header',
          required => \1, schema => { type => 'string' } } ]));
      return 0 unless $a;
      my ($absent) = req($a, header => {});
      my ($given)  = req($a, header => { 'x-h' => 'v' });
      return (!$absent && $given) ? 1 : 0;
  } },

{ id => 'header/array-comma-separated', section => '4.14 Header Object',
  requirement => 'a header carrying an array is comma separated, per style simple',
  run => sub {
      my ($a) = api(op_doc(parameters => [ { name => 'X-H', in => 'header',
          schema => { type => 'array', items => { type => 'string' } } } ]));
      return 0 unless $a;
      my ($ok, $res) = req($a, header => { 'x-h' => 'a,b,c' });
      return 0 unless $ok;
      return eq_deeply_ish($res->{header}{'X-H'}, [ 'a', 'b', 'c' ]);
  } },

{ id => 'xml/on-a-property', section => '4.26 XML Object',
  requirement => 'an xml object on a property is carried and changes nothing',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object', required => ['a'],
          properties => { a => { type => 'string',
                                 xml => { name => 'A', attribute => \1 } } } }));
      return 0 unless $a;
      my ($good) = req($a, header => $JSON, body => '{"a":"v"}');
      my ($bad)  = req($a, header => $JSON, body => '{}');
      return ($good && !$bad) ? 1 : 0;
  } },

{ id => 'callback/multiple-expressions', section => '4.17 Callback Object',
  requirement => 'a callback may declare more than one runtime expression',
  run => sub {
      loads(op_doc(method => 'post', callbacks => { onData => {
          '{$request.body#/a}' => { post => { operationId => 'c1',
              responses => { 200 => { description => 'ok' } } } },
          '{$request.body#/b}' => { post => { operationId => 'c2',
              responses => { 200 => { description => 'ok' } } } } } }));
  } },

{ id => 'callback/components-key-pattern', section => '4.9 Components Object',
  requirement => 'the component key pattern covers components.callbacks',
  run => sub {
      croaks(doc(components => { callbacks => {
          'not a key!' => { '{$request.body#/u}' => { post => {
              operationId => 'c',
              responses => { 200 => { description => 'ok' } } } } } } }));
  } },

{ id => 'discriminator/mapping-implicit-name', section => '4.25 Discriminator Object',
  requirement => 'a mapping value may be a bare schema name, not only a $ref',
  run => sub {
      my ($a) = api(json_body_op(
          { oneOf => [ { '$ref' => '#/components/schemas/Dog' },
                       { '$ref' => '#/components/schemas/Cat' } ],
            discriminator => { propertyName => 'petType',
                               mapping => { dog => 'Dog', cat => 'Cat' } } },
          components => { schemas => {
              Dog => { type => 'object', required => [ 'petType', 'bark' ],
                       properties => { petType => { type => 'string' },
                                       bark    => { type => 'string' } } },
              Cat => { type => 'object', required => [ 'petType', 'meow' ],
                       properties => { petType => { type => 'string' },
                                       meow    => { type => 'string' } } } } }));
      return 0 unless $a;
      my ($bad)  = req($a, header => $JSON, body => '{"petType":"dog","meow":"m"}');
      my ($good) = req($a, header => $JSON, body => '{"petType":"dog","bark":"w"}');
      return (!$bad && $good) ? 1 : 0;
  } },

{ id => 'discriminator/with-anyOf', section => '4.25 Discriminator Object',
  requirement => 'a discriminator is legal beside anyOf, not only oneOf',
  run => sub {
      my ($a) = api(json_body_op(
          { anyOf => [ { '$ref' => '#/components/schemas/Dog' },
                       { '$ref' => '#/components/schemas/Cat' } ],
            discriminator => { propertyName => 'petType',
                               mapping => { dog => '#/components/schemas/Dog',
                                            cat => '#/components/schemas/Cat' } } },
          components => { schemas => {
              Dog => { type => 'object', required => [ 'petType', 'bark' ],
                       properties => { petType => { type => 'string' },
                                       bark    => { type => 'string' } } },
              Cat => { type => 'object', required => [ 'petType', 'meow' ],
                       properties => { petType => { type => 'string' },
                                       meow    => { type => 'string' } } } } }));
      return 0 unless $a;
      my ($bad) = req($a, header => $JSON, body => '{"petType":"dog","meow":"m"}');
      return $bad ? 0 : 1;
  } },

{ id => 'components/every-section-accepted', section => '4.9 Components Object',
  requirement => 'all ten typed component maps are recognised',
  run => sub {
      loads(doc(components => {
          schemas         => { S => { type => 'string' } },
          responses       => { R => { description => 'ok' } },
          parameters      => { P => { name => 'p', in => 'query',
                                      schema => { type => 'string' } } },
          examples        => { E => { value => 'v' } },
          requestBodies   => { B => { content => { 'application/json' => {
                                        schema => { type => 'string' } } } } },
          headers         => { H => { schema => { type => 'string' } } },
          securitySchemes => { K => { type => 'apiKey', name => 'k',
                                      in => 'header' } },
          links           => { L => { operationRef => '#/paths/~1t/get' } },
          callbacks       => { C => { '{$request.body#/u}' => { post => {
                                  operationId => 'cb',
                                  responses => { 200 => { description => 'ok' } } } } } },
          pathItems       => { I => { get => { operationId => 'pi',
                                  responses => { 200 => { description => 'ok' } } } } },
      }));
  } },

{ id => 'components/unreferenced-is-fine', section => '4.9 Components Object',
  requirement => 'a component nothing references is not an error',
  run => sub {
      loads(op_doc(components => { schemas => {
          Unused => { type => 'object',
                      properties => { x => { type => 'string' } } } } }));
  } },

{ id => 'tag/operation-tag-need-not-be-declared', section => '4.4 Operation Object',
  requirement => 'an operation may name a tag the root does not declare',
  run => sub {
      # built by hand: op_doc hoists `tags` to the document root, where a bare
      # string is not a Tag Object and is skipped - the case would assert
      # nothing at all
      my ($a) = api(doc(paths => { '/t' => { get => {
          operationId => 'op',
          tags        => [ 'undeclared' ],
          responses   => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      # and it really is on the operation, not the document
      my $t = $a->spec->{paths}{'/t'}{get}{tags};
      return (ref $t eq 'ARRAY' && @$t && $t->[0] eq 'undeclared') ? 1 : 0;
  } },

# ---- the request body, both directions ---------------------------------------
#
# The same two-sided contract the styles have. The client used to JSON-encode
# every body and label it `application/json` whatever the document declared, so
# an operation declaring only a form body sent JSON and this library's own
# server answered 415: a client and a server built from one document could not
# talk to each other.

{ id => 'clientbody/json-declared', section => '4.11 Request Body Object',
  requirement => 'a declared JSON body is sent as application/json',
  run => sub {
      my ($b, $ct) = body_for('application/json');
      return (defined $ct && $ct =~ m{^application/json}) ? 1 : 0;
  } },

{ id => 'clientbody/form-declared', section => '4.11 Request Body Object',
  requirement => 'a form-only operation sends x-www-form-urlencoded, not JSON',
  run => sub {
      my ($b, $ct) = body_for('application/x-www-form-urlencoded');
      return 0 unless defined $ct && defined $b;
      return ($ct =~ m{^application/x-www-form-urlencoded}
              && $b !~ /^\{/) ? 1 : 0;
  } },

{ id => 'clientbody/multipart-declared', section => '4.11 Request Body Object',
  requirement => 'a multipart-only operation sends multipart with a boundary',
  run => sub {
      my ($b, $ct) = body_for('multipart/form-data');
      return 0 unless defined $ct && defined $b;
      return ($ct =~ m{^multipart/form-data;\s*boundary=(\S+)}
              && index($b, $1) >= 0) ? 1 : 0;
  } },

{ id => 'clientbody/json-preferred', section => '4.11 Request Body Object',
  requirement => 'when several media types are declared, JSON is chosen',
  run => sub {
      my ($a) = api(op_doc(method => 'post', requestBody => { required => \1,
          content => {
              'application/x-www-form-urlencoded' => { schema => $BODY_SCHEMA },
              'application/json'                  => { schema => $BODY_SCHEMA } } }));
      return 0 unless $a;
      my $c = eval { Open::API::Client->new(api => $a, base_url => 'http://h.test') };
      return 0 unless $c;
      my (undef, $ct) = $c->_request_body('op', { body => { a => 'x' } });
      return (defined $ct && $ct =~ m{^application/json}) ? 1 : 0;
  } },

{ id => 'clientbody/missing-required', section => '4.11 Request Body Object',
  requirement => 'a required body the caller did not supply is refused, not sent empty',
  run => sub {
      my ($a) = api(op_doc(method => 'post', requestBody => { required => \1,
          content => { 'application/json' => { schema => $BODY_SCHEMA } } }));
      return 0 unless $a;
      my $c = eval { Open::API::Client->new(api => $a, base_url => 'http://h.test') };
      return 0 unless $c;
      my $sent = eval { my @r = $c->_request_body('op', {}); 1 };
      return $sent ? 0 : 1;
  } },

{ id => 'bodyroundtrip/json', section => '4.11 Request Body Object',
  requirement => 'a JSON body the client builds is accepted by the server',
  run => sub { body_round_trip('application/json') } },

{ id => 'bodyroundtrip/urlencoded', section => '4.11 Request Body Object',
  requirement => 'a form body the client builds is accepted by the server',
  run => sub { body_round_trip('application/x-www-form-urlencoded') } },

{ id => 'bodyroundtrip/multipart', section => '4.11 Request Body Object',
  requirement => 'a multipart body the client builds is accepted by the server',
  run => sub { body_round_trip('multipart/form-data') } },

# ---- the runtime surface -----------------------------------------------------
#
# Most of this catalogue asks whether a bad DOCUMENT is refused. These ask what
# the library is actually for: whether a request and a response are held to
# what the document declared.

{ id => 'response/body-validated', section => '4.7 Response Object',
  requirement => 'a response body that violates its schema is reported',
  run => sub {
      my ($a) = api(op_doc(responses => { 200 => { description => 'ok',
          content => { 'application/json' => { schema => {
              type => 'object', required => ['a'],
              properties => { a => { type => 'string' } } } } } } }));
      return 0 unless $a;
      my $errs = $a->check_response('op',
          [ 200, [ 'Content-Type', 'application/json' ], ['{"a":5}'] ]);
      return (ref $errs eq 'ARRAY' && @$errs) ? 1 : 0;
  } },

{ id => 'response/body-conforming-clean', section => '4.7 Response Object',
  requirement => 'a conforming response body reports nothing',
  run => sub {
      my ($a) = api(op_doc(responses => { 200 => { description => 'ok',
          content => { 'application/json' => { schema => {
              type => 'object', required => ['a'],
              properties => { a => { type => 'string' } } } } } } }));
      return 0 unless $a;
      my $errs = $a->check_response('op',
          [ 200, [ 'Content-Type', 'application/json' ], ['{"a":"v"}'] ]);
      return (!$errs || !@$errs) ? 1 : 0;
  } },

{ id => 'response/header-missing-reported', section => '4.7 Response Object',
  requirement => 'a required response header that is absent is reported',
  run => sub {
      my ($a) = api(op_doc(responses => { 200 => { description => 'ok',
          headers => { 'X-H' => { required => \1,
                                  schema => { type => 'string' } } } } }));
      return 0 unless $a;
      my $errs = $a->check_response('op', [ 200, [], [] ]);
      return (ref $errs eq 'ARRAY' && @$errs) ? 1 : 0;
  } },

{ id => 'response/header-present-clean', section => '4.7 Response Object',
  requirement => 'a declared response header that is present reports nothing',
  run => sub {
      my ($a) = api(op_doc(responses => { 200 => { description => 'ok',
          headers => { 'X-H' => { required => \1,
                                  schema => { type => 'string' } } } } }));
      return 0 unless $a;
      my $errs = $a->check_response('op', [ 200, [ 'X-H', 'v' ], [] ]);
      return (!$errs || !@$errs) ? 1 : 0;
  } },

{ id => 'security/and-within-one-requirement', section => '4.28 Security Requirement',
  requirement => 'two schemes in ONE requirement object must BOTH be satisfied',
  run => sub {
      my ($a) = api(doc(
          components => { securitySchemes => {
              A => { type => 'apiKey', name => 'X-A', in => 'header' },
              B => { type => 'apiKey', name => 'X-B', in => 'header' } } },
          paths => { '/t' => { get => { operationId => 'op',
              security  => [ { A => [], B => [] } ],
              responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      # check_op_security returns the DENIAL: undef means the request proceeds.
      # The credential is extracted from the env BEFORE the checker is called,
      # so both keys have to be present or nothing is ever weighed.
      my $env  = { HTTP_X_A => 'ka', HTTP_X_B => 'kb' };
      my $both = $a->check_op_security('op', $env,
          { A => sub { 1 }, B => sub { 1 } });
      my $half = $a->check_op_security('op', $env,
          { A => sub { 1 }, B => sub { 0 } });
      return (!$both && $half) ? 1 : 0;
  } },

{ id => 'security/or-across-requirements', section => '4.28 Security Requirement',
  requirement => 'two requirement objects are alternatives: either suffices',
  run => sub {
      my ($a) = api(doc(
          components => { securitySchemes => {
              A => { type => 'apiKey', name => 'X-A', in => 'header' },
              B => { type => 'apiKey', name => 'X-B', in => 'header' } } },
          paths => { '/t' => { get => { operationId => 'op',
              security  => [ { A => [] }, { B => [] } ],
              responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      # undef is "may proceed", so the SECOND alternative alone must admit it
      my $env     = { HTTP_X_A => 'ka', HTTP_X_B => 'kb' };
      my $second  = $a->check_op_security('op', $env,
          { A => sub { 0 }, B => sub { 1 } });
      my $neither = $a->check_op_security('op', $env,
          { A => sub { 0 }, B => sub { 0 } });
      return (!$second && $neither) ? 1 : 0;
  } },

{ id => 'pathitem/literal-beats-template', section => '4.5 Paths Object',
  requirement => 'a literal path segment wins over a template that also matches',
  run => sub {
      my ($a) = api(doc(paths => {
          '/t/{id}'  => { get => { operationId => 'by_id',
                          parameters => [ { name => 'id', in => 'path',
                                            required => \1,
                                            schema => { type => 'string' } } ],
                          responses => { 200 => { description => 'ok' } } } },
          '/t/fixed' => { get => { operationId => 'fixed',
                          responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      # match returns a LIST ($opId, $captures). In scalar context it yields
      # the CAPTURES, and `{id => 'fixed'}` then reads like a match on the
      # literal when it is in fact the template capturing it - a case that
      # passes for exactly the wrong reason.
      my ($literal)  = $a->match(GET => '/t/fixed');
      my ($templated) = $a->match(GET => '/t/other');
      return 0 unless defined $literal && defined $templated;
      return ($literal eq 'fixed' && $templated eq 'by_id') ? 1 : 0;
  } },

{ id => 'parameter/required-enforced', section => '4.10 Parameter Object',
  requirement => 'a required query parameter that is absent is refused',
  run => sub {
      my ($a) = api(op_doc(parameters => [ { name => 'q', in => 'query',
          required => \1, schema => { type => 'string' } } ]));
      return 0 unless $a;
      my ($absent) = req($a, query => '');
      my ($given)  = req($a, query => 'q=v');
      return (!$absent && $given) ? 1 : 0;
  } },

{ id => 'parameter/optional-absent-ok', section => '4.10 Parameter Object',
  requirement => 'an optional parameter that is absent is not an error',
  run => sub {
      my ($a) = api(op_doc(parameters => [ { name => 'q', in => 'query',
          schema => { type => 'string' } } ]));
      return 0 unless $a;
      my ($ok) = req($a, query => '');
      return $ok ? 1 : 0;
  } },

{ id => 'parameter/deprecated-still-accepted', section => '4.10 Parameter Object',
  requirement => 'deprecated marks a parameter, it does not disable it',
  run => sub {
      my ($a) = api(op_doc(parameters => [ { name => 'q', in => 'query',
          deprecated => \1, schema => { type => 'string' } } ]));
      return 0 unless $a;
      my ($ok) = req($a, query => 'q=v');
      return $ok ? 1 : 0;
  } },

{ id => 'requestbody/415-undeclared-type', section => '4.11 Request Body Object',
  requirement => 'a body whose media type the operation does not declare is refused',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object' }));
      return 0 unless $a;
      my ($ok) = req($a, header => { 'content-type' => 'application/xml' },
                         body => '<a/>');
      return $ok ? 0 : 1;
  } },

# ---- 3.0 against 3.1, one case per conversion rule ---------------------------
#
# A 3.0 document is converted to 3.1 shape at load, so every one of these has
# two halves: the 3.0 spelling must behave as 3.0 defines it, and the 3.1
# spelling of the same constraint must behave identically. A conversion that
# silently drops a constraint passes a shape test and fails these.

{ id => 'openapi30/nullable-accepts-null', section => '4.8.24 nullable (3.0)',
  requirement => 'nullable: true admits an explicit null',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object',
          properties => { a => { type => 'string', nullable => 1 } } },
          openapi => '3.0.3'));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => '{"a":null}');
      return $ok ? 1 : 0;
  } },

{ id => 'openapi30/not-nullable-refuses-null', section => '4.8.24 nullable (3.0)',
  requirement => 'without nullable, null is still refused',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object',
          properties => { a => { type => 'string' } } }, openapi => '3.0.3'));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => '{"a":null}');
      return $ok ? 0 : 1;
  } },

{ id => 'openapi30/nullable-keeps-its-type', section => '4.8.24 nullable (3.0)',
  requirement => 'nullable widens the type, it does not replace it',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object',
          properties => { a => { type => 'string', nullable => 1 } } },
          openapi => '3.0.3'));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => '{"a":5}');
      return $ok ? 0 : 1;   # a number is still not a string
  } },

{ id => 'openapi30/exclusive-minimum-boolean', section => '4.8.24 (3.0)',
  requirement => 'the 3.0 boolean exclusiveMinimum excludes the bound',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object', properties => {
          a => { type => 'integer', minimum => 5, exclusiveMinimum => \1 } } },
          openapi => '3.0.3'));
      return 0 unless $a;
      my ($lo) = req($a, header => $JSON, body => '{"a":5}');
      my ($hi) = req($a, header => $JSON, body => '{"a":6}');
      return (!$lo && $hi) ? 1 : 0;
  } },

{ id => 'openapi30/exclusive-minimum-false', section => '4.8.24 (3.0)',
  requirement => 'exclusiveMinimum: false leaves the bound inclusive',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object', properties => {
          a => { type => 'integer', minimum => 5, exclusiveMinimum => \0 } } },
          openapi => '3.0.3'));
      return 0 unless $a;
      my ($lo) = req($a, header => $JSON, body => '{"a":5}');
      return $lo ? 1 : 0;
  } },

{ id => 'openapi30/exclusive-maximum-boolean', section => '4.8.24 (3.0)',
  requirement => 'the 3.0 boolean exclusiveMaximum excludes the bound',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object', properties => {
          a => { type => 'integer', maximum => 5, exclusiveMaximum => \1 } } },
          openapi => '3.0.3'));
      return 0 unless $a;
      my ($hi) = req($a, header => $JSON, body => '{"a":5}');
      my ($lo) = req($a, header => $JSON, body => '{"a":4}');
      return (!$hi && $lo) ? 1 : 0;
  } },

{ id => 'openapi31/exclusive-minimum-numeric', section => '4.8.24 (3.1)',
  requirement => 'the 3.1 numeric exclusiveMinimum names the bound itself',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object', properties => {
          a => { type => 'integer', exclusiveMinimum => 5 } } }));
      return 0 unless $a;
      my ($lo) = req($a, header => $JSON, body => '{"a":5}');
      my ($hi) = req($a, header => $JSON, body => '{"a":6}');
      return (!$lo && $hi) ? 1 : 0;
  } },

{ id => 'openapi30/tuple-items', section => '4.8.24 items (3.0)',
  requirement => 'a 3.0 array items becomes positional prefixItems',
  run => sub {
      my ($a) = api(json_body_op({ type => 'array',
          items => [ { type => 'string' }, { type => 'integer' } ] },
          openapi => '3.0.3'));
      return 0 unless $a;
      my ($good) = req($a, header => $JSON, body => '["a",1]');
      my ($bad)  = req($a, header => $JSON, body => '[1,"a"]');
      return ($good && !$bad) ? 1 : 0;
  } },

{ id => 'openapi30/format-byte', section => '4.8.24 format (3.0)',
  requirement => 'format byte becomes contentEncoding base64, and format is kept for the reader',
  run => sub {
      my ($a) = api(json_body_op({ type => 'string', format => 'byte' },
                                 openapi => '3.0.3'));
      return 0 unless $a;
      my $s = $a->spec->{paths}{'/t'}{post}{requestBody}
                  {content}{'application/json'}{schema};
      return (ref $s eq 'HASH'
              && ($s->{contentEncoding} || '') eq 'base64'
              && ($s->{format} || '') eq 'byte') ? 1 : 0;
  } },

{ id => 'openapi30/schema-example-to-examples', section => '4.8.24 example (3.0)',
  requirement => 'a 3.0 schema example becomes the 2020-12 examples array',
  run => sub {
      my ($a) = api(json_body_op({ type => 'string', example => 'x' },
                                 openapi => '3.0.3'));
      return 0 unless $a;
      my $s = $a->spec->{paths}{'/t'}{post}{requestBody}
                  {content}{'application/json'}{schema};
      return (ref $s eq 'HASH' && ref $s->{examples} eq 'ARRAY'
              && @{ $s->{examples} } && $s->{examples}[0] eq 'x') ? 1 : 0;
  } },

{ id => 'openapi30/normalisation-idempotent', section => '4.8.24 (3.0)',
  requirement => 'feeding ->spec back through new() converts no further',
  run => sub {
      my ($a) = api(json_body_op({ type => 'object', properties => {
          a => { type => 'string', nullable => 1 },
          b => { type => 'integer', minimum => 1, exclusiveMinimum => \1 } } },
          openapi => '3.0.3'));
      return 0 unless $a;
      my ($b) = api($a->spec);
      return 0 unless $b;
      # the second pass must reach the same document, not eat its own output
      my $j1 = $a->spec->{paths}{'/t'}{post}{requestBody}
                   {content}{'application/json'}{schema};
      my $j2 = $b->spec->{paths}{'/t'}{post}{requestBody}
                   {content}{'application/json'}{schema};
      return eq_deeply_ish($j2, $j1);
  } },

{ id => 'openapi30/discriminator-in-both', section => '4.25 Discriminator',
  requirement => 'a discriminator is spelled identically in 3.0 and 3.1, and binds in both',
  run => sub {
      my $mk = sub {
          my ($ver) = @_;
          return api(json_body_op(
              { oneOf => [ { '$ref' => '#/components/schemas/Dog' },
                           { '$ref' => '#/components/schemas/Cat' } ],
                discriminator => { propertyName => 'petType',
                                   mapping => { dog => '#/components/schemas/Dog',
                                                cat => '#/components/schemas/Cat' } } },
              openapi    => $ver,
              components => { schemas => {
                  Dog => { type => 'object', required => [ 'petType', 'bark' ],
                           properties => { petType => { type => 'string' },
                                           bark    => { type => 'string' } } },
                  Cat => { type => 'object', required => [ 'petType', 'meow' ],
                           properties => { petType => { type => 'string' },
                                           meow    => { type => 'string' } } } } }));
      };
      for my $ver ('3.0.3', '3.1.0') {
          my ($a) = $mk->($ver);
          return 0 unless $a;
          my ($bad) = req($a, header => $JSON, body => '{"petType":"dog","meow":"m"}');
          return 0 if $bad;                       # must be refused in both
          my ($good) = req($a, header => $JSON, body => '{"petType":"dog","bark":"w"}');
          return 0 unless $good;                  # and accepted in both
      }
      return 1;
  } },

# ================================================================ Swagger 2.0
#
# Authored from plan_openapi_v2/spec/2.0-2026-10-11.md (the specification,
# fetched, never recalled), object by object in the order the specification
# defines them. Every case names its object and quotes or closely paraphrases
# the sentence it tests. The 2.0 catalogue was written BEFORE the conversion
# code and every id was listed in expected-fail.txt with its phase; the phases
# remove lines, and the gate is the list being empty again.
#
# Two stances are stated once here rather than in every case. 2.0 defers to
# JSON Schema draft-04, which ignores unknown keywords, and this distribution
# does not lint unknown keys in any version; so a 2.0 document carrying oneOf
# or `schema` on a query parameter is accepted (D6 in the plan's overview),
# and no case below asserts otherwise. And a converted 2.0 document KEEPS
# `swagger: "2.0"` and is fed back through new() unchanged (D2), so every
# structural MUST is phrased in terms that survive conversion.

# ---------------------------------------------------------------- Swagger Object

{ id => 'swagger/version-string', section => '2.0 Swagger Object',
  requirement => '"The value MUST be "2.0"": a swagger: "2.0" document loads',
  run => sub { loads(doc20()) } },

{ id => 'swagger/version-numeric-refused', section => '2.0 Swagger Object',
  requirement => 'a numeric swagger version (a YAML 2.0) is refused by name',
  run => sub { api_err(doc20(swagger => 2.0)) =~ /must be the string "2\.0"/ ? 1 : 0 } },

{ id => 'swagger/both-keys-refused', section => '2.0 Swagger Object',
  requirement => 'a document declaring both openapi and swagger is refused',
  run => sub { api_err(doc20(openapi => '3.1.0')) =~ /both 'openapi' and 'swagger'/ ? 1 : 0 } },

{ id => 'swagger/paths-required', section => '2.0 Swagger Object',
  requirement => 'paths is REQUIRED',
  run => sub {
      my $d = doc20(); delete $d->{paths};
      croaks($d);
  } },

{ id => 'swagger/host-no-scheme', section => '2.0 Swagger Object',
  requirement => 'host "MUST be the host only and does not include the scheme"',
  run => sub { croaks(op_doc20(host => 'https://h.test')) } },

{ id => 'swagger/host-no-path', section => '2.0 Swagger Object',
  requirement => 'host "does not include ... sub-paths"',
  run => sub { croaks(op_doc20(host => 'h.test/v2')) } },

{ id => 'swagger/host-port-allowed', section => '2.0 Swagger Object',
  requirement => 'host "MAY include a port"',
  run => sub {
      my ($a) = api(op_doc20(host => 'h.test:8443', schemes => ['https']));
      return 0 unless $a;
      my $s = $a->spec->{servers};
      return (ref $s eq 'ARRAY' && @$s == 1 && $s->[0]{url} eq 'https://h.test:8443') ? 1 : 0;
  } },

{ id => 'swagger/basePath-leading-slash', section => '2.0 Swagger Object',
  requirement => 'basePath "MUST start with a leading slash (/)"',
  run => sub { croaks(op_doc20(basePath => 'v2')) } },

{ id => 'swagger/schemes-values', section => '2.0 Swagger Object',
  requirement => 'schemes "Values MUST be from the list: http, https, ws, wss"',
  run => sub { croaks(op_doc20(host => 'h.test', schemes => ['ftp'])) } },

{ id => 'swagger/servers-from-host', section => '2.0 Swagger Object',
  requirement => 'host, basePath and schemes become one server per scheme, in order',
  run => sub {
      my ($a) = api(op_doc20(host => 'h.test', basePath => '/v2', schemes => ['https', 'http']));
      return 0 unless $a;
      return deep_eq($a->spec->{servers},
                     [ { url => 'https://h.test/v2' }, { url => 'http://h.test/v2' } ]);
  } },

{ id => 'swagger/servers-scheme-relative', section => '2.0 Swagger Object',
  requirement => 'host with no schemes ("the one used to access the Swagger definition itself") is a scheme-relative server',
  run => sub {
      my ($a) = api(op_doc20(host => 'h.test', basePath => '/v2'));
      return 0 unless $a;
      return deep_eq($a->spec->{servers}, [ { url => '//h.test/v2' } ]);
  } },

{ id => 'swagger/servers-basepath-only', section => '2.0 Swagger Object',
  requirement => 'basePath with no host is a relative server URL',
  run => sub {
      my ($a) = api(op_doc20(basePath => '/v2'));
      return 0 unless $a;
      return deep_eq($a->spec->{servers}, [ { url => '/v2' } ]);
  } },

{ id => 'swagger/servers-none', section => '2.0 Swagger Object',
  requirement => 'with neither host, basePath nor schemes, no servers are invented',
  run => sub {
      my ($a) = api(op_doc20());
      return 0 unless $a;
      return exists $a->spec->{servers} ? 0 : 1;
  } },

{ id => 'swagger/basepath-routes-opt-in', section => '2.0 Swagger Object',
  requirement => 'basePath prefixes every path ("The path is appended to the basePath"), honoured under servers => 1 as a 3.x server prefix is',
  run => sub {
      my $d = op_doc20(host => 'h.test', basePath => '/v2', schemes => ['https']);
      my ($on)  = api($d, servers => 1);
      my ($off) = api($d);
      return 0 unless $on && $off;
      # under the option the prefixed path routes; the bare path still routes
      # too, as it does for a 3.x server prefix (an app mounted under the
      # prefix sees PATH_INFO without it); without the option only the bare one
      my ($i1) = $on->match(GET => '/v2/t');
      my ($i2) = $off->match(GET => '/v2/t');
      my ($i3) = $off->match(GET => '/t');
      return (defined $i1 && $i1 eq 'op' && !defined $i2 && defined $i3) ? 1 : 0;
  } },

{ id => 'swagger/consumes-mime', section => '2.0 Swagger Object',
  requirement => 'consumes "Value MUST be as described under Mime Types"',
  run => sub { croaks(op_doc20(consumes => ['json'])) } },

{ id => 'swagger/produces-mime', section => '2.0 Swagger Object',
  requirement => 'produces "Value MUST be as described under Mime Types"',
  run => sub { croaks(op_doc20(produces => ['json'])) } },

{ id => 'swagger/extensions-preserved', section => '2.0 Swagger Object / Specification Extensions',
  requirement => '^x- fields at the root and on a schema survive into ->spec uninterpreted',
  run => sub {
      my ($a) = api(doc20('x-corp' => { a => 1 },
          definitions => { S => { type => 'string', 'x-nullable' => \1 } },
          paths => { '/t' => { get => { operationId => 'op',
                                        responses => { 200 => { description => 'ok' } } } } }));
      return 0 unless $a;
      return 0 unless ref $a->spec->{'x-corp'} eq 'HASH' && $a->spec->{'x-corp'}{a} == 1;
      my $s = $a->spec->{components}{schemas}{S};
      return ($s && exists $s->{'x-nullable'}) ? 1 : 0;
  } },

(map {
    my ($key, $value, $dest) = @$_;
    { id => "swagger/$key-moved", section => '2.0 Swagger Object',
      requirement => "$key becomes components.$dest and the 2.0 key is gone",
      run => sub {
          my ($a) = api(op_doc20($key eq 'parameters' ? 'root_parameters'
                               : $key eq 'responses'  ? 'root_responses' : $key, $value));
          return 0 unless $a;
          return 0 if exists $a->spec->{$key};
          return (ref $a->spec->{components}{$dest} eq 'HASH'
                  && exists $a->spec->{components}{$dest}{X}) ? 1 : 0;
      } };
} (
    [ 'definitions',         { X => { type => 'string' } },                              'schemas' ],
    [ 'parameters',          { X => { name => 'x', in => 'query', type => 'string' } },  'parameters' ],
    [ 'responses',           { X => { description => 'x' } },                             'responses' ],
    [ 'securityDefinitions', { X => { type => 'apiKey', name => 'k', in => 'header' } }, 'securitySchemes' ],
)),

{ id => 'swagger/root-keys-deleted', section => '2.0 Swagger Object',
  requirement => 'host, basePath, schemes, consumes and produces are consumed, not copied beside their replacements',
  run => sub {
      my ($a) = api(op_doc20(host => 'h.test', basePath => '/v2', schemes => ['https'],
                             consumes => ['application/json'], produces => ['application/json']));
      return 0 unless $a;
      for (qw(host basePath schemes consumes produces)) { return 0 if exists $a->spec->{$_} }
      return 1;
  } },

{ id => 'swagger/normalisation-idempotent', section => '2.0 (this build)',
  requirement => 'new(spec => ->spec) over a document using every rule yields the same document',
  run => sub {
      my ($a) = api("$DIR/swagger2-everything.json");
      return 0 unless $a;
      my ($b) = api($a->spec);
      return 0 unless $b;
      return deep_eq($a->spec, $b->spec) && $b->openapi_version eq '2.0' ? 1 : 0;
  } },

# ----------------------------------------- Info, Contact, License, Tag, External Docs

{ id => 'swagger/info/title-required', section => '2.0 Info Object',
  requirement => 'title is REQUIRED',
  run => sub { croaks(doc20(info => { version => '1' })) } },

{ id => 'swagger/info/version-required', section => '2.0 Info Object',
  requirement => 'version is REQUIRED',
  run => sub { croaks(doc20(info => { title => 'T' })) } },

{ id => 'swagger/license/name-required', section => '2.0 License Object',
  requirement => 'name is REQUIRED',
  run => sub { croaks(doc20(info => { title => 'T', version => '1',
                                      license => { url => 'https://h.test/l' } })) } },

{ id => 'swagger/contact/email-format', section => '2.0 Contact Object',
  requirement => 'email "MUST be in the format of an email address"',
  run => sub { croaks(doc20(info => { title => 'T', version => '1',
                                      contact => { email => 'not an address' } })) } },

{ id => 'swagger/tag/name-unique', section => '2.0 Swagger Object (tags)',
  requirement => '"Each tag name in the list MUST be unique"',
  run => sub { croaks(op_doc20(tags => [ { name => 'a' }, { name => 'a' } ])) } },

{ id => 'swagger/externaldocs/url-required', section => '2.0 External Documentation Object',
  requirement => 'url is REQUIRED',
  run => sub { croaks(op_doc20(externalDocs => { description => 'd' })) } },

# ------------------------------------------------------------------ Paths Object

{ id => 'swagger/paths/leading-slash', section => '2.0 Paths Object',
  requirement => '"The field name MUST begin with a slash"',
  run => sub { croaks(doc20(paths => { 't' => { get => {
      operationId => 'op', responses => { 200 => { description => 'ok' } } } } })) } },

{ id => 'swagger/paths/templates-differ-only-by-name', section => '2.0 Paths Object / Path Templating',
  requirement => 'two paths differing only in their template variable names are one path twice',
  run => sub {
      my %op = (responses => { 200 => { description => 'ok' } },
                parameters => [ { name => 'a', in => 'path', required => \1, type => 'string' } ]);
      my %op2 = (%op, parameters => [ { name => 'b', in => 'path', required => \1, type => 'string' } ]);
      croaks(doc20(paths => { '/t/{a}' => { get => { operationId => 'x', %op } },
                              '/t/{b}' => { get => { operationId => 'y', %op2 } } }));
  } },

{ id => 'swagger/paths/extensions', section => '2.0 Paths Object',
  requirement => 'an ^x- field under paths is not a path',
  run => sub {
      my $d = op_doc20();
      $d->{paths}{'x-note'} = { anything => 1 };
      my ($a) = api($d);
      return 0 unless $a;
      return @{ $a->operations } == 1 ? 1 : 0;
  } },

# -------------------------------------------------------------- Path Item Object

{ id => 'swagger/pathitem/ref-unresolvable-refused', section => '2.0 Path Item Object',
  requirement => 'a path item $ref that resolves to nothing is refused loudly, never dropped',
  run => sub { croaks(doc20(paths => { '/t' => { '$ref' => '#/x/y' } })) } },

{ id => 'swagger/pathitem/parameters-apply', section => '2.0 Path Item Object',
  requirement => 'path item parameters "are applicable for all the operations described under this path"',
  run => sub {
      my $d = op_doc20();
      $d->{paths}{'/t'}{parameters} = [ { name => 'q', in => 'query', required => \1, type => 'string' } ];
      my ($a) = api($d);
      return 0 unless $a;
      my ($absent) = req($a, query => '');
      my ($given)  = req($a, query => 'q=v');
      return (!$absent && $given) ? 1 : 0;
  } },

{ id => 'swagger/pathitem/operation-overrides', section => '2.0 Path Item Object',
  requirement => '"These parameters can be overridden at the operation level, but cannot be removed there"',
  run => sub {
      my $d = op_doc20(parameters => [ { name => 'q', in => 'query', type => 'string' } ]);
      $d->{paths}{'/t'}{parameters} = [ { name => 'q', in => 'query', required => \1, type => 'string' } ];
      my ($a) = api($d);
      return 0 unless $a;
      my ($absent) = req($a, query => '');
      return $absent ? 1 : 0;          # the operation's optional q wins
  } },

{ id => 'swagger/pathitem/body-at-path-level', section => '2.0 Path Item Object',
  requirement => 'a body parameter declared on the path item is the body of every operation under it',
  run => sub {
      my $d = op_doc20(method => 'post', consumes => ['application/json']);
      $d->{paths}{'/t'}{parameters} = [ { name => 'b', in => 'body', required => \1,
          schema => { type => 'object', required => ['a'], properties => { a => { type => 'string' } } } } ];
      my ($a) = api($d);
      return 0 unless $a;
      my ($bad)  = req($a, header => $JSON, body => '{}');
      my ($good) = req($a, header => $JSON, body => '{"a":"x"}');
      return (!$bad && $good) ? 1 : 0;
  } },

{ id => 'swagger/pathitem/duplicate-name-in-refused', section => '2.0 Path Item Object',
  requirement => '"The list MUST NOT include duplicated parameters. A unique parameter is defined by a combination of a name and location"',
  run => sub { croaks(op_doc20(parameters => [
      { name => 'a', in => 'query', type => 'string' },
      { name => 'a', in => 'query', type => 'integer' } ])) } },

{ id => 'pathitem/duplicate-name-in-refused', section => '4.5 Path Item Object',
  requirement => 'the same rule in 3.x: a (name, in) duplicated within one list is refused',
  run => sub { croaks(op_doc(parameters => [
      { name => 'a', in => 'query', schema => { type => 'string' } },
      { name => 'a', in => 'query', schema => { type => 'integer' } } ])) } },

# -------------------------------------------------------------- Operation Object

{ id => 'swagger/operation/responses-required', section => '2.0 Operation Object',
  requirement => 'responses is REQUIRED',
  run => sub { croaks(doc20(paths => { '/t' => { get => { operationId => 'op' } } })) } },

{ id => 'swagger/operation/responses-non-empty', section => '2.0 Responses Object',
  requirement => '"The Responses Object MUST contain at least one response code"',
  run => sub { croaks(op_doc20(responses => {})) } },

{ id => 'swagger/operation/operationId-unique', section => '2.0 Operation Object',
  requirement => '"The id MUST be unique among all operations described in the API"',
  run => sub { croaks(doc20(paths => {
      '/a' => { get => { operationId => 'op', responses => { 200 => { description => 'ok' } } } },
      '/b' => { get => { operationId => 'op', responses => { 200 => { description => 'ok' } } } } })) } },

{ id => 'swagger/operation/deprecated', section => '2.0 Operation Object',
  requirement => 'deprecated is carried',
  run => sub {
      my ($a) = api(op_doc20(deprecated => \1));
      return 0 unless $a;
      my $doc = eval { $a->operation_doc('op') } or return 0;
      return $doc->{deprecated} ? 1 : 0;
  } },

{ id => 'swagger/operation/consumes-overrides', section => '2.0 Operation Object',
  requirement => 'operation consumes "overrides the consumes definition at the Swagger Object"',
  run => sub {
      my ($a) = api(body20({ type => 'object' },
          consumes => ['application/xml'], op_consumes => ['application/json']));
      return 0 unless $a;
      my ($json) = req($a, header => $JSON, body => '{}');
      my ($xml)  = req($a, header => { 'content-type' => 'application/xml' }, body => '<a/>');
      return ($json && !$xml) ? 1 : 0;
  } },

{ id => 'swagger/operation/consumes-empty-clears', section => '2.0 Operation Object',
  requirement => '"An empty value MAY be used to clear the global definition": the body falls to the default, not to the root list',
  run => sub {
      my ($a) = api(body20({ type => 'object' },
          consumes => ['application/xml'], op_consumes => []));
      return 0 unless $a;
      my ($json) = req($a, header => $JSON, body => '{}');
      my ($xml)  = req($a, header => { 'content-type' => 'application/xml' }, body => '<a/>');
      return ($json && !$xml) ? 1 : 0;
  } },

{ id => 'swagger/operation/produces-overrides', section => '2.0 Operation Object',
  requirement => 'operation produces "overrides the produces definition at the Swagger Object"',
  run => sub {
      my ($a) = api(op_doc20(produces => ['application/xml'], op_produces => ['application/json'],
          responses => { 200 => { description => 'ok', schema => { type => 'object' } } }));
      return 0 unless $a;
      my $c = $a->spec->{paths}{'/t'}{get}{responses}{200}{content};
      return (ref $c eq 'HASH' && exists $c->{'application/json'}
              && !exists $c->{'application/xml'}) ? 1 : 0;
  } },

{ id => 'swagger/operation/schemes', section => '2.0 Operation Object',
  requirement => 'operation schemes "overrides the Swagger Object schemes definition": an operation-level server',
  run => sub {
      my ($a) = api(op_doc20(host => 'h.test', schemes => ['https'], op_schemes => ['wss']));
      return 0 unless $a;
      my $s = $a->spec->{paths}{'/t'}{get}{servers};
      return deep_eq($s, [ { url => 'wss://h.test' } ]);
  } },

{ id => 'swagger/operation/schemes-without-host', section => '2.0 Operation Object',
  requirement => 'operation schemes with no host render no URL and are dropped, and the document still loads',
  run => sub {
      my ($a) = api(op_doc20(op_schemes => ['wss']));
      return 0 unless $a;
      return exists $a->spec->{paths}{'/t'}{get}{servers} ? 0 : 1;
  } },

{ id => 'swagger/operation/security-empty-object-optional', section => '2.0 Security Requirement Object',
  requirement => 'an empty requirement object among the alternatives makes security optional',
  run => sub {
      loads(op_doc20(securityDefinitions => { K => { type => 'apiKey', name => 'k', in => 'header' } },
                     security => [ { K => [] }, {} ]));
  } },

{ id => 'swagger/operation/security-empty-array-removes', section => '2.0 Operation Object',
  requirement => '"To remove a top-level security declaration, an empty array can be used"',
  run => sub {
      my ($a) = api(op_doc20(securityDefinitions => { K => { type => 'apiKey', name => 'X-K', in => 'header' } },
                             security => [ { K => [] } ], op_security => []));
      return 0 unless $a;
      # undef is "may proceed": with no credential at all the operation admits
      my $denied = $a->check_op_security('op', {}, { K => sub { 0 } });
      return $denied ? 0 : 1;
  } },

# -------------------------------------------------------------- Parameter Object

{ id => 'swagger/parameter/in-values', section => '2.0 Parameter Object',
  requirement => 'in: "Possible values are query, header, path, formData or body": cookie is refused',
  run => sub { croaks(op_doc20(parameters => [ { name => 'c', in => 'cookie', type => 'string' } ])) } },

{ id => 'swagger/parameter/type-required-off-body', section => '2.0 Parameter Object',
  requirement => 'type is REQUIRED for a non-body parameter: one with neither type nor schema is refused',
  run => sub { croaks(op_doc20(parameters => [ { name => 'q', in => 'query' } ])) } },

{ id => 'swagger/parameter/path-required-true', section => '2.0 Parameter Object',
  requirement => '"If the parameter is in path, this property is required and its value MUST be true"',
  run => sub { croaks(op_doc20(path => '/t/{id}', parameters => [
      { name => 'id', in => 'path', type => 'integer', required => \0 } ])) } },

{ id => 'swagger/parameter/items-required-for-array', section => '2.0 Parameter Object',
  requirement => 'items is "Required if type is array"',
  run => sub { croaks(op_doc20(parameters => [ { name => 'a', in => 'query', type => 'array' } ])) } },

{ id => 'swagger/parameter/inline-type-integer', section => '2.0 Parameter Object',
  requirement => 'the inline type of a query parameter is validated (type: integer)',
  run => sub {
      my ($a) = api(op_doc20(parameters => [ { name => 'v', in => 'query', type => 'integer' } ]));
      return 0 unless $a;
      my ($bad)  = req($a, query => 'v=x');
      my ($good) = req($a, query => 'v=5');
      return (!$bad && $good) ? 1 : 0;
  } },

# one case per draft-04 keyword the Parameter Object takes "directly from the
# JSON Schema definition": a refusing and an accepting request each, so a
# keyword the converter forgets to carry fails by name
(map {
    my ($kw, $extra, $bad, $good) = @$_;
    { id => "swagger/parameter/inline-$kw", section => '2.0 Parameter Object',
      requirement => "$kw on a non-body parameter is validated",
      run => sub {
          my ($a) = api(op_doc20(parameters => [ { name => 'v', in => 'query', %$extra } ]));
          return 0 unless $a;
          my ($b) = req($a, query => "v=$bad");
          my ($g) = req($a, query => "v=$good");
          return (!$b && $g) ? 1 : 0;
      } };
} (
    [ 'enum',             { type => 'string', enum => ['a', 'b'] },                       'c',    'a' ],
    [ 'maximum',          { type => 'integer', maximum => 5 },                            '6',    '5' ],
    [ 'exclusiveMaximum', { type => 'integer', maximum => 5, exclusiveMaximum => \1 },    '5',    '4' ],
    [ 'minimum',          { type => 'integer', minimum => 5 },                            '4',    '5' ],
    [ 'exclusiveMinimum', { type => 'integer', minimum => 5, exclusiveMinimum => \1 },    '5',    '6' ],
    [ 'maxLength',        { type => 'string', maxLength => 2 },                           'abc',  'ab' ],
    [ 'minLength',        { type => 'string', minLength => 2 },                           'a',    'ab' ],
    [ 'pattern',          { type => 'string', pattern => '^a' },                          'b',    'a' ],
    [ 'maxItems',         { type => 'array', items => { type => 'string' }, maxItems => 1 }, 'a,b', 'a' ],
    [ 'minItems',         { type => 'array', items => { type => 'string' }, minItems => 2 }, 'a',   'a,b' ],
    [ 'uniqueItems',      { type => 'array', items => { type => 'string' }, uniqueItems => \1 }, 'a,a', 'a,b' ],
    [ 'multipleOf',       { type => 'integer', multipleOf => 5 },                         '7',    '10' ],
)),

{ id => 'swagger/parameter/inline-format-carried', section => '2.0 Parameter Object',
  requirement => 'format travels into the schema (a format is an annotation the validator does not refuse on)',
  run => sub {
      my ($a) = api(op_doc20(parameters => [ { name => 'v', in => 'query', type => 'string', format => 'date' } ]));
      return 0 unless $a;
      my $p = $a->spec->{paths}{'/t'}{get}{parameters}[0];
      return ($p->{schema} && ($p->{schema}{format} || '') eq 'date') ? 1 : 0;
  } },

{ id => 'swagger/parameter/default-carried-not-injected', section => '2.0 Parameter Object',
  requirement => 'default travels into the schema and is NOT injected into a request that omits the parameter',
  run => sub {
      my ($a) = api(op_doc20(parameters => [ { name => 'v', in => 'query', type => 'integer', default => 7 } ]));
      return 0 unless $a;
      my $p = $a->spec->{paths}{'/t'}{get}{parameters}[0];
      return 0 unless $p->{schema} && ($p->{schema}{default} || 0) == 7;
      my ($ok, $res) = req($a, query => '');
      return ($ok && !exists $res->{query}{v}) ? 1 : 0;
  } },

{ id => 'swagger/parameter/type-file-not-in-formdata', section => '2.0 Parameter Object',
  requirement => 'If type is file ... "the parameter MUST be in formData"',
  run => sub { croaks(op_doc20(parameters => [ { name => 'f', in => 'query', type => 'file' } ])) } },

{ id => 'swagger/parameter/type-file-needs-form-consumes', section => '2.0 Parameter Object',
  requirement => 'If type is file, "the consumes MUST be either multipart/form-data, application/x-www-form-urlencoded or both"',
  run => sub { api_err(form20([ { name => 'f', type => 'file' } ], consumes => ['application/json'])) =~ /file.*consumes|consumes.*file/i ? 1 : 0 } },

{ id => 'swagger/parameter/type-file-binary', section => '2.0 Parameter Object',
  requirement => 'a formData file under multipart loads as a binary string property',
  run => sub {
      my ($a) = api(form20([ { name => 'f', type => 'file', required => \1 } ],
                           consumes => ['multipart/form-data']));
      return 0 unless $a;
      my $s = $a->spec->{paths}{'/t'}{post}{requestBody}{content}{'multipart/form-data'}{schema};
      return 0 unless $s && ref $s->{properties} eq 'HASH';
      my $f = $s->{properties}{f} or return 0;
      return (($f->{type} || '') eq 'string' && ($f->{format} || '') eq 'binary') ? 1 : 0;
  } },

{ id => 'swagger/parameter/body-at-most-one', section => '2.0 Operation Object',
  requirement => '"There can be one "body" parameter at most"',
  run => sub { api_err(op_doc20(method => 'post', consumes => ['application/json'], parameters => [
      { name => 'a', in => 'body', schema => { type => 'object' } },
      { name => 'b', in => 'body', schema => { type => 'object' } } ])) =~ /one body parameter|at most one body/i ? 1 : 0 } },

{ id => 'swagger/parameter/body-not-with-formdata', section => '2.0 Parameter Object',
  requirement => 'form parameters "cannot be declared together with a body parameter"',
  run => sub { api_err(op_doc20(method => 'post', consumes => ['application/x-www-form-urlencoded'], parameters => [
      { name => 'a', in => 'body', schema => { type => 'object' } },
      { name => 'b', in => 'formData', type => 'string' } ])) =~ /body.*formData|formData.*body/i ? 1 : 0 } },

{ id => 'swagger/parameter/body-schema-required', section => '2.0 Parameter Object',
  requirement => 'schema is REQUIRED on a body parameter',
  run => sub { api_err(op_doc20(method => 'post', consumes => ['application/json'],
                               parameters => [ { name => 'a', in => 'body' } ])) =~ /body.*schema|schema.*body/i ? 1 : 0 } },

{ id => 'swagger/parameter/body-required', section => '2.0 Parameter Object',
  requirement => 'a required body that is absent is refused; an optional one may be absent',
  run => sub {
      my ($req) = api(body20({ type => 'object' }));
      my ($opt) = api(op_doc20(method => 'post', consumes => ['application/json'],
          parameters => [ { name => 'b', in => 'body', schema => { type => 'object' } } ]));
      return 0 unless $req && $opt;
      my ($r) = req($req, header => $JSON);
      my ($o) = req($opt, header => $JSON);
      return (!$r && $o) ? 1 : 0;
  } },

{ id => 'swagger/parameter/body-description-carried', section => '2.0 Parameter Object',
  requirement => 'the body parameter description is the request body description',
  run => sub {
      my ($a) = api(op_doc20(method => 'post', consumes => ['application/json'],
          parameters => [ { name => 'b', in => 'body', description => 'the thing',
                            schema => { type => 'object' } } ]));
      return 0 unless $a;
      my $rb = $a->spec->{paths}{'/t'}{post}{requestBody} or return 0;
      return ($rb->{description} || '') eq 'the thing' ? 1 : 0;
  } },

{ id => 'swagger/parameter/allowEmptyValue-query', section => '2.0 Parameter Object',
  requirement => 'allowEmptyValue "Sets the ability to pass empty-valued parameters" in query',
  run => sub {
      my ($with) = api(op_doc20(parameters => [ { name => 'v', in => 'query', type => 'integer', allowEmptyValue => \1 } ]));
      my ($sans) = api(op_doc20(parameters => [ { name => 'v', in => 'query', type => 'integer' } ]));
      return 0 unless $with && $sans;
      my ($w) = req($with, query => 'v=');
      my ($s) = req($sans, query => 'v=');
      return ($w && !$s) ? 1 : 0;
  } },

{ id => 'swagger/parameter/allowEmptyValue-formdata', section => '2.0 Parameter Object',
  requirement => 'allowEmptyValue is "valid only for either query or formData": an empty form value is accepted',
  run => sub {
      my ($with) = api(form20([ { name => 'v', type => 'integer', allowEmptyValue => \1 } ]));
      my ($sans) = api(form20([ { name => 'v', type => 'integer' } ]));
      return 0 unless $with && $sans;
      my ($w) = req($with, header => $FORM, body => 'v=');
      my ($s) = req($sans, header => $FORM, body => 'v=');
      return ($w && !$s) ? 1 : 0;
  } },

{ id => 'swagger/parameter/items-nested', section => '2.0 Items Object',
  requirement => 'a nested Items Object carries its own collectionFormat: 1|2,3|4 is [[1,2],[3,4]]',
  run => sub {
      my $p = { name => 'm', in => 'query', type => 'array', collectionFormat => 'csv',
                items => { type => 'array', collectionFormat => 'pipes', items => { type => 'integer' } } };
      my ($a) = api(op_doc20(parameters => [ $p ]));
      return 0 unless $a;
      my ($ok, $res) = req($a, query => 'm=1|2,3|4');
      return 0 unless $ok;
      return eq_deeply_ish($res->{query}{m}, [ [1, 2], [3, 4] ]);
  } },

{ id => 'swagger/parameter/items-nested-header', section => '2.0 Items Object',
  requirement => 'the same nesting in a header',
  run => sub {
      my $p = { name => 'X-M', in => 'header', type => 'array', collectionFormat => 'csv',
                items => { type => 'array', collectionFormat => 'pipes', items => { type => 'integer' } } };
      my ($a) = api(op_doc20(parameters => [ $p ]));
      return 0 unless $a;
      my ($ok, $res) = req($a, header => { 'x-m' => '1|2,3|4' });
      return 0 unless $ok;
      return eq_deeply_ish($res->{header}{'X-M'}, [ [1, 2], [3, 4] ]);
  } },

{ id => 'swagger/parameter/ref-root-parameters', section => '2.0 Reference Object / Parameters Definitions Object',
  requirement => 'a $ref to #/parameters/X resolves and the parameter applies',
  run => sub {
      my ($a) = api(op_doc20(
          root_parameters => { Q => { name => 'q', in => 'query', required => \1, type => 'string' } },
          parameters => [ { '$ref' => '#/parameters/Q' } ]));
      return 0 unless $a;
      my ($absent) = req($a, query => '');
      my ($given)  = req($a, query => 'q=v');
      return (!$absent && $given) ? 1 : 0;
  } },

{ id => 'swagger/parameter/ref-body-component', section => '2.0 Reference Object / Parameters Definitions Object',
  requirement => 'a $ref to a body parameter definition is the operation body',
  run => sub {
      my ($a) = api(op_doc20(method => 'post', consumes => ['application/json'],
          root_parameters => { B => { name => 'b', in => 'body', required => \1,
              schema => { type => 'object', required => ['a'], properties => { a => { type => 'string' } } } } },
          parameters => [ { '$ref' => '#/parameters/B' } ]));
      return 0 unless $a;
      my ($bad)  = req($a, header => $JSON, body => '{}');
      my ($good) = req($a, header => $JSON, body => '{"a":"x"}');
      return (!$bad && $good) ? 1 : 0;
  } },

{ id => 'swagger/parameter/ref-formdata-component', section => '2.0 Reference Object / Parameters Definitions Object',
  requirement => 'two formData parameter definitions reached by $ref form one body',
  run => sub {
      my ($a) = api(op_doc20(method => 'post', consumes => ['application/x-www-form-urlencoded'],
          root_parameters => { A => { name => 'a', in => 'formData', required => \1, type => 'string' },
                               B => { name => 'b', in => 'formData', required => \1, type => 'string' } },
          parameters => [ { '$ref' => '#/parameters/A' }, { '$ref' => '#/parameters/B' } ]));
      return 0 unless $a;
      my ($half) = req($a, header => $FORM, body => 'a=1');
      my ($both) = req($a, header => $FORM, body => 'a=1&b=2');
      return (!$half && $both) ? 1 : 0;
  } },

{ id => 'swagger/parameter/body-definition-is-request-body', section => '2.0 Parameters Definitions Object',
  requirement => 'a body parameter definition becomes a component request body, not a component parameter',
  run => sub {
      my ($a) = api(op_doc20(method => 'post', consumes => ['application/json'],
          root_parameters => { B => { name => 'b', in => 'body', schema => { type => 'object' } },
                               Q => { name => 'q', in => 'query', type => 'string' } },
          parameters => [ { '$ref' => '#/parameters/B' } ]));
      return 0 unless $a;
      my $c = $a->spec->{components} or return 0;
      return 0 unless ref $c->{requestBodies} eq 'HASH' && $c->{requestBodies}{B}
                   && ref $c->{requestBodies}{B}{content} eq 'HASH';
      return 0 if ref $c->{parameters} eq 'HASH' && exists $c->{parameters}{B};
      return (ref $c->{parameters} eq 'HASH' && $c->{parameters}{Q}) ? 1 : 0;
  } },

{ id => 'swagger/parameter/formdata-duplicate-refused', section => '2.0 Path Item Object / Operation Object',
  requirement => 'two formData parameters with one name in one list are a duplicated parameter and are refused',
  run => sub { croaks(form20([ { name => 'a', type => 'string' },
                               { name => 'a', type => 'integer' } ])) } },

{ id => 'swagger/parameter/ref-unresolvable', section => '2.0 Reference Object',
  requirement => 'a $ref to a parameter definition that does not exist is refused',
  run => sub { croaks(op_doc20(parameters => [ { '$ref' => '#/parameters/Nope' } ])) } },

{ id => 'swagger/reference/external-refused', section => '2.0 Reference Object',
  requirement => 'a $ref into another file is refused (this build resolves no external references, in any version)',
  run => sub { api_err(body20({ '$ref' => 'other.json#/definitions/X' })) =~ /other\.json/ ? 1 : 0 } },

# ---------------------------------------------------------------- Items Object

{ id => 'swagger/items/type-required', section => '2.0 Items Object',
  requirement => 'type is REQUIRED',
  run => sub { croaks(op_doc20(parameters => [ { name => 'a', in => 'query', type => 'array', items => {} } ])) } },

{ id => 'swagger/items/no-multi', section => '2.0 Items Object',
  requirement => 'an Items Object collectionFormat is csv, ssv, tsv or pipes: multi is not a value',
  run => sub { croaks(op_doc20(parameters => [ { name => 'a', in => 'query', type => 'array',
      items => { type => 'array', collectionFormat => 'multi', items => { type => 'string' } } } ])) } },

{ id => 'swagger/items/nested-depth-bound', section => '2.0 Items Object',
  requirement => 'nesting to depth 4 is accepted and depth 5 is refused with a message, not a stack',
  run => sub {
      my $mk = sub { my ($d) = @_; my $s = { type => 'string' };
                     $s = { type => 'array', items => $s } for 1 .. $d; $s };
      my $four = $mk->(4); my $five = $mk->(5);
      my ($ok4) = api(op_doc20(parameters => [ { name => 'a', in => 'query', %$four } ]));
      my $e5 = api_err(op_doc20(parameters => [ { name => 'a', in => 'query', %$five } ]));
      return ($ok4 && $e5) ? 1 : 0;
  } },

{ id => 'swagger/items/constraints-apply', section => '2.0 Items Object',
  requirement => 'an Items Object constraint applies to each item',
  run => sub {
      my ($a) = api(op_doc20(parameters => [ { name => 'a', in => 'query', type => 'array',
          items => { type => 'integer', maximum => 5 } } ]));
      return 0 unless $a;
      my ($bad)  = req($a, query => 'a=1,6');
      my ($good) = req($a, query => 'a=1,5');
      return (!$bad && $good) ? 1 : 0;
  } },

# ------------------------------------------------------------ Responses Object

{ id => 'swagger/responses/default-selected', section => '2.0 Responses Object',
  requirement => 'default "is used to cover all the HTTP codes that are not covered individually"',
  run => sub {
      my ($a) = api(op_doc20(produces => ['application/json'],
          responses => { default => { description => 'any', schema => {
              type => 'object', required => ['ok'], properties => { ok => { type => 'boolean' } } } } }));
      return 0 unless $a;
      my $errs = $a->check_response('op',
          [ 418, [ 'Content-Type' => 'application/json' ], [ '{"wrong":1}' ] ]);
      return (ref $errs eq 'ARRAY' && @$errs) ? 1 : 0;
  } },

{ id => 'swagger/responses/range-key-refused', section => '2.0 Responses Object',
  requirement => 'response keys are HTTP status codes and default: a 2XX range (3.0) is refused under 2.0',
  run => sub { croaks(op_doc20(responses => { '2XX' => { description => 'ok' } })) } },

{ id => 'swagger/responses/extensions', section => '2.0 Responses Object',
  requirement => 'an ^x- field under responses is not a status',
  run => sub { loads(op_doc20(responses => { 200 => { description => 'ok' }, 'x-note' => 1 })) } },

# ------------------------------------------------------------- Response Object

{ id => 'swagger/response/description-required', section => '2.0 Response Object',
  requirement => 'description is REQUIRED',
  run => sub { croaks(op_doc20(responses => { 200 => {} })) } },

{ id => 'swagger/response/schema-validated', section => '2.0 Response Object',
  requirement => 'a response schema is applied to the body under the produces type',
  run => sub {
      my ($a) = api(op_doc20(produces => ['application/json'],
          responses => { 200 => { description => 'ok', schema => {
              type => 'object', required => ['id'], properties => { id => { type => 'integer' } } } } }));
      return 0 unless $a;
      my $bad = $a->check_response('op', [ 200, [ 'Content-Type' => 'application/json' ], [ '{}' ] ]);
      my $ok  = $a->check_response('op', [ 200, [ 'Content-Type' => 'application/json' ], [ '{"id":1}' ] ]);
      return (ref $bad eq 'ARRAY' && @$bad && (!$ok || !@$ok)) ? 1 : 0;
  } },

{ id => 'swagger/response/schema-default-produces', section => '2.0 Response Object',
  requirement => 'with no produces anywhere a response schema is still applied (this build keys it as application/json)',
  run => sub {
      my ($a) = api(op_doc20(responses => { 200 => { description => 'ok', schema => {
              type => 'object', required => ['id'], properties => { id => { type => 'integer' } } } } }));
      return 0 unless $a;
      my $bad = $a->check_response('op', [ 200, [ 'Content-Type' => 'application/json' ], [ '{}' ] ]);
      return (ref $bad eq 'ARRAY' && @$bad) ? 1 : 0;
  } },

{ id => 'swagger/response/schema-per-produces', section => '2.0 Response Object',
  requirement => 'a response schema is declared once and keyed by every produces type (the shape; a non-JSON row is not validated, as in 3.x)',
  run => sub {
      my ($a) = api(op_doc20(produces => ['application/json', 'application/xml'],
          responses => { 200 => { description => 'ok', schema => { type => 'object' } } }));
      return 0 unless $a;
      my $r = $a->spec->{paths}{'/t'}{get}{responses}{200};
      return 0 if exists $r->{schema};
      my $c = $r->{content};
      return (ref $c eq 'HASH' && $c->{'application/json'}{schema} && $c->{'application/xml'}{schema}) ? 1 : 0;
  } },

{ id => 'swagger/response/schema-type-file', section => '2.0 Response Object',
  requirement => '"its root type value may also be file": a binary string under the produces type',
  run => sub {
      my ($a) = api(op_doc20(produces => ['application/octet-stream'],
          responses => { 200 => { description => 'bytes', schema => { type => 'file' } } }));
      return 0 unless $a;
      my $s = $a->spec->{paths}{'/t'}{get}{responses}{200}{content}{'application/octet-stream'}{schema};
      return ($s && ($s->{type} || '') eq 'string' && ($s->{format} || '') eq 'binary') ? 1 : 0;
  } },

{ id => 'swagger/response/no-schema-no-content', section => '2.0 Response Object',
  requirement => '"If this field does not exist, it means no content is returned": no content entry is invented',
  run => sub {
      my ($a) = api(op_doc20(produces => ['application/json'],
          responses => { 204 => { description => 'gone' } }));
      return 0 unless $a;
      return exists $a->spec->{paths}{'/t'}{get}{responses}{204}{content} ? 0 : 1;
  } },

{ id => 'swagger/response/headers-validated', section => '2.0 Response Object / Header Object',
  requirement => 'a declared response header is checked against its type',
  run => sub {
      my ($a) = api(op_doc20(responses => { 200 => { description => 'ok',
          headers => { 'X-R' => { type => 'integer' } } } }));
      return 0 unless $a;
      my $bad = $a->check_response('op', [ 200, [ 'X-R', 'x' ], [] ]);
      my $ok  = $a->check_response('op', [ 200, [ 'X-R', '5' ], [] ]);
      return (ref $bad eq 'ARRAY' && @$bad && (!$ok || !@$ok)) ? 1 : 0;
  } },

{ id => 'swagger/response/headers-array-csv', section => '2.0 Header Object',
  requirement => 'a response header array is csv by default',
  run => sub {
      my ($a) = api(op_doc20(responses => { 200 => { description => 'ok',
          headers => { 'X-R' => { type => 'array', items => { type => 'integer' } } } } }));
      return 0 unless $a;
      my $bad = $a->check_response('op', [ 200, [ 'X-R', 'a,b' ], [] ]);
      my $ok  = $a->check_response('op', [ 200, [ 'X-R', '1,2' ], [] ]);
      return (ref $bad eq 'ARRAY' && @$bad && (!$ok || !@$ok)) ? 1 : 0;
  } },

{ id => 'swagger/response/headers-collectionFormat-pipes', section => '2.0 Header Object',
  requirement => 'a response header array with collectionFormat pipes splits on |',
  run => sub {
      my ($a) = api(op_doc20(responses => { 200 => { description => 'ok',
          headers => { 'X-R' => { type => 'array', items => { type => 'integer' },
                                  collectionFormat => 'pipes' } } } }));
      return 0 unless $a;
      my $bad = $a->check_response('op', [ 200, [ 'X-R', '1,2' ], [] ]);
      my $ok  = $a->check_response('op', [ 200, [ 'X-R', '1|2' ], [] ]);
      return (ref $bad eq 'ARRAY' && @$bad && (!$ok || !@$ok)) ? 1 : 0;
  } },

{ id => 'swagger/response/examples-map', section => '2.0 Response Object / Example Object',
  requirement => 'examples is a map from a produces mime type to an example, and the mock serves it',
  run => sub {
      my ($a) = api(op_doc20(produces => ['application/json'],
          responses => { 200 => { description => 'ok',
              schema => { type => 'object', properties => { id => { type => 'integer' } } },
              examples => { 'application/json' => { id => 7 } } } }));
      return 0 unless $a;
      my $t = eval { $a->synthesize('op') } or return 0;
      my $body = eval { file_json_decode(join '', @{ $t->[2] }) };
      return (ref $body eq 'HASH' && ($body->{id} || 0) == 7) ? 1 : 0;
  } },

{ id => 'swagger/example/mime-not-in-produces', section => '2.0 Example Object',
  requirement => 'an example under a mime type the operation does not produce is carried without a schema and the document loads',
  run => sub {
      loads(op_doc20(produces => ['application/json'],
          responses => { 200 => { description => 'ok', examples => { 'text/plain' => 'x' } } }));
  } },

# ----------------------------------------------------------------- Header Object

{ id => 'swagger/header/type-to-schema', section => '2.0 Header Object',
  requirement => 'a Header Object type becomes the header schema',
  run => sub {
      my ($a) = api(op_doc20(responses => { 200 => { description => 'ok',
          headers => { 'X-R' => { type => 'integer', description => 'd' } } } }));
      return 0 unless $a;
      my $h = $a->spec->{paths}{'/t'}{get}{responses}{200}{headers}{'X-R'} or return 0;
      return ($h->{schema} && ($h->{schema}{type} || '') eq 'integer' && !exists $h->{type}) ? 1 : 0;
  } },

{ id => 'swagger/header/collectionFormat-tsv', section => '2.0 Header Object',
  requirement => 'a response header array with collectionFormat tsv splits on a tab',
  run => sub {
      my ($a) = api(op_doc20(responses => { 200 => { description => 'ok',
          headers => { 'X-R' => { type => 'array', items => { type => 'integer' },
                                  collectionFormat => 'tsv' } } } }));
      return 0 unless $a;
      my $bad = $a->check_response('op', [ 200, [ 'X-R', '1,2' ], [] ]);
      my $ok  = $a->check_response('op', [ 200, [ 'X-R', "1\t2" ], [] ]);
      return (ref $bad eq 'ARRAY' && @$bad && (!$ok || !@$ok)) ? 1 : 0;
  } },

{ id => 'swagger/header/no-multi', section => '2.0 Header Object',
  requirement => 'a Header Object collectionFormat is csv, ssv, tsv or pipes: multi is refused',
  run => sub { croaks(op_doc20(responses => { 200 => { description => 'ok',
      headers => { 'X-R' => { type => 'array', items => { type => 'string' },
                              collectionFormat => 'multi' } } } })) } },

{ id => 'swagger/header/request-required', section => '2.0 Parameter Object (header)',
  requirement => 'a required header parameter that is absent is refused',
  run => sub {
      my ($a) = api(op_doc20(parameters => [ { name => 'X-H', in => 'header', required => \1, type => 'string' } ]));
      return 0 unless $a;
      my ($absent) = req($a, header => {});
      my ($given)  = req($a, header => { 'x-h' => 'v' });
      return (!$absent && $given) ? 1 : 0;
  } },

# -------------------------------------------------------------- Reference Object

{ id => 'swagger/reference/definitions-rewritten', section => '2.0 Reference Object / Definitions Object',
  requirement => 'no #/definitions/, #/parameters/ or #/responses/ reference survives into ->spec',
  run => sub {
      my ($a) = api("$DIR/swagger2-everything.json");
      return 0 unless $a;
      return has_2_0_ref($a->spec) ? 0 : 1;
  } },

{ id => 'swagger/reference/position-aware', section => '2.0 Reference Object',
  requirement => 'a key spelled $ref inside a default value is user data and is not rewritten',
  run => sub {
      my ($a) = api(op_doc20(definitions => { S => { type => 'object',
          default => { '$ref' => '#/definitions/Nope' } } }));
      return 0 unless $a;
      my $d = $a->spec->{components}{schemas}{S}{default};
      return (ref $d eq 'HASH' && ($d->{'$ref'} || '') eq '#/definitions/Nope') ? 1 : 0;
  } },

{ id => 'swagger/reference/pointer-escapes', section => '2.0 Reference Object / RFC 6901',
  requirement => 'a JSON-pointer escape in a definition name (~1 for /) resolves',
  run => sub {
      my ($a) = api(body20({ '$ref' => '#/definitions/a~1b' },
          definitions => { 'a/b' => { type => 'object', required => ['x'],
                                      properties => { x => { type => 'string' } } } }));
      return 0 unless $a;
      my ($bad)  = req($a, header => $JSON, body => '{}');
      my ($good) = req($a, header => $JSON, body => '{"x":"y"}');
      return (!$bad && $good) ? 1 : 0;
  } },

{ id => 'swagger/reference/responses-rewritten', section => '2.0 Reference Object / Responses Definitions Object',
  requirement => 'a $ref to #/responses/X resolves and the response is compiled',
  run => sub {
      my ($a) = api(op_doc20(produces => ['application/json'],
          root_responses => { NotFound => { description => 'nf', schema => {
              type => 'object', required => ['code'], properties => { code => { type => 'integer' } } } } },
          responses => { 200 => { description => 'ok' }, 404 => { '$ref' => '#/responses/NotFound' } }));
      return 0 unless $a;
      my $bad = $a->check_response('op', [ 404, [ 'Content-Type' => 'application/json' ], [ '{}' ] ]);
      return (ref $bad eq 'ARRAY' && @$bad) ? 1 : 0;
  } },

{ id => 'swagger/reference/definitions-ref-body', section => '2.0 Reference Object / Definitions Object',
  requirement => 'a body schema $ref to #/definitions/X validates against X',
  run => sub {
      my ($a) = api(body20({ '$ref' => '#/definitions/X' },
          definitions => { X => { type => 'object', required => ['a'], properties => { a => { type => 'string' } } } }));
      return 0 unless $a;
      my ($bad)  = req($a, header => $JSON, body => '{}');
      my ($good) = req($a, header => $JSON, body => '{"a":"x"}');
      return (!$bad && $good) ? 1 : 0;
  } },

{ id => 'swagger/reference/siblings-ignored', section => '2.0 Reference Object / draft-04',
  requirement => 'draft-04: assertions beside a $ref are ignored',
  run => sub {
      my ($a) = api(body20({ type => 'object', properties => {
              a => { '$ref' => '#/definitions/S', maxLength => 1 } } },
          definitions => { S => { type => 'string' } }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => '{"a":"longer than one"}');
      return $ok ? 1 : 0;
  } },

# ----------------------------------------------------------------- Schema Object

{ id => 'swagger/schema/type-string-only', section => '2.0 Schema Object / Data Types',
  requirement => 'type "Value MUST be a string. Multiple types via an array are not supported"',
  run => sub { api_err(body20({ type => ['string', 'null'] })) =~ /type.*(?:string|array)/i ? 1 : 0 } },

{ id => 'swagger/schema/discriminator-string', section => '2.0 Schema Object',
  requirement => 'a string discriminator names the property that selects the inheriting schema',
  run => sub {
      my ($a) = api(body20({ '$ref' => '#/definitions/Pet' }, definitions => {
          Pet => { type => 'object', discriminator => 'kind', required => ['kind'],
                   properties => { kind => { type => 'string' } } },
          Dog => { allOf => [ { '$ref' => '#/definitions/Pet' },
                              { type => 'object', required => ['bark'],
                                properties => { bark => { type => 'string' } } } ] } }));
      return 0 unless $a;
      my ($bad)  = req($a, header => $JSON, body => '{"kind":"Dog"}');
      my ($good) = req($a, header => $JSON, body => '{"kind":"Dog","bark":"w"}');
      return (!$bad && $good) ? 1 : 0;
  } },

{ id => 'swagger/schema/discriminator-property-missing', section => '2.0 Schema Object',
  requirement => '"The property name used MUST be defined at this schema"',
  run => sub { api_err(body20({ type => 'object', discriminator => 'kind', required => ['kind'] })) =~ /discriminator.*(?:defined|propert)/i ? 1 : 0 } },

{ id => 'swagger/schema/discriminator-not-required', section => '2.0 Schema Object',
  requirement => 'the discriminator property "MUST be in the required property list"',
  run => sub { api_err(body20({ type => 'object', discriminator => 'kind',
                               properties => { kind => { type => 'string' } } })) =~ /discriminator.*required/i ? 1 : 0 } },

{ id => 'swagger/schema/nullable-dropped', section => '2.0 Schema Object (not a 2.0 keyword)',
  requirement => 'nullable is not a 2.0 keyword: draft-04 ignores it, so null is refused and ->spec carries no nullable and no type array',
  run => sub {
      my ($a) = api(body20({ type => 'object', properties => { a => { type => 'string', nullable => \1 } } }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => '{"a":null}');
      return 0 if $ok;
      my $s = $a->spec->{paths}{'/t'}{post}{requestBody}{content}{'application/json'}{schema}{properties}{a};
      return ($s && !exists $s->{nullable} && !ref $s->{type}) ? 1 : 0;
  } },

{ id => 'swagger/schema/readOnly-response-only', section => '2.0 Schema Object',
  requirement => 'readOnly "MAY be sent as part of a response but MUST NOT be sent as part of the request"',
  run => sub {
      my ($a) = api(body20({ type => 'object', properties => {
          id => { type => 'integer', readOnly => \1 }, n => { type => 'string' } } }));
      return 0 unless $a;
      my ($bad)  = req($a, header => $JSON, body => '{"n":"x","id":1}');
      my ($good) = req($a, header => $JSON, body => '{"n":"x"}');
      return (!$bad && $good) ? 1 : 0;
  } },

{ id => 'swagger/schema/exclusive-bool', section => '2.0 Schema Object / draft-04',
  requirement => 'the draft-04 boolean exclusiveMinimum excludes the bound',
  run => sub {
      my ($a) = api(body20({ type => 'object', properties => {
          a => { type => 'integer', minimum => 5, exclusiveMinimum => \1 } } }));
      return 0 unless $a;
      my ($lo) = req($a, header => $JSON, body => '{"a":5}');
      my ($hi) = req($a, header => $JSON, body => '{"a":6}');
      return (!$lo && $hi) ? 1 : 0;
  } },

{ id => 'swagger/schema/items-tuple', section => '2.0 Schema Object / draft-04',
  requirement => 'a draft-04 tuple items becomes positional prefixItems',
  run => sub {
      my ($a) = api(body20({ type => 'array', items => [ { type => 'string' }, { type => 'integer' } ] }));
      return 0 unless $a;
      my $s = $a->spec->{paths}{'/t'}{post}{requestBody}{content}{'application/json'}{schema};
      return (ref $s->{prefixItems} eq 'ARRAY' && @{ $s->{prefixItems} } == 2) ? 1 : 0;
  } },

{ id => 'swagger/schema/example-to-examples', section => '2.0 Schema Object',
  requirement => 'a schema example is carried (as the 2020-12 examples list)',
  run => sub {
      my ($a) = api(body20({ type => 'string', example => 'x' }));
      return 0 unless $a;
      my $s = $a->spec->{paths}{'/t'}{post}{requestBody}{content}{'application/json'}{schema};
      return (ref $s->{examples} eq 'ARRAY' && $s->{examples}[0] eq 'x') ? 1 : 0;
  } },

{ id => 'swagger/schema/format-byte', section => '2.0 Data Types',
  requirement => 'format byte (base64) is carried as contentEncoding',
  run => sub {
      my ($a) = api(body20({ type => 'string', format => 'byte' }));
      return 0 unless $a;
      my $s = $a->spec->{paths}{'/t'}{post}{requestBody}{content}{'application/json'}{schema};
      return ($s->{contentEncoding} || '') eq 'base64' ? 1 : 0;
  } },

{ id => 'swagger/schema/format-binary', section => '2.0 Data Types',
  requirement => 'format binary is carried as contentMediaType',
  run => sub {
      my ($a) = api(body20({ type => 'string', format => 'binary' }));
      return 0 unless $a;
      my $s = $a->spec->{paths}{'/t'}{post}{requestBody}{content}{'application/json'}{schema};
      return $s->{contentMediaType} ? 1 : 0;
  } },

{ id => 'swagger/schema/over-acceptance-stated', section => '2.0 Schema Object (this build, D6)',
  requirement => 'oneOf is not a 2.0 field and is honoured if present: an over-acceptance by decision D6, documented, not compliance',
  run => sub {
      my ($a) = api(body20({ oneOf => [ { type => 'string' }, { type => 'integer' } ] }));
      return 0 unless $a;
      my ($str)  = req($a, header => $JSON, body => '"x"');
      my ($bool) = req($a, header => $JSON, body => 'true');
      return ($str && !$bool) ? 1 : 0;
  } },

{ id => 'swagger/schema/xml-object', section => '2.0 XML Object',
  requirement => 'an XML Object on a property is carried; namespace "SHOULD be in the form of a URL"',
  run => sub {
      my ($a) = api(body20({ type => 'object', properties => { a => { type => 'string',
          xml => { name => 'A', namespace => 'https://h.test/ns', prefix => 'p', attribute => \1 } } } }));
      return 0 unless $a;
      my $s = $a->spec->{paths}{'/t'}{post}{requestBody}{content}{'application/json'}{schema};
      return ($s->{properties}{a}{xml} && $s->{properties}{a}{xml}{name} eq 'A') ? 1 : 0;
  } },

# ------------------------------------------ Security Definitions / Security Scheme

{ id => 'swagger/security/basic', section => '2.0 Security Scheme Object',
  requirement => 'type basic is HTTP Basic: the scheme compiles and a request without Authorization is denied',
  run => sub {
      my ($a) = api(op_doc20(securityDefinitions => { S => { type => 'basic' } },
                             security => [ { S => [] } ]));
      return 0 unless $a;
      my $s = $a->spec->{components}{securitySchemes}{S} or return 0;
      return 0 unless ($s->{type} || '') eq 'http' && ($s->{scheme} || '') eq 'basic';
      my $denied  = $a->check_op_security('op', {}, { S => sub { 1 } });
      my $allowed = $a->check_op_security('op', { HTTP_AUTHORIZATION => 'Basic dTpw' }, { S => sub { 1 } });
      return ($denied && !$allowed) ? 1 : 0;
  } },

{ id => 'swagger/security/apiKey-query', section => '2.0 Security Scheme Object',
  requirement => 'apiKey in query is supported',
  run => sub { loads(op_doc20(securityDefinitions => { S => { type => 'apiKey', name => 'k', in => 'query' } },
                              security => [ { S => [] } ])) } },

{ id => 'swagger/security/apiKey-header', section => '2.0 Security Scheme Object',
  requirement => 'apiKey in header is supported',
  run => sub { loads(op_doc20(securityDefinitions => { S => { type => 'apiKey', name => 'X-K', in => 'header' } },
                              security => [ { S => [] } ])) } },

{ id => 'swagger/security/apiKey-cookie-refused', section => '2.0 Security Scheme Object',
  requirement => 'apiKey in: "Valid values are query or header": cookie is refused',
  run => sub { api_err(op_doc20(securityDefinitions => { S => { type => 'apiKey', name => 'k', in => 'cookie' } },
                               security => [ { S => [] } ])) =~ /cookie/ ? 1 : 0 } },

{ id => 'swagger/security/apiKey-name-required', section => '2.0 Security Scheme Object',
  requirement => 'name is REQUIRED for apiKey',
  run => sub { api_err(op_doc20(securityDefinitions => { S => { type => 'apiKey', in => 'header' } },
                               security => [ { S => [] } ])) =~ /\bname\b/ ? 1 : 0 } },

{ id => 'swagger/security/scheme-type-unknown', section => '2.0 Security Scheme Object',
  requirement => 'type "Valid values are basic, apiKey or oauth2": anything else is refused',
  run => sub { api_err(op_doc20(securityDefinitions => { S => { type => 'digest' } },
                               security => [ { S => [] } ])) =~ /digest/ ? 1 : 0 } },

{ id => 'swagger/security/oauth2-flow-required', section => '2.0 Security Scheme Object',
  requirement => 'flow is REQUIRED for oauth2',
  run => sub { api_err(op_doc20(securityDefinitions => { S => { type => 'oauth2', scopes => {} } },
                               security => [ { S => [] } ])) =~ /\bflow\b/ ? 1 : 0 } },

{ id => 'swagger/security/oauth2-flow-unknown', section => '2.0 Security Scheme Object',
  requirement => 'flow "Valid values are implicit, password, application or accessCode"',
  run => sub { api_err(op_doc20(securityDefinitions => { S => { type => 'oauth2', flow => 'device',
      tokenUrl => 'https://h.test/t', scopes => {} } }, security => [ { S => [] } ])) =~ /\bflow\b.*device|device.*\bflow\b/ ? 1 : 0 } },

(map {
    my ($flow, $dest, $fields) = @$_;
    { id => "swagger/security/oauth2-$flow", section => '2.0 Security Scheme Object',
      requirement => "oauth2 flow $flow loads and is the 3.x $dest flow",
      run => sub {
          my ($a) = api(op_doc20(securityDefinitions => { S => { type => 'oauth2', flow => $flow,
              scopes => { read => 'r' }, %$fields } }, security => [ { S => ['read'] } ]));
          return 0 unless $a;
          my $f = $a->spec->{components}{securitySchemes}{S}{flows} or return 0;
          return (ref $f eq 'HASH' && exists $f->{$dest} && ref $f->{$dest}{scopes} eq 'HASH') ? 1 : 0;
      } };
} (
    [ 'implicit',    'implicit',          { authorizationUrl => 'https://h.test/a' } ],
    [ 'password',    'password',          { tokenUrl => 'https://h.test/t' } ],
    [ 'application', 'clientCredentials', { tokenUrl => 'https://h.test/t' } ],
    [ 'accessCode',  'authorizationCode', { authorizationUrl => 'https://h.test/a', tokenUrl => 'https://h.test/t' } ],
)),

(map {
    my ($flow, $missing, $fields) = @$_;
    { id => "swagger/security/oauth2-$missing-required-$flow", section => '2.0 Security Scheme Object',
      requirement => "$missing is REQUIRED for the $flow flow (and the croak names it)",
      run => sub { api_err(op_doc20(securityDefinitions => { S => { type => 'oauth2', flow => $flow,
          scopes => {}, %$fields } }, security => [ { S => [] } ])) =~ /\b\Q$missing\E\b/ ? 1 : 0 } };
} (
    [ 'implicit',    'authorizationUrl', {} ],
    [ 'accessCode',  'authorizationUrl', { tokenUrl => 'https://h.test/t' } ],
    [ 'password',    'tokenUrl',         {} ],
    [ 'application', 'tokenUrl',         {} ],
    [ 'accessCode',  'tokenUrl',         { authorizationUrl => 'https://h.test/a' } ],
)),

{ id => 'swagger/security/oauth2-scopes-required', section => '2.0 Security Scheme Object',
  requirement => 'scopes is REQUIRED for oauth2',
  run => sub { api_err(op_doc20(securityDefinitions => { S => { type => 'oauth2', flow => 'implicit',
      authorizationUrl => 'https://h.test/a' } }, security => [ { S => [] } ])) =~ /scopes/ ? 1 : 0 } },

# ------------------------------------------------------ Security Requirement Object

{ id => 'swagger/security-requirement/scopes-empty-off-oauth2', section => '2.0 Security Requirement Object',
  requirement => '"For other security scheme types, the array MUST be empty" (and it is refused for THAT reason, not because the scheme was not found)',
  run => sub {
      api_err(op_doc20(securityDefinitions => { K => { type => 'apiKey', name => 'k', in => 'header' } },
                       security => [ { K => ['s1'] } ])) =~ /must be an empty list/ ? 1 : 0;
  } },

{ id => 'swagger/security-requirement/oauth2-scopes-passed', section => '2.0 Security Requirement Object',
  requirement => 'for oauth2 "the value is a list of scope names required for the execution", handed to the checker',
  run => sub {
      my ($a) = api(op_doc20(securityDefinitions => { S => { type => 'oauth2', flow => 'application',
          tokenUrl => 'https://h.test/t', scopes => { read => 'r', write => 'w' } } },
          op_security => [ { S => [ 'read', 'write' ] } ]));
      return 0 unless $a;
      my $got;
      $a->check_op_security('op', { HTTP_AUTHORIZATION => 'Bearer t' },
                            { S => sub { $got = $_[3]; 1 } });
      return eq_deeply_ish($got, [ 'read', 'write' ]);
  } },

{ id => 'swagger/security-requirement/unknown-scheme-refused', section => '2.0 Security Requirement Object',
  requirement => '"The name used for each property MUST correspond to a security scheme declared in the Security Definitions"',
  run => sub { api_err(op_doc20(securityDefinitions => { K => { type => 'apiKey', name => 'k', in => 'header' } },
                               security => [ { Nope => [] } ])) =~ /Nope/ ? 1 : 0 } },

{ id => 'swagger/security-requirement/and-within', section => '2.0 Security Requirement Object',
  requirement => 'two schemes in ONE requirement object must BOTH be satisfied',
  run => sub {
      my ($a) = api(op_doc20(securityDefinitions => {
              A => { type => 'apiKey', name => 'X-A', in => 'header' },
              B => { type => 'apiKey', name => 'X-B', in => 'header' } },
          op_security => [ { A => [], B => [] } ]));
      return 0 unless $a;
      my $env  = { HTTP_X_A => 'ka', HTTP_X_B => 'kb' };
      my $both = $a->check_op_security('op', $env, { A => sub { 1 }, B => sub { 1 } });
      my $half = $a->check_op_security('op', $env, { A => sub { 1 }, B => sub { 0 } });
      return (!$both && $half) ? 1 : 0;
  } },

{ id => 'swagger/security-requirement/or-across', section => '2.0 Security Requirement Object',
  requirement => '"there is a logical OR between the security requirements"',
  run => sub {
      my ($a) = api(op_doc20(securityDefinitions => {
              A => { type => 'apiKey', name => 'X-A', in => 'header' },
              B => { type => 'apiKey', name => 'X-B', in => 'header' } },
          op_security => [ { A => [] }, { B => [] } ]));
      return 0 unless $a;
      my $env     = { HTTP_X_A => 'ka', HTTP_X_B => 'kb' };
      my $second  = $a->check_op_security('op', $env, { A => sub { 0 }, B => sub { 1 } });
      my $neither = $a->check_op_security('op', $env, { A => sub { 0 }, B => sub { 0 } });
      return (!$second && $neither) ? 1 : 0;
  } },

# ------------------------------------------------ the runtime surface, in 2.0 words

{ id => 'swagger/body/json-validated', section => '2.0 Parameter Object (body)',
  requirement => 'a JSON body is validated against the body parameter schema',
  run => sub {
      my ($a) = api(body20({ type => 'object', required => ['a'], properties => { a => { type => 'string' } } }));
      return 0 unless $a;
      my ($ok) = req($a, header => $JSON, body => '{}');
      return $ok ? 0 : 1;
  } },

{ id => 'swagger/body/415-undeclared-type', section => '2.0 Operation Object (consumes)',
  requirement => 'a body whose media type is not in consumes is refused',
  run => sub {
      my ($a) = api(body20({ type => 'object' }));
      return 0 unless $a;
      my ($ok) = req($a, header => { 'content-type' => 'application/xml' }, body => '<a/>');
      return $ok ? 0 : 1;
  } },

{ id => 'swagger/body/urlencoded-validated', section => '2.0 Parameter Object (formData)',
  requirement => 'an application/x-www-form-urlencoded body is validated against the formData parameters',
  run => sub {
      my ($a) = api(form20([ { name => 'a', type => 'string', required => \1 } ]));
      return 0 unless $a;
      my ($bad)  = req($a, header => $FORM, body => 'nope=1');
      my ($good) = req($a, header => $FORM, body => 'a=1');
      return (!$bad && $good) ? 1 : 0;
  } },

{ id => 'swagger/body/multipart-validated', section => '2.0 Parameter Object (formData)',
  requirement => 'a multipart/form-data body is validated against the formData parameters',
  run => sub {
      my ($a) = api(form20([ { name => 'a', type => 'string', required => \1 } ],
                           consumes => ['multipart/form-data']));
      return 0 unless $a;
      my $mp = { 'content-type' => 'multipart/form-data; boundary=xx' };
      my ($bad)  = req($a, header => $mp,
          body => "--xx\r\nContent-Disposition: form-data; name=\"nope\"\r\n\r\n1\r\n--xx--\r\n");
      my ($good) = req($a, header => $mp,
          body => "--xx\r\nContent-Disposition: form-data; name=\"a\"\r\n\r\n1\r\n--xx--\r\n");
      return (!$bad && $good) ? 1 : 0;
  } },

{ id => 'swagger/body/formdata-type-validated', section => '2.0 Parameter Object (formData)',
  requirement => 'a formData parameter type is validated',
  run => sub {
      my ($a) = api(form20([ { name => 'n', type => 'integer' } ]));
      return 0 unless $a;
      my ($bad)  = req($a, header => $FORM, body => 'n=x');
      my ($good) = req($a, header => $FORM, body => 'n=5');
      return (!$bad && $good) ? 1 : 0;
  } },

{ id => 'swagger/body/formdata-needs-form-consumes', section => '2.0 Parameter Object (formData)',
  requirement => 'a formData parameter under a consumes list with no form type can never be carried and is refused',
  run => sub { api_err(form20([ { name => 'a', type => 'string' } ], consumes => ['application/json'])) =~ /formData.*consumes|consumes.*formData/i ? 1 : 0 } },

{ id => 'swagger/client/body-json', section => '2.0 Parameter Object (body), client',
  requirement => 'the client sends a body parameter as application/json when consumes says so',
  run => sub {
      my ($a) = api(body20({ type => 'object' }));
      return 0 unless $a;
      my $c = eval { Open::API::Client->new(api => $a, base_url => 'http://h.test') };
      return 0 unless $c;
      my ($b, $ct) = eval { $c->_request_body('op', { body => { a => 'x' } }) };
      return (defined $ct && $ct =~ m{^application/json} && defined $b && $b =~ /^\{/) ? 1 : 0;
  } },

{ id => 'swagger/client/body-form', section => '2.0 Parameter Object (formData), client',
  requirement => 'the client sends formData as x-www-form-urlencoded, not JSON',
  run => sub {
      my ($a) = api(form20([ { name => 'a', type => 'string' } ]));
      return 0 unless $a;
      my $c = eval { Open::API::Client->new(api => $a, base_url => 'http://h.test') };
      return 0 unless $c;
      my ($b, $ct) = eval { $c->_request_body('op', { body => { a => 'x' } }) };
      return (defined $ct && $ct =~ m{^application/x-www-form-urlencoded} && defined $b && $b !~ /^\{/) ? 1 : 0;
  } },

(map {
    my ($slug, $consumes) = @$_;
    { id => "swagger/roundtrip/body-$slug", section => '2.0 Parameter Object, client and server',
      requirement => "a $slug body the client builds from a 2.0 document is accepted and decoded by its server",
      run => sub {
          my ($a) = $slug eq 'json'
              ? api(body20({ type => 'object', required => ['a'],
                             properties => { a => { type => 'string' }, b => { type => 'string' } } }))
              : api(form20([ { name => 'a', type => 'string', required => \1 },
                             { name => 'b', type => 'string' } ], consumes => [ $consumes ]));
          return 0 unless $a;
          my $c = eval { Open::API::Client->new(api => $a, base_url => 'http://h.test') };
          return 0 unless $c;
          my ($b, $ct) = eval { $c->_request_body('op', { body => { a => 'x', b => 'y' } }) };
          return 0 unless defined $b && defined $ct;
          my ($ok, $res) = $a->validate_request(op => { header => { 'content-type' => $ct }, body => $b });
          return 0 unless $ok;
          return eq_deeply_ish($res->{body}, { a => 'x', b => 'y' });
      } };
} (
    [ 'json',       'application/json' ],
    [ 'urlencoded', 'application/x-www-form-urlencoded' ],
    [ 'multipart',  'multipart/form-data' ],
)),


);

# ---- the expected-fail list -------------------------------------------------

my %EXPECTED;
if (open my $fh, '<', $FAIL) {
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*(#|$)/;
        my ($id, $why) = $line =~ /^(\S+)\s*(.*)$/;
        $EXPECTED{$id} = defined $why ? $why : '';
    }
    close $fh;
}

# ---- run --------------------------------------------------------------------

my ($met, $gap, $promote) = (0, 0, 0);

for my $c (@CASES) {
    my $id = $c->{id};
    local $CURRENT_CASE = $id;
    my $ok = eval { $c->{run}->() ? 1 : 0 };
    my $err = $@;
    if ($err) {
        $ok = 0;
        diag("$id threw: $err") unless exists $EXPECTED{$id};
    }
    my $listed = exists $EXPECTED{$id};

    if ($ok && !$listed) {
        $met++;
        pass("$id - $c->{requirement}");
    }
    elsif ($ok && $listed) {
        $promote++;
        fail("$id is listed in expected-fail.txt but now MEETS the requirement"
             . " - remove the line, the list only shrinks");
    }
    elsif (!$ok && $listed) {
        $gap++;
        pass("$id - known gap: $EXPECTED{$id}");
    }
    else {
        fail("$id - $c->{section}: $c->{requirement}");
        diag("  not met, and not listed in t/compliance/expected-fail.txt");
    }
}

diag(sprintf("compliance: %d met, %d known gaps, %d to promote, %d cases total",
             $met, $gap, $promote, scalar @CASES));
# Reported because it is the one number the vendored suite can move without
# failing anything: a group newly skipped is a schema this build stopped
# accepting, which looks like silence rather than a failure.
my $jss_n    = grep { $_->{id} =~ m{^jsonschema/} }    @CASES;
my $jssref_n = grep { $_->{id} =~ m{^jsonschemaref/} } @CASES;
my $jss30_n  = grep { $_->{id} =~ m{^jsonschema30/} }  @CASES;
diag(sprintf("  of which %d are the vendored JSON Schema suite: %d inline, "
             . "%d behind a component \$ref, %d as a 3.0/3.1 twin",
             $jss_n + $jssref_n + $jss30_n, $jss_n, $jssref_n, $jss30_n));
diag(sprintf("  skipped: %d inexpressible in OpenAPI, %d not expressible as a "
             . "component (root-anchored self-pointers), %d not expressible "
             . "in 3.0 (2020-12 keywords), %d where 3.0 differs on purpose "
             . "(\$ref siblings)",
             $JSS_SKIPPED, $JSS_REF_SKIPPED, $JSS_30_SKIPPED, $JSS_30_REFSIB));

# ...and asserted, not merely reported. If t/compliance/jsonschema/ does not
# ship, or a read fails, the generator returns an empty list and every other
# case still passes: the suite would go green having tested none of it. A
# floor well under the real count (108 at the time of writing) catches that
# without breaking when the vendored files are updated upstream.
cmp_ok($jss_n, '>=', 350,
       'the vendored JSON Schema suite contributed its inline cases')
    or diag("  t/compliance/jsonschema/ is missing or unreadable - the suite "
            . "was NOT exercised, however green the rest of this file looks");
cmp_ok($jssref_n, '>=', 300,
       'the vendored suite also ran behind a component $ref')
    or diag("  the referenced placement is what exercises the components -> "
            . "\$defs rewrite; inline alone hands the schema over untouched");
cmp_ok($jss30_n, '>=', 250,
       'the vendored suite also ran as a 3.0/3.1 twin')
    or diag("  the twin is what exercises the 3.0 converter over every "
            . "schema; without it the 3.0 files here test 3.1 only");

my $jss20_n    = grep { $_->{id} =~ m{^jsonschema20/} }    @CASES;
my $jss20ref_n = grep { $_->{id} =~ m{^jsonschema20ref/} } @CASES;
my $sw2_n      = grep { $_->{id} =~ m{^swagger2/.*/loads$} } @CASES;
diag(sprintf("  2.0: %d as a 2.0/3.1 twin, %d behind #/definitions/; skipped: %d not "
             . "expressible in 2.0 (draft-04 subset), %d where draft-04 ignores "
             . "\$ref siblings; %d official 2.0 documents vendored",
             $jss20_n, $jss20ref_n, $JSS_20_SKIPPED, $JSS_20_REFSIB, $sw2_n));
# Floors for the 2.0 placements and the vendored corpus, set from the counts
# measured when phase 02 of plan_openapi_v2 wrote them (see 02's Todo), well
# under the real numbers so an upstream refresh does not break them, and high
# enough that a missing directory or a broken filter cannot pass in silence.
cmp_ok($jss20_n, '>=', 150,
       'the vendored suite also ran as a 2.0/3.1 twin')
    or diag("  the 2.0 twin is what exercises the pre-pass over every draft-04 schema");
cmp_ok($jss20ref_n, '>=', 130,
       'the vendored suite also ran behind #/definitions/')
    or diag("  this placement is what exercises the 2.0 \$ref rewrite");
cmp_ok($sw2_n, '>=', 5,
       'the official 2.0 documents are present and each has its cases')
    or diag("  t/compliance/swagger2/ is missing or unreadable");

done_testing;

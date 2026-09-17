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

# A compliance matrix for OpenAPI 3.0 and 3.1, walked object by object.
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

sub api   { my ($s, %o) = @_;
            my $a = eval { Open::API->new(spec => $s, %o) }; return ($a, $@) }
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

done_testing;

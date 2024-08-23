package Plack::App::Catmandu::OAI;

our $VERSION = '0.02';

use Catmandu::Sane;
use Catmandu::Util qw(:is io);
use Catmandu::Error;
use Catmandu;
use Moo;
use Types::Standard qw(Str ArrayRef HashRef Enum Int CodeRef ScalarRef);
use Types::Common::String qw(NonEmptyStr);
use Types::Common::Numeric qw(PositiveInt);
use Catmandu::Exporter::Template;
use Catmandu::Fix;
use Data::MessagePack;
use MIME::Base64 qw(encode_base64url decode_base64url);
use DateTime;
use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;
use Try::Tiny;
use Plack::Request;
use namespace::clean;
use feature qw(signatures);
no warnings qw(experimental::signatures);

has store_name => (
    is => 'ro',
    isa => Str,
    init_arg => 'store',
);

has bag_name => (
    is => 'ro',
    isa => Str,
    init_arg => 'bag',
);

has fix => (
    is => 'ro',
    coerce => sub {
        if (is_string($_[0])) {
            $_[0] = Catmandu::Fix->new(fixes => [$_[0]]);
        } elsif (is_array_ref($_[0])) {
            $_[0] = Catmandu::Fix->new(fixes => $_[0]);
        }
        $_[0];
    },
);

has deleted => (
    is => 'ro',
    isa => CodeRef,
    default => sub { sub {0}; },
);

has set_specs_for => (
    is => 'ro',
    isa => CodeRef,
    default => sub { sub {[];}; },
);

has datestamp_field => (
    is => 'ro',
    isa => NonEmptyStr,
    required => 1,
);

has datestamp_index => (
    is => 'lazy',
    isa => NonEmptyStr,
);

has repositoryName => (
    is => 'ro',
    isa => NonEmptyStr,
    required => 1,
);

has adminEmail => (
    is => 'ro',
    isa => ArrayRef[NonEmptyStr],
);

has compression => (
    is => 'ro',
    isa => ArrayRef[NonEmptyStr],
);

has description => (
    is => 'ro',
    isa => ArrayRef[NonEmptyStr],
);

has earliestDatestamp => (
    is => 'ro',
    isa => NonEmptyStr,
);

has deletedRecord => (
    is => 'ro',
    isa => Enum[qw(no persistent transient)],
    default => sub { 'no'; },
);

has repositoryIdentifier => (
    is => 'ro',
    isa => NonEmptyStr,
    required => 1,
);

has cql_filter => (
    is => 'ro',
    isa => NonEmptyStr,
);

has default_search_params => (
    is => 'ro',
    isa => HashRef,
);

has search_strategy => (
    is => 'ro',
    isa => Enum[qw(paginate es.scroll filter)],
    default => sub { 'paginate'; },
);

has limit => (
    is => 'ro',
    isa => PositiveInt,
    default => sub { 100; },
);

has delimiter => (
    is => 'ro',
    isa => NonEmptyStr,
    default => sub { ':'; },
);

has sampleIdentifier => (
    is => 'ro',
    isa => NonEmptyStr,
    required => 1,
);

has xsl_stylesheet => (
    is => 'ro',
    isa => NonEmptyStr,
);

has metadata_formats => (
    is => 'ro',
    isa => ArrayRef[HashRef],
    default => sub { []; },
    coerce => sub {
        for my $format (@{$_[0]}) {
            if (my $fix = $format->{fix}) {
                $format->{fix} = Catmandu::Fix->new(fixes => $fix);
            }
        }
        $_[0];
    },
);

has sets => (
    is => 'ro',
    isa => ArrayRef[HashRef],
    default => sub { []; },
);

has template_options => (
    is => 'ro',
    isa => HashRef,
    default => sub { +{}; },
);

has granularity => (
    is => 'ro',
    isa => NonEmptyStr,
    default => sub { 'YYYY-MM-DDThh:mm:ssZ' },
);

has collectionIcon => (
    is => 'ro',
    isa => HashRef,
);

has get_record_cql_pattern => (
    is => 'lazy',
    isa => NonEmptyStr,
);

has datestamp_pattern => (
    is => 'ro',
    isa => NonEmptyStr,
);

# internal methods
has _bag => (
    is => 'lazy',
    init_arg => undef,
);

has _datestamp_formatter => (
    is => 'lazy',
    init_arg => undef,
);

has _message_pack => (
    is => 'ro',
    lazy => 1,
    default => sub { Data::MessagePack->new->utf8; },
    init_arg => undef,
);

has _templ_error => (
    is => 'rw',
    isa => ScalarRef[Str],
    init_arg => undef,
);

has _templ_get_record => (
    is => 'rw',
    isa => ScalarRef[Str],
    init_arg => undef,
);

has _templ_identify => (
    is => 'rw',
    isa => ScalarRef[Str],
    init_arg => undef,
);

has _templ_list_identifiers => (
    is => 'rw',
    isa => ScalarRef[Str],
    init_arg => undef,
);

has _templ_list_records => (
    is => 'rw',
    isa => ScalarRef[Str],
    init_arg => undef,
);

has _templ_list_metadata_formats => (
    is => 'rw',
    isa => ScalarRef[Str],
    init_arg => undef,
);

has _templ_list_sets => (
    is => 'rw',
    isa => ScalarRef[Str],
    init_arg => undef,
);

sub _serialize_token ($self, $token) {
    encode_base64url($self->_message_pack->pack($token));
}

sub _deserialize_token ($self, $token) {
    $self->_message_pack->unpack(decode_base64url($token));
}

sub _build_datestamp_index ($self) {
    $self->datestamp_field;
}

sub _get_record_cql_pattern ($self) {
    $self->bag->id_key . ' exact "%s"';
}

sub _build__bag ($self) {
    Catmandu->store($self->store_name)->bag($self->bag_name);
}

sub _build__datestamp_formatter ($self) {
    my $datestamp_parser;
    if ($self->datestamp_pattern) {
        $datestamp_parser = DateTime::Format::Strptime->new(
            pattern  => $self->datestamp_pattern,
            on_error => 'undef',
        );
    }

    $datestamp_parser ? sub {
        $datestamp_parser->parse_datetime($_[0])->iso8601 . 'Z';
    } : sub {
        $_[0];
    };
}

sub BUILD {
    my ($self, $args) = @_;

    if ($self->search_strategy eq 'es.scroll') {
        $self->default_search_params->{scroll} //= '10m';
    }


    my $ns = "oai:".$self->repositoryIdentifier.":";

    my $branding = "";
    if (my $icon = $self->collectionIcon) {
        if (my $url = $icon->{url}) {
            $branding .= <<TT;
<description>
<branding xmlns="http://www.openarchives.org/OAI/2.0/branding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/branding/ http://www.openarchives.org/OAI/2.0/branding.xsd">
<collectionIcon>
<url>$url</url>
TT
            for my $tag (qw(link title width height)) {
                my $val = $icon->{$tag} // next;
                $branding .= "<$tag>$val</$tag>\n";
            }

            $branding .= <<TT;
</collectionIcon>
</branding>
</description>
TT
        }
    }

    my $xsl_stylesheet = "";
    if (my $xsl_path = $self->xsl_stylesheet) {
        $xsl_stylesheet
            = "<?xml-stylesheet type='text/xsl' href='$xsl_path' ?>";
    }

    my $template_header = <<TT;
<?xml version="1.0" encoding="UTF-8"?>
$xsl_stylesheet
<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
<responseDate>[% response_date %]</responseDate>
[%- IF params.resumptionToken %]
<request verb="[% params.verb %]" resumptionToken="[% params.resumptionToken %]">[% uri_base %]</request>
[%- ELSE %]
<request[% FOREACH param IN params %] [% param.key %]="[% param.value | xml %]"[% END %]>[% uri_base %]</request>
[%- END %]
TT

    my $template_footer = <<TT;
</OAI-PMH>
TT

    my $template_error = <<TT;
$template_header
[%- FOREACH error IN errors %]
<error code="[% error.0 %]">[% error.1 | xml %]</error>
[%- END %]
$template_footer
TT
    $self->_templ_error(\$template_error);

    my $template_record_header = <<TT;
<header[% IF deleted %] status="deleted"[% END %]>
    <identifier>${ns}[% id %]</identifier>
    <datestamp>[% datestamp %]</datestamp>
    [%- FOREACH s IN setSpec %]
    <setSpec>[% s %]</setSpec>
    [%- END %]
</header>
TT

    my $template_get_record = <<TT;
$template_header
<GetRecord>
<record>
$template_record_header
[%- UNLESS deleted %]
<metadata>
[% metadata %]
</metadata>
[%- END %]
</record>
</GetRecord>
$template_footer
TT
    $self->_templ_get_record(\$template_get_record);

    my @identify_extra_fields;
    for my $field (qw(adminEmail description compression)) {
        my $vals = $self->$field;
        push @identify_extra_fields,
            join('', map {"<$field>$_</$field>"} @$vals);
    }

    my $repositoryName = $self->repositoryName;
    my $deletedRecord = $self->deletedRecord;
    my $granularity = $self->granularity;
    my $repositoryIdentifier = $self->repositoryIdentifier;
    my $delimiter = $self->delimiter;
    my $sampleIdentifier = $self->sampleIdentifier;

    my $template_identify = <<TT;
$template_header
<Identify>
<repositoryName>$repositoryName</repositoryName>
<baseURL>[% uri_base %]</baseURL>
<protocolVersion>2.0</protocolVersion>
<earliestDatestamp>[% earliest_datestamp %]</earliestDatestamp>
<deletedRecord>$deletedRecord</deletedRecord>
<granularity>$granularity</granularity>
<description>
    <oai-identifier xmlns="http://www.openarchives.org/OAI/2.0/oai-identifier"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai-identifier http://www.openarchives.org/OAI/2.0/oai-identifier.xsd">
        <scheme>oai</scheme>
        <repositoryIdentifier>$repositoryIdentifier</repositoryIdentifier>
        <delimiter>$delimiter</delimiter>
        <sampleIdentifier>$sampleIdentifier</sampleIdentifier>
    </oai-identifier>
</description>
@identify_extra_fields
$branding
</Identify>
$template_footer
TT

    $self->_templ_identify(\$template_identify);

    my $template_list_identifiers = <<TT;
$template_header
<ListIdentifiers>
[%- FOREACH records %]
$template_record_header
[%- END %]
[%- IF resumption_token %]
<resumptionToken completeListSize="[% total %]">[% resumption_token %]</resumptionToken>
[%- ELSE %]
<resumptionToken completeListSize="[% total %]"/>
[%- END %]
</ListIdentifiers>
$template_footer
TT

    $self->_templ_list_identifiers(\$template_list_identifiers);

    my $template_list_records = <<TT;
$template_header
<ListRecords>
[%- FOREACH records %]
<record>
$template_record_header
[%- UNLESS deleted %]
<metadata>
[% metadata %]
</metadata>
[%- END %]
</record>
[%- END %]
[%- IF resumption_token %]
<resumptionToken completeListSize="[% total %]">[% resumption_token %]</resumptionToken>
[%- ELSE %]
<resumptionToken completeListSize="[% total %]"/>
[%- END %]
</ListRecords>
$template_footer
TT

    $self->_templ_list_records(\$template_list_records);

    my $template_list_metadata_formats = <<TT;
$template_header
<ListMetadataFormats>
TT
    for my $format (@{$self->metadata_formats}) {
        $template_list_metadata_formats .= <<TT;
<metadataFormat>
    <metadataPrefix>$format->{metadataPrefix}</metadataPrefix>
    <schema>$format->{schema}</schema>
    <metadataNamespace>$format->{metadataNamespace}</metadataNamespace>
</metadataFormat>
TT
    }
    $template_list_metadata_formats .= <<TT;
</ListMetadataFormats>
$template_footer
TT

    $self->_templ_list_metadata_formats(\$template_list_metadata_formats);

    my $template_list_sets = <<TT;
$template_header
<ListSets>
TT
    for my $set (@{$self->sets}) {
        $template_list_sets .= <<TT;
<set>
    <setSpec>$set->{setSpec}</setSpec>
    <setName>$set->{setName}</setName>
TT

        my $set_descriptions = $set->{setDescription} // [];
        $set_descriptions = [$set_descriptions]
            unless is_array_ref($set_descriptions);
        $template_list_sets .= "<setDescription>$_</setDescription>"
            for @$set_descriptions;

        $template_list_sets .= <<TT;
</set>
TT
    }
    $template_list_sets .= <<TT;
</ListSets>
$template_footer
TT
    $self->_templ_list_sets(\$template_list_sets);
}

sub _tt_process ($self, $tmpl, $data) {
    my $out      = "";
    open my $fh, '>:utf8', \$out;
    my $exporter = Catmandu::Exporter::Template->new(
        template => $tmpl,
        fh => $fh,
    );
    $exporter->add($data);
    $exporter->commit;
    $out;
}

sub _render ($self, $body) {
    [200, ['Content-Type' => 'application/xml; charset=utf-8'], [$body]];
}

sub _render_error ($self, $vars) {
    $self->_render($self->_tt_process($self->_templ_error, $vars));
}

my $VERBS = {
    GetRecord => {
        valid    => {metadataPrefix => 1, identifier => 1},
        required => [qw(metadataPrefix identifier)],
    },
    Identify        => {valid => {}, required => []},
    ListIdentifiers => {
        valid => {
            metadataPrefix  => 1,
            from            => 1,
            until           => 1,
            set             => 1,
            resumptionToken => 1
        },
        required => [qw(metadataPrefix)],
    },
    ListMetadataFormats =>
        {valid => {identifier => 1, resumptionToken => 1}, required => []},
    ListRecords => {
        valid => {
            metadataPrefix  => 1,
            from            => 1,
            until           => 1,
            set             => 1,
            resumptionToken => 1
        },
        required => [qw(metadataPrefix)],
    },
    ListSets => {valid => {resumptionToken => 1}, required => []},
};

sub _new_token ($self, $hits, $params, $from, $until, $old_token = undef) {
    my $n = $old_token && $old_token->{_n} ? $old_token->{_n} : 0;
    $n += $hits->size;

    return unless $n < $hits->total;

    my $strategy = $self->search_strategy;

    my $token;

    if ($strategy eq 'paginate' && $hits->more) {
        $token = {start => $hits->start + $hits->limit};
    }
    elsif ($strategy eq 'es.scroll' && exists $hits->{scroll_id}) {
        $token = {scroll_id => $hits->{scroll_id}};
    }
    elsif ($strategy eq 'filter' && $hits->more) {
        $token = {_id => $hits->hits->[$hits->size - 1]->{_id}};
    }
    else {
        return;
    }

    $token->{_n} = $n;
    $token->{_s} = $params->{set} if defined $params->{set};
    $token->{_m} = $params->{metadataPrefix}
        if defined $params->{metadataPrefix};
    $token->{_f} = $from  if defined $from;
    $token->{_u} = $until if defined $until;
    $token;
}

sub _search ($self, $q, $token = undef) {
    my $strategy = $self->search_strategy;

    my %args = (
        %{$self->default_search_params},
        limit     => $self->limit,
        cql_query => $q,
    );
    if ($token) {
        if ($strategy eq 'paginate' && exists $token->{start}) {
            $args{start} = $token->{start};
        }
        elsif ($strategy eq 'es.scroll' && exists $token->{scroll_id}) {
            $args{scroll_id} = $token->{scroll_id};
        }
        elsif ($strategy eq 'filter' && $token->{_id}) {
            my $cql_query = $args{cql_query};
            if (is_string($cql_query)) {
                $cql_query .= qq( and _id > "$token->{_id}");
            } else {
                $cql_query = qq(_id > "$token->{_id}");
            }
            $args{cql_query} = $cql_query;
        }
    }

    $self->_bag->search(%args);
}

sub to_app ($self) {
    sub {
        my $env = $_[0];

        my $req = Plack::Request->new($env);

        return not_found() if $req->method() ne "GET";

        my $params  = $req->query_parameters();
        my $path    = $req->path_info();
        my $uri_base = $req->base();
        my $response_date = DateTime->now->iso8601 . 'Z';
        my $errors = [];
        my $format;
        my $set;
        my $ns = "oai:".$self->repositoryIdentifier.":";
        my $resumptionToken = $params->get('resumptionToken');
        my $verb = $params->get('verb');
        my $vars = {
            uri_base      => $uri_base->as_string,
            request_uri   => $uri_base . $path,
            response_date => $response_date,
            errors        => $errors,
        };

        if ($verb and my $spec = $VERBS->{$verb}) {
            my $valid    = $spec->{valid};
            my $required = $spec->{required};

            if ($valid->{resumptionToken} && exists $params->{resumptionToken}) {
                if (keys(%$params) > 2) {
                    push @$errors, [badArgument => "resumptionToken cannot be combined with other parameters"];
                }
            } else {
                for my $key (keys %$params) {
                    next if $key eq 'verb';
                    unless ($valid->{$key}) {
                        push @$errors, [badArgument => "parameter $key is illegal"];
                    }
                }
                for my $key (@$required) {
                    unless (exists $params->{$key}) {
                        push @$errors, [badArgument => "parameter $key is missing"];
                    }
                }
            }
        } else {
            push @$errors, [badVerb => "illegal OAI verb"];
        }

        if (@$errors) {
            return $self->_render_error($vars);
        }

        $vars->{params} = +{$params->flatten};

        if ($resumptionToken) {
            unless (is_string($resumptionToken)) {
                push @$errors,
                    [badResumptionToken =>
                        "resumptionToken is not in the correct format"
                    ];
            }

            if ($verb eq 'ListSets') {
                push @$errors,
                    [badResumptionToken => "resumptionToken isn't necessary"];
            } else {
                try {
                    my $token = $self->_deserialize_token($resumptionToken);
                    $params->{set} = $token->{_s} if defined $token->{_s};
                    $params->{metadataPrefix} = $token->{_m}
                        if defined $token->{_m};
                    $params->{from}  = $token->{_f} if defined $token->{_f};
                    $params->{until} = $token->{_u} if defined $token->{_u};
                    $vars->{token}   = $token;
                }
                catch {
                    push @$errors,
                        [badResumptionToken =>
                            "resumptionToken is not in the correct format"
                        ];
                };
            }
        }

        if (my $setSpec = $params->get('set')) {
            if (scalar(@{$self->sets}) == 0) {
                push @$errors, [noSetHierarchy => "sets are not supported"];
            } else {
                for (@{$self->sets}) {
                    if ($_->{setSpec} eq $setSpec) {
                        $set = $_;
                        last;
                    }
                }
                unless ($self) {
                    push @$errors, [badArgument => "set does not exist"];
                }
            }
        }

        if (my $metadataPrefix = $params->get('metadataPrefix')) {
            for (@{$self->metadata_formats}) {
                if ($metadataPrefix eq $_->{metadataPrefix}) {
                    $format = $_;
                    last;
                }
            }
            unless ($format) {
                push @$errors,
                    [cannotDisseminateFormat =>
                        "metadataPrefix $metadataPrefix is not supported"
                    ];
            }
        }

        if (@$errors) {
            return $self->_render_error($vars);
        }

        if ($verb eq 'GetRecord') {
            my $id = $params->get('identifier');
            $id =~ s/^$ns//;

            my $rec = $self->_bag->search(
                %{$self->default_search_params},
                cql_query => sprintf($self->get_record_cql_pattern, $id),
                start     => 0,
                limit     => 1,
            )->first;

            if (defined $rec) {
                if ($self->fix) {
                    $rec = $self->fix->fix($rec);
                }

                $vars->{id}        = $id;
                $vars->{datestamp} = $self->_datestamp_formatter->($rec->{$self->datestamp_field()});
                $vars->{deleted} = $self->deleted->($rec);
                $vars->{setSpec} = $self->set_specs_for->($rec);
                my $metadata = "";
                my $exporter = Catmandu::Exporter::Template->new(
                    %{$self->template_options},
                    template => $format->{template},
                    file     => \$metadata,
                );
                if ($format->{fix}) {
                    $rec = $format->{fix}->fix($rec);
                }
                $exporter->add($rec);
                $exporter->commit;
                $vars->{metadata} = $metadata;
                unless ($vars->{deleted} && $self->deletedRecord eq 'no') {
                    return $self->_render($self->_tt_process($self->_templ_get_record, $vars));
                }
            }
            push @$errors,
                [idDoesNotExist =>
                    "identifier $params->{identifier} is unknown or illegal"
                ];
            return $self->_render_error($vars);

        } elsif ($verb eq 'Identify') {

            $vars->{earliest_datestamp} = $self->earliestDatestamp || do {
                my $hits = $self->_bag->search(
                    %{$self->default_search_params},
                    cql_query => $self->cql_filter || 'cql.allRecords',
                    limit     => 1,
                    sru_sortkeys => $self->datestamp_index.",,1",
                );
                if (my $rec = $hits->first) {
                    $self->_datestamp_formatter->($rec->{$self->datestamp_field});
                } else {
                    '1970-01-01T00:00:01Z';
                }
            };
            return $self->_render($self->_tt_process($self->_templ_identify, $vars));

        } elsif ($verb eq 'ListIdentifiers' || $verb eq 'ListRecords') {

            my $from  = $params->get('from');
            my $until = $params->get('until');

            for my $datestamp (($from, $until)) {
                $datestamp || next;
                if ($datestamp !~ /^\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2}Z)?$/o) {
                    push @$errors,
                        [badArgument =>
                            "datestamps must have the format YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ"
                        ];
                    return $self->_render_error($vars);
                }
            }

            if ($from && $until && length($from) != length($until)) {
                push @$errors,
                    [
                    badArgument => "datestamps must have the same granularity"
                    ];
                return $self->_render_error($vars);
            }

            if ($from && $until && $from gt $until) {
                push @$errors,
                    [badArgument => "from is more recent than until"];
                return $self->_render_error($vars);
            }

            if ($from && length($from) == 10) {
                $from = "${from}T00:00:00Z";
            }
            if ($until && length($until) == 10) {
                $until = "${until}T23:59:59Z";
            }

            my @cql;
            my $cql_from  = $from;
            my $cql_until = $until;
            if (my $pattern = $self->datestamp_pattern) {
                $cql_from
                    = DateTime::Format::ISO8601->parse_datetime($from)
                    ->strftime($pattern)
                    if $cql_from;
                $cql_until
                    = DateTime::Format::ISO8601->parse_datetime($until)
                    ->strftime($pattern)
                    if $cql_until;
            }

            push @cql, "(".$self->cql_filter.")" if $self->cql_filter;
            push @cql, qq|($format->{cql})|         if $format->{cql};
            push @cql, qq|($set->{cql})|            if $set && $set->{cql};
            push @cql, "(".$self->datestamp_index ." >= \"$cql_from\")" if $cql_from;
            push @cql, "(".$self->datestamp_index ." <= \"$cql_until\")" if $cql_until;
            unless (@cql) {
                push @cql, "(cql.allRecords)";
            }

            my $search = $self->_search(join(' and ', @cql), $vars->{token});

            unless ($search->total) {
                push @$errors, [noRecordsMatch => "no records found"];
                return $self->_render_error($vars);
            }

            if (
                defined(
                    my $new_token = $self->_new_token(
                        $search, $params,
                        $from,    $until,  $vars->{token}
                    )
                )
                )
            {
                $vars->{resumption_token} = $self->_serialize_token($new_token);
            }

            $vars->{total} = $search->total;

            if ($verb eq 'ListIdentifiers') {
                $vars->{records} = [
                    map {
                        my $rec = $_;
                        my $id  = $rec->{$self->_bag->id_key};

                        if ($self->fix) {
                            $rec = $self->fix->fix($rec);
                        }

                        {
                            id        => $id,
                            datestamp => $self->_datestamp_formatter->(
                                $rec->{$self->datestamp_field()}
                            ),
                            deleted => $self->deleted->($rec),
                            setSpec => $self->set_specs_for->($rec),
                        };
                    } @{$search->hits}
                ];
                return $self->_render($self->_tt_process($self->_templ_list_identifiers, $vars));
            } else {
                $vars->{records} = [
                    map {
                        my $rec = $_;
                        my $id  = $rec->{$self->_bag->id_key};

                        if ($self->fix) {
                            $rec = $self->fix->fix($rec);
                        }

                        my $deleted = $self->deleted->($rec);

                        my $rec_vars = {
                            id        => $id,
                            datestamp => $self->_datestamp_formatter->(
                                $rec->{$self->datestamp_field()}
                            ),
                            deleted => $deleted,
                            setSpec => $self->set_specs_for->($rec),
                        };
                        unless ($deleted) {
                            my $metadata = "";
                            my $exporter = Catmandu::Exporter::Template->new(
                                %{$self->template_options},
                                template => $format->{template},
                                file     => \$metadata,
                            );
                            if ($format->{fix}) {
                                $rec = $format->{fix}->fix($rec);
                            }
                            $exporter->add($rec);
                            $exporter->commit;
                            $rec_vars->{metadata} = $metadata;
                        }
                        $rec_vars;
                    } @{$search->hits}
                ];
                return $self->_render($self->_tt_process($self->_templ_list_records, $vars));
            }

        } elsif ($verb eq 'ListMetadataFormats') {
            if (my $id = $params->get('identifier')) {
                $id =~ s/^$ns//;
                unless ($self->_bag->get($id)) {
                    push @$errors,
                        [idDoesNotExist =>
                            "identifier $id is unknown or illegal"
                        ];
                    return $self->_render_error($vars);
                }
            }
            return $self->_render($self->_tt_process($self->_templ_list_metadata_formats, $vars));
        }
        elsif ($verb eq 'ListSets') {
            return $self->_render($self->_tt_process($self->_templ_list_sets, $vars));
        }

    };
}

sub not_found ($self) {
    [404, ['Content-Type' => 'text/plain'], ['not found']];
}

1;


=head1 NAME

Plack::App::Catmandu::OAI - drop in replacement for Dancer::Plugin::Catmandu::OAI

=head1 SYNOPSIS

    use Plack::Builder;
    Plack::App::Catmandu::OAI;

    builder {
        enable 'ReverseProxy';
        enable '+Dancer::Middleware::Rebase', base  => Catmandu->config->{uri_base}, strip => 1;
        mount "/oai" => Plack::App::Catmandu::OAI->new(
            repositoryName => 'my repo',
            store => 'search',
            bag   => 'publication',
            cql_filter => 'type = dataset',
            limit  => 100,
            datestamp_field => 'date_updated',
            deleted => sub { $_[0]->{deleted}; },
            set_specs_for => sub {
                $_[0]->{specs};
            }
        )->to_app;
    };

=head1 CONSTRUCTOR ARGUMENTS

=over

=item store

Type: string

Description: Name of Catmandu store in your catmandu store configuration

Default: C<default>

=item bag

Type: string

Description: Name of Catmandu bag in your catmandu store configuration

Default: C<data>

This must be a bag that implements L<Catmandu::CQLSearchable>, and that configures a C<cql_mapping>

=item fix

Either name of fix, path to fix file or instance of L<Catmandu::Fix>

This fix will be applied to every record found, either via GetRecord or ListRecords

=item deleted

Type: code reference

Description: code reference that is supplied a record, and must return 0 or 1 determing if that record is deleted or not.

Required: false

=item set_specs_for

Type: code reference

Description: code reference that is supplied a record, and must return an array reference of strings, showing to which sets that record belongs

Required: false

=item datestamp_field

Type: string

Description: name of the field in the record that contains the oai record datestamp ('datestamp' in our example above)

Required: true

=item datestamp_index

Type: string

Description: Which CQL index should be used to find records within a specified date range. If not specified, the value from the 'datestamp_field' setting is used

Required: false

=item repositoryName

Type: string

Description: name of the repository

Required: true

=item adminEmail

Type: array reference of non empty strings

Description: array reference of administrative emails. These will be included in the Identify response.

Required: false

=item compression

Type: array reference of non empty strings

Description: a list compression encodings supported by the repository. These will be included in the Identify response.

Required: false

=item description

Type: array reference of non empty strings

Description: a list of XML containers that describe your repository. These will be included in the Identify response. Note that this module will try to validate the XML data.

Required: false

=item earliestDatestamp

Type: string

Description: The earliest datestamp available in the dataset formatted as YYYY-MM-DDTHH:MM:SSZ. This will be determined dynamically if no static value is given.

Required: false

=item deletedRecord

Type: enumeration, having possible values C<no> (default), C<persistent> or C<transient>

Description: The policy for deleted records. See also: L<https://www.openarchives.org/OAI/openarchivesprotocol.html#DeletedRecords>

Required: 1

=item repositoryIdentifier

Type: string

Description: A prefix to use in OAI-PMH identifiers

Required: true

=item cql_filter

A global CQL query that is applied to all search requests (GetRecord, ListRecords and ListIdentifiers).
Use this to determine what records from your underlying catmandu search store should be available to
to the OAI.

=item default_search_params

Extra search parameters added during search in your catmandu bag:

    $bag->search(
        %{$self->default_search_params},
        cql_query    => $cql,
        sru_sortkeys => $request->sortKeys,
        limit        => $limit,
        start        => $first - 1,
    );

Must be a hash reference

Note that search parameter C<cql_query>, C<sru_sortkeys>, C<limit> and C<start> are overwritten

=item search_strategy

Type: enumeration having possible value C<paginate> (default), C<es.scroll> or C<filter>

Description: strategy to implement paging of oai record results (in ListRecords or ListIdentifiers).
The default search strategy C<paginate> uses C<start> and C<limit> in the underlying search request,
but that may lead to deep paging problems. ElasticSearch for example will refuse to return results after
hit 10.000.

* C<paginate>: use catmandu store search parameters C<start> and C<limit> in order to advance to the next page.
  May result into a deep paging problem, but serves as a convenient default for small repositories.

* C<es.scroll>: use ElasticSearch scroll api (https://www.elastic.co/guide/en/elasticsearch/reference/current/scroll-api.html#scroll-api-request) to split into pages.
  As expected only useful for elasticsearch. Elasticsearch stores a snapshot of the resultset
  for a certain amount of time, returns the identifier (scroll_id) for that snapshot, and we use that
  scroll_id as the cursor to the next page. Requesting the first page however several times may cause a server downtime
  when the resources are exhausted to store an additional snapshot. This option is ONLY included as a deprecated option,
  never to be used anymore.

* C<filter>: use prefix filtering to split into pages. Works by sorting by on the primary identifier,
  and using a prefix query like C<"_id > this_page.last_id"> to fetch the next page.
  This is the RECOMMENDED approach
  cf. https://solr.apache.org/guide/6_6/pagination-of-results.html#using-cursors

Required: 1

=item limit

The number of records to be returned in each OAI list record page

When not provided in the constructor, it is derived from the default limit of your catmandu bag (see L<Catmandu::Searchable#default_limit>)

=item delimiter

Type: string

Description: delimiter used in prefixing a record identifier with a repositoryIdentifier.

Default: C<:>

Required: false

=item sampleIdentifier

Type: non empty string

Description: sample identifier.

Required: true

=item xsl_stylesheet

Type: non empty string

Description: url to XSLT stylesheet. When given a link to this stylesheet in every request of type ListRecords or ListIdentifiers. 
             Only useful in browser context where the browser use the stylesheet for dynamic conversion.

Required: false

=item metadata_formats

Type: array reference of hash reference

Description: An array of metadataFormats that are supported. Every object needs the following attributes:

* metadataPrefix: a short string for the name of the format
* schema: an URL to the XSD schema of this format
* metadataNamespace: an XML namespace for this format
* template: path to a Template Toolkit file to transform your records into this format
* fix: optionally an array of one or more L<Catmandu::Fix>-es or Fix files

Required: true

=item sets

Type: array reference of hash references

Description: an array of OAI-PMH sets and the CQL query to retrieve records in this set from the Catmandu::Store. Each object must have the following attributes:

* setSpec: a short string for the same of the set
* setName: a longer description of the set
* setDescription: an optional and repeatable container that may hold community-specific XML-encoded data about the set. Should be string or array of strings.
* cql: the CQL command to find records in this set in the L<Catmandu::Store>

Required: false

=item granularity

Type: non empty string

Description: datestamp granularity. Default: YYYY-MM-DDThh:mm:ssZ. This is validated against the returned record timestamps

Required: false

=item collectionIcon

Type: hash reference

Description: object containing attributes for collectionIcon as used in the Identify response:

* url (required)
* link
* title
* width
* height

Required: false

=item get_record_cql_pattern

Type: non empty string

Description: CQL query template to use when fetching a single record. Defaults to C<_id exact "%s">.
Note that the record identifier key as defined by the catmandu bag is taken into account (which is _id by default)

Required: true

=item datestamp_pattern

Type: non empty string

Description: datestamp pattern for OAI parameters C<from> and C<until>. Example: C<%Y-%m-%dT%H:%M:%SZ>

Required: true

=item template_options

An optional hash of configuration options that will be passed to L<Catmandu::Exporter::Template> or L<Template>

=back

As this is meant as a drop in replacement for L<Dancer::Plugin::Catmandu::OAI> all arguments should be the same.

So all arguments can be taken from your previous dancer plugin configuration, if necessary:

    use Dancer;
    use Catmandu;
    use Plack::Builder;
    use Plack::App::Catmandu::OAI;

    my $dancer_app = sub {
        Dancer->dance(Dancer::Request->new(env => $_[0]));
    };

    builder {
        enable 'ReverseProxy';
        enable '+Dancer::Middleware::Rebase', base  => Catmandu->config->{uri_base}, strip => 1;
    
        mount "/oai" => Plack::App::Catmandu::OAI->new(
            %{config->{plugins}->{'Catmandu::OAI'}}
        )->to_app;

        mount "/" => builder {
            # only create session cookies for dancer application
            enable "Session";
            mount '/' => $dancer_app;
        };
    };

=head1 METHODS

=over 4

=item to_app

returns Plack application that can be mounted. Path rebasements are taken into account

=back

=head1 AUTHOR

=over 4
    
=item Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=back
    
=head1 IMPORTANT

This module is still a work in progress, and needs further testing before using it in a production system

=head1 LICENSE AND COPYRIGHT
    
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

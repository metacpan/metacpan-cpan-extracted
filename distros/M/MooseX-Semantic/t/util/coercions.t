use Test::More tests => 12;
use Test::Moose;
use RDF::Trine;
use Data::Dumper;
use MooseX::Semantic::Test::Person;

sub round_trip {
my $tbl_uri = 'http://www.w3.org/People/Berners-Lee/card#i';
my $pers_cls = 'MooseX::Semantic::Test::Person';
my $some_data = "SOME_DATA";
my %tbl = (
    from_default => $pers_cls->new,
    from_string => $pers_cls->new( rdf_about => $tbl_uri ),
    from_uri => $pers_cls->new( rdf_about => URI->new($tbl_uri) ),
    from_node => $pers_cls->new( rdf_about => RDF::Trine::Node::Resource->new($tbl_uri)),
    from_scalarref => $pers_cls->new( rdf_about => \$some_data ),
    from_hash => $pers_cls->new( rdf_about => {
            path => '/People/Berners-Lee/card',
            host => 'www.w3.org',
            scheme => 'http',
            fragment => 'i',
    }),
);
for (qw(from_string from_uri from_node from_hash)) {
    isa_ok($tbl{$_}->rdf_about, RDF::Trine::Node::Resource);
    is($tbl{$_}->rdf_about->uri, $tbl_uri, "URI $_ can be round-tripped");
}
for (qw(from_scalarref)) {
    isa_ok($tbl{$_}->rdf_about, RDF::Trine::Node::Resource);
    is($tbl{$_}->rdf_about->uri, "data:,SOME_DATA", "URI $_ can be round-tripped");
}
for (qw(from_default)) {
    isa_ok($tbl{$_}->rdf_about, RDF::Trine::Node::Resource);
    like($tbl{$_}->rdf_about->uri, qr/^urn:uuid:/, "URN::UUID is URL ");
}
}

sub dynamic_has {
    {
        package Foaf;
        use Moose;
        my $foaf = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
        has $_ => (
            traits => ['Semantic'],
            is => 'rw',
            uri => $foaf->$_
        ) foreach (qw/name homepage mbox phone/);
    }
    my $f = Foaf->new(
        name => 'Foo Bar',
        homepage => 'http://foo.bar',
        mbox => 'foo@bar',
        phone => '555-FOOBAR'
    );
    my $foaf = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
    is($f->meta->get_attribute('name')->uri, $foaf->name->uri_value, 'Foaf->name has uri foaf:name');
    # warn Dumper 
}

# sub round_trip_blank_node {
#     my $tbl_uri = 'http://www.w3.org/People/Berners-Lee/card#i';
#     my $pers_cls = 'MooseX::Semantic::Test::Person';
#     my $some_data = "SOME_DATA";
#     my %tbl = (
#         from_default => $pers_cls->new,
#         from_string => $pers_cls->new( rdf_about => blank),
#     );
#     for (qw(from_string from_uri from_node from_hash)) {
#         ok($tbl{$_}->is_blank_node, "$_ is blank node");
#         isnt($tbl{$_}->rdf_about, $tbl_uri, "URI has been replaced with UUID since it's a blank node");
#         # is($tbl{$_}->rdf_about->as_string, $tbl_uri, "URI $_ can be round-tripped");
#     }
#     for (qw(from_scalarref)) {
#         # isa_ok($tbl{$_}->rdf_about, URI);
#         # is($tbl{$_}->rdf_about->as_string, "data:,SOME_DATA", "URI $_ can be round-tripped");
#     }
#     for (qw(from_default)) {
#         # isa_ok($tbl{$_}->rdf_about, URI);
#         # like($tbl{$_}->rdf_about->as_string, qr/^urn:uuid:/, "URN::UUID is URL ");
#     }
# }

&round_trip;
# &round_trip_blank_node;
# &dynamic_has;

# $tbl= 
# isa_ok($tbl->rdf_about, URI);
# $tbl= MooseX::Semantic::Test::Person->new( rdf_about => URI->new('http://www.w3.org/People/Berners-Lee/card#i') );
# isa_ok($tbl->rdf_about, URI);
# warn Dumper $tbl->rdf_about->isa('URI');
# &basic_export;
# done_testing;

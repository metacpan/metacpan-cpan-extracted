# Encapsulated "basic" tests for XML routines.

# Assumes Test::More and Test::Builder::Tester are already loaded, as well as
# utils.pl.

sub basic_tests
{
    my %args = @_;

    my $type          = $args{type};
    my $class         = $args{class};
    my $basecall      = $args{basecall};
    my $alias1        = $args{alias1};
    my $alias2        = $args{alias2};
    my $schemafile    = $args{schemafile};
    my $badschemafile = $args{badschemafile};

    my ($bad_xml, $good_xml, $good_xml_short, $good_xml_no_pi, $dom_obj);

    my $schema = read_file($schemafile);
    my $badschema = read_file($badschemafile);

    $bad_xml = <<'ENDXML';
<?xml version="1.0"?>
<container></container>
ENDXML
    $good_xml = <<'ENDXML';
<?xml version="1.0"?>
<container>
  <data>foo</data>
</container>
ENDXML
    $good_xml_short = <<'ENDXML';
<?xml version="1.0"?>
<data>foo</data>
ENDXML
    $good_xml_no_pi = <<'ENDXML';
<container>
  <data>foo</data>
</container>
ENDXML

    test_out('ok 1 - string+string');
    test_out('not ok 2 - string+string fail');
    test_out('ok 3 - string+string nested');
    $basecall->($schema, $good_xml_short, 'string+string');
    $basecall->($schema, $bad_xml, 'string+string fail');
    $basecall->($schema, $good_xml, 'string+string nested');
    test_test(title => 'basic string+string arguments', skip_err => 1);

    # Test the aliases with the same simple data
    test_out("ok 1 - $type alias 1");
    $alias1->($schema, $good_xml, "$type alias 1");
    test_test(
        name     => "string+string arguments, $type alias 1",
        skip_err => 1
    );

    test_out("ok 1 - $type alias 2");
    $alias2->($schema, $good_xml, "$type alias 2");
    test_test(
        title    => "string+string arguments, $type alias 2",
        skip_err => 1
    );

    # Test the other types of data we can pass for the schema

    # Scalar-ref data for the schema
    test_out('ok 1 - scalarref schema arg');
    $basecall->(\$schema, $good_xml, 'scalarref schema arg');
    test_test(title => 'scalarref schema arg', skip_err => 1);

    # File name for the schema
    test_out('ok 1 - filename schema arg');
    $basecall->($schemafile, $good_xml, 'filename schema arg');
    test_test(title => 'filename schema arg', skip_err => 1);

    # File handle for the schema
  SKIP: {
        open my $fh, '<', $schemafile;
        skip "Unable to open $schemafile for reading: $!", 1 if (! $fh);

        test_out('ok 1 - filehandle schema arg');
        $basecall->($fh, $good_xml, 'filehandle schema arg');
        test_test(title => 'filehandle schema arg', skip_err => 1);
        close $fh;
    }

    # XML::LibXML::* object for the schema
    if ($class eq 'XML::LibXML::Dtd')
    {
        $dom_obj = $class->parse_string($schema);
    }
    else
    {
        $dom_obj = $class->new(string => $schema);
    }
    test_out('ok 1 - object schema arg');
    $basecall->($dom_obj, $good_xml, 'object schema arg');
    test_test(title => 'object schema arg', skip_err => 1);

    # Negative tests

    # Handle on a file that has bad data
  SKIP: {
        open my $fh, '<', $badschemafile;
        skip "Unable to open $schemafile for reading: $!", 1 if (! $fh);

        test_out('not ok 1 - filehandle bad schema arg');
        $basecall->($fh, $good_xml, 'filehandle bad schema arg');
        test_test(title => 'filehandle bad schema arg', skip_err => 1);
        close $fh;
    }

    # Bad string data
    test_out('not ok 1 - bad schema string');
    $basecall->($badschema, $good_xml, 'bad schema string');
    test_test(title => 'bad schema string',  skip_err => 1);

    # Bad scalarref data
    test_out('not ok 1 - bad schema scalarref');
    $basecall->(\$badschema, $good_xml, 'bad schema scalarref');
    test_test(title => 'bad schema scalarref',  skip_err => 1);

    # Bad file content
    test_out('not ok 1 - bad schema file');
    $basecall->($badschemafile, $good_xml, 'bad schema file');
    test_test(title => 'bad schema file',  skip_err => 1);

    # Bad argument for the schema
    test_out('not ok 1 - bad schema arg');
    $basecall->([], $good_xml, 'bad schema arg');
    test_test(title => 'bad schema arg', skip_err => 1);

    return;
}

1;

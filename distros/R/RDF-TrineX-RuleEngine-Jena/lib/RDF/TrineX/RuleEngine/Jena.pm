package RDF::TrineX::RuleEngine::Jena;
use Moose;
use English;
use Path::Class;
use File::Find;
use Archive::Zip qw(:CONSTANTS :ERROR_CODES);
use Try::Tiny;
use File::Copy;
use File::Share ':all';
use File::Slurp;
use IO::CaptureOutput qw(capture);
use RDF::Trine;
use RDF::Trine::Namespace qw(rdf rdfs owl xsd);
use RDF::Trine::Model::StatementFilter;
use Carp qw(cluck);

use File::Temp qw(tempfile);
use Data::Dumper;

BEGIN {
    $RDF::TrineX::RuleEngine::Jena::VERSION = '0.001';
}

has JENAROOT => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
);

has JENA_VERSION => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has JENA_SOURCES_JAR => (
    is       => 'ro',
    isa      => 'Archive::Zip',
    required => 1,
);
has JENA_CLASSPATH => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has ruleset_map => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Str]',
    handles => {
        'available_rulesets'   => 'keys',
        'get_ruleset_filename' => 'get',
    },
);

sub stringify_classpath {
    my $self = shift;
    return join ":", @{ $self->JENA_CLASSPATH };
}

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_;

    # detect JENAROOT
    # first as an argument passed to the constructor
    unless ( $args{JENAROOT} ) {

        # second as an environment variable
        $args{JENAROOT} = $ENV{JENAROOT};
        unless ( $args{JENAROOT} ) {

            # third as a build option stored in share/JENAROOT
            my $JENAROOT_sharefile = dist_file( 'RDF-TrineX-RuleEngine-Jena', 'JENAROOT' );
            try {
                $args{JENAROOT} = read_file $JENAROOT_sharefile;
                chomp $args{JENAROOT} if $args{JENAROOT};
            }
            catch {
                confess "Couldn't open shared file $JENAROOT_sharefile. Broken build, reinstall";
            };
        }
    }
    confess
        "Must pass JENAROOT via constructor, set environment variable JENAROOT or configure path at runtime"
        unless $args{JENAROOT};

    $args{JENAROOT} = Path::Class::Dir->new( $args{JENAROOT} );
    confess "JENAROOT '$args{JENAROOT}' does not exist."
        unless ( -e $args{JENAROOT} );
    confess "JENAROOT '$args{JENAROOT}' is not a directory."
        unless ( -d $args{JENAROOT} );
    for (qw(lib lib-src)) {
        confess "JENAROOT doesn't contain '$_'. Probably the wrong directory."
            unless ( -e $args{JENAROOT}->subdir($_) );
    }

    # collect jars for classpath
    $args{JENA_CLASSPATH} = [];
    find(
        sub {
            m/jar$/
                && ( push @{ $args{JENA_CLASSPATH} }, $File::Find::name );
        },
        $args{JENAROOT}->subdir('lib')
    );

    # find sources jar and set JENA_VERSION
    find(
        sub {
            m/jena-([\d\.]+)-sources\.jar/
                && -e $_
                && $1
                && ( $args{JENA_VERSION}     = $1 )
                && ( $args{JENA_SOURCES_JAR} = Archive::Zip->new($File::Find::name) );
        },
        $args{JENAROOT}->subdir("lib-src")
    );
    confess "Couldn't determine Jena version."
        unless ( $args{JENA_VERSION} );
    confess
        "Couldn't find jena-$args{JENA_VERSION}-sources.jar (should be in \$JENAROOT/lib-src but isn't."
            unless ( $args{JENA_SOURCES_JAR} );

    # detect available_rulesets
    $args{ruleset_map} = { map { $_->fileName =~ m|etc/(.+).rules$|; $1 => $_->fileName }
            $args{JENA_SOURCES_JAR}->membersMatching('etc/.+rules$') };

    # COMPATIBILITY
    # 'owl.rules' and 'owl-b.rules' are broken
    delete $args{ruleset_map}->{'owl-b'};
    delete $args{ruleset_map}->{'owl'};
    delete $args{ruleset_map}->{'owl-fb-old'};
    delete $args{ruleset_map}->{'rdfs-fb-tgc-simple'};

    return $class->$orig(%args);
};
sub apply_rules {
    my $self      = shift;
    my %opts      = @_;
    my %tempfiles = (
        input => File::Temp->new(
            TMPDIR   => 1,
            TEMPLATE => 'jena_in_XXXXX',
            SUFFIX   => '.nt',
            UNLINK   => 0
        ),
        output => File::Temp->new(
            TMPDIR   => 1,
            TEMPLATE => 'jena_out_XXXXX',
            SUFFIX   => '.nt',
            UNLINK   => 0
        ),
        rules => File::Temp->new(
            TMPDIR   => 1,
            TEMPLATE => 'jena_XXXXX',
            SUFFIX   => '.rules',
            UNLINK   => 0
        ),
    );

    # determine input
    confess "Must specify 'input' to apply_rules."
        unless $opts{input};
    $self->_coerce_input( $opts{input}, %tempfiles );

    # determine input format
    my $input_format = $opts{input_format} || 'N-TRIPLE';

    # determine rules
    confess "Must specify 'rules' to apply_rules."
        unless $opts{rules};
    $self->_coerce_rules( $opts{rules}, %tempfiles );

    # close (and write out) all tempfiles
    map { $_->close } values %tempfiles;

    # actually execute jena.RuleMap
    # my $jena_rulemap_sub = sub {
    my $stderr;
    capture(
        sub {
            $self->exec_jena_rulemap(
                filename_rules => $tempfiles{rules}->filename,
                filename_input => $tempfiles{input}->filename,
                input_format   => $input_format,
                output_format  => 'N-TRIPLE',
                additions_only => $opts{additions_only},
            )
        },
        undef, # don't capture output
        \$stderr, #capture stderr
        $tempfiles{output}, #write stdout to this tempfile
        undef, #don't write stderr to file
    );
    $tempfiles{output}->close;

    if ($opts{output} && ! blessed $opts{output}) {
        if ($opts{output} =~ m/^:filename$/i) {
            return $tempfiles{output}->filename;
        } elsif ($opts{output} =~ m/^:(?:FH|string)$/i ) {
            open my $fh, "<:utf8", $tempfiles{output}->filename;
            return $fh if $opts{output} =~ m/^:FH/i;
            return do { local $/; <$fh>; };
        }
    }

    # make sure we have an output model
    my $out_model = $self->_coerce_output( $opts{output} );
    my $parser = RDF::Trine::Parser->new('ntriples');
    $parser->parse_file_into_model( '/', $tempfiles{output}->filename, $out_model );

    # purge stuff
    if ( my $schemas_to_purge = $opts{purge_schemas} ) {

        # "cast" model to statementfiltermodel
        unless ( $out_model->isa('RDF::Trine::Model::StatementFilter') ) {
            $out_model = RDF::Trine::Model::StatementFilter->new( $out_model->_store );
        }

        # warn "Adding rules to Model::StatementFilter";
        unless ( ref $schemas_to_purge ) {
            $schemas_to_purge = [$schemas_to_purge];
        }
        $self->_remove_schema( $out_model, $schemas_to_purge );
    }

    # remove all tempfiles
    map { unlink $_ } values %tempfiles;

    # return the output as a model
    return $out_model;
}

sub _coerce_output {
    my $self = shift;
    my $data = shift;
    unless ($data) {
        return RDF::Trine::Model::StatementFilter->temporary_model;
    }
    if ( blessed $data) {
        if ( $data->isa('RDF::Trine::Model') ) {
            return $data;
        }
        else {
            confess "Can't handle output of type " . ref $data;
        }
    }
    else {
        confess "Output must be a model.";
    }
}

sub _coerce_input {
    my $self      = shift;
    my $data      = shift;
    my %tempfiles = @_;
    if ( ref $data ) {
        if ( ref $data eq 'SCALAR' ) {
            print { $tempfiles{input} } $$data;
        }

        # TODO cleaner class check
        elsif ( blessed $data ) {
            if ( $data->isa('RDF::Trine::Model') ) {
                my $serializer = RDF::Trine::Serializer->new('ntriples');
                my $data_ser   = $serializer->serialize_model_to_string($data);
                print { $tempfiles{input} } $data_ser;
            }
            else {
                confess "Can't handle objects of type " . ref $data;
            }
        }
    }
    else {
        confess "Couldn't open input file $data"
            unless ( -e $data && -r $data );
        copy( $data, $tempfiles{input}->tempfile );
    }
}

sub _coerce_rules {
    my $self      = shift;
    my $data      = shift;
    my %tempfiles = @_;
    if ( ref $data ) {

        # if it's SCALAR ref, use those rules directly
        if ( ref $data eq 'SCALAR' ) {
            print { $tempfiles{rules} } $$data;
        }

        # if it's a GLOB reference, write it to tempfile
        elsif ( ref $data eq 'GLOB' ) {
            while (<$data>) {
                print { $tempfiles{rules} } $_;
            }
        }
    }
    else {

        # might be a predefined ruleset
        my $predefined_ruleset = $self->get_ruleset_filename($data);
        if ($predefined_ruleset) {

            # confess "No such ruleset $opts{ruleset}." unless $dataet_filename;
            my $extract_ok
                = $self->JENA_SOURCES_JAR->extractMemberWithoutPaths( $predefined_ruleset,
                $tempfiles{rules}->filename );
            unless ( AZ_OK == $extract_ok ) {
                confess "Couldn't extract $predefined_ruleset to " . $tempfiles{rules}->filename;
            }
        }

        # it's a filename
        else {
            confess "Rule file '$data' does't exist or isn't readable."
                unless ( -e $data && -r $data );
            copy( $data, $tempfiles{rules}->filename );
        }
    }
}

sub exec_jena_rulemap {
    my $self           = shift;
    my %opts           = @_;
    my $filename_rules = $opts{filename_rules};
    my $filename_input = $opts{filename_input};
    my $input_format   = $opts{input_format} || "N-TRIPLE";
    my $output_format   = $opts{output_format} || "N-TRIPLE";
    my $additions_only = $opts{additions_only};
    # my %tempfiles = ${

    my $OLD_CLASSPATH = $ENV{CLASSPATH};
    $ENV{CLASSPATH} = $self->stringify_classpath;
    my @jena_rulemap_cmd = (
        "java" => "jena.RuleMap",
        "-il"  => $input_format,
        "-ol"  => $output_format,
        $opts{filename_rules},
        $opts{filename_input},
    );

    if ($additions_only) {
        splice @jena_rulemap_cmd, 6, 0, "-d";
    }
    # my ( $stdout, $stderr, $success, $exit_code ) = capture_exec(@jena_rulemap_cmd);
    system( @jena_rulemap_cmd );
    $ENV{CLASSPATH} = $OLD_CLASSPATH;

    return 1;
}

sub _model_difference {
    my $self = shift;
    my ( $model, $model_diff ) = @_;
    my $iter = $model_diff->as_stream;
    while ( my $stmt = $iter->next ) {
        $model->remove_statement($stmt);
    }
    return $model;
}

sub _remove_tautologies {
    my $self = shift;
    my ($model) = @_;

    # ?a owl:equivalentProperty ?a -> []
    $model->add_rule(
        sub {
            my $stmt = shift;
            if (
                $stmt->subject->equal( $stmt->object )
                && $stmt->predicate->equal(
                    RDF::Trine::iri('http://www.w3.org/2002/07/owl#equivalentProperty')
                )
                )
            {
                return 0;
            }
            return 1;
        }
    );
}

sub _remove_schema {
    my $self          = shift;
    my ($model)       = shift;
    my (@namespaces)  = @{ shift() };
    my %namespaces_re = (
        rdf  => qr/^$rdf/,
        rdfs => qr/^$rdfs/,
        owl  => qr/^$owl/,
        xsd  => qr/^$xsd/,
        jena => qr|^\Qurn:x-hp-jena:rubrik/\E|,
        daml => qr|^\Qhttp://www.daml.org/2001/03/daml+oil#\E|,
    );
    if ( $namespaces[0] eq ':all' ) {
        @namespaces = keys %namespaces_re;
    }
    $model->add_rule(
        sub {
            my $stmt = shift;

            # remove all statements about RDF, RDFS, OWL, jena:rubrik, DAML and XSD resources
            for my $ns (@namespaces) {
                if ( $stmt->subject->is_blank ) {
                    if ( $stmt->object->equal( $owl->Thing ) ) {
                        return 0;
                    }
                    return 1;
                }
                return 0 if $stmt->subject->uri_value =~ $namespaces_re{$ns};

                # additionally  purge everything with jena's FB namespace in i
                if ( $ns eq 'jena' ) {
                    for ( 0 .. 2 ) {
                        next unless [ $stmt->nodes ]->[$_]->is_resource;
                        return 0 if [ $stmt->nodes ]->[$_]->uri_value =~ $namespaces_re{$ns};
                    }
                }
            }
            return 1;
        }
    );

    # warn Dumper $model->count_statements;
}

1;
=head1 NAME

RDF::TrineX::RuleEngine::Jena - Wrapper around Jena's rule engine for reasoning over RDF

=head1 SYNOPSIS

    use RDF::Trine::Namespace qw(rdf rdfs);

    my $one_triple = "<test/classA> <${rdfs}domain> <test/ClassB> .";

    my $reasoner = RDF::TrineX::RuleEngine::Jena->new;
    my $model_inferred = $reasoner->apply_rules(
        input => \ $one_triple,
        rules => 'rdfs-fb',
        purge_schemas => ':all',
    );

    print $model_inferred->size;    
    # 7

    my $serializer = RDF::Trine::Serializer->new('turtle' , namespaces => { rdf => $rdf, rdfs => $rdfs });
    print $serializer->serialize_model_to_string( $model_inferred );

    # <test/ClassB> rdfs:subClassOf rdfs:Resource, <test/ClassB> ;
    #     a rdfs:Class .
    # <test/classA> rdfs:domain <test/ClassB> ;
    #     a rdf:Property, rdfs:Resource .

=head1 DESCRIPTION

This module is a convenience wrapper around a call to Jena's C< jena.RuleMap >
command line rule-engine interface. It transparently handles serialization and
creation of temporary files, but it relies on a working Java installation and knowledge
of the location of the Jena framework.

=head2 Finding Jena

When building this module, the Jena framework can be downloaded or a path to an
existing Jena installation can be specified. This path is stored in a shared
file. If you can't or don't want to specify it at build time, you can set the
JENAROOT environment variable to the location of the extracted Jena download.
Finally you can pass the path to it at runtime to the constructor.

=head2 RDF::Trine vs. Jena Format names

    Trine    | Jena
    ---------+----------------------------
    ntriples | N-TRIPLE
    turtle   | TURTLE
    rdxml    | RDF/XML, RDF/XML-ABBREV
    n3       | N3-PP, N3-PLAIN, N3-TRIPLE


=head1 ATTRIBUTES

=over 4

=item JENAROOT

A L<Path::Class::Dir|Path::Class::Dir> object of the Jena directory.

=item JENA_VERSION

The Version of Jena used, determined from the C<< jena-X.X.X-sources.jar >>
file.

=item JENA_SOURCES_JAR

L<Archive::Zip|Archive::Zip> object for the C<< jena-X.X.X-sources.jar >> file.
Contains the predefined rulesets.

=item JENA_CLASSPATH

Array reference holding the paths to all the C<<jar>> files required for Jena
to run.

=back

=head1 METHODS

=head2 new

Returns a new L<RDF::TrineX::RuleEngine::Jena|RDF::TrineX::RuleEngine::Jena>
object. Before 

The optional C<JENAROOT> argument holds the path to the extracted Jena source.
If not set, C<JENAROOT> is determined as described in L</JENAROOT>.


=head2 apply_rules

Applies a set of Jena rules to RDF input and adds the inferred statements to
the output model.

=over 4

=item C<< input => $input_data >> 

B<required>

C<$input_data> is serialized, written to a temporary file and fed to
L</exec_jena_rulemap> as the C<filename_input> argument. Currently, the
following data types are handled:

=over 4

=item * L<RDF::Trine::Model|RDF::Trine::Model>.

    my $model = RDF::Trine::Model->temporary_model;
    RDF::Trine::Parser->new('turtle')->parse_file_into_model('my_file.ttl');
    $reasoner->apply_rules(
        input => $model,
        rules => ...,
    );

=item * String: Treated as the path to a file containing a serialized RDF graph.
    
    $reasoner->apply_rules(
        input => 'my_file.nt',
        rules => ...,
    );

=item * Scalar reference: Treated as a reference to a serialized RDF graph.

    my $input_ttl = <'EOF';
    @prefix rdfs:http://www.w3.org/2000/01/rdf-schema# .
    <Tiny> rdfs:subClassOf <Small> .
    EOF
    $reasoner-apply_rules(
        input => \ $input_ttl,
        input_format => 'TURTLE',
        rules => ...,
    );

=back

=item C<< rules => $rules_data >> 

B<required>

C<< $rules_data >> can be any of the following:

=over 4

=item * String matching one of the L</available_rulesets>: The appropriate rules file is
loaded from L</JENA_SOURCES_JAR>.

    $reasoner->apply_rules(
        input => ...,
        rules => 'rdfs',
    );

=item * Scalar reference: The dereferenced value is treated as a string of rules.

    my $rules = "[dummy: (?a ?b ?c) -> (?a rdfs:label "This is stupid") ]";
    $reasoner->apply_rules(
        input => ...,
        rules => \ $rules,
    );

=item * Any other string: Treat C<$rules_data> as a filename and load rules from there.

    $reasoner->apply_rules(
        input => ...,
        rules => '/path/to/my/ruleset.rules',
    );

=back

=item C<< output => ($model|":fh"|":filename"|":string"|$string) >>

If specified, inferred statements are written to this model, otherwise a
temporary model is created. If you set output to the same value as input,
inferred statements are added to the original model.

=over 4

=item * C<< $model >>: The statements are added to this L<RDF::Trine::Model>.
Setting this to the same model as in C<< input >> will cause all rule-based
statement removals to be ignored since there currently is no way of tracking
which statements I<were> by applying the rules.

=item * C<":fh">: If this special string (case-insensitive) is supplied, a readable filehandle
to the raw output of jena.RuleMap is returned. C<< purge_schemas >> is ignored.

    my $fh = $reasoner->apply_rules(
        input => ...,
        rules => ...,
        output => ':FH',
    );
    while (<$fh>) {
        my ($s, $p, $o ) = $_ =~ m/^\s*<([^>]+>\s+<([^>]+>\s+<([^>]+>\s*.$/;
    }

=item * C<":filename">: If this special string (case-insensitive) is supplied, the filename of the
temporary file containing the raw output of jena.rulemap is returned .
C<purge_schemas> is ignored.

    use File::Slurp;
    my $fname = $reasoner->apply_rules(
        input => ...,
        rules => ...,
        output => ':filename',
    );
    my $contents = read_file $fname;

=item * C<":string">: If this special string (case-insensitive) is supplied,
the complete raw output of jena.RuleMap is returned. C<< purge_schemas >> is
ignored.

    my $serialized = $reasoner->apply_rules(
        input => ...,
        rules => ...,
        output => ':sTRing',
    );

=item * C<$string>: Any other string is treated as a filename to write the raw
output of jena.RuleMap to. C<< purge_schemas >> is ignored.

    my $serialized = $reasoner->apply_rules(
        input => 'data.nt',
        rules => ...,
        output => 'data_inferred.nt',
    );

=back

=item C<< purge_schemas => (\@list_of_schemanames|":all") >>

Jena's rule engine adds lots and lots of schema statements about rdf, rdfs, owl,
xsd plus some internals. You can tell RDF::TrineX::RuleEngine::Jena to purge those
statements by supplying an array ref of schema names to purge_schemas.

Specifying C<:all> removes all schema statements, RDF::TrineX::RuleEngine::Jena knows
about.

    $reasoner->apply_rules(
        input => ...,
        rules => ...,
        purge_schemas => ':all',
    );

is equivalent to

    $reasoner->apply_rules(
        input => ...,
        rules => ...,
        purge_schemas => [qw( rdf rdfs daml xsd owl jena )],
    );

=back

=head2 exec_jena_rulemap

Sets and resets CLASSPATH and runs C<< java jena.RuleMap ... >> using a
L<system|perlfunc/system> call.  This is all this function does, capturing STDIN and
STDERR and parsing/serializing happens in L<< apply_rules >>.

Arguments:

=over 4

=item filename_rules

Filename of the C<< .rules >> file

=item filename_input

File name of the file containing the assertions.

=item input format

The format of the input file, in Jena notation (i.e. 'N-TRIPLE', 'TURTLE', 'RDF/XML'...)

=item output_format

Format of the result printed to STDOUT, again in Jena notation.

=item additions_only

When this flag is set, Jena will only return deduced and schema statements, as
opposed to the original model with added and removed statements when the flag
is not set.

=back

=cut

=head2 _model_difference

Given two models A and B, remove all statements from A that are also in B.

=cut


=head2 _remove_tautologies

Remove all statements of the form C<X owl:equivalentProperty X>.

=cut 

=head2 available_rulesets

Lists the available predefined rulesets shipped with Jena that aren't broken. Currently, these are:

=over 4

=item * B<daml-micro>

=item * B<owl-fb>

=item * B<owl-fb-micro>

=item * B<owl-fb-mini>

=item * B<rdfs>

=item * B<rdfs-b>

=item * B<rdfs-b-tuned>

=item * B<rdfs-fb>

=item * B<rdfs-fb-lp-expt>

=item * B<rdfs-fb-tgc>

=item * B<rdfs-fb-tgc-noresource>

=item * B<rdfs-noresource>

=back

=head2 get_ruleset_filename

Get the filename of a predefined ruleset within L</JENA_SOURCES_JAR>.

=cut



=head1 AUTHOR

Konstantin Baierer <kba@cpan.org>

=head1 SEE ALSO

=over 4

=item L< http://answers.semanticweb.com/questions/1453/reasoning-and-sparql-through-arq-command-line >

=back

use strict;
use Test::More;
use File::Find;

BEGIN {
    eval { 
        require RDF::Trine::Model; 
        require RDF::Trine::Serializer::NTriples::Canonical;
        require JSON;
        1; 
    } or do {
        plan skip_all => "RDF::Trine or JSON required";
    };
}

sub slurp { 
    local (@ARGV, $/) = @_; 
    my $data = -e $ARGV[0] ? <> : "";
    $data =~ s/\n$//;
    $data;
}

use RDF::aREF qw(decode_aref);
use RDF::aREF::Decoder;

sub trine_statement { # TODO: remove/modify this method
    RDF::aREF::Decoder::trine_statement(@_);
}

foreach my $file (sort <t/suite/*.json>) {
    $file =~ s/\.json$//;
    my $name = $file; $name =~ s{^t/suite/}{};
    my $aref = JSON::from_json(slurp("$file.json"));
    my $nt   = slurp("$file.nt");
    my $err  = slurp("$file.err");
    my @errors;

    my $model = RDF::Trine::Model->new;
    # TODO: use iterator instead
    # a (->next returns a trine-statement)
    $model->begin_bulk_ops;
    my $decoder = RDF::aREF::Decoder->new(
        callback => sub {
            $model->add_statement( trine_statement( @_ ) ) 
        }, 
        complain => 2,
        strict => ($file =~ /strict/ ? 1 : 0),
    );
    eval { $decoder->decode($aref) };
    if ($err) {
        my $got = $@;
        $got =~ s{ at t/suite\.t line \d+[.]?\n}{};
        is $got, $err, "$name.err";
    } else {
        $model->end_bulk_ops;
        my $got = RDF::Trine::Serializer::NTriples::Canonical->new(
            onfail => 'truncate',
        )->serialize_model_to_string($model);
        $got =~ s/\r|\n$//g;
        $file =~ s{.*/}{};
        is $got, $nt, $file;
    }
}

done_testing;

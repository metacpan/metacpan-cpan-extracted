#!/usr/bin/env perl
$|++;

use strict;

use RDF::LDF;
use RDF::Trine::Store::LDF;
use RDF::Trine::Store;
use RDF::Query;
use Getopt::Long;
use utf8;
use Encode;

use JSON ();
my $JSON = JSON->new->utf8->allow_nonref;
sub encode_json { $JSON->encode(@_) }

my ($subject,$predicate,$object);

@ARGV = map { Encode::decode('UTF-8', $_) } @ARGV;

GetOptions("subject=s" => \$subject , "predicate=s" => \$predicate , "object=s" => \$object);

my $url    = shift;
my $sparql = shift;

unless (defined $url) {
    print STDERR <<EOF;
usage: $0 url sparql

usage: $0 [options] url

where:
    url - an LDF endpoint or a space delimited list of multiple LDF endpoints
          (for an federated query)
    
options:

   --subject=<.>
   --predicate=<.>
   --object=<.>

EOF
    exit(1);
}

init_cache();

if (defined $sparql) {
    process_sparql($sparql);
}
else {
    process_fragments($subject,$predicate,$object);
}

sub init_cache {
    use LWP::UserAgent::CHICaching;
    my $cache = CHI->new( driver => 'Memory', global => 1 );
    my $ua = LWP::UserAgent::CHICaching->new(cache => $cache);
    RDF::Trine->default_useragent($ua);
}

sub process_fragments {
    my ($subject,$predicate,$object) = @_;

    my $client = RDF::LDF->new(url => [split(/\s+/,$url)]);
    my $it = $client->get_statements($subject,$predicate,$object);

    print "[\n";
    if ($it) {
        while (my $st = $it->()) {
            printf "{\"subject\":%s,\"predicate\":%s,\"object\":%s}\n",
                encode_json($st->subject->value),
                encode_json($st->predicate->value),
                encode_json($st->object->value);
        }
    }
    print "]\n";
}

sub process_sparql {
    my $sparql = shift;
    $sparql = do { local (@ARGV,$/) = $sparql; <> } if -r $sparql;

    my $store = RDF::Trine::Store->new_with_config({
            storetype => 'LDF',
            url => [split(/\s+/,$url)]
    });

    my $model =  RDF::Trine::Model->new($store);

    my $rdf_query = RDF::Query->new( $sparql );

    unless ($rdf_query) {
        print STDERR "failed to parse:\n$sparql";
        exit(2);
    }

    my $iter = $rdf_query->execute($model);

    print "[\n";
    if ($iter) {
        my $count = 0;
        while (my $s = $iter->next) {
            my $h = {};
            for my $v ($s->variables) {
                my $node = $s->{$v};
                my $val;
                if ($node->isa('RDF::Trine::Node::Variable')) {
                    $val = $node->as_string; # ?foo
                } elsif ($node->isa('RDF::Trine::Node::Literal')) {
                    $val = $node->as_string; # includes quotes and any language or datatype
                    $val =~ s{^"|"$}{}g;
                } else {
                    $val = $node->value; # the raw IRI or blank node identifier value, without other syntax
                }
                $h->{$v} = $val; 
            }
            print (",\n") if ($count++ > 0);
            print encode_json($h);
        }
        print "\n";
    }
    print "]\n";
}
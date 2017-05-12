package MooseX::Semantic::Test;
use RDF::Trine ();
use Term::ANSIColor;
use String::Diff;
use Data::Dumper;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(ser ser_dump diff_models Dumper);  # symbols to export on request
my ($red, $green, $reset) = map {color $_} qw(red green reset);
%String::Diff::DEFAULT_MARKS = (
        remove_open  => $red,
        remove_close => $reset,
        append_open  => $green,
        append_close => $reset,
        separator => '',
    # separator    => '&lt;-OLD|NEW-&gt;', # for diff_merge
);

sub ser {
    my $format = shift || 'ntriples';
    return RDF::Trine::Serializer->new($format);
}
sub ser_dump {
    my $model = shift;
    my $format = shift || 'ntriples';
    ser->serialize_model_to_string( $model );
}
# warn Dumper( color 'blue' );
sub diff_models {
    my ($m1, $m2) = sort {$a->size < $b->size} @_;
    my ($m1_str, $m2_str) = map{ser_dump($_)} $m1, $m2;
    # my ($m1_str_lines, $m2_str_lines) = map{[split "\n", $_]} $m1_str, $m2_str;
    # my ( $m1_lines, $m2_lines ) = map {
        # my $m = $_;
        # [ map { ser_dump($m) } split( '\n', $_ ) ]
    # } $m1_str, $m2_str;
    # warn Dumper $m2_str_lines;
    my $diff = String::Diff::diff_merge($m1_str, $m2_str);
    print $diff;
}

1;

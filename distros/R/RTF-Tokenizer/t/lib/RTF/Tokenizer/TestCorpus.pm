#!perl
package RTF::Tokenizer::TestCorpus;
use strict;
use warnings;
use RTF::Tokenizer;

my $group_separator  = "\x{1d}";
my $record_separator = "\x{1e}";
my $unit_separator   = "\x{1f}";

sub test_corpus {
    my $filename = shift;
    my ( $test_name, $rtf, $expected_tokens ) = load_from_corpus($filename);

    # Check the standard tokenizer works
    my @actual_tokens = RTF::Tokenizer->new( string => $rtf )->get_all_tokens;
    Test::More::is_deeply( \@actual_tokens, $expected_tokens, $test_name );

    # Check we can round-trip
    test_roundtrip( $test_name, $rtf );
}

sub test_roundtrip {
    my ( $test_name, $rtf_string ) = @_;
    my $result        = '';
    my @actual_tokens = RTF::Tokenizer->new(
        string              => $rtf_string,
        preserve_whitespace => 1,
    )->get_all_tokens;
    for (@actual_tokens) {
        my ( $type, $argument, $parameter, $whitespace ) = @$_;
        $result .= $argument if $type eq 'text';
        $result .= '{' if $type eq 'group' && $argument;
        $result .= '}' if $type eq 'group' && !$argument;
        if ( $type eq 'control' ) {
            $result .= "\\";
            $result .= $_
                for grep defined, ( $argument, $parameter, $whitespace );
        }
    }

    Test::More::is( $result, $rtf_string, "Round-trip works for: $test_name" );
}

sub load_from_corpus {
    my $filename = shift;
    my $data     = read_file($filename);

    my ( $test_name, $rtf, $token_string ) = split( $group_separator, $data );
    my @tokens_raw = split( $record_separator, $token_string );
    my @tokens = map {
        my @fields = split( $unit_separator, $_ );
        push( @fields, '' ) unless @fields > 2;
        \@fields;
    } @tokens_raw;

    return ( $test_name, $rtf, \@tokens );
}

sub write_corpus {
    my $filename = shift;
    my $data     = create_from_t($filename);
    my ($output) = $filename =~ m/9\d+(.+)\./;
    $output = 't/corpus/' . $output . '.corpus';
    open( FH, ">$output" ) || die $!;
    print FH $data;
    close FH;
    print $output . "\n";
}

sub create_from_t {
    my $filename = shift;
    my $data     = read_file($filename);

    my $test_name = $filename;
    $test_name =~ s/.+9\d*//;
    $test_name =~ s/\.t$//;
    $test_name =~ s/_/ /g;
    $test_name = ucfirst($test_name);

    my ( $perl, $rtf ) = split( /\n__DATA__\n/, $data );

    return create( $test_name, $rtf );
}

sub create {
    my ( $test_name, $rtf ) = @_;
    my @tokens = RTF::Tokenizer->new( string => $rtf )->get_all_tokens;

    my $token_string = join $record_separator,
        map { join( $unit_separator, @$_ ) } @tokens;

    return join $group_separator, $test_name, $rtf, $token_string;
}

sub read_file {
    my $filename = shift;
    open( FH, "< $filename" ) || die $!;
    my $data = join '', (<FH>);
    close FH;
    return $data;
}

package Helpers;
use 5.14.0;
use warnings;
use parent 'Exporter';
our @EXPORT_OK = ( qw|
    test_TAD_analyze_methods
| );
use Test::More ();
*ok     = \&Test::More::ok;
*like   = \&Test::More::like;

sub test_TAD_analyze_methods {
    my ($self) = @_;
    my $ranalysis_dir;
    {
        local $@;
        eval { $ranalysis_dir = $self->analyze_cpanm_build_logs( [ verbose => 1 ] ); };
        like($@, qr/analyze_cpanm_build_logs: Must supply hash ref as argument/,
            "analyze_cpanm_build_logs(): Got expected error message for lack of hash ref");
    }

    $ranalysis_dir = $self->analyze_cpanm_build_logs( { verbose => 1 } );
    ok(-d $ranalysis_dir,
        "analyze_cpanm_build_logs() returned path to version-specific analysis directory '$ranalysis_dir'");

    my $rv;
    {
        local $@;
        eval { $rv = $self->analyze_json_logs( verbose => 1 ); };
        like($@, qr/analyze_json_logs: Must supply hash ref as argument/,
            "analyze_json_logs(): Got expected error message: absence of hash ref");
    }

    {
        local $@;
        eval { $rv = $self->analyze_json_logs( { verbose => 1, sep_char => "\t" } ); };
        like($@, qr/analyze_json_logs: Currently only pipe \('\|'\) and comma \(','\) are supported as delimiter characters/,
            "analyze_json_logs(): Got expected error message: unsupported delimiter");
    }

    my $fpsvfile = $self->analyze_json_logs( { verbose => 1 } );
    ok($fpsvfile, "analyze_json_logs() returned true value");
    ok(-f $fpsvfile, "Located '$fpsvfile'");

    my $fcsvfile = $self->analyze_json_logs( { verbose => 1 , sep_char => ',' } );
    ok($fcsvfile, "analyze_json_logs() returned true value");
    ok(-f $fcsvfile, "Located '$fcsvfile'");
    return 1;
}

1;

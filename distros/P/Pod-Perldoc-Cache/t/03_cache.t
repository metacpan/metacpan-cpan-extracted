use strict;
use Test::More;
use Pod::Perldoc::Cache;
use t::Helper;

subtest 'cache exists after parsing' => sub {
    my ($podfile, $out_fh, $cachefile) = prepare_all('=head1 HELLO');
    my $p = Pod::Perldoc::Cache->new;
    $p->parse_from_file($podfile, $out_fh);

    ok -e $cachefile;
    is read_from_file($cachefile), "HELLO\n";
};

subtest 'reads from cache if cache exists' => sub {
    my ($podfile, $out_fh, $cachefile) = prepare_all('');

    # prepare cache
    open my $fh, '>', $cachefile;
    print $fh 'WORLD';
    close $fh;

    my $p = Pod::Perldoc::Cache->new;
    $p->parse_from_file($podfile, $out_fh);
    is read_from_fh($out_fh), 'WORLD';
};

subtest 'reads from pod itself if pod is updated' => sub {
    # 1st parse(create cache)
    my ($podfile, $out_fh, $cachefile) = prepare_all('=head1 HELLO');
    my $p = Pod::Perldoc::Cache->new;
    $p->parse_from_file($podfile, $out_fh);

    # modify pod
    open my $fh, '>', $podfile;
    print $fh '=head1 WORLD';
    close $fh;

    # 2nd parse
    my ($out_fh2) = mk_outfile();
    $p->parse_from_file($podfile, $out_fh2);
    is read_from_fh($out_fh2), "WORLD\n";
};

done_testing;

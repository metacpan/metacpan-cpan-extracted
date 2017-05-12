use Test::More qw(no_plan);
BEGIN { use_ok('TM::Ontology::KIF') };

{
    my $k = new TM::Ontology::KIF;
    is (ref($k->{sentence}), 'CODE', 'code default');
}

eval {
    my $k = new TM::Ontology::KIF (sentence => 'rumsti');
}; like ($@, qr/no subroutine reference/, 'raised exception');

{
    my $count = 0;
    my $k = new TM::Ontology::KIF (sentence => sub { $count++; });
    use IO::String;
    $k->parse (IO::String->new('(xxx yyy zzz) (xxx yyy zzz)'));
    is ($count, 2, 'found 2 sentences');
}


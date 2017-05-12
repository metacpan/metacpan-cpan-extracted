use Test::Spec;

use OTRS::SphinxSearch;

describe "OTRS::SphinxSearch" => sub {
    it "required valid Sphinx::Search version" => sub {
        use_ok('Sphinx::Search', 0.28);
    };
    it "required Time::Piece" => sub {
        use_ok('Time::Piece');
    };
    it "required Readonly" => sub {
        use_ok('Readonly');
    };
    it "should implement methods" => sub {
        can_ok('OTRS::SphinxSearch', qw(new search _get_time_slot _get_time_point));
    };
};

runtests unless caller;

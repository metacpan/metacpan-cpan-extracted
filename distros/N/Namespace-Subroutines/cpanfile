requires 'perl', 'v5.18';

on 'test' => sub {
    requires 'Test::More', '0.98';
	requires 'Test2::V0', '>= 0.000155';
	requires 'HTTP::Status', '>= 6.44';
};

on 'develop' => sub {
	requires 'App::perlimports', '>= 0.000051';
	requires 'Perl::Tidy', '>= 20230701';
	requires 'Perl::Critic', '>= 1.150';
	requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitAccessOfPrivateData';
	requires 'Perl::Critic::Policy::Freenode::WhileDiamondDefaultAssignment';
};

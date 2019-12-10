requires 'PDL'              => 0;
requires 'Variable::Magic'  => 0;
requires 'namespace::clean' => 0;

feature dpss => 'Support for DPSS windows' => sub {
    recommends 'PDL::LinearAlgebra::Special';
};

feature kaiser => 'Support for kaiser windows' => sub {
    recommends 'PDL::GSLSF::BESSEL';
};

feature plot => 'Plot windows' => sub {
    recommends 'PDL::Graphics::Gnuplot';
};

on test => sub {
    requires 'Try::Tiny'     => '0';
    requires 'Capture::Tiny' => '0';
    requires 'Test::More'    => '0.96';
};

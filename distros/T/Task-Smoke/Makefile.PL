use inc::Module::Install;

name         ('Task-Smoke');
all_from     ('lib/Task/Smoke.pm');

# All the things we need for testing Pugs
requires     ('URI'                    => 0);
requires     ('MKDoc::XML'             => 0);
requires     ('Petal'                  => 0);
requires     ('Test::TAP::Model'       => 0.08);
requires     ('Test::TAP::HTMLMatrix'  => 0);
requires     ('Best'                   => 0.06) ;
requires     ('Test::Harness::Results' => 0);
requires     ('Time::Out'              => 0);

# Choosing a YAML provider's a bit tricky. If we have YAML::Syck,
# demand the proper version so that various users don't have to worry
# about that themselves. If not, use can_cc heuristic.

if (can_use('YAML::Syck') && YAML::Syck->VERSION lt '0.85') { # FIXME: proper version comparison
    requires('YAML::Syck' => '0.85');
}
elsif (can_cc()) {
    if (can_use('YAML' => 0.35)) {
        recommends('YAML::Syck' => '0.85');
    }
    else {
        requires('YAML::Syck' => '0.85');
    }
}
else {
    requires('YAML' => '0.35');
}

sign();
auto_install();

&WriteAll;

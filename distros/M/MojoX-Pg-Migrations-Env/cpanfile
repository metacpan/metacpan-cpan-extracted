requires 'Mojolicious' => '7.51';
requires 'Mojo::Pg'    => '4.04';
on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile';
};
on test => sub {
    requires 'Test::Simple' => '1.302210';
};
on develop => sub {
    requires 'Perl::Critic';
    requires 'Perl::Tidy';
    requires 'Test::PerlTidy';
};

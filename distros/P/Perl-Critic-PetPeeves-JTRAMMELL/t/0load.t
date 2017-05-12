use Test::More tests => 2;

use_ok('Perl::Critic::PetPeeves::JTRAMMELL');
use_ok('Perl::Critic::Policy::Variables::ProhibitUselessInitialization');

diag("\nTesting Perl::Critic::PetPeeves::JTRAMMELL");
diag("version $Perl::Critic::PetPeeves::JTRAMMELL::VERSION");
diag("Perl $], $^X");


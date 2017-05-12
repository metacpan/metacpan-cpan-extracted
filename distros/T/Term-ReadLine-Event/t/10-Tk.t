use strict;
use warnings;

BEGIN { $ENV{PERL_RL} = 'Stub'; }

use Test::More;

use Term::ReadLine 1.09;
use Term::ReadLine::Event;

plan skip_all => "Tk is not installed" unless eval "
    use Tk;
    1";

our $mw;
plan skip_all => "Tk can't initialise: $@" unless eval {
    $mw = MainWindow->new(-title => '');
    $mw->withdraw();
    1;
};

plan tests => 2;
diag( "Testing Term::ReadLine::Event: Tk version $Tk::VERSION" );

my $term = Term::ReadLine::Event->with_Tk('test');
isa_ok($term->trl, 'Term::ReadLine::Stub');

my $w = sub {
    pass;
    print {$term->OUT()} $Term::ReadLine::Stub::rl_term_set[3];
    exit 0;
};
Tk::after($mw, 1000, $w);

$term->readline('> Do not type anything');
fail();

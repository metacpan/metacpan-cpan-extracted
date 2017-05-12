use lib 't', 'lib';
use strict;
use warnings;
use Test::More;
BEGIN {
    eval "use Test::Memory::Cycle";
    if ($@) {
        plan skip_all => 'These tests require Test::Memory::Cycle';
    }
    else {
        plan tests => 13;
    }
}
use Spoon;

{
    my $spoon = Spoon->new;
    my $hub = $spoon->load_hub;

    memory_cycle_ok($spoon, 'check for cycles in Spoon object');
    memory_cycle_ok($hub, 'check for cycles in Spoon::Hub object');
}

{
    my $spoon = Spoon->new;
    {
        my $hub = $spoon->load_hub;
    }

    ok($spoon->hub, 'Hub does not get destroyed before main goes out of scope');
}

{
    my %classes = (cgi_class => 'Spoon::CGI',
                   headers_class => 'Spoon::Headers',
                   cookie_class => 'Spoon::Cookie',
                   formatter_class => 'Spoon::Formatter',
                   template_class => 'Spoon::Template::TT2',
                  );

    my $spoon = Spoon->new;
    my $hub = $spoon->load_hub(\%classes);

    foreach my $key (keys %classes) {
        (my $id = $key) =~ s/_class$//;
        my $object = $hub->$id;

        memory_cycle_ok($hub, 'check for cycles in Spoon::Hub object');
        memory_cycle_ok($object, "check for cycles in $classes{$key} object");
    }
}


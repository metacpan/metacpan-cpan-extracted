use 5.010;

use Pask;
use Data::Dumper;

my $pask = Pask::task "GreetWorld";

$pask->set_parameter({
    "from" => [
        "argument",
        {"default" => "yesterday"},
        {"type" => "date"}
    ],    
    "to" => [
        "argument",
        "nullable",
        {"type" => "date"},
        {"todo" => sub { shift->{"from"} }},
        {"dependency" => ["from"]}
    ],
    "date" => [
        {"fn" => sub { shift->{"from"} }}
    ],
    "name" => [
        {"argument" => "nick"},
        {"default" => "dreamy"}
    ]
});

$pask->set_command(sub {
    my $args = shift;
    Pask::say "Yesterday is ", $args->{"to"};
    Pask::say {-info}, "Hello, ", $args->{"name"}, ":";
    Pask::say {-debug}, "A Wonderful Day!";
});

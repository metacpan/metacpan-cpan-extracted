use 5.010;

use Pask;

my $pask = Pask::task "BadApple" => {
    description => "Bad Apple is a demo!",
    command => sub {
        Pask::say {-debug}, "Red Orange";
        Pask::say {-info}, "Cyan Water";
        Pask::say {-title}, "Green Leaf";
        Pask::say {-description}, "Purple Grape";
        Pask::say "Grey Shadow";
    }
};

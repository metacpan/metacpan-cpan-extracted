package Object::Animal::ICow;
use Pony::Object -abstract;

    sub getLegsCount : Abstract;
    sub getMilk : Abstract;
    sub getYieldOfMilk : Abstract;

1;
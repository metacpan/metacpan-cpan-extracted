Railsish::Router->draw(
    sub {
        my ($map) = @_;
        $map->connect("/:controller/:action");
    }
);

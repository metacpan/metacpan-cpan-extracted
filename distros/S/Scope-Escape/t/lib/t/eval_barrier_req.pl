push @events, ["c2", Scope::Escape::Continuation::is_accessible($cont)];
$cont->("c2a", "c2b");

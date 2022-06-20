package Not::Corinna::Role::Created {
    use MooseX::Extended::Role types => ['PositiveInt'];
    field created => ( isa => PositiveInt, lazy => 0, default => sub {time} );
}

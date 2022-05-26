package Not::Corinna::Role::Created {
    use MooseX::Extended::Role types => ['PositiveInt'];
    field created => ( isa => PositiveInt, default => sub {time} );
}

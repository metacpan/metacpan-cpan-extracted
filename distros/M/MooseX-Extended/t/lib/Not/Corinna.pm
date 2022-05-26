package Not::Corinna {
    use MooseX::Extended types => [qw(compile Num NonEmptyStr Str PositiveInt ArrayRef)];
    use List::Util 'sum';

    with qw(
      Not::Corinna::Role::Created
    );

    # these default to 'ro' (but you can override that) and are required
    param _name => ( isa => NonEmptyStr, init_arg => 'name' );
    param title => ( isa => Str,         required => 0 );

    # fields must never be passed to the constructor
    # note that ->title and ->name are guaranteed to be set before
    # this because fields are lazy by default
    field name => (
        isa     => NonEmptyStr,
        default => sub ($self) {
            my $title = $self->title;
            my $name  = $self->_name;
            return $title ? "$title $name" : $name;
        },
    );

    sub add ( $self, $args ) {
        state $check = compile( ArrayRef [ Num, 1 ] );
        ($args) = $check->($args);
        return sum( $args->@* );    # note that Not::Corinna->can('sum') will return false!
    }

    sub warnit ($self) {
        carp("this is a warning");    # carp and croak are automatically available
    }

    # There is no need for __PACKAGE__->meta->make_immutable or to end in a true
    # value. MooseX::Extended takes care of that for you.
}

package Reaction::Role::Meta::Attribute;

use Moose::Role;

#is => 'Bool' ? or leave it open
has lazy_fail  =>
    (is => 'ro', reader => 'is_lazy_fail',  required => 1, default => 0);

if ( $Moose::VERSION < 1.09 ) { 
  around legal_options_for_inheritance => sub {
    return (shift->(@_), qw/valid_values/);
  };
}

around _process_options => sub {
    my $super = shift;
    my ($class, $name, $options) = @_;

    my $fail  = $options->{lazy_fail};

    if ( $fail ) {
      confess("You may not use both lazy_build and lazy_fail for one attribute")
        if $fail && $options->{lazy_build};

      $options->{lazy} = 1;
      $options->{required} = 1;
      $options->{default} = sub { confess "${name} must be provided before calling reader" };
    }

    #we are using this everywhere so might as well move it here.
    $options->{predicate} ||= ($name =~ /^_/) ? "_has${name}" : "has_${name}"
      if !$options->{required} || $options->{lazy};

    $super->($class, $name, $options);
};

foreach my $type (qw(clearer predicate)) {

  my $value_meth = do {
    if ($type eq 'clearer') {
      'clear_value'
    } elsif ($type eq 'predicate') {
      'has_value'
    } else {
      confess "NOTREACHED";
    }
  };

  __PACKAGE__->meta->add_method("get_${type}_method" => sub {
    my $self = shift;
    my $info = $self->$type;
    return $info unless ref $info;
    my ($name) = %$info;
    return $name;
  });

  __PACKAGE__->meta->add_method("get_${type}_method_ref" => sub {
    my $self = shift;
    if ((my $name = $self->${\"get_${type}_method"}) && $self->associated_class) {
        return $self->associated_class->get_method($name);
    } else {
        return sub { $self->$value_meth(@_); }
    }
  });
}

1;

__END__;

=head1 NAME

Reaction::Meta::Attribute

=head1 SYNOPSIS

    has description => (is => 'rw', isa => 'Str', lazy_fail => 1);

=head1 Method-naming conventions

Reaction::Meta::Attribute will never override the values you set for method names,
but if you do not it will follow these basic rules:

Attributes with a name that starts with an underscore will default to using
builder and predicate method names in the form of the attribute name preceeded by
either "_has" or "_build". Otherwise the method names will be in the form of the
attribute names preceeded by "has_" or "build_". e.g.

   #auto generates "_has_description" and expects "_build_description"
   has _description => (is => 'rw', isa => 'Str', lazy_fail => 1);

   #auto generates "has_description" and expects "build_description"
   has description => (is => 'rw', isa => 'Str', lazy_fail => 1);

=head2 Predicate generation

All non-required or lazy attributes will have a predicate automatically
generated for them if one is not already specified.

=head2 lazy_fail

lazy_fail will fail if it is called without first having set the value.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut

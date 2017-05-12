package Mite::Attribute;

use Carp;
use Mouse;
use Method::Signatures;

has default =>
  is            => 'rw',
  isa           => 'Maybe[Str|Ref]',
  predicate     => 'has_default';

has coderef_default_variable =>
  is            => 'rw',
  isa           => 'Str',
  lazy          => 1,           # else $self->name might not be set
  default       => method {
      # This must be coordinated with Mite.pm
      return sprintf '$__%s_DEFAULT__', $self->name;
  };

has is =>
  is            => 'rw',
  default       => '',
  trigger       => method($new, $old?) {
      croak
        "I do not understand this option (is => $new) on attribute (@{[$self->name]})"
        unless $new =~ /^(ro|rw|)$/;
      return;
  };

has name =>
  is            => 'rw',
  isa           => 'Str',
  required      => 1;

method clone(%args) {
    $args{name} //= $self->name;
    $args{is}   //= $self->is;

    # Because undef is a valid default
    $args{default} = $self->default if !exists $args{default} and $self->has_default;

    return $self->new(
        %args
    );
}

method has_dataref_default() {
    # We don't have a default
    return 0 unless $self->has_default;

    # It's not a reference.
    return 0 if $self->has_simple_default;

    return ref $self->default ne 'CODE';
}

method has_coderef_default() {
    # We don't have a default
    return 0 unless $self->has_default;

    return ref $self->default eq 'CODE';
}

method has_simple_default() {
    return 0 unless $self->has_default;

    # Special case for regular expressions, they do not need to be dumped.
    return 1 if ref $self->default eq 'Regexp';

    return !ref $self->default;
}

method _empty() { return ';' }

method compile() {
    my $perl_method = $self->is eq 'rw' ? '_compile_rw_perl'    :
                      $self->is eq 'ro' ? '_compile_ro_perl'    :
                                          '_empty'              ;

    my $xs_method   = $self->is eq 'rw' ? '_compile_rw_xs'      :
                      $self->is eq 'ro' ? '_compile_ro_xs'      :
                                          '_empty'              ;

    return sprintf <<'CODE', $self->$xs_method, $self->$perl_method;
if( !$ENV{MITE_PURE_PERL} && eval { require Class::XSAccessor } ) {
%s
}
else {
%s
}
CODE
}

method _compile_rw_xs() {
    my $name = $self->name;

    return <<"CODE";
Class::XSAccessor->import(
    accessors => { q[$name] => q[$name] }
);
CODE

}

method _compile_rw_perl() {
    my $name = $self->name;

    return sprintf <<'CODE', $name, $name, $name;
*%s = sub {
    # This is hand optimized.  Yes, even adding
    # return will slow it down.
    @_ > 1 ? $_[0]->{ q[%s] } = $_[1]
           : $_[0]->{ q[%s] };
}
CODE

}

method _compile_ro_xs() {
    my $name = $self->name;

    return <<"CODE";
Class::XSAccessor->import(
    getters => { q[$name] => q[$name] }
);
CODE
}

method _compile_ro_perl() {
    my $name = $self->name;
    return sprintf <<'CODE', $name, $name, $name;
*%s = sub {
    # This is hand optimized.  Yes, even adding
    # return will slow it down.
    @_ > 1 ? require Carp && Carp::croak("%s is a read-only attribute of @{[ref $_[0]]}")
           : $_[0]->{ q[%s] };
};
CODE
}

1;

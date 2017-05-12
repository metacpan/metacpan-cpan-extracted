package Method::Generate::Accessor::Role::TypeTiny;
use Moo::Role;
use Sub::Quote qw(quotify);

around _generate_isa_check => sub {
  my $orig = shift;
  my $self = shift;
  my ($name, $value, $check, $init_arg) = @_;
  return $self->$orig(@_)
    unless eval { $check->isa('Type::Tiny') };

  my $var = '$isa_check_for_'.$self->_sanitize_name($name);
  $self->{captures}->{$var} = \$check;

  my $varname = defined $init_arg
    ? sprintf('$args->{%s}', quotify($init_arg))
    : sprintf('$self->{%s}', quotify($name));

  my $inline_check = $check->can_be_inlined ? $check->inline_check($value)
                                            : "${var}->check(${value})";

  join "\n",
    '(',
    "  ${inline_check} or do {",
    '    require Error::TypeTiny::Assertion;',
    '    local $Method::Generate::Accessor::CurrentAttribute;',
    '    Error::TypeTiny::Assertion->throw(',
    "      message => ${var}->get_message(${value}),",
    "      type    => ${var},",
    "      value   => ${value},",
    '      attribute_name => '.quotify($name).',',
    '      attribute_step => '.quotify('isa check').',',
    '      varname        => '.quotify($varname).',',
    '    );',
    '  }',
    ')';
};

around _generate_coerce => sub {
  my $orig = shift;
  my $self = shift;
  my ($name, $value, $coerce, $init_arg) = @_;
  return $self->$orig(@_)
    unless eval { $coerce->isa('Type::Coercion') };

  my $var = '$coercion_for_'.$self->_sanitize_name($name);
  $self->{captures}->{$var} = \$coerce;
  $coerce->can_be_inlined ? $coerce->inline_coercion($value) : "${var}->coerce(${value})"
};

1;

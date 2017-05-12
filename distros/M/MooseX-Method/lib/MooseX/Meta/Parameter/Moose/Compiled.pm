package MooseX::Meta::Parameter::Moose::Compiled;

use Moose;

use HTML::Template::Pro;
use Moose::Util::TypeConstraints;
use MooseX::Method::Constant;
use MooseX::Method::Exception;

extends qw/MooseX::Meta::Parameter::Moose/;

with qw/MooseX::Meta::Parameter::Compiled/;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

my $compile_template = HTML::Template::Pro->new (scalarref => \<< 'EOF');
sub {
  my $provided = $#_ >= 0;

  $_ = $_[0];

  <TMPL_VAR NAME="body">

  return $_;
};
EOF

my $as_perl_template = HTML::Template::Pro->new (scalarref => \<< 'EOF');
<TMPL_IF NAME="has_default">
unless ($provided) {
  <TMPL_IF NAME="has_default_coderef">
  $_ = <TMPL_VAR NAME="default">->($self);
  <TMPL_ELSE>
  $_ = <TMPL_VAR NAME="default">;
  </TMPL_IF>

  $provided = 1;
}
</TMPL_IF>

<TMPL_IF NAME="has_constraint_or_does">
if ($provided) {
  <TMPL_IF NAME="has_constraint">
  unless (<TMPL_VAR NAME="validator">->($_)) {
    <TMPL_IF NAME="has_coerce">
    $_ = <TMPL_VAR NAME="constraint">->coerce ($_);

    MooseX::Method::Exception->throw ("Argument isn't a (<TMPL_VAR NAME="isa">)")
      unless (<TMPL_VAR NAME="validator">->($_));
    <TMPL_ELSE>
    MooseX::Method::Exception->throw ("Argument isn't a (<TMPL_VAR NAME="isa">)");
    </TMPL_IF>
  }
  </TMPL_IF>

  <TMPL_IF NAME="has_does">
  MooseX::Method::Exception->throw ("Does not do (<TMPL_VAR NAME="does">)")
    unless Scalar::Util::blessed ($_) && $_->can ('does') && $_->does ("<TMPL_VAR NAME="does">");
  </TMPL_IF>
}
  <TMPL_IF NAME="has_required">
else {
  MooseX::Method::Exception->throw ("Must be specified");
}
  </TMPL_IF>
<TMPL_ELSE>
  <TMPL_IF NAME="has_required">
MooseX::Method::Exception->throw ("Must be specified")
  unless ($provided);
  </TMPL_IF>
</TMPL_IF>
EOF

override new => sub {
  my $self = super;

  $self->{params} = $self->_setup_params;

  return $self;
};

sub validate {
  my $self = shift;

  $self->{compiled_validator} ||= $self->compile;

  return $self->{compiled_validator}->(@_);
}

sub compile {
  my ($self) = @_;

  $compile_template->param (body => $self->as_perl);

  my $coderef = eval $compile_template->output;

  MooseX::Method::Exception->throw ("Compilation failed: $@")
    if ($@);

  return $coderef;
}

sub as_perl {
  my ($self) = @_;

  $as_perl_template->param ($self->{params});

  return $as_perl_template->output;
}

sub _setup_params {
  my ($self) = @_;

  my $params = {
    has_default            => 0,
    has_default_coderef    => 0,
    has_constraint_or_does => 0,
    has_constraint         => 0,
    has_coerce             => 0,
    has_does               => 0,
    has_required           => 0,
  };

  if (defined $self->{default}) {
    $params->{has_default} = 1;

    $params->{has_default_coderef} = (ref $self->{default} eq 'CODE');

    $params->{default} = MooseX::Method::Constant->make ($self->{default});
  }

  if (defined $self->{type_constraint} || defined $self->{does}) {
    $params->{has_constraint_or_does} = 1;

    if (defined $self->{type_constraint}) {
      $params->{isa} = quotemeta $self->{isa};

      $params->{has_constraint} = 1;

      $params->{has_coerce} = $self->{coerce};

      $params->{constraint} = MooseX::Method::Constant->make ($self->{type_constraint}); 

      if ($self->{type_constraint}->can ('has_hand_optimized_type_constraint') && $self->{type_constraint}->has_hand_optimized_type_constraint) {
        $params->{validator} = MooseX::Method::Constant->make ($self->{type_constraint}->hand_optimized_type_constraint);
      } else {
        $params->{validator} = MooseX::Method::Constant->make ($self->{type_constraint}->_compiled_type_constraint);
      }

      $params->{has_coerce} = 1
        if $self->{coerce};
    }

    if (defined $self->{does}) {
      $params->{has_does} = 1;

      $params->{does} = quotemeta $self->{does};
    }
  }

  $params->{has_required} = 1
    if $self->{required};

  return $params;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__

=pod

=head1 NAME

MooseX::Meta::Parameter::Moose::Compiled - Compiled Moose parameter metaclass

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 METHODS

=over 4

=item B<validate>

Overriden from superclass.

=item B<as_perl>

Returns a string of perl code that will validate an argument. Expects
the value to be validated to reside in $_ and that the scalar $provided
is present to tell if a value was provided. This is because undef is
an allowed provided value. Modifies $_ if coercion is set.

=item B<compile>

Returns a coderef that will perform the validation. Essencially a
wrapper around as_perl that is handy if you don't need to do any
inlining but still want the performance benefit. Note that the
validate method is overridden to use a compiled version of the
validator so you probably don't need to use this method yourself.

=back

=head1 BUGS

Most software has bugs. This module probably isn't an exception. 
If you find a bug please either email me, or add the bug to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Anders Nor Berle.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


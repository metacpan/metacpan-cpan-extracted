package MooseX::Meta::Signature::Positional::Compiled;

use Moose;

use HTML::Template::Pro;
use MooseX::Meta::Parameter::Moose::Compiled;
use MooseX::Method::Constant;
use MooseX::Method::Exception;

extends qw/MooseX::Meta::Signature::Positional/;

with qw/MooseX::Meta::Signature::Compiled/;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

my $compile_template = HTML::Template::Pro->new (scalarref => \<< 'EOF');
sub {
  my @values = @_;

<TMPL_VAR NAME="body">

  return @values;
}
EOF

my $as_perl_template = HTML::Template::Pro->new (scalarref => \<< 'EOF');
my $pos = 0;

eval {
  my $provided;
<TMPL_LOOP NAME="parameters">
  <TMPL_IF NAME="has_inline">
  $provided = $#values >= <TMPL_VAR NAME="pos">;

  $_ = $values[<TMPL_VAR NAME="pos">];

  <TMPL_VAR NAME="body">

  $values[<TMPL_VAR NAME="pos">] = $_;
  <TMPL_ELSE>
    $values[<TMPL_VAR NAME="pos">] = <TMPL_VAR NAME="parameter">->validate ($values[<TMPL_VAR NAME="pos">]);
  </TMPL_IF>

  $pos++;
</TMPL_LOOP>
};

if ($@) {
  if (Scalar::Util::blessed $@ && $@->isa ('MooseX::Method::Exception')) {
    $@->error ("Parameter $pos: " . $@->error);

    $@->rethrow;
  } else {
    die $@;
  }
}
EOF

sub _parameter_metaclass { 'MooseX::Meta::Parameter::Moose::Compiled' }

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
};

sub _setup_params {
  my ($self) = @_;

  my $params = {
    parameters => [],
  };

  my $pos = 0;

  for (@{ $self->{'@!parameter_map'} }) {
    my $parameter_params = {
      pos => $pos,
    };

    if ($_->does ('MooseX::Meta::Parameter::Compiled')) {
      $parameter_params->{'has_inline'} = 1;
      
      $parameter_params->{'body'} = $_->as_perl;
    } else {
      $parameter_params->{'parameter'} = MooseX::Method::Constant->make ($_);
    }
      
    push @{ $params->{parameters} },$parameter_params;

    $pos++;
  }

  return $params;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__

=pod

=head1 NAME

MooseX::Meta::Signature::Positional::Compiled - Compiled positional signature

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

  use MooseX::Meta::Signature::Positional::Compiled;

  my $validator = MooseX::Meta::Signature::Positional::Compiled->new ({ isa => 'Int' })->compile;

  eval {
    $validator->(42);
  };

=head1 METHODS

=over 4

=item validate

Overriden from the superclass.

=item compile

Produces a validator coderef.

=item as_perl

Spits out most of the perl code used to produce the coderef above.
This is primarily used internally for inlining.

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


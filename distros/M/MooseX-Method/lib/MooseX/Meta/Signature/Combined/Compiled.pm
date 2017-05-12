package MooseX::Meta::Signature::Combined::Compiled;

use Moose;

use HTML::Template::Pro;
use MooseX::Meta::Signature::Named::Compiled;
use MooseX::Meta::Signature::Positional::Compiled;
use MooseX::Method::Constant;
use MooseX::Method::Exception;

extends qw/MooseX::Meta::Signature::Combined/;

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
my @pos_values = (scalar @values <= <TMPL_VAR NAME="size"> ? @values : @values[0..(<TMPL_VAR NAME="size_min">)]);

my @named_values = @values[<TMPL_VAR NAME="size">..$#values];

@values = @pos_values;

<TMPL_VAR NAME="pos_body">

@pos_values = @values;

@values = @named_values;

<TMPL_VAR NAME="named_body">

@named_values = @values;

@values = (@pos_values,@named_values);
EOF

sub _positional_metaclass { 'MooseX::Meta::Signature::Positional::Compiled' }

sub _named_metaclass { 'MooseX::Meta::Signature::Named::Compiled' }

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

  MooseX::Method::Exception->throw ("Compilation error: $@")
    if $@;

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
    size       => $self->{positional_signature_size},
    size_min   => $self->{positional_signature_size} - 1,
    pos_body   => $self->{positional_signature}->as_perl,
    named_body => $self->{named_signature}->as_perl,
  };

  return $params;  
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__

=pod

=head1 NAME

MooseX::Meta::Signature::Combined::Compiled - Compiled combined signature

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

  use MooseX::Meta::Signature::Combined::Compiled;

  my $validator = MooseX::Meta::Signature::Combined::Compiled->new ({ isa => 'Int' })->compile;

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


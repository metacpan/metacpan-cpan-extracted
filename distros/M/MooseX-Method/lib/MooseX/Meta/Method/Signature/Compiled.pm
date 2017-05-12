package MooseX::Meta::Method::Signature::Compiled;

use Moose;

use Carp;
use HTML::Template::Pro;
use MooseX::Method::Constant;
use MooseX::Method::Exception;

extends qw/MooseX::Meta::Method::Signature/;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

my $validating_template = HTML::Template::Pro->new (scalarref => \<< 'EOF');
sub {
  my $self = shift;

  eval {
<TMPL_IF NAME="has_inline">
    my @values = @_;

    <TMPL_VAR NAME="body">

    @_ = ($self,@values);
<TMPL_ELSE>
    @_ = ($self,<TMPL_VAR NAME="signature">->validate (@_));
</TMPL_IF>
  };

  Carp::croak ("$@")
    if $@;

  goto &<TMPL_VAR NAME="coderef">;
}
EOF

sub _make_validating_coderef {
  my ($class,$signature,$coderef) = @_;

  my $params = {
    has_inline => 0,
  };

  if ($signature->does ('MooseX::Meta::Signature::Compiled')) {
    $params->{has_inline} = 1;
    
    $params->{body} = $signature->as_perl;
  } else {
    $params->{signature} = MooseX::Method::Constant->make ($signature);
  }

  $params->{coderef} = MooseX::Method::Constant->make ($coderef);
  
  $validating_template->param ($params);

  my $new_coderef = eval $validating_template->output;

  MooseX::Method::Exception->throw ("Compilation failed: $@")
    if $@;

  return $new_coderef;
}
 
1;

__END__

=pod

=head1 NAME

MooseX::Meta::Method::Signature::Compiled - Compiled signature method metaclass

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

See L<MooseX::Meta::Method::Signature> for examples on how to use
this. Unlike the other compiled classes, it has no extra methods.

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


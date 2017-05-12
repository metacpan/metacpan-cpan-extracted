package Template::HTML::Context;

use strict;
use warnings;
use base qw(Template::Context);

sub filter {
    my $self = shift;
    my ($name, $args, $alias) = @_;

    if ( $name eq 'none' ) {
        return sub {
            my $value = shift;
            return $value->plain if UNIVERSAL::isa($value, 'Template::HTML::Variable');
            return $value;
        };
    }

    my $filter = $self->SUPER::filter(@_);

    return sub {
        my $value = shift;

        if ( UNIVERSAL::isa($value, 'Template::HTML::Variable') ) {
            return ref($value)->new($filter->($value->plain));
        }

        return $filter->($value);
    };
}

1;
__END__

=head1 NAME

Template::HTML::Context - A replacement for Template::Context that wraps filters

=head1 SYNOPSIS

  use Template::HTML;

  my $config = {
      # See Template.pm
  };

  my $template = Template::HTML->new($config);

  my $vars = {
      var1  => $value,
      var2  => \%hash,
      var3  => \@list,
      var4  => \&code,
      var5  => $object,
  };

  # specify input filename, or file handle, text reference, etc.
  my $input = 'myfile.html';

  # process input template, substituting variables
  $template->process($input, $vars)
      || die $template->error();

=head1 DESCRIPTION

This is a subclass of Template::Context (the Template Toolkit context module).
It wraps all filter calls to ensure that the automatic HTML encoding behaves
correctly when other filters are applied.

An extra special filter called "none" is implemented here to "opt-out" of
automatic encoding.

=head1 SEE ALSO

http://git.dollyfish.net.nz/?p=Template-HTML

=head1 FUNCTIONS

=head2 filter()

An overridden function from Template::Context that wraps filters to ensure the
automatic HTML encoding works correctly.

=head1 AUTHOR

Martyn Smith, E<lt>msmith@cpan.orgE<gt>

=head1 COPYTIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


package Template::HTML::Stash;

use strict;
use warnings;
use base qw(Template::Stash);
use Template::HTML::Variable;


sub get {
    my $self = shift;

    my $value = $self->SUPER::get(@_);

    $value = Template::HTML::Variable->new($value) unless ref $value;

    return $value;
}

1;
__END__

=head1 NAME

Template::HTML::Stash - A replacement for Template::Stash that wraps the get method

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

This is a subclass of Template::Stash (the Template Toolkit stash module).  It
wraps all get calls and returns an HTML::Template::Variable instead of the raw
string.

=head1 SEE ALSO

http://git.dollyfish.net.nz/?p=Template-HTML

=head1 FUNCTIONS

=head2 get()

An overridden function from Template::Stash that calls the parent classes get
method, and simply returns an Template::HTML::Variable instead of a raw string.

=head1 AUTHOR

Martyn Smith, E<lt>msmith@cpan.orgE<gt>

=head1 COPYTIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


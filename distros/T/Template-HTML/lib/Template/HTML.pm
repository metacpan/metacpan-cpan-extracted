package Template::HTML;

use strict;
use warnings;
use base qw(Template);

our $VERSION = '0.04';

use Template::HTML::Stash;
use Template::HTML::Context;

sub new {
    my $class = shift;

    my $config = $_[0];

    unless ( ref $config eq 'HASH' ) {
        $config = { @_ };
    }

    $config->{STASH} = Template::HTML::Stash->new($config);
    $config->{CONTEXT} = Template::HTML::Context->new($config);

    $class->SUPER::new($config);
}

1;
__END__

=head1 NAME

Template::HTML - Automatic HTML encoding of tags for Template Toolkit

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

This is a subclass of Template (the Template Toolkit frontend) provides
completely automatic application of an HTML filter on all templated variables.

An extra special filter called "none" is provided to "opt-out" on a per
variable basis.

=head1 SEE ALSO

http://git.dollyfish.net.nz/?p=Template-HTML

=head1 FUNCTIONS

=head2 new()

An implementation of the Template::new() method that forces the Context and
Stash to be Template::HTML::* rather than Template::*

=head1 AUTHOR

Martyn Smith, E<lt>msmith@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 COPYRIGHT

Copyright (c) 2008 - 2010
the Template::HTML L</AUTHOR>
as listed above.


=cut

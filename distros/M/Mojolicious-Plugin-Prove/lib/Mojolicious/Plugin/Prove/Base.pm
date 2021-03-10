package Mojolicious::Plugin::Prove::Base;
$Mojolicious::Plugin::Prove::Base::VERSION = '0.11';
# ABSTRACT: Base class for Mojolicious::Plugin::Prove

use Mojo::Base 'Mojolicious::Plugin';

use Cwd 'abs_path';

has 'prefix';
has 'conf';

sub add_template_path {
  my ($self, $renderer, $class) = @_;
  
  $class  =~ s{::}{/}g;
  $class .= '.pm';
  
  my $public = abs_path $INC{$class};
  $public    =~ s/\.pm$//;
  
  push @{$renderer->paths}, "$public/templates";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Prove::Base - Base class for Mojolicious::Plugin::Prove

=head1 VERSION

version 0.11

=head1 METHODS

=head2 add_template_path

Adds the path to templates for some loaded classes

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

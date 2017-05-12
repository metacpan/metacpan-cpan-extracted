package Spreadsheet::Template::Processor;
our $AUTHORITY = 'cpan:DOY';
$Spreadsheet::Template::Processor::VERSION = '0.05';
use Moose::Role;
# ABSTRACT: role for classes which preprocess a template file before rendering

requires 'process';



no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::Template::Processor - role for classes which preprocess a template file before rendering

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  package MyProcessor;
  use Moose;

  with 'Spreadsheet::Template::Processor';

  sub process {
      # ...
  }

=head1 DESCRIPTION

This role should be consumed by any class which will be used as the
C<processor_class> in a L<Spreadsheet::Template> instance.

=head1 METHODS

=head2 process($contents, $vars)

This method is required to be implemented by any classes which consume this
role. It should take the contents of the template and return a JSON file as
described in L<Spreadsheet::Template>. This typically just means running it
through a template engine of some kind.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut

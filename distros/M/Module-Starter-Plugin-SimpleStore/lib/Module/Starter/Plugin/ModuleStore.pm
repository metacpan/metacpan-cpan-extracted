use warnings;
use strict;

package Module::Starter::Plugin::ModuleStore;

our $VERSION = '0.144';

use Carp ();

=head1 NAME

Module::Starter::Plugin::ModuleStore -- store inline templates in modules

=head1 VERSION

version 0.144

=head1 SYNOPSIS

 use Module::Starter qw(
   Module::Starter::Simple
   Module::Starter::Plugin::Template
   Module::Starter::Plugin::ModuleStore
   ...
 );

 Module::Starter->create_distro( ... );

=head1 DESCRIPTION

This Module::Starter plugin is intended to be loaded after
Module::Starter::Plugin::Template.  It implements the C<templates> method,
required by the Template plugin.  It works like InlineStore, but instead of
loading a physical file, loads the DATA section of a Perl module.

=cut

=head1 METHODS

=head2 C<< templates >>

This method reads in the template module (described above) and populates the
object's C<templates> attribute.  The module template module is found by
checking the MODULE_TEMPLATE_MODULE environment variable and then the
"template_module" config option.

=cut

sub _template_filehandle {
    my $self = shift;

    my $template_module =
      ($ENV{MODULE_TEMPLATE_MODULE} || $self->{template_module});
    eval "require $template_module"
      or Carp::croak "couldn't load template store module $template_module: $@";

    no strict 'refs'; ## no critic NoStrict
    return \*{"$template_module\::DATA"};
}

sub templates {
    my $self = shift;
    my %template;
     
    my $template_file = $self->_template_filehandle;

    my $fn = q{_};
    while (<$template_file>) {
        if (/^___([-_.0-9A-Za-z]+)___$/) {
            $fn = $1;
            $template{$fn} = q{};
            next;
        }
        $template{$fn} .= $_;
    }

    return %template;
}

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 Bugs

Please report any bugs or feature requests to
C<bug-module-starter-plugin-inlinestore@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2004 Ricardo SIGNES, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

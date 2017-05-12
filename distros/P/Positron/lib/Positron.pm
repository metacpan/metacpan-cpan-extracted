package Positron;
our $VERSION = 'v0.1.3'; # VERSION

=head1 NAME

Positron - a family of templating and markup modules

=head1 VERSION

version v0.1.3

=head1 SYNOPSIS

  use Positron;

  my $template = Positron::Template->new();

  my $dom    = create_dom_tree();
  my $data   = { foo => 'bar', baz => [ 1, 2, 3 ] };
  my $result = $template->process($dom, $data); 

=head1 DESCRIPTION

Positron is a family of templating and markup modules. The module C<Positron> itself
is an umbrella module which simply requires all the other modules, but you can also
load them all separately.

B<Warning:> this is still B<alpha software> at best. Things can and will change, in
backwards incompatible and inconvenient ways.

=head1 MAIN MODULES

These are the modules you will most likely be using.

=head2 Positron::DataTemplate

L<Positron::DataTemplate> is a templating system for plain data. It accepts plain data
as templates, i.e. nested lists and hashes, and transforms them using the passed
template parameters (the "environment") into even more plain data. If this sounds
confusing, please check the module itself for examples.

=cut

use Positron::DataTemplate;

=head1 SUPPORTING MODULES

=head2 Positron::Environment

L<Positron::Environment> represents a set of template parameters, a mapping between
keys and values for evaluating the template. This is very similar to a plain hash, 
but with an additional C<parent> mechanism for forming a hierarchical
stack of environments.

=cut

use Positron::Environment;

=head2 Positron::Expression

L<Positron::Expression> implements a simple language for template parameter evaluation.
Instead of only looking up values with plain keys, expressions can be hash lookups,
method calls, or literal strings.

=cut

use Positron::Expression;

1; # End of Positron

__END__

=head1 AUTHOR

Ben Deutsch, C<< <ben at bendeutsch.de> >>

=head1 BUGS

None known so far, though keep in mind that this is alpha software.

Please report any bugs or feature requests to C<bug-positron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Positron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

This module is part of the Positron distribution.

You can find documentation for this distribution with the perldoc command.

    perldoc Positron

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Positron>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Positron>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Positron>

=item * Search CPAN

L<http://search.cpan.org/dist/Positron/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Ben Deutsch. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
See L<http://dev.perl.org/licenses/> for more information.

=cut

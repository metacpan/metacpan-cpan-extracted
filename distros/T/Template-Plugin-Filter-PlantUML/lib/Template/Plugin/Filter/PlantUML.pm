package Template::Plugin::Filter::PlantUML;

use 5.006;
use strict;
use warnings;

require Template::Plugin::Filter;
use base qw(Template::Plugin::Filter);
use vars qw($VERSION $DYNAMIC $FILTER_NAME);

use WWW::PlantUML;

=for html <a href="https://travis-ci.com/ranwitter/perl5-Template-Plugin-Filter-PlantUML"><img src="https://travis-ci.com/ranwitter/perl5-Template-Plugin-Filter-PlantUML.svg?branch=master"></a>&nbsp;</a><a title="Artistic-2.0" href="https://opensource.org/licenses/Artistic-2.0"><img src="https://img.shields.io/badge/License-Perl-0298c3.svg"></a>

=head1 NAME

Template::Plugin::Filter::PlantUML - A template toolkit plugin filter for encoding and processing PlantUML Diagrams using a PlantUML Server.

=head1 VERSION

Version 0.02

=cut

our $VERSION     = 0.02;
our $DYNAMIC     = 1;
our $FILTER_NAME = 'plantuml';

=head1 SYNOPSIS

To use this plugin, you have to make sure that the Template Toolkit knows about its namespace.

    my $tt2 = Template->new({
        PLUGIN_BASE => 'Template::Plugin::Filter',
    });

    # or

    my $tt2 = Template->new({
        PLUGINS => {
           PlantUML => 'Template::Plugin::Filter::PlantUML',
        },
    });

Then you C<USE> your plugin in a template file as follows.

    [% USE 'http://www.plantuml.com/plantuml' 'svg' -%]
    
    [% url = FILTER plantuml %]
      Bob -> Alice : hello
    [% END %]
    
    <img src="[% url %]"/>

Finally process your template.

    $tt2->process('foo.tt2') || die $tt2->error();

Result would be:

    <img src="http://www.plantuml.com/plantuml/svg/~169NZKb1moazIqBLJSCp9J4vLi5B8ICt9oUS204a_1dy0"/>

=head1 EXAMPLE

=begin HTML

<p><img src="http://www.plantuml.com/plantuml/svg/~169NZKb1moazIqBLJSCp9J4vLi5B8ICt9oUS204a_1dy0" alt="Live Example from PlantUML.com" /></p>

=end HTML

=head1 DESCRIPTION

This is a trivial Template::Toolkit plugin filter to allow any template writer to embed PlantUML Diagram Syntax in Templates and have them encoded and processed via any PlantUML Server in any supported formats.

It uses C<WWW:PlantUML> remote client under the hood.

=head1 SUBROUTINES/METHODS

=head2 init

defines init() method.

=cut

sub init {
    my $self = shift;
    $self->install_filter($FILTER_NAME);
    return $self;
}

=head2 filter

defines filter() method.

=cut

sub filter {
    my ( $self, $code, $args, $conf ) = @_;

    $args = $self->merge_args($args);
    $conf = $self->merge_config($conf);

    my $puml = WWW::PlantUML->new( @$args[0] );
    return $puml->fetch_url( $code, @$args[1] || 'png' );
}

=head1 AUTHOR

Rangana Sudesha Withanage, C<< <rwi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-plugin-filter-plantuml at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Filter-PlantUML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::Filter::PlantUML


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-Filter-PlantUML>

=item * GitHub Repository

L<https://github.com/ranwitter/perl5-Template-Plugin-Filter-PlantUML>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Template-Plugin-Filter-PlantUML>

=item * Search CPAN

L<https://metacpan.org/release/Template-Plugin-Filter-PlantUML>

=back


=head1 ACKNOWLEDGEMENTS

Many thanks to Andy Wardley L<http://wardley.org> for his awesome L<Template::Plugin::Filter>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2019 by Rangana Sudesha Withanage.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;    # End of Template::Plugin::Filter::PlantUML

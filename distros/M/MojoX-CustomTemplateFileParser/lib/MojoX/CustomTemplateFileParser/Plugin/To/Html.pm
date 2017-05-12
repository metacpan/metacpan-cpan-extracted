package MojoX::CustomTemplateFileParser::Plugin::To::Html;

use strict;
use warnings;
use 5.10.1;

our $VERSION = '0.1002'; # VERSION
# ABSTRACT: Create html

use Moose::Role;

sub to_html {
    my $self = shift;

    my @out = ();
    my $tests = $self->structure->{'tests'};

    foreach my $test (@{ $tests }) {
        push @out => (qq{<div class="panel panel-default"><div class="panel-body">});
        if(scalar @{ $test->{'lines_before'} }) {
            push @out => @{ $test->{'lines_before'} };
        }
        push @out => ('<pre>', HTML::Entities::encode_entities(join("\n" => @{ $test->{'lines_template'} })), '</pre>');
        if(scalar @{ $test->{'lines_between'} }) {
            push @out => @{ $test->{'lines_between'} };
        }
        push @out => ('<pre>', HTML::Entities::encode_entities(join("\n" => @{ $test->{'lines_expected'} })), '</pre>');
        if(scalar @{ $test->{'lines_after'} }) {
            push @out => @{ $test->{'lines_after'} };
        }
        push @out => '<hr />', @{ $test->{'lines_expected'} };
        push @out => (qq{</div></div>});
    }

    return join '' => @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MojoX::CustomTemplateFileParser::Plugin::To::Html - Create html

=head1 VERSION

Version 0.1002, released 2015-11-26.

=head1 SYNOPSIS

  use MojoX::CustomTemplateFileParser;

  my $parser = MojoX::CustomTemplateFileParser->new(path => '/path/to/file.mojo', output => ['Html']);

  print $parser->to_html;

=head1 DESCRIPTION

MojoX::CustomTemplateFileParser::Plugin::To::Html is an output plugin to L<MojoX::CustomTemplateFileParser>.

=head2 to_html()

This method is added to L<MojoX::CustomTemplateFileParser> objects created with C<output =E<gt> ['Html']>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::InsertExample::FromMojoTemplates>

=item *

L<MojoX::CustomTemplateFileParser::Plugin::To::Pod>

=item *

L<MojoX::CustomTemplateFileParser::Plugin::To::Test>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-mojox-customtemplatefileparser>

=head1 HOMEPAGE

L<https://metacpan.org/release/MojoX-CustomTemplateFileParser>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

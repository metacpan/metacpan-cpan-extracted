package Template::Plugin::TextToHtml;

require 5.004;

use strict;
use vars qw( @ISA $VERSION );
use base qw( Template::Plugin );
use Template::Plugin;
use HTML::FromText;

$VERSION = '0.02';

sub new {
    my ($class, $context, $format) = @_;;
    $context->define_filter('text2html', [ \&text2html_filter_factory => 1 ]);
    return \&tt_wrap;
}

sub tt_text2html {
    my $text    = shift;
    my $args    = shift;
    text2html($text, %{$args});
}

sub text2html_filter_factory {
    my ($context, $args) = @_;
    return sub {
	my $text = shift;
	tt_text2html($text, $args);
    }
}


1;

__END__


=head1 NAME

Template::Plugin::TextToHtml - Plugin interface to HTML::FromText

=head1 SYNOPSIS

    [% USE TextToHtml %]

    # call text2html subroutine
    [% text2html(mytext, paras=1, url=1, email=1) %]

    # or use text2html FILTER
    [% mytext FILTER text2html(paras=1, url=1, email=1) %]

=head1 DESCRIPTION

This plugin provides an interface to the HTML::FromText module which 
provides simple HTML formatting.

TextToHtml defines a subrouting C<text2html> that, when called,
reformats plain text into HTML.

The options passed to the C<text2html> subroutine correspond to those
passed to the same routine from the HTML::FromText module.

=head1 AUTHOR

Casey West E<lt>casey@geeknest.comE<gt>

=head1 VERSION

0.01

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, L<HTML::FromText|HTML::FromText>

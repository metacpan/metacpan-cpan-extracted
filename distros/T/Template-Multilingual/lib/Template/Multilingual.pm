package Template::Multilingual;

use strict;
use base qw(Template);
use Template::Multilingual::Parser;

our $VERSION = '1.00';

sub _init
{
    my ($self, $options) = @_;

    $self->{LANGUAGE_VAR} = $options->{LANGUAGE_VAR};
    $options->{LANGUAGE_VAR} ||= 'language';
    $options->{PARSER} = Template::Multilingual::Parser->new($options);
    $self->{PARSER} = $options->{PARSER};
    $self->SUPER::_init($options)
}
sub language
{
    my $self = shift;
    @_ ? $self->{language} = shift
       : $self->{language};
}
sub process
{
    my ($self, $filename, $vars, @args) = @_;
    unless ($self->{LANGUAGE_VAR}) {
        $vars ||= {};
        $vars->{language} = $self->{language}
    }
    $self->SUPER::process($filename, $vars, @args);
}

=head1 NAME

Template::Multilingual - Multilingual templates for Template Toolkit

=head1 SYNOPSIS

This subclass of Template Toolkit's C<Template> class supports multilingual
templates: templates that contain text in several languages.

    <t>
      <en>Hello!</en>
      <fr>Bonjour !</fr>
    </t>

Specify the language to use when processing a template:

    use Template::Multilingual;

    my $template = Template::Multilingual->new();
    $template->language('en');
    $template->process('example.ttml');

You can also provide the name of the template variable that will
hold the language:

    my $template = Template::Multilingual->new(LANGUAGE_VAR => 'foo');
    $template->process('example.ttml', { foo => 'en' });

=head1 METHODS

=head2 new(\%params)

The new() constructor creates and returns a reference to a new
template object. A reference to a hash may be supplied as a
parameter to provide configuration values.

Configuration values are all valid C<Template> superclass options,
and one specific to this class:

=over

=item LANGUAGE_VAR

The LANGUAGE_VAR option can be used to set the name of the template
variable which contains the current language.

  my $parser = Template::Multilingual->new({
     LANGUAGE_VAR => 'global.language',
  });

If this option is set, your code is responsible for setting the
variable's value to the current language when processing the
template. Calling C<language()> will have no effect.

If this option is not set, it defaults to I<language>.

=back

=head2 language($lcode)

Specify the language to be used when processing the template. Any string that
matches C<\w+> is fine, but we suggest sticking to ISO-639 which provides
2-letter codes for common languages and 3-letter codes for many others.

=head2 process

Used exactly as the original Template Toolkit C<process> method.
Be sure to call C<language> before calling C<process>.

=head1 LANGUAGE SUBTAG HANDLING

This module supports language subtags to express variants, e.g. "en_US" or "en-US".
Here are the rules used for language matching:

=over

=item *

Exact match: the current language is found in the template

  language    template                              output
  fr          <fr>foo</fr><fr_CA>bar</fr_CA>        foo
  fr_CA       <fr>foo</fr><fr_CA>bar</fr_CA>        bar

=item *

Fallback to the primary language

  language    template                              output
  fr_CA       <fr>foo</fr><fr_BE>bar</fr_BE>        foo

=item *

Fallback to first (in alphabetical order) other variant of the primary language

  language    template                              output
  fr          <fr_FR>foo</fr_FR><fr_BE>bar</fr_BE>  bar
  fr_CA       <fr_FR>foo</fr_FR><fr_BE>bar</fr_BE>  bar

=back

=head1 AUTHOR

Eric Cholet, C<< <cholet@logilune.com> >>

=head1 BUGS

Multilingual text sections cannot be used inside TT directives.
The following is illegal and will trigger a TT syntax error:

    [% title = "<t><fr>Bonjour</fr><en>Hello</en></t>" %]

Use this instead:

    [% title = BLOCK %]<t><fr>Bonjour</fr><en>Hello</en></t>[% END %]


The TAG_STYLE, START_TAG and END_TAG directives are supported, but the
TAGS directive is not.

Please report any bugs or feature requests to
C<bug-template-multilingual@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Multilingual>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

If you are already using your own C<Template> subclass, you may find it
easier to use L<Template::Multilingual::Parser> instead.

ISO 639-2 Codes for the Representation of Names of Languages:
http://www.loc.gov/standards/iso639-2/langcodes.html

=head1 COPYRIGHT & LICENSE

Copyright 2009 Eric Cholet, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Template::Multilingual

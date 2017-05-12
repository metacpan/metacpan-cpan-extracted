package Template::Plugin::StripScripts;

use strict;
use HTML::StripScripts::Parser;

use base qw (Template::Plugin::Filter);

our $VERSION = 0.02;

sub init {
    my $self = shift;
    $self->{_DYNAMIC} = 1;
    $self->install_filter($self->{_ARGS}->[0] || 'stripscripts');
    $self;
}

sub filter {
    my ($self, $text, $args, $config) = @_;
    my $parser_options = delete $config->{ParserOptions};
    my $hss = HTML::StripScripts::Parser->new(
        $config,
        ref $parser_options eq 'HASH' ? %$parser_options : undef,
    );
    return $hss->filter_html($text);
}

1;

__END__

=head1 NAME

Template::Plugin::StripScripts - TT plugin to filter HTML against XSS

=head1 SYNOPSIS

  [% USE StripScripts %]
  [% FILTER stripscripts Context             => 'Document',
                         BanList             => ['br' 'img'],
                         BanAllBut           => ['p' 'div' 'span'],
                         AllowSrc            => 1,
                         AllowHref           => 1,
                         AllowRelURL         => 0,
                         AllowMailto         => 0,
                         EscapeFiltered      => 0,
                         Rules               => { See the POD of HTML::StripScripts },
                         ParserOptions       => {
                             strict_names    => 1,
                             strict_comments => 1,
                         },
  %]

     ... HTML which can cause XSS ...

  [% END %]

  or

  [% myhtml | stripscripts options_like_above %]

=head1 DESCRIPTION

Template::Plugin::StripScripts is a Template::Toolkit plugin to filter
HTML and strip scripting snipets which can cause XSS. Additionally,
due to some nice features from L<HTML::StripScripts>, this module can
work really flexibly on treating HTML.

For more details about filter options, consult the documentaion of
L<HTML::StripScripts>.

=head1 SEE ALSO

=over 4

=item * L<Template>

=item * L<HTML::StripScripts>, L<HTML::StripScripts::Parser>

=item * L<HTML::Parser>

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) 2007 - 2008, Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

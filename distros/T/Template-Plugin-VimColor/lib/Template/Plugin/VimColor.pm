#$Id:$
package Template::Plugin::VimColor;
use strict;
use warnings;

use base qw (Template::Plugin::Filter);
use Text::VimColor;

our $VERSION = 0.01;

sub init {
    my $self = shift;
    $self->{_DYNAMIC} = 1;
    $self->install_filter($self->{_ARGS}->[0] || 'vimcolor');
    $self;
}

sub filter {
    my ($self, $text, $args, $config) = @_;
    my $filetype = delete $config->{filetype} || 'perl';
    my $syntax = Text::VimColor->new(
        string   => \$text,
        filetype => $filetype,
        %$config,
    );

    my $output = $syntax->html;
    $output = _numbered(\$output) if $config->{set_number};
    return $output;
}

sub _numbered {
    my $textref = shift;
    my $ret = '';
    my $cur_line = 0;
    $ret .= sprintf qq{<span class="synLinenum">%5d</span> %s\n}, ++$cur_line, $_
        for split /(?:\r\n|\r|\n)/, $$textref;
    $ret;
}

1;
__END__

=head1 NAME

Template::Plugin::VimColor - TT plugin for Text::VimColor

=head1 SYNOPSIS

  // in your template
  [% USE VimColor %]
  <pre>
  [% FILTER vimcolor set_number => 1 -%]
  #!/usr/local/bin/perl
  use strict;
  use warnings;

  print "Hello, World!\n";
  [% END -%]
  </pre>

  // for another language
  <pre>
  [% FILTER vimcolor filetype => 'ruby' -%]
  #!/usr/local/bin/ruby

  puts "Hello, World";
  [% END -%]
  </pre>

=head1 DESCRIPTION

This plugin allows you to mark up your code in your document with VimColor style. 

You probably need to define styles for marked strings like this,

  <style type="text/css">
  pre { color: #fff; background-color: #000; padding: 10px; }
  span.synComment { color: blue; }
  span.synConstant { color: red; }
  span.synIdentifier { color: aqua; }
  span.synStatement { color: yellow; }
  span.synPreProc { color: fuchsia; }
  span.synType { color: lime; }
  span.synSpecial { color: fuchsia;  }
  span.synUnderlined { color: fuchsia; text-decoration: underline; }
  span.synError { background-color: red; color: white; font-weight: bold; }
  span.synTodo { background-color: yellow; color: black; }
  span.Linenum { color: yellow; }
  </style>

=head1 SEE ALSO

L<Template>, L<Text::VimColor>

=head1 TODO

Caching the marked output with Cache::Cache like Apache::VimColor. Patches welcome :)

=head1 AUTHOR

Naoya Ito E<lt>naoya@bloghackers.netE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

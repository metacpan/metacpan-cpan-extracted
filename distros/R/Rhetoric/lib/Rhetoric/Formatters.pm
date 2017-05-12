package Rhetoric::Formatters;
use common::sense;
use aliased 'Squatting::H';
use Try::Tiny;
use Memoize;
use Ouch;
use Method::Signatures::Simple;

#memoize('_load');
sub _load {
  my $module    = shift;
  my $formatter = shift;
  my $path      = $module;
  $path =~ s{::}{/}g;
  $path .= ".pm";
  my $module_loaded = 0;
  try {
    require($path);
    $module_loaded = 1;
  } catch {
    ouch('RequireFailed', "Could not load $module: $_");
  };
  return $formatter->() if $module_loaded;
}

our $F = H->new({
  raw => method($t) {
    $t
  },

  pod => method($t) {
    my $pod = _load('Pod::Simple::HTML', sub {
      my $pod = Pod::Simple::HTML->new;
      $pod->index(0);
      return $pod;
    });
    my $out;
    $pod->output_string(\$out);
    $pod->parse_string_document("=pod\n\n$t\n\n=cut\n");
    $out =~ s/^.*<!-- start doc -->//s;
    $out =~ s/<!-- end doc -->.*$//s;
    #$out =~ s/^(.*%3A%3A.*)$/my $x = $1; ($x =~ m{indexItem}) ? 1 : $x =~ s{%3A%3A}{\/}g; $x/gme;
    return $out;
  },

  textile => method($t) {
    my $tt = _load('Text::Textile', sub {
      return Text::Textile->new(
        disable_html => 1
      );
    });
    return $tt->process($t);
  },

  markdown => method($t) {
    my $md = _load('Text::Markdown', sub {
      # TODO - figure out what options we want to set for markdown
      return Text::Markdown->new();
    });
    return $md->markdown($t);
  },
});

1;

__END__

=head1 NAME

Rhetoric::Formatters - various text formatting functions

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXPORTS

=head2 %f

=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: nil ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: nil ***
# End: ***
# vim:tabstop=2 softtabstop=2 shiftwidth=2 shiftround expandtab

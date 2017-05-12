package Templates::MenuTmpl;
use Su::Template;

my $model = {};

sub process {
  if ( $_[0] eq __PACKAGE__ ) {
    shift;
  }

  my $ctx_hash_ref = shift;

  #$Su::Template::DEBUG=1;
  my $ret = expand( <<'__TMPL__', $model );
% my $href = shift;
field and values.
% for   my $key (sort keys %{$href}) {
  <%= $key%>:<%= $href->{$key}->{type}%>
% }

__TMPL__

  #$Su::Template::DEBUG=0;
  return $ret;
} ## end sub process

sub model {
  if ( $_[0] eq __PACKAGE__ ) {
    shift;
  }
  my $arg = shift;
  if ($arg) {
    $model = $arg;
  } else {
    return $model;
  }
} ## end sub model

1;


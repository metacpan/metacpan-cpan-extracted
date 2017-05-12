use strict;
use warnings;
use t::scan::Util;

test(<<'TEST'); # DAMI/Alien-GvaScript-1.44/GvaScript_Builder.pm
sub generate_js { # concatenates sources below into "GvaScript.js"
  my ($self) = @_;
  require "lib/Alien/GvaScript.pm";

  my @sources = qw/protoExtensions event keyMap
                   treeNavigator choiceList autoCompleter
                   customButtons paginator grid
                   repeat form/;
  my $dest = "lib/Alien/GvaScript/lib/GvaScript.js";
  chmod 0777, $dest;
  open my $dest_fh, ">$dest"  or die "open >$dest : $!";

  print $dest_fh <<__EOJS__;
/*-------------------------------------------------------------------------*
 * GvaScript - Javascript framework born in Geneva.
 *
 *  Authors: Laurent Dami            <laurent.d...\@etat.ge.ch>
 *           Mona Remlawi
 *           Jean-Christophe Durand
 *           Sebastien Cuendet

 *  LICENSE
 *  This library is free software, you can redistribute it and/or modify
 *  it under the same terms as Perl's artistic license.
 *
 *--------------------------------------------------------------------------*/

var GvaScript = {
  Version: '$Alien::GvaScript::VERSION',
  REQUIRED_PROTOTYPE: '1.7',
  load: function() {
    function convertVersionString(versionString) {
      var v = versionString.replace(/_.*|\\./g, '');
      v = parseInt(v + '0'.times(4-v.length));
      return versionString.indexOf('_') > -1 ? v-1 : v;
    }
    if((typeof Prototype=='undefined') ||
       (typeof Element == 'undefined') ||
       (typeof Element.Methods=='undefined') ||
       (convertVersionString(Prototype.Version) <
        convertVersionString(GvaScript.REQUIRED_PROTOTYPE)))
       throw("GvaScript requires the Prototype JavaScript framework >= " +
        GvaScript.REQUIRED_PROTOTYPE);
  }
};

GvaScript.load();
__EOJS__

  foreach my $sourcefile (@sources) {
    open my $fh, "src/$sourcefile.js" or die $!;
    print $dest_fh "\n//----------$sourcefile.js\n", <$fh>;
  }
}

sub generate_html {# regenerate html doc from pod sources
  my ($self) = @_;

  require Pod::POM;
  require Pod::POM::View::HTML;

  my @podfiles = glob ("lib/Alien/GvaScript/*.pod");
  my $parser = new Pod::POM;

  foreach my $podfile (@podfiles) {
    my $pom = $parser->parse($podfile) or die $parser->error;
    $podfile =~ m[^lib/Alien/GvaScript/(.*)\.pod];
    my $htmlfile = "doc/html/$1.html";
    print STDERR "converting $podfile ==> $htmlfile\n";
    open my $fh, ">$htmlfile" or die "open >$htmlfile: $!";
    print $fh Pod::POM::View::HTML::GvaScript->print($pom);
    close $fh;
  }
  return 1;
}

sub generate_googlewiki {# regenerate wiki doc from pod sources
  my ($self) = @_;

  require Pod::Simple::Wiki;
  require Pod::Simple::Wiki::Googlecode;

  # destination for wiki files
  my $dir = "blib/wiki";
  -d $dir or mkdir $dir or die "mkdir $dir: $!";

  # list of source files
  my @podfiles = glob ("lib/Alien/GvaScript/*.pod");

  # convert each file
  foreach my $podfile (@podfiles) {

    my $parser = Pod::Simple::Wiki->new('googlecode');
    $podfile =~ m[^lib/Alien/GvaScript/(.*)\.pod];
    my $wikifile = "$dir/$1.wiki";
    open my $fh, ">$wikifile" or die "open >$wikifile: $!";
    print STDERR "converting $podfile ==> $wikifile\n";

    $parser->output_fh($fh);
    $parser->parse_file($podfile);
  }

  return 1;
}



1;


#======================================================================
package Pod::POM::View::HTML::GvaScript;
#======================================================================
use strict;
use warnings;

use base 'Pod::POM::View::HTML';

sub _title_to_id {
  my $title = shift;
  $title =~ s/<.*?>//g; # no tags
  $title =~ s/\W+/_/g;
  return $title;
}


sub view_pod {
  my ($self, $pod) = @_;

  my $doc_title = ($pod->head1)[0]->content->present($self);
  $doc_title =~ s/<.*?>//g; # no tags
  my ($name, $description) = split /\s+-\s+/, $doc_title;

  my $content = $pod->content->present($self);
  my $toc = $self->make_toc($pod, 0);

  return <<__EOHTML__
<html>
<head>
  <script src="../../lib/Alien/GvaScript/lib/prototype.js"></script>
  <script src="../../lib/Alien/GvaScript/lib/GvaScript.js"></script>
  <link href="GvaScript_doc.css" rel="stylesheet" type="text/css">
  <script>
    document.observe('dom:loaded', function() { new GvaScript.TreeNavigator('TN_tree'); });
    function jumpto_href(event) {
      var label = event.controller.label(event.target);
      if (label && label.tagName == "A") {
        label.focus();
        return Event.stopNone;
      }
    }
  </script>
</head>
<body>
<div id='TN_tree'>
  <div class="TN_node">
   <h1 class="TN_label">$name</h1>
   <div class="TN_content">
     <p><em>$description</em></p>
     <div class="TN_node"  onPing="jumpto_href">
       <h3 class="TN_label">Table of contents</h3>
       <div class="TN_content">
         $toc
       </div>
     </div>
     <hr/>
   </div>
  </div>
$content
</div>
</body>
</html>
__EOHTML__

}

# installing same method for view_head1, view_head2, etc.
BEGIN {
  for my $num (1..6) {
    no strict 'refs';
    *{"view_head$num"} = sub {
      my ($self, $item) = @_;
      my $title   = $item->title->present($self);
      my $id      = _title_to_id($title);
      my $content = $item->content->present($self);
      my $h_num   = $num + 1;
      return <<__EOHTML__
  <div class="TN_node" id="$id">
    <h$h_num class="TN_label">$title</h$h_num>
    <div class="TN_content">
      $content
    </div>
  </div>
__EOHTML__
    }
  }
}


sub make_toc_orig {
  my ($self, $item, $level) = @_;

  my @nodes;
  my $method = "head" . ($level + 1);
  my $sub_items = $item->$method;

  foreach my $sub_item (@$sub_items) {
    my $title    = $sub_item->title->present($self);
    my $id       = _title_to_id($title);

    my $node_html = qq{<a toc_node="$id">$title</a>}
                  . $self->make_toc($sub_item, $level + 1);
    push @nodes, $node_html;
  }
  my $html = join "", map {"<li>$_</li>"}  @nodes;
  return $html ? "<ul>$html</ul>" : "";
}

sub make_toc {
  my ($self, $item, $level) = @_;

  my @nodes;
  my $method = "head" . ($level + 1);
  my $sub_items = $item->$method;

  foreach my $sub_item (@$sub_items) {
    my $title    = $sub_item->title->present($self);
    my $id       = _title_to_id($title);

    my $node_content = $self->make_toc($sub_item, $level + 1);
    my $class = $node_content ? "TN_node" : "TN_leaf";
    my $node_html = <<__EOHTML__;
<div class="$class">
  <a class="TN_label" href="#$id">$title</a>
  <div class="TN_content">$node_content</div>
</div>
__EOHTML__

    push @nodes, $node_html;
  }
  my $html = join "", @nodes;
  return $html;
}

1;
TEST

done_testing;

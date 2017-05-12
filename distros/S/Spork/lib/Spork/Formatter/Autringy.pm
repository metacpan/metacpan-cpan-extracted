package Spork::Formatter::Autringy;
use Spork::Formatter -Base;

sub formatter_classes {
    map { 
        s/^Ulist$/Spork::Formatter::Autringy::Ulist/; 
        s/^Item$/Spork::Formatter::Autringy::Item/; 
        $_;
    } super;
}  

################################################################################
package Spork::Formatter::Autringy::Ulist;
use base 'Kwiki::Formatter::Ulist';

const bullet => '[\*\-]+\ +';

################################################################################
package Spork::Formatter::Autringy::Item;
use base 'Kwiki::Formatter::Item';
const formatter_id => 'li';
const bullet => '[\*\-]+\ +';
field which => '';

sub html_start {
    return super unless $self->hub->config->flipflop;
    $self->which =~ /-/
    ? '<div style="background-color:lightblue"><li>'
    : '<div style="background-color:lightpink"><li>';
}

sub html_end {
    $self->hub->config->flipflop
    ? "</li></div>\n"
    : super;
}

sub match {
    my $bullet = $self->bullet;
    $self->which($1)
      if $self->text =~ /^($bullet)(.*)\n/m;
    return unless
      $self->text =~ /^$bullet(.*)\n/m;
    $self->set_match;
    return 1;
}

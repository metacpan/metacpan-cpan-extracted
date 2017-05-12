#===============================================================================
#
#  DESCRIPTION:  Utl visiter for setup nodes positions
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
package Plosurin::Utl::SetLinePos;
use strict;
use warnings;
use Plosurin::AbstractVisiter;
use base 'Plosurin::AbstractVisiter';
use Data::Dumper;
use vars qw($AUTOLOAD);


sub  Node {
    my $self = shift;
    my $n = shift;
    my $line = $n->{matchline} + ( $self->{offset} || 0 );
    my $src_file = $self->{srcfile};
    foreach my $c (@{ $n->childs }) {
        $c->{matchline} = $line;
        $c->{srcfile} = $src_file;
    }
    $self->visit_childs($n);
}

sub __default_method {
    my $self =shift;
    my $n = shift;

}
1;


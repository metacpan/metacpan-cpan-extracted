use strict;
package WWW::Scraper::Response::ScraperDiscovery;


=head1 NAME

WWW::Scraper::Response::ScraperDiscovery - 


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

C<WWW::Scraper::Response::ScraperDiscovery> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=cut

use vars qw($VERSION @ISA $CHECKED);
@ISA = qw(WWW::Scraper::Response);
use WWW::Scraper::Response;
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);
my $CHECKED = 0;
my $MODE = ''; sub SetMODE { $MODE = $_[0] }
my $Iterator = '0'; sub GetIterator { $Iterator }

sub asHtml {
    my ($self) = shift;

    if ( $MODE eq 'ScraperFrame' ) {
        return $self->asHTML_ScraperFrame(@_);
    } else {
        return $self->asHTML_RequestFrame(@_);
    }
}
    
sub asHTML_ScraperFrame {
    my ($self) = shift;
    my $typeLeaf = $self->typeLeaf;
    
    my $attrList = '';
    my %results = %{$self->GetFieldValues()};
    for ( qw(id onmouseover onmouseout onclick onMouseOver onMouseOut) ) { delete $results{$_}; } # We are usurping these attributes.
    my $val; 
    for ( keys %{$self->GetFieldTitles()} ) { 
        next if $_ eq 'content';
        next if $_ eq 'content';
        $val = $self->$_;
        next unless $val;
        $val = $$val;
        # Let's escape quotes or apostrophes the cheapest way possible.
        if ( $val !~ m{"} ) {
            $val = "\"$val\"";
        } elsif ( $val !~ m{'} ) {
            $val = "\'$val\'" unless $val =~ m{'};
        } else {
            $val =~ s{'}{%27}g;
            $val = "'$val'";
        }
        $attrList .= " $_=$val" if $val && $val ne '' 
    }

    $attrList .= ' style=""' unless $attrList =~ m{style=}; # Make sure each element has a style, for Javascript.
    $typeLeaf = 'DIV' if $typeLeaf eq 'BR';
    my ($content) = ($typeLeaf =~ m{^TD|BR|A$} ? ${$self->content}:'');
    map { $content .= $_->asHtml } @{$self->SubHitList} if $self->SubHitList;
    
    $Iterator += 1;
    my $mouseEvents = ($typeLeaf =~ m{BODY})?'':" onmouseover='hilite(event)' onmouseout='lolite(event)'";
    return <<EOT;
<$typeLeaf$attrList ID='$Iterator'$mouseEvents'>$content</$typeLeaf>
EOT
}


sub asHtml_RequestFrame {
    my ($self) = shift;
    my $typeLeaf = $self->typeLeaf;
    
    my $attrList = '';
    my %results = %{$self->GetFieldValues()};
    my $val; 
    for ( keys %{$self->GetFieldTitles()} ) { 
        next if $_ eq 'caption';
        $val = $self->$_;
        next unless defined $val;
        $val = $$val;
        # Let's escape quotes or apostrophes the cheapest way possible.
        if ( $val !~ m{"} ) {
            $val = "\"$val\"";
        } elsif ( $val !~ m{'} ) {
            $val = "\'$val\'" unless $val =~ m{'};
        } else {
            $val =~ s{'}{%27}g;
            $val = "'$val'";
        }
        $attrList .= " $_=$val" if $val && $val ne '' 
    }

    my $content = ''; my $checked = ''; my $theCheckBox = '&nbsp;';
    my $name = ref($self->name)?${$self->name}:'';
    if ( $typeLeaf eq 'INPUT' ) {
        if ( $attrList =~ m{type="(radio|checkbox)"} ) {
            $content = $self->caption;
        } elsif ( $attrList =~ m{type="hidden"} ) {
            #$attrList =~ s{type="hidden"}{type='text' cols='10' readonly}i;
            #$attrList =~ s{value=\S*}{value='       (hidden field)'}i unless 
            #    $attrList =~ s{value='[^']*'}{value='       (hidden field)'}i ||
            #    $attrList =~ s{value="[^"]*"}{value="       (hidden field)"}i;
            $content = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(hidden field)';
        } elsif ( $attrList =~ m{type=("text"|"")} ) {
            unless ( $WWW::Scraper::Response::ScraperDiscovery::CHECKED ) {
                $WWW::Scraper::Response::ScraperDiscovery::CHECKED = $self;
                $checked = ' checked';
            }
            $theCheckBox = "<input name='scraperDiscoveryQueryField' value='$name' type='radio'$checked>";
        }
    }
    else {
       map { $content .= $_->asHtml } @{$self->SubHitList} if $self->SubHitList;
    }
    
    return <<EOT;
<tr>
<td align='left'><input name='scraperDiscoveryNameOf_$name' value='$name' type='text' cols='15'></td>
<td width='10px'>$theCheckBox</td>
<td><$typeLeaf$attrList>$content</$typeLeaf></td>
</tr>
EOT
}

sub GenerateScraperRequest {} # Many Opcodes will have no impact on the scraperRequest.
1;


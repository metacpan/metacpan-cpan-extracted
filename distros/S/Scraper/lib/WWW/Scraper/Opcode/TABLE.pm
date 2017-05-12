
use strict;

package WWW::Scraper::Opcode::TABLE;
use base qw(WWW::Scraper::Opcode);
use vars qw($VERSION);

# new() Scraper::Opcode
#  $cls - Op class
#  $scaffold - current scaffold
#  $params - ref to array of parames in the 'OP()' portion of the scaffold.
sub new {
    my ($cls, $scaffold, $params) = @_;
    my $self = bless {};
    $self->{'fieldsDiscovered'} = ['name','content'];
    return $self;
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    my $next_scaffold;

    my ($sub_string, $attributes) = $TidyXML->getMarkedTextAndAttributes('TABLE');
    return undef unless defined($sub_string);

    my $elmName = $$scaffold[1];
    $elmName = '#0' unless $elmName;
    if ( 'ARRAY' eq ref $$scaffold[1] )
    {
        $next_scaffold = $$scaffold[1];
    }
    elsif ( $elmName =~ /^#(\d*)$/ )
    {
        for (1..$1)
        {
            $TidyXML->getMarkedText('TABLE'); # and throw it away.
        }
        $next_scaffold = $$scaffold[2];
    }
    else {
        print STDERR  "elmName: $elmName\n" if ($self->ScraperTrace('d'));
        $next_scaffold = $$scaffold[2];
        die "Element-name form of 'TABLE' is not implemented, yet.";
    }
    $next_scaffold = undef unless $sub_string = $TidyXML->getMarkedText('TABLE');
    return ($next_scaffold, $sub_string, $attributes);
}


1;

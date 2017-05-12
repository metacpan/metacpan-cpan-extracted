
use strict;

package WWW::Scraper::Opcode::REGEX;
use base qw(WWW::Scraper::Opcode);
use vars qw($VERSION);

# new() Scraper::Opcode
#  $cls - Op class
#  $scaffold - current scaffold
#  $params - ref to array of params in the 'OP()' portion of the scaffold.
sub new {
    my ($cls, $scaffold, $params) = @_;
    my $self = bless {};
    my @scfld = @$scaffold;
    shift @scfld;
    my $regex = shift @scfld;
    my @fields;
    map { push @fields, $_ unless !$_ || ref($_) || m{^#} } @scfld;

    $self->{'fieldsCaptured'} = \@fields;
    $self->{'fieldsDiscovered'} = \@fields;
    return $self;
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my (@ary,@dts,$hit_found) = (@$scaffold,undef,0);

    shift @ary;
    my $regex = shift @ary;
    if ( ${$TidyXML->asString()} =~ s/$regex//si )
    {
        @dts = ($1,$2,$3,$4,$5,$6,$7,$8,$9);
        for ( @ary ) 
        {
            if ( ! defined $_ ) { # "if ( $_ eq '' )" reports "use of uninitialized variable" under diagnostics.
                shift @dts;
            }
            elsif ( ref($_) eq 'CODE' ) {
                $dts[0] = &$_($scraper,$hit,$dts[0]);
            }
            elsif ( $_ eq 'url' )
            {
                my $url = new URI::URL(shift @dts, $scraper->{_base_url});
                $url = $url->abs();
                print "REGEX binding 'url' => $url\n" if ($scraper->ScraperTrace('d'));
                $hit->plug_url($url);
            } 
            elsif ( $_ ) {
                my $dt = $scraper->trimTags($hit, shift @dts);
                print "REGEX binding '$_' => $dt\n" if ($scraper->ScraperTrace('d'));
                $hit->plug_elem($_, $dt, $TidyXML) if defined $dt;
            }
        }
        $hit_found = 1;
    }
    return undef;
}


1;

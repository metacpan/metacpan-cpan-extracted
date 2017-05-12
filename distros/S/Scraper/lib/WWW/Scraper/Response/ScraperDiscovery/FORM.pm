use strict;
package WWW::Scraper::Response::ScraperDiscovery::FORM;

#####################################################################

# This is an appropriate VERSION calculation to use for CVS revision numbering.
use vars qw($VERSION);
use base qw(WWW::Scraper::Response::ScraperDiscovery);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+).(\d+)/);

sub asHtml {
    my ($self, $baseUrl, $newModuleName) = @_;
    
    my $attrList = '';
    my %results = %{$self->GetFieldValues()};
    my $val; 
    for ( keys %{$self->GetFieldTitles()} ) { 
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

    my $content = '';
    map { $content .= $_->asHtml } @{$self->SubHitList} if $self->SubHitList;
    my $name = ${$self->name};
    my $answer = <<EOT;
<form method='POST' name='formFor_$name' action='javascript:SubmitForm(document.formFor_$name)'>
<input type='hidden' name='scraperDiscoveryTargetForm' value='targetForm_$name'>
<input type='hidden' name='scraperDiscoveryOp' value='ScraperFrame'>
<input type='hidden' name='scraperDiscoveryModuleName' value='$newModuleName'>
$content
</form>
EOT
    my $method = ${$self->method};
    my $action = absolute(${$self->action}, $baseUrl);
    $answer .= <<EOT;
<form name='targetForm_$name' method='$method' target='scraper_$name\_target_window' action='$action'>
</form>
EOT
    return $answer;
}

sub absolute {
    my ($url, $baseUrl) = @_;
    
    $url .= '?' unless $url =~ m{\?$};
    if ( $url =~ m{^/} ) {
        $baseUrl =~ m{(\w+://[^/]*)};
        $url = "$1$url" unless $url =~ m{^https?://}i;
    } elsif ( $url =! m{^https?://}i ) {
        $url = "$baseUrl/$url" ;
    }
    return $url;
}

sub GenerateScraperRequest {
    my ($self, $baseUrl) = @_;

    my $type = ${$self->method};
    $type = 'QUERY' if lc $type eq 'get';
    my $url = absolute(${$self->action}, $baseUrl);
    
    my $scraperRequest = 
        { 
           # This engine's method is QUERY
           'type' => $type
            
           # This is the basic URL on which to get the form to build the query.
           ,'url' => $url

           # specify defaults, by native field names
           ,'nativeQuery' => undef
           ,'nativeDefaults' => {}
            
            # specify translations from canonical fields to native fields
           ,'defaultRequestClass' => undef
           ,'fieldTranslations' =>
                   {
                       '*' =>
                           {
                                '*'         => '*'
                           }
                   }
            # Miscellaneous options for the Scraper operation.
           ,'cookies' => 0
       };

    map { $_->GenerateScraperRequest($scraperRequest) } @{$self->SubHitList} if $self->SubHitList;
    return $scraperRequest;
}
1;

__END__
=pod

=head1 NAME

WWW::Scraper::ScraperDiscovery - discovers forms and inputs on a HTML page.


=head1 SYNOPSIS


=head1 DESCRIPTION

This class is an experimental exploration of "Scraper Discovery".

=head1 AUTHOR and CURRENT VERSION

C<WWW::Scraper::ScraperDiscovery> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2002 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


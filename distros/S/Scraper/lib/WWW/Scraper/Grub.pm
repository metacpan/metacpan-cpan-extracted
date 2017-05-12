use strict;
package WWW::Scraper::Grub;

#####################################################################

use base qw(WWW::Scraper Exporter);
# This is an appropriate VERSION calculation to use for CVS revision numbering.
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+).(\d+)/);

use WWW::Scraper(qw(3.00 generic_option trimLFs trimTags removeScriptsInHTML));

use strict;

my $scraperRequest = 
        { 
            # This engine's method is QUERY
            'type' => 'QUERY'
            
            # This is the basic URL on which to get the form to build the query.
            ,'url' => 'file://C:/TEMP/l-grub/index.html'

           # specify defaults, by native field names
           ,'nativeQuery' => undef
           ,'nativeDefaults' => undef
            
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

my $scraperFrame =
       [ 'HTML',
         [ 
            [ 'HIT*',
              [
                [ 'REGEX', '(l-grub.[^>]*?\.html)', 'url' ],
              ]
            ],
            [ 'BOGUS', 2 ]
         ]
       ];

my $scraperDetail = 
       [ 'HTML',
         [ 
            [ 'REGEX', '<a border="0" onMouseOver="iOver\\(\'topnext\'\\)[^>]*?href="([^"]+)"', 'nextUrl' ],
            [ 'TABLE', '#5', 
              [
                [ 'RESIDUE', 'section' ]
              ]
            ],
            [ 'GRUB', 'nextUrl' ]
         ]
       ];


sub init {
    my ($self, $subclass, $native_query, $native_options) = @_;
    $self->SetScraperRequest($scraperRequest);
    $self->SetScraperFrame($scraperFrame);
    $self->SetScraperDetail($scraperDetail);
    return $self->SUPER::init($subclass, $native_query, $native_options);
}

1;

__END__
=pod

=head1 NAME

WWW::Scraper::Grub - Scrapes www.Sample.com


=head1 SYNOPSIS

    require WWW::Scraper;
    $search = new WWW::Scraper('Grub');

See F<eg/GrabGrub.pl>

=head1 DESCRIPTION

This class is an experimental "grubbing" scraper.

=head1 AUTHOR and CURRENT VERSION

C<WWW::Scraper::Grub> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2002 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


package WWW::Scraper::Response::generic;


=head1 NAME

WWW::Scraper::Response::generic - place holder.

For Response sub-class when no sub-class is declared. Not normally declared by client applications.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

C<WWW::Scraper::Response::generic> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=cut

use strict;
use vars qw($VERSION @ISA);
use lib './lib';
use WWW::Scraper::Response;
@ISA = qw(WWW::Scraper::Response);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

sub new {
    my $self = WWW::Scraper::Response::new(
         $_[3]
        ,{
         }
        ,($_[0],$_[1],$_[2]));
    return $self;
}

1;


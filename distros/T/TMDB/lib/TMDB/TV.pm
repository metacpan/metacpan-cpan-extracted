package TMDB::TV;

#######################
# LOAD CORE MODULES
#######################
use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);

#######################
# LOAD CPAN MODULES
#######################
use Object::Tiny qw(id session);
use Params::Validate qw(validate_with :types);
use Locale::Codes::Country qw(all_country_codes);

#######################
# LOAD DIST MODULES
#######################
use TMDB::Session;

#######################
# VERSION
#######################
our $VERSION = '1.2.1';

#######################
# PUBLIC METHODS
#######################

## ====================
## Constructor
## ====================
sub new {
    my $class = shift;
    my %opts  = validate_with(
        params => \@_,
        spec   => {
            session => {
                type => OBJECT,
                isa  => 'TMDB::Session',
            },
            id => {
                type => SCALAR,
            },
        },
    );

    my $self = $class->SUPER::new(%opts);
  return $self;
} ## end sub new

## ====================
## INFO
## ====================
sub info {
    my $self   = shift;
    my $params = {};
    $params->{language} = $self->session->lang if $self->session->lang;
    my $info = $self->session->talk(
        {
            method => 'tv/' . $self->id,
            params => $params
        }
    );
  return unless $info;
    $self->{id} = $info->{id};  # Reset TMDB ID
  return $info;
} ## end sub info

## ====================
## ALTERNATIVE TITLES
## ====================
sub alternative_titles {
    my $self    = shift;
    my $country = shift;

    # Valid Country codes
    if ($country) {
        my %valid_country_codes
          = map { $_ => 1 } all_country_codes('alpha-2');
        $country = uc $country;
      return unless $valid_country_codes{$country};
    } ## end if ($country)

    my $args = {
        method => 'tv/' . $self->id() . '/alternative_titles',
        params => {},
    };
    $args->{params}->{country} = $country if $country;

    my $response = $self->session->talk($args);
    my $titles = $response->{results} || [];

  return @$titles if wantarray;
  return $titles;
} ## end sub alternative_titles

## ====================
## CAST
## ====================
sub cast {
    my $self     = shift;
    my $response = $self->_credits();
    my $cast     = $response->{cast} || [];
  return @$cast if wantarray;
  return $cast;
} ## end sub cast

## ====================
## CREW
## ====================
sub crew {
    my $self     = shift;
    my $response = $self->_credits();
    my $crew     = $response->{crew} || [];
  return @$crew if wantarray;
  return $crew;
} ## end sub crew

## ====================
## IMAGES
## ====================
sub images {
    my $self   = shift;
    my $params = {};
    $params->{lang} = $self->session->lang if $self->session->lang;
  return $self->session->talk(
        {
            method => 'tv/' . $self->id() . '/images',
            params => $params
        }
    );
} ## end sub images

## ====================
## VIDEOS
## ====================
sub videos {
    my $self = shift;
    my $response
      = $self->session->talk( { method => 'tv/' . $self->id() . '/videos' } );
    my $videos = $response->{results} || [];

  return @$videos if wantarray;
  return $videos;

} ## end sub videos

## ====================
## KEYWORDS
## ====================
sub keywords {
    my $self     = shift;
    my $response = $self->session->talk(
        { method => 'tv/' . $self->id() . '/keywords' } );
    my $keywords_dump = $response->{results} || [];
    my @keywords;
    foreach (@$keywords_dump) { push @keywords, $_->{name}; }
  return @keywords if wantarray;
  return \@keywords;
} ## end sub keywords

## ====================
## TRANSLATIONS
## ====================
sub translations {
    my $self     = shift;
    my $response = $self->session->talk(
        { method => 'tv/' . $self->id() . '/translations' } );
    my $translations = $response->{translations} || [];
  return @$translations if wantarray;
  return $translations;
} ## end sub translations

## ====================
## SIMILAR TV SHOWS
## ====================
sub similar {
    my ( $self, $max_pages ) = @_;
  return $self->session->paginate_results(
        {
            method    => 'tv/' . $self->id() . '/similar',
            max_pages => $max_pages,
            params    => {
                language => $self->session->lang
                ? $self->session->lang
                : undef,
            },
        }
    );
} ## end sub similar

## ====================
## CONTENT RATING
## ====================
sub content_ratings {
    my $self     = shift;
    my $response = $self->session->talk(
        { method => 'tv/' . $self->id() . '/content_ratings' } );
    my $content_ratings = $response->{results} || [];
  return @$content_ratings if wantarray;
  return $content_ratings;
} ## end sub content_ratings

## ====================
## SEASON
## ====================
sub season {
    my $self   = shift;
    my $season = shift;
  return $self->session->talk(
        { method => 'tv/' . $self->id() . '/season/' . $season } );
} ## end sub season

## ====================
## EPISODE
## ====================
sub episode {
    my $self    = shift;
    my $season  = shift;
    my $episode = shift;
  return $self->session->talk(
        {
                method => 'tv/'
              . $self->id()
              . '/season/'
              . $season
              . '/episode/'
              . $episode
        }
    );
} ## end sub episode

## ====================
## CHANGES
## ====================
sub changes {
    my ( $self, @args ) = @_;
    my %options = validate_with(
        params => [@args],
        spec   => {
            start_date => {
                type     => SCALAR,
                optional => 1,
                regex    => qr/^\d{4}\-\d{2}\-\d{2}$/
            },
            end_date => {
                type     => SCALAR,
                optional => 1,
                regex    => qr/^\d{4}\-\d{2}\-\d{2}$/
            },
        },
    );

    my $changes = $self->session->talk(
        {
            method => 'tv/' . $self->id() . '/changes',
            params => {
                (
                    $options{start_date}
                    ? ( start_date => $options{start_date} )
                    : ()
                ), (
                    $options{end_date} ? ( end_date => $options{end_date} )
                    : ()
                ),
            },
        }
    );

  return unless defined $changes;
  return unless exists $changes->{changes};
  return @{ $changes->{changes} } if wantarray;
  return $changes->{changes};
} ## end sub changes

## ====================
## VERSION
## ====================
sub version {
    my ($self) = @_;
    my $response = $self->session->talk(
        {
            method       => 'tv/' . $self->id(),
            want_headers => 1,
        }
    ) or return;
    my $version = $response->{etag} || q();
    $version =~ s{"}{}gx;
  return $version;
} ## end sub version

#######################
# PRIVATE METHODS
#######################

## ====================
## CREDITS
## ====================
sub _credits {
    my $self = shift;
  return $self->session->talk(
        {
            method => 'tv/' . $self->id() . '/credits',
        }
    );
} ## end sub _credits

#######################
1;

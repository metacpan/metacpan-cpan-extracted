package Moo::Google::Discovery;
$Moo::Google::Discovery::VERSION = '0.03';

# ABSTRACT: Methods for working with Google API discovery service


use Moo;
use Mojo::UserAgent;
use List::Util qw(uniq);
use Hash::Slice qw/slice/;

use Data::Dumper;

has 'ua' => ( is => 'ro', default => sub { Mojo::UserAgent->new }, lazy => 1 );
has 'discovery_full' => ( is => 'ro', default => \&discover_all, lazy => 1 );
has 'debug' => ( is => 'rw', default => 0, lazy => 1 );


sub getRest {
    my ( $self, $params ) = @_;
    return $self->ua->get( 'https://www.googleapis.com/discovery/v1/apis/'
          . $params->{api} . '/'
          . $params->{version}
          . '/rest' )->result->json;
}


sub discover_all {
    shift->ua->get('https://www.googleapis.com/discovery/v1/apis')
      ->result->json;
}


sub availableAPIs {
    my $self = shift;
    my $all  = $self->discover_all()->{items};
    for my $i (@$all) {
        $i = {
            map { $_ => $i->{$_} }
            grep { exists $i->{$_} } qw/name version documentationLink/
        };
    }
    my @subset = uniq map { $_->{name} } @$all;    ## unique names
                                                   # warn scalar @$all;
                                                   # warn scalar @subset;
                                                   # warn Dumper \@subset;
          # my @a = map { $_->{name} } @$all;

    my @arr;
    for my $s (@subset) {
        my @v = map { $_->{version} } grep { $_->{name} eq $s } @$all;
        my @doclinks =
          uniq map { $_->{documentationLink} } grep { $_->{name} eq $s } @$all;

        # warn "Match! :".Dumper \@v;
        # my $versions = grep
        push @arr, { name => $s, versions => \@v, doclinks => \@doclinks };
    }

    return \@arr;

    # warn Dumper \@arr;

    # return \@a;
}


sub exists {
    my ( $self, $api ) = @_;
    my $apis_all = $self->availableAPIs();
    my $res = grep { $_->{name} eq $api } @$apis_all;
}


sub printSupported {
    my $self     = shift;
    my $apis_all = $self->availableAPIs();
    for my $api (@$apis_all) {
        print $api->{name} . ' : '
          . join( ',', @{ $api->{versions} } ) . ' : '
          . join( ',', @{ $api->{doclinks} } ) . "\n";
    }
}


sub availableVersions {
    my ( $self, $api ) = @_;
    my $apis_all = $self->availableAPIs();
    my @api_target = grep { $_->{name} eq $api } @$apis_all;
    return $api_target[0]->{versions};
}


sub latestStableVersion {
    my ( $self, $api ) = @_;
    my $versions = $self->availableVersions($api);    # arrayref
    if ( $versions->[-1] =~ /beta/ ) {
        return $versions->[0];
    }
    else {
        return $versions->[-1];
    }
}


sub findAPIsWithDiffVers {
    my $self = shift;
    my $all  = $self->availableAPIs();
    grep { scalar @{ $_->{versions} } > 1 } @$all;
}


sub searchInServices {
    my ( $self, $string ) = @_;

    # warn Dumper $self->availableAPIs();
    my @res = grep { $_->{name} eq lc $string } @{ $self->availableAPIs };

    # warn "Result: ".Dumper \@res;
    return $res[0];
}


sub getMethodMeta {
    my ( $self, $caller ) = @_;

    # $caller = 'Moo::Google::Calendar::CalendarList::delete';
    my @a = split( /::/, $caller );

    # warn Dumper \@a;
    my $method   = pop @a;            # delete
    my $resource = lcfirst pop @a;    # CalendarList
    my $service  = lc pop @a;         # Calendar
    my $service_data =
      $self->searchInServices($service);    # was string, become hash
    warn "getResourcesMeta:service_data : " . Dumper $service_data
      if ( $self->debug );

    my $all = $self->getRest(
        {
            api     => $service_data->{name},
            version => $service_data->{versions}[0]
        }
    );
    my $baseUrl = $all->{baseUrl};
    my $resource_data =
      $all->{resources}{$resource};         # return just a list of all methods
    my $method_data = $resource_data->{methods}{$method};    # need httpMethod
    $method_data->{path} = $baseUrl . $method_data->{path};
    my $res = slice $method_data, qw/httpMethod path id/;
}


sub getResourceMeta {
    my ( $self, $package ) = @_;

    # $package = 'Moo::Google::Calendar::Events';
    my @a        = split( /::/, $package );
    my $resource = lcfirst pop @a;            # CalendarList
    my $service  = lc pop @a;                 # Calendar
    my $service_data =
      $self->searchInServices($service);      # was string, become hash
    my $all = $self->getRest(
        {
            api     => $service_data->{name},
            version => $service_data->{versions}[0]
        }
    );
    return $all->{resources}{$resource};    # return just a list of all methods
}


sub listOfMethods {
    my ( $self, $package ) = @_;
    my $r = $self->getResourceMeta($package);
    my @a = keys %{ $r->{methods} };
    return \@a;
}


sub metaForAPI {
    my ( $self, $params ) = @_;
    my $full = $self->discovery_full;
    my @a;

    if ( defined $params->{api} ) {
        @a = grep { $_->{name} eq $params->{api} } @{ $full->{items} };
    }
    else {
        die "metaForAPI() : No api specified!";
    }

    if ( defined $params->{version} ) {
        @a = grep { $_->{version} eq $params->{version} } @a;
    }

    return $a[0];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moo::Google::Discovery - Methods for working with Google API discovery service

=head1 VERSION

version 0.03

=head1 METHODS

=head2 getRest

Retrieve the description of a particular version of an API

  my $d = Moo::Google::Discovery->new;
  $d->getRest({ api=> 'calendar', version => 'v3' });

Return result like

  $VAR1 = {
          'ownerDomain' => 'google.com',
          'version' => 'v2.4',
          'protocol' => 'rest',
          'icons' => 'HASH(0x29760c0)',
          'discoveryVersion' => 'v1',
          'id' => 'analytics:v2.4',
          'parameters' => 'HASH(0x29709c0)',
          'basePath' => '/analytics/v2.4/',
          'revision' => '20170321',
          'description' => 'Views and manages your Google Analytics data.',
          'servicePath' => 'analytics/v2.4/',
          'title' => 'Google Analytics API',
          'kind' => 'discovery#restDescription',
          'rootUrl' => 'https://www.googleapis.com/',
          'etag' => '"YWOzh2SDasdU84ArJnpYek-OMdg/uF7o_i10s0Ir7WGM7zLi8NwSHXI"',
          'ownerName' => 'Google',
          'auth' => 'HASH(0x2948880)',
          'resources' => 'HASH(0x296b218)',
          'batchPath' => 'batch',
          'name' => 'analytics',
          'documentationLink' => 'https://developers.google.com/analytics/',
          'baseUrl' => 'https://www.googleapis.com/analytics/v2.4/'
        };

=head2 discover_all

  Return details about all APIs

=head2 getRest

Return arrayref of all available API's (services)

    {
      'name' => 'youtube',
      'versions' => [ 'v3' ]
    },

Useful when printing list of supported API's in documentation

=head2 exists

Return 1 if service is supported by Google API discovery. Otherwise return 0

  warn $d->exists('calendar');  # 1
  warn $d->exists('someapi');  # 0

=head2 printSupported

  Print list of supported APIs in human-readible format (used in description of Google.pm)

=head2 availableVersions

  Show available versions of particular API

  $d->availableVersions('calendar');  # ['v3']
  $d->availableVersions('youtubeAnalytics');  # ['v1','v1beta1']

  Returns arrayref

=head2 return latest stable verion of API

  $d->availableVersions('calendar');  # ['v3']
  $d->latestStableVersion('calendar');  # 'v3'

  $d->availableVersions('tagmanager');  # ['v1','v2']
  $d->latestStableVersion('tagmanager');  # ['v2']

  $d->availableVersions('storage');  # ['v1','v1beta1', 'v1beta2']
  $d->latestStableVersion('storage');  # ['v1']

=head2 findAPIsWithDiffVers

Return only APIs with multiple versions available

=head2 searchInServices

  Search in services in "I'm lucky way"

  Must process case-insensitive way:
  e.g. Class is called CalendarList but resources is called calendarList in discovery

=head2 getMethodMeta

Download metadata from Google API discovery for particular class method

  $discovery->getResourceMeta('Moo::Google::Calendar::CalendarList::delete')

=head2 getResourceMeta

Download metadata from Google API discove for particular resource

  $discovery->getResourceMeta('Moo::Google::Calendar::Events')

=head2 listOfMethods

Return array of methods that are available for particular resource

  $discovery->listOfMethods('Moo::Google::Calendar::Events')

=head2 metaForAPI

  Same as getRest method but faster.
  Uses as cache discovery_full attribute to avoid multimple requests

  metaForAPI({ api => 'calendar', version => 'v3' });

=head1 MORE INFORMATION

https://developers.google.com/discovery/v1/reference/

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

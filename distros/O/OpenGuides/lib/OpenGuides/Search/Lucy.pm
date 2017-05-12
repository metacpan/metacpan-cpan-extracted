package OpenGuides::Search::Lucy;
use strict;
our $VERSION = '0.01';

use OpenGuides::Utils;
use Wiki::Toolkit::Search::Lucy;

=head1 NAME

OpenGuides::Search::Lucy - Run Lucy-backed text searches for OpenGuides.

=head1 DESCRIPTION

Does search stuff for OpenGuides.  Distributed and installed as part of
the OpenGuides project, not intended for independent installation.
This documentation is probably only useful to OpenGuides developers.

=head1 SYNOPSIS

  use OpenGuides::Config;
  use OpenGuides::Search::Lucy;

  my $config = OpenGuides::Config->new( file => "wiki.conf" );
  my $search = OpenGuides::Search::Lucy->new( config => $config );
  $search->run_text_search( search_string => "wombat defenestration" );

=head1 METHODS

=over 4

=item B<new>

  my $config = OpenGuides::Config->new( file => "wiki.conf" );
  my $search = OpenGuides::Search::Lucy->new( config => $config );

=cut

sub new {
    my ($class, %args) = @_;
    my $config = $args{config};
    my $searcher = OpenGuides::Utils->make_lucy_searcher( config => $config );

    my $self = {
      config => $config,
      searcher => $searcher,
    };

    bless $self, $class;
}

=item B<run_text_search>

  my $config = OpenGuides::Config->new( file => "wiki.conf" );
  my $search = OpenGuides::Search::Lucy->new( config => $config );
  $search->run_text_search( search_string => "wombat defenestration" );

=cut

sub run_text_search {
    my ( $self, %args ) = @_;

    # If there are commas in the search string, we're looking at an OR search.
    my $str = $args{search_string};
    my $and_or = ( $str =~ /,/ ) ? "OR" : "AND";

    my %finds = $self->{searcher}->search_nodes( $str, $and_or );

    # Package the finds in a way that OpenGuides::Search expects.
    my %results = map { $_ => { name => $_, score => $finds{$_} } }
                      keys %finds;
    return %results;
}

=back

=cut

=head1 AUTHOR

The OpenGuides Project (openguides-dev@lists.openguides.org)

=head1 COPYRIGHT

     Copyright (C) 2013 The OpenGuides Project.  All Rights Reserved.

The OpenGuides distribution is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<OpenGuides>

=cut

1;

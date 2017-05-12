package OpenGuides::Test;

use OpenGuides::Config;
use Wiki::Toolkit::Setup::SQLite;

use strict;
use vars qw( $VERSION );
$VERSION = '0.07';

use CGI;

=head1 NAME

OpenGuides::Test - Methods to help test OpenGuides applications.

=head1 DESCRIPTION

Provides methods to help when writing tests for OpenGuides.
Distributed and installed as part of the OpenGuides project, not
intended for independent installation.  This documentation is probably
only useful to OpenGuides developers.

=head1 SYNOPSIS

  use OpenGuides;
  use OpenGuides::Test;

  OpenGuides::Test::refresh_db();

  my $config = OpenGuides::Test->make_basic_config;
  $config->default_language( "nl" );

  my $guide = OpenGuides->new( config => $config );

  OpenGuides::Test->write_data(
                                guide      => $guide,
                                node       => "Crabtree Tavern",
                                os_x       => 523465,
                                os_y       => 177490,
                                categories => "Pubs",
                              );

=head1 METHODS

=over 4

=item B<make_basic_config>

  my $config = OpenGuides::Test->make_basic_config;
  $config->default_language( "nl" );

Makes an L<OpenGuides::Config> object with needed fields pre-filled.  You can
mess with it as you like then.

=cut

sub make_basic_config {
    my $config = OpenGuides::Config->new(
           vars => {
                     dbtype               => "sqlite",
                     dbname               => "t/node.db",
                     indexing_directory   => "t/indexes",
                     script_url           => "",
                     script_name          => "",
                     site_name            => "Test",
                     template_path        => "./templates",
                     custom_template_path => "./custom-templates",
                     home_name            => "Home",
                     geo_handler          => 1,
                     force_wgs84          => 1,
                     contact_email        => 'admins@example.org',
                     moderate_whitelist   => "",
                   }
    );

    eval { require Wiki::Toolkit::Search::Plucene; };
    if ( $@ ) { $config->use_plucene ( 0 ) };
	
    return $config;
}

=item B<write_data>

  my $config = OpenGuides::Test->make_basic_config;
  my $guide = OpenGuides->new( config => $config );

  OpenGuides::Test->write_data(
                                guide      => $guide,
                                node       => "Crabtree Tavern",
                                os_x       => 523465,
                                os_y       => 177490,
                                categories => "Pubs\r\nPub Food",
                              );

This method calls the C<make_cgi_object> method to make its CGI
object; you can supply values for any key mentioned there.  You should
supply them exactly as they would come from a CGI form, eg lines in a
textarea are separated by C<\r\n>.

This method will automatically grab the checksum from the database, so
even if the node already exists your data will still be written.  If you
don't want this behaviour (for example, if you're testing edit conflicts)
then pass in a true value to the C<omit_checksum> parameter:

  OpenGuides::Test->write_data(
                                guide         => $guide,
                                node          => "Crabtree Tavern",
                                omit_checksum => 1,
                              );

If you want to grab the output, pass a true value to C<return_output>:

  my $output = OpenGuides::Test->write_data(
                                             guide        => $guide,
                                             node         => "Crabtree Tavern",
                                             return_output => 1,
                                           );

Similarly, if you pass a true value to C<return_tt_vars>, the return value
will be the variables which would have been passed to the template for output:

  my %vars = OpenGuides::Test->write_data(
                                             guide        => $guide,
                                             node         => "Crabtree Tavern",
                                             return_tt_vars => 1,
                                           );

=cut

sub write_data {
    my ($class, %args) = @_;

    my $guide = delete $args{guide};
    my $node  = delete $args{node};

    my $q = $class->make_cgi_object( %args );

    # Get the checksum of the current contents if necessary.
    unless ( $args{omit_checksum} ) {
        my $wiki = $guide->wiki;
        if ( $wiki->node_exists( $node ) ) {
            my %data = $wiki->retrieve_node( $node );
            $q->param( -name => "checksum", -value => $data{checksum} );
        }
    }

    if ( $args{return_output} ) {
        return $guide->commit_node(
                                          return_output => 1,
                                          id => $node,
                                          cgi_obj => $q,
                                        );
    } elsif ( $args{return_tt_vars} ) {
        return $guide->commit_node(
                                          return_tt_vars => 1,
                                          id => $node,
                                          cgi_obj => $q,
                                        );
    } else {
        $guide->commit_node(
                                   id => $node,
                                   cgi_obj => $q,
                                 );
    }
}

=item B<make_cgi_object>

  my $q = OpenGuides::Test->make_cgi_object;

You can supply values for the following keys: C<content>, C<categories>,
C<locales>, C<node_image>, C<node_image_licence>,
C<node_image_copyright>, C<node_image_url>, C<phone>, C<fax>,
C<website>, C<hours_text>, C<address>, C<postcode>, C<map_link>,
C<os_x>, C<os_y>, C<osie_x>, C<osie_y>, C<latitude>, C<longitude>,
C<summary>, C<username>, C<comment>, C<edit_type>.  You should supply
them exactly as they would come from a CGI form, eg lines in a textarea
are separated by C<\r\n>.

=cut

sub make_cgi_object {
    my ( $class, %args ) = @_;

    # Set up CGI parameters ready for a node write.
    # Most of these are in here to avoid uninitialised value warnings.
    my $q = CGI->new( "" );
    $args{content} ||= "foo";
    $args{edit_type} ||= "Normal edit";
    for my $param ( qw( content categories locales node_image node_image_licence
                        node_image_copyright node_image_url phone fax website
                        hours_text address postcode map_link os_x os_y osie_x osie_y
                        latitude longitude summary username comment edit_type
                      )
                  ) {
        if (defined $args{$param}) {
            $q->param( -name => $param, -value => $args{$param} );
        } else {
            $q->param( -name => $param, -value => '' );
        }
    }
    $ENV{REMOTE_ADDR} = "127.0.0.1";

    return $q;
}

=item B<refresh_db>

  Openguides::Test::refresh_db();

Unlink the existing SQLite database t/node.db and Plucene/Lucy indexes.
Then create a new SQLite database t/node.db

=cut
sub refresh_db {
    unlink "t/node.db";
    unlink <t/indexes/*>;
    Wiki::Toolkit::Setup::SQLite::setup( { dbname => "t/node.db" } );
}


=back

=head1 AUTHOR

The OpenGuides Project (openguides-dev@lists.openguides.org)

=head1 COPYRIGHT

  Copyright (C) 2004-2013 The OpenGuides Project.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

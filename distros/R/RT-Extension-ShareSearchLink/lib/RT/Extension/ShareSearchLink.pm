use strict;
use warnings;

package RT::Extension::ShareSearchLink;

our $VERSION = '0.02';

=head1 NAME

RT::Extension::ShareSearchLink - Shorter links for ticket searches

=head1 DESCRIPTION

This extension adds a "I<Share>" item to the menu on the search results
page, and a "I<Share a link>" button to the bottom of the results.

Both of these will show a pop-up box containing a short link to the current
search, with all the search terms and formatting stored in a database entry
in RT.

This is useful when your search URL is very long.

=head1 RT VERSION

Known to work with RT 4.2.16, 4.4.4, and 5.0.1.

=head1 REQUIREMENTS

Requires C<Data::GUID>.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions.

=item Set up the database

After running C<make install> for the first time, you will need to create
the database tables for this extension.  Use C<etc/schema-mysql.sql> for
MySQL or MariaDB, or C<etc/schema-postgresql.sql> for PostgreSQL.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::ShareSearchLink');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your web server

=item Set up database pruning

Add a cron job similar to the ones you will already have for other RT
maintenance jobs like C<rt-email-dashboards> to clear down expired shared
search links, like this:

 4 4 * * * root /opt/rt4/bin/rt-crontool --search RT::Extension::ShareSearchLink --action RT::Extension::ShareSearchLink

This way, shared search links will expire 90 days after they have last been
viewed, and will expire within 7 days of creation if they aren't viewed at
least twice in that time.

=back

=head1 AUTHOR

Andrew Wood

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-ShareSearchLink@rt.cpan.org">bug-RT-Extension-ShareSearchLink@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ShareSearchLink">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-ShareSearchLink@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ShareSearchLink

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Andrew Wood

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

# Dummy "new" function to pretend to be an RT::Search type of thing so we
# can be called from rt-crontool.
#
sub new {
    my ( $proto, %args ) = @_;
    my ( $class, $self );
    $class = ref($proto) || $proto;

    $self = {
        '_TicketsObj'  => $args{'TicketsObj'},
        '_Argument'    => $args{'Argument'},
        '_CurrentUser' => $args{'CurrentUser'}
    };

    bless( $self, $class );

    return $self;
}

# Dummy "Prepare" function pretending to be an RT::Search so that we run a
# pruning action when called from rt-crontool.
#
sub Prepare {
    my ($self) = @_;
    my ( $CutoffISO, $ItemsToRemove, $Item );
    my ($sec,  $min,  $hour,  $mday,  $mon,
        $year, $wday, $ydaym, $isdst, $offset
       );

    # Remove items created, and last viewed, more than 90 days ago.
    #
    ( $sec, $min, $hour, $mday, $mon, $year, $wday, $ydaym, $isdst, $offset )
        = gmtime( time - 90 * 86400 );
    $CutoffISO = sprintf(
        "%04d-%02d-%02d %02d:%02d:%02d",
        ( $year + 1900 ),
        ( $mon + 1 ),
        $mday, $hour, $min, $sec
    );
    $ItemsToRemove = RT::ShareSearchLink::SharedSearchLinks->new(
        $self->{'_CurrentUser'} );
    $ItemsToRemove->Limit(
        'FIELD'    => 'LastViewed',
        'OPERATOR' => '<',
        'VALUE'    => $CutoffISO
    );
    $ItemsToRemove->Limit(
        'FIELD'    => 'Created',
        'OPERATOR' => '<',
        'VALUE'    => $CutoffISO
    );
    $Item->Delete() while ( $Item = $ItemsToRemove->Next );

    # Remove items created, and last viewed, more than 7 days ago, which
    # have been viewed fewer than twice.
    #
    ( $sec, $min, $hour, $mday, $mon, $year, $wday, $ydaym, $isdst, $offset )
        = gmtime( time - 7 * 86400 );
    $CutoffISO = sprintf(
        "%04d-%02d-%02d %02d:%02d:%02d",
        ( $year + 1900 ),
        ( $mon + 1 ),
        $mday, $hour, $min, $sec
    );
    $ItemsToRemove = RT::ShareSearchLink::SharedSearchLinks->new(
        $self->{'_CurrentUser'} );
    $ItemsToRemove->Limit(
        'FIELD'    => 'LastViewed',
        'OPERATOR' => '<',
        'VALUE'    => $CutoffISO
    );
    $ItemsToRemove->Limit(
        'FIELD'    => 'Views',
        'OPERATOR' => '<',
        'VALUE'    => 2
    );
    $ItemsToRemove->Limit(
        'FIELD'    => 'Created',
        'OPERATOR' => '<',
        'VALUE'    => $CutoffISO
    );
    $Item->Delete() while ( $Item = $ItemsToRemove->Next );

    # Remove items created more than 7 days ago and never viewed.
    #
    $ItemsToRemove = RT::ShareSearchLink::SharedSearchLinks->new(
        $self->{'_CurrentUser'} );
    $ItemsToRemove->Limit(
        'FIELD'    => 'LastViewed',
        'OPERATOR' => 'IS',
        'VALUE'    => 'NULL',
    );
    $ItemsToRemove->Limit(
        'FIELD'    => 'Created',
        'OPERATOR' => '<',
        'VALUE'    => $CutoffISO
    );
    $Item->Delete() while ( $Item = $ItemsToRemove->Next );
}

{

=head1 Internal package RT::ShareSearchLink::SharedSearchLink

This package provides the shared search link object.

=cut

    package RT::ShareSearchLink::SharedSearchLink;
    use base 'RT::Record';

    use Data::GUID;
    use Storable qw/nfreeze thaw/;
    use MIME::Base64;

    sub Table {'SharedSearchLinks'}

=head2 Create Parameters => { ... }, [ UUID => 'xxx' ]

Creates a new shared search link for a search with the given parameters, and
returns (I<$id>, I<$message>).  If a I<UUID> is not supplied, a new one is
generated.

=cut

    sub Create {
        my $self = shift;
        my %args = (
            'UUID'       => '',
            'Parameters' => '',
            'LastViewed' => undef,
            'Views'      => 0,
            @_
        );

        $args{'UUID'} = Data::GUID->new->as_string if ( not $args{'UUID'} );
        $args{'Parameters'} = encode_base64( nfreeze( $args{'Parameters'} ) );

        $RT::Handle->BeginTransaction();
        my ( $id, $msg ) = $self->SUPER::Create(%args);
        unless ($id) {
            $RT::Handle->Rollback();
            return ( undef, $msg );
        }

    # We won't bother with a transaction history as it would just waste
    # space.
    #
    # my ($txn_id, $txn_msg, $txn) = $self->_NewTransaction(Type => 'Create');
    # unless ($txn_id) {
    #     $RT::Handle->Rollback();
    #     return (undef, $self->loc('Internal error: [_1]', $txn_msg));
    # }

        $RT::Handle->Commit();

        return ( $id,
            $self->loc( 'Shared search link [_1] created', $self->id ) );
    }

=head2 Load $id|$UUID

Load a shared search link by numeric ID or by string UUID, returning the
numeric ID or undef.

=cut

    sub Load {
        my $self = shift;

        my $Identifier = shift;
        if ( not $Identifier ) {
            return (undef);
        }

        if ( $Identifier =~ /^(\d+)$/ ) {
            $self->SUPER::LoadById($Identifier);
        } else {
            $self->LoadByCols( 'UUID' => $Identifier );
        }

        return ( $self->Id );
    }

=head2 Delete

Delete this shared search link from the database.

=cut

    sub Delete {
        my $self = shift;

        $RT::Handle->BeginTransaction();
        $self->SUPER::Delete();
        $RT::Handle->Commit();
        return ( 1, $self->loc('Shared search link deleted') );
    }

=head2 Parameters

Return a hash of the parameters stored in this shared search link.

=cut

    sub Parameters {
        my $self = shift;

        my $Parameters;
        eval {
            $Parameters
                = thaw( decode_base64( $self->_Value('Parameters') ) );
        };
        if ($@) {
            $RT::Logger->error( "Deserialization of shared search link "
                    . $self->id
                    . " failed" );
        }

        return (%$Parameters);
    }

=head2 AddView

Increment the view counter for this shared search link, and set its last viewed date.

=cut

    sub AddView {
        my $self = shift;

        $self->SUPER::_Set(
            'Field' => 'Views',
            'Value' => 1 + $self->_Value('Views')
        );

        my ($sec,  $min,  $hour,  $mday,  $mon,
            $year, $wday, $ydaym, $isdst, $offset
           ) = gmtime();

        my $NowISO = sprintf(
            "%04d-%02d-%02d %02d:%02d:%02d",
            ( $year + 1900 ),
            ( $mon + 1 ),
            $mday, $hour, $min, $sec
        );

        $self->SUPER::_Set(
            'Field' => 'LastViewed',
            'Value' => $NowISO
        );

        return ( 0, '' );
    }

=head2 _CoreAccessible

Private method which defines the columns in the database table.

=cut

    sub _CoreAccessible {
        {

            'id' => {
                read       => 1,
                auto       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => ''
            },

            'UUID' => {
                read       => 1,
                write      => 1,
                sql_type   => 12,
                length     => 37,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'varchar(37)',
                default    => ''
            },

            'Parameters' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'LastViewed' => {
                read       => 1,
                auto       => 0,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            },

            'Views' => {
                read       => 1,
                auto       => 0,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'LastUpdatedBy' => {
                read       => 1,
                auto       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'LastUpdated' => {
                read       => 1,
                auto       => 1,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            },

            'Creator' => {
                read       => 1,
                auto       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Created' => {
                read       => 1,
                auto       => 1,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            },
        };
    }

    RT::Base->_ImportOverlays();
}

{

=head1 Internal package RT::ShareSearchLink::SharedSearchLinks

This package provides the group class for shared search links.

=cut

    package RT::ShareSearchLink::SharedSearchLinks;

    use base 'RT::SearchBuilder';

    sub Table {'SharedSearchLinks'}

    sub _Init {
        my $self = shift;
        $self->OrderByCols( { FIELD => 'id', ORDER => 'ASC' } );
        return $self->SUPER::_Init(@_);
    }

    RT::Base->_ImportOverlays();
}

1;

package <%= ${class} %>::GuiPlugin::Song;
use Mojo::Base 'CallBackery::GuiPlugin::AbstractTable';
use CallBackery::Translate qw(trm);
use CallBackery::Exception qw(mkerror);
use Mojo::JSON qw(true false);

=head1 NAME

<%= ${class} %>::GuiPlugin::Song - Song Table

=head1 SYNOPSIS

 use <%= ${class} %>::GuiPlugin::Song;

=head1 DESCRIPTION

The Song Table Gui.

=cut


=head1 METHODS

All the methods of L<CallBackery::GuiPlugin::AbstractTable> plus:

=cut


has screenOpts => sub {
    my $self = shift;
    my $opts = $self->SUPER::screenOpts;
    return {
        %%$opts,
        # an alternate layout for this screen
        layout => {
            class => 'qx.ui.layout.Dock',
            set => {},
        },
        # and settings accordingly
        container => {
            set => {
                # see https://www.qooxdoo.org/apps/apiviewer/#qx.ui.core.LayoutItem
                # for inspiration in properties to set
                maxWidth => 700,
                maxHeight => 500,
                alignX => 'left',
                alignY => 'top',
            },
            addProps => {
                edge => 'west'
            }
        }
    }
};

has formCfg => sub {
    my $self = shift;
    my $db = $self->user->db;

    return [
        {
            widget => 'header',
            label => trm('*'),
            note => trm('Nice Start')
        },
        {
            key => 'song_title',
            widget => 'text',
            note => 'Just type the title of a song',
            label => 'Search',
            set => {
                placeholder => 'Song Title',
            },
        },
    ]
};

=head2 tableCfg


=cut

has tableCfg => sub {
    my $self = shift;
    return [
        {
            label => trm('Id'),
            type => 'number',
            width => '1*',
            key => 'song_id',
            sortable => true,
            primary => true
        },
        {
            label => trm('Title'),
            type => 'string',
            width => '6*',
            key => 'song_title',
            sortable => true,
        },
        {
            label => trm('Voices'),
            type => 'string',
            width => '1*',
            key => 'song_voices',
            sortable => true,
        },
        {
            label => trm('Composer'),
            type => 'string',
            width => '2*',
            key => 'song_composer',
            sortable => true,
        },
        {
            label => trm('Page'),
            type => 'number',
            width => '1*',
            key => 'song_page',
            sortable => true,
        },
#        {
#            label => trm('Size'),
#            type => 'number',
#            format => {
#                unitPrefix => 'metric',
#                maximumFractionDigits => 2,
#                postfix => 'Byte',
#                locale => 'en'
#            },
#            width => '1*',
#            key => 'song_size',
#            sortable => true,
#        },
        {
            label => trm('Note'),
            type => 'string',
            width => '3*',
            key => 'song_note',
            sortable => true,
        },
#       {
#            label => trm('Created'),
#            type => 'date',
#            format => 'yyyy-MM-dd HH:mm:ss Z',
#            width => '3*',
#            key => 'song_date',
#            sortable => true,
#       },
        
     ]
};

=head2 actionCfg

Only users who can write get any actions presented.

=cut

has actionCfg => sub {
    my $self = shift;
    return [] if $self->user and not $self->user->may('write');

    return [
        {
            label => trm('Add Song'),
            action => 'popup',
            addToContextMenu => false,
            name => 'songFormAdd',
            key => 'add',
            popupTitle => trm('New Song'),
            set => {
                minHeight => 600,
                minWidth => 500
            },
            backend => {
                plugin => 'SongForm',
                config => {
                    type => 'add'
                }
            }
        },
        {
            action => 'separator'
        },
        {
            label => trm('Edit Song'),
            action => 'popup',
            addToContextMenu => true,
            defaultAction => true,
            key => 'edit',
            name => 'songFormEdit',
            buttonSet => {
                enabled => false,
            },
            popupTitle => trm('Edit Song'),
            backend => {
                plugin => 'SongForm',
                config => {
                    type => 'edit'
                }
            }
        },
        {
            label => trm('Delete Song'),
            action => 'submitVerify',
            addToContextMenu => true,
            question => trm('Do you really want to delete the selected Song '),
            key => 'delete',
            buttonSet => {
                enabled => false,
            },
            actionHandler => sub {
                my $self = shift;
                my $args = shift;
                my $id = $args->{selection}{song_id};
                die mkerror(4992,"You have to select a song first")
                    if not $id;
                my $db = $self->user->db;
                if ($db->deleteData('song',$id) == 1){
                    return {
                         action => 'reload',
                    };
                }
                die mkerror(4993,"Faild to remove song $id");
                return {};
            }
        }
    ];
};

sub db {
    shift->user->mojoSqlDb;
};

sub _getFilter {
    my $self = shift;
    my $search = shift;
    my $filter = '';
    if ( $search ){
        $filter = "WHERE song_title LIKE ".$self->db->dbh->quote('%'.$search);
    }
    return $filter;
}

sub getTableRowCount {
    my $self = shift;
    my $args = shift;
    my $filter = $self->_getFilter($args->{formData}{song_title});
    return $self->db->query("SELECT count(song_id) AS count FROM song $filter")->hash->{count};
}

sub getTableData {
    my $self = shift;
    my $args = shift;
    my $filter = $self->_getFilter($args->{formData}{song_title});
    my $SORT ='';
    if ($args->{sortColumn}){
        $SORT = 'ORDER BY '.$self->dbh->quote_identifier($args->{sortColumn});
        $SORT .= $args->{sortDesc} ? ' DESC' : ' ASC';
    }
    my $data = $self->db->query(<<"SQL",$args->{lastRow}-$args->{firstRow}+1,$args->{firstRow});
SELECT *
FROM song
$filter
$SORT
LIMIT ? OFFSET ?
SQL
    # this is just a silly example to show how to modify the action button properties
    # based on the row selected
    for my $row (@$data) {
        my $ok = true;        
        if ($row->{song_note} =~ /protect/ and not $self->user->may('admin')){
             $ok = false;
        }
        $row->{_actionSet} = {
            edit => {
                enabled => $ok
            },
            delete => {
                enabled => $ok,
            }        
       }
    }
    return $data;
}

1;
__END__

=head1 COPYRIGHT

Copyright (c) <%= ${year} %> by <%= ${fullName} %>. All rights reserved.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 <%= "${date} ${userName}" %> 0.0 first version

=cut

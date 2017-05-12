package Parley::Controller::My;
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use base 'Catalyst::Controller';

use Image::Magick;
use JSON;
use Image::Size qw( html_imgsize imgsize );

use Parley::App::Error qw( :methods );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Global class data
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my %dfv_profile_for = (
    # DFV validation profile for preferences
    time_format => {
        # make sure we get *something* for checkboxes
        # (which don't submit anything at all when unchecked)
        defaults => {
            use_utc     => 0,
            show_tz     => 0,
        },

        require_some => {
            tz_data => [ 1, qw(use_utc selectZone) ],
        },
        optional => [
            qw( show_tz time_format ),
        ],

        filters     => [qw( trim )],
        msgs => {
            format  => q{%s},
            missing => q{One ore more required fields are missing.},

            constraints => {
                tz_data => 'you must do stuff',
            },
        },
    },

    notifications => {
        # make sure we get *something* for checkboxes
        # (which don't submit anything at all when unchecked)
        defaults => {
            watch_on_post       => 0,
            notify_thread_watch => 0,
        },

        required => [
            qw(
                watch_on_post
                notify_thread_watch
            )
        ],
    },

    skin => {
        required => [
            qw(
                skin
            )
        ],
    },

    user_avatar => {
        required => [
            qw(
                avatar_file
            )
        ],
    },
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Controller Actions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub auto : Private {
    my ($self, $c) = @_;
    # need to be logged in to perform any 'my' actions
    my $status = $c->login_if_required(
        $c->localize(q{LOGIN REQUIRED}) 
    );
    if (not defined $status) {
        return 0;
    }

    # undecided if you need to be authed to perform 'my' actions
    #if (not Parley::App::Helper->is_authenticted($c)) {
    #    $c->stash->{error}{message} = q{You need to authenticate your registration before you can start a new topic.};
    #}


    # data we always want in the stash for /my

    # what's the current time? then we can show it in the TZ area
    $c->stash->{current_time} = DateTime->now();

    # fetch timezone categories
    my $tz_categories = DateTime::TimeZone->all_names();
    $c->stash->{tz_categories} = $tz_categories;

    # fetch time formats
    $c->stash->{time_formats} =
        $c->model('ParleyDB')->resultset('PreferenceTimeString')->search(
            {},     # fetch everything
            {
                order_by    => [\'sample ASC'],    # order by the "preview/sample" string
            }
        );


    return 1;
}


sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Parley::Controller::My in My.');
}


sub preferences : Local {
    my ($self, $c) = @_;
    my ($tz_categories);

    # where did we come from? it would be nice to return there when we're done
    if (
        defined $c->request->referer()
            and 
        $c->request->referer() !~ m{/my/preferences}xms
    ) {
        $c->session->{my_pref_came_from} = $c->request->referer();
    }

    # show a specific tab?
    if (defined $c->request->param('tab')) {
        $c->session->{show_pref_tab} = 'tab_' . $c->request->param('tab');
        $c->log->warn( $c->session->{show_pref_tab} );
    }

    # formfill/stash data
    if ('UTC' eq $c->_authed_user()->preference()->timezone()) {
        $c->stash->{formdata}{use_utc} = 1;
    }
    else {
        $c->stash->{formdata}{selectZone}
            = $c->_authed_user()->preference()->timezone();
    }
    # time format
    if (defined $c->_authed_user()->preference()->time_format()) {
        $c->stash->{formdata}{time_format} =
            $c->_authed_user()->preference()->time_format()->id();
    }
    # show tz?
    $c->stash->{formdata}{show_tz}
        = $c->_authed_user()->preference()->show_tz();

    # watched threads
    my $watches = $c->model('ParleyDB')->resultset('ThreadView')->search(
        {
            person_id   => $c->_authed_user()->id(),
            watched     => 1,
        },
        {
            order_by    => [\'last_post.created DESC'],
            join        => {
                'thread' => 'last_post',
            },
        }
    );
    $c->stash->{thread_watches} = $watches;

    # skin
    $c->stash->{formdata}{skin}
        = (
            $c->_authed_user()->preference()->skin()
                or
            $c->config->{site_skin}
                or
            q{base}
        )
    ;
    $c->log->debug('pref-site-skin: ' . $c->stash->{formdata}{skin});

    return;
}

sub update :Path('/my/preferences/update') {
    my ($self, $c) = @_;
    my $form_name = $c->request->param('form_name');

    # use the my/preferences template
    $c->stash->{template} = 'my/preferences';

    # make sure the form name matches something we have a DFV profile for
    if (not exists $dfv_profile_for{ $form_name }) {
        # if there's no form, detach back to prefs
        if ($form_name =~ m{\A\s*\z}xms) {
            $c->response->redirect( $c->uri_for('/my/preferences') );
            return;
        }

        # otherwise notify user about the unknown form
        parley_warn(
            $c,
              $c->localize(qq{No Such Form}) 
            . qq{: $form_name}
        );
        return;
    }

    # validate the specified form
    $c->form(
        $dfv_profile_for{ $form_name }
    );

    # are we updating TZ preferences?
    my $ok_update;
    if ('time_format' eq $form_name) {
        # return to the right tab
        # use session flash, or we lose the info with the redirect
        $c->session->{show_pref_tab} = 'tab_time';

        $ok_update = $self->_process_form_time_format( $c );
    }
    # are we updating notification preferences?
    elsif ('notifications' eq $form_name) {
        # return to the right tab
        # use session flash, or we lose the info with the redirect
        $c->session->{show_pref_tab} = 'tab_notifications';

        $ok_update = $self->_process_form_notifications( $c );
    }
    # are we updating the skin
    elsif ('skin' eq $form_name) {
        # return to the right tab
        # use session flash, or we lose the info with the redirect
        $c->session->{show_pref_tab} = 'tab_skin';

        $ok_update = $self->_process_form_skin( $c );
    }
    # are we updating the avatar
    elsif ('user_avatar' eq $form_name) {
        # return to the right tab
        # use session flash, or we lose the info with the redirect
        $c->session->{show_pref_tab} = 'tab_avatar';

        $ok_update = $self->_process_form_avatar( $c );
    }

    # otherwise we haven't decided how to handle the specified form ...
    else {
        $c->stash->{error}{message} = "don't know how to handle: $form_name";
        return;
    }

    if ($ok_update) {
        $c->response->redirect( $c->uri_for('/my/preferences') );
    }
    else {
        $c->stash->{template} = 'my/preferences';
    }

    return;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Private Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _form_data_valid {
    my ($self, $c) = @_;

    # deal with missing/invalid fields
    if ($c->form->has_missing()) {
        parley_warn($c, $c->localize(q{DFV FILL REQUIRED}));
        foreach my $f ( $c->form->missing ) {
            parley_warn($c, $f);
        }

        return; # invalid form data
    }
    elsif ($c->form->has_invalid()) {
        parley_warn($c, $c->localize(q{DFV FIELDS INVALID}));
        foreach my $f ( $c->form->invalid ) {
            parley_warn($c, $f);
        }

        return; # invalid form data
    }

    # otherwise, the form data is ok ...
    return 1;
}


sub upload : Global {
    my ($self, $c) = @_;

    if ( $c->request->parameters->{form_submit} eq 'yes' ) {

        if ( my $upload = $c->request->upload('avatar_file') ) {

            my $filename = $upload->filename;
            my $target   = "/tmp/upload/$filename";

            unless ( $upload->link_to($target) || $upload->copy_to($target) ) {
                die( "Failed to copy '$filename' to '$target': $!" );
            }
        }
    }

    $c->stash->{template} = 'my/preferences';
}


sub _process_form_avatar {
    my ($self, $c) = @_;
    my ($upload);
    $c->log->debug('_process_form_avatar');

    if (not $self->_form_data_valid($c)) {
        $c->log->debug('form data is not valid');
        return;
    }

    $c->log->info( $c->request->param('avatar_file') );
    
    if ( $upload = $c->request->upload('avatar_file') ) {
        $c->log->debug( ref($upload) );
        $c->log->debug( $upload->filename );
        $c->log->debug( $upload->type );
        $c->log->debug( $upload->size );

        # reject files that are too large
        if ($upload->size > 20480 ) {
            parley_warn($c, $c->localize(q{FILE TOO LARGE}));
            $c->log->info($c->localize(q{FILE TOO LARGE}));
            return;
        }

        # reject anything that doesn't appear to be an image
        if ($upload->type !~ m{\Aimage/}xms) {
            parley_warn(
                $c,
                  $c->localize(q{FILE NOT IMAGE}) 
                . q{ [}
                . $upload->type
                . q{]}
            );
            return;
        }

        # store the file (but don't make it active yet)
        my $filename    = $upload->filename;
        my $target_dir  =   $c->path_to('root')
                          . q{/static/user_file/}
                          . $c->_authed_user->id();
        my $target      = $target_dir . q{/} . $filename;

        # create the directory if it doesn't exist
        if (not -d $target_dir) {
            # try to create the target directory
            mkdir $target_dir or do {
                $c->log->error( qq{$target_dir - $!} );
                parley_warn($c, $c->localize(q{FILE NEWDIR FAILED}));
                return;
            };

            # if for some reason the directory still doesn't exist..
            if (not -d $target_dir) {
                parley_warn($c, $c->localize(q{FILE NEWDIR FAILED}));
                $c->log->error( qq{$target_dir - $!} );
                return;
            }
        }

        # save the file for processing
        if ( not $upload->link_to($target) and not $upload->copy_to($target) ) {
            parley_warn($c, $c->localize(q{FILE STORE FAILED}));
            $c->log->error( qq{$target - $!} );
            return;
        }
        $c->log->info($target, $target_dir);

        # check the image dimensions, and if it's too large, scale it down to
        # something we accept, also convert it to a JPG
        _convert_and_scale_image($target, $target_dir);
    }

    return 1;
}

sub _process_form_notifications {
    my ($self, $c) = @_;

    if (not $self->_form_data_valid($c)) {
        return;
    }

    # Automatically add watches for new posts?
    $c->_authed_user()->preference()->watch_on_post(
        $c->form->valid('watch_on_post')
    );

    # Receive email notification for watched threads
    $c->_authed_user()->preference()->notify_thread_watch(
        $c->form->valid('notify_thread_watch')
    );

    # store changes
    $c->_authed_user()->preference()->update;

    return 1;
}

sub _process_form_skin {
    my ($self, $c) = @_;

    if (not $self->_form_data_valid($c)) {
        return;
    }

    # if our skin is 'base' set the preference to NULL
    if (q{base} eq $c->form->valid('skin')) {
        $c->_authed_user()->preference()->skin(
            undef
        );
    }
    else {
        $c->_authed_user()->preference()->skin(
            $c->form->valid('skin')
        );
    }

    # store changes
    $c->_authed_user()->preference()->update;

    return 1;
}


sub _process_form_time_format {
    my ($self, $c) = @_;

    if (not $self->_form_data_valid($c)) {
        return;
    }

    $c->log->debug(
        ref($c->_authed_user()->preference())
    );

    # tz preference value
    if ($c->form->valid('use_utc')) {
        $c->_authed_user()->preference()->timezone('UTC');
    }
    else {
        $c->_authed_user()->preference()->timezone(
            $c->form->valid('selectZone')
        );
    }
    # time_format preference
    if (defined $c->form->valid('time_format')) {
        $c->_authed_user()->preference()->time_format_id(
            $c->form->valid('time_format')
        )
    }
    else {
        $c->_authed_user()->preference()->time_format_id( undef );
    }
    # show_tz
    $c->_authed_user()->preference()->show_tz(
        ($c->form->valid('show_tz') || 0)
    );
    # store changes
    $c->_authed_user()->preference()->update();

    return 1;
}

sub saveHandler : Local {
    my ($self, $c) = @_;
    my ($return_data, $json);
    my $fieldname = $c->request->param('fieldname');

    $c->response->content_type('text/json');

    $return_data->{old_value} = $c->request->param('ovalue');
    $return_data->{fieldname} = $fieldname;
    $return_data->{fieldname} =~ s{\s+}{}g;

    my %field_map = (
        'FirstName' => {
            'resultset'     => 'Person',
            'db_column'     => 'first_name',
        },
        'LastName' => {
            'resultset'     => 'Person',
            'db_column'     => 'last_name',
        },
        'ForumName' => {
            'resultset'     => 'Person',
            'db_column'     => 'forum_name',
            'is_unique'     => 1,
        },
    );

    if (exists $field_map{$fieldname}) {
        my $resultset = $field_map{$fieldname}->{resultset};
        my $db_column = $field_map{$fieldname}->{db_column};
        my $is_unique = $field_map{$fieldname}->{is_unique} || 0;

        # get the user we're authed as
        my $person = $c->model('ParleyDB')->resultset($resultset)->find(
            $c->_authed_user()->id()
        );
        # it would be nice to deduce this from the schema, but hey ..
        # .. this'll do for now
        if ($is_unique) {
            # make sure the value isn't already in use
            my $count = $c->model('ParleyDB')->resultset($resultset)->count(
                {
                    $db_column => $c->request->param('value'),
                }
            );
            if ($count) {
                $return_data->{message} =
                      q{<p>'}
                    . $c->request->param('value')
                    . q{' }
                    . $c->localize(q{FORUMNAME USED})
                    . q{.</p>}
                ;
                $return_data->{updated} = 0;
                $json = to_json($return_data);
                $c->response->body( $json );
                $c->log->info( $json );
                return;
            };
        }

        # perform the update
        eval {
            # update the relevant field
            $person->update(
                {
                    $db_column => $c->request->param('value'),
                }
            );
        };
        # check for errors
        if ($@) {
            parley_warn($c, $@);
            $return_data->{message} = qq{<p>ERROR: $@</p>};
            $return_data->{updated} = 0;
            $json = objToJson($return_data);
            $c->response->body( $json );
            return;
        }
        else {
            $return_data->{message} =
                  q{<p>Updated }
                . $fieldname
                . q{ from '}
                . $c->request->param('ovalue')
                . q{' to '}
                . $c->request->param('value')
                . q{'</p>}
            ;
            $return_data->{updated} = 1;
            $json = objToJson($return_data);
            $c->log->info( $json );
            $c->response->body( $json );
            return;
        }
    }
    else {
        $return_data->{message} =
              q{<p>}
            . $c->localize(q{Unknown field name})
            . q{</p>};
        $return_data->{updated} = 0;
        $json = objToJson($return_data);
        $c->response->body( $json );
        return;
    }

    return;
}

sub _convert_and_scale_image {
    my ($file, $destdir) = @_;
    my $options = {
        'width'  => 100,
        'height' => 150,
    };

    # get the image dimensions
    my ($width, $height) = imgsize($file);

    # create a new image mangling object
    my $img = Image::Magick->new()
        or die $!;

    # read in the image file
    $img->Read($file);

    if ($width > $options->{width} or $height > $options->{height}) {
        # scale the longest side - if it's square, scale by height
        if ($width > $height) {
            # scale down by width
            #warn('# scale down by width');
            $img->Resize(
                geometry => $options->{width}
            );
        }
        elsif ($height >= $width) {
            # scale down by height
            #warn('# scale down by height');
            $img->Resize(
                geometry => q{x} . $options->{height}
            );
        }
    }

    # write out the scaled image
    $img->Write($destdir . q{/avatar.jpg});

    return;
}

=head1 NAME

Parley::Controller::My - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index 

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

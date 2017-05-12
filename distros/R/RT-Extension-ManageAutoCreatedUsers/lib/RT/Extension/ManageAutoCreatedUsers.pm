package RT::Extension::ManageAutoCreatedUsers;

use strict;
use warnings;
use RT::Extension::MergeUsers;
use Scalar::Util 'blessed';
use Module::Runtime 'use_module';

our $VERSION = '0.12';

RT->AddJavaScript('manage-autocreated-users.js');

sub get_autocreated_users {
    my $class = shift;
    my $users = RT::Users->new(RT->SystemUser);
    $users->Limit(
        FIELD => 'Comments',
        OPERATOR => 'STARTSWITH',
        VALUE => 'Autocreated',
    );
    return $users;
}

sub get_watching_tickets_for {
    my ( $class, $email_address ) = @_;
    my $tickets = RT::Tickets->new(RT->SystemUser);
    $tickets->LimitWatcher(
        OPERATOR => '=',
        VALUE => $email_address,
    );
    return $tickets;
}

sub get_merge_suggestion_for {
    my ( $class, $email_address ) = @_;
    my $mail_domain = RT->Config->Get('RTxAutoUserMailDomain');
    return unless $mail_domain;

    $email_address =~ s/\@.*/\@$mail_domain/;
    my $users = RT::Users->new(RT->SystemUser);
    $users->LimitToEmail($email_address);
    return $users->First;
}

sub get_list_of_actions { return qw(no-action validate shred replace merge) }

sub _get_user_by_email {
    my ( $class, $email_address ) = @_;
    my $user = RT::User->new(RT->SystemUser);
    $user->LoadByEmail($email_address);
    return $user;
}

sub _do_validate {
    my ( $class, $user ) = @_;
    my $user_comments = $user->Comments;
    $user_comments = 'Valid, ' . $user_comments;
    $user->SetComments($user_comments);
    return $user;
}

sub _do_merge {
    my ( $class, $user, $new_email_address ) = @_;
    my $new_user = $class->_get_user_by_email($new_email_address);
    if ( $new_user->id ) {
        $user = $class->_do_validate($user);
        $user->MergeInto($new_user);
        return $new_user;
    }
    return [0, 'New user not found'];
}

sub _do_shred {
    my ( $class, $user ) = @_;
    my $user_id = $user->id;
    my $tickets_shredder = use_module('RT::Shredder::Plugin::Tickets')->new;
    my ( $test_status, $msg ) = $tickets_shredder->TestArgs(
        query => qq{Requestor.id = '$user_id'},
    );
    if ($test_status) {
        my ( $run_status, @objs ) = $tickets_shredder->Run;
        if ($run_status) {
            my $shredder = use_module('RT::Shredder')->new;
            @objs = $shredder->CastObjectsToRecords(Objects => \@objs);
            $shredder->Wipeout(Object => $_) for @objs;

            my $user_shredder = use_module('RT::Shredder::Plugin::Users')->new;
            ( $test_status, $msg ) = $user_shredder->TestArgs(
                status => 'any',
                name => $user->Name,
            );
            if ($test_status) {
                ( $run_status, @objs ) = $user_shredder->Run;
                if ($run_status) {
                    @objs = $shredder->CastObjectsToRecords(Objects => \@objs);
                    $shredder->Wipeout(Object => $_) for @objs;
                    return $user;
                }
                else {
                    return [$run_status, 'User shredder failed on ->Run'];
                }
            }
            else {
                return [$test_status, $msg];
            }
        }
        else {
            return [$run_status, 'Tickets shredder failed on ->Run'];
        }
    }
    else {
        return [$test_status, $msg];
    }
}

sub _do_replace {
    my ( $class, $user, $new_email_address ) = @_;
    my $new_user = $class->_get_user_by_email($new_email_address);
    if ( $new_user->id ) {
        my $shred_plugin = use_module('RT::Shredder::Plugin::Users')->new;
        my ( $test_status, $msg ) = $shred_plugin->TestArgs(
            status => 'any',
            name => $user->Name,
            replace_relations => $new_user->id,
        );
        if ( $test_status )  {
            my ( $run_status, @objs) = $shred_plugin->Run;
            if ( $run_status ) {
                my $shredder = use_module('RT::Shredder')->new;
                @objs = $shredder->CastObjectsToRecords( Objects => \@objs );
                my ( $resolver_status, $msg) = $shred_plugin->SetResolvers(
                    Shredder => $shredder
                );
                if ( $resolver_status ) {
                    $shredder->Wipeout(Object => $_) for @objs;
                    return $new_user;
                }
                else {
                    return [$resolver_status, $msg];
                }
            }
            else {
                return [$run_status, 'Users shredder failed on ->Run'];
            }
        }
        else {
            return [$test_status, $msg];
        }
    }
    return [0, 'New user not found'];
}

sub process_form {
    my ( $class, $args ) = @_;
    my $sys_user = RT->SystemUser;
    my $action_map = {
        map {
            $_ => join(q{_}, '_do', $_)
        } $class->get_list_of_actions
    };
    my @results;
    ACTION : foreach my $param (grep { /^action/ } keys %$args) {
        my $action = $args->{$param};
        next ACTION if $action eq 'no-action';

        my $function_name = $action_map->{$action};
        unless ( $function_name ) {
            RT->Logger->warn("Invalid action: $action");
            next ACTION;
        }

        my ( $user_id ) = $param =~ /^action-(\d+)/;
        my $user = RT::User->new($sys_user);
        $user->Load($user_id);
        unless ( $user->id ) {
            RT->Logger->warn("Error loading the user: $user_id");
            next ACTION;
        }

        if ( my $code_ref = $class->can($function_name) ) {
            my $new_email_address = $args->{
                join q{-}, 'merge-user', $user_id
            };
            my $return = $code_ref->($class, $user, $new_email_address);
            if ( blessed $return ) {
                push @results, $sys_user->loc(
                    ucfirst($action) . ': [_1] [_2]',
                    ($user->EmailAddress || $user->Name),
                    $action =~ /replace|merge/ ?
                        ' => ' . $return->EmailAddress || $return->Name
                        : q{},
                );
            }
            else {
                push @results, $sys_user->loc(
                    "Failed to $action: [_1]",
                    $user->EmailAddress || $user->Name,
                );
                RT->Logger->warn(
                    "Error to $action user $user_id: " . join(q{ - }, @$return)
                );
            }
        }
    }
    return @results;
}

package RT::User;

use Class::Method::Modifiers;

after UnMerge => sub {
    my $self = shift;
    my $user_comments = $self->Comments;
    $user_comments =~ s/Valid,\s+//;
    $self->SetComments($user_comments);
};

=head1 NAME

RT-Extension-ManageAutoCreatedUsers - Manage auto-created users

=head1 DESCRIPTION

This extension provides a tool to easy the management of auto-created users.

For each auto-created user, the tool shows tickets that they are a watcher of,
and offer the choice of:

=over

=item No action

=item Shred, replacing with an alternate user

=item Shred entirely

=item Merge with an alternate user

=item Mark as valid

=back

The tool attempts to supply a suggested user to merge into based on a simple
heuristic which assumes the correct email address from the
C<RTxAutoUserMailDomain> config option. If any of the options are selected,
the user will not appear in the listing again.

=head1 RT VERSION

Works with RT 4.2

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Set(@Plugins, qw(RT::Extension::ManageAutoCreatedUsers));

or add C<RT::Extension::ManageAutoCreatedUsers> to your existing C<@Plugins>
line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC <modules@bestpractical.com>

=head1 BUGS

All bugs should be reported via email to
L<bug-RT-Extension-ManageAutoCreatedUsers@rt.cpan.org|mailto:bug-RT-Extension-ManageAutoCreatedUsers@rt.cpan.org>
or via the web at
L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ManageAutoCreatedUsers>.

=head1 LICENSE AND COPYRIGHT

Copyright Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;

use strict;
use warnings;

my $new_group_name = 'Custom-Staff';

sub client_setup {

    # all privileged users will belong to this group
    my $group = RT::Group->new($RT::SystemUser);
    $group->LoadUserDefinedGroup($new_group_name);
    if ($group->Id) {
        print "Not creating $new_group_name: one already exists ". $group->Id . "\n";
    }
    my ($gid, $msg) = $group->CreateUserDefinedGroup( Name => $new_group_name );
    unless ($gid) {
        print "Unable to create group $new_group_name: $msg \n";
    }

}

sub client_import_queue {
    my $queue = shift;

    foreach my $cf (@{$queue->{CustomField}}) {
            $cf->{Name} = "FOO-" . $cf->{Name};
    }

    my $new_cf = {
      'Value' => [ qw(High Medium Low) ],
      'Name' => 'New Priority',
      'Single' => 1
    };

    push @{ $queue->{CustomField} }, $new_cf;

    return $queue;

}

sub client_import_user {
    my $user = shift;

    return unless $user->Privileged;

    my $new_group_name = $new_group_name;
    my $group = RT::Group->new($RT::SystemUser);
    $group->LoadUserDefinedGroup($new_group_name);
    if ($group->Id) {
        my $user_principal = $user->PrincipalObj;
        unless ($group->HasMember($user_principal)) {
            my ($mid,$msg) = $group->AddMember($user_principal->Id); 
            if ($mid) {
                print "Added " . $user->Name . " to $new_group_name \n";
            } else {
                print "Couldn't add " . $user->Name .
                      "to group $new_group_name: $msg \n";
            }
        }
    } else {
        print "Can't find group $new_group_name\n";
    }
}

# you might want to write some other code to track an old queue
# and indicate in the imported ticket which old queue it came from
sub client_import_ticket_extra {
    my $ticket = shift;

    my $queue_obj = RT::Queue->new($RT::SystemUser);
    $queue_obj->LoadByCols( Name => $ticket->{Queue} );

    my $cfobj = RT::CustomField->new($RT::SystemUser);
    $cfobj->LoadByName(
        Name  => 'Old Queue',
        Queue => $queue_obj->Id
    );
    
    $ticket->AddCustomFieldValue( 
        Field => $cfobj, 
        Value => 'Name of Old Queue',
        RecordTransaction => 0 # can load EffectiveId before its been rewritten
    );

    return $ticket;
        
}

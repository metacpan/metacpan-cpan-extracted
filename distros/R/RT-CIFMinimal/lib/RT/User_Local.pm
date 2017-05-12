package RT::User;

=head2 Apikeys

return an array of the user's apikeys from CIF

=cut

sub Apikeys {
    my $self = shift;
    require CIF::WebAPI::APIKey;
    my @recs = CIF::WebAPI::APIKey->search(uuid_alias => $self->EmailAddress());
    return(\@recs);
}

=head2 Load

Load a user object from the database. Takes a single argument.
If the argument is numerical, load by the column 'id'. If a user
object or its subclass passed then loads the same user by id.
Otherwise, load by the "Name" column which is the user's textual
username.

=cut

sub Load {
    my $self = shift;
    my $identifier = shift || return undef;
    
    my $ret;
    if ( $identifier !~ /\D/ ) {
        $ret = $self->SUPER::LoadById( $identifier );
    }
    elsif ( UNIVERSAL::isa( $identifier, 'RT::User' ) ) {
        $ret = $self->SUPER::LoadById( $identifier->Id );
    }
    else {
        $ret = $self->LoadByCol( "Name", $identifier );
    }
    if($self->Id()){
        my $mod = caller();
        if($mod eq 'RT::Interface::Web' && ref($self) eq 'RT::CurrentUser'){
            $self->CheckGroups();
        }
    }
    return($ret);
}

sub CheckGroups {
    my $self = shift;

    if(my %map = RT->Config->Get('CIFMinimal_UserGroupMapping')){
        my $x = $ENV{$map{'EnvVar'}};
        my @tags = split($map{'Pattern'},$x);
        my $group_map = $map{'Mapping'};
        foreach(keys %$group_map){
            foreach my $g (@tags){
                if($g eq $_){
                    require RT::Group;
                    my $y = RT::Group->new($RT::SystemUser);
                    my ($ret,$err) = $y->LoadUserDefinedGroup($group_map->{$_});
                    next if($y->HasMemberRecursively($self->PrincipalId));  
                    RT::Logger->debug("adding user to group: $g");
                    ($ret,$err) = $y->AddMember($self->PrincipalId);
                    unless($ret){
                        $RT::Logger->error("Couldn't add user to group: ".$y->Name());
                        $RT::Logger->error($err);
                        #$RT::Handle->Rollback();
                        return(0);
                    }
                }
            }
        }
    }
}

1;

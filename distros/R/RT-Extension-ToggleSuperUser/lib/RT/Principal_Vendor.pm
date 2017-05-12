no warnings qw(redefine);

sub _HasGroupRight
{
    my $self = shift;
    my %args = (
        Right        => undef,
        EquivObjects => [],
        @_
    );
    my $right = $args{'Right'};

    my $query =
      "SELECT ACL.id, ACL.ObjectType, ACL.ObjectId " .
      "FROM ACL, Principals, CachedGroupMembers WHERE ";

      if ( $self->CurrentUser->UserObj->FirstAttribute('DisableSuperUser') && $self->CurrentUser->UserObj->FirstAttribute('DisableSuperUser')->Content ) {
          # Only find rights with the name $right
          $query .= " (ACL.RightName = '$right') ";
      } else {
          # Only find superuser or rights with the name $right
          $query .= " (ACL.RightName = 'SuperUser' OR ACL.RightName = '$right') ";
      }

      # Never find disabled groups.
      $query .= "AND Principals.id = ACL.PrincipalId "
      . "AND Principals.PrincipalType = 'Group' "
      . "AND Principals.Disabled = 0 "

      # See if the principal is a member of the group recursively or _is the rightholder_
      # never find recursively disabled group members
      # also, check to see if the right is being granted _directly_ to this principal,
      #  as is the case when we want to look up group rights
      . "AND CachedGroupMembers.GroupId  = ACL.PrincipalId "
      . "AND CachedGroupMembers.GroupId  = Principals.id "
      . "AND CachedGroupMembers.MemberId = ". $self->Id ." "
      . "AND CachedGroupMembers.Disabled = 0 ";

    my @clauses;
    foreach my $obj ( @{ $args{'EquivObjects'} } ) {
        my $type = ref( $obj ) || $obj;
        my $clause = "ACL.ObjectType = '$type'";

        if ( ref($obj) && UNIVERSAL::can($obj, 'id') && $obj->id ) {
            $clause .= " AND ACL.ObjectId = ". $obj->id;
        }

        push @clauses, "($clause)";
    }
    if ( @clauses ) {
        $query .= " AND (". join( ' OR ', @clauses ) .")";
    }

    $self->_Handle->ApplyLimits( \$query, 1 );
    my ($hit, $obj, $id) = $self->_Handle->FetchResult( $query );
    return (0) unless $hit;

    $obj .= "-$id" if $id;
    return (1, $obj);
}

sub _HasRoleRight
{
    my $self = shift;
    my %args = (
        Right        => undef,
        EquivObjects => [],
        @_
    );
    my $right = $args{'Right'};

    my $query =
      "SELECT ACL.id " .
      "FROM ACL, Groups, Principals, CachedGroupMembers WHERE "; 

      if ( $self->CurrentUser->UserObj->FirstAttribute('DisableSuperUser') && $self->CurrentUser->UserObj->FirstAttribute('DisableSuperUser')->Content ) {
          # Only find rights with the name $right
          $query .= " (ACL.RightName = '$right') ";
      } else {
          # Only find superuser or rights with the name $right
          $query .= " (ACL.RightName = 'SuperUser' OR ACL.RightName = '$right') ";
      }

      # Never find disabled things
      $query .= "AND Principals.Disabled = 0 "
      . "AND CachedGroupMembers.Disabled = 0 "

      # We always grant rights to Groups
      . "AND Principals.id = Groups.id "
      . "AND Principals.PrincipalType = 'Group' "

      # See if the principal is a member of the group recursively or _is the rightholder_
      # never find recursively disabled group members
      # also, check to see if the right is being granted _directly_ to this principal,
      #  as is the case when we want to look up group rights
      . "AND Principals.id = CachedGroupMembers.GroupId "
      . "AND CachedGroupMembers.MemberId = ". $self->Id ." "
      . "AND ACL.PrincipalType = Groups.Type ";

    my (@object_clauses);
    foreach my $obj ( @{ $args{'EquivObjects'} } ) {
        my $type = ref($obj)? ref($obj): $obj;
        my $id;
        $id = $obj->id if ref($obj) && UNIVERSAL::can($obj, 'id') && $obj->id;

        my $object_clause = "ACL.ObjectType = '$type'";
        $object_clause   .= " AND ACL.ObjectId = $id" if $id;
        push @object_clauses, "($object_clause)";
    }
    # find ACLs that are related to our objects only
    $query .= " AND (". join( ' OR ', @object_clauses ) .")";

    # because of mysql bug in versions up to 5.0.45 we do one query per object
    # each query should be faster on any DB as it uses indexes more effective
    foreach my $obj ( @{ $args{'EquivObjects'} } ) {
        my $type = ref($obj)? ref($obj): $obj;
        my $id;
        $id = $obj->id if ref($obj) && UNIVERSAL::can($obj, 'id') && $obj->id;

        my $tmp = $query;
        $tmp .= " AND Groups.Domain = '$type-Role'";
        # XXX: Groups.Instance is VARCHAR in DB, we should quote value
        # if we want mysql 4.0 use indexes here. we MUST convert that
        # field to integer and drop this quotes.
        $tmp .= " AND Groups.Instance = '$id'" if $id;

        $self->_Handle->ApplyLimits( \$tmp, 1 );
        my ($hit) = $self->_Handle->FetchResult( $tmp );
        return (1) if $hit;
    }

    return 0;
}


1;
